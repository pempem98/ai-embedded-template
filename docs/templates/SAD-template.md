# Software Architecture Document (SAD) — <software system> — DRAFT (IEC 62304 §5.3)
| Rev | Date | Author | Change | Status |
|---|---|---|---|---|
<!-- Sơ đồ: Mermaid theo .claude/skills/architecture-design/references/diagrams.md; màu theo class -->

## 1. Context & phạm vi (FIG-SAD-01)
## 2. Software items (FIG-SAD-02)
| SI | Tên | Trách nhiệm | Nền tảng | Class | Lý do phân loại | SRS | RCM thực hiện |
|---|---|---|---|---|---|---|---|
## 3. Interfaces (FIG-SAD-03)
| IF | Từ → Đến | Cơ chế (call / msg / shm / fieldbus) | Dữ liệu (kiểu, đơn vị, miền) | Chu kỳ / deadline | Kiểm tra (CRC/seq/timeout) | Lỗi → |
|---|---|---|---|---|---|---|
## 4. SOUP (§5.3.3–5.3.4)
| SOUP | Phiên bản | SI dùng | Yêu cầu chức năng/hiệu năng | Yêu cầu HW/SW hệ thống | Link soup-list |
|---|---|---|---|---|---|
## 5. Segregation (§5.3.5)
| Item | Cơ chế (process / partition / MPU / CPU riêng) | Bằng chứng |
|---|---|---|
## 6. Deployment (FIG-SAD-04)
| SI | Node / CPU | OS | Process / partition | Thread | Policy / priority | Core |
|---|---|---|---|---|---|---|
## 7. Dynamic behavior (FIG-SAD-05..) — luồng chính & đường lỗi
## 8. Mode & safe state (FIG-SAD-06)
## 9. Timing budget
| Loop / chuỗi | Chu kỳ | Deadline | Các chặng & WCET | Tổng | Bằng chứng đo |
|---|---|---|---|---|---|
## 10. Chiến lược xử lý lỗi & logging
## 11. Quyết định kiến trúc (ADR)
## 12. Verify kiến trúc (§5.3.6) — checklist skill architecture-design, kết quả & người review
## 13. TBD
