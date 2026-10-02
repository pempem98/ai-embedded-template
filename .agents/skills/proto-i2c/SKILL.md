---
name: proto-i2c
description: Implement giao tiếp thiết bị I2C/SMBus trên lớp HAL. Áp dụng khi protocols có i2c.
---
# I2C / SMBus
- Địa chỉ, tốc độ, thanh ghi, độ dài: đúng task card. Mọi giao dịch có timeout; NACK, arbitration lost, timeout là lỗi phải trả về.
- Không có CRC (trừ SMBus PEC — dùng nếu task card yêu cầu). Kiểm tra plausibility/status bit của thiết bị.
- Bus treo (SDA giữ thấp): chỉ thực hiện thủ tục phục hồi task card chỉ định (vd. tối đa 9 xung SCL + STOP); không tự reset thiết bị.
- Retry: chỉ số lần task card cho phép; không retry vô hạn.
- Không gọi I2C trong vòng RT cứng nếu task card không cho phép.
- Test (mock HAL): NACK địa chỉ/dữ liệu, timeout, bus busy, giá trị ngoài miền, thiết bị reset về mặc định.
