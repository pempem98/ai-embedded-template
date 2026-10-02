# BiSS-C (giao thức mở của iC-Haus)

## Đặc điểm cần nhớ
- Master phát MA (clock), slave trả SL. Khung: Ack (đo & bù trễ đường dây tự động) → Start bit → CDS → dữ liệu vị trí
  (single cycle data) → bit Error (nE) & Warning (nW), active-low → CRC → timeout (slave đưa SL về idle).
- CRC thường 6 bit, đa thức 0x43 (x⁶+x+1), truyền dạng đảo — nhưng độ dài/đa thức/vị trí bit phụ thuộc encoder:
  lấy từ datasheet, không giả định.
- Register communication qua bit CDM (master gửi) / CDS (slave trả), mỗi khung 1 bit → đọc/ghi 1 thanh ghi cần nhiều khung.
- Clock tới khoảng 10 MHz; point-to-point hoặc bus nhiều slave.

## Chốt trong SDD
Cấu hình khung (bit ST/MT, nE/nW, CRC), tần số MA, timeout; master thực hiện bằng IP FPGA / peripheral MCU / IC (vd. iC-MB4)
— là SOUP/phần cứng cần quản lý; chu kỳ đọc; phản ứng khi CRC sai N lần liên tiếp, nE active, nW active, không thấy start bit.
Có dùng BiSS Safety profile không — khi đó theo safety manual của encoder (task research).

## Hazard điển hình
Dùng vị trí khi CRC sai hoặc nE active; bỏ qua nW (nhiễm bẩn, nhiệt độ, pin multi-turn yếu); không kiểm tra timeout → treo;
register access xen giữa làm trễ chu kỳ điều khiển.

## Bằng chứng
Vector CRC từ datasheet; inject CRC sai, nE/nW, mất start bit; đo latency đọc trên phần cứng đích.
