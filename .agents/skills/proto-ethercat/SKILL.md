---
name: proto-ethercat
description: Implement ứng dụng EtherCAT master (process data, WKC, DC, ESM, CoE/CiA 402) trên Linux RT / QNX. Áp dụng khi protocols có ethercat.
---
# EtherCAT
- Dùng master stack & API task card chỉ định (IgH EtherLab, SOEM, acontis EC-Master...). Không sửa ENI/ESI, PDO mapping, DC config.
- Mỗi chu kỳ theo ĐÚNG thứ tự task card (vd. receive → process domain → kiểm tra → tính toán → queue → send;
  với DC: cập nhật application time / đồng bộ reference clock tại đúng điểm chỉ định).
- DC: chế độ (master shift / bus shift), SYNC0 shift, ngưỡng System Time Difference (0x092C) do task card chốt. Chỉ yêu cầu OP sau khi
  bù drift xong và mọi slave DC trong ngưỡng (nếu task card giao việc này); đọc & báo 0x092C / sync error counter theo chu kỳ chỉ định.
  Thread cyclic bám DC theo cơ chế task card — không tự thêm bộ điều chỉnh PI hay đổi chu kỳ.
- CSP: target cập nhật MỖI chu kỳ (kể cả khi giữ vị trí — gửi lại target hiện tại); không để drive tự ngoại suy ngoài thiết kế.
- Working Counter: so WKC từng domain với giá trị mong đợi MỖI chu kỳ. Sai → KHÔNG dùng input chu kỳ đó,
  không tính output mới từ dữ liệu sai, tăng counter, phản ứng theo task card (N chu kỳ liên tiếp → báo supervisor/safe state).
- Giám sát trạng thái ESM (AL state) của master/slave & link theo chu kỳ task card; slave rời OP / AL status code ≠ 0 /
  link down → báo theo task card. KHÔNG tự yêu cầu chuyển state.
- Process data: truy cập qua offset/mapping sinh từ cấu hình, kiểm tra kích thước; EtherCAT little-endian — đọc/ghi bằng hàm tường minh.
- CoE SDO: chỉ ngoài vòng RT, có timeout, xử lý abort code.
- CiA 402: controlword/statusword theo state machine Lead cung cấp; kiểm tra mode display trước khi gửi target;
  CSP: target position liên tục, giới hạn bước/vận tốc theo task card; không tự clear fault.
- FSoE / safety stack: KHÔNG tự implement; chỉ gọi thư viện được chỉ định.
- Đo & báo: cycle overrun, jitter, DC sync diff nếu task card yêu cầu (vào ring buffer, không log đồng bộ).
- Thread chu kỳ theo linux-rt-impl / qnx-impl.
- Test (mock master API): WKC thiếu/thừa, slave không OP, mất link, overrun, statusword bất ngờ, fault drive.
