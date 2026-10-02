---
name: build-protocol
description: Cách build, phân loại lỗi build và khi nào được tự sửa vs phải hỏi Lead. Luôn áp dụng cho task có code.
---
# Build
Dùng ĐÚNG lệnh trong "THAM SỐ PHIÊN" (đã gắn --platform và --class):
- Build nhanh: `./scripts/gate.sh --build-only --platform <p> --class <c>`
- Gate đầy đủ: `./scripts/gate.sh --platform <p> --class <c> --base <sha>` (build target + host, test, banned-check,
  phân tích tĩnh, coverage theo class — trên các file bạn thay đổi so với base của task)
- Gate mà delegate.sh chấm dùng script & config của repo chính: sửa gate/config trong worktree không có tác dụng và bị đánh FAIL.

# Khi build/gate lỗi
Chỉ được tự sửa khi CẢ HAI đúng:
(a) còn lượt `autofix_max` (Class C luôn = 0), và
(b) lỗi CƠ HỌC trong code chính bạn vừa viết: typo, thiếu `;`/ngoặc, thiếu `#include` header đã có
    trong task card, sai tên biến cục bộ, unused variable bạn vừa tạo.
Mọi trường hợp khác → KHÔNG sửa, BLOCKED + question kèm lỗi đã lọc:
- file ngoài phạm vi, linker/undefined reference, toolchain/CMake/cờ compiler, SDK QNX/Linux
- cần đổi kiểu, chữ ký hàm, interface `.h`; warning cần quyết định; test fail
- vi phạm banned-check / MISRA / clang-tidy / coverage không đạt; trace gap
Mỗi lỗi: file:dòng, thông báo, phương án A/B. KHÔNG tự chọn.
Tuyệt đối không: tắt warning, cast/pragma/NOLINT, comment code, xóa test, hạ ngưỡng coverage.
