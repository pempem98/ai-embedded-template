---
id: T000
title: Common core headers & OSAL/HAL interfaces (ADR-001)
type: implement
owner: lead
platform: host
safety_class: C
software_item: SI-000
requirements: SRS-000        # thay bằng SRS của common core (vd. xử lý lỗi, giám sát thời gian) — /reqs trước
risk_controls:
detailed_design: docs/04-detailed-design/SDD-common-core.md   # /design common-core trước khi start
protocols:
decisions: ADR-001
effort: high
---
## Mục tiêu
Tạo nền tảng chung theo ADR-001 để mọi task sau (Gemini và Lead) build được: kiểu lỗi, Result, assert, thời gian, container,
byte order, CRC, sequence, interface OSAL/HAL/log/safety, fake cho test. Chia nhỏ thành T000a/b/c nếu diff > ~300 dòng.

## Files được phép
- tạo: include/common/*.hpp, src/common/*.cpp, include/osal/*.hpp, src/osal/host/*.cpp, include/hal/*.hpp,
  include/log/*.hpp, src/log/*.cpp, include/safety/fault.hpp, test/fakes/*.hpp, test/common/test_*.cpp, test/osal/test_*.cpp
- sửa: CMakeLists.txt (thêm thư mục con & target common/osal/log), src/CMakeLists.txt, test/CMakeLists.txt

## Quyết định đã chốt
- Toàn bộ API theo `.agents/skills/project-conventions/SKILL.md` (ADR-001). Mọi header đánh dấu `// OWNER: lead`.
- `Result<T>`: lưu `T` và `Error` không cấp phát (union có kiểm soát hoặc `std::optional<T>` + Error), `value()` khi rỗng → `VSUR_ASSERT`.
- `fatal_error()` trên host: ghi log + `std::abort()`; trên Linux/QNX/MCU: Lead định nghĩa trong task nền tảng riêng.
- CRC preset ban đầu: `kCrc16Modbus`, `kCrc32IsoHdlc` (check value theo catalogue CRC chuẩn, có test).

## Tiêu chí chấp nhận
- [ ] Build host không warning; gate Class C PASS (100% line + branch cho src/common, src/log).
- [ ] Test biên cho byte_order (offset/độ dài), CRC check value, seq_delta tại wrap, StaticVector/SpscRing đầy/rỗng.
- [ ] Review độc lập + cross-review + kỹ sư ký trước khi task Gemini đầu tiên dùng các header này.
