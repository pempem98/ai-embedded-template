---
description: Kiểm tra sẵn sàng release phần mềm (IEC 62304 §5.8)
argument-hint: <phiên bản>
---
Phiên bản: $ARGUMENTS — dùng `docs/10-release/release-checklist.md`.
Tự động kiểm:
- `python scripts/trace.py` không GAP.
- Gate toàn bộ: với mỗi SI trong SAD chạy `./scripts/gate.sh --platform <p> --class <class của SI> --scope "<thư mục SI>"`;
  thêm một lượt `--full --class A` (build/test/banned toàn bộ). Ngưỡng không được nới.
- Mọi thư mục `docs/07-verification/records/<ID>/` có review.md (AI_VERDICT, REVIEWED_SHA, chữ ký B/C), provenance.txt, merge-checks.txt.
- ANOM mở → danh sách unresolved kèm đánh giá; soup-list & SBOM khớp build; không còn TBD trong tài liệu phát hành;
  ADR Accepted đã phản ánh vào SDD/SRS khi liên quan.
Báo bảng: mục | trạng thái | bằng chứng. Mục cần con người → đánh dấu rõ. Không tuyên bố "đạt chuẩn".
