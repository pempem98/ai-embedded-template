# Ngân sách timing & cách đo

## Bảng ngân sách end-to-end (đặt trong SAD, mỗi dòng truy vết tới SRS/RCM)
| Chặng | Node / thread | Chu kỳ | Trễ worst-case (thiết kế) | Đo được (p99 / max) | Nguồn số liệu |
|---|---|---|---|---|---|
| Đọc tay cầm (encoder → mẫu) | console MCU/RT | | | | |
| Console → cart (mạng, DDS) | NIC, DDS thread | | | | |
| Teleop mapping (scaling, clutch, giới hạn) | teleop-service | | | | |
| Inverse kinematics | kinematics-service | | | | |
| Chờ pha tới chu kỳ fieldbus kế tiếp | comm-service | | ≤ 1 chu kỳ | | |
| Fieldbus → drive (SYNC0 shift / SYNC window) | EtherCAT / CANopen | | | | |
| Nội suy drive (CSP) + vòng servo | drive | | | | |
| **Tổng** (≤ yêu cầu SRS) | | | | | |
Quy tắc: worst-case = cộng chu kỳ chờ pha tối đa + thời gian tính WCET đo được + trễ truyền tối đa; không dùng trung bình.
Biên dự trữ (margin) ghi rõ, gợi ý ≥ 20% với giá trị đo max.

## Ngân sách phát hiện lỗi (fault detection + reaction ≤ thời gian an toàn của HAZ)
| Lỗi | Cơ chế phát hiện | Thời gian phát hiện | Phản ứng | Thời gian phản ứng | Tổng ≤ |
|---|---|---|---|---|---|
| Mất lệnh teleop | timeout tuổi mẫu | | giữ vị trí → quick stop | | |
| Service treo | DDS liveliness MANUAL / heartbeat | | SSM → safe state | | |
| Mất sync DC | 0x092C / sync error counter | | | | |
| Mất PTP lock | offset > ngưỡng / servo state | | giảm chế độ | | |

## Đo (bằng chứng)
- Jitter vòng: timestamp đầu chu kỳ mỗi vòng (ring buffer, xả non-RT) → histogram, max; chạy ≥ thời gian đủ dài dưới
  stress (CPU `stress-ng`, mạng, I/O) — thời lượng chốt trong test spec.
- Lệch pha giữa node: GPIO toggle tại điểm mốc trên mỗi node + logic analyzer, hoặc timestamp HW (PHC) cùng miền PTP.
- End-to-end: chèn seq + timestamp nguồn, ghi timestamp tại từng chặng (cùng miền PTP) → phân rã trễ theo chặng.
- WCET: đo trên phần cứng đích với cache lạnh/nóng, đầu vào worst-case; ghi phương pháp — WCET đo không phải bằng chứng tuyệt đối,
  cần margin.
- Ghi phiên bản kernel, cấu hình isolcpus/IRQ affinity, firmware drive, ENI/DCF khi đo (configuration item).
