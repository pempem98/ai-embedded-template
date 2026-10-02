# UART / RS-232 / RS-422 / RS-485 (Modbus RTU)

## Đặc điểm cần nhớ
- Không đồng bộ; khung: baud, data bits, parity, stop bits. Lỗi phần cứng: framing, parity, overrun, noise, break.
- RS-485 half-duplex: điều khiển DE/RE, thời gian turnaround, termination 120 Ω hai đầu, fail-safe biasing.
- Byte stream không có ranh giới khung → cần framing (header+length, COBS/SLIP) + CRC. Modbus RTU: khoảng lặng 3.5 ký tự,
  CRC-16/MODBUS.

## Chốt trong SDD
- Thông số khung, giao thức framing & CRC (width, poly, init, refin/refout, xorout), timeout inter-byte & inter-frame,
  kích thước buffer, retry.
- Ai điều khiển DE (UART phần cứng hay GPIO trong ISR — ISR do Lead), master/slave, địa chỉ node.
- Cổng dịch vụ/debug: xác thực, tắt trong chế độ lâm sàng nếu cần (skill medical-cybersecurity).

## Hazard điển hình
Overrun mất byte → ghép sai khung; resync nhầm; DE giữ quá lâu chặn bus; parser tràn buffer với length giả (bề mặt tấn công nếu là cổng dịch vụ).

## Bằng chứng
Parser test: khung cắt đôi, byte rác, length lớn, CRC sai; fuzz; đo turnaround bằng scope.
