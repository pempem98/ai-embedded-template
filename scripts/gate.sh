#!/usr/bin/env bash
# Máy chấm theo nền tảng + safety class. Chỉ in lỗi đã lọc.
# Usage: scripts/gate.sh [--build-only] [--platform host|mcu|linux|qnx] [--class A|B|C]
#                        [--base <sha>] [--scope "<file|thư mục> ..."] [--full]
# Phạm vi cho banned-check / phân tích tĩnh / coverage (ngưỡng KHÔNG đổi, chỉ đổi tập file được chấm):
#   --full          toàn bộ mã nguồn (release-check: chạy theo từng SI với --scope)
#   --scope "..."   file/thư mục chỉ định (+ file thay đổi nếu có --base); coverage chỉ tính trên --scope
#   --base <sha>    file nguồn thay đổi so với <sha> (delegate/lead/merge truyền base của task)
#   (mặc định)      file nguồn thay đổi so với HEAD + file mới chưa track
# Phân loại file theo config: SRC_DIRS_RX (production) · TEST_DIRS_RX (test) · EXCLUDE_RX (sinh tự động/submodule/SOUP).
# Code không thuộc nhóm nào → [layout] FAIL (tránh PASS rỗng khi đổi bố cục repo).
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

# Bố cục mã nguồn lấy từ config (polyrepo/monorepo đều được); giá trị mặc định cho config cũ chưa có khóa.
EXT_RX='\.(c|cc|cpp|cxx|h|hh|hpp|hxx)$'; TU_RX='\.(c|cc|cpp|cxx)$'
SRC_DIRS_RX="${SRC_DIRS_RX:-^(src|inc|include)/}"
TEST_DIRS_RX="${TEST_DIRS_RX:-^(test|tests|unittest|unit_test|integration_test)/}"
EXCLUDE_RX="${EXCLUDE_RX:-^(build|gen|generated|external|third_party)/}"
code_only() { grep -E "$EXT_RX" | grep -vE "$EXCLUDE_RX" | sort -u || true; }
pick() { grep -E "$1" <<<"$2" || true; }          # $1 regex, $2 danh sách
drop() { grep -vE "$1" <<<"$2" | grep -v '^$' || true; }
ALL_PROD="$(git ls-files | code_only | grep -E "$SRC_DIRS_RX" || true)"
if [[ $FULL -eq 1 ]]; then
  CAND="$(git ls-files | code_only)"; MODE=full
else
  CHANGED="$( { git diff --name-only --diff-filter=d "${BASE:-HEAD}"; git ls-files --others --exclude-standard; } | code_only)"
  SCOPED=""
  # shellcheck disable=SC2086
  [[ -n "$SCOPE" ]] && SCOPED="$(git ls-files --cached --others --exclude-standard -- $SCOPE | code_only)"
  CAND="$(printf '%s\n%s\n' "$CHANGED" "$SCOPED" | grep -v '^$' | sort -u || true)"
  MODE="${BASE:+base:${BASE:0:10}}"; MODE="${MODE:-HEAD}"; [[ -n "$SCOPE" ]] && MODE+="+scope"
fi
PROD="$(pick "$SRC_DIRS_RX" "$CAND")"
TESTS="$(pick "$TEST_DIRS_RX" "$(drop "$SRC_DIRS_RX" "$CAND")")"
# Code nằm ngoài mọi thư mục đã khai báo → gate sẽ chấm rỗng (PASS giả) → FAIL ngay
UNCLASSIFIED="$(drop "$SRC_DIRS_RX|$TEST_DIRS_RX" "$CAND")"
FILES="$(printf '%s\n%s\n' "$PROD" "$TESTS" | grep -v '^$' || true)"
if [[ $FULL -eq 1 ]]; then COV_FILES="$PROD"
elif [[ -n "$SCOPE" ]]; then COV_FILES="$(pick "$SRC_DIRS_RX" "$SCOPED")"
else COV_FILES="$(pick "$SRC_DIRS_RX" "$CHANGED")"; fi
# Phân tích tĩnh cần translation unit: header production đổi → chấm mọi TU production (bắt lỗi trong inline/template)
SRCS="$(pick "$TU_RX" "$PROD")"; LINT_NOTE=""
if [[ $FULL -eq 0 && -n "$(drop "$TU_RX" "$PROD")" ]]; then
  SRCS="$(pick "$TU_RX" "$ALL_PROD")"; LINT_NOTE=" (header đổi → lint mọi TU production)"
fi
quote_list() {
  local out="" f quoted
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    printf -v quoted '%q' "$f"
    out+=" $quoted"
  done <<< "$1"
  echo "${out# }"
}
COV_FILTER=""
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  printf -v quoted '%q' "$f"
  COV_FILTER+=" --filter $quoted"
done <<< "$COV_FILES"
echo "gate: platform=$PLATFORM class=$CLASS scope=$MODE prod=$(grep -c . <<<"$PROD") test=$(grep -c . <<<"$TESTS") lint_tu=$(grep -c . <<<"$SRCS")$LINT_NOTE"
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
if [[ -n "$UNCLASSIFIED" ]]; then
  echo "[layout] FAIL (code ngoài SRC_DIRS_RX/TEST_DIRS_RX/EXCLUDE_RX — sửa bố cục hoặc config, không để gate chấm rỗng)"
  head -n "${GATE_TAIL:-20}" <<<"$UNCLASSIFIED" | sed 's/^/  /'; rc=1
fi
bvar="BUILD_CMD_${PLATFORM}"
run "build:$PLATFORM" "${!bvar:-}"
# Logic luôn phải build + test được trên host
[[ "$PLATFORM" != host ]] && run "build:host" "${BUILD_CMD_host:-}"
[[ $BUILD_ONLY -eq 1 || $rc -ne 0 ]] && exit $rc

run test "$TEST_CMD"
# Sanitizer chạy unit test host (ASan+UBSan, TSan) — bắt data race/UB mà review khó thấy. Không có trên MinGW/MSYS.
if [[ "$CLASS" == B || "$CLASS" == C ]]; then
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      if [[ "${REQUIRE_SAN:-0}" == 1 ]]; then echo "[sanitizer] FAIL (REQUIRE_SAN=1 — chạy gate trên Linux/WSL)"; rc=1
      else echo "[sanitizer] SKIP (Windows host — chạy trên Linux/WSL)"; fi ;;
    *) run asan-ubsan "${SAN_CMD:-}" "${REQUIRE_SAN:-0}"; run tsan "${TSAN_CMD:-}" "${REQUIRE_SAN:-0}" ;;
  esac
fi
# Banned API: production theo class/platform; test chỉ luật chung (test được dùng container/new của GoogleTest)
BANNED="$PYTHON '$SELF/scripts/check_banned.py' --dev-dir '$SELF/.ai/deviations'"
if [[ -n "$PROD" ]]; then run banned "$BANNED --class $CLASS --platform $PLATFORM --files $(quote_list "$PROD")"
else echo "[banned] SKIP (không có file production trong phạm vi)"; fi
[[ -n "$TESTS" ]] && run banned:test "$BANNED --class A --platform host --files $(quote_list "$TESTS")"
if [[ "$CLASS" == B || "$CLASS" == C ]]; then
  run cppcheck "$LINT_CMD"
  run clang-tidy "$TIDY_CMD"
  run misra "$MISRA_CMD" "${REQUIRE_MISRA:-0}"
fi
[[ "$CLASS" == B ]] && run coverage "$COV_CMD_B"
[[ "$CLASS" == C ]] && { run coverage "$COV_CMD_C"; run mcdc "$MCDC_CMD" "${REQUIRE_MCDC:-0}"; }
exit $rc
