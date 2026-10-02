#!/usr/bin/env bash
# Bảng trạng thái ngắn (≤ ~15 dòng) — SessionStart hook và /status. Không đọc log.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
  || { echo "## Trạng thái AI team: chưa là git repo — git init + commit template trước khi /delegate"; exit 0; }
cd "$ROOT" || exit 0
# shellcheck disable=SC1091
source .ai/config.env 2>/dev/null
shopt -s nullglob
tasks=(.ai/tasks/*.md)
echo "## Trạng thái AI team ($(git rev-parse --abbrev-ref HEAD 2>/dev/null))"
if (( ${#tasks[@]} == 0 )); then echo "- Không có task mở."; fi
for t in "${tasks[@]}"; do
  id="$(basename "$t" .md)"
  g() { grep -m1 -E "^$1:" "$t" | sed -E "s/^$1:[[:space:]]*//; s/[[:space:]]*#.*$//"; }
  cls="$(g safety_class)"; own="$(g owner)"; rev=".ai/reviews/$id.md"; st="chưa bắt đầu"
  [[ -d "$(dirname "$ROOT")/wt-$id" ]] && st="đang làm (worktree)"
  [[ -f ".ai/reports/$id.md" ]] && st="có report → /review"
  if [[ -f ".ai/questions/$id.md" ]] && { [[ ! -f ".ai/answers/$id.md" ]] || [[ ".ai/questions/$id.md" -nt ".ai/answers/$id.md" ]]; }; then
    st="BLOCKED → /answer"
  fi
  if [[ -f "$rev" ]]; then
    if grep -qE '^HUMAN_DECISION:[[:space:]]*APPROVED' "$rev"; then st="đã ký → ./scripts/merge.sh $id"
    elif [[ " ${HUMAN_SIGNOFF_CLASSES:-B C} " == *" $cls "* ]]; then st="CHỜ KỸ SƯ KÝ $rev"
    else st="review xong → ./scripts/merge.sh $id"; fi
  fi
  echo "- $id [class ${cls:--}${own:+, owner $own}] $st"
done | head -12
anoms=(docs/09-problem-resolution/ANOM-*.md)
if (( ${#anoms[@]} )); then
  open=0; for a in "${anoms[@]}"; do grep -qiE '^(Status|Trạng thái):[[:space:]]*Closed' "$a" || open=$((open+1)); done
  echo "- Anomaly mở: $open / ${#anoms[@]}"
fi
exit 0
