#!/usr/bin/env bash
# Merge task đã APPROVE và lưu bằng chứng vào docs/07-verification/records/<ID>/ (DHF).
# Điều kiện (thiếu → không merge):
#   - .ai/reviews/<ID>.md: AI_VERDICT APPROVE; REVIEWED_SHA trùng HEAD của nhánh task/<ID>
#   - worktree sạch (không có thay đổi chưa qua review)
#   - Class trong HUMAN_SIGNOFF_CLASSES: chữ ký kỹ sư (SIGNOFF_MODE=text: trường HUMAN_*; gpg: + commit ký GPG)
#   - MERGE_RERUN_GATE=1: chạy lại scope + gate + trace tại đúng SHA đã ký, bằng script/config của repo chính
# Usage: scripts/merge.sh <ID>
# Exit:  0 merged | 1 thiếu điều kiện | 3 kiểm tra lại FAIL | 5 thiếu/không hợp lệ chữ ký kỹ sư
set -uo pipefail
ID="${1:?Usage: merge.sh <ID>}"
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
fail() { echo "✖ $1"; exit "${2:-1}"; }
load_task
REV=".ai/reviews/$ID.md"

[[ -f "$REV" ]] || fail "Thiếu hồ sơ review $REV (Claude phải ghi AI review trước)"
grep -qE '^AI_VERDICT:[[:space:]]*APPROVE' "$REV" || fail "AI_VERDICT chưa APPROVE"
[[ -d "$WT" ]] || fail "Không có worktree $WT"
BASE="$(git rev-parse -q --verify "$BASEREF")" || fail "Thiếu $BASEREF"
[[ -z "$(git -C "$WT" status --porcelain)" ]] \
  || fail "Worktree còn thay đổi chưa commit (chưa qua review) — chạy delegate --resume / lead.sh finish rồi review lại"
HEAD_SHA="$(git rev-parse "$BR")"
RSHA="$(grep -m1 -E '^REVIEWED_SHA:' "$REV" | sed -E 's/^REVIEWED_SHA:[[:space:]]*//; s/[[:space:]].*$//')"
[[ ${#RSHA} -ge 7 && "$HEAD_SHA" == "$RSHA"* ]] \
  || fail "REVIEWED_SHA (${RSHA:-trống}) ≠ HEAD của $BR ($HEAD_SHA) — code đã đổi sau review, phải review lại"

if [[ -n "$CLASS" && " $HUMAN_SIGNOFF_CLASSES " == *" $CLASS "* ]]; then
  if ! grep -qE '^HUMAN_REVIEWER:[[:space:]]*[^<[:space:]]' "$REV" || ! grep -qE '^HUMAN_DECISION:[[:space:]]*APPROVED' "$REV"; then
    echo "⏸ Class $CLASS cần kỹ sư review: điền HUMAN_REVIEWER, HUMAN_DECISION: APPROVED, HUMAN_DATE trong $REV"
    echo "  Xem diff đã review: git -C $WT diff $BASE $HEAD_SHA"; exit 5
  fi
  if [[ "${SIGNOFF_MODE:-text}" == gpg ]]; then
    [[ -z "$(git status --porcelain -- "$REV")" ]] \
      || fail "SIGNOFF_MODE=gpg: kỹ sư phải commit $REV bằng commit ký GPG (git commit -S) và không sửa sau đó" 5
    SIG="$(git log -1 --format='%G?' -- "$REV")"; SIGNER="$(git log -1 --format='%an <%ae>' -- "$REV")"
    [[ "$SIG" == G ]] || fail "Commit gần nhất của $REV không có chữ ký GPG hợp lệ (%G?=${SIG:-none})" 5
    [[ "$SIGNER" != *"${AI_WORKER_EMAIL:-ai-worker@localhost}"* && "$SIGNER" != *"${AI_LEAD_EMAIL:-ai-lead@localhost}"* ]] \
      || fail "Người ký $REV là tài khoản AI" 5
    echo "✔ Chữ ký GPG: $SIGNER"
  fi
fi

TMP="$(mktemp -d)"
if [[ "${MERGE_RERUN_GATE:-1}" == 1 ]]; then
  echo "■ Chạy lại kiểm tra tại ${HEAD_SHA:0:10} (script/config repo chính)..."
  run_checks > "$TMP/merge-checks.txt" 2>&1; RC=$?
  if (( RC != 0 )); then tail -30 "$TMP/merge-checks.txt"; fail "Kiểm tra lại FAIL — không merge" 3; fi
  grep -E '^\[|^trace:|^SCOPE' "$TMP/merge-checks.txt" | head -20
fi

HIST="$(git log --format='%h %an %ad %s' --date=iso-strict "$BASE..$HEAD_SHA")"
REVIEWER="$(grep -m1 -E '^HUMAN_REVIEWER:' "$REV" | sed -E 's/^HUMAN_REVIEWER:[[:space:]]*//')"
[[ "$REVIEWER" == \<* ]] && REVIEWER=""
MTRAILERS="$(commit_trailers)"$'\n'"Class: ${CLASS:-n/a}"$'\n'"Reviewed-SHA: $HEAD_SHA"
[[ -n "$REVIEWER" ]] && MTRAILERS+=$'\n'"Reviewed-by: $REVIEWER"
git merge --no-ff -q "$BR" -m "$(commit_subject merge "$ID" "${TITLE:-task}")" -m "$MTRAILERS" \
  || fail "git merge lỗi — xử lý conflict thủ công (conflict = code chưa review → review lại)"

# ---- Bằng chứng (DHF) ----
EV="docs/07-verification/records/$ID"; mkdir -p "$EV"
cp "$TASK" "$EV/task.md"; cp "$REV" "$EV/review.md"
[[ -f ".ai/reports/$ID.md" ]]         && cp ".ai/reports/$ID.md" "$EV/worker-report.md"
[[ -f ".ai/reports/$ID.xreview.md" ]] && cp ".ai/reports/$ID.xreview.md" "$EV/cross-review.md"
[[ -f ".ai/reports/$ID.meta" ]]       && cp ".ai/reports/$ID.meta" "$EV/rounds.txt"
[[ -f ".ai/reports/$ID.hook.log" ]]   && cp ".ai/reports/$ID.hook.log" "$EV/hook-denials.log"
for d in answers questions; do [[ -f ".ai/$d/$ID.md" ]] && cp ".ai/$d/$ID.md" "$EV/$d.md"; done
[[ -f ".ai/logs/$ID.gate" ]] && cp ".ai/logs/$ID.gate" "$EV/gate-output.txt"
[[ -f "$TMP/merge-checks.txt" ]] && cp "$TMP/merge-checks.txt" "$EV/merge-checks.txt"
{
  echo "task: $ID — ${TITLE:-}"; echo "class: ${CLASS:-n/a}  type: $TYPE  platform: $PLATFORM  owner: $OWNER"
  echo "base: $BASE"; echo "reviewed_head: $HEAD_SHA"; echo "merge_commit: $(git rev-parse HEAD)"
  echo "merged_utc: $(date -u +%FT%TZ)"; echo "signoff_mode: ${SIGNOFF_MODE:-text}"
  echo "worker_cli: agy $(agy_version)"
  echo "worker_models: low=$AGY_MODEL_LOW high=$AGY_MODEL_HIGH"
  echo; echo "## Commits (author ai-worker = Gemini qua agy, ai-lead = Claude)"; echo "$HIST"
} > "$EV/provenance.txt"
if [[ -f .ai/metrics.csv ]]; then { head -1 .ai/metrics.csv; grep -E "^[^,]*,$ID," .ai/metrics.csv; } > "$EV/metrics.csv"; fi
mkdir -p .ai/tasks/done; mv "$TASK" .ai/tasks/done/
for d in answers questions reviews; do [[ -f ".ai/$d/$ID.md" ]] && mv ".ai/$d/$ID.md" ".ai/tasks/done/$ID.$d.md"; done
git add -A docs/07-verification/records .ai/tasks .ai/reviews .ai/answers .ai/questions .ai/metrics.csv \
  || fail "Không stage được bằng chứng merge" 3
git diff --cached --quiet && fail "Không có bằng chứng mới để commit" 3
git commit -q -m "docs(records): $ID verification evidence" -m "Task: $ID" \
  || fail "Không commit được bằng chứng merge" 3
git ls-files --error-unmatch "$EV/provenance.txt" >/dev/null \
  || fail "Commit evidence không chứa provenance.txt" 3
rm -rf "$TMP"
git worktree remove --force "$WT" \
  || fail "Không xóa được worktree sau khi đã lưu evidence" 3
git branch -q -d "$BR" \
  || fail "Không xóa được branch $BR sau khi merge" 3
git update-ref -d "$BASEREF" \
  || fail "Không xóa được ref $BASEREF sau khi merge" 3
echo "✔ Đã merge $ID — bằng chứng: $EV"
