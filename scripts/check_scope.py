#!/usr/bin/env python3
"""Kiểm tra phạm vi thay đổi của 1 task so với base (đã commit + chưa commit + file mới):
  - chỉ tạo/sửa file khớp mục '## Files được phép' (dòng `- tạo:` / `- sửa:`; xóa phải nằm trong `- xóa:`)
  - không sửa/xóa file có `OWNER: lead` (trừ task owner: lead)
  - không chạm đường dẫn được bảo vệ (script, config, gate, skill, hồ sơ) — Gemini: tuyệt đối;
    Lead: chỉ khi được liệt kê rõ trong 'Files được phép' (vd. linker script, startup trong cmake/)
Mẫu cho phép: đường dẫn chính xác, glob (src/teleop/*.cpp), hoặc thư mục kết thúc bằng '/'.
Usage: check_scope.py --root WT --task .ai/tasks/T01.md --base <sha> [--owner gemini|lead]
Exit 0 OK | 1 vi phạm"""
import argparse, fnmatch, pathlib, re, subprocess, sys

PROTECTED_PREFIX = ("scripts/", ".ai/templates/", ".ai/tasks/", ".ai/answers/", ".ai/questions/", ".ai/reviews/",
                    ".ai/reports/", ".ai/deviations/", ".ai/decisions/", ".claude/", ".gemini/", "cmake/",
                    "docs/07-verification/records/")
PROTECTED_EXACT = (".ai/config.env", ".ai/metrics.csv", "GEMINI.md", "CLAUDE.md", "CMakeLists.txt", ".clang-tidy",
                   ".clang-format", ".gitattributes", ".gitignore")


def git(root, *args):
    return subprocess.run(["git", "-c", "core.quotepath=off", "-C", root, *args],
                          capture_output=True, text=True, encoding="utf-8", errors="replace").stdout


def allowed(task):
    txt = pathlib.Path(task).read_text(encoding="utf-8", errors="ignore")
    m = re.search(r"^##\s*Files được phép\s*$(.*?)(?=^##\s|\Z)", txt, re.M | re.S)
    write, delete = [], []
    for line in (m.group(1).splitlines() if m else []):
        lm = re.match(r"^\s*-\s*(tạo|sửa|xóa|create|modify|delete)\s*:\s*(.+)$", line, re.I)
        if not lm:
            continue
        body = re.sub(r"\([^)]*\)", " ", lm.group(2))
        toks = [t.strip().strip("`") for t in re.split(r"[,\s]+", body)]
        toks = [t for t in toks if t and ("/" in t or "." in t)]
        (delete if lm.group(1).lower() in ("xóa", "delete") else write).extend(toks)
    return write, delete


def match(path, pats):
    return any(path.startswith(p) if p.endswith("/") else fnmatch.fnmatchcase(path, p) for p in pats)


def protected(path):
    return path.startswith(PROTECTED_PREFIX) or path in PROTECTED_EXACT


def changed(root, base):
    out = []
    for line in git(root, "diff", "--name-status", "--no-renames", base).splitlines():
        if "\t" in line:
            st, path = line.split("\t", 1)
            out.append((st[0], path))
    out += [("A", p) for p in git(root, "ls-files", "--others", "--exclude-standard").splitlines() if p]
    return out


def main():
    for st in (sys.stdout, sys.stderr):  # Windows: in tiếng Việt qua pipe (cp1252) không lỗi
        try: st.reconfigure(encoding="utf-8", errors="replace")
        except Exception: pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True); ap.add_argument("--task", required=True)
    ap.add_argument("--base", required=True); ap.add_argument("--owner", default="gemini")
    a = ap.parse_args()
    write, delete = allowed(a.task)
    if not write and not delete:
        print("SCOPE FAIL: mục '## Files được phép' không có dòng '- tạo:' / '- sửa:' nào"); sys.exit(1)
    files, bad = changed(a.root, a.base), []
    for st, p in files:
        pats = delete if st == "D" else write
        if protected(p) and not (a.owner == "lead" and match(p, pats)):
            bad.append(f"{p}: đường dẫn được bảo vệ (script/config/gate/skill/hồ sơ)")
        elif not match(p, pats):
            bad.append(f"{p}: {'xóa' if st == 'D' else 'tạo/sửa'} ngoài 'Files được phép'")
        if st in "MD" and a.owner != "lead" and "OWNER: lead" in git(a.root, "show", f"{a.base}:{p}"):
            bad.append(f"{p}: file OWNER: lead — worker không được sửa")
    for b in bad[:30]:
        print("SCOPE", b)
    print(f"SCOPE {'FAIL' if bad else 'OK'}: {len(files)} file thay đổi, {len(bad)} vi phạm")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
