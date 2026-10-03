#!/usr/bin/env bash
# Cài / nâng cấp AI kit (repo template này) vào GỐC một repo dự án.
# Usage: scripts/install.sh <repo đích> [--upgrade] [--dry-run]
#
# Hai loại file:
#   KIT     (template sở hữu): CLAUDE.md, AGENTS.md, .claude/, .agents/ (trừ project-conventions), scripts/, .ai/templates/,
#           docs/templates/, .ai/KIT_VERSION. Upgrade: ghi đè nếu dự án chưa sửa; dự án đã sửa → ghi <file>.vsur-kit (CONFLICT).
#   PROJECT (dự án sở hữu): .ai/config.env, project-conventions, docs/* (bản làm việc), .clang-*, .editorconfig, .gitattributes.
#           Chỉ tạo khi chưa có, không bao giờ ghi đè. .gitignore: thêm dòng còn thiếu.
# Trạng thái lưu ở .ai/kit-manifest.txt (sha256 của file KIT đã cài) — commit file này cùng repo.
set -uo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DST="${1:?Usage: install.sh <repo đích> [--upgrade] [--dry-run]}"; shift
UPGRADE=0; DRY=0
while [[ $# -gt 0 ]]; do case "$1" in
  --upgrade) UPGRADE=1 ;; --dry-run) DRY=1 ;;
  *) echo "Tham số lạ: $1"; exit 1 ;; esac; shift; done

[[ -d "$DST" ]] || { echo "✖ Không có thư mục $DST"; exit 1; }
DST="$(cd "$DST" && pwd)"
[[ "$DST" == "$SRC" ]] && { echo "✖ Đích trùng template"; exit 1; }
if ! git -C "$DST" rev-parse --git-dir >/dev/null 2>&1; then echo "⚠ $DST chưa là git repo — git init trước khi dùng /delegate"
elif [[ -n "$(git -C "$DST" rev-parse --show-prefix)" ]]; then
  echo "✖ $DST không phải gốc repo ($(git -C "$DST" rev-parse --show-toplevel)) — kit phải nằm ở gốc repo"; exit 1
fi
MAN="$DST/.ai/kit-manifest.txt"
if [[ -f "$MAN" && $UPGRADE -eq 0 ]]; then echo "✖ Đã cài kit ($(cat "$DST/.ai/KIT_VERSION" 2>/dev/null)) — dùng --upgrade"; exit 1; fi
[[ ! -f "$MAN" && $UPGRADE -eq 1 ]] && echo "⚠ Không có manifest — coi như cài mới; file khác biệt sẽ thành .vsur-kit"

# Kit ≤ 2.1 (Gemini CLI) → 2.2 (Antigravity CLI): chuyển project-conventions (file DỰ ÁN) sang .agents/ trước khi cài,
# để không bị seed bằng bản baseline. File kit cũ trong .gemini/ xử lý theo manifest (REMOVED/OBSOLETE) bên dưới.
OLD_PC="$DST/.gemini/skills/project-conventions"; NEW_PC="$DST/.agents/skills/project-conventions"
if [[ -d "$OLD_PC" && ! -e "$NEW_PC" ]]; then
  echo "↻ Di chuyển project-conventions: .gemini/skills → .agents/skills (Antigravity CLI)"
  if [[ $DRY -eq 0 ]]; then
    mkdir -p "$DST/.agents/skills"
    git -C "$DST" mv .gemini/skills/project-conventions .agents/skills/project-conventions 2>/dev/null || mv "$OLD_PC" "$NEW_PC"
  fi
fi
if [[ -f "$DST/.ai/config.env" ]] && grep -q '^GEMINI_MODEL' "$DST/.ai/config.env" && ! grep -q '^AGY_MODEL' "$DST/.ai/config.env"; then
  echo "⚠ .ai/config.env còn biến GEMINI_* — script tạm ánh xạ, nhưng hãy đổi sang AGY_* (mẫu: .ai/config.env của kit) và ghim model từ 'agy models'"
fi

cd "$SRC" || exit 1
kit_files() {
  { printf '%s\n' CLAUDE.md AGENTS.md .claude/settings.json .agents/hooks.json .ai/KIT_VERSION
    find .claude/agents .claude/commands .claude/skills scripts .ai/templates docs/templates .agents/workflows .agents/hooks -type f
    find .agents/skills -type f -not -path '.agents/skills/project-conventions/*'
  } | grep -vE '__pycache__|\.pyc$|^scripts/install\.sh$' | sort -u
}
seed_files() {
  { printf '%s\n' .ai/config.env .clang-format .clang-tidy .editorconfig .gitattributes docs/07-verification/records/.gitkeep
    find .agents/skills/project-conventions -type f
    find docs -type f -not -path 'docs/templates/*' -not -path 'docs/07-verification/records/*'
    find .ai -name .gitkeep
    find .ai/decisions -type f -name 'ADR-*.md'
  } | sort -u
}
# sha chạy trong $(...) → exit chỉ thoát subshell; dùng sha_of để dừng thật ở shell chính
sha() { local out; out="$(sha256sum "$1")" || return 1; out="${out%% *}"; [[ ${#out} -eq 64 ]] || return 1; echo "$out"; }
sha_of() { local v; v="$(sha "$1")" || { echo "✖ Không tính được SHA-256: $1" >&2; exit 1; }; printf -v "$2" '%s' "$v"; }
man_get() { [[ -f "$MAN" ]] && awk -v p="$1" '$2==p {print $1; exit}' "$MAN"; }
put() {
  [[ $DRY -eq 1 ]] && return 0
  mkdir -p "$(dirname "$2")" || { echo "✖ Không tạo được thư mục cho $2" >&2; exit 1; }
  cp -p "$1" "$2" || { echo "✖ Không sao chép được $1 → $2" >&2; exit 1; }
}

NEWMAN="$(mktemp)"; declare -A CNT; LOG=()
note() { CNT[$1]=$(( ${CNT[$1]:-0} + 1 )); [[ "$1" == SAME ]] || LOG+=("$1  $2"); }
KIT_LIST="$(kit_files)"
for f in $KIT_LIST; do
  t="$DST/$f"; sha_of "$f" s_new
  if [[ ! -e "$t" ]]; then put "$f" "$t"; note NEW "$f"; echo "$s_new $f" >> "$NEWMAN"; continue; fi
  sha_of "$t" s_t; s_m="$(man_get "$f")"
  if [[ "$s_t" == "$s_new" ]]; then note SAME "$f"; echo "$s_new $f" >> "$NEWMAN"
  elif [[ -z "$s_m" ]]; then put "$f" "$t.vsur-kit"; note CONFLICT "$f (file có sẵn của dự án → xem $f.vsur-kit)"; echo "$s_new $f" >> "$NEWMAN"
  elif [[ "$s_t" == "$s_m" ]]; then put "$f" "$t"; note UPDATE "$f"; echo "$s_new $f" >> "$NEWMAN"
  elif [[ "$s_new" == "$s_m" ]]; then note LOCAL "$f (dự án đã sửa, kit không đổi — giữ nguyên)"; echo "$s_m $f" >> "$NEWMAN"
  else put "$f" "$t.vsur-kit"; note CONFLICT "$f (cả dự án và kit đều đổi → gộp $f.vsur-kit)"; echo "$s_new $f" >> "$NEWMAN"
  fi
done
# File kit cũ không còn trong kit mới
if [[ -f "$MAN" ]]; then
  while read -r s p; do
    grep -qxF "$p" <<<"$KIT_LIST" && continue
    if [[ -f "$DST/$p" ]] && sha_of "$DST/$p" s_old && [[ "$s_old" == "$s" ]]; then [[ $DRY -eq 0 ]] && rm -f "$DST/$p"; note REMOVED "$p"
    elif [[ -f "$DST/$p" ]]; then note OBSOLETE "$p (kit đã bỏ, dự án đã sửa — tự quyết xóa/giữ)"; fi
  done < "$MAN"
fi
for f in $(seed_files); do
  [[ -e "$DST/$f" ]] && continue; put "$f" "$DST/$f"; note SEED "$f"
done
# config.env là file dự án (không ghi đè) → báo khóa mới của kit mà dự án chưa có
if [[ -f "$DST/.ai/config.env" ]]; then
  for k in $(grep -oE '^[A-Z_][A-Z0-9_]*=' .ai/config.env | tr -d '=' | sort -u); do
    grep -qE "^$k=" "$DST/.ai/config.env" || note CONFIGKEY "$k (kit có, .ai/config.env dự án chưa có — thêm thủ công)"
  done
fi
# .gitignore: thêm dòng còn thiếu
touch_gi=0
while read -r line; do
  [[ -z "$line" ]] && continue
  grep -qxF "$line" "$DST/.gitignore" 2>/dev/null && continue
  [[ $DRY -eq 0 ]] && echo "$line" >> "$DST/.gitignore"; touch_gi=1
done < .gitignore
(( touch_gi )) && note GITIGNORE ".gitignore (thêm dòng còn thiếu)"

if [[ $DRY -eq 0 ]]; then mkdir -p "$DST/.ai"; sort -k2 "$NEWMAN" > "$MAN"; fi
rm -f "$NEWMAN"

echo "== AI kit $(cat .ai/KIT_VERSION) → $DST $([[ $DRY -eq 1 ]] && echo '(DRY-RUN, không ghi gì)')"
for k in NEW UPDATE SEED REMOVED LOCAL OBSOLETE CONFLICT CONFIGKEY GITIGNORE SAME; do [[ -n "${CNT[$k]:-}" ]] && printf '  %-9s %s\n' "$k" "${CNT[$k]}"; done
printf '%s\n' "${LOG[@]}" | grep -E '^(CONFLICT|OBSOLETE|REMOVED|LOCAL|CONFIGKEY)' | head -40 || true
if [[ -n "${CNT[CONFLICT]:-}" ]]; then echo "⚠ Gộp các file .vsur-kit vào file tương ứng rồi xóa .vsur-kit trước khi commit."; fi
if [[ $UPGRADE -eq 0 ]]; then cat <<'EOF'
Bước tiếp theo trong repo đích:
  1. Sửa .ai/config.env (PYTHON, BUILD_CMD_*, AGY_MODEL_LOW/HIGH từ `agy models`, SIGNOFF_MODE...); cài agy và đăng nhập (README §Cài đặt)
  2. Rà ADR-001 / project-conventions (baseline đã chốt), điền docs/03-architecture/context-brief.md;
     tạo nền common core: /design common-core → copy .ai/templates/bootstrap-T000.md thành .ai/tasks/T000.md → /lead T000
  3. Xóa dòng ví dụ trong docs/ (SRS-041, SI-012, SYS-010...) khi bắt đầu dự án thật
  4. git config core.hooksPath scripts/git-hooks
  5. git add -A && git add --chmod=+x scripts/*.sh scripts/*.py scripts/hooks/* scripts/git-hooks/*
     git commit -m "chore(ai-kit): install AI kit"
EOF
else echo "Tiếp: chạy lại e2e/pilot nhỏ, rồi git commit -m \"chore(ai-kit): upgrade to $(cat .ai/KIT_VERSION)\" (thay đổi công cụ → đánh giá tái validate, docs/01-plan §3)"; fi
