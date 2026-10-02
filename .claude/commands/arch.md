---
description: Thiết kế/cập nhật kiến trúc hệ thống (SyAD) hoặc phần mềm (SAD) kèm sơ đồ, trade-off, ADR, verify kiến trúc
argument-hint: <system|software> <phạm vi: hệ thống / subsystem / software system / SI>
---
Đối tượng: $ARGUMENTS — skills `architecture-design` (+ `references/diagrams.md` khi vẽ), `safety-architecture`,
`requirements-engineering`; `comm-protocols`, `linux-rt-design`, `qnx-design`, `medical-cybersecurity` theo nội dung. Think hard.
1. Driver: SYS/SRS, HAZ/RCM, ràng buộc liên quan (grep); thiếu thông tin phần cứng/OS → task research.
2. Quyết định quan trọng: ≥ 2 phương án + bảng tiêu chí → đề xuất; ghi ADR (Proposed). Hỏi người dùng các quyết định về
   phân bổ SW/HW cho chức năng an toàn, phân loại class, segregation.
3. Cập nhật Draft `docs/03-architecture/SyAD.md` (system) hoặc `SAD.md` (software) theo template; vẽ các view bắt buộc bằng Mermaid.
4. Cập nhật `context-brief.md`, `docs/06-soup/soup-list.md` (SOUP mới → /soup), data flow cho threat model nếu có biên tin cậy mới.
5. Verify kiến trúc theo checklist §5.3.6 của skill; giao `fw-safety-assessor` phản biện phần an toàn.
6. Báo: sơ đồ đã cập nhật, ADR mới, danh sách SI/interface mới, SRS dẫn xuất cần thêm (/reqs), điểm cần người dùng quyết.
