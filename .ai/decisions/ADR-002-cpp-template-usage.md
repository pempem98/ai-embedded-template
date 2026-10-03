# ADR-002 — Dùng C++ template trong SDK (`vsur-common`) và service
Status: Proposed
Date: 2026-10-03   Phạm vi: toàn dự án (code C++)   Người quyết định: Lead (đề xuất) — chờ người dùng chốt

## Bối cảnh
SDK dùng chung dự kiến viết nhiều dưới dạng template (container, Result, tiện ích giao tiếp). Template có ba hệ quả mà kit chưa xử lý:
(1) gate của service loại `external/` (`EXCLUDE_RX`) nên code sinh ra khi service instantiate template của SDK với kiểu mới không
được repo nào chấm; (2) coverage/phân tích tĩnh chỉ thấy member đã được instantiate — member chưa dùng trong test "vô hình" và
coverage 100% là giả; (3) thân template nằm trong header, trong khi header interface là `OWNER: lead` (worker không được sửa).

## Quyết định
1. Phạm vi dùng: template chỉ khi cần tổng quát theo **kiểu dữ liệu hoặc kích thước** (container, `Result<T>`, `SeqCounter<UInt>`,
   wrapper typed cho message). OSAL, HAL, log, safety API, state machine, logic điều khiển: class thường với interface cố định
   (ADR-001 #4 giữ nguyên — interface thuần ảo + fake/mock). Template mới trong SDK phải có lý do trong SDD.
2. Ràng buộc tham số (C++17): `static_assert` + `<type_traits>` ở đầu thân class/hàm, thông báo lỗi nói rõ điều kiện. Không
   SFINAE/`enable_if` để chọn overload, không template đệ quy, không template-template parameter, không variadic ngoài forwarding
   đơn giản, không CRTP — ngoại lệ ghi trong SDD và do Lead viết (`owner: lead`).
3. Tách file: `include/<module>/<name>.hpp` (`// OWNER: lead`: khai báo, contract Doxygen, `static_assert`, dòng cuối
   `#include "<name>_impl.hpp"`) + `include/<module>/<name>_impl.hpp` (thân; worker được sửa; code khác không include trực tiếp).
4. Verify tại repo định nghĩa template: file test chứa **explicit instantiation definition** cho từng instantiation đại diện
   (`template class vsur::SpscRing<TestPod, 8>;`) để mọi member được biên dịch và hiện trong coverage/phân tích tĩnh. Bộ đại
   diện phủ miền ràng buộc (N: nhỏ nhất, 2, lớn nhất dự kiến; T: nhỏ nhất/lớn nhất cho phép) và được liệt kê trong SDD.
5. Dùng ở repo khác:
   - Template **dữ liệu thuần** (chỉ sao chép/lưu T; `static_assert(std::is_trivially_copyable_v<T>)`): instantiate với kiểu
     thỏa ràng buộc không cần test lại template.
   - Template **nhận hành vi** (policy, traits, callable, toán tử/hàm thành viên của T): mỗi instantiation là một unit mới →
     test trong repo dùng nó, liệt kê ở task card (mục "Template").

## Hệ quả cho code / test
- Container và tiện ích của ADR-001 (`StaticVector`, `SpscRing`, `TripleBuffer`, `Result`, `SeqCounter`) theo #2–#4 khi viết
  ở task bootstrap `T000`; SDD-common-core liệt kê bộ instantiation đại diện.
- Worker không tự thêm tham số template, không tự tạo template mới ngoài task card; cần tổng quát hóa → HỎI.
- Review REJECT: tham số không ràng buộc; test thiếu explicit instantiation; instantiation nhận hành vi không có test;
  metaprogramming ngoài #2 không có trong SDD.
- Nơi ghi luật: `cpp-embedded-standard` (worker), `embedded-review`, `task-card`, `service-architecture`.

## Truy vết
Coding standard: docs/01-plan/coding-standard.md (Rev 0.2). IEC 62304 §5.5 (unit implementation & verification) — quy ước kỹ thuật,
không trực tiếp từ SRS/HAZ.
