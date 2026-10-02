#!/usr/bin/env python3
"""Ma trận truy vết IEC 62304: SRS <-> code (@req) <-> test (@verifies) <-> risk control (@rcm).
Quy tắc đếm:
  - @req/@rcm chỉ tính ở file implement: .c/.cc/.cpp, hoặc header KHÔNG phải `OWNER: lead`
    (header interface của Lead chỉ khai báo → không chứng minh đã implement). Tag trong file test bị bỏ qua.
  - @verifies chỉ tính trong file test (thư mục test/tests/…, tên test_*.x hoặc *_test.x); nằm ngoài → GAP.
Usage:
  trace.py                         # toàn dự án -> docs/08-traceability/trace-matrix.csv + tóm tắt lỗ hổng
  trace.py --root DIR --task FILE  # kiểm tra 1 task: mọi SRS/RCM trong task card đã được implement + verify
"""
import argparse, csv, re, sys, pathlib

ID = r"(?:SRS|RCM|HAZ|SI)-\d{3,}"
SRC_EXT = (".c", ".cc", ".cpp", ".h", ".hpp")
IMPL_EXT = (".c", ".cc", ".cpp")
TEST_DIRS = {"test", "tests", "unittest", "unit_test", "integration_test"}
SKIP_DIRS = {"build", ".git", "third_party", ".ai-out"}


def ids_in(path, kind):
    p = pathlib.Path(path)
    return set(re.findall(rf"\b{kind}-\d{{3,}}\b", p.read_text(errors="ignore"))) if p.exists() else set()


def is_test(p, root):
    parts = p.relative_to(root).parts
    return bool(TEST_DIRS & set(parts[:-1])) or p.name.startswith("test_") or re.search(r"_test\.\w+$", p.name)


def scan(root):
    impl, ver, rcm, misplaced = {}, {}, {}, []
    root = pathlib.Path(root)
    for p in root.rglob("*"):
        if p.suffix not in SRC_EXT or SKIP_DIRS & set(p.relative_to(root).parts):
            continue
        rel, text = p.relative_to(root).as_posix(), p.read_text(errors="ignore")
        test = is_test(p, root)
        impl_ok = not test and (p.suffix in IMPL_EXT or "OWNER: lead" not in text)
        for n, line in enumerate(text.splitlines(), 1):
            for tag, store in (("@req", impl), ("@verifies", ver), ("@rcm", rcm)):
                for grp in re.findall(rf"{tag}\s+((?:{ID}[\s,]*)+)", line):
                    for one in re.findall(ID, grp):
                        if tag == "@verifies" and not test:
                            misplaced.append(f"{one}: @verifies ngoài file test ({rel}:{n})")
                        elif tag != "@verifies" and not impl_ok:
                            continue
                        else:
                            store.setdefault(one, []).append(f"{rel}:{n}")
    return impl, ver, rcm, misplaced


def task_ids(task):
    txt = pathlib.Path(task).read_text(errors="ignore")
    want = {}
    for key in ("requirements", "risk_controls"):
        m = re.search(rf"^{key}:\s*(.*)$", txt, re.M)
        want[key] = set(re.findall(ID, m.group(1))) if m else set()
    return want


def table_rows(path, kind):
    """Dòng bảng markdown bắt đầu bằng | <kind>-nnn | → {id: text dòng}."""
    p = pathlib.Path(path)
    rows = {}
    for line in (p.read_text(encoding="utf-8", errors="ignore").splitlines() if p.exists() else []):
        m = re.match(rf"^\|\s*({kind}-\d{{3,}})\s*\|", line)
        if m:
            rows[m.group(1)] = line
    return rows


def requirement_gaps(sysrs_path, srs_path):
    """SYS ↔ SRS: SRS phải có nguồn (SYS/RCM/ADR/HAZ); SYS phân bổ SW phải có SRS; SRS không trỏ tới SYS không tồn tại."""
    sys_rows, srs_rows, gaps = table_rows(sysrs_path, "SYS"), table_rows(srs_path, "SRS"), []
    referenced = set()
    for sid, line in sorted(srs_rows.items()):
        src = set(re.findall(r"\b(?:SYS|RCM|ADR|HAZ)-\d{3,}\b", line))
        if not src:
            gaps.append(f"{sid}: không có nguồn (SYS/RCM/ADR) trong SRS")
        for s in sorted(x for x in src if x.startswith("SYS-")):
            referenced.add(s)
            if sys_rows and s not in sys_rows:
                gaps.append(f"{sid}: tham chiếu {s} không có trong SysRS")
    for s, line in sorted(sys_rows.items()):
        cells = [c.strip() for c in line.strip("|").split("|")]
        alloc = cells[3] if len(cells) > 3 else ""
        if re.search(r"\bSW\b", alloc) and s not in referenced:
            gaps.append(f"{s}: phân bổ SW nhưng chưa có SRS nào tham chiếu")
    return gaps


def main():
    for st in (sys.stdout, sys.stderr):  # Windows: in tiếng Việt qua pipe (cp1252) không lỗi
        try: st.reconfigure(encoding="utf-8", errors="replace")
        except Exception: pass
    ap = argparse.ArgumentParser(); ap.add_argument("--root", default="."); ap.add_argument("--task")
    a = ap.parse_args()
    impl, ver, rcm, misplaced = scan(a.root)
    gaps = list(misplaced)
    if a.task:
        w = task_ids(a.task)
        for r in sorted(w["requirements"]):
            if r not in impl: gaps.append(f"{r}: thiếu @req trong code implement")
            if r not in ver:  gaps.append(f"{r}: thiếu @verifies trong test")
        for r in sorted(w["risk_controls"]):
            if r not in rcm: gaps.append(f"{r}: thiếu @rcm tại điểm implement risk control")
            if r not in ver: gaps.append(f"{r}: thiếu @verifies cho risk control")
    else:
        srs = ids_in("docs/02-requirements/SRS.md", "SRS")
        rcms = ids_in("docs/05-risk-management/risk-control-matrix.md", "RCM")
        out = pathlib.Path("docs/08-traceability/trace-matrix.csv"); out.parent.mkdir(parents=True, exist_ok=True)
        with out.open("w", newline="") as f:
            w = csv.writer(f); w.writerow(["ID", "Implemented_at", "Verified_by"])
            for r in sorted(srs | rcms):
                w.writerow([r, "; ".join(impl.get(r, []) + rcm.get(r, [])), "; ".join(ver.get(r, []))])
                if r not in impl and r not in rcm: gaps.append(f"{r}: chưa implement")
                if r not in ver: gaps.append(f"{r}: chưa có test verify")
        for r in sorted((set(impl) | set(ver) | set(rcm)) - srs - rcms):
            gaps.append(f"{r}: tag trong code nhưng không có trong SRS/RCM (ID mồ côi)")
        gaps += requirement_gaps("docs/02-requirements/SysRS.md", "docs/02-requirements/SRS.md")
        print(f"Đã ghi {out}")
    for g in gaps[:40]: print("GAP", g)
    print(f"trace: {len(gaps)} gap(s)")
    sys.exit(1 if gaps else 0)


if __name__ == "__main__":
    main()
