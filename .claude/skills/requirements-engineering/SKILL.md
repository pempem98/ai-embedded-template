---
name: requirements-engineering
description: Phân rã và viết yêu cầu cho thiết bị y tế — user needs (UN) → system requirements (SysRS, SYS) → phân bổ cho subsystem SW/HW/ME → software requirements (SRS) theo IEC 62304 §5.2, có nguồn rủi ro (HAZ/RCM), phương pháp verify, truy vết. Mẫu EARS, tiêu chí chất lượng yêu cầu, checklist nội dung SRS. Dùng khi /reqs, /plan, viết/review SysRS hoặc SRS, phân rã yêu cầu, hoặc người dùng nhắc "requirement", "yêu cầu", "spec".
---
# Tầng yêu cầu & truy vết
```
UN-nnn (user need, intended use)  ──►  SYS-nnn (SysRS, toàn hệ thống, phân bổ SW/HW/ME/EE)
HAZ-nnn ─► RCM-nnn (risk control)  ──►  SYS-nnn và/hoặc SRS-nnn
SYS-nnn (phân bổ SW) ──► SRS-nnn (mỗi software system) ──► SI-nnn (SAD) ──► code @req ──► test @verifies
Quyết định kiến trúc (ADR/SAD) ──► SRS dẫn xuất (derived) — nguồn ghi ADR/SAD và phải đưa lại vào phân tích rủi ro
```
- Mỗi SRS có ≥ 1 nguồn (SYS / RCM / ADR); mỗi SYS phân bổ SW có ≥ 1 SRS. `trace.py` báo GAP nếu thiếu.
- SysRS thuộc thiết kế hệ thống (design input ISO 13485 §7.3.3); SRS là §5.2 của 62304. Hai tài liệu tách riêng, ID riêng.
- Class của SRS = class của software item thực hiện nó (người dùng/safety engineer xác nhận).

# Quy trình phân rã (/reqs)
1. Thu thập nguồn: UN, intended use, HAZ/RCM, tiêu chuẩn sản phẩm (IEC 60601-1, 80601-2-77, 62366-1...), ràng buộc kỹ thuật.
   Tài liệu dài → task research cho Gemini → `.ai/notes/`.
2. Viết SYS: hành vi hệ thống nhìn từ bên ngoài, đo được, chưa quyết định SW hay HW.
3. Phân bổ từng SYS: SW / HW / ME / EE (có thể nhiều). Phân bổ quyết định bởi kiến trúc hệ thống (skill `architecture-design`, SyAD).
4. Với phần SW: viết SRS cho software system tương ứng; tách SYS thành nhiều SRS khi khác SI, khác class, hoặc khác cách verify.
5. Gắn SRS ↔ SI (SAD) và class; gắn verify method; liệt kê TBD; hỏi người dùng xác nhận trước khi đổi trạng thái.
6. Tài liệu lớn: giao Gemini `type: doc` (dải ID cấp sẵn) → review bằng `reg-doc-reviewer`.

# Viết một yêu cầu
- Một ý, một "shall"; chủ ngữ là hệ thống/software item; không mô tả cách implement (trừ ràng buộc thiết kế có nguồn).
- Định lượng có đơn vị và dung sai; điều kiện rõ; kiểm chứng được bằng T(est) / A(nalysis) / I(nspection) / D(emonstration).
- Tiêu chí chất lượng (theo tinh thần INCOSE): cần thiết, đơn nghĩa, đầy đủ, đơn lẻ, khả thi, kiểm chứng được, đúng, nhất quán, truy vết được.
- Từ cấm (không đo được): fast, quickly, adequate, user-friendly, robust, flexible, as appropriate, if possible, minimize/maximize
  (không có ngưỡng), support, etc., and/or, real-time (không có số).

## Mẫu EARS
| Loại | Mẫu | Ví dụ |
|---|---|---|
| Ubiquitous | The <system> shall <response>. | The teleoperation software shall limit each commanded joint velocity to ±v_max. |
| Event | When <trigger>, the <system> shall <response>. | When the clutch pedal is released, the software shall command all arms to hold position within 50 ms. |
| State | While <state>, the <system> shall <response>. | While in instrument-exchange mode, the software shall reject teleoperation commands. |
| Unwanted | If <fault>, then the <system> shall <response>. | If no valid master command is received for 3 consecutive cycles, then the software shall enter the hold safe state. |
| Optional | Where <feature>, the <system> shall <response>. | Where the energy instrument is installed, the software shall ... |
| Complex | While <state>, when <trigger>, the <system> shall ... | |
Yêu cầu từ RCM thường là dạng Unwanted (If … then …) và phải nêu thời gian phát hiện + phản ứng.

# Checklist nội dung SRS (IEC 62304 §5.2.2) — mỗi mục có yêu cầu hoặc ghi "không áp dụng" + lý do
Chức năng & năng lực (hiệu năng, timing) · đầu vào/đầu ra phần mềm · interface với hệ thống khác · alarm/warning/thông báo ·
bảo mật (skill medical-cybersecurity) · usability liên quan lỗi người dùng (IEC 62366-1) · định nghĩa dữ liệu & database ·
cài đặt & chấp nhận tại nơi dùng · vận hành & bảo trì · IT-network · bảo trì bởi người dùng · quy định pháp lý ·
biện pháp kiểm soát rủi ro do phần mềm thực hiện (§5.2.3). Sau khi viết: đánh giá lại phân tích rủi ro (§5.2.4), verify SRS (§5.2.6).

# Review SysRS/SRS — REJECT nếu
Nhiều "shall"/ý trong một dòng; không đo được; thiếu nguồn hoặc verify method; SRS mô tả implement; mâu thuẫn với SYS/RCM;
ID trùng/tái sử dụng; class không khớp SI; RCM không có SRS/SYS tương ứng.
