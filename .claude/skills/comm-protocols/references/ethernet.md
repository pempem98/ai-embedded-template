# Ethernet (UDP/TCP, TSN, PTP, DDS) — console ↔ patient cart, vision, dịch vụ

## Đặc điểm cần nhớ
- Ethernet chuẩn không xác định thời gian; dùng mạng riêng point-to-point, VLAN/QoS, hoặc TSN (vd. 802.1Qbv, 802.1AS) để giới hạn trễ.
- UDP cho dữ liệu chu kỳ (lệnh teleop, trạng thái); TCP cho cấu hình/log (retransmission → không dùng trong đường RT).
- Middleware DDS (Fast DDS, Cyclone DDS, RTI Connext — có bản hướng safety) là SOUP lớn.

## Chốt trong SDD
- Topology; cô lập mạng điều khiển khỏi mạng bệnh viện (skill medical-cybersecurity).
- Bảng message: port, chu kỳ, kích thước, deadline, QoS; MTU — tránh phân mảnh IP cho dữ liệu RT.
- Lớp E2E: CRC + sequence + timestamp + source ID; timeout phía nhận và phản ứng (mất lệnh teleop → dừng có kiểm soát).
- Đồng bộ thời gian (PTP/802.1AS) & hành vi khi mất đồng bộ.
- NIC IRQ affinity, thread nhận, priority (skill linux-rt-design / qnx-design).
- Video: cơ chế phát hiện đông cứng (frame counter/timestamp giám sát độc lập, chỉ báo cho phẫu thuật viên).
- Kênh ra ngoài thiết bị: xác thực, mã hóa (TLS), đóng cổng không dùng.

## Hazard điển hình
Video đông cứng nhưng hiển thị như trực tiếp; lệnh teleop trễ/lặp/đảo thứ tự; broadcast storm làm quá tải CPU;
giả mạo gói; mất đồng bộ thời gian làm sai kiểm tra stale.

## Bằng chứng
Đo latency end-to-end & jitter dưới tải; inject mất/trễ/lặp/đảo gói (vd. tc netem trên Linux); flood test; fuzz parser; pentest.
