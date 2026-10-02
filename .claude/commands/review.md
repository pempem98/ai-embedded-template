---
description: Review task (Gemini hoặc Lead), ghi hồ sơ review, APPROVE→merge hoặc REJECT→rework
argument-hint: <ID>
---
Đọc `type:`, `owner:`, `effort:`, `safety_class:`, `risk_controls:`, `protocols:` trong `.ai/tasks/$ARGUMENTS.md`. Skill `delegate-gemini`.
- type doc → subagent `reg-doc-reviewer` (đọc tài liệu trong `../wt-$ARGUMENTS`).
- type research → bạn tự kiểm file `.ai/notes/` trong worktree: mọi dữ kiện có trích dẫn (tài liệu + mục/trang hoặc file:dòng),
  không khuyến nghị thiết kế, đúng giới hạn độ dài; không cần subagent. Ghi hồ sơ review ngắn rồi merge như bình thường.
- effort high hoặc owner lead → `fw-reviewer-high`; ngược lại `fw-reviewer-low`.
- Class C, có risk_controls, hoặc owner lead → thêm `fw-safety-assessor` sau khi reviewer APPROVE.
- owner lead (bắt buộc) hoặc Class C (tùy chọn) → `./scripts/cross-review.sh $ARGUMENTS`, đọc `.ai/reports/$ARGUMENTS.xreview.md`,
  phân xử từng Xn (đúng → sửa/REWORK; sai → ghi lý do bác bỏ trong hồ sơ).
REJECT (hoặc SAFETY_VERDICT khác ACCEPTABLE) → Gemini: REWORK + `--resume`; Lead: sửa trong `../wt-$ARGUMENTS` rồi `lead.sh finish`, review lại.
NEEDS_RISK_TEAM → dừng, báo người dùng.
APPROVE → ghi `.ai/reviews/$ARGUMENTS.md` theo `.ai/templates/review.md`: BASE_SHA, REVIEWED_SHA = SHA reviewer trả về
(phải bằng `git -C ../wt-$ARGUMENTS rev-parse HEAD`), để nguyên placeholder HUMAN_*. Rồi `./scripts/merge.sh $ARGUMENTS`.
- exit 5 → báo người dùng: kỹ sư xem diff (lệnh in ra) và ký vào file review (SIGNOFF_MODE=gpg: commit ký GPG), rồi chạy lại merge.
- exit 3 → kiểm tra lại lúc merge FAIL: báo người dùng, không tự sửa gate.
- exit 1 do REVIEWED_SHA lệch → code đã đổi sau review: review lại phần thay đổi.
