---
name: proto-spi
description: Implement driver/logic thiết bị SPI (cảm biến, ADC, driver chip) trên lớp HAL. Áp dụng khi protocols có spi.
---
# SPI
- Mode (CPOL/CPHA), tần số, bit order, word size, CS: đúng task card; không tự đổi cấu hình bus.
- SPI không có ACK: thiết bị mất nguồn/rời vẫn đọc ra 0x00/0xFF. Phát hiện theo task card: đọc ID/WHO_AM_I lúc init,
  CRC/parity của thiết bị (bật nếu được chỉ định), status/fault bit, mẫu 0x00/0xFF liên tiếp, read-back thanh ghi cấu hình định kỳ.
- Mọi giao dịch qua HAL trả mã lỗi; timeout khi chờ hoàn tất; kiểm tra độ dài tx/rx.
- Bus chia sẻ: chỉ dùng cơ chế khóa task card chỉ định; không khóa trong ISR. DMA/ISR do Lead viết — bạn viết lớp logic phía trên.
- Đóng khung theo datasheet tóm tắt trong task card (thứ tự byte lệnh/địa chỉ/dữ liệu, bit R/W, dummy cycle).
- Test (mock HAL): rx toàn 0x00/0xFF, CRC sai, fault bit, timeout, ID sai lúc init, cấu hình bị reset (read-back khác).
