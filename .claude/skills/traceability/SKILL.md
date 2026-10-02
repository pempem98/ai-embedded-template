---
name: traceability
description: Hệ thống ID và truy vết hai chiều HAZ ↔ RCM ↔ SRS ↔ SI ↔ code ↔ test cho IEC 62304/FDA, và cách dùng scripts/trace.py. Dùng khi tạo yêu cầu, task card, lệnh /trace, chuẩn bị release hoặc kiểm tra thiếu test.
---
# ID
| Tiền tố | Ý nghĩa | Nơi định nghĩa |
|---|---|---|
| UN-nnn | User need | docs/02-requirements/SysRS.md |
| SYS-nnn | Yêu cầu hệ thống (có phân bổ SW/HW/ME/EE) | docs/02-requirements/SysRS.md |
| IF-nnn | Interface (ICD / SAD) | docs/03-architecture/ |
| HAZ-nnn | Mối nguy | docs/05-risk-management/hazard-analysis.md |
| RCM-nnn | Biện pháp kiểm soát rủi ro | docs/05-risk-management/risk-control-matrix.md |
| SRS-nnn | Yêu cầu phần mềm | docs/02-requirements/SRS.md |
| SI-nnn | Software item | docs/03-architecture/SAD.md |
| SDD-<item> | Detailed design | docs/04-detailed-design/ |
| DEV-nnn | Deviation quy tắc code | .ai/deviations/ (con người phê duyệt) |
| ANOM-nnn | Anomaly | docs/09-problem-resolution/ |
| ADR-nnn | Quyết định kỹ thuật dùng chung | .ai/decisions/ |
ID không bao giờ tái sử dụng; yêu cầu bị bỏ → trạng thái Deleted, giữ dòng.

# Tag trong code
`@req SRS-x` (implement) · `@rcm RCM-x` (điểm implement risk control) · `@verifies SRS-x|RCM-x` (test) · `// @deviation DEV-x`.

# Quy tắc đếm của trace.py
- `@req`/`@rcm` chỉ tính trong file implement (.c/.cc/.cpp, hoặc header không phải `OWNER: lead`) — tag trong header
  interface của Lead không chứng minh đã implement.
- `@verifies` chỉ tính trong file test (thư mục test/tests/…, `test_*.x`, `*_test.x`); nằm ngoài → GAP.
- Yêu cầu (chế độ toàn dự án): SRS không có nguồn SYS/RCM/ADR/HAZ → GAP; SYS có `SW` ở cột Allocation mà không SRS nào
  tham chiếu → GAP; SRS trỏ tới SYS không có trong SysRS → GAP.

# Công cụ
- `python scripts/trace.py` → `docs/08-traceability/trace-matrix.csv` + danh sách GAP (chưa implement, chưa test, ID mồ côi, @verifies sai chỗ).
- `delegate.sh` / `lead.sh` / `merge.sh` tự chạy `trace.py --task` cho task Class B/C.
- Đọc output GAP, không đọc CSV. GAP trước release = blocker.
