---
name: build-protocol
description: Build/gate do script chạy thay worker, cách đọc kết quả gửi lại, khi nào được tự sửa vs phải hỏi Lead. Luôn áp dụng cho task có code.
---
# Build — bạn KHÔNG tự chạy
Bạn chạy qua Antigravity CLI ở chế độ không tương tác: KHÔNG có quyền chạy lệnh shell (build, test, git, python...).
Gọi lệnh → bị hook `vsur-policy` chặn (có thể kết thúc phiên), được ghi vào hồ sơ. Viết code + test cẩn thận bằng cách ĐỌC code/header liên quan, rồi ghi report.
- Sau report `STATUS: DONE`, delegate.sh chạy: scope → gate (build target + host, test, banned-check, phân tích tĩnh,
  coverage theo class — trên file bạn thay đổi so với base) → trace, bằng script & config của repo chính.
- FAIL → script gửi lại trong CÙNG hội thoại: `.ai-out/checks.txt` (tóm tắt) và `.ai-out/gate.log` (đầy đủ), kèm số lượt autofix còn lại.
- Report của bạn: `Build: chưa chạy (script chấm)` ở lượt đầu; sau phản hồi ghi theo checks.txt.

# Khi script báo FAIL
Chỉ được tự sửa khi CẢ HAI đúng:
(a) script báo còn lượt autofix (`autofix_max`; Class C luôn = 0), và
(b) lỗi CƠ HỌC trong code chính bạn vừa viết: typo, thiếu `;`/ngoặc, thiếu `#include` header đã có
    trong task card, sai tên biến cục bộ, unused variable bạn vừa tạo.
Mọi trường hợp khác → KHÔNG sửa, ghi `.ai-out/question.md` + report `STATUS: BLOCKED` kèm lỗi đã lọc:
- file ngoài phạm vi, linker/undefined reference, toolchain/CMake/cờ compiler, SDK QNX/Linux
- cần đổi kiểu, chữ ký hàm, interface `.h`; warning cần quyết định; test fail
- vi phạm banned-check / MISRA / clang-tidy / coverage không đạt; trace gap
Mỗi lỗi: file:dòng, thông báo, phương án A/B. KHÔNG tự chọn.
Tuyệt đối không: tắt warning, cast/pragma/NOLINT, comment code, xóa test, hạ ngưỡng coverage.
