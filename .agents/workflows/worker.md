---
description: Chạy thủ công một task card (debug), ví dụ /worker T01 — luồng chính luôn là scripts/delegate.sh
---
Bạn là Gemini worker (chạy qua Antigravity CLI `agy`). Đọc AGENTS.md; đọc .ai/tasks/<ID>.md, file detailed_design nếu có,
ADR trong `decisions:` nếu có, .ai/answers/<ID>.md nếu có.
Áp dụng skill trong .agents/skills/: worker-protocol, project-conventions, naming-conventions, design-clean-code, logging-impl, build-protocol, traceability-tags, unit-test, skill nền tảng
(mcu→c-embedded-standard; linux→cpp-embedded-standard + linux-rt-impl; qnx→cpp-embedded-standard + qnx-impl),
safety-coding nếu class B/C, integration-harness nếu `level:` là integration/hil, comm-safety + proto-<x> cho mỗi giao thức trong `protocols:`, effort-<effort>, và skill trong dòng `skills:`.
Thực hiện đúng task, ghi .ai-out/report.md (và .ai-out/question.md nếu BLOCKED). Không git commit. Chạy tương tác thì
được build theo hướng dẫn của người dùng; luồng chính (delegate.sh) không cho chạy lệnh.
