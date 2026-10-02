---
name: comm-safety
description: Quy tắc chung khi implement code giao tiếp/giao thức (parser, driver, fieldbus, encoder, link giữa các node). Tự động áp dụng khi task card có protocols:.
---
# Mô hình: kênh truyền KHÔNG tin cậy (black channel)
Lỗi phải xử lý: hỏng dữ liệu, lặp, mất, chèn, sai thứ tự, trễ, giả mạo nguồn.
CRC phần cứng của bus KHÔNG thay thế kiểm tra ở tầng ứng dụng mà task card yêu cầu.

# Nhận dữ liệu — thứ tự kiểm tra BẮT BUỘC trước khi dùng bất kỳ trường nào
1. Mã lỗi driver/HAL/OS của lần nhận
2. Độ dài (≥ tối thiểu, ≤ buffer, khớp trường length)
3. CRC/checksum (tham số đúng task card)
4. Type / version / ID nguồn-đích
5. Sequence / alive counter (lặp, nhảy, đảo thứ tự)
6. Tuổi dữ liệu / timestamp (stale)
7. Miền giá trị & plausibility
Sai ở bước nào → KHÔNG dùng dữ liệu, trả lỗi đúng loại + tăng counter lỗi tương ứng.

# Quy tắc code
- KHÔNG `memcpy`/cast buffer vào struct để giải mã, không dựa vào layout/packing/endianness của compiler.
  Đọc/ghi từng trường bằng hàm endianness tường minh của dự án.
- Kiểm tra chỉ số/độ dài trước MỌI truy cập buffer.
- Counter: so sánh bằng số học modulo trên kiểu unsigned (xử lý wrap-around), có test tại biên wrap.
- Timeout: clock monotonic của dự án, so với deadline tuyệt đối; không sleep tương đối; không `CLOCK_REALTIME`.
- CRC: đúng tham số (width, poly, init, refin, refout, xorout); test bằng check value của chuỗi "123456789"
  và vector trong task card/spec.
- Buffer chia sẻ với ISR/DMA: chỉ dùng cơ chế task card chỉ định (double buffer, sequence lock, SPSC). ISR/DMA do Lead viết.
- Gửi: đóng gói từng trường tường minh, điền counter/CRC theo spec; không gửi struct thô.

# Lỗi & phục hồi
- Đếm lỗi theo loại; ngưỡng & phản ứng (bỏ mẫu / giữ giá trị cũ có thời hạn / báo supervisor / safe state) ĐÚNG task card.
- KHÔNG tự thêm retry, tự reset bus/thiết bị, tự re-init hay tự cho phép hoạt động lại. Chưa có chỉ định → HỎI.

# Test bắt buộc
Khung hợp lệ; từng loại lỗi ở trên; length 0 / tối thiểu-1 / max / max+1; counter lặp / nhảy / wrap;
timeout tại deadline-1, deadline, deadline+1; CRC check value; lỗi driver/HAL (mock).
