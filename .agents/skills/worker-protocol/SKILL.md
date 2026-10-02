---
name: worker-protocol
description: Quy trình bắt buộc của Gemini worker cho MỌI task — đọc task card, hỏi khi chưa rõ, ghi report/question. Luôn áp dụng.
---
# Quy trình
1. Đọc hết: detailed design (nếu có), task card, "CHỈ ĐẠO TỪ LEAD" (round mới nhất ưu tiên nhất), THAM SỐ PHIÊN.
2. TRƯỚC khi code: rà soát điểm chưa chốt. Có → gom TẤT CẢ câu hỏi vào MỘT question, BLOCKED, dừng.
3. Implement đúng phạm vi; gặp điểm chưa rõ giữa chừng → dừng, hỏi.
4. KHÔNG chạy lệnh shell (bị chặn, phiên kết thúc) — chỉ đọc/tìm/sửa file. Build/test do script chạy sau report,
   lỗi gửi lại theo `build-protocol`. Gắn tag theo `traceability-tags`.
5. Ghi report (+ question nếu BLOCKED). delegate.sh tự commit mỗi lượt.
6. Chỉ sửa file trong "Files được phép"; sửa file khác, file `OWNER: lead`, script/config/skill → check_scope.py đánh FAIL tự động.
7. Câu hỏi về quy ước chung (kiểu lỗi, OSAL, logger, đơn vị, CRC...) mà `project-conventions` còn TBD → hỏi; Lead sẽ chốt thành ADR.

# .ai-out/question.md
```
# QUESTION <ID>
## Đã làm đến đâu (≤3 dòng)
## Câu hỏi
Q1: <câu hỏi cụ thể>
  A: <phương án>   B: <phương án>   (liệt kê, KHÔNG tự chọn)
  Ảnh hưởng an toàn: <không | mô tả ngắn>
## Lỗi build/gate (nếu có, đã lọc, ≤15 dòng, file:dòng)
```

# .ai-out/report.md (dòng đầu PHẢI là STATUS)
```
STATUS: DONE | BLOCKED | FAILED
TASK: <ID>  CLASS: <A|B|C>  PLATFORM: <p>
## Files đã thay đổi
- path — mô tả 1 dòng
## Truy vết
- SRS-xxx → src/file.cpp:fn (@req) → test/test_x.cpp:test_name (@verifies)
- RCM-xxx → ... (@rcm) → ...
## Build: chưa chạy (script chấm) | PASS|FAIL theo .ai-out/checks.txt · Tests: x/y · Coverage (nếu có)
## Điểm Lead nên soát (≤5 dòng: concurrency, timing, số học, lỗi)
## Lệch khỏi task card: KHÔNG | <mô tả>
```
FAILED chỉ khi không thể thực hiện (thiếu file/tool), ghi nguyên nhân. Report ≤ 30 dòng.
