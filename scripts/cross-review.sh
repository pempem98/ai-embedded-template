#!/usr/bin/env bash
# Review chéo bằng model KHÁC tác giả (Gemini HIGH) — đa dạng hóa reviewer cho code Lead viết (bắt buộc) và Class C (tùy chọn).
# Gemini chỉ đọc; kết quả lấy từ stdout; mọi thay đổi Gemini lỡ tạo trong worktree bị hoàn tác.
# Usage: scripts/cross-review.sh <ID>  → .ai/reports/<ID>.xreview.md
# Exit:  0 có kết quả | 4 không có kết quả hợp lệ | 1 lỗi sử dụng
set -uo pipefail
ID="${1:?Usage: cross-review.sh <ID>}"
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_task
[[ -d "$WT" ]] || { echo "✖ Không có worktree $WT"; exit 1; }
ensure_worktree
[[ -z "$(git -C "$WT" status --porcelain)" ]] \
  || { echo "✖ Worktree còn thay đổi chưa commit — chạy lead.sh finish / delegate trước khi cross-review"; exit 1; }

PROMPT=".ai/logs/$ID.xreview.prompt.md"
{
  echo "# BẠN LÀ REVIEWER ĐỘC LẬP (model khác tác giả). CHỈ ĐỌC — không tạo/sửa file, không chạy lệnh ghi."
  strip_fm .gemini/skills/cross-review/SKILL.md
  PROTOS="$(field protocols | tr ',' ' ')"
  if [[ -n "${PROTOS// /}" ]]; then
    strip_fm .gemini/skills/comm-safety/SKILL.md
    for p in $PROTOS; do [[ -f ".gemini/skills/proto-$p/SKILL.md" ]] && strip_fm ".gemini/skills/proto-$p/SKILL.md"; done
  fi
  DD="$(field detailed_design)"
  if [[ -n "$DD" && -f "$DD" ]]; then printf '\n\n# ===== DETAILED DESIGN (%s) =====\n' "$DD"; cat "$DD"; fi
  printf '\n\n# ===== TASK CARD (%s) =====\n' "$ID"; cat "$TASK"
  printf '\n\n# ===== DIFF (%s..HEAD) =====\n' "${BASE:0:10}"; git -C "$WT" diff "$BASE" HEAD
} > "$PROMPT"

OUT=".ai/reports/$ID.xreview.md"
echo "▶ cross-review $ID | model=$GEMINI_MODEL_HIGH | HEAD $(git -C "$WT" rev-parse --short HEAD)"
( cd "$WT" && timeout "$GEMINI_TIMEOUT" gemini -m "$GEMINI_MODEL_HIGH" \
    -p "Review theo hướng dẫn trong input. Chỉ in kết quả theo đúng định dạng, không sửa file." < "$ROOT/$PROMPT" ) \
  > "$OUT.tmp" 2> ".ai/logs/$ID.xreview.log"

if [[ -n "$(git -C "$WT" status --porcelain)" ]]; then
  echo "⚠ Gemini đã sửa worktree khi cross-review — hoàn tác:"; git -C "$WT" status --short | head -10
  git -C "$WT" checkout -q -- . && git -C "$WT" clean -fdq
fi
# Bỏ phần lời dẫn trước dòng XVERDICT
awk 'found || /^XVERDICT:/ {found=1; print}' "$OUT.tmp" > "$OUT"; rm -f "$OUT.tmp"
if ! grep -qE '^XVERDICT:[[:space:]]*(NO_FINDINGS|FINDINGS)' "$OUT"; then
  echo "✖ Không có kết quả hợp lệ (xem .ai/logs/$ID.xreview.log — người dùng đọc, Lead không đọc)"; exit 4
fi
echo "HEAD: $(git -C "$WT" rev-parse HEAD)" >> "$OUT"
head -30 "$OUT"
exit 0
