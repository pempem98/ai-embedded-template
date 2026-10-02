---
name: delegate-gemini
description: Giao thức điều khiển Gemini worker và luồng code của Lead — delegate, lead.sh, exit code, trả lời BLOCKED, REWORK, cross-review, review record, merge có chữ ký kỹ sư, abort. Dùng bất cứ khi nào chạy scripts/delegate.sh, lead.sh, cross-review.sh, merge.sh, đọc .ai/questions/ hoặc .ai/reports/, hoặc Gemini báo lỗi build.
---
`./scripts/delegate.sh <ID> [--resume] [--effort low|high]` — mỗi round được commit trong `../wt-<ID>` (author ai-worker);
base của task ở `refs/ai/base/<ID>`. Xem diff: `git -C ../wt-<ID> diff refs/ai/base/<ID> HEAD -- <file>`.

| Exit | Ý nghĩa | Việc của bạn |
|---|---|---|
| 0 | DONE, scope + gate + trace PASS | /review |
| 1 | task card không hợp lệ / skill-ADR không tồn tại / vượt MAX_REWORK | sửa task card, hoặc abort |
| 2 | BLOCKED | /answer |
| 3 | DONE nhưng scope/gate/trace FAIL | /review (thường REJECT kèm chỉ đạo; vi phạm scope → REJECT) |
| 4 | FAILED / không report | đọc report; sửa task card hoặc tự làm |

Task độc lập: chạy nhiều `delegate.sh` song song bằng Bash `run_in_background`, xử lý từng kết quả khi có thông báo.

# ANSWER (append `.ai/answers/<ID>.md`, không xóa round cũ)
```
## Round <n> — ANSWER
Q1: B
Q2: Timeout 2 ms (2 chu kỳ 1 kHz); hết hạn → trả Error::Timeout, tăng counter, KHÔNG vào safe state (supervisor xử lý).
```
- Trả lời đủ, có giá trị cụ thể. Câu hỏi lộ lỗ hổng lớn → sửa task card/SDD thay vì trả lời vụn.
- Câu trả lời có tính chung (sẽ lặp ở task khác) → tạo `.ai/decisions/ADR-nnn-*.md` (template `.ai/templates/adr.md`)
  + 1 dòng vào skill Gemini `project-conventions`. Quyết định về yêu cầu/an toàn trong ADR cần người dùng duyệt.
- Câu hỏi về yêu cầu sản phẩm, phân loại class, hành vi an toàn chưa có trong SRS/SDD → HỎI NGƯỜI DÙNG trước.
- Gemini xin deviation / hạ ngưỡng / thêm SOUP → không tự đồng ý, hỏi người dùng. Deviation được chấp thuận: bạn tạo
  `.ai/deviations/DEV-nnn.md` từ template ở repo chính (để trống APPROVED_BY cho người duyệt), rồi ANSWER cho phép dùng `// @deviation DEV-nnn`.

# REWORK
```
## Round <n> — REWORK
R1: src/teleop/scaler.cpp:88 — scale trước khi clamp → clamp sau khi scale theo SDD-teleop §4.2.
```
Rồi `--resume`. delegate.sh từ chối khi số REWORK > MAX_REWORK → `./scripts/abort.sh <ID>`, tự làm (owner: lead) hoặc chia nhỏ.

# Code của Lead (owner: lead)
`./scripts/lead.sh start <ID>` → sửa code TRONG `../wt-<ID>` (chỉ file được phép) → `./scripts/lead.sh finish <ID>` (exit 0/3)
→ /review: fw-reviewer-high + fw-safety-assessor + `./scripts/cross-review.sh <ID>` (bắt buộc). Bạn không review code của chính mình.

# Cross-review (model khác)
`./scripts/cross-review.sh <ID>` → `.ai/reports/<ID>.xreview.md` (XVERDICT + X1..Xn). Bắt buộc với owner lead; tùy chọn cho Class C.
Exit 4 (không có kết quả hợp lệ) → chạy lại một lần; vẫn lỗi → báo người dùng, không coi là NO_FINDINGS. Exit 1 → worktree chưa commit.
Phân xử từng Xn: đúng → sửa/REWORK; sai → ghi lý do bác bỏ trong bảng Issues của hồ sơ review.

# Kết thúc
APPROVE → ghi `.ai/reviews/<ID>.md` với `REVIEWED_SHA` = `git -C ../wt-<ID> rev-parse HEAD` (SHA đã review) → `./scripts/merge.sh <ID>`.
merge.sh: exit 1 thiếu điều kiện (SHA lệch → code đổi sau review → review lại) · 3 chạy lại gate FAIL · 5 cần kỹ sư ký → báo người dùng.
Không bao giờ điền HUMAN_* (hook chặn); không sửa worktree sau khi đã ghi REVIEWED_SHA.
