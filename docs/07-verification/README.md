# Verification
- `records/<ID>/` — tự sinh bởi scripts/merge.sh (AI không được sửa): task.md, review.md (có REVIEWED_SHA + chữ ký kỹ sư),
  worker-report.md, questions.md/answers.md, cross-review.md, gate-output.txt (lần chạy của delegate/lead),
  merge-checks.txt (scope + gate + trace chạy lại lúc merge), provenance.txt (base/head/merge SHA, commit theo tác giả,
  phiên bản CLI/model), rounds.txt, metrics.csv.
- Integration test (§5.6): `integration-plan.md` (lệnh /integrate, skill integration-test); system test (§5.7),
  latency/timing test trên phần cứng đích: thêm spec/report theo template.
