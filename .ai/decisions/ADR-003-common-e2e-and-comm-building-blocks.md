# ADR-003 — Lớp E2E chung, khối kiểm tra phía nhận và wrapper DDS typed
Status: Accepted
Date: 2026-10-03   Phạm vi: toàn dự án (giao tiếp giữa service/node)   Người quyết định: Lead (đề xuất) — người dùng chốt
2026-10-03 (CRC-32, CRC trên mã hóa chuẩn tắc; nguồn `epoch` và độ rộng trường giao Lead đề xuất theo hướng ưu tiên Class C)

## Bối cảnh
ADR-001 để ngỏ lớp E2E ("định nghĩa theo từng interface"). Với nhiều service do nhiều người viết, mỗi interface tự định nghĩa
header/CRC/counter sẽ cho ra nhiều biến thể của cùng một risk control, mỗi biến thể phải verify riêng. Skill `comm-safety` bắt
worker viết lại 7 bước kiểm tra ở mọi driver, trong đó CRC, sequence và tuổi dữ liệu giống hệt nhau giữa các giao thức.

## Quyết định
1. **Một header E2E** (30 byte) cho mọi message an toàn do dự án định nghĩa (topic DDS, khung UDP/UART tự định nghĩa giữa node).
   Kiểu IDL `E2eHeader` (`@final`) ở `vsur-idl`; trên link không phải DDS mã hóa little-endian theo đúng thứ tự dưới đây:
   | Trường | Kiểu | Chống lỗi |
   |---|---|---|
   | `data_id` | u32 — duy nhất cho từng topic/loại message, cấp trong bảng ICD | giả mạo, sai kiểu, chèn |
   | `epoch` | u32 — phiên của bên gửi (mục 3) | dữ liệu của phiên cũ, tiến trình cũ còn sống, late joiner |
   | `seq` | u32 — tăng 1 mỗi lần gửi, số học modulo, về 0 khi `epoch` đổi | lặp, mất, sai thứ tự |
   | `timestamp_us` | i64 — thời gian monotonic trong miền đồng hồ chung | trễ, dữ liệu cũ |
   | `source_id` | u16 — định danh thực thể gửi | giả mạo nguồn |
   | `length` | u16 — số byte payload chuẩn tắc | cắt cụt, sai độ dài |
   | `clock_domain` | u8 | so tuổi giữa hai miền đồng hồ khác nhau |
   | `e2e_version` | u8 — phiên bản bố cục header | bên gửi/nhận khác phiên bản |
   | `crc` | u32 | hỏng dữ liệu |
2. **CRC**: preset `kCrc32Autosar` — width 32, poly 0xF4ACFB13, init 0xFFFFFFFF, refin true, refout true, xorout 0xFFFFFFFF,
   check 0x1697D06A (khác đa thức CRC-32 của Ethernet). Tính trên header (trừ `crc`) nối với **mã hóa chuẩn tắc của payload**:
   từng trường theo thứ tự IDL, little-endian, không padding, do code dự án thực hiện cho từng kiểu — không dùng byte do vendor
   DDS tuần tự hóa.
3. **Nguồn `epoch`** — ssm-service là nơi cấp duy nhất: 16 bit cao = bộ đếm khởi động của ssm-service (lưu bền, hai bản sao có
   CRC; không đọc được → ssm-service không khởi động); 16 bit thấp = số lần ssm-service cho service đó vào ACTIVE. Service nhận
   `epoch` trong lệnh chuyển trạng thái và đặt `seq = 0`. `epoch = 0` nghĩa là chưa có phiên: dữ liệu mang `epoch = 0` không được
   dùng cho điều khiển. ssm-service công bố `epoch` hiện hành của từng nguồn; bên nhận so **khớp với giá trị được công bố**, không
   chỉ phát hiện thay đổi.
4. **Profile theo từng message**: `struct E2eProfile` `constexpr`, không phải template — `data_id`, `source_id` hợp lệ, độ dài
   payload, `max_age`, `max_seq_gap` (số mẫu mất chấp nhận được), `rx_timeout`, `clock_domain`. Sinh từ bảng ICD trong
   `vsur-idl`, không viết tay ở service.
5. **Khối dùng chung trong `vsur-common`** (`include/comm/`, namespace `vsur::comm`, Class C):
   - `E2eProtector`: giữ `epoch`/`seq`, điền header khi gửi.
   - `E2eChecker`: giữ trạng thái nhận; `check()` trả một trong `Ok, CrcMismatch, WrongId, WrongVersion, LengthError, Repeated,
     SequenceGap, Stale, WrongEpoch`; `check_timeout(now)` phát hiện không có mẫu hợp lệ trong `rx_timeout`. Mẫu đầu tiên sau init
     hoặc sau khi `epoch` đổi chỉ dùng để đồng bộ, chưa được dùng cho điều khiển.
   - `ErrorMonitor`: đếm theo loại lỗi, ngưỡng và cửa sổ lấy từ SDD; vượt ngưỡng → `safety::report_fault`. Không tự phục hồi về
     trạng thái hoạt động — việc cho hoạt động lại do ssm-service quyết.
   Code riêng của từng giao thức vẫn tự làm: mã lỗi driver, độ dài khung, kiểu/phiên bản khung, miền giá trị (bước 1, 2, 4, 7 của `comm-safety`).
6. **Wrapper DDS typed** `SafeWriter<T>` / `SafeReader<T>` (T = kiểu sinh từ IDL) và hàm mã hóa chuẩn tắc của từng kiểu, đặt
   cùng repo `vsur-idl` vì tập kiểu là đóng (bảng topic) → explicit instantiation và test cho từng topic nằm ở đó, service không
   phải test lại (ADR-002 #4, #5). Wrapper: tạo entity ở init từ tên QoS profile và đọc lại QoS để so; nhận bằng WaitSet trong
   thread của dự án; kiểm `valid_data` / `instance_state` rồi gọi `E2eChecker` + `ErrorMonitor`; không được gọi từ thread RT.
   Logic của service phụ thuộc interface `Publisher<T>` / `Subscriber<T>` thuần ảo để unit test bằng fake; kiểu của vendor DDS
   không lộ ra header công khai.
7. **Không gom**: khung và state machine riêng của giao thức (CANopen NMT/SDO/PDO, EtherCAT PDO/WKC/DC, BiSS-C, EnDat, thanh ghi
   SPI/I2C). Không tạo lớp `Transport<T>` chung cho mọi bus. Không bọc E2E của dự án lên FSoE / CANopen Safety / BiSS safety.
8. MCU (C): module `vsur_e2e` cùng định dạng byte; một bộ test vector dùng chung cho bản C và C++ lưu ở `vsur-idl`.

## Còn mở (không chặn ADR, chặn việc viết code)
- Phân tích độ đủ của CRC-32 theo độ dài message tối đa và xác suất lỗi dư chấp nhận được: làm trong SDD-common-comm, giao
  `fw-safety-assessor` đánh giá; SDD chốt độ dài payload tối đa cho message an toàn. Đối chiếu tham số preset với tài liệu chuẩn
  gốc trong SDD (check value ở mục 2 đã được tính lại, chưa đối chiếu với tài liệu gốc).
- Phụ thuộc ADR chưa có: vendor DDS, miền đồng hồ & PTP (skill `service-architecture`, mục câu hỏi phải chốt).
- Chi tiết cấp và công bố `epoch`: SDD của ssm-service.

## Hệ quả cho code / test
- Thay mục "Lớp E2E: TBD" của ADR-001 và `project-conventions`.
- Cần SDD-common-comm (Class C) trước khi viết code; header `OWNER: lead`. Mã lỗi mới cho `vsur::Error` và preset
  `kCrc32Autosar` do Lead thêm.
- Test: vector CRC, wrap của `seq`, lặp/mất/đảo, tuổi tại `max_age−1 / max_age / max_age+1`, `epoch` sai/bằng 0/đổi,
  `data_id`/`source_id`/`e2e_version` lạ, `length` sai, timeout nhận; fault injection end-to-end ở mức integration.
- Worker không tự định nghĩa header/CRC/counter riêng cho message an toàn; cần khác chuẩn này → HỎI.

## Truy vết
ADR-001 #7 và mục E2E để ngỏ; ADR-002 (template). HAZ/RCM về lỗi truyền thông: gắn khi `/hazard` cho từng interface. Mô hình lỗi
kênh truyền theo skill `comm-protocols` (black channel).
