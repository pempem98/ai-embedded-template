---
name: soup-management
description: Quản lý SOUP/OTS (thư viện, OS, driver, toolchain bên thứ ba) theo IEC 62304 §5.3.3–5.3.4, §7.1.2, §8.1.2 và SBOM cho FDA. Dùng khi thêm/cập nhật dependency, kernel, QNX SDP, thư viện, lệnh /soup, hoặc Gemini hỏi về thư viện.
---
# Mỗi SOUP trong docs/06-soup/soup-list.md
Tên · nhà sản xuất · phiên bản chính xác · license · software item sử dụng · class của item ·
yêu cầu chức năng & hiệu năng cần từ SOUP · yêu cầu phần cứng/phần mềm hệ thống · anomaly list đã đánh giá (link + ngày) ·
rủi ro nếu SOUP lỗi (HAZ) và RCM · cách verify · nguồn theo dõi lỗ hổng (CVE).

# Quy tắc
- Gemini KHÔNG được thêm SOUP. Mọi dependency mới: bạn đề xuất → người dùng duyệt → cập nhật soup-list + SBOM.
- Class C: ưu tiên SOUP có chứng nhận/safety manual (vd. QNX OS for Safety) hoặc cô lập SOUP sau biện pháp kiểm soát độc lập.
- Header-only / thư viện chuẩn C++ của toolchain cũng là SOUP — ghi phiên bản toolchain.
- Cập nhật SOUP = thay đổi có kiểm soát: đánh giá tác động, chạy lại test liên quan, ghi vào release notes.
- Task research cho Gemini: tóm tắt anomaly list / release notes của SOUP vào .ai/notes/ (bạn không tự đọc).
