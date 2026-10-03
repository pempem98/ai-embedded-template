#!/usr/bin/env bash
# Review chéo bằng model KHÁC tác giả (AGY_MODEL_HIGH qua Antigravity CLI `agy`) — đa dạng hóa reviewer cho code Lead viết (bắt buộc) và Class C (tùy chọn).
# Reviewer chỉ đọc; chạy agy --mode plan, kết quả lấy từ response (stream-json); mọi thay đổi lỡ tạo trong worktree bị hoàn tác.
# Usage: scripts/cross-review.sh <ID>  → .ai/reports/<ID>.xreview.md
# Exit:  0 có kết quả | 4 không có kết quả hợp lệ | 1 lỗi sử dụng
set -uo pipefail
ID="${1:?Usage: cross-review.sh <ID>}"
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_task
agy_preflight "$AGY_MODEL_HIGH"
# agy phục vụ cả model Claude → chặn để review chéo thực sự khác họ model với Lead (Claude)
if [[ "${AGY_MODEL_HIGH,,}" == *claude* ]]; then
  echo "✖ AGY_MODEL_HIGH=$AGY_MODEL_HIGH là model Claude — cross-review phải dùng model khác họ với Lead"; exit 1
fi
[[ -d "$WT" ]] || { echo "✖ Không có worktree $WT"; exit 1; }
ensure_worktree
[[ -z "$(git -C "$WT" status --porcelain)" ]] \
  || { echo "✖ Worktree còn thay đổi chưa commit — chạy lead.sh finish / delegate trước khi cross-review"; exit 1; }

PROMPT=".ai/logs/$ID.xreview.prompt.md"
{
  echo "# BẠN LÀ REVIEWER ĐỘC LẬP (model khác tác giả). CHỈ ĐỌC — không tạo/sửa file, không chạy lệnh shell (chỉ dùng công cụ đọc/tìm file)."
  strip_fm .agents/skills/cross-review/SKILL.md
  PROTOS="$(field protocols | tr ',' ' ')"
  if [[ -n "${PROTOS// /}" ]]; then
    strip_fm .agents/skills/comm-safety/SKILL.md
    for p in $PROTOS; do [[ -f ".agents/skills/proto-$p/SKILL.md" ]] && strip_fm ".agents/skills/proto-$p/SKILL.md"; done
  fi
  DD="$(field detailed_design)"
  if [[ -n "$DD" && -f "$DD" ]]; then printf '\n\n# ===== DETAILED DESIGN (%s) =====\n' "$DD"; cat "$DD"; fi
  printf '\n\n# ===== TASK CARD (%s) =====\n' "$ID"; cat "$TASK"
  printf '\n\n# ===== DIFF (%s..HEAD) =====\n' "${BASE:0:10}"; git -C "$WT" diff "$BASE" HEAD
} > "$PROMPT"

OUT=".ai/reports/$ID.xreview.md"
cp "$PROMPT" "$WT/.ai-out/xreview.prompt.md"
echo "▶ cross-review $ID | model=$AGY_MODEL_HIGH | HEAD $(git -C "$WT" rev-parse --short HEAD)"
LOG=".ai/logs/$ID.xreview.log"; : > "$LOG"
head_snapshot
agy_run "$AGY_MODEL_HIGH" plan "$LOG" \
  "Đọc TOÀN BỘ file .ai-out/xreview.prompt.md (dùng công cụ đọc file; KHÔNG chạy lệnh shell — mọi lệnh bị chặn) và review theo hướng dẫn trong đó. Trả lời bằng văn bản đúng định dạng, dòng đầu là XVERDICT:. Không tạo/sửa file."
XRC=$?
agy_field "$LOG" response > "$OUT.tmp"
rm -f "$WT/.ai-out/xreview.prompt.md"

head_guard || { echo "✖ Worktree bị đổi HEAD/nhánh khi cross-review — Lead kiểm tra trước khi review tiếp"; exit 4; }
if (( XRC != 0 )); then rm -f "$OUT.tmp"; echo "✖ agy kết thúc lỗi (rc=$XRC) — không dùng kết quả cross-review lượt này"; exit 4; fi
if [[ -n "$(git -C "$WT" status --porcelain)" ]]; then
  echo "⚠ Reviewer đã sửa worktree khi cross-review — hoàn tác:"; git -C "$WT" status --short | head -10
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
