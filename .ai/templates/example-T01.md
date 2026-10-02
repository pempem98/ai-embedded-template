---
id: T01
title: Joint velocity limiter (teleoperation)
type: implement
owner: gemini
platform: qnx
safety_class: C
software_item: SI-012
requirements: SRS-041, SRS-042
risk_controls: RCM-012
detailed_design: docs/04-detailed-design/SDD-velocity-limiter.md
protocols:
decisions:
effort: high
skills:
autofix_max: 0
---
## Mục tiêu
Unit thuần (không gọi OS) giới hạn vận tốc lệnh từng khớp trước khi gửi xuống joint controller, chạy trong thread teleop 1 kHz.

## Files được phép
- tạo: src/teleop/velocity_limiter.cpp, test/teleop/test_velocity_limiter.cpp
- sửa: src/teleop/CMakeLists.txt, test/teleop/CMakeLists.txt (chỉ thêm file)
- chỉ đọc: include/teleop/velocity_limiter.hpp, include/common/result.hpp (OWNER: lead)

## Quyết định đã chốt
- Kiểu: `double`, đơn vị rad/s; số khớp `kNumJoints = 7` (constexpr trong header).
- Giới hạn `SafetyLimits::v_max_rad_s[7]` do caller cấp, đã được kiểm CRC ở tầng trên.
- Đầu vào NaN/Inf ở bất kỳ khớp nào → trả `Error::InvalidInput`, output = 0 cho TẤT CẢ khớp.
- |v| > v_max → clamp về ±v_max, đặt cờ `clamped[j] = true`, KHÔNG trả lỗi (SRS-042).
- v_max ≤ 0 hoặc NaN → `Error::InvalidLimits`, output = 0 tất cả khớp.
- Không cấp phát, không exception, `noexcept`, không trạng thái nội bộ (hàm thuần).

## Tiêu chí chấp nhận
- [ ] SRS-041 / RCM-012: mọi output |v| ≤ v_max với đầu vào ngẫu nhiên + biên (±v_max, ±v_max±ε, 0)
- [ ] SRS-042: cờ clamped đúng từng khớp
- [ ] NaN, +Inf, -Inf ở từng khớp → InvalidInput, output 0
- [ ] v_max ≤ 0 / NaN → InvalidLimits
- [ ] 100% line + branch coverage

## Ngoài phạm vi
- Không gọi safety supervisor, không log, không chạm thread/QNX API.
