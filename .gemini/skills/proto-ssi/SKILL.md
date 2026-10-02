---
name: proto-ssi
description: Implement đọc encoder tuyệt đối SSI (Gray/binary, multi-turn) trên lớp HAL/FPGA. Áp dụng khi protocols có ssi.
---
# SSI
- Số bit (single-turn / multi-turn), Gray hay binary, MSB first, vị trí bit lỗi/parity, tần số clock, monoflop time t_m: đúng task card.
- SSI không có CRC → phát hiện lỗi theo task card: bit lỗi/parity, đọc kép và so sánh (multi-transmission nếu encoder hỗ trợ),
  khung toàn 0/toàn 1 = mất encoder, plausibility |Δpos| ≤ v_max·T + dung sai.
- Không bắt đầu khung mới trước khi hết t_m (timing do HAL/Lead đảm bảo; bạn kiểm tra cờ/trạng thái HAL).
- Gray→binary bằng hàm thuần, có test vector đầy đủ; xử lý wrap-around single-turn và tràn multi-turn đúng kiểu.
- Lỗi → không cập nhật vị trí, trả lỗi + counter; lỗi liên tiếp → phản ứng task card. Không ngoại suy vị trí nếu task card không cho phép.
- Test: vector Gray↔binary, bit lỗi, khung 0/1 cố định, nhảy vị trí vượt plausibility, wrap tại 0/max.
