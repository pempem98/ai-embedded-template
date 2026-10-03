---
name: project-conventions
description: Quy ước chung của dự án (namespace, kiểu lỗi/Result, OSAL/HAL, logger & báo lỗi an toàn, bộ nhớ & container, đơn vị & thời gian, tiện ích giao tiếp, test). Luôn áp dụng cho task code. Lead sở hữu & cập nhật; nguồn: ADR-001.
---
<!-- OWNER: lead — Gemini KHÔNG sửa. Header nêu dưới đây do Lead viết (task bootstrap T000, OWNER: lead).
     Header cần dùng mà chưa tồn tại trong worktree, hoặc mục còn TBD mà task cần → HỎI (BLOCKED), không tự tạo/tự chọn. -->
# Ngôn ngữ & namespace
- C++17 (host/Linux/QNX), C11 (MCU). Mọi code C++: `namespace vsur::<module>`; không code ở global namespace.
- Macro & include guard: tiền tố `VSUR_` (`VSUR_<MODULE>_<FILE>_HPP_`). Đặt tên còn lại: skill `naming-conventions`.

# Kiểu lỗi & kết quả — `include/common/error.hpp`, `include/common/result.hpp`
- `enum class vsur::Error : std::uint16_t` — MỘT enum cho cả dự án: `InvalidArgument, OutOfRange, InvalidInput, InvalidState,
  NotReady, Busy, Timeout, CrcMismatch, SequenceError, StaleData, LengthError, HardwareFault, ResourceExhausted, NotSupported`.
  Thêm mã mới = Lead sửa header (hỏi, không tự thêm).
- Hàm có thể lỗi trả `vsur::Result<T>` (giá trị hoặc `Error`) hoặc `vsur::Status` (= không có giá trị). Cả hai `[[nodiscard]]`.
  Tạo: `Result<T>::ok(v)`, `Result<T>::fail(Error::Timeout)`, `Status::ok()`, `Status::fail(e)`.
  Dùng: `if (!r.has_value()) { return Status::fail(r.error()); }` rồi `r.value()` (precondition: has_value — vi phạm là lỗi lập trình).
- Dữ liệu lớn đầu ra: tham số tham chiếu `T& out` + trả `Status`. Không dùng exception, không mã lỗi int/bool.
- `VSUR_ASSERT(cond)` (`include/common/assert.hpp`): chỉ cho bất biến lập trình; vi phạm → `vsur::fatal_error()` (safe state do Lead
  định nghĩa theo nền tảng). Không dùng `assert()` chuẩn, không dùng ASSERT thay xử lý lỗi runtime.

# Thời gian & đơn vị — `include/common/time.hpp`
- Thời gian: `std::chrono` với `vsur::Microseconds = std::chrono::duration<std::int64_t, std::micro>`,
  `vsur::TimePoint` = mốc của clock monotonic dự án (`vsur::osal::MonotonicClock`). Không dùng `uint64_t` trần cho thời gian, không `CLOCK_REALTIME`.
- Đại lượng vật lý: SI cơ bản (m, rad, s, N, N·m, A, V) + hậu tố đơn vị trong tên (naming-conventions). Không dùng thư viện đơn vị bên thứ ba.
- Số thực: `double` trên Linux/QNX; `float` trên MCU (theo FPU). Hằng vật lý & giới hạn là `constexpr` có đơn vị trong tên.

# OSAL — `include/osal/` (impl: `src/osal/<linux|qnx|host>/`)
- `vsur::osal::Thread` + `ThreadConfig{name, policy (Fifo|Other), priority, cpu_affinity, stack_size_bytes}` — không `std::thread`.
- `vsur::osal::Mutex` (luôn priority inheritance) + `ScopedLock`; thứ tự khóa ghi trong SDD.
- `vsur::osal::MonotonicClock::now()`, `vsur::osal::sleep_until(TimePoint)` (tuyệt đối), `PeriodicTimer{period}` có đếm overrun.
- Host test: `test/fakes/fake_clock.hpp` (`vsur::testing::FakeClock` điều khiển thời gian), không sleep thật.

# HAL — `include/hal/<thiết bị>.hpp` (interface thuần ảo), impl `src/hal/<platform>/`, fake `test/fakes/`
- Ví dụ: `vsur::hal::SpiBus`, `I2cBus`, `UartPort`, `CanBus`, `Gpio`, `Watchdog`. Mỗi hàm trả `Status`/`Result<T>`, có timeout.
- Code logic nhận HAL qua tham chiếu interface (ports & adapters) → unit test với `Fake<Interface>` / `Mock<Interface>` (GoogleMock).

# Logging & báo lỗi an toàn — `include/log/`, `include/safety/fault.hpp`
- RT path: `vsur::log::event(EventId id, std::uint32_t arg0 = 0, std::uint32_t arg1 = 0) noexcept` — ghi ring buffer lock-free,
  không chuỗi, không cấp phát. `EventId` là enum trong `include/log/event_id.hpp` (Lead cấp mã).
- Non-RT: `vsur::log::text(Level, const char* msg) noexcept` — chỉ ở thread non-RT.
- Báo lỗi lên safety supervisor: `vsur::safety::report_fault(FaultId, std::uint32_t detail) noexcept` (không chặn).
  Ánh xạ lỗi → FaultId và phản ứng: theo SDD/task card, không tự chọn.

# Bộ nhớ & container — `include/common/`
- Cấp phát chỉ trong pha init (trước khi vào RT/Operational). Class B/C runtime: không heap.
- Container: `std::array`, `vsur::StaticVector<T, N>` (`static_vector.hpp`), `vsur::SpscRing<T, N>` (`spsc_ring.hpp`, RT ↔ non-RT),
  `vsur::TripleBuffer<T>` (`triple_buffer.hpp`). Không `std::vector/string/map/function/shared_ptr` trong code Class C.
- Bộ đệm byte: `vsur::ByteSpan` / `vsur::ConstByteSpan` (`span.hpp`: con trỏ + độ dài, kiểm biên) — không truyền cặp pointer/len rời.

# Tiện ích giao tiếp — `include/common/`
- Endianness (`byte_order.hpp`): `vsur::read_u16_le(ConstByteSpan, std::size_t offset) -> Result<std::uint16_t>` và họ
  `read/write_{u8,u16,u32,u64,i16,i32}_{le,be}` — kiểm độ dài bên trong.
- CRC (`crc.hpp`): `vsur::crc::compute(const CrcParams&, ConstByteSpan) -> std::uint32_t`; `CrcParams{width, poly, init, refin,
  refout, xorout, check}`; preset dùng chung đặt tên `kCrc<Tên chuẩn>` (vd. `kCrc16Modbus`) — preset mới do Lead thêm. Test bằng `check`.
- Sequence counter (`sequence.hpp`): `vsur::SeqCounter<UInt>`; `vsur::seq_delta(prev, cur)` số học modulo; không so sánh `<` trực tiếp.
- Lớp E2E cho message an toàn: TBD — định nghĩa theo từng interface trong SDD/ADR (header, CRC preset, timeout). Chưa có → HỎI.

# Test
- C++: GoogleTest + GoogleMock. C (MCU): Unity. Không đổi framework.
- Thư mục: `test/<module>/test_<file>.cpp`, fake/mock dùng chung ở `test/fakes/`, test tích hợp `test/integration/<chủ đề>/`.
- Mỗi test độc lập; dùng FakeClock thay sleep; không truy cập phần cứng/OS thật.

# Quyết định chung đã chốt (1 dòng/ADR từ .ai/decisions/)
- ADR-001 — Baseline quy ước dự án (toàn bộ nội dung skill này).
- ADR-002 — Template C++: chỉ tổng quát theo kiểu/kích thước, ràng buộc bằng `static_assert`, thân ở `<name>_impl.hpp`,
  test có explicit instantiation (chi tiết: skill `cpp-embedded-standard`).
