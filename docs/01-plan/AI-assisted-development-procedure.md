# AI-Assisted Software Development Procedure (DRAFT)
Status: Draft — cần QA/RA phê duyệt trước khi dùng cho phần mềm phát hành.

## 1. Phạm vi
Mô tả việc dùng công cụ AI (Claude Code: thiết kế/review hỗ trợ, viết code safety-critical có kiểm soát; Antigravity CLI `agy` với model Gemini: implement/soạn nháp/
review chéo) trong vòng đời phần mềm. AI là **công cụ phát triển**, không phải người phê duyệt.
Trách nhiệm thuộc về kỹ sư có năng lực được chỉ định.

## 2. Kiểm soát
1. Mọi đầu ra AI (Gemini và Claude) đi qua: kiểm tra phạm vi thay đổi (`check_scope.py`) → gate tự động (build, test, static analysis,
   coverage, banned-check) → trace → AI review → **review của con người** (bắt buộc Class B/C, `.ai/reviews/<ID>.md`).
   Gate/scope/trace luôn chạy bằng script & cấu hình của repo chính, không phải bản trong worktree của AI.
2. Phân loại safety class, yêu cầu, chấp nhận rủi ro, deviation, SOUP, ngưỡng gate: chỉ con người quyết định.
   Hook của Claude Code chặn AI điền trường phê duyệt (HUMAN_*, APPROVED_BY) và sửa hồ sơ đã lưu.
3. Mã do Lead (AI) viết trực tiếp (safety supervisor, ISR, state machine...) đi qua cùng quy trình (`lead.sh`), được review độc lập
   (subagent khác context + review chéo bằng model khác) và được con người review như mã do người viết.
4. Chữ ký gắn với commit: hồ sơ review ghi `REVIEWED_SHA`; `merge.sh` chỉ merge đúng SHA đó, worktree sạch, và chạy lại gate/scope/trace.
   `SIGNOFF_MODE=gpg`: kỹ sư commit file review bằng commit ký GPG (khuyến nghị cho phần mềm phát hành — QA quyết định).
5. Mọi hồ sơ được lưu vào `docs/07-verification/records/<ID>/`: task card, câu hỏi/trả lời, worker report, cross-review, gate output,
   kết quả kiểm tra lúc merge, review record, provenance (base/head SHA, lịch sử commit theo tác giả ai-worker/ai-lead, phiên bản CLI, model),
   số liệu round.
6. Phiên bản công cụ & model AI được ghi trong configuration management (`.ai/config.env`, provenance.txt từng task).
7. Quyết định kỹ thuật dùng chung được ghi thành ADR (`.ai/decisions/`) trong repo; không dùng bộ nhớ riêng của công cụ AI cho quyết định dự án.

## 3. Validation công cụ (ISO 13485 §4.1.6 / QMSR)
- Phân tích rủi ro việc dùng công cụ: lỗi AI được phát hiện bởi các lớp kiểm soát ở §2 nào.
- Bằng chứng validation: TBD(QA) — vd. bộ lỗi cài sẵn (seeded defects: data race, thiếu kiểm CRC, sửa ngoài phạm vi, hạ ngưỡng trong
  worktree, tag truy vết giả) phải bị scope/gate/trace/review phát hiện.
- Số liệu vận hành: `.ai/metrics.csv` (round, BLOCKED, REWORK, gate fail theo loại task) — đầu vào cho đánh giá hiệu quả định kỳ (/retro).
- Tái validate khi đổi model/phiên bản công cụ lớn hoặc thay đổi skill/gate/script.

## 4. Bảo mật thông tin
- Chỉ dùng gói dịch vụ AI có cam kết không dùng dữ liệu để huấn luyện và điều khoản bảo mật doanh nghiệp. TBD(IT/Legal)
- Không đưa dữ liệu bệnh nhân, khóa bí mật, thông tin đối tác chưa được phép vào prompt.
- Gemini worker (qua `agy`) chạy trong worktree riêng, KHÔNG có quyền chạy lệnh shell (chỉ đọc/sửa file — `--mode accept-edits`);
  build/test/phân tích do script của repo chính chạy. Reviewer chéo chạy `--mode plan` (chỉ đọc).
  Không dùng chế độ tự duyệt mọi tool. Lệnh git ghi (nếu có) bị phát hiện hậu kiểm (HEAD/nhánh worktree) và bị gỡ/dừng.

## 5. Việc còn mở & quyết định cần chốt trước pilot
| # | Câu hỏi / việc | Người quyết | Hiện trạng |
|---|---|---|---|
| 1 | Class nào bắt buộc kỹ sư ký trước merge | QA + SW Lead | `HUMAN_SIGNOFF_CLASSES="B C"` |
| 2 | Hình thức chữ ký: trường văn bản / commit ký GPG / eQMS; có cần 21 CFR Part 11 | QA/RA | `SIGNOFF_MODE="text"` |
| 3 | Ngưỡng coverage B (line ≥ 90%), C (line+branch 100%), MC/DC & công cụ | SW Lead + QA | Bật `REQUIRE_MCDC=1` trước pilot/release Class C |
| 4 | Coverage/phân tích tĩnh mỗi task tính trên file thay đổi; release theo SI/toàn bộ | SW Lead + QA | đã implement trong gate.sh |
| 5 | Cho Gemini tự sửa lỗi build cơ học ở Class A/B? | SW Lead | `AUTOFIX_MAX_DEFAULT=0` |
| 6 | Công cụ MISRA & thời điểm bắt buộc | SW Lead | Bật `REQUIRE_MISRA=1` trước pilot/release Class B/C |
| 7 | Danh mục hồ sơ bắt buộc trước merge/release | QA/RA | merge.sh lưu bộ hồ sơ ở docs/07 README |
| 8 | Bảng hoạt động theo class (skill `iec62304-process`) khớp tiêu chuẩn & SOP công ty | QA/RA | chưa đối chiếu |
| 9 | Danh mục mối nguy/RCM mẫu, cơ chế đánh giá an toàn độc lập Class C | Safety/Risk | skill risk-management, safety-architecture |
| 10 | Quy tắc RT/IPC/interrupt, API QNX theo safety manual, tham số giao thức/encoder | Platform owner | skill linux-rt-*, qnx-*, comm-protocols |
| 11 | Điều khoản dữ liệu của nhà cung cấp AI, phạm vi mã nguồn được đưa vào prompt | IT/Legal | TBD |
| 12 | Kế hoạch pilot: module, tiêu chí thành công (dùng `.ai/metrics.csv`), giới hạn phạm vi | SW Lead | TBD |
| 13 | Toolchain files, `.clang-tidy`/`.clang-format` (bản khởi đầu đã có, cần chỉnh theo dự án) | SW Lead | đang làm |
