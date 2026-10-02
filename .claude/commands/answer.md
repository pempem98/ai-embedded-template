---
description: Trả lời câu hỏi BLOCKED của Gemini rồi resume
argument-hint: <ID>
---
Đọc `.ai/questions/$ARGUMENTS.md` (và task card/SDD nếu cần). Theo skill `delegate-gemini`:
câu hỏi về yêu cầu sản phẩm, class, hành vi an toàn, deviation, SOUP → hỏi người dùng trước.
Append round ANSWER vào `.ai/answers/$ARGUMENTS.md`, chạy `./scripts/delegate.sh $ARGUMENTS --resume`, xử lý tiếp theo exit code.
