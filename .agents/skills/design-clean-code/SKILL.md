---
name: design-clean-code
description: Design pattern được phép/cấm và kỹ thuật clean code cho code C/C++ nhúng an toàn (singleton, factory, observer, state, strategy, DI...; cấu trúc hàm/class, comment, trùng lặp, phạm vi refactor). Tự động áp dụng cho mọi task code.
---
<!-- Phân vai skill: cpp-/c-embedded-standard = luật ngôn ngữ · naming-conventions = đặt tên · safety-coding = phòng vệ B/C ·
     design-clean-code = cấu trúc & pattern. Pattern nào dùng ở đâu do Lead chốt trong SDD/task card — bạn không tự chọn. -->
# Nguyên tắc
- Cấu trúc (class nào, interface nào, ai tạo, ai gọi ai) lấy từ SDD/task card/header của Lead. KHÔNG tự thêm lớp trừu tượng,
  interface, pattern, điểm mở rộng "để sau này dùng". Thấy cần → HỎI.
- Mọi phụ thuộc phải nhìn thấy được ở constructor/tham số hàm; mọi đối tượng có vòng đời tĩnh, tạo ở pha init.

# Design pattern (C++ — Linux/QNX/host)
| Pattern | Quy định |
|---|---|
| Singleton / service locator / biến toàn cục | **Cấm** (kể cả `static T& instance()`): phụ thuộc ẩn, không thay được bằng fake, thứ tự khởi tạo tĩnh không xác định, khóa ẩn khi khởi tạo lần đầu trên đường RT. Thay bằng: tạo một lần ở composition root (`main`/init) rồi truyền tham chiếu. API toàn cục duy nhất được dùng là của Lead: `log::event`, `safety::report_fault`, `MonotonicClock::now` |
| Dependency injection | **Mặc định**: nhận interface thuần ảo qua tham chiếu ở constructor, lưu `T&`. Không setter đổi phụ thuộc sau init |
| Factory | Chỉ ở pha init, trả đối tượng theo giá trị hoặc đặt vào vùng nhớ tĩnh/pool của dự án (Class C: không `new`). Việc có thể lỗi → hàm tạo trả `Result<T>`/`init()` trả `Status`, không để trong constructor. Không chọn kiểu từ dữ liệu ngoài chưa kiểm tra |
| Observer / callback | Danh sách subscriber dung lượng cố định (`std::array`/`StaticVector`), đăng ký chỉ ở init, không hủy đăng ký lúc chạy, gọi theo thứ tự đăng ký. Callback = tham chiếu interface hoặc con trỏ hàm + context (Class C: không `std::function`). Callback `noexcept`, có cận thời gian, không block, không đăng ký/notify lồng. Khác thread → KHÔNG gọi callback, chuyển dữ liệu qua `SpscRing`/`TripleBuffer` |
| State | `enum class` + `switch` đủ case (safety-coding #5) hoặc bảng chuyển `constexpr`. Không dùng đối tượng state đa hình cấp phát động. State machine safe state do Lead viết |
| Strategy | Interface thuần ảo, chọn một lần ở init qua constructor; đổi lúc chạy chỉ khi SDD cho phép. Dạng tham số template → ADR-002 (hỏi) |
| Adapter (ports & adapters) | Logic không include header OS/vendor/phần cứng; chỉ gọi qua interface HAL/OSAL. Adapter mỏng, không chứa logic nghiệp vụ |
| Command / message | Struct dữ liệu kích thước cố định qua hàng đợi; không đối tượng lệnh đa hình có `execute()` ảo |
| RAII / scoped guard | Dùng cho mọi tài nguyên (lock, fd); guard không copy được |
| Kế thừa / template method | Chỉ kế thừa interface thuần ảo; tái sử dụng code bằng composition |
| Pimpl, builder, visitor, decorator, proxy, mediator, chain of responsibility, object pool | Không dùng khi SDD/task card không nêu (Pimpl cần heap; pool chỉ dùng pool của dự án) |

# Design pattern (C — MCU)
- Module = file `.c` với trạng thái `static` (`s_`) hoặc struct context truyền qua con trỏ + `<module>_init()`; không biến `extern` thay đổi được.
- Callback: con trỏ hàm + `void* ctx`, đăng ký ở init, bảng `const` khi có thể; kiểm NULL trước khi gọi; không gọi callback từ ISR nếu task card không nêu.
- State machine: `enum` + `switch` đủ case hoặc bảng `const`; đa hình bằng bảng con trỏ hàm `const` chỉ khi task card nêu.

# Clean code
- Hàm: một nhiệm vụ, một mức trừu tượng; kiểm lỗi/điều kiện trước rồi trả về sớm, đường chính không lồng sâu. Hàm hoặc thay đổi
  trạng thái hoặc trả thông tin, không cả hai (trừ `Status`/`Result`).
- Tham số: ≤ 5; nhiều hơn → gom vào struct. Không tham số `bool` điều khiển hành vi (dùng `enum class` hoặc tách hàm). Đầu vào
  `const&`/giá trị, đầu ra qua giá trị trả về (dữ liệu lớn: `T& out` + `Status` theo project-conventions).
- Hằng số: không magic number — `constexpr` có tên và hậu tố đơn vị, ghi nguồn (mục SDD/spec). Ngoại lệ: 0, 1, chỉ số hiển nhiên.
- Biến: `const` mặc định, khai báo sát nơi dùng, khởi tạo ngay, phạm vi hẹp nhất.
- Class: một trách nhiệm; dữ liệu `private`; bất biến đúng ngay sau init; không getter/setter cho mọi field; method không đổi
  trạng thái là `const`; class giữ tài nguyên `= delete` copy tường minh. Không chuỗi gọi `a.b().c().d()`.
- Điều kiện: biểu thức phức tạp đặt tên bằng biến/hàm `is_`/`has_`; không toán tử ba ngôi lồng; không tên phủ định (`is_not_ready`).
- Trùng lặp: gom trong phạm vi module của task. Code dùng chung giữa module/service thuộc `vsur-common` → HỎI, không tự tạo file `utils`.
- Comment: giải thích **vì sao**, ràng buộc, đơn vị, nguồn (mục spec/SDD); không lặp lại code. Không để code bị comment, `#if 0`,
  TODO/FIXME — việc chưa xong ghi vào report. Không code chết, tham số/include/hàm không dùng.
- Phụ thuộc: header include tối thiểu, forward declaration khi đủ; không phụ thuộc vòng giữa module; logic → interface ← adapter.
- Test cũng sạch: Arrange–Act–Assert, một hành vi mỗi test, dựng dữ liệu bằng helper trong `test/fakes/`.
- **Không dọn dẹp ngoài phạm vi**: không refactor/đổi tên/format code ngoài "Files được phép" hoặc không liên quan mục tiêu task
  (thay đổi không kiểm soát với thiết bị y tế). Thấy code xấu → ghi đề xuất trong report.
- Nhất quán với code xung quanh hơn sở thích cá nhân.
