---
id: T001
title: <name>-service skeleton (main, lifecycle, CMake, DDS participant)
type: implement
owner: lead                # khung lifecycle/safe state/thread RT = việc của Lead; logic nghiệp vụ giao Gemini sau
platform: linux
safety_class: C            # theo phân loại service trong SAD (skill service-architecture)
software_item: SI-<SVC>-00
requirements: SRS-<SVC>-001  # lifecycle, khởi tạo, giám sát — /reqs trước
risk_controls:
detailed_design: docs/04-detailed-design/SDD-<name>-service-skeleton.md
protocols: dds
decisions: ADR-001         # + ADR polyrepo, DDS vendor, miền đồng hồ, restart policy
skills: linux-service-impl
effort: high
---
## Mục tiêu
Khung service build ra binary `<name>-service` trên Linux (aarch64) + chạy được trên host để test: main, nạp cấu hình, lifecycle
cục bộ điều khiển bởi ssm-service, health/watchdog, DDS participant theo `vsur-idl`, thread theo bảng deployment.
Chia T001a (CMake + submodule + main/cấu hình) / T001b (lifecycle + health) / T001c (DDS bridge) nếu diff > ~300 dòng.

## Điều kiện trước
- `external/vsur-common` và `external/vsur-idl` là submodule ghim **tag** (không nhánh); `.ai/config.env`: `EXCLUDE_RX` gồm
  `external/` và `gen/`, `INTEGRATION_BRANCH` đúng nhánh tích hợp của repo.
- ADR đã chốt: DDS vendor/phiên bản, miền đồng hồ, restart policy theo class, user/capabilities, CPU set.

## Files được phép
- tạo: CMakeLists.txt, src/CMakeLists.txt, test/CMakeLists.txt, src/main.cpp, src/<name>/*.cpp, include/<name>/*.hpp,
  test/<name>/test_*.cpp, deploy/<name>-service.service, deploy/<name>-service.conf
- sửa:

## Quyết định đã chốt
- CMake: `CMAKE_EXPORT_COMPILE_COMMANDS ON`; option `VSUR_SANITIZE` (STRING, xem bootstrap-T000) & `ENABLE_COVERAGE`;
  `add_subdirectory(external/vsur-common)`; code IDL sinh vào `${CMAKE_BINARY_DIR}/gen` (hoặc `gen/`) bằng generator ghim phiên bản;
  target thực thi `<name>-service` + thư viện `<name>_core` (logic, test được trên host không cần DDS thật).
- Lifecycle: UNCONFIGURED → INACTIVE → ACTIVE ↔ SAFE → ERROR; lệnh từ topic `transition_cmd`, báo `transition_ack`/`service_status`
  (skill distributed-sync-control → references/distributed-ssm.md). Khởi động vào INACTIVE.
- systemd: `Type=notify`, `WatchdogSec=<…>`, `Restart=<…>` theo restart policy, `User=`, `AmbientCapabilities=CAP_SYS_NICE CAP_IPC_LOCK`
  (chỉ khi có thread RT), `CPUAffinity=`; READY sau khi init xong.
- Bảng thread: <tên | policy | prio | CPU | chu kỳ | deadline | phản ứng overrun>.
- Cấu hình: `/etc/vsur/<name>-service.conf`, schema version <n>, các trường & miền giá trị <…>; sai → exit code <…>.
- Version: công bố version, git SHA, hash `vsur-idl` trong `service_status`.

## Tiêu chí chấp nhận
- [ ] Build `linux` (cross) + `host` không warning; gate Class <C> PASS; `[asan-ubsan]`, `[tsan]` PASS trên Linux/WSL.
- [ ] Test: cấu hình sai từng trường → không khởi động; mọi cạnh lifecycle hợp lệ/không hợp lệ; watchdog không kick khi một thread dừng;
      SIGTERM → SAFE trước khi thoát; epoch SSM cũ bị bỏ.
- [ ] Integration (SIL, task riêng): service + ssm-service giả lập trên DDS localhost — mất SSM → SAFE trong ≤ <T> ms.
