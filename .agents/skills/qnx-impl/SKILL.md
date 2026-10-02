---
name: qnx-impl
description: Cách implement code trên QNX Neutrino / QNX OS for Safety (message passing, resource manager, pulse, interrupt, priority). Tự động áp dụng cho platform=qnx.
---
# QNX
- Build bằng toolchain QNX (qcc/q++) qua CMake toolchain file của dự án; không đổi cờ build.
- Nếu dự án dùng QNX OS for Safety: chỉ dùng API nằm trong safety manual (task card/Lead cung cấp danh sách); API ngoài danh sách → hỏi.
- IPC: message passing đồng bộ `MsgSend`/`MsgReceive`/`MsgReply` qua channel/connection; thông báo bất đồng bộ dùng **pulse** (`MsgSendPulse`).
  Server phải reply MỌI message (kể cả lỗi bằng `MsgError`) — client không được treo.
  Luôn kiểm tra `rcvid`, kích thước message, kiểu message (header có type + version).
- Dịch vụ dạng file/driver: dùng resource manager framework (`resmgr_attach`, `iofunc_*`) theo task card.
- Interrupt: ưu tiên `InterruptAttachEvent` (xử lý trong thread); `InterruptAttach` (ISR handler) chỉ khi task card yêu cầu, handler cực ngắn.
- Thread: priority & scheduling policy theo task card; dùng priority inheritance (mặc định của QNX mutex) đúng cách; không busy-wait.
- Timer chu kỳ: `timer_create` với pulse event hoặc `TimerTimeout` cho thao tác blocking có timeout. Mọi lời gọi blocking phải có timeout.
- Bộ nhớ: cấp phát lúc init; `mmap_device_memory`/`mmap_device_io` cho thanh ghi, cần `ThreadCtl(_NTO_TCTL_IO, 0)` — chỉ ở module được phép.
- Logging: `slog2` theo buffer set của dự án.
- High availability: heartbeat/đăng ký theo cơ chế dự án (vd. HAM) — không tự thêm.
- Mọi API kiểm tra `-1`/`errno` (hoặc `EOK`).
