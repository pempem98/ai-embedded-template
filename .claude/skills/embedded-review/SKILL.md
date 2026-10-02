---
name: embedded-review
description: Rubric review khó tính cho code C/C++ nhúng (MCU, Linux RT, QNX) của thiết bị y tế do Gemini hoặc Lead viết, và cách ghi hồ sơ review. Dùng mỗi khi review diff, đọc .ai/reports/, quyết định APPROVE/REJECT.
---
# Thứ tự (dừng sớm khi đủ lý do REJECT)
1. Report: STATUS, "Lệch khỏi task card" — lệch không được phép → REJECT.
2. Scope/gate/trace phải PASS (exit 0). Scope FAIL → REJECT. Gate FAIL → REJECT kèm chỉ đạo, trừ khi lỗi do header/thiết kế của bạn.
3. `git -C ../wt-<ID> diff --stat refs/ai/base/<ID> HEAD`; lịch sử round: `git -C ../wt-<ID> log --oneline refs/ai/base/<ID>..HEAD`.
4. Đọc diff từng file quan trọng: `git -C ../wt-<ID> diff refs/ai/base/<ID> HEAD -- <file>`; đối chiếu SDD/task card, không đọc cả file.

# REJECT ngay
- Data race / thiếu atomic-volatile / lock sai thứ tự / mutex không PI trong đường RT
- Đường RT: cấp phát, I/O, syscall block, sleep tương đối, logging đồng bộ
- Class B/C: cấp phát động, exception, RTTI(C), recursion, goto; lỗi bị bỏ qua (`[[nodiscard]]` bị lờ)
- UB: shift, overflow, out-of-bounds, alignment, aliasing, lifetime, so sánh float ==
- Thiếu kiểm tra đầu vào/NaN/stale, vòng chờ không timeout, state machine thiếu case, hành vi lỗi tự chế không theo SDD
- QNX: message không reply, blocking không timeout, InterruptAttach không được phép
- Giao tiếp (task có `protocols:`): theo mục Review của skill `comm-protocols`
- Đổi interface của lead, tắt warning, NOLINT/pragma/cast bịt lỗi, xóa/skip test, test có expected lấy từ output code
- Tag truy vết sai/thiếu/gắn cho có; ID không có trong task card; `@req` chỉ ở header OWNER: lead
- Đặt tên/cấu trúc sai skill Gemini `naming-conventions`: ngoài `vsur::<module>`, include guard/macro thiếu `VSUR_`,
  tên file ≠ class, thiếu hậu tố đơn vị, viết tắt ngoài danh sách (clang-tidy chỉ bắt được một phần)

# Effort high / Class C thêm
WCET & bounded loops, stack, priority inversion, init order, wrap-around tick, endianness/packed struct,
memory barrier với DMA/cache, đường lỗi đưa về đúng safe state, tiêu chí §5.5.4.

# Hồ sơ `.ai/reviews/<ID>.md` (template `.ai/templates/review.md`) — bắt buộc trước merge
AI_VERDICT, BASE_SHA, REVIEWED_SHA (= HEAD worktree lúc review), reviewer (subagent + model, cross-review), mục đã kiểm,
issues & cách xử lý (kể cả Xn bị bác + lý do), gate/scope/trace. Để nguyên placeholder HUMAN_* cho kỹ sư.
