# ADR-001 — Baseline quy ước dự án (namespace, lỗi, OSAL/HAL, logging, bộ nhớ, thời gian, giao tiếp, test)
Status: Accepted
Date: 2026-10-03   Phạm vi: toàn dự án   Người quyết định: Lead (đề xuất) — người dùng chốt 2026-10-03

## Bối cảnh
Trước pilot, các mục TBD trong `project-conventions` làm Gemini BLOCKED lặp lại ở mọi task. Cần một baseline chung, nhất quán
với coding standard (cpp-/c-embedded-standard, naming-conventions, safety-coding) và banned-check.

## Quyết định
1. C++17 / C11; namespace `vsur::<module>`; tiền tố macro `VSUR_`.
2. Một `enum class vsur::Error : std::uint16_t` toàn dự án; `vsur::Result<T>` / `vsur::Status` `[[nodiscard]]`, không exception; `VSUR_ASSERT` → `fatal_error()`.
3. Thời gian: `std::chrono` (`vsur::Microseconds`, clock monotonic của OSAL); đại lượng vật lý: SI + hậu tố đơn vị, không thư viện đơn vị bên thứ ba.
4. OSAL (`Thread`, `Mutex` PI, `MonotonicClock`, `sleep_until`, `PeriodicTimer`) và HAL interface thuần ảo + fake/mock (ports & adapters).
5. Logging RT bằng `log::event(EventId, arg0, arg1)` vào ring buffer; báo lỗi an toàn bằng `safety::report_fault(FaultId, detail)`.
6. Không heap sau init; container `StaticVector`, `SpscRing`, `TripleBuffer`, `ByteSpan`.
7. Tiện ích `byte_order`, `crc` (tham số đầy đủ + preset), `sequence` (modulo).
8. Test: GoogleTest/GoogleMock (C++), Unity (C); FakeClock; cấu trúc thư mục cố định.
Chi tiết API: `.gemini/skills/project-conventions/SKILL.md`.

## Hệ quả cho code / test
- Các header trong `include/common`, `include/osal`, `include/hal`, `include/log`, `include/safety` là OWNER: lead, tạo trong task
  bootstrap `T000` (mẫu `.ai/templates/bootstrap-T000.md`) trước khi giao task Gemini dùng chúng. Thư viện common được dùng bởi
  item Class C → coi là Class C (cần SDD-common-core).
- GoogleTest/GoogleMock/Unity là công cụ phát triển (không vào sản phẩm) → ghi danh sách tool/phiên bản; std library của toolchain là SOUP.
- Lớp E2E cho message an toàn chưa chốt: quyết định theo từng interface trong SDD/ADR sau.

## Truy vết
Coding standard: docs/01-plan/coding-standard.md. Không trực tiếp từ SRS/HAZ (quy ước kỹ thuật).
