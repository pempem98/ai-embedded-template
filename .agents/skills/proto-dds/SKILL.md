---
name: proto-dds
description: Implement giao tiếp DDS (DataWriter/DataReader, WaitSet, QoS profile, IDL sinh code, E2E) giữa các service/node. Áp dụng khi protocols có dds.
---
# DDS
- Vendor, phiên bản, API (C++ PSM / modern C++ API), file QoS profile, tên topic, kiểu IDL, domain ID, partition: ĐÚNG task card.
  Không tự đổi QoS trong code, không tạo QoS inline — chỉ nạp profile được chỉ định. Không thêm topic/kiểu mới.
- Code sinh từ IDL (`gen/`) KHÔNG sửa tay, không commit bản sửa; chỉ dùng qua wrapper của dự án nếu task card có.
- Tạo entity (participant, topic, writer, reader, WaitSet) trong pha init; kiểm mọi giá trị trả về/null; lỗi → trả `Status`, không tiếp tục.
- Sau khi tạo, đọc lại QoS thực tế của writer/reader so với giá trị task card khi task card yêu cầu; xử lý
  `offered_incompatible_qos` / `requested_incompatible_qos` / `liveliness_lost` / `deadline_missed` → báo theo task card.
- Nhận: ưu tiên WaitSet trong thread OSAL được chỉ định; listener (nếu task card cho) chỉ copy dữ liệu vào SPSC/triple buffer rồi return
  — không xử lý logic, không block, không gọi logger đồng bộ trong callback.
- Mỗi mẫu: kiểm `SampleInfo.valid_data` TRƯỚC khi đọc; xử lý `instance_state` NOT_ALIVE_DISPOSED / NO_WRITERS theo task card;
  rồi kiểm E2E (source_id, seq qua `vsur::seq_delta`, tuổi = now − timestamp cùng miền đồng hồ ≤ max_age, CRC) theo comm-safety.
- Thread RT (fieldbus loop) KHÔNG gọi API DDS: chỉ đọc/ghi SPSC/triple buffer; thread bridge do task card chỉ định gọi DDS.
- Gửi: điền header E2E (seq tăng, timestamp, source_id, CRC) trước `write`; kiểm kết quả `write` (timeout/out of resources là lỗi,
  không retry vô hạn). Liveliness MANUAL: chỉ `assert_liveliness`/write khi vòng xử lý thật sự tiến triển.
- Kiểu dữ liệu bounded: không gán vượt bound (kiểm độ dài trước), không dùng `std::string`/`std::vector` của API ở đường Class C
  nếu task card không cho.
- Loan/zero-copy: chỉ khi task card cho; trả loan trên mọi nhánh (RAII).
- Test (host): logic tách khỏi DDS qua interface (Fake publisher/subscriber); test valid_data=false, instance disposed, seq lặp/nhảy,
  mẫu quá tuổi, CRC sai, source_id lạ, writer trả lỗi, QoS incompatible callback, deadline missed.
