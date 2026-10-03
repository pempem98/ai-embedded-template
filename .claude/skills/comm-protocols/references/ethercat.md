# EtherCAT (+ CoE / CiA 402, Distributed Clocks, FSoE)

## Đặc điểm cần nhớ
- Master–slave trên Ethernet; khung đi qua mọi slave (processing on the fly). Chu kỳ thường 1–8 kHz tùy số slave/payload.
- ESM: INIT → PRE-OP → SAFE-OP → OP (+ BOOT). SAFE-OP: input hợp lệ, output giữ trạng thái an toàn.
- Working Counter (WKC) mỗi datagram phải bằng giá trị mong đợi; sai → dữ liệu chu kỳ đó không hợp lệ.
- Distributed Clocks: SYNC0/SYNC1, reference clock thường là slave DC đầu tiên; theo dõi system time difference.
- SyncManager watchdog trong ESC: mất cập nhật process data → output slave về trạng thái an toàn sau thời gian cấu hình.
- CoE: SDO (mailbox, cấu hình) & PDO (process data). Drive thường CiA 402 (CSP/CSV/CST).
- FSoE (Safety over EtherCAT, IEC 61784-3-12): black channel, tới SIL 3; FSoE master (thường ở safety controller) ↔ FSoE slave;
  connection ID, watchdog, CRC riêng.

## Chốt trong SDD
- Master stack (SOUP) & phiên bản: IgH EtherLab (Linux), SOEM, acontis EC-Master (Linux/QNX)...; ENI/ESI là configuration item.
- Chu kỳ, DC mode, SYNC0 shift; thread cyclic (CPU, priority — skill linux-rt-design/qnx-design); master bám DC hay ngược lại.
- DC chi tiết (skill `distributed-sync-control`):
  - **Master shift**: thread cyclic của master điều chỉnh pha/chu kỳ bám reference clock (jitter bus tốt nhất, đồng hồ hệ thống tự do).
    **Bus shift**: reference clock bị kéo theo thời gian master (cần đồng hồ master ổn định, vd. khi master bám PTP). Chọn một, ghi ADR.
  - Khởi động: đo propagation delay, bù offset, bù drift tĩnh (nhiều khung ARMW) TRƯỚC khi vào SAFE-OP/OP; chỉ vào OP khi
    |System Time Difference| (0x092C) < ngưỡng ở mọi slave DC.
  - Vận hành: mỗi chu kỳ cập nhật application time + đồng bộ reference/slave clocks đúng điểm (vd. IgH
    `ecrt_master_application_time`, `ecrt_master_sync_reference_clock`, `ecrt_master_sync_slave_clocks`); giám sát
    0x092C định kỳ, SM event missed / sync error counter (0x1C32/0x1C33: sync type, cycle time, shift time, các bộ đếm lỗi).
  - SYNC0 shift: khung output phải tới mọi slave trước SYNC0 → shift ≥ thời gian gửi khung + truyền qua chuỗi + margin;
    input latch tại SYNC0/SYNC1 đọc ở chu kỳ sau → trễ 1 chu kỳ đưa vào ngân sách timing.
  - CiA 402 CSP: 0x60C2 (interpolation time period) = chu kỳ bus; target cập nhật mỗi chu kỳ; hành vi drive khi lỡ một chu kỳ
    (ngoại suy/giữ/fault) lấy từ manual drive (task research) và ghi SDD; following error window 0x6065.
- WKC mong đợi từng domain; số chu kỳ sai liên tiếp N cho phép → safe state.
- Phản ứng khi slave rời OP / AL status code ≠ 0 / link down / topology thay đổi; có cho phép tự đưa lại OP không.
- CiA 402: mode (CSP thường dùng cho teleop), giới hạn bước vị trí/vận tốc, quick stop, fault reaction; logic chuyển trạng thái do Lead.
- FSoE: phân vai safety controller, watchdog time, dữ liệu safe in/out, FSoE master ở đâu; stack FSoE là SOUP có chứng nhận.
- Cable redundancy (nếu dùng) và hành vi khi đứt một nhánh.

## Hazard điển hình
Dùng dữ liệu khi WKC sai; mất đồng bộ DC → jitter khớp/rung; slave tụt khỏi OP không bị phát hiện; PDO mapping sai thứ tự trục;
cycle overrun cộng dồn; ENI sai phiên bản phần cứng; target position nhảy khi chuyển mode.

## Bằng chứng
cyclictest + đo jitter chu kỳ thực tế dưới tải; rút cáp giữa chuỗi; tắt nguồn một slave; đo DC drift;
kiểm tra phản ứng SM watchdog & FSoE watchdog; đo thời gian từ lỗi đến safe state.
