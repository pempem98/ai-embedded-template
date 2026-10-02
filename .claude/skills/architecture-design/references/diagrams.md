# Quy ước sơ đồ kiến trúc (Mermaid)

## Quy tắc
- Mỗi sơ đồ: tiêu đề `FIG-<tài liệu>-nn — <tên>`, chú thích 1–2 câu, legend nếu dùng màu/kiểu đường.
- Tên node = ID + tên ngắn khớp bảng (`SI012[SI-012 Velocity limiter]`). Không có phần tử nào không có trong bảng của tài liệu.
- ≤ ~25 phần tử mỗi sơ đồ; nhiều hơn → tách theo subsystem.
- Màu theo safety class (dùng thống nhất mọi tài liệu): C đỏ, B cam, A xanh, HW/SOUP xám.
- Mũi tên có nhãn: interface ID + giao thức/chu kỳ (`IF-03 EtherCAT 4 kHz`).
- Nộp hồ sơ: xuất SVG/PDF bằng mermaid-cli (`mmdc -i SAD.md -o out/`) — công cụ ghi vào danh sách tool; nếu công ty dùng
  Enterprise Architect/Cameo (SysML), sơ đồ gốc ở công cụ đó, markdown nhúng ảnh xuất + ghi phiên bản model.

```
classDef clsC fill:#fde2e2,stroke:#b42318,stroke-width:2px,color:#000;
classDef clsB fill:#fff1db,stroke:#b54708,color:#000;
classDef clsA fill:#e3f2e8,stroke:#067647,color:#000;
classDef ext  fill:#eeeeee,stroke:#666,stroke-dasharray: 4 3,color:#000;
```

## Context (SyAD/SAD)
```mermaid
flowchart LR
  surgeon([Phẫu thuật viên]) -->|thao tác tay, pedal| SYS[Hệ thống robot]
  staff([Nhân viên phòng mổ]) -->|setup, dụng cụ| SYS
  SYS -->|chuyển động dụng cụ| patient([Bệnh nhân])
  SYS <-->|video, log, cập nhật| net[(Mạng bệnh viện)]
  classDef ext fill:#eeeeee,stroke:#666,stroke-dasharray: 4 3,color:#000;
  class surgeon,staff,patient,net ext
```

## Decomposition + interface (SAD)
```mermaid
flowchart TB
  subgraph console[Surgeon console]
    SI001[SI-001 Master input]:::clsC
    SI002[SI-002 UI]:::clsB
  end
  subgraph cart[Patient cart]
    SI010[SI-010 Teleop & kinematics]:::clsC
    SI012[SI-012 Velocity limiter]:::clsC
    SI020[SI-020 Safety supervisor]:::clsC
  end
  SI001 -->|IF-01 UDP+E2E 1 kHz| SI010
  SI010 -->|IF-02 call| SI012
  SI012 -->|IF-03 EtherCAT CSP 4 kHz| drives[(Joint drives)]:::ext
  SI020 -.->|IF-04 heartbeat 1 ms| SI010
  classDef clsC fill:#fde2e2,stroke:#b42318,stroke-width:2px,color:#000;
  classDef clsB fill:#fff1db,stroke:#b54708,color:#000;
  classDef ext fill:#eeeeee,stroke:#666,stroke-dasharray: 4 3,color:#000;
```

## Deployment
```mermaid
flowchart TB
  subgraph n1[Node: Cart controller — x86/ARM, QNX OS for Safety]
    subgraph p1[Process teleop — partition RT 60%]
      t1[thread ctrl 4 kHz prio 60 core 2]
    end
    subgraph p2[Process supervisor — partition SAFE 20%]
      t2[thread monitor 1 kHz prio 70 core 3]
    end
  end
  subgraph n2[Node: Safety MCU — Cortex-R, bare metal]
    t3[SI-021 watchdog & STO]
  end
  t2 -->|IF-05 SPI + CRC| t3
```

## Dynamic (luồng chính + đường lỗi)
```mermaid
sequenceDiagram
  participant M as SI-001 Master
  participant T as SI-010 Teleop
  participant L as SI-012 Limiter
  participant S as SI-020 Supervisor
  M->>T: cmd(seq, ts, crc) 1 kHz
  T->>T: kiểm CRC/seq/tuổi
  T->>L: clamp_velocity(cmd)
  L-->>T: cmd_limited, flags
  alt mất 3 chu kỳ liên tiếp
    T->>S: fault(COMM_LOSS)
    S->>T: enter_safe_state(HOLD)
  end
```

## State / mode
```mermaid
stateDiagram-v2
  [*] --> SelfTest
  SelfTest --> Standby: pass
  SelfTest --> Fault: fail
  Standby --> Teleop: clutch engaged & homed
  Teleop --> Hold: clutch released / comm loss
  Hold --> Teleop: clutch engaged
  Teleop --> Fault: supervisor trip
  Hold --> Fault: supervisor trip
  Fault --> [*]: power cycle
```

## Data flow & trust boundary (threat model)
```mermaid
flowchart LR
  subgraph trusted[Biên tin cậy: mạng điều khiển cô lập]
    C[Console] -->|teleop E2E| K[Cart]
  end
  subgraph dmz[Biên: dịch vụ]
    G[Service gateway]
  end
  H[(Mạng bệnh viện)] -->|TLS, xác thực| G
  G -->|cập nhật ký số| K
```
