# USB

## Đặc điểm cần nhớ
- Host / device / OTG; full/high speed; enumeration, descriptor, class (CDC-ACM, HID, MSC, vendor bulk).
- Hot-plug bất kỳ lúc nào; độ trễ không xác định; stack phức tạp là SOUP (TinyUSB, stack vendor MCU, Linux gadget/host, libusb, QNX io-usb-otg).

## Quyết định
- KHÔNG dùng USB trong đường điều khiển/an toàn RT; chỉ dịch vụ, cập nhật, log, phụ kiện không an toàn — chứng minh segregation trong SAD.
- Cyber: cổng USB là bề mặt tấn công (thiết bị giả bàn phím, mass storage chứa mã độc, descriptor độc hại) → whitelist VID/PID/class,
  tắt class không dùng, xác thực chế độ dịch vụ, cập nhật phải ký số và chống rollback (skill medical-cybersecurity).
- Hành vi khi cắm/rút trong ca mổ: không ảnh hưởng chức năng an toàn; tải CPU của enumeration không lấn lõi/partition RT.

## Hazard điển hình
Ngắt/enumeration USB chiếm CPU lõi RT; descriptor độc hại làm crash driver/kernel; ghi log lớn làm đầy storage.

## Bằng chứng
Cắm/rút liên tục khi chạy tải RT (đo jitter); fuzz descriptor/protocol; test thiết bị ngoài whitelist; pentest cổng dịch vụ.
