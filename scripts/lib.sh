# Hàm dùng chung cho delegate.sh / lead.sh / cross-review.sh / merge.sh / abort.sh.
# Chỉ source (sau khi đã đặt biến ID), không chạy trực tiếp.
# Nguyên tắc: worktree là vùng KHÔNG tin cậy (AI worker ghi được) → mọi kiểm tra dùng script & config của ROOT.
ROOT="$(git rev-parse --show-toplevel)" || { echo "✖ Không phải git repo"; exit 1; }
cd "$ROOT" || exit 1
[[ "$ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] \
  || { echo "✖ ID task không hợp lệ: chỉ dùng chữ, số, '.', '_' hoặc '-'"; exit 1; }
# shellcheck disable=SC1091
source .ai/config.env
TASK=".ai/tasks/$ID.md"; WT="$(dirname "$ROOT")/wt-$ID"; BR="task/$ID"; BASEREF="refs/ai/base/$ID"
MAX_REWORK="${MAX_REWORK:-3}"
# config.env cũ (kit ≤ 2.1, Gemini CLI): ánh xạ biến GEMINI_* nếu dự án chưa đổi sang AGY_*
AGY_BIN="${AGY_BIN:-agy}"
AGY_MODEL_LOW="${AGY_MODEL_LOW:-${GEMINI_MODEL_LOW:-}}"; AGY_MODEL_HIGH="${AGY_MODEL_HIGH:-${GEMINI_MODEL_HIGH:-}}"
AGY_TIMEOUT="${AGY_TIMEOUT:-${GEMINI_TIMEOUT:-900}}"; AGY_SANDBOX="${AGY_SANDBOX:-${GEMINI_SANDBOX:-}}"

field() { grep -m1 -E "^$1:" "$TASK" 2>/dev/null | sed -E "s/^$1:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]+$//" || true; }
is_code() { [[ "$TYPE" == implement || "$TYPE" == fix || "$TYPE" == test ]]; }
strip_fm() { awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm' "$1"; }

load_task() {
  [[ -f "$TASK" ]] || { echo "✖ Không có $TASK"; exit 1; }
  TYPE="$(field type)"; TYPE="${TYPE:-implement}"
  PLATFORM="$(field platform)"; PLATFORM="${PLATFORM:-host}"
  CLASS="$(field safety_class)"; TITLE="$(field title)"
  OWNER="$(field owner)"; OWNER="${OWNER:-gemini}"
  COV_SCOPE="$(field coverage_scope | tr ',' ' ')"
}

validate_task() {
  if is_code; then
    [[ "$CLASS" =~ ^[ABC]$ ]] || { echo "✖ Task code phải có safety_class: A|B|C"; exit 1; }
    if [[ "$CLASS" != A && -z "$(field requirements)" ]]; then echo "✖ Class $CLASS phải có requirements: SRS-xxx"; exit 1; fi
    if [[ "$CLASS" == C ]]; then
      local dd; dd="$(field detailed_design)"
      [[ -n "$dd" && -f "$dd" ]] || { echo "✖ Class C bắt buộc detailed_design trỏ tới file có thật (docs/04-detailed-design/SDD-xxx.md)"; exit 1; }
    fi
  fi
  grep -q '^## Files được phép' "$TASK" || { echo "✖ Task card thiếu mục '## Files được phép' (check_scope.py cần)"; exit 1; }
}

ensure_worktree() {
  if [[ ! -d "$WT" ]]; then
    local dirty
    dirty="$(git status --porcelain -- . ':(exclude).ai' ':(exclude)docs/07-verification/records' 2>/dev/null | head -10)"
    if [[ -n "$dirty" ]]; then
      echo "⚠ Repo chính có thay đổi CHƯA commit — worktree tạo từ HEAD sẽ KHÔNG thấy (interface, SDD?):"; echo "$dirty"
    fi
    git worktree add -q "$WT" -b "$BR" 2>/dev/null || git worktree add -q "$WT" "$BR" \
      || { echo "✖ Không tạo được worktree $WT"; exit 1; }
    git rev-parse -q --verify "$BASEREF" >/dev/null || git update-ref "$BASEREF" "$(git -C "$WT" rev-parse HEAD)"
  fi
  BASE="$(git rev-parse -q --verify "$BASEREF")" \
    || { echo "✖ Thiếu $BASEREF (worktree tạo bằng bản cũ?) — ./scripts/abort.sh $ID rồi làm lại"; exit 1; }
  [[ -d "$WT/.git" || -f "$WT/.git" ]] \
    || { echo "✖ $WT không phải Git worktree hợp lệ"; exit 1; }
  actual_branch="$(git -C "$WT" symbolic-ref -q --short HEAD || true)"
  [[ "$actual_branch" == "$BR" ]] \
    || { echo "✖ Worktree $WT đang ở branch '${actual_branch:-DETACHED}', cần '$BR'"; exit 1; }
  wt_head="$(git -C "$WT" rev-parse HEAD)"
  git -C "$WT" merge-base --is-ancestor "$BASE" "$wt_head" \
    || { echo "✖ HEAD worktree không bắt nguồn từ $BASEREF — abort và tạo lại task"; exit 1; }
  mkdir -p "$WT/.ai-out" .ai/reports .ai/questions .ai/logs
}

# Commit toàn bộ thay đổi của round trong worktree. Author phân biệt AI worker / AI lead (bằng chứng nguồn gốc code).
commit_round() {  # $1 = worker|lead, $2 = status của round
  local name="${AI_WORKER_NAME:-ai-worker}" mail="${AI_WORKER_EMAIL:-ai-worker@localhost}"
  if [[ "$1" == lead ]]; then name="${AI_LEAD_NAME:-ai-lead}"; mail="${AI_LEAD_EMAIL:-ai-lead@localhost}"; fi
  local subject trailers
  subject="$(commit_subject "$(commit_type)" "$(commit_scope)" "${TITLE:-$ID} [r$(round_no)]")"
  trailers="$(commit_trailers)"$'\n'"Round: $(round_no)"$'\n'"Status: $2"$'\n'"Author-Role: $1"
  ( cd "$WT" && git -c core.safecrlf=false add -A && { git diff --cached --quiet \
      || git -c user.name="$name" -c user.email="$mail" commit -q --no-verify -m "$subject" -m "$trailers"; } )
  HEAD_SHA="$(git -C "$WT" rev-parse HEAD)"
}

# ---- Commit message theo naming-conventions: <type>(<scope>): <tóm tắt ≤72> + trailer Task/Refs/Anomaly ----
commit_type() { case "$TYPE" in implement) echo feat ;; fix) echo fix ;; test) echo test ;; *) echo docs ;; esac; }
commit_scope() { local si; si="$(field software_item | tr '[:upper:]' '[:lower:]')"; echo "${si:-$ID}"; }
commit_subject() {  # $1 type, $2 scope, $3 tóm tắt → cắt cho vừa 72 ký tự (đếm theo ký tự UTF-8)
  local LC_ALL=C.UTF-8 head="$1($2): " text="$3"; local room=$(( 72 - ${#head} ))
  (( ${#text} > room )) && text="${text:0:$(( room - 1 ))}…"
  text="${text%.}"; echo "$head$text"
}
commit_trailers() {
  local refs anom; refs="$(printf '%s, %s' "$(field requirements)" "$(field risk_controls)" | sed -E 's/^, //; s/, $//')"
  anom="$(field anomaly)"
  echo "Task: $ID"; [[ -n "$refs" ]] && echo "Refs: $refs"; [[ -n "$anom" ]] && echo "Anomaly: $anom"; return 0
}

# Scope + gate + trace bằng script/config của ROOT. In tóm tắt. Trả 0 PASS | 3 FAIL.
run_checks() {
  local rc=0
  echo "■ Scope:"
  $PYTHON "$ROOT/scripts/check_scope.py" --root "$WT" --task "$TASK" --base "$BASE" --owner "$OWNER" | tail -15 || rc=3
  if is_code; then
    echo "■ Gate (platform=$PLATFORM class=$CLASS):"
    local scope_args=(); [[ -n "$COV_SCOPE" ]] && scope_args=(--scope "$COV_SCOPE")
    ( cd "$WT" && "$ROOT/scripts/gate.sh" --platform "$PLATFORM" --class "$CLASS" --base "$BASE" "${scope_args[@]}" ) \
      > ".ai/logs/$ID.gate" 2>&1 || rc=3
    head -n $(( ${GATE_TAIL:-20} + 15 )) ".ai/logs/$ID.gate"
    if [[ "$CLASS" != A ]]; then
      echo "■ Trace:"; $PYTHON "$ROOT/scripts/trace.py" --root "$WT" --task "$TASK" | tail -12 || rc=3
    fi
  fi
  return $rc
}

round_no() { local n; n="$(grep -cE '^## Round' ".ai/answers/$ID.md" 2>/dev/null)"; echo $(( ${n:-0} + 1 )); }
rework_count() { local n; n="$(grep -cE '^## Round .*REWORK' ".ai/answers/$ID.md" 2>/dev/null)"; echo "${n:-0}"; }

# Số liệu quy trình (.ai/metrics.csv, commit cùng repo) + provenance từng round (.ai/reports/<ID>.meta).
record() {  # $1 actor, $2 status, $3 exit, $4 model
  local now; now="$(date -u +%FT%TZ)"
  [[ -f .ai/metrics.csv ]] || echo "date_utc,id,actor,type,platform,class,effort,model,round,status,exit,duration_s" > .ai/metrics.csv
  echo "$now,$ID,$1,${TYPE:-},${PLATFORM:-},${CLASS:-},${EFFORT:-},${4:-},$(round_no),$2,$3,$SECONDS" >> .ai/metrics.csv
  echo "$now round=$(round_no) actor=$1 status=$2 exit=$3 model=${4:-} tool=${TOOL_VER:-} base=${BASE:-} head=${HEAD_SHA:-}" >> ".ai/reports/$ID.meta"
}

# ---- Antigravity CLI (agy) — worker & cross-review ----
# Mô hình quyền (đã kiểm chứng với agy 1.2.15, Windows): ở chế độ -p, agy BỎ QUA permissions.allow và quyết định "allow"
# của hook (issue google-antigravity/antigravity-cli#548) → mọi lệnh shell bị soft-deny và phiên DỪNG ngay.
# Kit không dùng --dangerously-skip-permissions (tắt cả hook/deny). Thay vào đó AI KHÔNG chạy lệnh shell, và chính sách tool
# nằm TRONG REPO (không dùng ~/.gemini của từng máy): hook .agents/hooks.json → .agents/hooks/vsur_policy.py theo VSUR_AGY_ROLE:
#   worker  : --mode accept-edits — chỉ đọc/sửa file trong worktree; build/gate do delegate.sh chạy và gửi lỗi lại (resume)
#   reviewer: --mode plan         — chỉ đọc; kết quả lấy từ "response" của stream-json
# Prompt dài nằm trong file .ai-out/ của worktree (bị .gitignore) — không qua argv/stdin.
# Log dạng stream-json (--output-format) → scripts/agy_result.py lấy conversation id, status, lệnh bị chặn, response.
agy_version() { "$AGY_BIN" --version 2>/dev/null | head -1; }
agy_preflight() {  # $1 = model
  command -v "$AGY_BIN" >/dev/null 2>&1 \
    || { echo "✖ Không tìm thấy '$AGY_BIN' (Antigravity CLI) trong PATH — 'agy install' hoặc đặt AGY_BIN trong .ai/config.env"; exit 1; }
  [[ -n "$1" ]] || { echo "✖ Chưa ghim model trong .ai/config.env (AGY_MODEL_LOW/AGY_MODEL_HIGH) — chọn từ 'agy models'"; exit 1; }
}
# Hook chính sách trong worktree phải giống hệt base (worktree là vùng AI ghi được) — sai lệch → từ chối chạy.
POLICY_FILES=(.agents/hooks.json .agents/hooks scripts/check_scope.py)
agy_policy_check() {
  [[ -f "$WT/.agents/hooks.json" && -f "$WT/.agents/hooks/vsur_policy.py" ]] \
    || { echo "✖ Worktree thiếu .agents/hooks.json hoặc .agents/hooks/vsur_policy.py (kit cài chưa đủ/chưa commit)"; exit 1; }
  if ! git -C "$WT" diff --quiet "$BASE" -- "${POLICY_FILES[@]}" \
     || [[ -n "$(git -C "$WT" status --porcelain -- "${POLICY_FILES[@]}")" ]]; then
    echo "✖ Hook chính sách agy trong $WT khác base — ./scripts/abort.sh $ID"; exit 1
  fi
}
agy_field() { $PYTHON "$ROOT/scripts/agy_result.py" "$1" "$2"; }  # $1 log, $2 cid|status|denied|response
# $1 model, $2 mode accept-edits|plan, $3 log (ghi nối), $4 chỉ dẫn ngắn cho -p, $5 conversation id để resume (tùy chọn)
# Đặt AGY_RC, AGY_CID, AGY_DENIED. Bị soft-deny lệnh shell → tự resume tối đa AGY_DENY_RETRY lần với lời nhắc.
agy_run() {
  local sb=() conv=() tries=0 msg="$4" part role=worker
  [[ "$2" == plan ]] && role=reviewer
  agy_policy_check
  [[ -n "${AGY_SANDBOX:-}" ]] && sb=(--sandbox)
  [[ -n "${5:-}" ]] && conv=(--conversation "$5")
  AGY_DENIED=""
  while :; do
    part="$3.part"
    ( cd "$WT" && VSUR_AGY_ROLE="$role" timeout "$(( AGY_TIMEOUT + 30 ))" "$AGY_BIN" --model "$1" --mode "$2" "${sb[@]}" "${conv[@]}" \
        --output-format stream-json --print-timeout "${AGY_TIMEOUT}s" -p "$msg" < /dev/null ) > "$part" 2>&1
    AGY_RC=$?
    cat "$part" >> "$3"
    if [[ -s "$WT/.ai-out/hook.log" ]]; then   # bằng chứng: hành động AI bị hook vsur-policy chặn
      echo "⚠ hook vsur-policy đã chặn $(grep -c . "$WT/.ai-out/hook.log") hành động (.ai/reports/$ID.hook.log)"
      cat "$WT/.ai-out/hook.log" >> ".ai/reports/$ID.hook.log"; rm -f "$WT/.ai-out/hook.log"
    fi
    AGY_CID="$(agy_field "$part" cid)"
    local denied; denied="$(agy_field "$part" denied)"; rm -f "$part"
    [[ -z "$denied" ]] && break
    AGY_DENIED+="$denied"$'\n'
    echo "⚠ agy chặn hành động của AI: $denied"
    (( tries >= ${AGY_DENY_RETRY:-1} )) || [[ -z "$AGY_CID" ]] && break
    tries=$(( tries + 1 )); conv=(--conversation "$AGY_CID")
    msg="Hành động vừa rồi bị CHẶN ($denied): bạn KHÔNG có quyền chạy lệnh shell hay tool ngoài đọc/sửa file. Không thử lại. Tiếp tục nhiệm vụ chỉ bằng đọc/sửa file theo hướng dẫn ban đầu."
  done
  return "$AGY_RC"
}
# Phòng thủ nhiều lớp: AI không có quyền chạy lệnh, nhưng script vẫn kiểm
# HEAD và nhánh worktree phải giữ nguyên sau khi AI chạy. Trả 0 nếu nguyên vẹn hoặc đã khôi phục an toàn, 1 nếu không thể.
head_snapshot() { HEAD_BEFORE="$(git -C "$WT" rev-parse HEAD)"; BRANCH_BEFORE="$(git -C "$WT" symbolic-ref -q HEAD || echo DETACHED)"; }
head_guard() {
  local now br; now="$(git -C "$WT" rev-parse HEAD)"; br="$(git -C "$WT" symbolic-ref -q HEAD || echo DETACHED)"
  [[ "$now" == "$HEAD_BEFORE" && "$br" == "$BRANCH_BEFORE" ]] && return 0
  echo "⚠ AI đã chạy lệnh git ghi trong worktree (HEAD $HEAD_BEFORE → $now, nhánh $BRANCH_BEFORE → $br)"
  if [[ "$br" == "$BRANCH_BEFORE" ]] && git -C "$WT" merge-base --is-ancestor "$HEAD_BEFORE" "$now"; then
    git -C "$WT" reset -q --soft "$HEAD_BEFORE"   # giữ nội dung, bỏ commit của AI → script commit lại với author chuẩn
    echo "  → đã gỡ commit của AI (giữ thay đổi trong worktree); ghi nhận vi phạm trong review"; GIT_VIOLATION=1; return 0
  fi
  echo "  → không khôi phục tự động được (đổi nhánh/reset/rebase). Lead kiểm tra $WT, hoặc ./scripts/abort.sh $ID"; return 1
}
