---
description: Threat model & cybersecurity risk cho một tính năng/interface (FDA §524B, IEC 81001-5-1)
argument-hint: <tính năng / interface / cổng>
---
Đối tượng: $ARGUMENTS — skills `medical-cybersecurity`, `comm-protocols` (nếu là giao tiếp), `risk-management-iso14971`.
1. Data flow & trust boundary (console, cart, vision, mạng bệnh viện, USB/cổng dịch vụ, cập nhật).
2. STRIDE theo từng flow → threat, tài sản, khả năng khai thác dẫn đến tác hại (liên kết HAZ nếu có).
3. Biện pháp → yêu cầu SRS (bảo mật) + cách verify (fuzz, pentest, static analysis); SOUP liên quan → SBOM.
4. Cập nhật Draft `docs/11-cybersecurity/` theo `docs/templates/threat-model-template.md`. Đánh giá mức chấp nhận: người dùng/security team.
