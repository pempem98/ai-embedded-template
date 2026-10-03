# Context brief (≤ 50 dòng) — Lead & subagent đọc file này thay vì suy ra lại từ code
<!-- OWNER: lead. Cập nhật khi SAD thay đổi. Chỉ tóm tắt; chi tiết ở SAD/SDD. -->

## Hệ thống
- Sản phẩm: TBD (vd. robot phẫu thuật nội soi N cánh tay, console + patient cart + vision cart)
- Mục đích sử dụng / phân loại thiết bị: TBD(RA)

## Node & nền tảng
| Node | CPU/MCU | OS | Vai trò | Class cao nhất |
|---|---|---|---|---|
| TBD | | | | |

## Giao tiếp
| Link | Giao thức | Chu kỳ | Dữ liệu | Lớp an toàn (E2E/FSoE/...) |
|---|---|---|---|---|
| TBD | | | | |

## Vòng điều khiển & timing budget
| Loop | Node | Chu kỳ | Deadline | Ghi chú |
|---|---|---|---|---|
| TBD | | | | |

## Safe state theo chế độ
- TBD (setup / teleop / instrument exchange / homing)

## ADR nền tảng CHƯA CÓ — động đến thì dừng, lập ADR trước (xóa dòng khi đã có ADR)
- **Vendor DDS** (vendor, phiên bản, generator, license): chặn mọi task `protocols: dds`, wrapper `SafeWriter`/`SafeReader`,
  QoS profile XML, mục DDS trong SOUP list.
- **Miền đồng hồ & PTP/gPTP** (grandmaster, quan hệ với EtherCAT DC, hành vi khi mất lock): chặn `timestamp_us`/`clock_domain`/
  `max_age` của E2E (ADR-003), stale check giữa các node, timing budget end-to-end.

## Quy ước chính
- Xem `.agents/skills/project-conventions/SKILL.md` và `.ai/decisions/`.
