#!/usr/bin/env python3
"""Claude Code PreToolUse hook — chặn AI tự điền phần phê duyệt của con người và sửa hồ sơ đã lưu.
Exit 2 = chặn (stderr được gửi lại cho Claude). Đây là lớp phòng ngừa; lớp quyết định là SIGNOFF_MODE=gpg trong merge.sh."""
import json, re, sys

FILLED = re.compile(r"^\s*(HUMAN_(REVIEWER|DECISION|DATE)|APPROVED_BY|APPROVED_DATE)\s*:\s*[^<\s]", re.M)
# Trong lệnh shell: giá trị đã điền (không phải placeholder <...> hay pattern grep [[:space:]]...)
FILLED_CMD = re.compile(r"(HUMAN_(REVIEWER|DECISION|DATE)|APPROVED_BY|APPROVED_DATE)\s*:\s*[^<\s'\"\[\]\\*.(|]")
APPROVED_STATUS = re.compile(r"^\s*(Status|Trạng thái)\s*:\s*Approved\b", re.M | re.I)
WRITE_CMD = re.compile(r">|\btee\b|sed\s+-i|perl\s+-i|python|printf|echo|Set-Content|Out-File|Add-Content")


def block(msg):
    print(f"⛔ guard: {msg} — việc này do con người làm (CLAUDE.md 'Không bao giờ').", file=sys.stderr)
    sys.exit(2)


def main():
    try:
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass
    try:
        d = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    tool, ti = d.get("tool_name", ""), d.get("tool_input", {}) or {}
    if tool == "Bash":
        cmd = ti.get("command", "")
        if FILLED_CMD.search(cmd) and WRITE_CMD.search(cmd):
            block("lệnh shell ghi trường phê duyệt của con người")
        if "docs/07-verification/records" in cmd and re.search(r"\brm\b|sed\s+-i|>|\bmv\b|\bcp\b", cmd):
            block("sửa bằng chứng đã lưu trong docs/07-verification/records")
        sys.exit(0)
    path = (ti.get("file_path") or ti.get("notebook_path") or "").replace("\\", "/")
    texts = [ti.get("content") or "", ti.get("new_string") or ""] + \
            [(e or {}).get("new_string") or "" for e in (ti.get("edits") or [])]
    if "/docs/07-verification/records/" in path or path.startswith("docs/07-verification/records/"):
        block("sửa bằng chứng đã lưu trong docs/07-verification/records (chỉ merge.sh ghi)")
    if any(FILLED.search(t) for t in texts):
        block("điền HUMAN_REVIEWER/HUMAN_DECISION/HUMAN_DATE/APPROVED_BY")
    if path.endswith(".md") and "/docs/" in path and any(APPROVED_STATUS.search(t) for t in texts):
        block("đặt trạng thái tài liệu = Approved")
    sys.exit(0)


if __name__ == "__main__":
    main()
