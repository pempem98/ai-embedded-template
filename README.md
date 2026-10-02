# VinSurgical AI Template v2 — Claude (Lead) + Gemini CLI (Workers)
Template khép kín cho phát triển phần mềm robot phẫu thuật theo IEC 62304 (Class A/B/C), ISO 14971, hướng tới hồ sơ FDA.
Nền tảng: MCU (C), Embedded Linux PREEMPT_RT (C++), QNX Neutrino / QNX OS for Safety (C++).

> AI tạo code và **bằng chứng**; con người **quyết định và phê duyệt** (phân loại, rủi ro, deviation, SOUP, merge Class B/C).
> Template không làm sản phẩm "đạt chuẩn" — đánh giá tuân thủ thuộc RA/QA và tổ chức đánh giá.

## Dùng cho dự án: cài vào TỪNG repo (không dùng thư mục workspace chung)
Repo này là **AI kit có phiên bản** (`.ai/KIT_VERSION`, `CHANGELOG.md`). Mỗi repo sản phẩm (một software system hoặc monorepo)
cài kit vào **gốc repo**:
```
./scripts/install.sh ../robot-teleop            # cài mới
./scripts/install.sh ../robot-teleop --upgrade  # nâng cấp: file dự án đã sửa không bị ghi đè (sinh .kit-new)
./scripts/install.sh ../robot-teleop --dry-run  # xem trước
```
Vì sao không "thả dự án vào workspace/":
- IEC 62304 §8: bằng chứng (review, gate, trace, chữ ký) phải gắn với **đúng phiên bản code** → nằm cùng repo, cùng commit.
- Script dùng gốc git repo (worktree `../wt-<ID>`, `refs/ai/base`, merge); repo lồng trong repo khác sẽ chạy sai repo.
- Claude Code nạp `CLAUDE.md`/`.claude/` theo thư mục mở; mỗi repo có cấu hình (`config.env`, toolchain, ngưỡng) riêng.
Đọc/tìm hiểu code bên ngoài (legacy, vendor SDK) → không cần cài kit; giao task `type: research` để Gemini tóm tắt vào `.ai/notes/`.

## Cài đặt công cụ (Windows + Git Bash)
1. Cài: VS Code + Claude Code, Gemini CLI (`npm i -g @google/gemini-cli`), Git for Windows, Python 3, CMake,
   cppcheck, clang-tidy/clang-format ≥ 15, gcovr (`pip install gcovr`), ccache (tùy chọn), toolchain ARM / Linux cross / QNX SDP.
   Build Linux target thuận tiện hơn trong WSL2. Sandbox Gemini cần Docker/Podman.
2. `./scripts/install.sh <repo>` rồi làm theo "Bước tiếp theo" script in ra (config.env, project-conventions, context-brief,
   `git config core.hooksPath scripts/git-hooks`, chmod +x, commit). **`.gitattributes` bắt buộc LF** cho script.
3. Thử: `echo "trả lời OK" | gemini -p "làm theo input"`. Kiểm tra schema `.gemini/settings.json` khớp phiên bản Gemini CLI.
4. **Bảo mật**: dùng gói Gemini/Claude doanh nghiệp có cam kết không huấn luyện trên dữ liệu (docs/01-plan/AI-assisted-development-procedure.md).

## Quy trình
```
/hazard <tính năng>   phân tích mối nguy → HAZ/RCM (Draft, risk team quyết)
/reqs <nguồn>         UN → SysRS (SYS, phân bổ SW/HW/ME) → SRS (EARS, nguồn, verify method)
/arch system|software SyAD / SAD: view & sơ đồ Mermaid, interface, deployment, trade-off → ADR, verify §5.3.6
/plan <tính năng>     software item, safety class (người dùng xác nhận) → task cards (owner, protocols, decisions)
/design <unit>        SDD + interface cho Class C (Claude viết)
/delegate T01         Gemini implement trong ../wt-T01, commit mỗi round → scope + gate + trace (script repo chính)
   exit 2 → /answer   exit 0/3 → /review   exit 1 → sửa task card   exit 4 → xem report
/lead T02             code safety-critical do Claude viết: lead.sh start → sửa trong ../wt-T02 → lead.sh finish
/review T01           reviewer low/high [+ safety assessor] [+ cross-review Gemini] → .ai/reviews/T01.md (REVIEWED_SHA)
                      Class B/C: kỹ sư ký HUMAN_* (gpg tùy chọn) → merge.sh chạy lại kiểm tra, merge đúng SHA đã ký,
                      lưu bằng chứng vào docs/07-verification/records/T01
/status /trace /soup /anomaly /impact /integrate /threat /retro /release-check
```

## Cơ chế chính
| Cơ chế | Ở đâu |
|---|---|
| Skill Gemini tự chọn theo type/platform/class/protocols + project-conventions + ADR | `scripts/delegate.sh` |
| Class C: ép effort high, autofix 0, bắt buộc SDD (chèn vào prompt) | `scripts/lib.sh` |
| Phạm vi thay đổi: chỉ "Files được phép", không chạm `OWNER: lead`, script/config/skill | `scripts/check_scope.py` |
| Gate: build target + host, test, banned API, cppcheck, clang-tidy, MISRA, coverage theo class, theo phạm vi file | `scripts/gate.sh`, `check_banned.py` |
| Gate/scope/trace chạy bằng script & config repo chính (worktree không tự nới được) | `lib.sh: run_checks` |
| Truy vết `@req/@rcm/@verifies` ↔ SRS/RCM (@verifies chỉ trong test, @req không tính header của lead) | `scripts/trace.py` |
| Deviation chỉ hợp lệ khi có `APPROVED_BY` của con người | `.ai/deviations/`, `check_banned.py` |
| Code của Lead qua cùng quy trình + review chéo bằng model khác | `scripts/lead.sh`, `scripts/cross-review.sh` |
| Chữ ký gắn SHA, worktree sạch, chạy lại gate lúc merge, GPG tùy chọn | `scripts/merge.sh` (exit 1/3/5) |
| Hook chặn AI điền HUMAN_*/APPROVED_BY, sửa records; SessionStart in trạng thái | `.claude/settings.json`, `scripts/hooks/` |
| Giới hạn vòng REWORK, số liệu round/BLOCKED/REWORK, provenance | `MAX_REWORK`, `.ai/metrics.csv`, `.ai/reports/<ID>.meta` |
| Coding standard: đặt tên (clang-tidy identifier-naming), định dạng (.clang-format), commit message (git hook) | `docs/01-plan/coding-standard.md`, `scripts/git-hooks/` |
| Truy vết yêu cầu SYS ↔ SRS (nguồn, phân bổ SW) | `scripts/trace.py` |
| Cài/nâng cấp kit theo phiên bản, không ghi đè file dự án | `scripts/install.sh`, `.ai/kit-manifest.txt` |
| Hồ sơ IEC 62304 | `docs/` |

## Skills
**Claude** (`.claude/skills/`): iec62304-process, risk-management-iso14971, safety-architecture, task-card, delegate-gemini,
embedded-review, effort-routing, traceability, soup-management, medical-cybersecurity, linux-rt-design, qnx-design,
regulatory-docs, problem-resolution, **architecture-design** (+ references/diagrams), **requirements-engineering**, **comm-protocols** (+ references: can, ethercat, spi, i2c, uart, usb, ssi, biss-c, endat, ethernet),
**integration-test**.
Phân vai skill Gemini: `cpp-embedded-standard`/`c-embedded-standard` = luật ngôn ngữ · `naming-conventions` = đặt tên/định dạng/commit · `safety-coding` = lập trình phòng vệ Class B/C.
**Subagents**: fw-reviewer-low (sonnet), fw-reviewer-high (opus), fw-safety-assessor (opus), reg-doc-reviewer (sonnet).
**Gemini** (`.gemini/skills/`): worker-protocol, project-conventions, **naming-conventions**, build-protocol, traceability-tags, unit-test, cpp-embedded-standard,
c-embedded-standard, safety-coding, linux-rt-impl, qnx-impl, regulatory-doc-writer, research, effort-low, effort-high,
comm-safety, proto-can, proto-ethercat, proto-spi, proto-i2c, proto-uart, proto-usb, proto-ssi, proto-biss-c, proto-endat,
proto-ethernet, cross-review.

## Memory
Memory của Claude Code nằm ngoài repo, không thuộc quản lý cấu hình → chỉ cho sở thích cá nhân. Quyết định dự án → ADR/SDD/SRS trong repo.

## Việc bạn cần tự hoàn thiện
- Toolchain files `cmake/arm-none-eabi.cmake`, `linux-aarch64.cmake`, `qnx-aarch64le.cmake`; chạy thử `.clang-tidy`/`.clang-format` khởi đầu trên code thật và chỉnh.
- Công cụ MISRA và MC/DC (Helix QAC/Polyspace/Parasoft/PC-lint; VectorCAST/LDRA/CTC++) — điền `MISRA_CMD`, `MCDC_CMD` (có thể dùng `{FILES}`/`{SRCS}`).
- Common core theo ADR-001 (`project-conventions` đã chốt): `/design common-core` → task `.ai/templates/bootstrap-T000.md` → `/lead T000`,
  trước task Gemini đầu tiên. Lớp E2E cho message an toàn: chốt theo từng interface. Điền `context-brief.md`.
- Danh sách API được phép từ QNX safety manual; tham số giao thức/encoder cụ thể (task research → `.ai/notes/`).
- Đối chiếu bảng hoạt động theo class trong skill `iec62304-process` với bản tiêu chuẩn công ty đang áp dụng; RA xác nhận chiến lược FDA.
- Validation công cụ AI (docs/01-plan §3) cùng QA; quyết định `SIGNOFF_MODE`.
