---
name: proto-biss-c
description: Implement đọc encoder BiSS-C (khung vị trí, nE/nW, CRC, register access CDM/CDS) qua master IP/IC. Áp dụng khi protocols có biss-c.
---
# BiSS-C
- Cấu hình khung theo task card (từ datasheet encoder): số bit ST/MT, vị trí bit nE (error) & nW (warning) — active-low,
  độ dài & đa thức CRC (thường 6 bit, poly 0x43 = x⁶+x+1, truyền dạng ĐẢO — phải đối chiếu task card), tần số MA, timeout.
- Master do IP FPGA / peripheral MCU / IC (vd. iC-MB4) thực hiện theo task card — bạn viết lớp logic đọc kết quả, không đổi cấu hình master.
- Mỗi khung: trạng thái master (không có start bit / timeout) → CRC (đảo bit trước khi so nếu spec yêu cầu) → nE → nW → plausibility.
  CRC sai hoặc nE active → KHÔNG dùng vị trí.
- nW active: không bỏ qua — báo theo task card (nhiệt độ, pin multi-turn, nhiễm bẩn...).
- Register communication (CDM/CDS) chỉ ngoài đường RT hoặc theo cơ chế task card; có timeout; không làm trễ chu kỳ đọc vị trí.
- Test: vector CRC từ datasheet/task card, CRC sai 1 bit, nE/nW active, thiếu start bit, timeout, nhảy vị trí, wrap.
