---
name: logging-impl
description: Quy tắc ghi log khi implement — dùng đúng API theo context (RT/non-RT), ghi gì và không ghi gì, chống bão log, không rò rỉ secret/dữ liệu bệnh nhân/thông tin thiết kế, không code chỉ-có-ở-bản-debug. Tự động áp dụng cho mọi task code.
---
# API (project-conventions) — chỉ dùng các hàm này
- Thread RT / Class C: `vsur::log::event(EventId, arg0, arg1)`. Thread non-RT: thêm `vsur::log::text(Level, msg)`.
- Lỗi an toàn: `vsur::safety::report_fault(FaultId, detail)` theo ánh xạ trong task card.
- KHÔNG `printf`, `std::cout/cerr`, `syslog`, `slog2` trực tiếp, ghi file trực tiếp. MCU: API log task card chỉ định.
- `EventId`/`FaultId` do Lead cấp trong header. Cần mã mới → HỎI, không tự thêm, không dùng tạm mã khác.

# Ghi gì
- Chuyển trạng thái, lỗi (một lần, tại nơi phát hiện, kèm mã lỗi + chi tiết số), vượt ngưỡng, cấu hình/phiên bản đã nạp, bắt đầu/dừng.
- Đối số là số nguyên có đơn vị ghi ở comment của `EventId`; số thực đổi sang số nguyên theo đơn vị cố định (vd. µrad).
- Lỗi đã log ở tầng phát hiện thì tầng trên chỉ chuyển tiếp `Status`, không log lại.
- Log không thay xử lý lỗi: vẫn phải trả `Status`/`Result` và báo fault đúng task card.

# Không làm chậm, không bão log
- Trong code chu kỳ: chỉ log theo **cạnh** (khi giá trị/trạng thái đổi) hoặc qua bộ giới hạn của dự án. Không log mỗi chu kỳ.
- Không format chuỗi, không ghép chuỗi, không cấp phát để phục vụ log trên đường RT. Không chờ/retry khi ghi log thất bại.
- Giá trị tín hiệu theo từng chu kỳ để debug: không tự thêm log — dùng flight recorder nếu task card nêu, không thì HỎI.

# Không rò rỉ — KHÔNG bao giờ ghi
- Khóa, mật khẩu, token, session, nội dung chứng chỉ (chỉ ghi ID khóa nếu task card cho phép).
- Dữ liệu bệnh nhân, tên/tài khoản người vận hành, hình ảnh.
- Buffer thô / hex dump dữ liệu nhận từ ngoài; con trỏ, địa chỉ bộ nhớ.
- Đường dẫn file nguồn, tên hàm (`__FILE__`, `__func__`, `__PRETTY_FUNCTION__`), tham số thuật toán/hiệu chuẩn.
- `log::text`: `msg` là hằng chuỗi trong code. Chuỗi đến từ ngoài (mạng, USB, file) không được dùng làm `msg` hay chuỗi format;
  nếu task card yêu cầu ghi lại thì giới hạn độ dài và thay ký tự điều khiển.

# Không có code chỉ dành cho debug
- Không `#ifdef DEBUG`/`NDEBUG`/biến môi trường làm đổi hành vi. Không lệnh test, cửa hậu, tham số ẩn, bỏ qua kiểm tra "để dễ thử".
- Không để lại log tạm dùng lúc debug. Công cụ hỗ trợ debug đặt ở `test/`, không ở `src/`.

# Test & report
- Test đường lỗi kiểm tra đúng `EventId`/`FaultId` được phát (fake sink trong `test/fakes/` nếu có; chưa có → HỎI).
- Report liệt kê mọi `EventId` code mới phát ra và điều kiện phát.
