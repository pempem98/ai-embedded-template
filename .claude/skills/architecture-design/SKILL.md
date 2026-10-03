---
name: architecture-design
description: Thiết kế & tài liệu hóa kiến trúc cho robot phẫu thuật — System Architecture (SyAD: subsystem, phân bổ SW/HW/ME, ICD) và Software Architecture (SAD, IEC 62304 §5.3: software item, interface, SOUP, segregation, class, deployment, timing), các view & sơ đồ (Mermaid), phân tích trade-off → ADR, verify kiến trúc. Dùng khi /arch, /plan, chia software item, vẽ sơ đồ kiến trúc, viết/review SyAD/SAD, hoặc người dùng nhắc "kiến trúc", "architecture", "sơ đồ", "block diagram".
---
# Đầu ra & vị trí
| Tài liệu | Mẫu | Bản làm việc | Nội dung chính |
|---|---|---|---|
| SyAD (system) | `docs/templates/SyAD-template.md` | `docs/03-architecture/SyAD.md` | subsystem, phân bổ SYS → SW/HW/ME/EE, ICD giữa subsystem, chế độ hệ thống, kiến trúc an toàn hệ thống |
| SAD (software) | `docs/templates/SAD-template.md` | `docs/03-architecture/SAD.md` | software item, class & lý do, interface, SOUP, segregation, deployment, dynamic, timing, xử lý lỗi |
| ADR | `.ai/templates/adr.md` | `.ai/decisions/` | quyết định + phương án đã cân nhắc |
| Context brief | — | `docs/03-architecture/context-brief.md` | tóm tắt ≤ 50 dòng cho AI |
Sơ đồ: Mermaid trong markdown (diff được, review được) — quy ước & mẫu ở `references/diagrams.md` (chỉ đọc khi vẽ).

# Quy trình (/arch)
1. **Driver**: SYS/SRS liên quan, HAZ/RCM, ràng buộc (nền tảng, SOUP có chứng nhận, chi phí, nhân lực), thuộc tính chất lượng xếp hạng:
   an toàn > tính xác định thời gian thực > bảo mật > khả năng kiểm thử > bảo trì > hiệu năng.
2. **Phân rã**: hệ thống → subsystem (SyAD) → software system → software item (SAD) → unit (SDD, Class C).
   Mỗi SI một trách nhiệm chính; logic an toàn tách thành SI riêng, đơn giản, độc lập (skill `safety-architecture`).
3. **Phân bổ**: SYS → subsystem; SRS → SI; RCM → SI/HW; SI → node/CPU/OS/process/partition/thread (deployment).
4. **Interface**: mọi interface có ID (IF-nnn), hướng, dữ liệu (kiểu, đơn vị, miền), chu kỳ/deadline, giao thức (skill `comm-protocols`),
   xử lý lỗi, lớp an toàn E2E. Interface giữa subsystem → ICD trong SyAD.
5. **Phân loại & segregation**: class từng SI + lý do; SI class thấp hơn cha chỉ khi segregation có bằng chứng (§5.3.5).
6. **Trade-off**: ≥ 2 phương án cho quyết định quan trọng → bảng tiêu chí (theo driver) → chọn → ADR. Không chọn ngầm.
7. **Vẽ view** (bảng dưới), cập nhật `context-brief.md`, SOUP list, threat model (data flow).
8. **Verify kiến trúc** (§5.3.6) bằng checklist dưới; giao `fw-safety-assessor` phản biện phần an toàn; người dùng duyệt phân loại.

# View bắt buộc
| View | Trả lời câu hỏi | Sơ đồ Mermaid | SyAD | SAD |
|---|---|---|---|---|
| Context | hệ thống tương tác với ai/gì | flowchart | ✔ | ✔ |
| Decomposition / block | gồm những phần nào, class mỗi phần | flowchart + subgraph + màu theo class | ✔ | ✔ |
| Interface | phần nào nói với phần nào, qua gì | flowchart có nhãn IF-nnn / bảng ICD | ✔ | ✔ |
| Deployment | chạy ở đâu (node, CPU, OS, process, partition, core) | flowchart lồng subgraph | ✔ | ✔ |
| Dynamic | luồng chính & đường lỗi theo thời gian | sequenceDiagram | – | ✔ |
| State / mode | chế độ hệ thống, safe state, chuyển trạng thái | stateDiagram-v2 | ✔ | ✔ |
| Data flow & trust boundary | dữ liệu đi đâu, biên tin cậy (cyber) | flowchart + subgraph biên | ✔ | ✔ |
| Timing budget | chu kỳ, deadline, WCET từng chặng | bảng | – | ✔ |

# Mẫu kiến trúc phần mềm thường dùng
- Phân lớp: HAL → OSAL/driver → service (fieldbus, logging, config) → ứng dụng (control, teleop) → supervisor. Lớp dưới không gọi lớp trên.
- Ports & adapters: logic thuần tách khỏi OS/HW qua interface → unit test trên host (điều kiện để gate chạy được).
- Giao tiếp giữa SI: message passing (QNX) / SPSC queue, triple buffer, shared memory + seqlock (Linux RT); không chia sẻ biến toàn cục.
- State machine tường minh cho mode hệ thống & safe state (Lead viết); supervisor/monitor độc lập kênh 2.
- Cấu hình & tham số hiệu chuẩn: dữ liệu có version + CRC, kiểm tra lúc khởi động.
- Design pattern trong SI: bạn chốt trong SDD (ai tạo đối tượng — composition root, ai inject gì, callback hay hàng đợi, bảng
  chuyển trạng thái); worker không tự chọn. Giới hạn theo skill Gemini `design-clean-code`: không singleton, DI qua constructor,
  factory chỉ ở init, observer dung lượng cố định và không xuyên thread.

# Checklist verify kiến trúc (62304 §5.3.6) — mỗi mục có bằng chứng
Mọi SRS được phân bổ cho SI · mọi SI có class + lý do · interface giữa SI và với HW/SOUP được định nghĩa đầy đủ ·
SOUP: yêu cầu chức năng/hiệu năng & phần cứng (§5.3.3–5.3.4) · segregation có cơ chế + bằng chứng · RCM được phân bổ và có thể verify ·
timing budget cộng lại ≤ deadline · đường lỗi nào cũng dẫn tới safe state xác định · không có dữ liệu từ thành phần class thấp
ghi vào dữ liệu safety mà không kiểm tra · kiến trúc kiểm thử được (unit trên host, integration, HIL).

# Phân vai
Claude viết SyAD/SAD (quyết định kiến trúc là việc của Lead), Gemini có thể soạn nháp phần mô tả dài/bảng từ ghi chú (type: doc).
Phân loại class, chấp nhận segregation, quyết định SW/HW cho chức năng an toàn: người dùng / system & safety engineer phê duyệt.
