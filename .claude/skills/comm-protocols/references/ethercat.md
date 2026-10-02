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
