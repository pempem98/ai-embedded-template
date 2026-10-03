# Software Coding Standard (DRAFT) — IEC 62304 §5.1.4
| Rev | Date | Author | Change | Status |
|---|---|---|---|---|
| 0.1 | | | Initial | Draft |
| 0.2 | 2026-10-03 | Lead (AI) | Thêm luật dùng C++ template (ADR-002) vào `cpp-embedded-standard`; thêm `design-clean-code`, `logging-impl` | Draft |
| 0.3 | 2026-10-03 | Lead (AI) | Lớp E2E chung (ADR-003) trong `comm-safety`, `proto-dds`; ID `CR-nnn` và trailer `Change:` (ADR-004) trong `naming-conventions` | Draft |

Áp dụng cho mọi mã nguồn sản phẩm, bất kể do kỹ sư, Claude hay Gemini viết. Các file dưới đây là **nguồn kiểm soát**
(quản lý cấu hình trong git); tài liệu này chỉ mô tả phạm vi, cách thực thi và quy trình thay đổi.

## 1. Thành phần
| Nội dung | Nguồn kiểm soát | Thực thi |
|---|---|---|
| Luật ngôn ngữ C++ (tham chiếu MISRA C++:2023, AUTOSAR C++14, CERT C++) | `.agents/skills/cpp-embedded-standard/SKILL.md` | clang-tidy, cppcheck, MISRA tool, review |
| Luật ngôn ngữ C cho MCU (tham chiếu MISRA C:2012/2023, CERT C) | `.agents/skills/c-embedded-standard/SKILL.md` | như trên |
| Lập trình phòng vệ Class B/C | `.agents/skills/safety-coding/SKILL.md` | review, unit test |
| Design pattern được phép/cấm, clean code | `.agents/skills/design-clean-code/SKILL.md` | review, clang-tidy (một phần) |
| Logging (đường RT, nội dung cấm ghi, code debug) | `.agents/skills/logging-impl/SKILL.md` | review, banned-check (`printf`/`cout` Class C) |
| Đặt tên, ID, file, commit message | `.agents/skills/naming-conventions/SKILL.md` | clang-tidy `readability-identifier-naming`, git hook `commit-msg`, review |
| Định dạng | `.clang-format`, `.editorconfig` | hook format (Claude), worker, CI |
| Phân tích tĩnh | `.clang-tidy` (C++), `.ai/templates/clang-tidy-mcu-c.yaml` (C) | gate (`TIDY_CMD`) |
| API/pattern cấm theo class & nền tảng | `scripts/check_banned.py` | gate (`banned`) |
| Giao tiếp/giao thức | `.agents/skills/comm-safety`, `proto-*` | review, unit/integration test |
| Truy vết trong code | `.agents/skills/traceability-tags/SKILL.md` | `scripts/trace.py` |

## 2. Ngoại lệ
Vi phạm có chủ đích → deviation `DEV-nnn` (`.ai/templates/deviation.md`), comment `// @deviation DEV-nnn` cùng dòng,
con người phê duyệt (`APPROVED_BY`). Không dùng NOLINT/pragma để bịt cảnh báo.

## 3. Thay đổi coding standard
Đề xuất (thường từ /retro) → Lead + kỹ sư phụ trách duyệt → cập nhật file nguồn + bảng Rev ở trên → đánh giá ảnh hưởng tới
mã hiện có (chạy gate `--full`) và tới validation công cụ AI (docs/01-plan/AI-assisted-development-procedure.md §3).

## 4. Cài đặt cho mỗi clone
`git config core.hooksPath scripts/git-hooks` (kiểm tra commit message). Công cụ: clang-format ≥ 15, clang-tidy cùng phiên bản (ghi vào SOUP/toolchain list).
