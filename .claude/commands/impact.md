---
description: Phân tích ảnh hưởng của một thay đổi (IEC 62304 §6, §7.4, §8) — yêu cầu, rủi ro, SI, test cần chạy lại
argument-hint: <mô tả thay đổi / ANOM-xxx / SOUP mới / file>
---
Thay đổi: $ARGUMENTS — skills `traceability`, `risk-management-iso14971`, `iec62304-process`.
1. Xác định SI & file bị ảnh hưởng (grep tag `@req/@rcm`, include, interface `OWNER: lead`); không đọc cả file lớn.
2. Truy ngược: SRS, RCM, HAZ liên quan; class của SI; SDD cần cập nhật; SOUP liên quan.
3. Đánh giá: có ảnh hưởng risk control hiện có / tạo chuỗi nguy hiểm mới? → nếu có: chạy /hazard, giao `fw-safety-assessor`.
4. Regression set: unit test (@verifies các ID trên), integration/HIL liên quan (skill `integration-test`).
5. Kết quả: bảng ảnh hưởng (mục | ID | hành động) + task card đề xuất. Quyết định chấp nhận thay đổi là của người dùng.
