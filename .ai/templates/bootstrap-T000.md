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
decisions: ADR-001, ADR-002
effort: high
---
## Mục tiêu
Tạo nền tảng chung theo ADR-001 để mọi task sau (Gemini và Lead) build được: kiểu lỗi, Result, assert, thời gian, container,
byte order, CRC, sequence, interface OSAL/HAL/log/safety, fake cho test. Chia nhỏ thành T000a/b/c nếu diff > ~300 dòng.
Polyrepo: task này chạy trong repo `vsur-common` (SI riêng, release & tag riêng). Mỗi service dùng nó qua submodule
`external/vsur-common` ghim tag (EXCLUDE_RX loại khỏi gate của service). Service mới: mẫu `bootstrap-service.md`.

## Files được phép
- tạo: include/common/*.hpp, src/common/*.cpp, include/osal/*.hpp, src/osal/host/*.cpp, include/hal/*.hpp,
  include/log/*.hpp, src/log/*.cpp, include/safety/fault.hpp, test/fakes/*.hpp, test/common/test_*.cpp, test/osal/test_*.cpp
- sửa: CMakeLists.txt (thêm thư mục con & target common/osal/log), src/CMakeLists.txt, test/CMakeLists.txt

## Quyết định đã chốt
- CMake: `CMAKE_EXPORT_COMPILE_COMMANDS ON` (clang-tidy của gate cần); option cache `VSUR_SANITIZE` (STRING, rỗng mặc định,
  nhận `address,undefined` | `thread`) → thêm `-fsanitize=$VSUR_SANITIZE -fno-omit-frame-pointer` cho compile & link, cấm
  kết hợp với `ENABLE_COVERAGE`; `ENABLE_COVERAGE` → `--coverage`. Warning theo cpp-embedded-standard, `-Werror`.
- Thư viện xuất ra target `vsur::common`, `vsur::osal`, `vsur::log` (+ `install(EXPORT)` / dùng được qua `add_subdirectory`).
- Toàn bộ API theo `.agents/skills/project-conventions/SKILL.md` (ADR-001). Mọi header đánh dấu `// OWNER: lead`.
- Template (ADR-002): `Result`, `StaticVector`, `SpscRing`, `TripleBuffer`, `SeqCounter` tách `<name>.hpp` (khai báo, contract,
  `static_assert`) + `<name>_impl.hpp` (thân). `_impl.hpp` của `SpscRing`/`TripleBuffer` cũng `// OWNER: lead` (đồng bộ RT).
  Bộ instantiation đại diện lấy từ SDD-common-core; mỗi cái có explicit instantiation definition trong file test.
- `Result<T>`: lưu `T` và `Error` không cấp phát (union có kiểm soát hoặc `std::optional<T>` + Error), `value()` khi rỗng → `VSUR_ASSERT`.
- `fatal_error()` trên host: ghi log + `std::abort()`; trên Linux/QNX/MCU: Lead định nghĩa trong task nền tảng riêng.
- CRC preset ban đầu: `kCrc16Modbus`, `kCrc32IsoHdlc` (check value theo catalogue CRC chuẩn, có test).

## Tiêu chí chấp nhận
- [ ] Build host không warning; gate Class C PASS (100% line + branch cho src/common, src/log).
- [ ] `[asan-ubsan]` và `[tsan]` PASS trên Linux/WSL (SpscRing/TripleBuffer có test đa luồng chạy dưới TSan).
- [ ] Test biên cho byte_order (offset/độ dài), CRC check value, seq_delta tại wrap, StaticVector/SpscRing đầy/rỗng.
- [ ] Mỗi template có explicit instantiation cho bộ đại diện trong SDD; coverage tính trên `include/common/*_impl.hpp`.
- [ ] Review độc lập + cross-review + kỹ sư ký trước khi task Gemini đầu tiên dùng các header này.
