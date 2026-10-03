# CR-<nnn> — <tiêu đề ngắn>
<!-- Lưu ở vsur-system: docs/12-change-requests/CR-nnn-<tieu-de-kebab>.md (ADR-004). Chỉ dùng cho thay đổi chạm ≥ 2 repo
     hoặc đổi interface dùng chung. AI soạn nháp; các trường APPROVED_BY / CLOSED_BY do con người điền. -->
| Trường | Giá trị |
|---|---|
| Trạng thái | Draft / Approved / In progress / Closed / Rejected |
| Ngày lập | <YYYY-MM-DD> |
| Người khởi xướng | <tên — repo> |
| Nguồn | <SYS-… / HAZ-… / ANOM-… / yêu cầu mới> |
| APPROVED_BY | <!-- con người điền: tên, ngày --> |
| CLOSED_BY | <!-- con người điền: tên, ngày --> |

## 1. Mô tả & lý do
<thay đổi gì, vì sao, hệ quả nếu không làm>

## 2. Ảnh hưởng an toàn
<HAZ/RCM liên quan; có tạo chuỗi nguy hiểm mới hoặc ảnh hưởng risk control hiện có không; class của các SI bị chạm>

## 3. Thay đổi interface
| Repo | Hiện tại (tag) | Đích (tag) | Loại | Nội dung |
|---|---|---|---|---|
| vsur-idl | vX.Y.Z | vX.Y.Z | bổ sung / phá vỡ tương thích | <topic, kiểu, QoS> |
| vsur-common | | | | |

Tổ hợp phiên bản không được chạy chung (nếu phá vỡ tương thích): <...>

## 4. Repo bị ảnh hưởng & task
| Thứ tự | Repo | Người phụ trách | Việc cần làm | Task (`<repo>:<ID>`) | Tag phát hành | Trạng thái |
|---|---|---|---|---|---|---|
| 1 | vsur-idl | | | | | |
| 2 | comm-service | | | | | |
| 2 | kinematics-service | | | | | |
| 3 | teleop-service | | | | | |

Cùng số thứ tự = làm song song được. Mỗi người phụ trách tự chạy `/impact` và tự tạo task trong repo của mình.

## 5. Kiểm tra tích hợp
- Manifest: <phiên bản từng service + vsur-common + vsur-idl>
- Test tích hợp/HIL cần chạy: <ID test spec>
- Kết quả: <link bằng chứng>

## 6. Điều kiện đóng
- [ ] Mọi task ở mục 4 đã merge và có tag
- [ ] Ma trận tương thích và manifest ở `vsur-system` đã cập nhật
- [ ] Test tích hợp trên manifest có kết quả
- [ ] `/trace` tổng hợp không có GAP mới
- [ ] ANOM phát sinh đã ghi nhận
