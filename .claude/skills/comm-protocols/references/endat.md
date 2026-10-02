# EnDat 2.2 (Heidenhain)

## Đặc điểm cần nhớ
- Hai chiều, đồng bộ theo clock master; master gửi mode command (vd. đọc vị trí, đọc vị trí kèm additional information,
  đọc/ghi tham số, reset lỗi).
- Khung trả về: start bit, bit lỗi, giá trị vị trí, (additional information), CRC 5 bit.
- Bù trễ đường dây cho clock cao; tần số tối đa phụ thuộc phiên bản/encoder.
- EnDat functional safety: hai giá trị vị trí độc lập cho ứng dụng an toàn — dùng theo safety manual của Heidenhain.
Chi tiết bit/mode command: lấy từ spec Heidenhain qua task research (`.ai/notes/`), không giả định.

## Chốt trong SDD
Mode command dùng trong chu kỳ, số bit vị trí, additional information nào, tần số clock, bù trễ, xử lý bit lỗi/alarm/warning,
CRC, timeout; master IP/IC (thường là SOUP của Heidenhain hoặc vendor FPGA) & phiên bản; cách so sánh hai giá trị vị trí nếu dùng safety.

## Hazard & bằng chứng
Như BiSS-C: CRC sai, bit lỗi, timeout, nhảy vị trí; thêm kiểm tra alarm/warning định kỳ.
Bằng chứng: vector CRC, inject lỗi, đo latency, test so sánh hai kênh vị trí (nếu dùng safety).
