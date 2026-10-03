# Changelog — AI kit (cài vào dự án bằng scripts/install.sh)
Mỗi phiên bản thay đổi skill/gate/script = thay đổi công cụ → dự án đánh giá tái validate (docs/01-plan §3) khi upgrade.

## 2.5.0
ADR-002 Accepted. Hai ADR mới (Accepted) và skill theo đó; không đổi gate/ngưỡng/script.
- ADR-003 — lớp E2E chung: header 30 byte (`data_id`, `epoch`, `seq`, `timestamp_us`, `source_id`, `length`, `clock_domain`,
  `e2e_version`, `crc`), CRC `kCrc32Autosar` trên mã hóa chuẩn tắc, `epoch` do ssm-service cấp; `E2eProtector`/`E2eChecker`/
  `ErrorMonitor` trong `vsur-common`; wrapper DDS `SafeWriter<T>`/`SafeReader<T>` trong `vsur-idl`. Cập nhật skill Gemini
  `comm-safety`, `proto-dds`, `project-conventions`; skill Claude `comm-protocols`, `service-architecture`; mẫu `task.md`.
- ADR-004 — change request xuyên service (`CR-nnn` ở `vsur-system`, mỗi repo tự làm task của mình, không khóa chéo bằng script).
  Mẫu `docs/templates/change-request-template.md`; trường task card `change:`, trailer commit `Change:`; cập nhật
  `service-architecture`, `task-card`, `naming-conventions`, `/impact`. Coding standard Rev 0.3.
Nâng cấp dự án: `project-conventions` là file dự án (install.sh không ghi đè) — chép tay mục E2E và ba dòng ADR-002..004.

## 2.4.0
Skill & quy ước code (không đổi gate/ngưỡng). Prompt của mọi task code có thêm `design-clean-code` và `logging-impl`.
- ADR-002 (Proposed) — luật dùng C++ template: phạm vi, ràng buộc `static_assert`, tách `<name>.hpp`/`<name>_impl.hpp`, explicit
  instantiation trong test, instantiation ở repo khác. Cập nhật skill Gemini `cpp-embedded-standard`, `project-conventions`;
  skill Claude `embedded-review`, `task-card`, `service-architecture`; mẫu `task.md`; coding standard Rev 0.2.
- Skill Gemini mới **design-clean-code** (design pattern được phép/cấm: singleton, DI, factory, observer, state, strategy...;
  clean code; cấm dọn dẹp ngoài phạm vi task). delegate.sh tự chèn cho mọi task implement/fix/test. Cập nhật `embedded-review`,
  `architecture-design`, `task-card`, README, worker workflow.
- Skill Claude mới **logging-diagnostics** (kênh log, đường RT không trễ, flight recorder, một binary cho debug & sản xuất, chống
  rò rỉ PHI/secret/IP/core dump/cổng debug, rò rỉ tài nguyên) và skill Gemini **logging-impl** (delegate.sh tự chèn cho task code).
  Cập nhật `embedded-review`, `medical-cybersecurity`, `/release-check`, CLAUDE.md, coding standard.

## 2.3.0
Gate & merge (khắc phục điểm yếu tồn tại sau 2.2.1):
- Bố cục mã nguồn cấu hình được: `SRC_DIRS_RX`, `TEST_DIRS_RX`, `EXCLUDE_RX` (code sinh IDL, submodule). Code nằm ngoài bố cục →
  `[layout] FAIL` (trước đây gate SKIP mọi bước và PASS rỗng khi code không ở `src|inc|include/`).
- Header production thay đổi mà không có `.cpp` nào đổi → cppcheck/clang-tidy chấm mọi TU production (trước đây SKIP).
- Banned-API: production theo class/platform; test chỉ luật chung (`banned:test`) — tránh FAIL giả do GoogleTest dùng container/new.
- Sanitizer cho Class B/C: `SAN_CMD` (ASan+UBSan), `TSAN_CMD`, `REQUIRE_SAN`; CMake phải khai option `VSUR_SANITIZE` (kiểm qua
  CMakeCache để không PASS giả). Windows host → SKIP (hoặc FAIL khi `REQUIRE_SAN=1`).
- `BUILD_CMD_host` xuất `compile_commands.json`; `TIDY_CMD` FAIL nếu thiếu file này.
- merge.sh: chỉ merge vào `INTEGRATION_BRANCH`; từ chối khi repo chính có thay đổi chưa commit ngoài `.ai/`; nhánh tích hợp đã tiến
  so với base → chạy gate trên **kết quả merge** (bắt xung đột ngữ nghĩa giữa task song song); code + bằng chứng trong **một**
  merge commit (trailer `Evidence:`), lỗi giữa chừng → hoàn tác để chạy lại; `provenance.txt` ghi `integration` + `post_merge_gate`.
- cross-review.sh: agy kết thúc lỗi → không chấp nhận kết quả (đồng nhất với delegate.sh).
- install.sh: lỗi SHA-256 dừng thật (bản 2.2.1 chỉ thoát subshell); báo `CONFIGKEY` khi kit có khóa config mà dự án chưa có.
Line ending (Windows + Linux):
- `.gitattributes`: `* text=auto eol=lf` + đuôi code/build/tài liệu rõ ràng + `binary` cho nhị phân → working tree luôn LF, không
  phụ thuộc `core.autocrlf` từng máy (trước đây chỉ vài đuôi được ép LF → `.cpp/.hpp/CMakeLists.txt` bị đổi CRLF trên Windows).
  File này là file dự án (install.sh không ghi đè): dự án cũ chép tay, rồi `git add --renormalize .` nếu cần.
Skill (hệ nhiều service C++ trên Linux, DDS, CANopen, EtherCAT, đồng bộ/phân tán):
- Claude: **distributed-sync-control** (+ references timing-budget, distributed-ssm), **service-architecture** (polyrepo, lifecycle,
  IDL/ICD, deployment, restart policy, release bundle); comm-protocols thêm references **dds**, **canopen**; ethercat.md bổ sung DC
  (master/bus shift, 0x092C, SYNC0 shift, 0x1C32/0x1C33, CSP 0x60C2); linux-rt-design thêm PTP/sanitizer/service.
- Gemini: **proto-dds**, **proto-canopen**, **sync-control-impl**, **linux-service-impl**; proto-ethercat bổ sung DC/CSP.
  delegate.sh: `protocols: canopen` tự kèm `proto-can`; ethercat/canopen tự kèm `sync-control-impl`.
- Mẫu `.ai/templates/bootstrap-service.md`; bootstrap-T000 thêm CMake (compile_commands, `VSUR_SANITIZE`) và ghi chú polyrepo.
Nâng cấp dự án: thêm thủ công các khóa mới vào `.ai/config.env` (install.sh liệt kê `CONFIGKEY`); gate script có giá trị mặc định
cho config cũ, riêng `INTEGRATION_BRANCH` mặc định `main`.

## 2.2.1
- Gate hỗ trợ giai đoạn bootstrap khi chưa có tool MISRA/MC/DC; bật `REQUIRE_MISRA=1`/`REQUIRE_MCDC=1` trước pilot/release để fail-closed.
- Loại bỏ quote không an toàn khi chèn danh sách file vào lệnh gate; kiểm tra ID task, branch/base của worktree và lỗi non-zero từ `agy`.
- Hook worker chuẩn hóa key đường dẫn, từ chối write không xác định target và symlink escape; scope check cũng từ chối symlink.
- Merge không còn bỏ qua lỗi commit bằng chứng; thu hẹp quyền Git trực tiếp của Claude.
- Gate kiểm tra Python runtime, ghi version toolchain vào output và giới hạn glob scope theo đúng cấp thư mục.
- Installer fail-fast khi không thể tính hash hoặc sao chép file.

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
