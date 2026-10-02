# Hàm dùng chung cho delegate.sh / lead.sh / cross-review.sh / merge.sh / abort.sh.
# Chỉ source (sau khi đã đặt biến ID), không chạy trực tiếp.
# Nguyên tắc: worktree là vùng KHÔNG tin cậy (Gemini ghi được) → mọi kiểm tra dùng script & config của ROOT.
ROOT="$(git rev-parse --show-toplevel)" || { echo "✖ Không phải git repo"; exit 1; }
cd "$ROOT" || exit 1
# shellcheck disable=SC1091
source .ai/config.env
TASK=".ai/tasks/$ID.md"; WT="$(dirname "$ROOT")/wt-$ID"; BR="task/$ID"; BASEREF="refs/ai/base/$ID"
MAX_REWORK="${MAX_REWORK:-3}"

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
