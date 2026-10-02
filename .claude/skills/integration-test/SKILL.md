---
name: integration-test
description: Kiểm thử tích hợp (IEC 62304 §5.6) và hỗ trợ system test (§5.7) cho robot phẫu thuật — SIL/HIL, fault injection end-to-end, đo timing trên phần cứng đích, task card level integration/hil, regression set. Dùng khi lệnh /integrate, khi ghép các software item, khi cần bằng chứng hiệu quả của RCM trải qua nhiều item, hoặc chuẩn bị test trên phần cứng.
---
# Mức test
| Mức | Ở đâu | Ai chạy | Bằng chứng |
|---|---|---|---|
| Unit | host (gate) | gate tự động | coverage, @verifies |
| Integration SIL | host: nhiều unit thật + mock biên OS/HW | gate (ctest) | @verifies, kết quả test |
| Integration HIL | bench/phần cứng đích | kỹ sư chạy; script/harness do Gemini viết | test report có chữ ký, dữ liệu đo |
| System (§5.7) | robot đầy đủ | V&V team | AI chỉ soạn nháp test spec |

# Kế hoạch integration (`docs/07-verification/integration-plan.md`)
- Thứ tự tích hợp theo SAD (bottom-up từ HAL/driver → fieldbus → điều khiển → supervisor), interface được test,
  mỗi interface test gì: dữ liệu, timing, lỗi.
- Mỗi RCM trải qua nhiều software item → test chứng minh hiệu quả end-to-end: lỗi tại nguồn → phát hiện → phản ứng/safe state
  trong thời gian yêu cầu (số đo, không chỉ pass/fail).
- Regression set cho mỗi SI (dùng khi /impact và trước release).

# Task card
- `type: test`, `level: integration` (SIL) hoặc `level: hil`; `platform:` đích; `coverage_scope:` nếu cần.
- HIL: Gemini chỉ viết harness/script + test spec theo `docs/templates/test-spec-template.md`; KHÔNG khẳng định kết quả.
  Kết quả do kỹ sư chạy & ký, lưu `docs/07-verification/records/` hoặc test report.
- Tiêu chí có số: latency ≤ X ms, jitter ≤ Y µs, reaction time ≤ Z ms — lấy từ SRS/phân tích rủi ro, không tự đặt.

# Fault injection gợi ý
Mất/chậm/hỏng/lặp message (skill `comm-protocols`), process/thread chết, cycle overrun, cảm biến nhảy giá trị, encoder lỗi,
mất nguồn một node, E-stop, clutch nhả giữa chuyển động, đầy log/storage, mất đồng bộ thời gian.
