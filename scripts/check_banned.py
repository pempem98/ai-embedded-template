#!/usr/bin/env python3
"""Chặn API/pattern cấm theo safety class & platform.
Phạm vi: --files <f...> (gate.sh truyền vào) hoặc mặc định file thay đổi so với HEAD + file mới.
Ngoại lệ: comment cùng dòng `// @deviation DEV-xxx`, chỉ hợp lệ khi <dev-dir>/DEV-xxx.md tồn tại VÀ có
`APPROVED_BY:` do con người điền. dev-dir mặc định là .ai/deviations của repo chứa script (không phải worktree)."""
import argparse, re, subprocess, sys, pathlib

COMMON = [  # mọi class
    (r"#\s*pragma\s+(GCC|clang)\s+diagnostic\s+ignored", "tắt warning bằng pragma"),
    (r"\bNOLINT", "NOLINT không có deviation"),
    (r"\bgoto\b", "goto"),
    (r"\b(setjmp|longjmp)\b", "setjmp/longjmp"),
    (r"\b(gets|strcpy|strcat|sprintf|vsprintf)\s*\(", "hàm chuỗi không giới hạn độ dài"),
    (r"\batoi\s*\(|\batof\s*\(", "atoi/atof không kiểm tra lỗi"),
]
CLASS_BC = [
    (r"\b(malloc|calloc|realloc|free)\s*\(", "cấp phát động"),
    (r"\bthrow\b", "exception trong code an toàn"),
    (r"\breinterpret_cast\b", "reinterpret_cast"),
    (r"\bstd::(thread|async)\b", "tạo thread không qua lớp OSAL (không đặt priority/policy)"),
]
CLASS_C = [
    (r"(?<![\w:])new\s+[A-Za-z_]", "new (dùng pool/placement có kiểm soát)"),
    (r"\bdelete\b(?!\s*;)", "delete"),
    (r"\bstd::(vector|string|map|list|unordered_map|function|shared_ptr)\b", "container/kiểu cấp phát động"),
    (r"\bdynamic_cast\b|\btypeid\b", "RTTI"),
    (r"\bprintf\s*\(|\bstd::cout\b", "I/O không xác định thời gian (dùng logger RT)"),
]
PLATFORM = {
    "linux": [(r"\busleep\s*\(|\bsleep\s*\(", "sleep tương đối trong RT loop (dùng clock_nanosleep TIMER_ABSTIME)")],
    "qnx":   [(r"\bInterruptAttach\s*\(", "InterruptAttach (ưu tiên InterruptAttachEvent)")],
    "mcu":   [(r"\bfloat\b.*\bISR\b", "float trong ISR (kiểm tra FPU context)")],
}
SRC_RX = re.compile(r"^(src|inc|include)/.*\.(c|cc|cpp|h|hpp)$")


def changed_files():
    run = lambda *a: subprocess.run(["git", *a], capture_output=True, text=True).stdout.split()
    out = run("diff", "--name-only", "HEAD") + run("ls-files", "--others", "--exclude-standard")
    return sorted(f for f in set(out) if SRC_RX.match(f))


def strip_strings(code):
    return re.sub(r'"(?:\\.|[^"\\])*"', '""', code)


def main():
    for st in (sys.stdout, sys.stderr):  # Windows: in tiếng Việt qua pipe (cp1252) không lỗi
        try: st.reconfigure(encoding="utf-8", errors="replace")
        except Exception: pass
    ap = argparse.ArgumentParser()
    ap.add_argument("--class", dest="cls", default="B", choices=["A", "B", "C"])
    ap.add_argument("--platform", default="host")
    ap.add_argument("--files", nargs="*")
    ap.add_argument("--dev-dir", default=str(pathlib.Path(__file__).resolve().parent.parent / ".ai" / "deviations"))
    a = ap.parse_args()
    rules = COMMON + (CLASS_BC if a.cls in ("B", "C") else []) + (CLASS_C if a.cls == "C" else []) \
        + PLATFORM.get(a.platform, [])
    files = a.files if a.files is not None else changed_files()
    approved = {}
    bad = 0
    for f in files:
        p = pathlib.Path(f)
        if not p.exists():
            continue
        in_block = False
        for n, line in enumerate(p.read_text(errors="ignore").splitlines(), 1):
            m = re.search(r"@deviation\s+(DEV-\d+)", line)
            if m:
                dev = m.group(1)
                if dev not in approved:
                    d = pathlib.Path(a.dev_dir) / f"{dev}.md"
                    approved[dev] = d.exists() and re.search(r"^APPROVED_BY:\s*[^<\s]", d.read_text(errors="ignore"), re.M)
                if approved[dev]:
                    continue
                print(f"{f}:{n}: violation [{dev} chưa có file phê duyệt (APPROVED_BY) trong {a.dev_dir}]"); bad += 1
            # bỏ comment khối /* */ và comment dòng, chuỗi ký tự
            code = line
            if in_block:
                if "*/" not in code: continue
                code, in_block = code.split("*/", 1)[1], False
            code = re.sub(r"/\*.*?\*/", " ", code)
            if "/*" in code:
                code, in_block = code.split("/*", 1)[0], True
            code = strip_strings(code.split("//")[0])
            for rx, why in rules:
                if re.search(rx, line if "NOLINT" in rx else code):
                    print(f"{f}:{n}: violation [{why}] -> {line.strip()[:90]}"); bad += 1
    print(f"banned-check class={a.cls} platform={a.platform} files={len(files)}: {bad} violation(s)")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
