---
name: naming-conventions
description: Quy ước đặt tên & định dạng chuẩn của dự án C/C++ thiết bị y tế — file, thư mục, namespace, kiểu, hàm, biến, hằng, enum, macro, đơn vị, test, ID tài liệu. Luôn áp dụng cho task code. clang-tidy (readability-identifier-naming) & clang-format thực thi tự động.
---
<!-- Nguồn kiểm soát: docs/01-plan/coding-standard.md trỏ tới file này. Thay đổi = thay đổi coding standard (Lead + kỹ sư duyệt). -->
# Nguyên tắc
- Tên nói ĐÚNG ý nghĩa, đọc được như tiếng Anh; không viết tắt tự chế. Viết tắt chỉ trong danh sách cho phép.
- Từ viết tắt/acronym coi như một từ: `CanFrame`, `EthercatMaster`, `SpiDriver`, `crc_u16` (không `CANFrame`, `SPIDriver`).
- Không dùng tên bắt đầu bằng `_` hoặc chứa `__` (dành cho compiler/thư viện chuẩn). Không trùng tên giữa scope (shadow).
- Không ký hiệu Hungarian (`iCount`, `pData`, `m_`). Kiểu đã nói lên kiểu dữ liệu.

# C++ (host / Linux / QNX)
| Thực thể | Kiểu viết | Ví dụ |
|---|---|---|
| File | snake_case, `.hpp`/`.cpp`, tên = tên class chính | `velocity_limiter.hpp`, `velocity_limiter.cpp` |
| File test | `test_<file>.cpp` | `test_velocity_limiter.cpp` |
| Thư mục / module | snake_case | `include/teleop/`, `src/teleop/`, `test/teleop/` |
| Namespace | snake_case, gốc dự án + module | `vsur::teleop` — gốc cố định `vsur`; mọi code dự án nằm trong `vsur::<module>` |
| Class, struct, enum, alias, template param | PascalCase | `VelocityLimiter`, `JointCmd`, `using JointArray = ...`, `template <typename Value>` |
| Hàm, method | snake_case, bắt đầu bằng động từ | `clamp_velocity()`, `read_position()`, `is_enabled()` |
| Biến cục bộ, tham số | snake_case | `joint_idx`, `cmd_in` |
| Thành viên private/protected | snake_case + `_` cuối | `limit_rad_s_`, `state_` |
| Thành viên public của struct dữ liệu | snake_case, không `_` | `JointCmd::vel_rad_s` |
| Hằng `constexpr`/`const` tĩnh, hằng thành viên | `k` + PascalCase | `kNumJoints`, `kCycleTimeUs` |
| Enumerator (`enum class`) | PascalCase | `Error::InvalidInput`, `State::Operational` |
| Macro (hạn chế tối đa) | UPPER_SNAKE, tiền tố dự án | `VSUR_ASSERT`, include guard `VSUR_TELEOP_VELOCITY_LIMITER_HPP_` (`VSUR_<MODULE>_<FILE>_HPP_`) |
| Biến toàn cục thay đổi được | Cấm. Ngoại lệ cần deviation: `g_` + snake_case | `g_isr_tick_count` |
| Mock / fake trong test | `Mock`/`Fake` + tên interface | `MockJointDriver`, `FakeClock` |

- `enum class` luôn khai báo kiểu nền: `enum class Error : std::uint8_t`.
- Bool: tiền tố `is_`, `has_`, `can_`, `should_` (`is_clamped`, `has_fault`). Hàm trả bool cũng vậy.
- Header dùng include guard (không `#pragma once` — implementation-defined theo MISRA/AUTOSAR).
- Một class public chính mỗi cặp file; tên file = snake_case của class.

# C (MCU)
| Thực thể | Kiểu viết | Ví dụ |
|---|---|---|
| File | `<module>_<thành phần>.c/.h` | `enc_biss.c`, `enc_biss.h` |
| Hàm public | `<module>_<động từ>_<danh từ>` | `enc_biss_read_position()` |
| Hàm/biến file-scope (`static`) | snake_case, biến có tiền tố `s_` | `s_frame_buf`, `parse_frame()` |
| Kiểu (typedef struct/enum) | `<module>_<tên>_t` | `enc_biss_cfg_t` |
| Hằng, enumerator, macro | `<MODULE>_UPPER_SNAKE` | `ENC_BISS_CRC_POLY`, `ENC_BISS_ERR_TIMEOUT` |
| Biến toàn cục (cần deviation) | `g_<module>_<tên>` | `g_enc_biss_isr_count` |
Hậu tố `_t` chỉ dùng trong code MCU (POSIX dành riêng `_t` trên Linux/QNX — code C++ không dùng).

# Đơn vị trong tên (khi chưa dùng strong type của dự án) — luôn chữ thường
`_s` `_ms` `_us` `_ns` · `_m` `_mm` · `_rad` `_deg` · `_rad_s` `_rad_s2` `_m_s` · `_n` (newton) `_nm` (newton-mét) ·
`_a` `_v` `_w` · `_degc` · `_pct` · `_cnt` (số đếm/tick) · `_hz`. Ví dụ: `vel_rad_s`, `torque_nm`, `timeout_us`, `wkc_cnt`.
Đổi đơn vị phải hiện rõ trong tên hàm: `rad_to_deg()`, `us_to_ticks()`.

# Viết tắt cho phép
`id idx num cnt cfg cmd ctrl err msg buf len pos vel acc max min ref tmp rx tx crc seq isr dma hal osal rt` — ngoài danh sách → viết đủ.

# Test (GoogleTest không cho `_` trong tên suite/test)
`TEST(VelocityLimiter, ClampsCommandAboveMax)` — `<Unit PascalCase>, <Hành vi PascalCase: Hàm + Điều kiện + Kết quả>`.

# ID & tên file tài liệu
Task `T001` · `UN-nnn` `SYS-nnn` `SRS-nnn` `HAZ-nnn` `RCM-nnn` `SI-nnn` `ADR-nnn` `DEV-nnn` `ANOM-nnn` `CR-nnn` (3 chữ số trở lên, không tái sử dụng) ·
`SDD-<unit-kebab>.md` · `ADR-nnn-<tieu-de-kebab>.md` · nhánh `task/<ID>`.

# Commit message (Conventional Commits + truy vết)
```
<type>(<scope>): <tóm tắt mệnh lệnh, ≤ 72 ký tự, không dấu chấm cuối>

<thân: vì sao, không phải cái gì — tùy chọn>

Task: T012
Refs: SRS-041, RCM-012
```
type: `feat` `fix` `test` `docs` `refactor` `perf` `build` `ci` `chore` `revert` `safety` (thay đổi risk control) `merge` (do merge.sh).
scope: module hoặc SI (`teleop`, `si-012`, `records`). Trailer `Task:` bắt buộc cho commit thuộc task; `Refs:` khi chạm SRS/RCM;
`Anomaly: ANOM-nnn` cho fix; `Change: CR-nnn` cho task thuộc change request xuyên service. Git hook `scripts/git-hooks/commit-msg` kiểm tra định dạng. Worker KHÔNG tự commit (delegate.sh commit theo mẫu này).
