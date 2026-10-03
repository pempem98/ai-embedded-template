# CANopen (CiA 301/302/305/306, CiA 402, EN 50325-5) — tầng ứng dụng trên CAN (xem thêm `can.md` cho tầng link)

## Đặc điểm cần nhớ
- NMT: Initialisation → Pre-operational → Operational ↔ Stopped; boot-up message COB-ID 0x700+node_id (data 0x00).
- Heartbeat: producer time 0x1017, consumer 0x1016 (node, timeout) — ưu tiên hơn node guarding. Error behaviour 0x1029.
- SDO (0x600/0x580 + node_id): expedited/segmented/block; luôn có timeout; abort code (vd. 0x05040000 timeout,
  0x06020000 object không tồn tại, 0x06090030 giá trị ngoài miền).
- PDO: RPDO comm 0x1400+/mapping 0x1600+, TPDO comm 0x1800+/mapping 0x1A00+. Transmission type 1–240 = đồng bộ mỗi n SYNC;
  254/255 = theo sự kiện (inhibit time sub3, event timer sub5).
- SYNC: COB-ID 0x1005, chu kỳ 0x1006, sync window 0x1007 (RPDO đồng bộ đến sau cửa sổ bị bỏ), SYNC counter 0x1019 (đa tần số).
  Node latch input tại SYNC, áp dụng output đồng bộ tại SYNC kế tiếp.
- EMCY (0x80+node_id): error code + error register 0x1001; TIME (0x100); LSS (CiA 305) gán node ID/bitrate.
- CiA 302: master/boot-up process, configuration manager (DCF), kiểm cấu hình (0x1F26/0x1F27 ngày/giờ cấu hình hoặc đọc lại).
- CiA 402 qua CANopen: controlword 0x6040, statusword 0x6041, mode 0x6060/display 0x6061 (PP=1, PV=3, HM=6, IP=7, CSP=8, CSV=9,
  CST=10), interpolation time period 0x60C2, following error window 0x6065, quick stop option 0x605A, fault reaction 0x605E.
- CANopen Safety (EN 50325-5): SRDO (dữ liệu + bản đảo bit, hai COB-ID), SCT/SRVT; stack safety là SOUP có chứng nhận.
- Stack (SOUP): CANopenNode, Lely CANopen, emtas, port, Vector... trên SocketCAN (Linux) / driver BSP (QNX) / HAL (MCU).

## Chốt trong SDD
- Vai trò NMT master, SYNC producer (node nào, thread nào, priority), heartbeat producer/consumer từng node + timeout.
- EDS/DCF từng thiết bị là configuration item (phiên bản firmware tương ứng); quy trình cấu hình lúc boot ở Pre-op
  (tắt PDO bằng bit 31 COB-ID → mapping count 0 → ghi mapping → count → bật) và kiểm lại sau cấu hình.
- Bảng PDO: COB-ID, transmission type, mapping (object, sub, bit length), chu kỳ, inhibit/event timer, consumer & timeout.
- Bus load tính worst-case: frame CAN 8 byte ~111–135 bit (có bit stuffing) → 1 Mbit/s chỉ ~7–9k frame/s lý thuyết.
  Vd. 6 trục × (1 RPDO + 1 TPDO) ở 1 kHz = 12k frame/s → KHÔNG khả thi trên Classic CAN 1 Mbit/s: giảm tần số, gộp PDO, CAN FD
  (CANopen FD, CiA 1301) hoặc EtherCAT. Giới hạn tải gợi ý ≤ 50–60%.
- Sync window & thời điểm master gửi RPDO trong chu kỳ (căn pha với vòng tính toán — skill `distributed-sync-control`).
- Phản ứng: heartbeat mất, EMCY (theo mã), node về Pre-op/Stopped, SDO abort khi cấu hình, bus-off; được phép tự cấu hình lại và
  cho chuyển động lại không.
- CiA 402: state machine & fault reaction do Lead viết; mode được phép; giới hạn bước/vận tốc; homing.

## Hazard điển hình
PDO mapping sai (trục/đơn vị/scaling); RPDO tới ngoài sync window bị drive bỏ âm thầm → giữ lệnh cũ; SYNC jitter/mất SYNC;
bus load quá cao làm trễ PDO; node reset tự vào Operational và nhận lệnh; heartbeat consumer chưa cấu hình → mất node không phát hiện;
cấu hình DCF không khớp firmware; EMCY bị bỏ qua.

## Bằng chứng
Tính + đo bus load; đo jitter SYNC; đo thời gian phát hiện mất heartbeat; tắt nguồn/reset node khi đang Operational; RPDO trễ quá
sync window; SDO timeout/abort; bus-off; kiểm cấu hình sau boot so với DCF; fault reaction CiA 402.
