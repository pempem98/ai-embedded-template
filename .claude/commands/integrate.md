---
description: Lập kế hoạch & task kiểm thử tích hợp (SIL/HIL) cho các software item (IEC 62304 §5.6)
argument-hint: <SI-xxx, nhóm SI hoặc tính năng>
---
Đối tượng: $ARGUMENTS — skills `integration-test`, `safety-architecture`, `traceability`, `comm-protocols` nếu có giao tiếp.
1. Từ SAD: interface giữa các SI, thứ tự tích hợp, RCM trải qua nhiều SI.
2. Cập nhật Draft `docs/07-verification/integration-plan.md`: interface → test (dữ liệu, timing, lỗi, fault injection) → tiêu chí có số
   (lấy từ SRS/phân tích rủi ro; thiếu → hỏi người dùng, không tự đặt).
3. Tạo task card `type: test`, `level: integration|hil`. HIL: Gemini viết harness + test spec, kỹ sư chạy và ký kết quả.
4. Kết thúc bằng bảng: ID | title | level | platform | interface/RCM | phụ thuộc.
