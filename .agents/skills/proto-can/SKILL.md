---
name: proto-can
description: Implement CAN / CAN FD / CANopen / CiA 402 (MCU HAL, Linux SocketCAN, QNX). Áp dụng khi protocols có can.
---
# CAN / CAN FD / CANopen
- Dùng ĐÚNG bảng message của task card (ID, DLC, layout bit, endianness, scaling, chu kỳ, timeout). Không tự đổi ID/DLC/filter.
- Classic CAN: payload ≤ 8 byte. CAN FD: độ dài hợp lệ chỉ 0–8, 12, 16, 20, 24, 32, 48, 64 — dùng hàm chuyển DLC↔length, kiểm tra cả hai chiều.
- Nhận: ID nằm trong bảng, DLC đúng giá trị mong đợi, rồi theo comm-safety. Message an toàn: CRC + alive counter của lớp E2E dự án.
- Giám sát trạng thái controller (error warning / error passive / bus-off), RX overrun / FIFO full → báo theo task card.
  Phục hồi bus-off CHỈ theo chính sách task card.
- Gửi: kiểm tra kết quả queue TX; TX đầy / timeout là lỗi phải trả về.
- Linux SocketCAN: `CAN_RAW`; CAN FD bật `CAN_RAW_FD_FRAMES` và kiểm tra `read()` trả đúng `CAN_MTU`/`CANFD_MTU`;
  nhận error frame qua `CAN_RAW_ERR_FILTER` (mask theo task card); socket non-blocking hoặc chờ có timeout;
  không gọi trong vòng RT nếu task card không cho phép.
- QNX: API driver CAN của BSP theo task card. MCU: HAL FDCAN/bxCAN/MCAN của dự án; ISR do Lead viết.
- CANopen: OD/PDO mapping theo task card; heartbeat consumer timeout; SDO luôn có timeout & xử lý abort code; NMT chỉ theo chỉ định.
- CiA 402 (drive): chỉ gửi controlword theo state machine Lead cung cấp; đọc statusword trước khi chuyển;
  không tự chuyển trạng thái drive, không tự clear fault.
- Test: ID/DLC sai, DLC FD không hợp lệ, counter lặp/nhảy, timeout chu kỳ, bus-off & error passive (mock), TX đầy.
