#!/usr/bin/env python3
"""PreToolUse hook của Antigravity (agy) — chính sách tool cấp WORKSPACE, nằm trong repo (không phụ thuộc ~/.gemini của từng máy).
Đăng ký trong .agents/hooks.json; agy chạy với cwd = .agents/, payload JSON qua stdin, quyết định JSON qua stdout.

Hành vi agy đã kiểm chứng (1.2.15): thiếu/không đọc được quyết định → tool bị CHẶN (fail-closed); "deny" chặn cứng nhưng phiên
chạy tiếp (AI nhận lý do); ở chế độ -p, "allow" KHÔNG cấp được quyền chạy lệnh shell (issue #548) nhưng có hiệu lực với đọc/ghi file.

Vai trò lấy từ biến môi trường VSUR_AGY_ROLE (scripts/lib.sh đặt khi gọi agy):
  worker   — delegate.sh: đọc trong repo; ghi trong repo trừ đường dẫn bảo vệ / file `OWNER: lead`; KHÔNG lệnh shell, mạng, subagent
  reviewer — cross-review.sh: chỉ đọc
  (trống)  — người dùng chạy agy tương tác trong repo: đọc → allow; ghi/lệnh/mạng → ask; luôn chặn lệnh git ghi và rm -rf
Mọi quyết định deny của vai trò script được ghi vào .ai-out/hook.log (bằng chứng cho review).
"""
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]          # <repo|worktree>/.agents/hooks/vsur_policy.py
sys.path.insert(0, str(ROOT / "scripts"))
try:
    from check_scope import protected                # một nguồn duy nhất cho danh sách đường dẫn được bảo vệ
except Exception:                                    # thiếu check_scope → coi mọi thứ ngoài src/inc/include/test/docs là bảo vệ
    def protected(path):
        return not re.match(r"^(src|inc|include|test|tests|docs)/", path)

ROLE = os.environ.get("VSUR_AGY_ROLE", "").strip().lower()
SCRIPTED = ROLE in ("worker", "reviewer")

READ_TOOLS = {"view_file", "list_dir", "grep_search", "find_by_name", "command_status", "list_permissions",
              "list_resources", "read_resource", "wait", "wait_5_seconds", "finish", "ask_question", "manage_task"}
WRITE_TOOLS = {"write_to_file", "replace_file_content", "multi_replace_file_content", "sed_file", "notebook_edit"}
COMMAND_TOOLS = {"run_command", "send_command_input", "notebook_execution"}
# Còn lại (browser_*, read_url_content, search_web, call_mcp_tool, subagent, schedule, send_message...) → mạng/ngoài phạm vi

GIT_WRITE = re.compile(r"\bgit(\.exe)?\b.*\b(commit|push|pull|fetch|reset|checkout|switch|restore|rebase|merge|stash|clean|"
                       r"branch|tag|worktree|update-ref|symbolic-ref|cherry-pick|revert|am|apply|config|gc|prune|remote|"
                       r"submodule|filter-branch|replace|notes|add|rm|mv)\b", re.I)
RM_RF = re.compile(r"(\brm\s+-[a-z]*[rf]|Remove-Item\b.*-Recurse|\brmdir\s+/s|\brd\s+/s|\bdel\s+/s)", re.I)


def rel(p):
    """Đường dẫn tương đối so với ROOT (dạng a/b/c), hoặc None nếu nằm ngoài repo/worktree."""
    try:
        q = Path(p) if os.path.isabs(p) else ROOT / p
        r = os.path.relpath(os.path.normcase(os.path.abspath(q)), os.path.normcase(str(ROOT)))
    except ValueError:                               # khác ổ đĩa trên Windows
        return None
    r = r.replace("\\", "/")
    return None if r == ".." or r.startswith("../") else r


def paths(args):
    return [v for k, v in args.items() if isinstance(v, str) and v and ("Path" in k or "File" in k or k == "Directory")]


def owner_lead(r):
    try:
        with open(ROOT / r, encoding="utf-8", errors="replace") as f:
            return any("OWNER: lead" in f.readline() for _ in range(5))
    except OSError:
        return False


def decide(name, args):
    if name in READ_TOOLS:
        for p in paths(args):
            if rel(p) is None:
                return "deny" if SCRIPTED else "ask", f"đọc ngoài repo: {p}"
        return "allow", ""
    if name in WRITE_TOOLS:
        if ROLE == "reviewer":
            return "deny", "reviewer chỉ đọc"
        for p in paths(args):
            r = rel(p)
            if r is None:
                return "deny", f"ghi ngoài repo/worktree: {p}"
            if r.startswith(".ai-out/"):
                continue
            if protected(r) or r.startswith(".git/"):
                return ("deny" if SCRIPTED else "ask"), f"đường dẫn được bảo vệ: {r}"
            if owner_lead(r):
                return ("deny" if SCRIPTED else "ask"), f"file OWNER: lead: {r}"
        return ("allow" if ROLE == "worker" else "ask"), ""
    if name in COMMAND_TOOLS:
        cmd = str(args.get("CommandLine", ""))
        if GIT_WRITE.search(cmd):
            return "deny", "lệnh git ghi bị cấm — script tự commit"
        if RM_RF.search(cmd):
            return "deny", "xóa đệ quy bị cấm"
        if SCRIPTED:
            return "deny", "không có quyền chạy lệnh shell; build/test/gate do script chạy sau report — chỉ đọc/sửa file"
        return "ask", ""
    return ("deny" if SCRIPTED else "ask"), f"tool {name} ngoài phạm vi (mạng/ngoài/subagent)"


def main():
    try:
        d = json.load(sys.stdin)
        tc = d.get("toolCall") or {}
        name, args = tc.get("name", ""), tc.get("args") or {}
        decision, reason = decide(name, args)
    except Exception as e:                           # lỗi hook → chặn (fail-closed), không đoán
        name, args, decision, reason = "?", {}, "deny", f"hook lỗi: {e}"
    out = {"decision": decision}
    if reason:
        out["reason"] = f"[vsur-policy] {reason}"
    if decision == "deny" and SCRIPTED:
        try:
            (ROOT / ".ai-out").mkdir(exist_ok=True)
            with open(ROOT / ".ai-out" / "hook.log", "a", encoding="utf-8") as f:
                f.write(json.dumps({"role": ROLE, "tool": name, "reason": reason,
                                    "args": {k: str(v)[:200] for k, v in args.items() if k in
                                             ("CommandLine", "TargetFile", "AbsolutePath")}}, ensure_ascii=False) + "\n")
        except OSError:
            pass
    sys.stdout.write(json.dumps(out))  # ASCII: stdout Windows có thể là cp1252


if __name__ == "__main__":
    main()
