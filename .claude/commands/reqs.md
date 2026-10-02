---
description: Phân rã yêu cầu UN → SysRS (SYS) → phân bổ → SRS, kiểm chất lượng & truy vết
argument-hint: <nguồn: tính năng / UN-xxx / SYS-xxx / tài liệu đầu vào>
---
Nguồn: $ARGUMENTS — skills `requirements-engineering`, `traceability`, `iec62304-process`; `risk-management-iso14971` nếu chạm an toàn. Think hard.
1. Grep UN/SYS/SRS/HAZ/RCM hiện có liên quan (không đọc toàn bộ file lớn). Tài liệu đầu vào dài → task research trước.
2. Đề xuất SYS mới/sửa (EARS, đo được, verify method, nguồn) và phân bổ SW/HW/ME/EE — phân bổ dựa trên SyAD (`/arch system` nếu chưa có).
3. Phần SW → SRS (một ý/dòng, nguồn SYS/RCM, SI & class theo SAD, verify method); cập nhật checklist §5.2.2.
4. Tự kiểm theo mục "Review" của skill; chạy `python scripts/trace.py` — chỉ đọc GAP liên quan.
5. Ghi bản Draft vào `docs/02-requirements/SysRS.md` / `SRS.md` (khối lượng lớn → task `type: doc` cho Gemini + `reg-doc-reviewer`).
6. Báo bảng: ID | yêu cầu (rút gọn) | nguồn | phân bổ/SI | class | verify | điểm cần người dùng quyết.
   **Người dùng xác nhận** yêu cầu, phân bổ và class trước khi tạo task card.
