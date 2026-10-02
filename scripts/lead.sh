#!/usr/bin/env bash
# Code do Lead (Claude) tự viết (ISR, DMA, safety monitor, safe state, đồng bộ RT, startup/linker, scheduler/partition)
# đi qua CÙNG quy trình như code Gemini: worktree riêng → scope + gate + trace → review độc lập + cross-review → kỹ sư ký → merge.
# Task card phải có `owner: lead`.
# Usage: scripts/lead.sh start <ID>   → tạo ../wt-<ID>; Lead sửa code TRONG worktree đó
#        scripts/lead.sh finish <ID>  → commit (author ai-lead) + scope + gate + trace
# Exit:  0 PASS | 3 scope/gate/trace FAIL | 1 lỗi sử dụng / task card không hợp lệ
set -uo pipefail
CMD="${1:?Usage: lead.sh start|finish <ID>}"; ID="${2:?Usage: lead.sh start|finish <ID>}"
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
load_task
[[ "$OWNER" == lead ]] || { echo "✖ $TASK phải có owner: lead"; exit 1; }
validate_task

case "$CMD" in
  start)
    ensure_worktree
    echo "✔ Worktree: $WT (base ${BASE:0:10}). Chỉ sửa file trong 'Files được phép', xong chạy: ./scripts/lead.sh finish $ID"
    exit 0 ;;
  finish)
    [[ -d "$WT" ]] || { echo "✖ Chưa có worktree — chạy: ./scripts/lead.sh start $ID"; exit 1; }
    ensure_worktree; SECONDS=0
    commit_round lead DONE
    run_checks; RC=$?
    echo "■ Diff (git -C $WT diff $BASE HEAD -- <file>):"; git -C "$WT" diff --stat "$BASE" HEAD | tail -15
    TOOL_VER="claude-code"; EFFORT=high
    record lead DONE "$RC" "${CLAUDE_MODEL_ID:-claude}"
    echo "■ HEAD: $HEAD_SHA | Kết quả: $([[ $RC -eq 0 ]] && echo PASS || echo FAIL) — tiếp: /review $ID (bắt buộc cross-review)"
    exit $RC ;;
  *) echo "✖ Lệnh lạ: $CMD (start|finish)"; exit 1 ;;
esac
