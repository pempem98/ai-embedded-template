#!/usr/bin/env bash
# Wrapper PreToolUse: chạy guard.py bằng python có sẵn (Windows: python, Linux/WSL: python3).
d="$(dirname "${BASH_SOURCE[0]}")"
if command -v python >/dev/null 2>&1; then exec python "$d/guard.py"; else exec python3 "$d/guard.py"; fi
