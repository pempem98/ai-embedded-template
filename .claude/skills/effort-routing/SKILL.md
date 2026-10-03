---
name: effort-routing
description: Chọn effort low/high cho Gemini (model, độ kỹ) và Claude (model, reviewer, mức suy nghĩ), gắn với safety class. Dùng khi viết task card, chọn reviewer, hoặc cân nhắc mức công sức.
---
# Quy tắc
- **safety_class C → luôn HIGH** (delegate.sh ép), reviewer high + fw-safety-assessor.
- HIGH nếu có bất kỳ: dữ liệu chia sẻ ISR/thread, RT loop, IPC/protocol, parse dữ liệu bên ngoài, flash/boot/update,
  số học dễ tràn/fixed-point/kinematics, task đã REJECT ≥ 2 lần, `protocols:` thuộc đường điều khiển (ethercat, can, canopen, dds, biss-c, endat, ssi), đồng bộ/đa tần số/state machine phân tán
  hoặc nhận dữ liệu từ ngoài thiết bị (usb, ethernet, uart dịch vụ).
- owner: lead → luôn reviewer high + fw-safety-assessor + cross-review (Gemini HIGH).
- Dùng `.ai/metrics.csv` (/retro) để chỉnh: loại task low hay bị exit 3 / REWORK → nâng high.
- LOW: Class A, glue code, logging non-RT, tool, research, soạn nháp tài liệu, test cho code đã ổn định.

| | LOW | HIGH |
|---|---|---|
| Gemini (agy) | AGY_MODEL_LOW (slug gồm mức suy luận) + skill effort-low | AGY_MODEL_HIGH + skill effort-high |
| Claude review | fw-reviewer-low | fw-reviewer-high (+ fw-safety-assessor nếu C hoặc có RCM) |
| Claude thiết kế | bình thường | model mạnh nhất + "think hard"/ultrathink (hoặc mức effort cao nếu Claude Code hỗ trợ) |
| Tài liệu | reg-doc-reviewer | reg-doc-reviewer + bạn đọc phần thay đổi |
