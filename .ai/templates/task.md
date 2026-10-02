---
id: T01
title: <tên ngắn>
type: implement            # implement | fix | test | research | doc
owner: gemini              # gemini (delegate.sh) | lead (Claude tự viết: ISR/DMA/safety/safe state/RT sync → lead.sh)
platform: host             # host | mcu | linux | qnx
safety_class: B            # A | B | C   (C → effort high, autofix 0, bắt buộc detailed_design)
software_item: SI-000
requirements: SRS-000      # bắt buộc với B/C
risk_controls:             # RCM-xxx nếu task implement biện pháp kiểm soát rủi ro
detailed_design:           # bắt buộc với C: docs/04-detailed-design/SDD-xxx.md (file phải có thật)
anomaly:                   # ANOM-xxx nếu type: fix
protocols:                 # can, ethercat, spi, i2c, uart, usb, ssi, biss-c, endat, ethernet → chèn skill comm-safety + proto-<x>
decisions:                 # ADR-xxx trong .ai/decisions/ được chèn nguyên văn vào prompt
level:                     # type test: unit (mặc định) | integration | hil
coverage_scope:            # file/thư mục tính coverage (bắt buộc với type: test không sửa src); trống = file thay đổi
effort: low                # low | high
skills:                    # skill Gemini bổ sung (skill theo type/platform/class/protocols đã tự động)
autofix_max:               # bỏ trống = theo config
---
## Mục tiêu
<1–3 câu>

## Files được phép
<!-- check_scope.py kiểm tra tự động: chỉ dòng "- tạo:", "- sửa:", "- xóa:" được tính; glob hoặc thư mục kết thúc '/' được phép -->
- tạo: src/<module>/<unit>.cpp, test/<module>/test_<unit>.cpp
- sửa: src/<module>/CMakeLists.txt (chỉ thêm source/test vào target có sẵn)
- chỉ đọc: include/<module>/<unit>.hpp (OWNER: lead)

## Quyết định đã chốt
- Đơn vị & kiểu: <...>
- Giới hạn / hằng số: <...>
- Context gọi: <thread nào, priority, chu kỳ / ISR>, đồng bộ bằng <...>
- Xử lý lỗi: <trả về gì, báo ai, có vào safe state không>
- Bộ nhớ: <tĩnh, kích thước>
- API OS/HAL được phép: <...>
- Giao tiếp (nếu có protocols): <khung/bảng message, CRC (width, poly, init, refin/refout, xorout, check value), counter, timeout, ngưỡng lỗi & phản ứng>

## Đặc tả hành vi
<từng hàm: input → output, lỗi>

## Tiêu chí chấp nhận
- [ ] <kiểm chứng được, gắn SRS/RCM>

## Ngoài phạm vi (KHÔNG làm)
- <...>
