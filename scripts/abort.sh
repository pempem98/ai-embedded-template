#!/usr/bin/env bash
# Hủy task: xóa worktree + nhánh + base ref (dùng khi Lead quyết định tự làm hoặc chia nhỏ lại). Task card vẫn giữ.
set -uo pipefail
ID="${1:?Usage: abort.sh <ID>}"
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
git worktree remove --force "$WT" 2>/dev/null || true
git branch -q -D "$BR" 2>/dev/null || true
git update-ref -d "$BASEREF" 2>/dev/null || true
if [[ -f "$TASK" ]]; then load_task; record abort ABORTED 0 ""; fi
echo "✔ Đã hủy worktree/nhánh của $ID (task card, report, metrics vẫn giữ)"
