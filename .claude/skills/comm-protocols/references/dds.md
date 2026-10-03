# DDS (OMG DDS + DDSI-RTPS) — service ↔ service, console ↔ cart

## Đặc điểm cần nhớ
- Data-centric publish/subscribe: DomainParticipant → Publisher/Subscriber → DataWriter/DataReader trên Topic (kiểu IDL).
  Wire protocol RTPS trên UDP (unicast/multicast) hoặc shared memory nội node. DDS là **black channel**: reliability của DDS
  ≠ an toàn; dữ liệu an toàn cần lớp E2E của dự án trong payload.
- Vendor (SOUP lớn): RTI Connext (Professional; Connext Micro/Cert — có gói bằng chứng chứng nhận cho ngành khác, kiểm hiện trạng
  với vendor), eProsima Fast DDS, Eclipse Cyclone DDS (+ iceoryx SHM), OpenDDS. Trộn vendor qua RTPS được nhưng QoS/XTypes/
  discovery khác nhau → chọn MỘT vendor cho sản phẩm (ADR).
- Code sinh từ IDL (rtiddsgen / fastddsgen / idlc): generator là tool phải validate; code sinh là configuration item, sinh lại
  trong build, không sửa tay (`gen/`, loại khỏi gate).

## QoS — chốt trong profile XML (configuration item trong `vsur-idl`), không đặt rải rác trong code
| Policy | Lựa chọn điển hình | Lưu ý an toàn |
|---|---|---|
| RELIABILITY | Luồng chu kỳ "mới nhất thắng" (teleop setpoint, trạng thái khớp): BEST_EFFORT; lệnh/sự kiện/chuyển trạng thái: RELIABLE | RELIABLE + backlog → lệnh cũ tới trễ |
| HISTORY | KEEP_LAST 1 cho state stream; KEEP_LAST n có giới hạn cho lệnh | Không KEEP_ALL trong đường RT |
| DURABILITY | VOLATILE cho stream; TRANSIENT_LOCAL cho trạng thái hệ thống/cấu hình (late joiner nhận giá trị cuối) | Late joiner không được hành động trên giá trị cũ mà không kiểm tuổi/epoch |
| DEADLINE | = chu kỳ × hệ số | Callback deadline missed → báo lỗi theo SDD |
| LIVELINESS | MANUAL_BY_TOPIC/PARTICIPANT, lease theo ngân sách phát hiện | AUTOMATIC chỉ chứng minh thread middleware còn sống, KHÔNG phát hiện app treo |
| LIFESPAN | ≤ max_age của dữ liệu | Middleware tự bỏ mẫu quá tuổi (vẫn phải kiểm ở app) |
| OWNERSHIP | EXCLUSIVE + strength khi có publisher dự phòng | Chuyển owner phải xác định |
| RESOURCE_LIMITS | max_samples/instances/samples_per_instance hữu hạn | Bộ nhớ bị chặn trên, cấp phát trước |
| DESTINATION_ORDER | BY_SOURCE_TIMESTAMP chỉ khi đồng hồ đã đồng bộ | Mặc định BY_RECEPTION |
| TRANSPORT_PRIORITY / DSCP, PARTITION, domain ID | Theo bảng mạng | Domain ID tách biệt từng hệ thống |
- Kiểm tra QoS thực tế lúc khởi động (đọc lại, so với profile) và xử lý `offered/requested_incompatible_qos` là lỗi — mismatch QoS
  làm im lặng mất liên lạc.

## Luồng thực thi
- Listener callback chạy trên thread middleware (priority không do dự án đặt): không xử lý nặng, không block, không gọi logic an toàn.
  Ưu tiên WaitSet trong thread của dự án (OSAL, priority chốt).
- Đường hard-RT (EtherCAT/CAN loop) KHÔNG gọi API DDS (có thể lock/cấp phát): bridge thread ↔ SPSC/triple buffer ↔ RT thread.
- Đọc mẫu: kiểm `SampleInfo.valid_data`, `instance_state` (NOT_ALIVE_DISPOSED / NO_WRITERS), rồi E2E (seq, tuổi, CRC, source).
- Zero-copy/shared memory (loan): vòng đời buffer theo API vendor, trả loan đúng hạn; chỉ khi ADR cho phép.

## Discovery & mạng
- Mạng điều khiển riêng (không chung mạng bệnh viện). Discovery: initial peers tĩnh / tắt multicast nếu chính sách mạng yêu cầu;
  thời gian discovery vào ngân sách khởi động. Giới hạn participant/endpoint (RESOURCE_LIMITS discovery).
- DDS Security (authentication, access control governance/permissions ký số, encryption) theo threat model (skill `medical-cybersecurity`);
  đo ảnh hưởng latency trước khi chốt.

## Chốt trong SDD / ADR
Vendor + phiên bản + license; generator; profile QoS từng topic; domain ID, partition; transport (UDPv4/SHM), interface NIC, MTU
(tránh phân mảnh cho dữ liệu RT); thread nhận (WaitSet/listener), priority/CPU; liveliness lease & deadline → phản ứng; lớp E2E;
hành vi late joiner; DDS Security bật cho topic nào.

## Hazard điển hình
Liveliness AUTOMATIC che app treo; backlog RELIABLE làm robot thực hiện lệnh cũ; writer RELIABLE block khi history đầy
(`max_blocking_time`) làm treo thread gửi; QoS mismatch → không có dữ liệu mà không ai báo; late joiner hành động trên trạng thái cũ;
type không tương thích sau khi đổi IDL; discovery storm/flood chiếm CPU; đồng hồ không sync làm sai BY_SOURCE_TIMESTAMP/stale check.

## Bằng chứng
Latency/jitter histogram dưới tải (CPU + mạng); kill/treo process publisher → đo thời gian phát hiện liveliness/deadline; restart
service (late joiner, epoch); QoS mismatch cố ý; tc netem mất/trễ/lặp/đảo gói; flood; type mismatch; fuzz payload ở tầng E2E.
