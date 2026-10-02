# REVIEW RECORD — <ID>
TASK: <ID> — <title>
SAFETY_CLASS: <A|B|C>      PLATFORM: <...>     SOFTWARE_ITEM: <SI-xxx>     OWNER: <gemini|lead>
REQUIREMENTS: <SRS-...>     RISK_CONTROLS: <RCM-...>     PROTOCOLS: <...>
BASE_SHA: <git rev-parse refs/ai/base/<ID>>
REVIEWED_SHA: <git -C ../wt-<ID> rev-parse HEAD — đúng SHA đã review; merge.sh từ chối nếu HEAD khác>
AI_VERDICT: APPROVE
AI_REVIEWERS: <fw-reviewer-high (opus), fw-safety-assessor (opus), cross-review (AGY_MODEL_HIGH)>
AI_REVIEW_DATE: <YYYY-MM-DD>
GATE: PASS (build <platform>+host, test, banned, static analysis, coverage <...>)   SCOPE: PASS   TRACE: PASS
ROUNDS: <số round / số REWORK>

## Mục đã kiểm
- <concurrency / timing / error handling / boundary / protocol robustness / traceability / coding standard ...>

## Issues & xử lý
| # | Nguồn (reviewer/Xn) | Vấn đề | Round | Trạng thái / lý do bác bỏ |
|---|---|---|---|---|

## Ghi chú cho kỹ sư review
- <điểm nên tự kiểm tra kỹ>
- Diff: `git -C ../wt-<ID> diff <BASE_SHA> <REVIEWED_SHA>`

---
## Phê duyệt của con người (bắt buộc cho class trong HUMAN_SIGNOFF_CLASSES) — AI KHÔNG điền (hook chặn)
HUMAN_REVIEWER: <họ tên, chức danh>
HUMAN_DECISION: <APPROVED | REJECTED>
HUMAN_DATE: <YYYY-MM-DD>
HUMAN_COMMENTS:
