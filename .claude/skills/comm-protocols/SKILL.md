---
name: comm-protocols
description: Thiết kế & review giao tiếp/giao thức truyền thông trong robot phẫu thuật — CAN/CAN FD/CANopen/CiA 402, EtherCAT/FSoE, SPI, I2C, UART/RS-485/Modbus, USB, SSI, BiSS-C, EnDat 2.2, Ethernet/UDP/TSN/DDS. Chọn giao thức, lớp an toàn (black channel), timing, xử lý lỗi, hazard, bằng chứng test. Dùng khi thiết kế/viết SDD/task card/review code driver, fieldbus, encoder, cảm biến, link console↔cart, hoặc người dùng nhắc tên một giao thức.
---
# Cách dùng
1. Đọc phần chung dưới đây, rồi CHỈ đọc `references/<giao-thức>.md` liên quan:
   can · ethercat · spi · i2c · uart · usb · ssi · biss-c · endat · ethernet
2. Thông số cụ thể (thanh ghi, timing, CRC poly, mode command) lấy từ datasheet/spec qua task `type: research` → `.ai/notes/`.
   Không tự đọc tài liệu dài, không đoán.
3. Task card: `protocols: can, ethercat` → delegate.sh chèn skill Gemini `comm-safety` + `proto-<x>`. Chốt mọi tham số trong
   "Quyết định đã chốt" (mục Giao tiếp). Parser dữ liệu từ ngoài / fieldbus điều khiển → effort high.

# Nguyên tắc chung — kênh không tin cậy (black channel, theo tinh thần IEC 61784-3 / EN 50159)
| Lỗi truyền | Biện pháp ở tầng ứng dụng an toàn |
|---|---|
| Hỏng dữ liệu | CRC ứng dụng độc lập CRC tầng link (đa thức/seed khác) |
| Lặp, mất, chèn, sai thứ tự | Sequence/alive counter, kiểm tra bước nhảy |
| Trễ | Timestamp hoặc watchdog thời gian nhận; deadline suy ra từ phân tích động học |
| Giả mạo nguồn (masquerade) | ID nguồn/đích, kiểu message, version trong payload |
| Sai độ dài/kiểu | Kiểm tra length/type/version/miền giá trị trước khi dùng |
Class C: dữ liệu an toàn đi qua lớp safety protocol (FSoE, CANopen Safety EN 50325-5, BiSS/EnDat safety profile, hoặc lớp E2E
do dự án định nghĩa trong SDD). Chỉ dựa vào CRC phần cứng của bus là KHÔNG đủ.

# Quyết định phải chốt trong SDD / task card (Gemini không tự chọn)
- Vai trò (master/slave, host/device), tốc độ, mode, định dạng khung, endianness, đơn vị & scaling từng trường
- Chu kỳ, deadline, jitter cho phép; ai sở hữu timing (ISR/DMA/thread nào — ISR/DMA do Lead viết)
- Bảng lỗi: phát hiện → đếm → ngưỡng → phản ứng (bỏ mẫu / giữ giá trị cũ có hạn / báo supervisor / safe state)
- Fault detection time + reaction time ≤ budget trong phân tích rủi ro (HAZ/RCM)
- Khởi tạo & phục hồi (bus-off, link down, re-enumeration): tự động hay cần xác nhận; có cho chuyển động lại không
- Stack/driver/IP master là SOUP nào, phiên bản (skill `soup-management`)
- Đầu vào từ ngoài thiết bị (USB, Ethernet bệnh viện, cổng dịch vụ) → skill `medical-cybersecurity`, fuzz test

# Gợi ý chọn giao thức (quyết định theo kiến trúc, ghi lý do trong SAD)
| Nhu cầu | Thường dùng |
|---|---|
| Vòng điều khiển khớp đồng bộ 1–8 kHz, nhiều trục | EtherCAT + DC, drive CiA 402 (CSP); an toàn qua FSoE |
| Mạng phụ, cảm biến/actuator chậm, dụng cụ, I/O | CAN FD / CANopen (Safety: EN 50325-5) |
| Encoder tuyệt đối | BiSS-C / EnDat 2.2 (có CRC, bit lỗi) ưu tiên hơn SSI (không CRC) |
| Ngoại vi trên board | SPI (nhanh, xác định), I2C (chậm — cấu hình/giám sát, tránh đường RT) |
| Console ↔ cart, video, dữ liệu lớn | Ethernet (UDP, TSN/VLAN, có thể DDS) + lớp E2E |
| Dịch vụ, cập nhật, chẩn đoán | USB / UART — cô lập khỏi đường điều khiển (segregation trong SAD) |

# Bằng chứng (docs/07)
- Unit test: parser/encoder khung, CRC với vector chuẩn từ spec, mọi mã lỗi, biên counter wrap-around.
- Integration/HIL (skill `integration-test`): fault injection — mất khung, CRC sai, lặp, trễ > deadline, rút cáp, bus-off,
  nhiễu → đo thời gian phát hiện & phản ứng so với yêu cầu.
- Đo trên phần cứng đích: tải bus, latency, jitter, cycle overrun.
- Fuzz test cho mọi parser nhận dữ liệu từ ngoài.

# Review (bổ sung cho `embedded-review`) — REJECT nếu
Dùng dữ liệu trước khi kiểm lỗi driver/length/CRC/counter; counter không xử lý wrap; timeout bằng sleep tương đối hoặc
clock không monotonic; `memcpy`/cast buffer vào struct; buffer ISR/DMA chia sẻ không theo cơ chế đã chốt; bỏ qua mã lỗi driver,
WKC, nE/nW, error passive/bus-off; tự retry/reset/re-init rồi cho hoạt động lại mà SDD không cho phép.
