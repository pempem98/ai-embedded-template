---
name: proto-ethernet
description: Implement giao tiếp Ethernet (UDP/TCP, DDS, PTP) giữa các node (console ↔ cart, vision, dịch vụ). Áp dụng khi protocols có ethernet.
---
# Ethernet / UDP / DDS
- Port, địa chỉ, kích thước, chu kỳ, deadline, QoS/VLAN: đúng task card. Middleware (DDS...) là SOUP — dùng đúng API & QoS profile chỉ định.
- Dữ liệu chu kỳ/điều khiển: UDP + lớp E2E của dự án (CRC, sequence, timestamp, source ID). TCP chỉ cho cấu hình/log, không trong đường RT.
- Kích thước gói ≤ MTU đã chốt (không phụ thuộc phân mảnh IP); datagram sai kích thước → loại.
- Socket non-blocking hoặc có timeout; kiểm tra mọi giá trị trả về/errno; nhận trong thread & CPU task card chỉ định.
- Video/trạng thái hiển thị: giữ & truyền frame counter/timestamp để phía hiển thị phát hiện đông cứng (theo task card).
- Dữ liệu từ mạng ngoài thiết bị là không tin cậy (cyber): parser phòng thủ, không cấp phát theo length nhận, xác thực/mã hóa theo task card.
- Test: mất/lặp/đảo thứ tự/trễ gói, gói cắt cụt/quá lớn, source ID sai, flood không làm trễ thread RT.
