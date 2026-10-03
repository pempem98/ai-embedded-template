---
name: distributed-sync-control
description: Thiết kế điều khiển đồng bộ (synchronized control) và điều khiển phân tán (distributed control) cho robot phẫu thuật — miền đồng hồ (CLOCK_MONOTONIC, EtherCAT DC, PTP/gPTP, CANopen SYNC), vòng đa tần số & rate transition, snapshot nhất quán đa trục, ngân sách latency end-to-end, vòng kín đặt ở đâu, teleop có trễ/force feedback, state machine phân tán (ssm-service), phản ứng khi mất đồng bộ/mất liên lạc. Dùng khi /arch, /design cho teleop/kinematics/ssm/comm-service, khi ghép nhiều service/node/bus, hoặc người dùng nhắc "đồng bộ", "sync", "distributed", "phân tán", "latency", "jitter", "clock".
---
# Cách dùng
Đọc phần dưới; chi tiết: `references/timing-budget.md` (bảng ngân sách & đo), `references/distributed-ssm.md` (state machine
phân tán). Giao thức: skill `comm-protocols` (ethercat · canopen · dds · ethernet). Mọi lựa chọn dưới đây chốt trong SAD/SDD/ADR
và task card — worker dùng skill `sync-control-impl`, không tự chọn. Logic đồng bộ RT & chuyển safe state: Lead tự viết (`/lead`).

# 1. Miền đồng hồ — vẽ trong SAD (deployment view), mỗi timestamp ghi rõ thuộc miền nào
| Miền | Nguồn | Dùng cho | Không dùng cho |
|---|---|---|---|
| Local monotonic | `CLOCK_MONOTONIC` mỗi node/OS | deadline, timeout, chu kỳ cục bộ | so sánh giữa 2 node |
| EtherCAT DC | reference clock (slave DC đầu) | SYNC0/SYNC1, latch input, CSP | đồng hồ khác node |
| PTP / gPTP (IEEE 1588 / 802.1AS) | grandmaster, `ptp4l` + `phc2sys` (SOUP) | timestamp liên node, stale check xuyên mạng | deadline cục bộ khi chưa lock |
| CANopen SYNC / TIME | SYNC producer (master) | latch/áp dụng PDO đồng bộ | đo thời gian tuyệt đối |
| QNX `ClockCycles`/monotonic | node QNX | như local monotonic | — |
Chốt: (a) node/miền nào là master thời gian; (b) ánh xạ giữa miền (vd. thread RT Linux bám DC — `master shift` —
hay DC bám PTP — `bus shift`); (c) ngưỡng lệch cho phép (offset, drift) và cách giám sát định kỳ; (d) **hành vi khi mất
đồng bộ**: chuyển sang stale-check theo sequence + thời điểm nhận cục bộ, giảm chế độ (vd. cấm teleop, chỉ giữ vị trí), báo SSM.
Đồng hồ chưa lock lúc khởi động → không vào chế độ cần nó.

# 2. Vòng điều khiển — đặt vòng kín ở đâu
- Vòng nhanh (dòng/tốc độ/vị trí khớp, kHz) kín trên drive hoặc trên node RT nối trực tiếp fieldbus xác định (EtherCAT/CAN).
  **KHÔNG khép vòng nhanh qua DDS/Ethernet không xác định.** DDS mang setpoint/trạng thái mức trên (teleop, kinematics, SSM).
- Mỗi tầng có giám sát cục bộ độc lập tầng trên: mất setpoint từ tầng trên quá timeout → tầng dưới tự về hành vi an toàn đã
  định nghĩa (giữ vị trí / quick stop / phanh), không chờ lệnh.
- Bảng vòng (SAD/context-brief): loop · node · chu kỳ · deadline · pha (offset trong chu kỳ) · nguồn trigger (timer/DC/SYNC) ·
  đầu vào từ đâu (tuổi tối đa) · đầu ra tới đâu · phản ứng overrun.

# 3. Đa tần số & rate transition (ghi trong SDD cho từng cặp producer → consumer)
| Trường hợp | Cơ chế | Phải chốt |
|---|---|---|
| Nhanh → chậm | lấy mẫu mới nhất (triple buffer / KEEP_LAST 1) hoặc lọc decimation | bộ lọc, aliasing |
| Chậm → nhanh | nội suy (tuyến tính/cubic) hoặc ZOH có giới hạn; drive CSP nội suy theo 0x60C2 | trễ thêm do nội suy, giới hạn bước/vận tốc/gia tốc |
| Mất mẫu | ngoại suy tối đa N chu kỳ rồi giữ/dừng có kiểm soát | N, tuổi tối đa, phản ứng |
| Lệch pha | căn pha: tính xong trước thời điểm gửi khung/SYNC0 | offset pha, margin |
Mọi mẫu mang timestamp (miền rõ ràng) + sequence; consumer kiểm tuổi = now − timestamp (cùng miền) ≤ max_age.

# 4. Đồng bộ đa trục / đa cánh tay
- Snapshot nhất quán: mọi khớp của một chuỗi động học phải cùng chu kỳ latch (EtherCAT: 1 frame + DC; CANopen: cùng SYNC,
  kiểm sync counter; nhiều bus: ghép theo timestamp trong cùng miền). Snapshot thiếu/lẫn chu kỳ → không tính kinematics chu kỳ đó.
- Lệnh đa trục áp dụng cùng thời điểm (cùng SYNC0 / cùng SYNC); không gửi lẻ từng trục qua kênh khác pha.
- Kinematics/teleop đầu vào phải là bộ (q, t, seq) đã kiểm; đầu ra kèm seq của đầu vào để truy vết trễ end-to-end.

# 5. Teleoperation có trễ
- Ngân sách latency tay cầm → đầu dụng cụ (và video → mắt) suy ra từ yêu cầu usability/human factors, không tự đặt.
  Đo phân phối (p50/p99/max), không chỉ trung bình. Dữ liệu tham khảo: hiệu suất phẫu thuật viên giảm rõ khi trễ tăng
  (vùng ~100–200 ms trở lên) — con số cụ thể phải từ nghiên cứu/validation của dự án.
- Lệnh teleop là luồng setpoint "mới nhất thắng": không xếp hàng, không phát lại lệnh cũ (DDS BEST_EFFORT + KEEP_LAST 1 + lifespan,
  hoặc RELIABLE có giới hạn backlog — chốt trong ADR). Lệnh quá tuổi → bỏ; mất liên tục > T → dừng có kiểm soát.
- Clutch/indexing, motion scaling, giới hạn vận tốc/gia tốc đầu dụng cụ áp dụng ở phía cart (gần actuator), không chỉ phía console.
- Force feedback hai chiều + trễ: phải có lập luận ổn định (passivity — vd. wave variables, time-domain passivity approach)
  trong SDD + bằng chứng mô phỏng/HIL; không có → không bật force feedback.

# 6. Điều khiển phân tán & state machine hệ thống
- Một nguồn quyết định trạng thái hệ thống (ssm-service); service khác là follower: báo trạng thái, yêu cầu chuyển, thực hiện lệnh.
- Mỗi service có phản ứng an toàn cục bộ khi mất SSM/mất đồng bộ — không phụ thuộc mạng còn sống. Chi tiết: `references/distributed-ssm.md`.
- Linux là SOUP không chứng nhận: chức năng Class C phân tán cần kênh giám sát độc lập (safety supervisor MCU/QNX, FSoE, phanh phần cứng).

# 7. Hazard điển hình (đưa vào /hazard)
Dùng mẫu stale như mới (đồng hồ lệch, mất sync không phát hiện); snapshot lẫn chu kỳ → kinematics sai; backlog lệnh → robot
"đuổi theo" lệnh cũ; ngoại suy không giới hạn → nhảy vị trí; drift DC → jitter/rung; rate transition không giới hạn bước;
hai service cùng tự coi là authority; service khởi động lại tự tiếp tục chuyển động; overrun cộng dồn làm lệch pha.

# 8. Bằng chứng (docs/07, skill `integration-test`)
Đo trên phần cứng đích dưới tải: jitter mỗi vòng, offset pha giữa vòng (GPIO toggle + oscilloscope/logic analyzer, hoặc
timestamp HW), latency end-to-end histogram, offset/drift PTP & DC theo thời gian; fault injection: mất grandmaster, rút cáp
EtherCAT, dừng SYNC producer, kill/restart từng service, trễ/mất gói (tc netem), CPU stress → đo thời gian phát hiện + phản ứng
so với RCM.

# Review — REJECT nếu
So sánh timestamp khác miền; dùng `CLOCK_REALTIME` cho deadline; không có max_age/stale check; ngoại suy không giới hạn; vòng
nhanh khép qua DDS/TCP; follower tự quyết chuyển chế độ; phản ứng mất liên lạc phụ thuộc vào chính kênh đã mất; thiếu bằng chứng
đo jitter/latency cho yêu cầu timing.
