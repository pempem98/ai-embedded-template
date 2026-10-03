#!/usr/bin/env bash
# Giao 1 task card cho Gemini worker qua Antigravity CLI `agy` (git worktree riêng ../wt-<ID>, base lưu ở refs/ai/base/<ID>).
# Usage: scripts/delegate.sh <ID> [--resume] [--effort low|high]
# Exit:  0 DONE + scope + gate + trace PASS | 2 BLOCKED (có câu hỏi) | 3 DONE nhưng scope/gate/trace FAIL
#        4 FAILED / không có report / AI tự đổi HEAD-nhánh worktree không khôi phục được | 1 lỗi sử dụng / task card không hợp lệ / vượt MAX_REWORK
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
case "$EFFORT" in high) MODEL="$AGY_MODEL_HIGH" ;; low) MODEL="$AGY_MODEL_LOW" ;;
  *) echo "✖ effort phải là low|high"; exit 1 ;; esac
agy_preflight "$MODEL"

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
    AUTO+=" project-conventions naming-conventions design-clean-code logging-impl build-protocol unit-test traceability-tags"
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
if [[ -n "${PROTOS// /}" ]]; then
  AUTO+=" comm-safety"
  [[ " $PROTOS " == *" canopen "* && " $PROTOS " != *" can "* ]] && PROTOS+=" can"   # CANopen luôn cần tầng link CAN
  for p in $PROTOS; do AUTO+=" proto-$p"; done
  [[ " $PROTOS " == *" ethercat "* || " $PROTOS " == *" canopen "* ]] && AUTO+=" sync-control-impl"
fi
AUTO+=" effort-$EFFORT"

MISSING=""
for s in $AUTO $(echo "$SKILLS" | tr ',' ' '); do [[ -f ".agents/skills/$s/SKILL.md" ]] || MISSING+=" $s"; done
DECS=""
for d in $(field decisions | tr ',' ' '); do
  f="$(ls .ai/decisions/"$d"*.md 2>/dev/null | head -1)"; [[ -n "$f" ]] && DECS+=" $f" || MISSING+=" decision:$d"
done
[[ -n "$MISSING" ]] && { echo "✖ Task card tham chiếu skill/ADR không tồn tại:$MISSING"; exit 1; }

ensure_worktree
rm -f "$WT/.ai-out/report.md" "$WT/.ai-out/question.md" "$WT/.ai-out/prompt.md"

# ---- Ghép prompt ----
PROMPT_FILE=".ai/logs/$ID.prompt.md"
declare -A SEEN
{
  echo "# BẠN LÀ GEMINI WORKER của dự án thiết bị y tế (robot phẫu thuật). Thực thi ĐÚNG task, không tự quyết."
  for s in $AUTO $(echo "$SKILLS" | tr ',' ' '); do
    [[ -n "${SEEN[$s]:-}" ]] && continue; SEEN[$s]=1
    printf '\n\n<!-- ===== SKILL: %s ===== -->\n' "$s"; strip_fm ".agents/skills/$s/SKILL.md"
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
  echo "- Bạn KHÔNG có quyền chạy lệnh shell (build, test, git, python...), mạng, subagent, hay ghi đường dẫn được bảo vệ: hook"
  echo "  vsur-policy chặn (có thể kết thúc phiên). Đừng thử lách."
  echo "  Chỉ dùng công cụ đọc/tìm/sửa file. Sau khi bạn ghi report, delegate.sh tự chạy scope + gate (build, test, phân tích tĩnh,"
  echo "  coverage) + trace; nếu FAIL, kết quả được gửi lại cho bạn trong .ai-out/checks.txt (skill build-protocol)."
  echo "- delegate.sh tự commit sau mỗi round. Chỉ sửa file trong 'Files được phép' — script tự kiểm tra."
  [[ $RESUME -eq 1 ]] && echo "- Code các round trước ĐÃ có trong worktree. Chỉ làm phần Lead yêu cầu ở round mới nhất."
} > "$PROMPT_FILE"

cp "$PROMPT_FILE" "$WT/.ai-out/prompt.md"     # agy đọc prompt từ file trong worktree (.ai-out/ bị .gitignore)
rm -f "$WT/.ai-out/checks.txt" "$WT/.ai-out/gate.log"
TOOL_VER="agy $(agy_version)"
echo "▶ $ID | type=$TYPE platform=$PLATFORM class=${CLASS:-n/a} | effort=$EFFORT model=$MODEL autofix=$AUTOFIX resume=$RESUME round=$(round_no)"
SECONDS=0; GIT_VIOLATION=0; FEEDBACK=0; CID=""; REPORT="$WT/.ai-out/report.md"
MAX_FEEDBACK=0; is_code && MAX_FEEDBACK=$(( AUTOFIX + 1 ))   # lượt cuối chỉ để worker chuyển sang BLOCKED + question
MSG="Đọc TOÀN BỘ file .ai-out/prompt.md rồi thực hiện CHÍNH XÁC theo hướng dẫn trong đó. Kết thúc bằng việc ghi .ai-out/report.md."
while :; do
  head_snapshot
  agy_run "$MODEL" accept-edits ".ai/logs/$ID.log" "$MSG" "$CID"
  CID="${AGY_CID:-$CID}"
  [[ $AGY_RC -eq 124 ]] && echo "⚠ agy timeout sau ${AGY_TIMEOUT}s"
  head_guard || { record worker GIT_VIOLATION 4 "$MODEL"; exit 4; }
  if (( AGY_RC != 0 )); then
    echo "✖ agy kết thúc lỗi (rc=$AGY_RC), không chấp nhận report của lượt này."
    record worker AGY_FAILURE 4 "$MODEL"
    exit 4
  fi

  STATUS=""
  [[ -f "$REPORT" ]] && { cp "$REPORT" ".ai/reports/$ID.md"; STATUS="$(grep -m1 -oE '^STATUS:[[:space:]]*[A-Z]+' "$REPORT" | awk '{print $2}')"; }
  commit_round worker "${STATUS:-NO_REPORT}"     # lưu lịch sử mọi lượt, kể cả BLOCKED
  (( GIT_VIOLATION )) && echo "⚠ AI tự chạy lệnh git ghi (script đã gỡ commit, giữ nội dung) — ghi vào hồ sơ review"

  if [[ ! -f "$REPORT" ]]; then
    rm -f "$WT/.ai-out/prompt.md"
    echo "✖ Không có report (rc=$AGY_RC)."
    [[ -n "$AGY_DENIED" ]] && printf '  agy đã chặn (AI cố chạy lệnh/tool không được phép):\n%s' "$AGY_DENIED"
    record worker NO_REPORT 4 "$MODEL"; exit 4
  fi
  if [[ "$STATUS" == "BLOCKED" ]]; then
    rm -f "$WT/.ai-out/prompt.md"
    [[ -f "$WT/.ai-out/question.md" ]] && cp "$WT/.ai-out/question.md" ".ai/questions/$ID.md"
    echo "⏸ BLOCKED — câu hỏi (.ai/questions/$ID.md):"; head -40 ".ai/questions/$ID.md" 2>/dev/null || head -20 ".ai/reports/$ID.md"
    record worker BLOCKED 2 "$MODEL"; exit 2
  fi
  if [[ "$STATUS" != "DONE" ]]; then
    rm -f "$WT/.ai-out/prompt.md"
    echo "✖ STATUS=${STATUS:-?}"; head -20 ".ai/reports/$ID.md"
    record worker "${STATUS:-UNKNOWN}" 4 "$MODEL"; exit 4
  fi

  run_checks > "$WT/.ai-out/checks.txt" 2>&1; RC=$?
  (( RC == 0 || FEEDBACK >= MAX_FEEDBACK )) || [[ -z "$CID" ]] && break
  # Worker không tự build được (agy -p không cho chạy lệnh) → gửi kết quả kiểm tra lại cho worker trong cùng hội thoại
  FEEDBACK=$(( FEEDBACK + 1 ))
  cp ".ai/logs/$ID.gate" "$WT/.ai-out/gate.log" 2>/dev/null
  if (( FEEDBACK <= AUTOFIX )); then
    RULE="Còn lượt autofix ($FEEDBACK/$AUTOFIX): CHỈ sửa lỗi CƠ HỌC đúng điều kiện của skill build-protocol rồi cập nhật .ai-out/report.md (STATUS: DONE). Lỗi khác → KHÔNG sửa code; ghi .ai-out/question.md và report STATUS: BLOCKED."
  else
    RULE="HẾT lượt autofix (autofix_max=$AUTOFIX): KHÔNG sửa code. Ghi .ai-out/question.md (lỗi đã lọc, file:dòng, phương án A/B) và cập nhật .ai-out/report.md với STATUS: BLOCKED."
  fi
  echo "↻ scope/gate/trace FAIL → gửi kết quả cho worker (lượt phản hồi $FEEDBACK/$MAX_FEEDBACK)"
  MSG="delegate.sh đã chạy scope + gate + trace sau report của bạn: FAIL. Đọc .ai-out/checks.txt (tóm tắt) và .ai-out/gate.log (đầy đủ). $RULE Không chạy lệnh shell."
done
rm -f "$WT/.ai-out/prompt.md"

cat "$WT/.ai-out/checks.txt"
echo "■ Diff (git -C $WT diff $BASE HEAD -- <file>):"
git -C "$WT" diff --stat "$BASE" HEAD | tail -15
echo "■ Report: .ai/reports/$ID.md | HEAD: $HEAD_SHA | Phản hồi build: $FEEDBACK lượt | Kết quả: $([[ $RC -eq 0 ]] && echo PASS || echo FAIL)"
record worker DONE "$RC" "$MODEL"
exit $RC
