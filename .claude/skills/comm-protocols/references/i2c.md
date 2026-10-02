# I2C / SMBus

## Đặc điểm cần nhớ
- Open-drain 2 dây, địa chỉ 7/10 bit, 100 kHz / 400 kHz / 1 MHz; ACK/NACK mỗi byte; slave có thể clock stretching.
- Không có CRC (SMBus PEC tùy chọn — bật nếu thiết bị hỗ trợ). Thời gian giao dịch không xác định chặt.

## Chốt trong SDD
- Tốc độ, địa chỉ, có clock stretching không, timeout tối đa mỗi giao dịch, retry tối đa.
- Bus chia sẻ: ai giữ lock, thứ tự truy cập.
- Phục hồi bus treo (SDA bị giữ thấp): tối đa 9 xung SCL rồi STOP; vẫn treo → reset nguồn thiết bị nếu phần cứng cho phép.
- Không đặt I2C trong đường điều khiển RT cứng trừ khi phân tích timing chứng minh.

## Hazard điển hình
Bus treo vô hạn (thiếu timeout); NACK bị bỏ qua → dùng giá trị cũ; thiết bị reset về mặc định sau brown-out; địa chỉ trùng.

## Bằng chứng
Mock NACK/timeout/arbitration lost; trên phần cứng: giữ SDA thấp, rút thiết bị, đo thời gian giao dịch worst case.
