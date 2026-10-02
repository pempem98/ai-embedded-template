---
name: regulatory-doc-writer
description: Soạn nháp tài liệu IEC 62304 / ISO 14971 (SysRS, SRS, SyAD, SAD, SDD, test spec, SOUP, hazard analysis) từ template. Dùng cho task type=doc.
---
# Soạn tài liệu
- Dùng template trong `docs/templates/` mà task card chỉ định; giữ nguyên cấu trúc mục, thứ tự cột bảng
  (scripts/trace.py đọc cột theo vị trí: SysRS cột 4 = Allocation; SRS phải có nguồn SYS/RCM/ADR trên cùng dòng).
- Chỉ ghi nội dung có nguồn: task card, chỉ đạo Lead, code/tài liệu được chỉ định. Không bịa số liệu, tiêu chuẩn, điều khoản.
- Chỗ thiếu thông tin: ghi `TBD(<câu hỏi>)` và liệt kê vào question — không đoán.
- ID: dùng ID task card cấp; ID mới chỉ khi task card cho phép và theo dải được giao (vd. SRS-100..149). Không tái sử dụng ID.
- Ngôn ngữ: tiếng Anh cho nội dung nộp hồ sơ (trừ khi task card nói khác); câu ngắn, thể bị động hạn chế.
- Không sửa phần đã có chữ ký/phê duyệt (Revision history có "Approved"); không tự đặt trạng thái Approved — hỏi Lead.

# Yêu cầu (SysRS / SRS)
- Một dòng = một "shall", một ý; định lượng có đơn vị & dung sai; không mô tả cách implement.
- Mẫu EARS: `The <system> shall …` · `When <trigger>, the <system> shall …` · `While <state>, …` ·
  `If <fault>, then the <system> shall …` (yêu cầu từ RCM: nêu thời gian phát hiện + phản ứng) · `Where <feature>, …`.
- Không dùng từ không đo được: fast, adequate, user-friendly, robust, as appropriate, if possible, minimize, support, etc., and/or.
- Mỗi yêu cầu: nguồn (UN/SYS/HAZ/RCM/ADR), verification T/A/I/D; SRS thêm SI + class (theo SAD, không tự phân loại).

# Kiến trúc (SyAD / SAD) & SDD
- Chỉ mô tả quyết định Lead đã chốt (task card, ADR, ghi chú) — không tự đề xuất kiến trúc, không tự phân loại class.
- Sơ đồ Mermaid theo quy ước Lead đưa trong task card: tiêu đề `FIG-<doc>-nn — <tên>`, node = ID + tên khớp bảng,
  ≤ ~25 phần tử, màu theo class (classDef clsC/clsB/clsA/ext), mũi tên có nhãn interface ID.
- Tên trong tài liệu khớp code: namespace `vsur::<module>`, file/class theo skill naming-conventions (nếu task cấp skill đó).
