---
name: safety-coding
description: Lập trình phòng vệ cho phần mềm Class B/C của robot phẫu thuật — kiểm tra đầu vào, phát hiện lỗi, trạng thái an toàn. Tự động áp dụng cho Class B/C.
---
# Nguyên tắc
1. **Không có lỗi im lặng.** Mọi lỗi phải được trả về, ghi log sự kiện và/hoặc báo lên safety monitor theo task card.
2. **Kiểm tra đầu vào** ở biên module: miền giá trị, NaN/Inf, độ dài, CRC/sequence counter/timestamp của bản tin.
3. **Kiểm tra tính hợp lý (plausibility)**: giá trị cảm biến so với giới hạn vật lý, tốc độ biến thiên, so chéo kênh dư thừa nếu task card yêu cầu.
4. **Dữ liệu cũ (stale)**: mọi dữ liệu từ bên ngoài có timestamp; quá hạn → coi là lỗi.
5. **State machine tường minh**: `switch` trên `enum class` đầy đủ case, `default` → lỗi/safe state; không trạng thái ngầm.
6. **Safe state**: khi lỗi chỉ thực hiện hành động an toàn mà task card/detailed design chỉ định (vd. dừng chuyển động, giữ phanh). KHÔNG tự sáng tạo hành vi phục hồi.
7. **Fail-safe default**: biến khởi tạo về giá trị an toàn; cờ cho phép (enable) mặc định false.
8. **Không tin tưởng tầng dưới**: kiểm tra giá trị trả về của OS/HAL/driver, kể cả hàm "không bao giờ lỗi".
9. **Assert**: chỉ cho bất biến lập trình (programming error); KHÔNG dùng assert thay xử lý lỗi runtime. Hành vi assert trong release theo detailed design.
10. **Thời gian xác định**: không vòng lặp không giới hạn; mọi vòng có cận trên tường minh.
11. **Dữ liệu an toàn quan trọng** (giới hạn, cấu hình hiệu chuẩn): có CRC/bản sao đảo bit nếu task card yêu cầu; kiểm tra trước khi dùng.
12. Ghi rõ trong report mọi chỗ bạn KHÔNG chắc hành vi lỗi — đó là thứ Lead cần soát.
