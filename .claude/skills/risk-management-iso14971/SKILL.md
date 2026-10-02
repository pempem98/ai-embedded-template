---
name: risk-management-iso14971
description: Phân tích mối nguy và biện pháp kiểm soát rủi ro phần mềm theo ISO 14971 + IEC 62304 §7 cho robot phẫu thuật. Dùng khi thiết kế tính năng mới, thay đổi hành vi điều khiển/an toàn, phân tích lỗi, lệnh /hazard, hoặc khi nhắc HAZ/RCM/FMEA/rủi ro.
---
# Chuỗi sự kiện
Software item lỗi → chuỗi sự kiện → tình huống nguy hiểm → tác hại. Ghi đủ chuỗi, không chỉ "phần mềm lỗi".

# Nguồn nguy cơ phần mềm điển hình của robot phẫu thuật
- Chuyển động ngoài ý muốn (lệnh sai, mất đồng bộ master–slave, sai kinematics/hiệu chuẩn, nhảy vị trí khi mất encoder)
- Vượt giới hạn vận tốc/lực/workspace, va chạm cánh tay–bệnh nhân/nhân viên
- Độ trễ/jitter teleoperation, mất frame video, video đông cứng nhưng hiển thị như trực tiếp
- Mất liên lạc fieldbus/IPC, dữ liệu stale, watchdog không kích hoạt
- Không dừng được khi nhấn E-stop/nhả clutch; không vào safe state; không thể chuyển sang thao tác thủ công/tháo dụng cụ
- Kích hoạt năng lượng (electrosurgery) ngoài ý muốn; nhận dạng sai dụng cụ/đếm lượt dùng
- Lỗi khởi động/cập nhật phần mềm, cấu hình sai phiên bản; lỗ hổng an ninh mạng
- SOUP lỗi (OS, thư viện, driver)

# Biện pháp kiểm soát (ưu tiên theo 14971: thiết kế an toàn vốn có > biện pháp bảo vệ > thông tin)
- Kiến trúc: safety monitor độc lập (kênh thứ 2, CPU/MCU khác), segregation, giới hạn cứng ở tầng thấp
- Phát hiện: plausibility, so chéo dư thừa, CRC/sequence/timestamp, heartbeat/watchdog, self-test lúc khởi động
- Phản ứng: safe state xác định (dừng có kiểm soát, phanh), thông báo người dùng
- Mỗi RCM do phần mềm thực hiện → trở thành yêu cầu SRS (class kế thừa từ mức nghiêm trọng) + test verify hiệu quả.

# Ghi nhận
- `docs/05-risk-management/hazard-analysis.md`: HAZ-xxx (nguyên nhân, chuỗi, tình huống, tác hại, severity, P trước/sau).
- `docs/05-risk-management/risk-control-matrix.md`: RCM-xxx ↔ HAZ ↔ SRS ↔ test.
- Bạn đề xuất; Risk Management team (con người) đánh giá xác suất, mức chấp nhận rủi ro và phê duyệt.
- Không tự định giá trị xác suất/acceptability — để `TBD(risk team)`.
