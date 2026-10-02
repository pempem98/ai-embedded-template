---
name: proto-uart
description: Implement giao tiếp UART / RS-232 / RS-422 / RS-485 (framing, Modbus RTU, protocol dự án). Áp dụng khi protocols có uart.
---
# UART / RS-485
- Baud, data bits, parity, stop bits, flow control: đúng task card.
- Lỗi phần cứng (framing, parity, overrun, noise, break) → đếm, loại bỏ khung đang ghép, theo task card.
- Byte stream không có ranh giới: dùng ĐÚNG framing task card (header+length, COBS/SLIP, Modbus RTU khoảng lặng 3.5 ký tự) + CRC.
  Parser là state machine tường minh, có timeout inter-byte/inter-frame, tự resync khi gặp rác.
- Trường length chỉ tin sau khi kiểm tra ≤ buffer; KHÔNG cấp phát theo length nhận được.
- RS-485 half-duplex: điều khiển DE/RE đúng thời điểm task card (thường do ISR/peripheral của Lead); timeout chờ phản hồi; không gửi khi đang nhận.
- Modbus RTU: CRC-16/MODBUS (poly 0x8005 reflected = 0xA001, init 0xFFFF) — vẫn đối chiếu tham số task card; xử lý exception response.
- Test: khung cắt đôi, byte rác trước/sau, length 0/max/max+1, CRC sai, timeout giữa khung, overrun;
  parser cổng dịch vụ → fuzz test nếu task card yêu cầu.
