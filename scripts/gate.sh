#!/usr/bin/env bash
# Máy chấm theo nền tảng + safety class. Chỉ in lỗi đã lọc.
# Usage: scripts/gate.sh [--build-only] [--platform host|mcu|linux|qnx] [--class A|B|C]
#                        [--base <sha>] [--scope "<file|thư mục> ..."] [--full]
# Phạm vi cho banned-check / phân tích tĩnh / coverage (ngưỡng KHÔNG đổi, chỉ đổi tập file được chấm):
#   --full          toàn bộ mã nguồn (release-check: chạy theo từng SI với --scope)
#   --scope "..."   file/thư mục chỉ định (+ file thay đổi nếu có --base); coverage chỉ tính trên --scope
#   --base <sha>    file nguồn thay đổi so với <sha> (delegate/lead/merge truyền base của task)
#   (mặc định)      file nguồn thay đổi so với HEAD + file mới chưa track
# Build & test luôn chạy toàn bộ. Config và check_banned lấy từ repo CHỨA script này
# (delegate/merge gọi script của repo chính → worktree không thể tự nới gate).
set -uo pipefail
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$(git rev-parse --show-toplevel)" || exit 1
# shellcheck disable=SC1091
source "$SELF/.ai/config.env"
if ! command -v "$PYTHON" >/dev/null 2>&1; then
  echo "gate: FAIL — không tìm thấy PYTHON='$PYTHON' trong PATH của shell này (cài Python hoặc sửa .ai/config.env)"
  exit 1
fi
BUILD_ONLY=0; PLATFORM=host; CLASS=B; BASE=""; SCOPE=""; FULL=0
while [[ $# -gt 0 ]]; do case "$1" in
  --build-only) BUILD_ONLY=1 ;;
  --platform) PLATFORM="$2"; shift ;;
  --class) CLASS="$2"; shift ;;
  --base) BASE="$2"; shift ;;
  --scope) SCOPE="$2"; shift ;;
  --full) FULL=1 ;;
  *) echo "Tham số lạ: $1"; exit 1 ;; esac; shift; done

SRC_RX='^(src|inc|include)/.*\.(c|cc|cpp|h|hpp)$'
CODE_RX='^(src|inc|include|test|tests|unittest|unit_test|integration_test)/.*\.(c|cc|cpp|h|hpp)$'
if [[ $FULL -eq 1 ]]; then
  FILES="$(git ls-files | grep -E "$CODE_RX")"; COV_FILES="$(git ls-files | grep -E "$SRC_RX")"; MODE=full
else
  CHANGED="$( { git diff --name-only --diff-filter=d "${BASE:-HEAD}"; git ls-files --others --exclude-standard; } \
              | grep -E "$CODE_RX" | sort -u)"
  SCOPED=""
  # shellcheck disable=SC2086
  [[ -n "$SCOPE" ]] && SCOPED="$(git ls-files --cached --others --exclude-standard -- $SCOPE | grep -E "$CODE_RX" | sort -u)"
  FILES="$(printf '%s\n%s\n' "$CHANGED" "$SCOPED" | grep -v '^$' | sort -u)"
  if [[ -n "$SCOPE" ]]; then COV_FILES="$(grep -E "$SRC_RX" <<<"$SCOPED" || true)"; else COV_FILES="$(grep -E "$SRC_RX" <<<"$CHANGED" || true)"; fi
  MODE="${BASE:+base:${BASE:0:10}}"; MODE="${MODE:-HEAD}"; [[ -n "$SCOPE" ]] && MODE+="+scope"
fi
SRCS="$(grep -E "$SRC_RX" <<<"$FILES" | grep -E '\.(c|cc|cpp)$' || true)"
quote_list() {
  local out="" f quoted
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    printf -v quoted '%q' "$f"
    out+=" $quoted"
  done <<< "$1"
  echo "${out# }"
}
if [[ $FULL -eq 1 ]]; then COV_FILTER="--filter src/"
else
  COV_FILTER=""
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    printf -v quoted '%q' "$f"
    COV_FILTER+=" --filter $quoted"
  done <<< "$COV_FILES"
fi
echo "gate: platform=$PLATFORM class=$CLASS scope=$MODE files=$(grep -c . <<<"$FILES")"
tool_version() {
  local tool="$1" version
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool=NOT_FOUND"
    return
  fi
  version="$($tool --version 2>&1 | head -1 || true)"
  echo "$tool=${version:-UNKNOWN}"
}
echo "toolchain: python=$($PYTHON --version 2>&1 | head -1)"
tool_version cmake
tool_version cppcheck
tool_version clang-tidy
tool_version gcovr

rc=0
run() {
  local name="$1" cmd="$2" required="${3:-0}"
  if [[ "$cmd" == *"{FILES}"* && -z "${FILES//[[:space:]]/}" ]] || [[ "$cmd" == *"{SRCS}"* && -z "${SRCS//[[:space:]]/}" ]] \
     || [[ "$cmd" == *"{COV_FILTER}"* && -z "${COV_FILTER// /}" ]]; then
    echo "[$name] SKIP (không có file nguồn trong phạm vi)"; return
  fi
  if [[ -z "$cmd" ]]; then
    if [[ "$required" == 1 ]]; then echo "[$name] FAIL (chưa cấu hình)"; rc=1
    else echo "[$name] SKIP (chưa cấu hình)"; fi
    return
  fi
  cmd="${cmd//"{FILES}"/"$(quote_list "$FILES")"}"; cmd="${cmd//"{SRCS}"/"$(quote_list "$SRCS")"}"
  cmd="${cmd//"{COV_FILTER}"/"$COV_FILTER"}"
  local out
  if out="$(eval "$cmd" 2>&1)"; then echo "[$name] PASS"
  else echo "[$name] FAIL"; rc=1
    echo "$out" | grep -E "error|warning|FAIL|Error|undefined|Assert|expected|violation|below|lines:|branches:" | head -n "${GATE_TAIL:-20}"
  fi
}
bvar="BUILD_CMD_${PLATFORM}"
run "build:$PLATFORM" "${!bvar:-}"
# Logic luôn phải build + test được trên host
[[ "$PLATFORM" != host ]] && run "build:host" "${BUILD_CMD_host:-}"
[[ $BUILD_ONLY -eq 1 || $rc -ne 0 ]] && exit $rc

run test "$TEST_CMD"
# shellcheck disable=SC2086
run banned "$PYTHON '$SELF/scripts/check_banned.py' --class $CLASS --platform $PLATFORM --dev-dir '$SELF/.ai/deviations' --files {FILES}"
if [[ "$CLASS" == B || "$CLASS" == C ]]; then
  run cppcheck "$LINT_CMD"
  run clang-tidy "$TIDY_CMD"
  run misra "$MISRA_CMD" "${REQUIRE_MISRA:-0}"
fi
[[ "$CLASS" == B ]] && run coverage "$COV_CMD_B"
[[ "$CLASS" == C ]] && { run coverage "$COV_CMD_C"; run mcdc "$MCDC_CMD" "${REQUIRE_MCDC:-0}"; }
exit $rc
