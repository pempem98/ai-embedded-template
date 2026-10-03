---
name: logging-diagnostics
description: Thiết kế logging, trace & chẩn đoán cho robot phẫu thuật — log trên đường real-time không gây trễ (binary event, ring buffer, flight recorder), điều khiển mức log lúc chạy, công cụ debug khi phát triển, và chống rò rỉ ở bản sản xuất (PHI, secret, IP, core dump, cổng debug, xuất log), giới hạn lưu trữ, rò rỉ tài nguyên. Dùng khi /arch, /design có logging/chẩn đoán, viết task card logger, /threat, /release-check, điều tra anomaly, hoặc người dùng nhắc "log", "logger", "debug", "trace", "core dump", "leak", "rò rỉ", "JTAG", "chẩn đoán".
---
# Hai mục tiêu phải đạt cùng lúc
1. Debug thuận tiện mà **không đổi timing**: log không được làm chậm hay làm lệch đường RT, và bật thêm log không tạo ra lỗi khác.
2. Bản sản xuất **không rò rỉ**: dữ liệu bệnh nhân, secret, tài sản trí tuệ, và không để lại cổng debug.
Nguyên tắc nối hai mục tiêu: **log nhị phân + từ điển nằm ngoài thiết bị**. Bản ghi chỉ chứa `EventId` + đối số số; chuỗi mô tả
nằm trong từ điển sinh từ `event_id.hpp`, giữ ở công ty → không tốn thời gian format trên thiết bị, binary không chứa chuỗi lộ thiết kế.

# Kênh log — mỗi kênh một chính sách (chốt trong SAD/SDD)
| Kênh | Nội dung | Cơ chế | Production |
|---|---|---|---|
| Event RT | chuyển trạng thái, lỗi, vượt ngưỡng | `log::event(EventId, arg0, arg1)` → ring SPSC theo từng thread; thread non-RT xả | Có |
| Text non-RT | khởi tạo, cấu hình, lifecycle | `log::text(Level, msg)` chỉ ở thread non-RT | Có, mức giới hạn |
| Fault record | lỗi an toàn (`safety::report_fault`) | vùng đệm dành riêng, không bị rate-limit, lưu bền | Có, không được mất |
| Flight recorder | biến vòng điều khiển (setpoint, phản hồi, trạng thái) | ring trong RAM luôn chạy; đóng băng và ghi ra khi có fault (trước/sau trigger) | Có, chỉ ghi khi fault |
| Audit / security | đăng nhập dịch vụ, cập nhật, đổi cấu hình | chống sửa đổi (skill `medical-cybersecurity`) | Có |
| Công cụ dev | LTTng/ftrace, gdbserver, core dump đầy đủ, stream tín hiệu trực tiếp | ngoài binary sản phẩm, ở image dev | **Không** |

# Đường RT — không gây trễ
- Một lần ghi: bản ghi kích thước cố định, không format, không chuỗi, không cấp phát, không lock, không syscall; timestamp monotonic.
- Ring đầy → **bỏ bản ghi mới + tăng bộ đếm mất**, không bao giờ chờ. Bộ đếm mất được ghi lại khi xả.
- Kích thước ring = tốc độ sinh tối đa × chu kỳ xả × hệ số dự phòng; thread xả ưu tiên thấp, không nằm trên CPU cô lập cho RT.
- Chống bão log: sự kiện trong code chu kỳ ghi theo **cạnh** (khi đổi trạng thái) hoặc qua bộ giới hạn (N lần đầu + đếm).
- Chi phí log tính vào WCET; test timing chạy ở **mức log cao nhất được phép trong production** và ở tải log tối đa.
- Mức log đổi lúc chạy: mặt nạ atomic theo module, đổi từ thread non-RT; kiểm tra mức là một lần đọc atomic.
- **Một binary cho cả debug lẫn sản xuất**: khác nhau ở cấu hình (đã ký), không ở `#ifdef DEBUG`. Binary được verify phải là
  binary xuất xưởng; code chỉ có ở bản debug làm đổi timing và layout bộ nhớ.
- Debug sau sự cố dựa vào flight recorder + fault record + build-id, không dựa vào việc tái hiện với log bật thêm.
- Tương quan giữa các service: timestamp cùng miền đồng hồ (skill `distributed-sync-control`), kèm boot id và `source_id`.

# Bản sản xuất — không rò rỉ
| Thứ có thể rò | Biện pháp |
|---|---|
| Dữ liệu bệnh nhân, danh tính người vận hành | Không có trong log kỹ thuật; cần định danh → mã giả danh. Hình ảnh/video không vào log |
| Secret (khóa, mật khẩu, token, session) | Không bao giờ ghi; chỉ ghi ID/fingerprint của khóa |
| Tài sản trí tuệ (chuỗi format, tên hàm, đường dẫn file, tham số thuật toán, hiệu chuẩn) | Log nhị phân, từ điển ngoài thiết bị; strip symbol, debug info lưu riêng theo build-id; không `__FILE__`/`__func__` trong chuỗi |
| Nội dung bộ nhớ (hex dump buffer, core dump) | Không dump buffer thô ở mức production; core dump tắt hoặc thay bằng crash record tối thiểu (thanh ghi, địa chỉ backtrace, build-id) được mã hóa |
| Địa chỉ/con trỏ | Không ghi con trỏ thô |
| Cổng debug (UART console, JTAG/SWD, gdbserver, SSH, topic DDS debug, lệnh test, biến môi trường bật tính năng ẩn) | Tắt/khóa ở image production; lập **bảng kiểm kê giao diện debug** trong threat model (`/threat`), kiểm ở `/release-check` |
| Xuất log | Chỉ qua chế độ dịch vụ có xác thực; gói log mã hóa + ký; không tự gửi ra mạng, không syslog/UDP không xác thực |
| Log lưu trên thiết bị | Phân vùng riêng có phân quyền; audit log có chuỗi băm chống sửa |
Đầu vào từ ngoài đưa vào log (tên file, chuỗi từ mạng/USB): giới hạn độ dài, lọc ký tự điều khiển, không dùng làm chuỗi format.

# Rò rỉ tài nguyên (lộ ra sau thời gian dài ở hiện trường)
- Lưu trữ: xoay vòng theo dung lượng, hạn mức từng kênh, phân vùng log tách khỏi rootfs; fault record có chỗ dành riêng.
  Tính ngân sách ghi flash theo tuổi thọ thiết bị.
- Bộ nhớ/fd/thread: không cấp phát sau init (ADR-001) + gate ASan/LSan; thêm soak test dài (skill `integration-test`) theo dõi RSS,
  số fd, số thread, mức đầy ring — phải phẳng. Các số này công bố trong `service_status` để phát hiện tại hiện trường.

# Phân loại & hồ sơ
- API ghi log phía RT nằm trong item Class C → Class C. Phần xả/lưu/xuất có thể class thấp hơn nếu SAD chứng minh segregation;
  lỗi của logger không được ảnh hưởng chức năng an toàn (đầy đĩa, thread xả treo → đường RT vẫn chạy đúng).
- Nội dung log cần cho điều tra khiếu nại/anomaly (skill `problem-resolution`) là yêu cầu → SRS có ID; thời hạn lưu do RA/QA chốt.
- Từ điển sự kiện là configuration item gắn phiên bản build; thiếu từ điển đúng phiên bản thì log hiện trường không giải mã được.

# Phải chốt (SDD/ADR) trước khi giao task — worker không tự chọn
Định dạng bản ghi & kích thước ring từng thread · chính sách khi đầy · thread xả (ưu tiên, CPU, chu kỳ) · biến nào vào flight
recorder, độ dài trước/sau trigger · mức log mặc định và mức tối đa ở production, ai được đổi · hạn mức lưu trữ & xoay vòng ·
đường xuất log và khóa · chính sách crash/core dump · bảng kiểm kê giao diện debug · danh sách `EventId` (Lead cấp).

# Review — REJECT nếu
Đường RT có format/chuỗi/`printf`/iostream/syslog hoặc chờ khi ring đầy; log mỗi chu kỳ không theo cạnh/không giới hạn; ghi
secret, dữ liệu bệnh nhân, buffer thô, con trỏ, đường dẫn file; chuỗi từ ngoài dùng làm format hoặc không giới hạn độ dài;
`#ifdef DEBUG`/`NDEBUG` làm đổi hành vi; lệnh test, cửa hậu, cổng debug không có trong bảng kiểm kê; tự cấp `EventId`;
ghi log thay cho xử lý lỗi (không trả lỗi/không `report_fault`); cùng một lỗi bị log lặp ở nhiều tầng.
