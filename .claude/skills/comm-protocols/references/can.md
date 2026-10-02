# CAN / CAN FD / CANopen / CiA 402

## Đặc điểm cần nhớ
- Classic CAN: ID 11/29 bit, ≤ 8 byte, ≤ 1 Mbit/s, CRC-15. CAN FD: ≤ 64 byte, data phase thường 2–5 Mbit/s (tới ~8),
  CRC-17/21; tốc độ data cao cần transmitter delay compensation (TDC).
- Arbitration theo ID: ID nhỏ ưu tiên cao → phân bổ ID là quyết định thiết kế (message an toàn/thời gian thực ưu tiên cao).
- Error confinement: error active → error passive (TEC hoặc REC > 127) → bus-off (TEC > 255).
  Phục hồi bus-off cần 128 lần 11 bit recessive; tự động hay chờ lệnh là quyết định thiết kế.

## Chốt trong SDD
- Bảng message (DBC hoặc bảng): ID, DLC, chu kỳ, nguồn/đích, layout bit, endianness, scaling, timeout phía nhận.
- Bit timing: nominal/data bitrate, sample point, SJW, TDC — tính theo clock controller & chiều dài cáp/stub; giới hạn bus load
  worst case (gợi ý ≤ 50–60%) và bằng chứng tính toán.
- Chính sách error passive / bus-off và phản ứng của safety function (mất mạng phụ có được tiếp tục chuyển động?).
- Lớp E2E cho message an toàn: CRC ứng dụng + alive counter + timeout; hoặc CANopen Safety (EN 50325-5) SRDO
  (dữ liệu gửi kèm bản đảo bit, chu kỳ SCT / thời gian SRVT).
- Mailbox/FIFO, filter phần cứng, xử lý RX overrun; tránh ghi đè mailbox làm dữ liệu stale.
- CANopen: NMT, heartbeat producer/consumer time, PDO mapping, SYNC, SDO timeout.
- CiA 402: state machine drive (Not ready to switch on → Switch on disabled → Ready to switch on → Switched on →
  Operation enabled; Quick stop active; Fault reaction active → Fault). Logic chuyển trạng thái & phản ứng fault do Lead viết.
- Nền tảng: MCU (FDCAN/bxCAN/MCAN HAL), Linux SocketCAN (CAN_RAW, CAN FD frames, error frames), QNX (driver CAN của BSP).

## Hazard điển hình
Mất/chậm message lệnh → khớp giữ lệnh cũ; babbling idiot chiếm bus; ID trùng giữa node; bus-off im lặng;
dữ liệu stale do mailbox bị ghi đè; sai endianness/scaling; drive tự vào Operation enabled sau reset.

## Bằng chứng
Tính & đo bus load, latency worst-case; fault injection: ngắt cáp/termination, CRC lỗi, node babbling, bus-off;
đo thời gian phát hiện mất heartbeat và thời gian đến safe state.
