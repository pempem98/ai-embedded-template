#!/usr/bin/env bash
# Giao 1 task card cho Gemini worker (git worktree riêng ../wt-<ID>, base lưu ở refs/ai/base/<ID>).
# Usage: scripts/delegate.sh <ID> [--resume] [--effort low|high]
# Exit:  0 DONE + scope + gate + trace PASS | 2 BLOCKED (có câu hỏi) | 3 DONE nhưng scope/gate/trace FAIL
#        4 FAILED / không có report | 1 lỗi sử dụng / task card không hợp lệ / vượt MAX_REWORK
set -uo pipefail
ID="${1:?Usage: delegate.sh <ID> [--resume] [--effort low|high]}"; shift
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

RESUME=0; EFFORT=""
while [[ $# -gt 0 ]]; do case "$1" in
  --resume) RESUME=1 ;; --effort) EFFORT="${2:-}"; shift ;;
  *) echo "Tham số lạ: $1"; exit 1 ;; esac; shift; done

load_task
[[ "$OWNER" == lead ]] && { echo "✖ $ID có owner: lead — Lead tự làm qua ./scripts/lead.sh start|finish $ID"; exit 1; }
validate_task
[[ -z "$EFFORT" ]] && EFFORT="$(field effort)"; EFFORT="${EFFORT:-low}"
SKILLS="$(field skills)"
AUTOFIX="$(field autofix_max)"; AUTOFIX="${AUTOFIX:-$AUTOFIX_MAX_DEFAULT}"
[[ "$CLASS" == C ]] && is_code && { EFFORT=high; AUTOFIX=0; }      # Class C: luôn high, không tự sửa
case "$EFFORT" in high) MODEL="$GEMINI_MODEL_HIGH" ;; low) MODEL="$GEMINI_MODEL_LOW" ;;
  *) echo "✖ effort phải là low|high"; exit 1 ;; esac

if [[ $RESUME -eq 1 ]]; then
  N_RW="$(rework_count)"
  if (( N_RW > MAX_REWORK )); then
    echo "✖ $ID đã $N_RW vòng REWORK (> MAX_REWORK=$MAX_REWORK): ./scripts/abort.sh $ID rồi tự làm hoặc chia nhỏ."
    echo "  (Nâng MAX_REWORK là quyết định của người dùng.)"; exit 1
  fi
fi

# ---- Skill tự động theo type / platform / class / protocols (+ skill khai báo trong task) ----
AUTO="worker-protocol"
case "$TYPE" in
  implement|fix|test)
    AUTO+=" project-conventions naming-conventions build-protocol unit-test traceability-tags"
    case "$PLATFORM" in
      mcu)   AUTO+=" c-embedded-standard" ;;
      linux) AUTO+=" cpp-embedded-standard linux-rt-impl" ;;
      qnx)   AUTO+=" cpp-embedded-standard qnx-impl" ;;
      host)  AUTO+=" cpp-embedded-standard" ;;
    esac
    [[ "$CLASS" == B || "$CLASS" == C ]] && AUTO+=" safety-coding"
    case "$(field level)" in integration|hil) AUTO+=" integration-harness" ;; esac ;;
  research) AUTO+=" research" ;;
  doc)      AUTO+=" regulatory-doc-writer" ;;
esac
PROTOS="$(field protocols | tr ',' ' ')"
if [[ -n "${PROTOS// /}" ]]; then AUTO+=" comm-safety"; for p in $PROTOS; do AUTO+=" proto-$p"; done; fi
AUTO+=" effort-$EFFORT"

MISSING=""
for s in $AUTO $(echo "$SKILLS" | tr ',' ' '); do [[ -f ".gemini/skills/$s/SKILL.md" ]] || MISSING+=" $s"; done
DECS=""
for d in $(field decisions | tr ',' ' '); do
  f="$(ls .ai/decisions/"$d"*.md 2>/dev/null | head -1)"; [[ -n "$f" ]] && DECS+=" $f" || MISSING+=" decision:$d"
done
[[ -n "$MISSING" ]] && { echo "✖ Task card tham chiếu skill/ADR không tồn tại:$MISSING"; exit 1; }

ensure_worktree
rm -f "$WT/.ai-out/report.md" "$WT/.ai-out/question.md"

# ---- Ghép prompt ----
PROMPT_FILE=".ai/logs/$ID.prompt.md"
declare -A SEEN
{
  echo "# BẠN LÀ GEMINI WORKER của dự án thiết bị y tế (robot phẫu thuật). Thực thi ĐÚNG task, không tự quyết."
  for s in $AUTO $(echo "$SKILLS" | tr ',' ' '); do
    [[ -n "${SEEN[$s]:-}" ]] && continue; SEEN[$s]=1
    printf '\n\n<!-- ===== SKILL: %s ===== -->\n' "$s"; strip_fm ".gemini/skills/$s/SKILL.md"
  done
  for f in $DECS; do printf '\n\n# ===== QUYẾT ĐỊNH ĐÃ CHỐT (%s) =====\n' "$f"; cat "$f"; done
  DD="$(field detailed_design)"
  if [[ -n "$DD" && -f "$DD" ]]; then printf '\n\n# ===== DETAILED DESIGN (%s) =====\n' "$DD"; cat "$DD"; fi
  printf '\n\n# ===== TASK CARD (%s) =====\n' "$ID"; cat "$TASK"
  if [[ -f ".ai/answers/$ID.md" ]]; then
    printf '\n\n# ===== CHỈ ĐẠO TỪ LEAD (ưu tiên CAO HƠN task card; round mới nhất ưu tiên nhất) =====\n'
    cat ".ai/answers/$ID.md"
  fi
  printf '\n\n# ===== THAM SỐ PHIÊN =====\n- task_id: %s\n- type: %s\n- platform: %s\n- safety_class: %s\n- effort: %s\n- autofix_max: %s\n- resume: %s\n' \
    "$ID" "$TYPE" "$PLATFORM" "${CLASS:-n/a}" "$EFFORT" "$AUTOFIX" "$RESUME"
  printf -- '- Lệnh build nhanh: ./scripts/gate.sh --build-only --platform %s --class %s\n' "$PLATFORM" "${CLASS:-A}"
  printf -- '- Lệnh gate đầy đủ: ./scripts/gate.sh --platform %s --class %s --base %s\n' "$PLATFORM" "${CLASS:-A}" "$BASE"
  echo "- KHÔNG git commit/push/reset: delegate.sh tự commit sau mỗi round. Chỉ sửa file trong 'Files được phép' — script tự kiểm tra."
  [[ $RESUME -eq 1 ]] && echo "- Code các round trước ĐÃ có trong worktree. Chỉ làm phần Lead yêu cầu ở round mới nhất."
} > "$PROMPT_FILE"

TOOL_VER="gemini-cli $(gemini --version 2>/dev/null | head -1)"
SANDBOX=(); [[ -n "${GEMINI_SANDBOX:-}" ]] && SANDBOX=(--sandbox)
echo "▶ $ID | type=$TYPE platform=$PLATFORM class=${CLASS:-n/a} | effort=$EFFORT model=$MODEL autofix=$AUTOFIX resume=$RESUME round=$(round_no)"
SECONDS=0
( cd "$WT" && timeout "$GEMINI_TIMEOUT" gemini -m "$MODEL" --yolo "${SANDBOX[@]}" \
    -p "Thực hiện CHÍNH XÁC theo hướng dẫn trong input. Kết thúc bằng việc ghi .ai-out/report.md." \
    < "$ROOT/$PROMPT_FILE" ) > ".ai/logs/$ID.log" 2>&1
GEM_RC=$?
[[ $GEM_RC -eq 124 ]] && echo "⚠ Gemini timeout sau ${GEMINI_TIMEOUT}s"

REPORT="$WT/.ai-out/report.md"
STATUS=""
[[ -f "$REPORT" ]] && { cp "$REPORT" ".ai/reports/$ID.md"; STATUS="$(grep -m1 -oE '^STATUS:[[:space:]]*[A-Z]+' "$REPORT" | awk '{print $2}')"; }
commit_round worker "${STATUS:-NO_REPORT}"     # lưu lịch sử mọi round, kể cả BLOCKED

if [[ ! -f "$REPORT" ]]; then
  echo "✖ Không có report (rc=$GEM_RC). 5 dòng cuối log:"; tail -5 ".ai/logs/$ID.log"
  record worker NO_REPORT 4 "$MODEL"; exit 4
fi
if [[ "$STATUS" == "BLOCKED" ]]; then
  [[ -f "$WT/.ai-out/question.md" ]] && cp "$WT/.ai-out/question.md" ".ai/questions/$ID.md"
  echo "⏸ BLOCKED — câu hỏi (.ai/questions/$ID.md):"; head -40 ".ai/questions/$ID.md" 2>/dev/null || head -20 ".ai/reports/$ID.md"
  record worker BLOCKED 2 "$MODEL"; exit 2
fi
if [[ "$STATUS" != "DONE" ]]; then
  echo "✖ STATUS=${STATUS:-?}"; head -20 ".ai/reports/$ID.md"
  record worker "${STATUS:-UNKNOWN}" 4 "$MODEL"; exit 4
fi

run_checks; RC=$?
echo "■ Diff (git -C $WT diff $BASE HEAD -- <file>):"
git -C "$WT" diff --stat "$BASE" HEAD | tail -15
echo "■ Report: .ai/reports/$ID.md | HEAD: $HEAD_SHA | Kết quả: $([[ $RC -eq 0 ]] && echo PASS || echo FAIL)"
record worker DONE "$RC" "$MODEL"
exit $RC
