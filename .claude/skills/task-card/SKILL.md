---
name: task-card
description: Cách viết task card giao cho Gemini worker hoặc cho chính Lead (owner lead), có safety class, platform, giao thức, truy vết. LUÔN dùng mỗi khi chia việc, lập kế hoạch, tạo file trong .ai/tasks/, hoặc chuẩn bị chạy scripts/delegate.sh / lead.sh — kể cả khi người dùng chỉ nói "giao cho Gemini", "chia task", "implement module X".
---
# Task card
Mẫu: `.ai/templates/task.md`; ví dụ đầy đủ: `.ai/templates/example-T01.md`. Lưu `.ai/tasks/<ID>.md`.

# Frontmatter (script kiểm tra và tự chọn skill Gemini)
| Field | Giá trị | Ghi chú |
|---|---|---|
| type | implement / fix / test / research / doc | |
| owner | gemini / lead | lead: code bạn tự viết (ISR, DMA, safety monitor, safe state, RT sync, startup...) → `lead.sh` |
| platform | host / mcu / linux / qnx | chọn build + skill nền tảng |
| safety_class | A / B / C | bắt buộc với task code; C → effort high, autofix 0 |
| software_item | SI-nnn | từ SAD |
| requirements | SRS-… | bắt buộc B/C; trace.py kiểm tra |
| risk_controls | RCM-… | nếu task implement biện pháp kiểm soát |
| detailed_design | docs/04-detailed-design/SDD-x.md | bắt buộc C, file phải có thật; được chèn vào prompt |
| anomaly | ANOM-nnn | với type: fix |
| protocols | can, canopen, ethercat, spi, i2c, uart, usb, ssi, biss-c, endat, ethernet, dds | chèn `comm-safety` + `proto-<x>` (canopen tự kèm can; ethercat/canopen tự kèm `sync-control-impl`); xem skill `comm-protocols` |
| decisions | ADR-nnn | file `.ai/decisions/ADR-nnn*.md` chèn nguyên văn vào prompt |
| change | CR-nnn | task thuộc thay đổi xuyên service (ADR-004); chỉ để truy vết, script không kiểm; commit thêm trailer `Change: CR-nnn` |
| level | unit / integration / hil | type test; xem skill `integration-test` |
| coverage_scope | file/thư mục | coverage tính trên phạm vi này; bắt buộc với type: test không sửa src |
| effort, skills, autofix_max | | skills chỉ cần thêm ngoài skill tự động: `linux-service-impl` (main/lifecycle/skeleton service), `sync-control-impl` (timestamp, stale, rate transition — khi không có ethercat/canopen) |

# Nguyên tắc
1. Một task = một unit/mục tiêu, diff < ~300 dòng.
2. Viết & commit interface `.h/.hpp` (`// OWNER: lead`) TRƯỚC khi delegate (worktree tạo từ HEAD; script cảnh báo nếu repo còn thay đổi).
3. "Quyết định đã chốt" trả lời trước mọi câu Gemini sẽ hỏi: kiểu, đơn vị, hằng số, giới hạn, timeout,
   xử lý lỗi & safe state, context (ISR/thread/priority), bộ nhớ, API OS được dùng; giao tiếp: khung, CRC đầy đủ tham số, counter, timeout, ngưỡng lỗi.
   Quyết định dùng lại nhiều task → ADR + tham chiếu `decisions:` thay vì chép lại.
   Cấu trúc: ai tạo đối tượng, phụ thuộc nào inject qua constructor, callback hay hàng đợi (worker theo `design-clean-code`,
   không tự chọn pattern).
   Task viết hoặc dùng template (ADR-002): mục "Template" liệt kê ràng buộc tham số và từng instantiation phải test; header
   khai báo `<name>.hpp` do bạn viết trước, worker chỉ được `- tạo:`/`- sửa:` file `<name>_impl.hpp`.
4. "Files được phép" chính xác — `check_scope.py` THỰC THI: chỉ dòng `- tạo:` / `- sửa:` / `- xóa:` được tính; glob và thư mục `/` được phép.
   Gemini không bao giờ được chạm scripts/, .ai/, .agents/, .gemini/, .claude/, cmake/, CMakeLists.txt gốc (kể cả khi liệt kê).
   Research/doc: liệt kê file ghi chú/tài liệu được tạo (vd. `- tạo: .ai/notes/T05-biss-encoder.md`).
5. Tiêu chí chấp nhận kiểm chứng được; Class C nêu thêm tiêu chí §5.5.4 liên quan (fault handling, boundary, init, resource...).
6. Không giao Gemini: safety supervisor core, state machine safe state, ISR/DMA, đồng bộ RT, cấu hình scheduler/partition,
   linker/startup/bootloader → task `owner: lead`.
7. Task phụ thuộc → merge task trước rồi mới delegate task sau; task độc lập chạy song song (Bash background).
   Task song song đã merge làm `INTEGRATION_BRANCH` tiến → merge.sh chạy gate trên kết quả merge; FAIL → cập nhật nhánh task, review lại.
8. Service mới (polyrepo): mẫu `.ai/templates/bootstrap-service.md`; kiến trúc theo skill `service-architecture`,
   timing/đồng bộ theo `distributed-sync-control` — chốt miền đồng hồ, max_age, chu kỳ/pha, QoS DDS trong "Quyết định đã chốt".
