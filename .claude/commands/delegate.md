---
description: Giao task cho Gemini và xử lý theo exit code
argument-hint: <ID> [--resume] [--effort low|high]
allowed-tools: Bash(./scripts/delegate.sh:*), Read
---
Chạy `./scripts/delegate.sh $ARGUMENTS`, xử lý theo skill `delegate-gemini`:
0/3 → như /review · 2 → như /answer · 1 → sửa task card · 4 → đọc report, báo người dùng ngắn gọn.
