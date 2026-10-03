---
name: linux-service-impl
description: Cách implement một service C++ (process/daemon) trên Embedded Linux — main & lifecycle, init/RT phase, systemd notify/watchdog, tín hiệu, cấu hình, health, version/interface hash. Áp dụng khi task card khai skills có linux-service-impl (skeleton/khung service, main, lifecycle).
---
# Service C++ trên Linux
- Cấu trúc theo task card/SDD: `main` mỏng → nạp cấu hình → khởi tạo → vòng lifecycle → dừng. Logic nghiệp vụ ở lớp tách khỏi
  OS (ports & adapters) để test trên host.
- Cấu hình: chỉ đọc file/đường dẫn task card chỉ định; kiểm schema version, kiểu, miền giá trị TỪNG trường; thiếu/sai → không khởi động
  (exit code task card), không dùng giá trị mặc định ngầm cho tham số an toàn.
- Pha init: cấp phát mọi bộ nhớ, tạo DDS entity, mở thiết bị, tạo thread qua OSAL (`ThreadConfig` đúng bảng thread), `mlockall`
  nếu có thread RT. Xong hết mới báo READY (`sd_notify("READY=1")` hoặc cơ chế task card). Không cấp phát sau READY ở Class B/C.
- Lifecycle cục bộ (UNCONFIGURED/INACTIVE/ACTIVE/SAFE/ERROR — đúng bảng task card): chỉ chuyển theo lệnh SSM hoặc tự về SAFE khi lỗi;
  khởi động luôn vào INACTIVE/SAFE, không tự ACTIVE.
- Watchdog systemd (`WATCHDOG=1`): chỉ gửi từ health checker khi MỌI thread quan trọng đã báo tiến triển trong chu kỳ vừa qua
  (counter/heartbeat của từng thread); không gửi từ timer độc lập.
- Tín hiệu: xử lý SIGTERM/SIGINT bằng `signalfd` hoặc self-pipe; handler chỉ làm việc async-signal-safe (đặt cờ/ghi pipe).
  Dừng: về SAFE theo trình tự task card → dừng thread → giải phóng → exit code đúng. Không `exit()` từ thread phụ.
- Cấm: `system()`, `popen()`, `fork/exec` ngoài task card; ghi file ngoài thư mục chỉ định; `std::cout`/`printf` ở thread RT;
  chạy với quyền root (dùng capabilities task card nêu).
- Version: in/ công bố phiên bản service, git SHA, phiên bản & hash interface (`vsur-idl`) khi khởi động và trong `service_status`.
- Lỗi khởi tạo nào cũng trả `Status` lên tới `main` → log non-RT + exit code; không tiếp tục chạy nửa vời.
- Test (host): parse cấu hình (thiếu trường, sai kiểu, ngoài miền, version sai), chuyển lifecycle hợp lệ/không hợp lệ, watchdog không
  kick khi một thread ngừng, xử lý tín hiệu dừng → SAFE trước khi thoát.
