---
description: Phân tích mối nguy phần mềm cho một tính năng/thay đổi (ISO 14971 + 62304 §7)
argument-hint: <tính năng hoặc thay đổi>
---
Đối tượng: $ARGUMENTS
Dùng skill `risk-management-iso14971`, `safety-architecture`. Think hard.
1. Grep HAZ/RCM hiện có liên quan trong docs/05-risk-management (không đọc toàn bộ file lớn).
2. Liệt kê chuỗi: lỗi phần mềm → tình huống nguy hiểm → tác hại; severity đề xuất.
3. Đề xuất RCM (ưu tiên thiết kế an toàn vốn có), mỗi RCM do phần mềm thực hiện → SRS + cách verify.
4. Giao subagent `fw-safety-assessor` phản biện.
5. Cập nhật bản Draft hazard-analysis.md / risk-control-matrix.md; xác suất & acceptability để `TBD(risk team)`.
Báo người dùng: danh sách HAZ/RCM mới, điểm cần risk team quyết.
