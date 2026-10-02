---
name: linux-rt-impl
description: Cách implement code real-time trên Embedded Linux PREEMPT_RT (control loop, IPC, driver userspace). Tự động áp dụng cho platform=linux.
---
# Real-time thread (dùng lớp OSAL của dự án nếu có; đây là quy tắc nó phải tuân theo)
- Khởi tạo: `mlockall(MCL_CURRENT|MCL_FUTURE)`, prefault stack và heap, cấp phát xong TRƯỚC khi vào loop.
- Policy `SCHED_FIFO`, priority & CPU affinity đúng như task card (CPU isolate theo `isolcpus`/cgroup do hệ thống cấu hình).
- Chu kỳ: `clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next, nullptr)`; tính `next` cộng dồn, không dùng sleep tương đối.
  Đo overrun mỗi chu kỳ; overrun → xử lý theo task card (đếm, báo safety monitor).
- Trong loop RT CẤM: cấp phát bộ nhớ, I/O file/console, syscall có thể block, `std::mutex` thường, logging đồng bộ, page fault.
- Đồng bộ: hàng đợi lock-free SPSC / triple buffer cho RT ↔ non-RT; nếu bắt buộc mutex thì `PTHREAD_PRIO_INHERIT`.
- Thời gian: chỉ `CLOCK_MONOTONIC` (hoặc `CLOCK_MONOTONIC_RAW` khi task card nói); không `gettimeofday`/`CLOCK_REALTIME` cho điều khiển.
- Logging RT: ghi vào ring buffer, thread non-RT xả ra.
- Fieldbus (EtherCAT/CAN-FD/SocketCAN): dùng API master/driver mà task card chỉ định; kiểm tra working counter / lỗi bus mỗi chu kỳ.
- Watchdog phần mềm: heartbeat theo cơ chế dự án (vd. `/dev/watchdog`, systemd watchdog) — chỉ kick tại điểm task card chỉ định.
- Mọi syscall kiểm tra giá trị trả về và `errno`.
- Code logic tách khỏi syscall qua interface để unit test trên host.
