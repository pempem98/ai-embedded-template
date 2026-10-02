---
name: problem-resolution
description: Quản lý anomaly/bug theo IEC 62304 §9 — báo cáo, điều tra, đánh giá ảnh hưởng an toàn, sửa, verify, xu hướng. Dùng khi có bug, test fail trên phần cứng, lỗi từ hiện trường, lệnh /anomaly, hoặc trước release.
---
# Quy trình
1. Tạo `docs/09-problem-resolution/ANOM-nnn.md` từ template: mô tả, cách tái hiện, phiên bản, phát hiện ở đâu.
2. Đánh giá: software item, class, liên quan HAZ nào, mức độ nghiêm trọng, có ảnh hưởng an toàn không (cần risk team xác nhận nếu có).
3. Điều tra nguyên nhân (có thể giao Gemini `type: research` đọc log/code, tóm tắt).
4. Sửa qua task `type: fix` (nêu ANOM-ID trong task card), thêm test tái hiện lỗi trước khi sửa (`@verifies` + ANOM ID trong comment).
5. Verify, cập nhật trạng thái; xét regression test cần chạy lại.
6. Anomaly chưa giải quyết lúc release → liệt kê trong release notes kèm lý do không ảnh hưởng an toàn (bắt buộc cho FDA).
7. Định kỳ phân tích xu hướng (cùng module, cùng loại lỗi) → đề xuất cải tiến quy trình.
