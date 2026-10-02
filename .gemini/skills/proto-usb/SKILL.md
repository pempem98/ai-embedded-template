---
name: proto-usb
description: Implement chức năng USB (device class CDC/HID/MSC/vendor, host) cho dịch vụ/cập nhật/phụ kiện. Áp dụng khi protocols có usb.
---
# USB
- Stack là SOUP (TinyUSB, stack vendor, Linux gadget/libusb, QNX io-usb-otg) — dùng đúng API & phiên bản task card, không thêm class/endpoint.
- USB KHÔNG nằm trong đường điều khiển/an toàn RT. Callback USB không gọi trực tiếp vào logic an toàn; chuyển dữ liệu qua hàng đợi có giới hạn.
- Mọi dữ liệu USB là đầu vào không tin cậy (cyber): kiểm tra độ dài, kiểu, miền giá trị; không tin descriptor/length từ thiết bị ngoài;
  whitelist VID/PID/class theo task card.
- Cắm/rút bất kỳ lúc nào: xử lý mất kết nối giữa chừng, đặt lại trạng thái, không treo, không rò tài nguyên.
- Lệnh dịch vụ/cập nhật: chỉ thực hiện sau xác thực theo task card; ảnh cập nhật phải kiểm chữ ký số (gọi module được chỉ định).
- Test: rút giữa transfer, khung độ dài sai/lớn, thiết bị ngoài whitelist, lệnh chưa xác thực.
