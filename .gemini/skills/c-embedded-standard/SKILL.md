---
name: c-embedded-standard
description: Chuẩn C nhúng trên MCU (tham chiếu MISRA C:2012/2023, CERT C). Áp dụng cho mọi code C/MCU.
---
# Chuẩn code
- C11, kiểu `<stdint.h>`, `bool` từ `<stdbool.h>`. `-Wall -Wextra -Wconversion -Werror`.
- Không `malloc/free` sau init (Class B/C: không bao giờ); không VLA; không recursion; không `goto`.
- Hằng số có tên (`enum`/`static const`), hậu tố `U` cho unsigned. Không magic number.
- Biến chia sẻ ISR ↔ task: `volatile`; read-modify-write trong critical section/atomic đúng như task card chỉ định.
- ISR: ngắn, không blocking, không printf, không float nếu FPU context không được lưu; chỉ set cờ/đẩy buffer.
- Hàm public trả mã lỗi; kiểm tra NULL và miền giá trị tham số; mọi mã lỗi HAL phải được xử lý.
- Vòng chờ phần cứng luôn có timeout. Watchdog chỉ được kick ở điểm Lead chỉ định.
- Không shift trên signed; không so sánh signed/unsigned; ép kiểu tường minh khi thu hẹp.
- `static` cho mọi thứ không public. Hàm ≤ ~60 dòng, lồng ≤ 3.
- Đặt tên & định dạng: skill `naming-conventions` (mục C): `module_verb_noun()`, `module_name_t`, `MODULE_CONST`, `s_` cho static file-scope.
- Header: include guard `<MODULE>_<FILE>_H`; chỉ khai báo API public; không định nghĩa biến trong header.
