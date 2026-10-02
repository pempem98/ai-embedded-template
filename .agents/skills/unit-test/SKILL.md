---
name: unit-test
description: Unit test trên host cho phần mềm thiết bị y tế — yêu cầu theo safety class, coverage, truy vết. Áp dụng cho mọi task có code.
---
# Unit test
- Framework theo dự án (GoogleTest cho C++, Unity/CppUTest cho C) — không tự đổi.
- Phần cứng/OS được mock qua lớp HAL/OSAL; không gọi thanh ghi, syscall RT hay API QNX thật trong unit test.
- Mỗi ID trong `requirements:`/`risk_controls:` ≥ 1 test có `@verifies`.
- Bắt buộc test: biên dưới/trên/ngoài biên, NaN/Inf (số thực), NULL/rỗng/đầy, lỗi HAL/OS, timeout, dữ liệu stale,
  mọi nhánh lỗi và mọi trạng thái/chuyển trạng thái của state machine.
- Coverage theo class (gate kiểm tra): B ≥ ngưỡng line trong config; C: 100% line + branch (MC/DC nếu có tool).
  Không đạt vì code không thể chạm tới → HỎI Lead (có thể là dead code), không tự thêm test giả.
- Tên: `TEST(<Unit PascalCase>, <HànhVi PascalCase>)` — không dùng `_` (quy tắc GoogleTest, xem naming-conventions). Test độc lập, reset state, không phụ thuộc thứ tự, không sleep.
- Expected value lấy từ đặc tả/task card, KHÔNG lấy từ output của chính code vừa viết.
- Không sửa code sản phẩm để dễ test nếu task card không cho phép → hỏi.
