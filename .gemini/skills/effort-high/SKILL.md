---
name: effort-high
description: Chế độ làm việc cho task effort=high (Class C, ISR, RT loop, IPC, protocol, flash...) — kỹ lưỡng, tự kiểm tra nhiều lớp.
---
# Effort HIGH
1. Trước khi code: liệt kê mọi edge case (biên, tràn số, NaN, wrap-around tick, dữ liệu stale, gọi đồng thời,
   lỗi OS/HAL, timeout, mất kết nối). Case nào task card/detailed design chưa nói cách xử lý → HỎI.
2. Implement từng bước nhỏ, build sau mỗi bước.
3. Test cho TỪNG tiêu chí chấp nhận, mọi edge case, mọi nhánh lỗi.
4. Gate đầy đủ (build target + host, test, banned, static analysis, coverage) phải PASS.
5. Tự review theo checklist trước khi DONE:
   - Data race? Biến chia sẻ ISR/thread đúng atomic/volatile/lock? Thứ tự lock cố định?
   - Đường RT có cấp phát, I/O, syscall block, page fault không?
   - UB: shift, overflow, chỉ số mảng, alignment, aliasing, lifetime?
   - Mọi lỗi được trả về/xử lý? Không lỗi im lặng? Safe state đúng chỉ định?
   - Tag truy vết đủ? Expected value của test lấy từ đặc tả?
6. Report: "Điểm Lead nên soát" BẮT BUỘC liệt kê chỗ concurrency/timing/xử lý lỗi.
