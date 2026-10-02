---
name: medical-cybersecurity
description: An ninh mạng thiết bị y tế — FDA §524B (cyber device), premarket cybersecurity guidance, IEC 81001-5-1, threat modeling, SBOM, secure boot/update. Dùng khi thiết kế kết nối mạng, cập nhật phần mềm, xác thực, log, dịch vụ từ xa, hoặc review code xử lý đầu vào bên ngoài.
---
# Hồ sơ (docs/11-cybersecurity/)
- Threat model (STRIDE theo data flow: console ↔ patient cart ↔ vision ↔ hospital network ↔ service).
- Cybersecurity risk assessment (tách khỏi safety risk nhưng liên kết HAZ khi khai thác dẫn đến tác hại).
- SBOM (SPDX/CycloneDX) sinh tự động từ build; kế hoạch theo dõi & vá lỗ hổng; kiến trúc bảo mật (views).
- Security testing: fuzzing parser/protocol, phân tích tĩnh, penetration test (bên thứ ba).

# Yêu cầu kỹ thuật thường gặp
- Secure boot chuỗi tin cậy; cập nhật ký số, chống rollback; rootfs read-only.
- Xác thực & phân quyền cho chế độ dịch vụ; không mật khẩu mặc định/hard-code; không key trong repo.
- Mạng: đóng cổng không cần, mã hóa kênh ra ngoài (TLS), cô lập mạng điều khiển khỏi mạng bệnh viện.
- Mọi parser dữ liệu bên ngoài: kiểm tra độ dài, kiểu, miền giá trị; fuzz test → task effort=high.
- Audit log chống sửa đổi; đồng bộ thời gian an toàn.
- **Chức năng an toàn phải giữ được khi mất kết nối mạng/bị tấn công DoS** (fail-safe, không phụ thuộc mạng ngoài).
