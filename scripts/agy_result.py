#!/usr/bin/env python3
"""Đọc log `agy --output-format stream-json` (NDJSON, có thể lẫn dòng stderr) và in thông tin cho script shell.

Usage: agy_result.py <log> cid|status|denied|response
  cid      conversation_id (để resume bằng --conversation)
  status   status của sự kiện result cuối (SUCCESS/ERROR/...); rỗng nếu không có
  denied   mỗi dòng một hành động bị agy soft-deny; với run_command kèm CommandLine đã bị chặn
  response văn bản trả lời cuối của model
"""
import json
import sys


def events(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line.startswith("{"):
                continue
            try:
                yield json.loads(line)
            except json.JSONDecodeError:
                continue


def main():
    path, what = sys.argv[1], sys.argv[2]
    cid = status = response = ""
    denied = []
    last_cmd = ""  # run_command cuối cùng — khi phiên dừng vì soft-deny, đó là lệnh bị chặn
    for e in events(path):
        if e.get("event") == "init":
            cid = e.get("conversation_id", cid)
        su = e.get("step_update") or {}
        if su.get("tool_name") == "run_command":
            last_cmd = ((su.get("tool_info") or {}).get("parameters") or {}).get("CommandLine", "") or last_cmd
        if e.get("event") == "result":
            r = e.get("result") or {}
            cid = r.get("conversation_id", cid)
            status = r.get("status", "")
            response = r.get("response", "")
            for d in r.get("denied_actions") or []:
                act = d.get("action", "?")
                denied.append(f"{act}: {last_cmd}" if act == "command" and last_cmd else act)
    sys.stdout.reconfigure(encoding="utf-8")
    out = {"cid": cid, "status": status, "response": response, "denied": "\n".join(denied)}
    if what not in out:
        sys.exit(f"unknown field {what}")
    if out[what]:
        print(out[what])


if __name__ == "__main__":
    main()
