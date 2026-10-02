# SDD — <unit> (SI-xxx, Class C) — DRAFT
| Rev | Date | Author | Change | Status |
|---|---|---|---|---|
## 1. Trách nhiệm & SRS/RCM thực hiện
## 2. Interface (header OWNER: lead, `vsur::<module>`) — tham số, đơn vị, miền giá trị, pre/post-condition
## 3. Dữ liệu & bộ nhớ (tĩnh, kích thước, ai sở hữu)
## 4. Thuật toán (bước, công thức, thứ tự phép tính, xử lý số thực)
## 5. State machine (trạng thái, sự kiện, chuyển trạng thái, default)
## 6. Xử lý lỗi & safe state (lỗi nào → trả gì → ai xử lý)
## 7. Timing (context, chu kỳ, WCET budget, blocking cho phép)
## 8. Concurrency (ai đọc/ghi gì, cơ chế đồng bộ)
## 9. Khởi tạo / kết thúc
## 10. Tiêu chí chấp nhận unit (62304 §5.5.3–5.5.4): sequence, data & control flow, resource, fault handling, init, self-diagnostics, memory, boundary
## 11. Giao tiếp (nếu có protocols) — khung/bảng message, CRC (width, poly, init, refin/refout, xorout, check value), counter,
timeout, bảng lỗi → phản ứng, fault detection + reaction time so với budget HAZ/RCM (skill comm-protocols)
