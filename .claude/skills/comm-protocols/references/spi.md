# SPI

## Đặc điểm cần nhớ
- Full-duplex, master phát SCLK; mode 0–3 (CPOL/CPHA), MSB/LSB first, word size, CS active level; timing setup/hold,
  CS-to-clock theo datasheet.
- Không có ACK/CRC ở tầng giao thức: thiết bị không trả lời vẫn đọc ra 0x00/0xFF.

## Chốt trong SDD
- Mode, tần số tối đa (tính cả trễ đường dây, isolator, level shifter), CS do phần cứng hay GPIO, bus chia sẻ & cơ chế khóa
  (không khóa trong ISR).
- Polling / IRQ / DMA — ISR & DMA (cache coherency, buffer alignment) do Lead viết; Gemini viết lớp logic trên HAL.
- Phát hiện lỗi: CRC/parity của thiết bị (bật nếu có), đọc ID lúc init, read-back thanh ghi cấu hình định kỳ,
  0x00/0xFF liên tiếp = mất thiết bị, status/fault bit của chip.
- Daisy-chain: thứ tự thiết bị, độ dài khung.
- Nền tảng: MCU HAL; Linux spidev hoặc kernel driver; QNX SPI resource manager của BSP.

## Hazard điển hình
Đọc dữ liệu rác khi slave mất nguồn; cấu hình chip bị reset do brown-out không bị phát hiện; tranh chấp bus giữa thread;
DMA buffer không đồng bộ cache → dữ liệu cũ.

## Bằng chứng
Unit test với mock HAL trả 0x00/0xFF/timeout/CRC sai; trên phần cứng: ngắt nguồn slave, đo timing bằng logic analyzer.
