# Changelog — AI kit (cài vào dự án bằng scripts/install.sh)
Mỗi phiên bản thay đổi skill/gate/script = thay đổi công cụ → dự án đánh giá tái validate (docs/01-plan §3) khi upgrade.

## 2.1.0
- Chốt baseline quy ước dự án (ADR-001): namespace `vsur`, Error/Result/Status, OSAL/HAL, logging & report_fault, container tĩnh,
  std::chrono, byte_order/CRC/sequence, GoogleTest/GoogleMock/Unity; mẫu task bootstrap T000 (owner lead).
- Kiến trúc & yêu cầu: skill `architecture-design` (SyAD/SAD, view, Mermaid), `requirements-engineering` (UN → SYS → SRS, EARS);
  lệnh `/arch`, `/reqs`; template SysRS/SRS/SyAD/SAD; trace.py kiểm SYS ↔ SRS.
- Coding standard: `naming-conventions` (đặt tên, ID, commit message), `cpp-safety-standard` → `cpp-embedded-standard`;
  `.clang-format`, `.clang-tidy` (identifier naming), `.editorconfig`, git hook `commit-msg`; docs/01-plan/coding-standard.md.
- Commit do script tạo theo Conventional Commits + trailer Task/Refs/Round; merge commit có Reviewed-SHA/Reviewed-by.
- `scripts/install.sh` cài/nâng cấp kit vào từng repo (manifest, không ghi đè file dự án đã sửa).
- Gộp nội dung review-request vào docs/01-plan/AI-assisted-development-procedure.md §5.

## 2.0.0
- Scope check, gate từ repo chính, REVIEWED_SHA, chạy lại gate khi merge, hook bảo vệ chữ ký, lead.sh, cross-review,
  comm-protocols + proto-*, project-conventions, ADR, metrics, /status /retro /impact /integrate /threat.
