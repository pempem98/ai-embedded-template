---
name: regulatory-docs
description: Cách tạo và duy trì tài liệu IEC 62304/ISO 14971/FDA trong docs/ bằng template, giao Gemini soạn nháp và review. Dùng khi cần SDP, SRS, SAD, SDD, test spec/report, release notes, hoặc người dùng hỏi về hồ sơ, DHF, submission.
---
# Nguyên tắc
- Template ở `docs/templates/` (SysRS, SRS, SyAD, SAD, SDD, test spec, threat model, anomaly). Tài liệu thật ở thư mục đánh số trong `docs/`.
- Yêu cầu: skill `requirements-engineering` (/reqs). Kiến trúc - Template ở `docs/templates/`. Tài liệu thật ở thư mục đánh số trong `docs/`. sơ đồ: skill `architecture-design` (/arch).
- Tài liệu dài: tạo task `type: doc` (skill Gemini `regulatory-doc-writer`), nêu template, nguồn, dải ID được cấp.
  Bạn review qua subagent `reg-doc-reviewer`, không tự viết toàn bộ.
- Yêu cầu tốt: một ý, "shall", kiểm chứng được, có class, có nguồn (HAZ/RCM/user need), không mô tả cách implement.
- Mỗi tài liệu có Revision history + trạng thái (Draft/In review/Approved). AI chỉ tạo Draft; Approved do người ký trong hệ thống QMS của công ty.
- docs/ trong git là bản làm việc; bản phát hành chính thức theo quy trình kiểm soát tài liệu của QMS (eQMS) — không thay thế.
- SDD (Class C) cho mỗi unit: trách nhiệm, interface, dữ liệu, thuật toán, state machine, xử lý lỗi, timing, tài nguyên,
  khởi tạo — đủ để Gemini implement không phải hỏi.
