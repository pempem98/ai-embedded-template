# Changelog — AI kit (cài vào dự án bằng scripts/install.sh)
Mỗi phiên bản thay đổi skill/gate/script = thay đổi công cụ → dự án đánh giá tái validate (docs/01-plan §3) khi upgrade.

## 2.2.0
- Worker chuyển từ Gemini CLI (ngừng hỗ trợ 06/2026) sang **Antigravity CLI `agy`** (vẫn dùng model Gemini):
  `.gemini/skills` → `.agents/skills`, `GEMINI.md` → `AGENTS.md`, `.gemini/commands/worker.toml` → `.agents/workflows/worker.md`,
  bỏ `.gemini/settings.json` (agy không có tools.exclude theo workspace).
- config.env: `GEMINI_*` → `AGY_BIN`, `AGY_MODEL_LOW/HIGH` (slug từ `agy models`), `AGY_TIMEOUT`, `AGY_SANDBOX`, `AGY_DENY_RETRY`;
  lib.sh ánh xạ tạm biến cũ.
- Chính sách tool cấp workspace trong repo (không dùng `~/.gemini`): `.agents/hooks.json` → `.agents/hooks/vsur_policy.py`
  (PreToolUse, fail-closed, theo `VSUR_AGY_ROLE` worker/reviewer/tương tác; dùng chung danh sách bảo vệ với check_scope.py;
  deny ghi vào `.ai-out/hook.log`). Script từ chối chạy nếu hook trong worktree khác base.
- **AI không chạy lệnh shell**: agy 1.2.x ở chế độ `-p` bỏ qua allow-list và hook `allow` (issue #548), mọi lệnh bị chặn và phiên dừng.
  Worker `--mode accept-edits` (chỉ đọc/sửa file); delegate.sh chạy scope + gate + trace và gửi lỗi lại cho worker trong cùng hội thoại
  (`--conversation`, tối đa `autofix_max + 1` lượt — lượt cuối chỉ để chuyển BLOCKED + question). Cross-review `--mode plan` (chỉ đọc).
  Skill build-protocol / worker-protocol / effort-* cập nhật theo.
- Prompt đưa qua file `.ai-out/prompt.md` trong worktree (không qua stdin/argv); log `--output-format stream-json`,
  `scripts/agy_result.py` lấy conversation id, lệnh bị chặn, response. AI cố chạy lệnh → tự resume `AGY_DENY_RETRY` lần với lời nhắc.
- Hậu kiểm git: AI đổi HEAD/nhánh worktree → gỡ commit (giữ nội dung) hoặc dừng exit 4. Cross-review từ chối model Claude.
- check_scope bảo vệ thêm `.agents/`, `AGENTS.md`, `.antigravitycli`; install.sh `--upgrade` chuyển project-conventions sang `.agents/`.

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
