---
name: safety-architecture
description: Mẫu kiến trúc an toàn cho robot phẫu thuật (theo cách các hệ thống như da Vinci, Hugo RAS, Toumai, Senhance phân tầng) — safety monitor, segregation, safe state, watchdog, dư thừa, teleoperation. Dùng khi thiết kế kiến trúc, chia software item, quyết định đặt logic an toàn ở đâu, hoặc review thay đổi ảnh hưởng an toàn.
---
# Phân tầng điển hình (tham khảo kiến trúc công khai của ngành, không phải thiết kế của hãng cụ thể)
| Tầng | Nền tảng thường gặp | Vai trò | Class |
|---|---|---|---|
| Surgeon console UI / video | Linux/QNX | Hiển thị, tương tác | B/C (video là C nếu ảnh hưởng thao tác) |
| Teleoperation & kinematics | QNX / Linux PREEMPT_RT, 1–4 kHz | Master→slave mapping, scaling, tremor filter | C |
| Safety supervisor | CPU/MCU độc lập, đơn giản | Giám sát giới hạn, heartbeat, E-stop, quyết định safe state | C |
| Joint controller | MCU/DSP/FPGA ở khớp | Vòng dòng/vận tốc/vị trí, giới hạn cứng | C |
| Fieldbus | EtherCAT / CAN-FD | Đồng bộ, phát hiện mất frame | C |
| Service, log, cập nhật | Linux | Chẩn đoán, OTA | A/B nếu segregation được chứng minh |

# Nguyên tắc
1. **Logic an toàn đơn giản & độc lập**: safety supervisor không phụ thuộc tầng phức tạp (UI, ML, mạng). Code ít, không cấp phát, dễ đạt coverage 100%.
2. **Phòng thủ nhiều lớp**: giới hạn ở planner + giới hạn ở joint controller + giám sát độc lập + phần cứng (phanh, STO).
3. **Segregation** (62304 §5.3.5): tiến trình/partition riêng (QNX adaptive partitioning, Linux process + cgroup/CPU isolation, MPU trên MCU), giao tiếp qua kênh có kiểm tra (CRC, sequence, timeout). Ghi bằng chứng segregation trong SAD.
4. **Safe state xác định** cho từng chế độ (setup, teleop, instrument exchange, homing): hành vi dừng, phanh, giữ vị trí; chuyển trạng thái là state machine tường minh do Lead viết.
5. **Heartbeat & watchdog** hai chiều giữa các node; mất heartbeat > T → safe state. T suy ra từ phân tích động học (khoảng cách dịch chuyển tối đa trong T).
6. **Dữ liệu điều khiển** luôn có timestamp + sequence + CRC; stale → bỏ, đếm, vượt ngưỡng → safe state.
7. **Clutch / deadman**: không có xác nhận chủ động của phẫu thuật viên → không chuyển động.
8. **Khởi động an toàn**: self-test (RAM/flash CRC, encoder plausibility, phanh) trước khi cho phép chuyển động; phiên bản phần mềm & cấu hình khớp nhau.
9. **Không để thành phần non-safety ghi vào dữ liệu safety** (hướng dữ liệu một chiều hoặc kiểm tra tại biên).
10. **Đo và chứng minh timing**: WCET/jitter của vòng điều khiển, độ trễ end-to-end teleop — có test đo, kết quả vào docs/07.

# Khi thiết kế
- Mỗi software item: class, lý do, nền tảng, chu kỳ, deadline, interface, RCM thực hiện.
- Gemini KHÔNG viết: state machine safe state, safety supervisor core, cấu hình partition/scheduler — bạn viết, kỹ sư review.
