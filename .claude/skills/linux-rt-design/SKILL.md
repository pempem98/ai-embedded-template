---
name: linux-rt-design
description: Quyết định thiết kế cho Embedded Linux real-time (PREEMPT_RT) trong thiết bị y tế — phân bổ CPU, priority, IPC, đo latency, SOUP kernel. Dùng khi thiết kế/review module platform=linux hoặc viết task card cho Linux.
---
# Chốt trong task card / SDD (Gemini không được tự chọn)
- Kernel: PREEMPT_RT (mainline từ 6.12) — phiên bản kernel là SOUP, ghi vào soup-list.
- Phân bổ CPU: `isolcpus`/`nohz_full`/`rcu_nocbs` cho lõi RT; IRQ affinity của NIC EtherCAT/CAN vào lõi RT; liệt kê lõi nào cho thread nào.
- Bảng thread: tên, policy (SCHED_FIFO/SCHED_DEADLINE/OTHER), priority, CPU, chu kỳ, deadline, xử lý overrun.
- IPC RT↔non-RT: SPSC lock-free / triple buffer / shared memory + seqlock — chỉ định cụ thể.
- Đồng hồ: CLOCK_MONOTONIC; đồng bộ với EtherCAT DC nếu dùng.
- Logging & lưu trữ: thread non-RT, ring buffer, không fsync trong đường RT.
- Watchdog: phần cứng (`/dev/watchdog`) do supervisor kick; systemd `WatchdogSec` cho dịch vụ non-RT.
- Bảo mật: chạy non-root, capabilities tối thiểu (`CAP_SYS_NICE`, `CAP_IPC_LOCK`), secure boot, read-only rootfs.

# Bằng chứng cần có
- cyclictest/latency test dưới tải stress (CPU, I/O, mạng) trên phần cứng đích, kết quả max latency vào docs/07.
- Đo overrun/jitter vòng điều khiển trong system test.
- Linux là SOUP lớn, không chứng nhận an toàn sẵn: chức năng Class C phải có biện pháp kiểm soát độc lập (safety supervisor trên MCU/QNX for Safety), không chỉ dựa vào Linux.
