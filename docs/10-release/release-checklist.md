# Software Release Checklist (IEC 62304 §5.8) — phiên bản: ____
| # | Mục | Bằng chứng | Trạng thái | Người xác nhận |
|---|---|---|---|---|
| 1 | Verification hoàn tất cho mọi SRS (trace.py không GAP) | trace-matrix.csv | | |
| 2 | Gate đầy đủ PASS cho mọi platform/class | CI log | | |
| 3 | Mọi task B/C có review record có chữ ký | docs/07/records | | |
| 4 | Anomaly còn mở được liệt kê & đánh giá không ảnh hưởng an toàn | unresolved-anomalies | | |
| 5 | Risk management: RCM verify hiệu quả, rủi ro tồn dư được chấp nhận | RMF | | |
| 6 | SOUP list & SBOM khớp bản build | soup-list, SBOM | | |
| 7 | Tài liệu không còn TBD, đã Approved trong eQMS | | | |
| 8 | Build tái lập được (toolchain, phiên bản, cấu hình được lưu) | | | |
| 9 | Đóng gói, ký số, lưu trữ bản release | | | |
| 10 | Cybersecurity: threat model cập nhật, lỗ hổng đã đánh giá | docs/11 | | |
