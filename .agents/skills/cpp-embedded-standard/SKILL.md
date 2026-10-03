---
name: cpp-embedded-standard
description: Chuẩn ngôn ngữ C++ nhúng an toàn cho thiết bị y tế (tham chiếu MISRA C++:2023, AUTOSAR C++14, CERT C++) — cặp với c-embedded-standard. Áp dụng cho mọi code C++ trên host/Linux/QNX. Đặt tên: skill naming-conventions.
---
<!-- Phân vai skill: cpp-/c-embedded-standard = luật ngôn ngữ · naming-conventions = đặt tên/định dạng/commit · safety-coding = lập trình phòng vệ Class B/C -->
# Định dạng
- `.clang-format` của dự án là chuẩn duy nhất (format.sh hook tự chạy cho Claude; worker chạy `clang-format -i` trên file mình sửa).
- `.clang-tidy` (gate) kiểm tra cả quy tắc ngôn ngữ và đặt tên — không NOLINT.

# Ngôn ngữ
- C++17 (trừ khi task card nói khác). `-Wall -Wextra -Wpedantic -Wconversion -Wshadow -Werror`.
- Không exception (`-fno-exceptions` trong code safety), không RTTI ở Class C. Lỗi trả về qua
  `enum class Error` / kiểu `Result<T, Error>` của dự án — KHÔNG bỏ qua giá trị trả về (`[[nodiscard]]`).
- Không cấp phát động sau khởi tạo trong luồng real-time / Class C: dùng `std::array`, pool tĩnh,
  container cố định dung lượng của dự án. Cấp phát lúc init chỉ khi task card cho phép.
- RAII cho mọi tài nguyên (fd, mutex, mapping). Không con trỏ thô sở hữu; `std::unique_ptr` chỉ ở init.
- `noexcept` cho hàm trong đường RT. `constexpr` / `static_assert` cho cấu hình và giả định kích thước.
- Kiểu cố định độ rộng `<cstdint>`; không chuyển đổi ngầm thu hẹp; `static_cast` tường minh;
  cấm `reinterpret_cast` (trừ lớp HAL có deviation), cấm C-style cast.
- `enum class`, không `#define` hằng số; không macro hàm (dùng `constexpr`/inline).
- Không `goto`, không recursion, không đa kế thừa ngoài interface thuần ảo, destructor base `virtual` hoặc `protected`.
- Đơn vị vật lý rõ ràng: strong type của dự án hoặc hậu tố đơn vị chữ thường theo `naming-conventions` (`pos_rad`, `vel_rad_s`, `force_n`, `t_us`).
- Include: header tự đủ (self-contained), thứ tự: header tương ứng → project → thư viện → chuẩn; không `using namespace` trong header.
- Số thực: không so sánh `==`; kiểm tra NaN/Inf ở đầu vào; giới hạn miền giá trị trước khi tính.
- Concurrency: `std::atomic` với memory order tường minh; không data race; lock theo thứ tự cố định;
  không `std::thread` trực tiếp — dùng lớp OSAL của dự án (đặt policy/priority/affinity).
- Template (ADR-002): chỉ để tổng quát theo kiểu dữ liệu/kích thước và chỉ khi task card yêu cầu — không tự tạo template,
  không tự thêm tham số template. Ràng buộc mọi tham số bằng `static_assert` + `<type_traits>` có thông báo rõ.
  Không SFINAE/`enable_if`, template đệ quy, template-template parameter, variadic, CRTP (cần → HỎI).
  Thân template viết ở `<name>_impl.hpp` (được include ở cuối `<name>.hpp` của Lead); code khác không include `_impl.hpp`.
  Test: explicit instantiation definition cho từng instantiation task card liệt kê (`template class vsur::SpscRing<TestPod, 8>;`)
  rồi test đủ mọi member trên từng instantiation đó.
- Hàm ≤ ~60 dòng, cyclomatic ≤ 10, độ sâu lồng ≤ 3. Một hàm một nhiệm vụ.
- Doxygen cho API public: `@brief`, `@param`, `@return`, `@pre`, `@post`, tag truy vết.
