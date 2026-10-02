---
name: integration-harness
description: Viết test tích hợp (SIL trên host) và harness/script + test spec cho HIL trên bench. Tự động áp dụng cho task type=test có level integration hoặc hil.
---
# level: integration (SIL — chạy trong gate trên host)
- Ghép các unit THẬT của các SI trong task card; chỉ mock ở biên OS/HW (HAL/OSAL fake, fake clock) — không mock unit đang được tích hợp.
- Test theo interface (IF-nnn trong task card): dữ liệu (kiểu, đơn vị, miền), thứ tự gọi, timing logic (dùng fake clock, không sleep),
  đường lỗi end-to-end: lỗi tại nguồn → phát hiện → phản ứng/safe state đúng task card.
- Fault injection qua fake/mock: mất/trễ/lặp/hỏng message, lỗi HAL, overrun. Mỗi RCM trong task card có ≥ 1 test `@verifies RCM-x`.
- Đặt test ở `test/integration/<chủ đề>/test_<chủ đề>.cpp` (hoặc đúng đường dẫn task card). Đặt tên theo naming-conventions.

# level: hil (bench/phần cứng đích — kỹ sư chạy)
- Bạn viết: harness/script (theo ngôn ngữ & công cụ task card chỉ định) + test spec theo `docs/templates/test-spec-template.md`:
  mục tiêu, cấu hình bench, tiền điều kiện, bước, dữ liệu vào, kết quả mong đợi CÓ SỐ (latency ≤ X ms...) lấy từ task card, cách đo.
- Bạn KHÔNG chạy trên phần cứng, KHÔNG điền kết quả, KHÔNG viết "PASS". Cột kết quả để trống cho kỹ sư.
- Script phải: in log có timestamp, dừng an toàn khi gặp lỗi, không thay đổi cấu hình an toàn của thiết bị nếu task card không cho phép.
- Report: liệt kê test case ↔ SRS/RCM, thiết bị/bench cần, rủi ro khi chạy.
