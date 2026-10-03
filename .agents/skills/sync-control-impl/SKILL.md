---
name: sync-control-impl
description: Quy tắc implement code điều khiển đồng bộ/đa tần số/phân tán (timestamp & miền đồng hồ, stale check, rate transition, snapshot đa trục, căn pha chu kỳ, phản ứng mất đồng bộ). Áp dụng khi task card khai skills có sync-control-impl, hoặc protocols có ethercat/canopen.
---
# Điều khiển đồng bộ & phân tán
- Mọi tham số timing (chu kỳ, pha/offset, max_age, số chu kỳ ngoại suy N, ngưỡng lệch đồng hồ, giới hạn bước/vận tốc/gia tốc)
  lấy từ task card/SDD dưới dạng `constexpr` có đơn vị trong tên. Không tự chọn, không "điều chỉnh cho chạy được".
- Timestamp: luôn kiểu thời gian của dự án (`vsur::TimePoint`/`Microseconds`) + ghi rõ miền đồng hồ (local monotonic / PTP /
  DC) theo task card. CẤM so sánh/trừ hai timestamp khác miền. Không dùng `CLOCK_REALTIME` cho deadline.
- Stale check: tuổi = now − timestamp (cùng miền) ≤ max_age VÀ seq tiến (`vsur::seq_delta`); mẫu stale → không dùng, đếm,
  phản ứng theo task card. Khi task card báo mất đồng bộ đồng hồ → dùng cơ chế dự phòng task card chỉ định (seq + thời điểm nhận cục bộ).
- Rate transition: dùng đúng cơ chế task card (triple buffer mới nhất / nội suy / ZOH có giới hạn). Ngoại suy tối đa N chu kỳ,
  sau đó giữ/dừng theo task card; mọi đầu ra qua bộ giới hạn bước/vận tốc/gia tốc trước khi gửi.
- Snapshot đa trục: chỉ tính khi mọi trục cùng chu kỳ latch (cùng cycle id / sync counter / timestamp trong dung sai);
  thiếu hoặc lẫn chu kỳ → bỏ chu kỳ đó, không trộn dữ liệu cũ–mới.
- Lệnh đa trục: ghi đủ mọi trục vào buffer rồi mới publish một lần (không publish nửa chừng).
- Đầu ra mang seq/cycle id của đầu vào đã dùng (truy vết latency end-to-end) nếu task card yêu cầu.
- Chu kỳ: thời điểm tuyệt đối theo nguồn trigger task card (timer tuyệt đối / bám DC / SYNC); đo overrun & offset pha mỗi chu kỳ vào
  ring buffer; overrun → phản ứng task card, không "bù" bằng cách chạy nhanh hai chu kỳ.
- Trạng thái hệ thống: chỉ đổi lifecycle theo lệnh SSM hoặc tự về SAFE khi phát hiện lỗi/mất liên lạc; KHÔNG tự đi ra khỏi SAFE,
  không tự tiếp tục chuyển động sau khi kết nối/đồng bộ trở lại. Bỏ lệnh có epoch cũ/transition_id lặp.
- Logic chuyển safe state & đồng bộ RT lõi do Lead viết: chỉ gọi API được cung cấp, không sửa file `// OWNER: lead`.
- Test (FakeClock, không sleep thật): đúng biên max_age (= và +1 tick), seq wrap, mất N và N+1 mẫu, snapshot lẫn chu kỳ, lệch
  pha, overrun liên tiếp, mất đồng bộ → cơ chế dự phòng, giới hạn bước tại biên, epoch cũ, lệnh lặp.
