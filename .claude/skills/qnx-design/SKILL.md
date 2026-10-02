---
name: qnx-design
description: Quyết định thiết kế cho QNX Neutrino / QNX OS for Safety trong thiết bị y tế — tiến trình, message passing, adaptive partitioning, HA, dùng safety manual. Dùng khi thiết kế/review module platform=qnx hoặc viết task card cho QNX.
---
# Chốt trong task card / SDD
- Phiên bản QNX SDP / QNX OS for Safety (SOUP); nếu dùng bản safety-certified: danh sách API & ràng buộc từ **safety manual** (giao Gemini task research tóm tắt vào .ai/notes/, không tự đọc).
- Mô hình tiến trình: mỗi software item quan trọng là một process riêng (bảo vệ bộ nhớ = bằng chứng segregation).
- Giao thức message: struct header (type, version, length, sequence), mỗi server reply mọi message, timeout phía client (`TimerTimeout`), xử lý server chết (`_NTO_CHF_COID_DISCONNECT`/pulse).
- Adaptive partitioning: budget CPU cho partition safety-critical, critical budget; tiến trình nào vào partition nào.
- Priority & policy từng thread; ưu tiên interrupt thread (`InterruptAttachEvent`).
- High availability: heartbeat, hành động khi process chết (restart / safe state) — chỉ restart nếu phân tích rủi ro cho phép.
- Resource manager cho driver; quyền truy cập (`procmgr_ability`) tối thiểu.
- Logging slog2, buffer size; core dump policy.

# Bằng chứng
- Đo latency interrupt→thread, end-to-end message latency trên phần cứng đích.
- Test phản ứng khi server crash, message hỏng, partition quá tải.
