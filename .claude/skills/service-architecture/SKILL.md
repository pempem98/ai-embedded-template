---
name: service-architecture
description: Kiến trúc hệ nhiều service C++ (Linux/QNX) cho robot phẫu thuật theo polyrepo — teleop-service, comm-service, kinematics-service, ssm-service... Phân chia service ↔ software item & safety class, repo chung (vsur-common, vsur-idl), interface DDS/IDL & version, lifecycle service, deployment (node, CPU, systemd, thứ tự khởi động), health/restart policy, cấu hình, release bundle hệ thống, truy vết xuyên repo. Dùng khi tạo service mới, /arch software, /plan nhiều service, viết task bootstrap service, hoặc người dùng nhắc "service", "daemon", "process", "polyrepo", "IDL", "ICD".
---
# Bố cục polyrepo (đã chốt — ADR của dự án)
| Repo | Nội dung | Ghi chú |
|---|---|---|
| `vsur-system` | SysRS, SyAD, hazard hệ thống, ICD tổng, ma trận tương thích phiên bản, release bundle | Không có code sản phẩm |
| `vsur-common` | error/result/osal/hal/log/safety API (ADR-001), container, CRC, E2E | SI riêng, tag semver |
| `vsur-idl` | IDL + QoS profile XML + bảng topic (ICD dạng máy đọc) | Configuration item; tag semver; hash nội dung |
| `<name>-service` | `src/ include/ test/ docs/` của service; `external/vsur-common`, `external/vsur-idl` (submodule ghim tag) | Kit AI cài vào mỗi repo |
- Submodule/package ghim theo **tag**, không theo nhánh. Nâng phiên bản = task riêng + /impact (ảnh hưởng mọi service dùng nó).
- `EXCLUDE_RX` của gate loại `external/` và `gen/` (code sinh từ IDL): chúng được verify ở repo/tool riêng.
  Hệ quả với template của SDK (ADR-002): service instantiate template **nhận hành vi** (policy/traits/callable) với kiểu của
  mình → code sinh ra không được `vsur-common` verify và nằm ngoài gate của service → phải có test trong repo service.
- ID yêu cầu có tiền tố service để truy vết xuyên repo: `SRS-TELEOP-012`, `SI-KIN-03`; SYS/HAZ/RCM ở `vsur-system`.
  `trace.py` chạy trong từng repo; liên kết SYS ↔ SRS xuyên repo kiểm ở `vsur-system` (/trace tổng hợp trước release).

# Service ↔ software item ↔ class
- Mỗi service = 1 software system/SI cấp cao (có thể chia SI con). Class theo hazard mà service góp phần (skill `iec62304-process`):
  teleop/kinematics/ssm thường C; comm-service C nếu mang lệnh chuyển động; logging/UI bridge có thể A/B **nếu** segregation chứng minh được.
- Segregation giữa process trên Linux (MMU, user riêng, cgroup, không chia sẻ bộ nhớ ghi) là lập luận một phần; Class C vẫn cần
  biện pháp độc lập ngoài Linux (skill `safety-architecture`). Ghi lập luận trong SAD §segregation.

# Interface (ICD) — `vsur-idl`
- Mỗi topic: tên, kiểu IDL, producer/consumer, chu kỳ/deadline, QoS profile, class dữ liệu (safety/non-safety), lớp E2E, max_age.
- Kiểu dữ liệu bounded (`sequence<T, N>`, `string<N>`), `@final` cho dữ liệu an toàn; mọi message an toàn có header E2E
  (source_id, seq, timestamp + miền đồng hồ, CRC) — định nghĩa một lần trong `vsur-idl`.
- Version: semver của `vsur-idl` + hash nội dung IDL/QoS nhúng vào binary; service công bố hash trong `service_status`;
  SSM từ chối ACTIVE khi hash không khớp ma trận tương thích.
- Đổi interface = task ở `vsur-idl` + task cập nhật ở mọi service consumer; /impact bắt buộc.

# Lifecycle & vận hành (chốt trong SAD/SDD, worker dùng skill `linux-service-impl`)
- Lifecycle cục bộ: UNCONFIGURED → INACTIVE → ACTIVE ↔ SAFE → (ERROR); chuyển theo lệnh ssm-service
  (skill `distributed-sync-control` → `references/distributed-ssm.md`).
- Khởi tạo xong mới báo READY (systemd `Type=notify`); cấp phát/khởi tạo DDS entity/mở thiết bị trong pha init.
- Watchdog: systemd `WatchdogSec` cho phát hiện treo process; chỉ kick khi health checker xác nhận mọi thread quan trọng tiến triển.
- Restart policy là **quyết định an toàn**: service Class C bị crash → không tự quay lại ACTIVE; `Restart=` (nếu có) chỉ đưa về
  INACTIVE, SSM quyết. Ghi `StartLimitBurst`, hành vi khi vượt (SSM → FAULT).
- Thứ tự khởi động/phụ thuộc (`After=`/`Requires=`) và hành vi khi phụ thuộc chưa sẵn sàng: chờ có timeout, không busy loop.
- Bảng deployment: service · node · user/group · capabilities · CPU set · thread (policy/prio/CPU) · bộ nhớ khóa · unit file.
- Cấu hình runtime: file read-only có schema & version, kiểm khi khởi động (sai → không khởi động); tham số an toàn (giới hạn khớp,
  timeout) là configuration item, đổi = thay đổi có kiểm soát (/impact).

# Release bundle hệ thống
- Mỗi service release riêng (tag + bằng chứng gate/review trong repo đó); bản phát hành hệ thống = manifest ghim phiên bản mọi
  service + vsur-common + vsur-idl + kernel/image + firmware drive/ENI/DCF → kiểm ma trận tương thích, system test trên đúng manifest.
- SBOM hợp nhất cho cả image (skill `soup-management`, `medical-cybersecurity`).

# Câu hỏi phải chốt (ADR) trước khi viết service đầu tiên
DDS vendor & phiên bản (skill `comm-protocols` → `references/dds.md`); miền đồng hồ & PTP; CANopen/EtherCAT master stack;
lớp E2E chung; cách build image (Yocto/Buildroot), toolchain; quy ước tên topic/domain ID; restart policy theo class.

# Review — REJECT nếu
Service tự đổi trạng thái hệ thống; interface không bounded/thiếu E2E cho dữ liệu an toàn; submodule theo nhánh; tự restart vào
ACTIVE; watchdog kick từ timer độc lập với tiến triển thread; cấu hình an toàn không kiểm khi khởi động; thiếu hash interface.
