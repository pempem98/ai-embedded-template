---
description: Lead tự viết code safety-critical (ISR, DMA, safety monitor, safe state, RT sync, startup/linker, scheduler/partition) qua cùng quy trình kiểm soát
argument-hint: <ID>
---
Task `.ai/tasks/$ARGUMENTS.md` phải có `owner: lead` (skill `task-card`; Class C cần SDD). Skills: `delegate-gemini`, `safety-architecture`,
skill nền tảng (`linux-rt-design`/`qnx-design`), `comm-protocols` nếu có `protocols:`. Think hard.
1. `./scripts/lead.sh start $ARGUMENTS` → chỉ sửa file trong "Files được phép", TRONG `../wt-$ARGUMENTS` (không sửa repo chính).
2. Viết code + unit test + tag truy vết theo đúng chuẩn của skill Gemini tương ứng (`.agents/skills/`): cùng luật, cùng gate.
3. `./scripts/lead.sh finish $ARGUMENTS` → exit 3: sửa và finish lại.
   Exit 0 → ghi `.ai/reports/$ARGUMENTS.md` đúng mẫu report của skill Gemini `worker-protocol` (STATUS, files, truy vết,
   build/test/coverage, "Điểm Lead nên soát" → ở đây là điểm reviewer nên soát) — reviewer và hồ sơ merge dùng file này.
4. `/review $ARGUMENTS` — reviewer độc lập + safety assessor + cross-review (bắt buộc). Bạn không tự APPROVE code của mình.
5. Báo người dùng: kỹ sư phải review như code do người viết (docs/01-plan §2.3).
