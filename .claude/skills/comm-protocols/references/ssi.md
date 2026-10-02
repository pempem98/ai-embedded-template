# SSI (Synchronous Serial Interface) — encoder tuyệt đối

## Đặc điểm cần nhớ
- Master phát clock (thường 100 kHz đến 1–2 MHz tùy chiều dài cáp); encoder chốt vị trí ở cạnh clock đầu và dịch bit ra;
  sau khung cần thời gian monoflop t_m (theo datasheet) trước khung mới.
- Định dạng: số bit, Gray hoặc binary, MSB first, bit lỗi/parity tùy hãng — KHÔNG có CRC chuẩn.
- Trễ cáp + transceiver RS-422 giới hạn tần số clock (trễ vòng phải nhỏ hơn cỡ nửa chu kỳ clock, hoặc cần bù trễ).

## Chốt trong SDD
Số bit single/multi-turn, Gray/binary, vị trí bit lỗi, tần số clock, t_m, chiều dài cáp, chu kỳ đọc, độ phân giải & đơn vị.
Phát hiện lỗi (vì không có CRC): đọc kép (multi-transmission nếu encoder hỗ trợ) và so sánh; bit lỗi/parity;
plausibility |Δpos| mỗi chu kỳ ≤ v_max·T + dung sai; line cố định mức 0/1 = mất encoder.
Class C: SSI đơn kênh thường KHÔNG đủ làm cảm biến an toàn → cần so chéo encoder thứ hai / motor encoder (quyết định kiến trúc).

## Hazard điển hình
Nhảy vị trí do bit lỗi → chuyển động đột ngột; đọc khi t_m chưa hết → dữ liệu sai; chuyển Gray→binary sai; wrap-around multi-turn.

## Bằng chứng
Vector Gray↔binary; test nhảy vị trí & phản ứng plausibility; đo clock/data bằng scope ở chiều dài cáp lớn nhất.
