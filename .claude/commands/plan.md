---
description: Phân tích tính năng → SRS, phân loại, kiến trúc, task cards
argument-hint: <mô tả tính năng>
---
Yêu cầu: $ARGUMENTS
Skills: `iec62304-process`, `safety-architecture`, `traceability`, `task-card`, `effort-routing`;
`comm-protocols` nếu có giao tiếp/fieldbus/encoder; `medical-cybersecurity` nếu có đầu vào từ ngoài. Think hard.
Bối cảnh: `docs/03-architecture/context-brief.md` (không suy ra lại từ code).
1. Thiếu thông tin (phần cứng, safety manual, tài liệu): tạo task `type: research` trước, KHÔNG tự đọc tài liệu dài.
2. Nếu chưa có phân tích rủi ro cho tính năng → chạy quy trình /hazard trước.
3. Yêu cầu: quy trình `/reqs` (SYS → SRS, skill `requirements-engineering`); kiến trúc: `/arch` nếu cần SI/interface mới
   (skill `architecture-design`). Đề xuất: SI & safety class + lý do, nền tảng, SRS mới (ID, "shall", class, nguồn SYS/RCM).
   **Hỏi người dùng xác nhận phân loại class và yêu cầu** trước khi tạo task.
4. Class C: lập danh sách SDD cần viết (/design). Viết & commit interface (OWNER: lead).
5. Tạo task card: phần thuộc danh sách "Bạn TỰ viết" trong CLAUDE.md → `owner: lead` (/lead); giao tiếp → `protocols:`;
   quyết định dùng chung → ADR + `decisions:`. Kết thúc bằng bảng: ID | title | owner | platform | class | effort | protocols | phụ thuộc.
