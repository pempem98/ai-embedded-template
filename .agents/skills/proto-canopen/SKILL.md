---
name: proto-canopen
description: Implement ứng dụng CANopen master/slave (NMT, heartbeat, SYNC, PDO, SDO, EMCY, cấu hình theo DCF, CiA 402) trên stack được chỉ định. Áp dụng khi protocols có canopen (luôn kèm proto-can).
---
# CANopen
- Stack & API: ĐÚNG task card (CANopenNode, Lely, emtas...). Không sửa EDS/DCF, object dictionary, PDO mapping, COB-ID, node ID.
- NMT: chỉ gửi lệnh NMT (start/stop/pre-op/reset) tại điểm task card chỉ định; không tự đưa node vào Operational.
- Heartbeat consumer: cấu hình đúng node/timeout; mất heartbeat / boot-up bất ngờ (node vừa reset) → báo theo task card,
  coi node chưa cấu hình cho tới khi cấu hình lại xong.
- SYNC: nếu là producer, phát từ thread/timer task card chỉ định (chu kỳ tuyệt đối, không sleep tương đối); gửi RPDO đồng bộ
  trong sync window (0x1007) sau SYNC; đo và báo trễ/lỡ cửa sổ. Kiểm SYNC counter nếu dùng 0x1019.
- PDO: đọc/ghi qua mapping sinh từ cấu hình, kiểm DLC = độ dài mapping; endianness little-endian bằng hàm `read/write_*_le`;
  scaling/đơn vị đúng bảng. TPDO nhận: kiểm timeout từng PDO (event timer/chu kỳ) → mẫu stale không dùng.
- SDO: chỉ ngoài thread RT, luôn có timeout; abort code → trả lỗi có mã, không retry vô hạn; cấu hình PDO ở Pre-op đúng trình tự
  (tắt PDO bit 31 → count 0 → mapping → count → bật) và đọc lại kiểm tra nếu task card yêu cầu.
- EMCY: giải mã error code + error register, chuyển thành FaultId theo bảng task card; không bỏ qua EMCY.
- CiA 402: controlword/statusword theo state machine Lead cung cấp; kiểm mode display 0x6061 trước khi gửi target;
  không tự clear fault, không tự enable operation.
- CANopen Safety/SRDO: KHÔNG tự implement; chỉ gọi stack safety được chỉ định.
- Test (mock CAN/stack): mất heartbeat, boot-up bất ngờ, SDO timeout/abort, PDO sai DLC, PDO quá tuổi, SYNC trễ/mất,
  RPDO ngoài sync window, EMCY, statusword bất ngờ, node về Pre-op.
