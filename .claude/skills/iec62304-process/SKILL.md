---
name: iec62304-process
description: Quy trình vòng đời phần mềm IEC 62304 cho robot phẫu thuật — phân loại safety class A/B/C, hoạt động & tài liệu bắt buộc theo class, ánh xạ sang hồ sơ FDA. Dùng mỗi khi lập kế hoạch tính năng, phân loại software item, quyết định cần tài liệu/kiểm thử gì, hoặc người dùng nhắc 62304, FDA, chứng chỉ, hồ sơ, DHF.
---
# Phân loại (62304 §4.3, sau Amd1:2015)
- Giả định phần mềm CÓ THỂ hỏng (xác suất = 1). Xét mức nghiêm trọng sau khi tính biện pháp kiểm soát rủi ro **bên ngoài phần mềm** (phần cứng, cơ khí):
  - **A**: không thể gây thương tích · **B**: thương tích không nghiêm trọng · **C**: tử vong hoặc thương tích nghiêm trọng.
- Software item kế thừa class cao nhất của các item con, trừ khi kiến trúc chứng minh **phân tách (segregation)** hiệu quả (§5.3.5) — ghi lý do trong SAD.
- Robot phẫu thuật: điều khiển chuyển động, kinematics, safety monitor, xử lý lệnh tay điều khiển, kẹp/năng lượng → thường **C**.
  UI không ảnh hưởng điều khiển, logging, công cụ dịch vụ → có thể **A/B** NẾU segregation chứng minh được.
- Phân loại do con người (System/Safety engineer) phê duyệt. Bạn đề xuất + lý do, không tự chốt.

# Hoạt động theo class (tóm tắt — đối chiếu bản tiêu chuẩn hiện hành của công ty)
| Hoạt động | A | B | C |
|---|---|---|---|
| Kế hoạch phát triển (§5.1), yêu cầu phần mềm (§5.2) | ✔ | ✔ | ✔ |
| Kiến trúc, SOUP requirements, segregation (§5.3) | – | ✔ | ✔ |
| Chia unit (§5.4.1) | – | ✔ | ✔ |
| Detailed design từng unit + interface (§5.4.2–5.4.4) | – | – | ✔ |
| Unit verification, tiêu chí chấp nhận (§5.5.2–5.5.3) | – | ✔ | ✔ |
| Tiêu chí chấp nhận bổ sung (§5.5.4: sequence, data/control flow, resource, fault handling, init, self-diagnostics, memory, boundary) | – | – | ✔ |
| Integration test (§5.6) | – | ✔ | ✔ |
| System test (§5.7), release (§5.8) | ✔ | ✔ | ✔ |
| Risk management (§7), configuration mgmt (§8), problem resolution (§9) | ✔ | ✔ | ✔ |

# Ánh xạ trong template
| Hồ sơ | Vị trí |
|---|---|
| SDP (kèm quy trình dùng AI) | docs/01-plan/ |
| SysRS (UN, SYS, phân bổ) — đầu vào thiết kế hệ thống | docs/02-requirements/SysRS.md |
| SRS | docs/02-requirements/SRS.md |
| SyAD (subsystem, ICD) · SAD (software items, class, segregation) | docs/03-architecture/SyAD.md, SAD.md |
| Coding standard (§5.1.4) | docs/01-plan/coding-standard.md |
| SDD (Class C) | docs/04-detailed-design/SDD-*.md |
| Hazard analysis, RCM | docs/05-risk-management/ |
| SOUP list | docs/06-soup/ |
| Bằng chứng verify, review records | docs/07-verification/ |
| Trace matrix | docs/08-traceability/ |
| Anomaly | docs/09-problem-resolution/ |
| Release, unresolved anomalies | docs/10-release/ |
| Threat model, SBOM | docs/11-cybersecurity/ |

# FDA (tham khảo, RA xác nhận)
- Hướng dẫn "Content of Premarket Submissions for Device Software Functions" (2023): robot phẫu thuật nhiều khả năng ở mức tài liệu **Enhanced** → cần SDS, kiến trúc, unit/integration test, lịch sử phiên bản, danh sách anomaly chưa giải quyết.
- QMSR (21 CFR 820, tích hợp ISO 13485:2016) — design controls, công cụ phần mềm dùng trong QMS phải được validate (bao gồm công cụ AI → docs/01-plan/AI-assisted-development-procedure.md).
- Cyber device (FD&C Act §524B): SBOM, kế hoạch quản lý lỗ hổng, threat model → skill `medical-cybersecurity`.
- Tiêu chuẩn liên quan: ISO 14971, IEC 60601-1 (§14 PEMS), IEC 80601-2-77 (robotically assisted surgical equipment), IEC 62366-1, IEC 81001-5-1, ISO 13485.
