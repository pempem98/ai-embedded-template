---
description: Viết detailed design (SDD) cho software unit Class C
argument-hint: <SI-xxx hoặc tên unit>
---
Unit: $ARGUMENTS
Skills: `regulatory-docs`, `safety-architecture`, `linux-rt-design`/`qnx-design` theo nền tảng,
`comm-protocols` (+ references/<giao-thức>.md) nếu unit giao tiếp. Think hard.
Giao tiếp: SDD phải chốt bảng message/khung, CRC đầy đủ tham số + check value, counter, timeout, bảng lỗi → phản ứng,
fault detection + reaction time so với budget HAZ/RCM. Thông số datasheet chưa có → task research trước.
Viết `docs/04-detailed-design/SDD-<unit>.md` từ `docs/templates/SDD-template.md`: trách nhiệm, interface, dữ liệu & đơn vị,
thuật toán, state machine, xử lý lỗi & safe state, timing/WCET budget, tài nguyên, khởi tạo, tiêu chí §5.5.4.
Mục tiêu: Gemini implement được mà không cần hỏi. Viết interface `.h/.hpp` tương ứng (OWNER: lead) theo skill Gemini
`naming-conventions` (`vsur::<module>`, include guard `VSUR_<MODULE>_<FILE>_HPP_`, Doxygen @pre/@post, đơn vị), không đặt `@req`
trong header (trace.py không tính). Commit theo quy ước: `docs(<si>): add SDD-<unit>` / `feat(<si>): add <unit> interface` + `Refs:`.
