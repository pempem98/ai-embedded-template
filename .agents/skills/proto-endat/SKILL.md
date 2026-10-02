---
name: proto-endat
description: Implement đọc encoder EnDat 2.2 (mode command, bit lỗi, CRC, additional info) qua master IP/IC. Áp dụng khi protocols có endat.
---
# EnDat 2.2
- Mode command, số bit vị trí, additional information được bật, tần số clock, bù trễ đường dây: đúng task card
  (tham số từ spec Heidenhain / datasheet encoder, qua task research).
- Master IP/IC theo task card (có thể là SOUP của nhà sản xuất) — bạn viết lớp logic, không đổi cấu hình master.
- Mỗi khung: trạng thái master/timeout → CRC → bit lỗi → alarm/warning trong additional info (nếu bật) → plausibility.
  Lỗi → KHÔNG dùng vị trí, trả lỗi + counter.
- Đọc/ghi tham số encoder (memory area) chỉ ngoài đường RT, có timeout, theo task card.
- Ứng dụng an toàn với EnDat functional safety: chỉ dùng hai giá trị vị trí & cơ chế so sánh theo safety manual mà task card tóm tắt.
- Test: vector CRC, bit lỗi, alarm/warning, timeout, nhảy vị trí, wrap.
