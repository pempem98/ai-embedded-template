# ADR-004 — Luồng change request (CR) cho thay đổi xuyên service
Status: Accepted
Date: 2026-10-03   Phạm vi: toàn dự án (polyrepo, nhiều người phụ trách service)   Người quyết định: Lead (đề xuất) — người dùng chốt 2026-10-03

## Bối cảnh
Mỗi service là một repo có người phụ trách riêng và bộ kit AI riêng. Một thay đổi ở teleop-service có thể cần đổi cả
comm-service và kinematics-service. Kit hiện chỉ điều phối trong một repo: task card không có tham chiếu xuyên repo và không có
nơi ghi một thay đổi hệ thống đã rải ra những task nào. Điều phối tự động xuyên repo (AI của repo này giao task vào repo khác)
bị loại vì phá ranh giới trách nhiệm: phân loại, review và chữ ký của một software item thuộc người phụ trách item đó.

## Quyết định
1. **Ranh giới**: AI và người phụ trách của một repo không viết task card, không delegate, không sửa code ở repo khác.
   Thứ duy nhất đi qua ranh giới là interface (`vsur-idl`, `vsur-common`) và bản ghi CR.
2. **Bản ghi CR** ở `vsur-system`: `docs/12-change-requests/CR-nnn-<tieu-de-kebab>.md` theo mẫu
   `docs/templates/change-request-template.md`. Chỉ lập khi thay đổi chạm từ hai repo trở lên hoặc đổi interface dùng chung.
3. **Luồng**:
   1. Người khởi xướng chạy `/impact` ở repo mình → danh sách repo bị ảnh hưởng và thay đổi interface cần có.
   2. Lập CR: lý do, nguồn (SYS/HAZ/ANOM), repo bị ảnh hưởng, người phụ trách từng repo, tag interface đích, thứ tự. Người có
      thẩm quyền phê duyệt CR (không phải AI).
   3. Đổi interface trước: task ở `vsur-idl`/`vsur-common`, người phụ trách mọi service consumer cùng review, merge, đánh tag.
   4. Mỗi người phụ trách tự chạy `/impact` và tự tạo task trong repo mình, qua đủ gate → review → ký → merge của repo đó.
   5. `vsur-system`: cập nhật ma trận tương thích và manifest, `/integrate` trên đúng manifest, `/trace` tổng hợp, đóng CR.
4. **Truy vết**: task card thuộc CR có dòng frontmatter `change: CR-nnn`; commit có trailer `Change: CR-nnn`. CR liệt kê task theo
   dạng `<repo>:<ID>` kèm tag phát hành chứa nó. Đây là bằng chứng kiểm soát thay đổi, không phải cơ chế chặn.
5. **Không khóa chéo bằng script**: phụ thuộc giữa các repo thể hiện bằng **tag** của `vsur-idl`/`vsur-common`. Service làm việc
   trên tag mới với fake cho phía đối diện; hash interface mà ssm-service kiểm lúc chạy bắt service chưa nâng phiên bản.
6. **Tương thích**: ưu tiên thay đổi interface kiểu bổ sung. Thay đổi phá vỡ tương thích phải ghi trong CR các tổ hợp phiên bản
   không được chạy chung và đưa vào ma trận tương thích.
7. **Đóng CR**: mọi task đã merge và có tag; test tích hợp trên manifest đã có kết quả; ANOM phát sinh đã ghi. Người phụ trách
   hệ thống đóng CR.

## Hệ quả cho code / test
- Thêm ID `CR-nnn` vào `naming-conventions`; trailer `Change:` vào quy ước commit (hook `commit-msg` không bắt buộc).
- `delegate.sh` bỏ qua trường `change:` (không ảnh hưởng gate); `status.sh` không tổng hợp xuyên repo.
- Nơi ghi luật: skill `service-architecture` (luồng 5 bước), `task-card` (trường `change:`), mẫu `task.md`, `/impact`
  (đầu ra có mục "repo khác bị ảnh hưởng → đề xuất CR").
- Thay đổi chỉ trong một repo vẫn theo luồng hiện tại (`/impact` → task), không cần CR.

## Truy vết
IEC 62304 §6.2 (triển khai thay đổi), §8.2 (kiểm soát thay đổi). Skill `service-architecture` (đổi interface = task ở `vsur-idl` +
task ở mọi consumer), `problem-resolution` (CR sinh từ ANOM).
