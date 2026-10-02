---
name: traceability-tags
description: Quy ước gắn tag truy vết IEC 62304 trong code và test (@req, @rcm, @verifies). Bắt buộc cho mọi task code.
---
# Tag
- Hàm/khối implement yêu cầu: Doxygen `@req SRS-012` (có thể nhiều ID: `@req SRS-012, SRS-013`) đặt tại ĐỊNH NGHĨA
  trong `.cpp`/`.c` (hoặc header do bạn tạo). Header interface `OWNER: lead` bạn không được sửa, và tag ở đó
  trace.py KHÔNG tính là đã implement.
- Điểm implement biện pháp kiểm soát rủi ro (ISO 14971): `@rcm RCM-004` — đặt ngay tại đoạn code kiểm tra/xử lý.
- Test case: `@verifies SRS-012` / `@verifies RCM-004` trong comment ngay trên test.
- Ngoại lệ quy tắc (đã được Lead phê duyệt): comment cùng dòng `// @deviation DEV-007`.
  KHÔNG tự tạo deviation — phải hỏi Lead.

# Quy tắc
- Chỉ dùng ID có trong task card (`requirements:`, `risk_controls:`). Không tự đặt ID mới.
- Mỗi ID trong task card phải có ít nhất 1 @req/@rcm VÀ 1 @verifies. `scripts/trace.py` sẽ kiểm tra.
- Không gắn tag "cho đủ" vào code không thực sự implement yêu cầu đó.

- `@verifies` chỉ đặt trong file test (`test/<module>/test_<file>.cpp`); đặt trong `src/` → trace.py báo GAP.

```cpp
// src/teleop/velocity_limiter.cpp
namespace vsur::teleop {
/**
 * @brief Giới hạn vận tốc khớp theo cấu hình an toàn.
 * @req SRS-041
 * @rcm RCM-012  Chặn lệnh vượt v_max → tránh chuyển động ngoài ý muốn (HAZ-007)
 */
Error VelocityLimiter::clamp_velocity(const JointCmd& cmd_in, JointCmd& cmd_out) const noexcept { ... }
}  // namespace vsur::teleop

// test/teleop/test_velocity_limiter.cpp
/// @verifies SRS-041
/// @verifies RCM-012
TEST(VelocityLimiter, ClampsCommandAboveMax) { ... }
```
