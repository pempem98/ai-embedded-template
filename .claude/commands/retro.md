---
description: Rút kinh nghiệm từ review & số liệu → đề xuất cải tiến skill, task card, effort routing
argument-hint: [số task gần nhất, mặc định 20]
---
Skill `effort-routing`, `embedded-review`.
1. `.ai/metrics.csv`: theo type/platform/class/effort/protocols — tỷ lệ BLOCKED, exit 3, số REWORK, thời gian. Đọc bằng grep/awk, không mở cả file lớn.
2. Bảng "Issues & xử lý" trong `docs/07-verification/records/*/review.md` (grep `^|`) và các file `answers.md`:
   nhóm lỗi lặp lại, câu hỏi lặp lại.
3. Đề xuất (dạng diff ngắn, KHÔNG tự áp dụng):
   - câu hỏi lặp → ADR + dòng trong `.agents/skills/project-conventions`;
   - lỗi lặp → luật mới cho skill Gemini liên quan hoặc rubric `embedded-review`;
   - loại task low hay fail → nâng effort trong `effort-routing`;
   - pattern cấm mới → `scripts/check_banned.py`.
4. Người dùng duyệt từng đề xuất. Thay đổi skill/gate = thay đổi công cụ → ghi vào docs/01-plan (đánh giá tái validate).
