# State machine hệ thống phân tán (ssm-service + follower)

## Vai trò
- **ssm-service** = authority duy nhất cho trạng thái hệ thống (vd. OFF → INIT → STANDBY/SAFE → HOMING → READY → TELEOP →
  INSTRUMENT_EXCHANGE → FAULT/E-STOP). Không có service thứ hai được tự quyết trạng thái hệ thống.
- **Follower** (teleop, kinematics, comm, ...): có lifecycle cục bộ (vd. UNCONFIGURED → INACTIVE → ACTIVE → SAFE/ERROR),
  chỉ đổi theo lệnh SSM hoặc tự về SAFE khi phát hiện lỗi/mất liên lạc (luôn được phép đi về an toàn, không bao giờ tự đi ra khỏi an toàn).
- Safety supervisor độc lập (MCU/QNX/FSoE) giám sát cả SSM; SSM là Linux → không phải lớp an toàn cuối.

## Giao thức (DDS topic, chốt trong ICD/IDL)
| Topic | Hướng | QoS gợi ý | Nội dung |
|---|---|---|---|
| `system_state` | SSM → all | RELIABLE, TRANSIENT_LOCAL, KEEP_LAST 1, DEADLINE, liveliness MANUAL | state, epoch, seq, timestamp |
| `transition_cmd` | SSM → service | RELIABLE, KEEP_LAST n | target, transition_id, deadline |
| `transition_ack` | service → SSM | RELIABLE | transition_id, result (OK/REFUSED/FAILED), lý do |
| `service_status` | service → SSM | RELIABLE, TRANSIENT_LOCAL, KEEP_LAST 1, liveliness MANUAL | lifecycle state, health, fault list, version/interface hash |
| `transition_request` | service → SSM | RELIABLE | yêu cầu (vd. fault → SAFE), SSM quyết |

## Quy tắc
- Chuyển sang chế độ có chuyển động: **hai pha** — PREPARE (mọi service kiểm điều kiện, trả READY/REFUSED trong timeout) →
  COMMIT. Một REFUSED/timeout → hủy, ở lại trạng thái an toàn.
- Chuyển về an toàn: một pha, ưu tiên, không cần đồng thuận; service thực hiện ngay rồi báo.
- Mỗi lệnh có `transition_id` + `epoch` (tăng khi SSM khởi động lại) → follower bỏ lệnh epoch cũ/lặp.
- Follower mất `system_state` (deadline/liveliness) > T → tự SAFE, báo khi có lại kết nối; không tự trở lại ACTIVE.
- SSM khởi động lại → epoch mới, mọi follower về SAFE/INACTIVE, đi lại từ đầu (không "tiếp tục" chuyển động cũ).
- Service khởi động/khởi động lại → INACTIVE/SAFE; kiểm interface hash/version với SSM trước khi được ACTIVE.
- Phân vùng mạng (partition): mỗi phía tự về an toàn; không có cơ chế bầu authority mới trong lúc vận hành.
- Mọi chuyển trạng thái ghi log sự kiện (thời điểm, nguyên nhân, transition_id) — dùng cho điều tra (anomaly §9).

## Thiết kế & test
- Mô hình state machine dạng bảng (state × event → action/next) trong SDD; logic chuyển an toàn do Lead viết.
- Model checking/khảo sát tổ hợp nếu nhiều service (vd. bảng mọi tổ hợp timeout/REFUSED) — ít nhất test bao phủ mọi cạnh.
- Fault injection: kill SSM giữa PREPARE/COMMIT, mất ack, ack trễ, lệnh lặp/đảo thứ tự, epoch cũ, service restart ở mỗi state.
