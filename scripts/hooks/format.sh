#!/usr/bin/env bash
# Claude Code PostToolUse hook: clang-format file C/C++ vừa sửa (không cần jq).
in="$(cat)"
f="$(printf '%s' "$in" | python -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null \
  || printf '%s' "$in" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)"
if [[ "$f" =~ \.(c|h|cc|cpp|hpp)$ ]] && command -v clang-format >/dev/null; then clang-format -i "$f"; fi
exit 0
