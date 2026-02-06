#!/usr/bin/env bash

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

on_error() {
  local exit_code=$?
  log "❌ FAILED (exit=$exit_code) at line $1"
  log "   script: $0"
  log "   config: ${CONFIG_FILE:-unknown}"
  log "   project: ${name:-unknown}"
  exit "$exit_code"
}
trap 'on_error $LINENO' ERR
set -euo pipefail

DEFAULT_OUTPUT_DIR="output/agents-review"
DEFAULT_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/agents-doc-review"
DEFAULT_CONFIG_FILE="automation/agents_doc_reviewer/agents_review_projects.json"

CONFIG_FILE="$DEFAULT_CONFIG_FILE"
OUTPUT_ROOT="$DEFAULT_OUTPUT_DIR"
STATE_DIR="$DEFAULT_STATE_DIR"
FORCE="false"
DRY_RUN="false"
OPEN_EDITOR="false"
AI_REVIEW="true"
AI_MODEL=""
SINGLE_PROJECT=""

print_help() {
  cat <<'EOF'
Usage:
  scripts/agents_doc_review.sh [options]

Options:
  --config <file>       JSON config file (default: scripts/agents_review_projects.json)
  --output-dir <dir>    Report output root (default: output/agents-review)
  --state-dir <dir>     Review state dir (default: $XDG_STATE_HOME/agents-doc-review)
  --project <name>      Run only for a specific project (by name)
  --force               Run even when interval is not due
  --dry-run             Do not write state files
  --open-editor         Open target docs with $EDITOR after report generation
  --no-ai               Skip AI review suggestions (enabled by default)
  --ai-model <m>        ai-call model override (default: ai-call's default)
  --help                Show this help

Config format (JSON):
  {
    "defaults": {
      "interval_days": 21,
      "docs": ["CLAUDE.md", "AGENTS.md"]
    },
    "projects": [
      {
        "name": "my-project",
        "path": "/absolute/path/to/repo",
        "interval_days": 14,       // optional, overrides default
        "docs": ["CLAUDE.md"]      // optional, overrides default
      }
    ]
  }
EOF
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

epoch_to_local() {
  local epoch="$1"
  if [[ "$epoch" -le 0 ]]; then
    printf 'N/A'
    return
  fi
  date -r "$epoch" "+%Y-%m-%d %H:%M:%S %z"
}

ai_call_cmd() {
  # ai-call wrapper: ai_call_cmd "prompt" > output
  local model_args=()
  if [[ -n "$AI_MODEL" ]]; then
    model_args=(-m "$AI_MODEL")
  fi
  ai-call "${model_args[@]}" "$1"
}

run_ai_review() {
  local project_name="$1"
  local project_path="$2"
  local report_file="$3"
  local suggestion_file="$4"
  shift 4
  local doc_paths=("$@")

  if ! command -v ai-call >/dev/null 2>&1; then
    log "  [ai] ai-call not found, skipping review."
    return 1
  fi

  local context=""
  context+="$(cat "$report_file")"
  context+=$'\n\n'

  for dp in "${doc_paths[@]}"; do
    if [[ -f "$dp" ]]; then
      local bn
      bn="$(basename "$dp")"
      context+="--- Current $bn ---"$'\n'
      context+="$(cat "$dp")"
      context+=$'\n\n'
    fi
  done

  local full_prompt
  full_prompt="CLAUDE.md/AGENTS.md 리뷰. 한국어로 짧게 답변.

규칙:
- CLAUDE.md/AGENTS.md는 매 대화 시스템 프롬프트에 로드됨 → 간결해야 함
- 코드 예시는 docs/로 분리, 여기엔 규칙만
- build/test/lint 명령어는 유지

출력 형식 (bullet만, 설명 최소화):
## 요약
(2-3줄)

## 변경 제안
각 항목을 아래 형식으로:
- [추가/수정/삭제] \`파일명\`: 내용 (1줄)

변경 없으면 \"변경 없음\" 한 줄만.

${context}"

  log "  [ai] Generating review suggestions for $project_name ($(ai-call --name)) ..."

  ai_call_cmd "$full_prompt" > "$suggestion_file" 2>/dev/null

  if [[ $? -eq 0 && -s "$suggestion_file" ]]; then
    log "  [ai] Suggestions saved: $suggestion_file"
    return 0
  else
    log "  [ai] Failed to generate suggestions."
    return 1
  fi
}

generate_applied_doc() {
  local doc_path="$1"
  local suggestion_file="$2"
  local output_file="$3"

  if [[ ! -f "$doc_path" || ! -s "$suggestion_file" ]]; then
    return 1
  fi

  local doc_name
  doc_name="$(basename "$doc_path")"
  local doc_content
  doc_content="$(cat "$doc_path")"
  local suggestion_content
  suggestion_content="$(cat "$suggestion_file")"

  local apply_prompt="아래는 현재 ${doc_name} 파일과 리뷰 제안이다.
제안을 모두 반영하여 업데이트된 ${doc_name} 전체 내용을 출력하라.

규칙:
- 마크다운 원본 형식 유지
- 제안된 추가/수정/삭제만 반영
- 설명, 주석, 메타 텍스트 없이 문서 내용만 출력
- 변경 없음이면 원본 그대로 출력

--- 현재 ${doc_name} ---
${doc_content}

--- 리뷰 제안 ---
${suggestion_content}

위 제안을 반영한 ${doc_name} 전체 내용:"

  log "  [ai] Generating applied ${doc_name} ..."

  ai_call_cmd "$apply_prompt" > "$output_file" 2>/dev/null

  if [[ $? -eq 0 && -s "$output_file" ]]; then
    log "  [ai] Applied doc saved: $output_file"
    return 0
  else
    log "  [ai] Failed to generate applied ${doc_name}."
    return 1
  fi
}

# --- Parse CLI args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)       CONFIG_FILE="${2:-}"; shift 2 ;;
    --output-dir)   OUTPUT_ROOT="${2:-}"; shift 2 ;;
    --state-dir)    STATE_DIR="${2:-}"; shift 2 ;;
    --project)      SINGLE_PROJECT="${2:-}"; shift 2 ;;
    --force)        FORCE="true"; shift ;;
    --dry-run)      DRY_RUN="true"; shift ;;
    --open-editor)  OPEN_EDITOR="true"; shift ;;
    --ai)           AI_REVIEW="true"; shift ;;
    --no-ai)        AI_REVIEW="false"; shift ;;
    --ai-model)     AI_MODEL="${2:-}"; shift 2 ;;
    --claude|--no-claude|--claude-model)  # backward compat: silently map
      case "$1" in
        --claude)       AI_REVIEW="true"; shift ;;
        --no-claude)    AI_REVIEW="false"; shift ;;
        --claude-model) AI_MODEL="${2:-}"; shift 2 ;;
      esac ;;
    --help)         print_help; exit 0 ;;
    *)              echo "Unknown option: $1" >&2; print_help; exit 1 ;;
  esac
done

# --- Validate ---
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file not found: $CONFIG_FILE" >&2
  echo "Copy and edit: scripts/agents_review_projects.example.json" >&2
  exit 1
fi

for cmd in git jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required." >&2
    exit 1
  fi
done

if [[ "$OPEN_EDITOR" == "true" ]] && [[ -z "${EDITOR:-}" ]]; then
  echo "Set \$EDITOR before using --open-editor." >&2
  exit 1
fi

# --- Parse JSON config ---
default_interval="$(jq -r '.defaults.interval_days // 21' "$CONFIG_FILE")"
default_docs="$(jq -r '(.defaults.docs // ["CLAUDE.md","AGENTS.md"]) | join(",")' "$CONFIG_FILE")"
project_count="$(jq '.projects | length' "$CONFIG_FILE")"

if [[ "$project_count" -eq 0 ]]; then
  echo "No projects defined in $CONFIG_FILE" >&2
  exit 1
fi

# --- Setup output ---
mkdir -p "$STATE_DIR"
run_ts="$(date +%Y%m%d-%H%M%S)"
run_dir="$OUTPUT_ROOT/$run_ts"
mkdir -p "$run_dir"

reviewed_count=0
skipped_count=0
ai_count=0
now_epoch="$(date +%s)"

# --- Iterate projects ---
for i in $(seq 0 $((project_count - 1))); do
  name="$(jq -r ".projects[$i].name" "$CONFIG_FILE")"
  project_path="$(jq -r ".projects[$i].path" "$CONFIG_FILE")"
  interval_days="$(jq -r ".projects[$i].interval_days // $default_interval" "$CONFIG_FILE")"
  docs_csv="$(jq -r "(.projects[$i].docs // [$(printf '"%s",' ${default_docs//,/\",\"} | sed 's/,$//') ]) | join(\",\")" "$CONFIG_FILE" 2>/dev/null || echo "$default_docs")"

  # --project filter
  if [[ -n "$SINGLE_PROJECT" && "$name" != "$SINGLE_PROJECT" ]]; then
    continue
  fi

  if [[ -z "$name" || "$name" == "null" || -z "$project_path" || "$project_path" == "null" ]]; then
    echo "Skipping project index $i: missing name or path." >&2
    continue
  fi

  if [[ ! -d "$project_path" ]]; then
    echo "Skipping $name: path not found ($project_path)." >&2
    continue
  fi
  if ! git -C "$project_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Skipping $name: not a git repository ($project_path)." >&2
    continue
  fi

  slug="$(slugify "$name")"
  state_file="$STATE_DIR/$slug.last_review_epoch"
  last_review_epoch=0
  if [[ -f "$state_file" ]]; then
    maybe_epoch="$(tr -d '[:space:]' < "$state_file" || true)"
    if [[ "$maybe_epoch" =~ ^[0-9]+$ ]]; then
      last_review_epoch="$maybe_epoch"
    fi
  fi

  min_interval_sec=$((interval_days * 86400))
  elapsed_sec=$((now_epoch - last_review_epoch))
  due="true"
  if [[ "$last_review_epoch" -gt 0 && "$elapsed_sec" -lt "$min_interval_sec" && "$FORCE" != "true" ]]; then
    due="false"
  fi

  if [[ "$due" != "true" ]]; then
    skipped_count=$((skipped_count + 1))
    next_due_epoch=$((last_review_epoch + min_interval_sec))
    log "Skipped $name (next due: $(epoch_to_local "$next_due_epoch"))"
    continue
  fi

  echo "Processing: $name ($project_path) ..."

  since_epoch="$last_review_epoch"
  if [[ "$since_epoch" -le 0 ]]; then
    since_epoch=$((now_epoch - min_interval_sec))
  fi

  report_file="$(mktemp)"
  repo_head_epoch="$(git -C "$project_path" log -1 --format=%ct 2>/dev/null || echo 0)"
  commit_count="$(git -C "$project_path" rev-list --count --since="@$since_epoch" HEAD 2>/dev/null || echo 0)"
  changed_files="$(git -C "$project_path" log --since="@$since_epoch" --name-only --pretty=format: 2>/dev/null | sed '/^$/d' | sort -u)"
  changed_file_count=0
  if [[ -n "$changed_files" ]]; then
    changed_file_count="$(printf '%s\n' "$changed_files" | wc -l | tr -d ' ')"
  fi
  recent_commits="$(git -C "$project_path" log --since="@$since_epoch" --pretty=format:'- %h | %ad | %s' --date=short -n 30 2>/dev/null)"

  {
    echo "# $name"
    echo
    echo "- project_path: $project_path"
    echo "- interval_days: $interval_days"
    echo "- review_window_start: $(epoch_to_local "$since_epoch")"
    echo "- run_at: $(epoch_to_local "$now_epoch")"
    echo "- commits_in_window: $commit_count"
    echo "- changed_files_in_window: $changed_file_count"
    echo
    echo "## Doc Status"
    echo
    echo "| doc | exists | updated_in_window | lag_days_from_head |"
    echo "|---|---|---|---|"
  } > "$report_file"

  IFS=',' read -r -a docs <<< "$docs_csv"
  docs_to_edit=()
  for doc in "${docs[@]}"; do
    doc="$(echo "$doc" | xargs)"  # trim
    [[ -z "$doc" ]] && continue

    doc_path="$project_path/$doc"
    exists="no"
    updated_in_window="no"
    lag_days="N/A"
    if [[ -f "$doc_path" ]]; then
      exists="yes"
      docs_to_edit+=("$doc_path")
      if [[ -n "$(git -C "$project_path" log --since="@$since_epoch" --oneline -1 -- "$doc" 2>/dev/null)" ]]; then
        updated_in_window="yes"
      fi
      doc_epoch="$(git -C "$project_path" log -1 --format=%ct -- "$doc" 2>/dev/null || echo 0)"
      if [[ "$doc_epoch" -gt 0 && "$repo_head_epoch" -gt 0 ]]; then
        lag_days=$(( (repo_head_epoch - doc_epoch) / 86400 ))
        [[ "$lag_days" -lt 0 ]] && lag_days=0
      fi
    fi
    echo "| $doc | $exists | $updated_in_window | $lag_days |" >> "$report_file"
  done

  {
    echo
    echo "## Changed Files (Top 100)"
    echo
    if [[ -n "$changed_files" ]]; then
      printf '%s\n' "$changed_files" | head -n 100 | sed 's/^/- /'
    else
      echo "- (no changed files in window)"
    fi
    echo
    echo "## Recent Commits (Top 30)"
    echo
    if [[ -n "$recent_commits" ]]; then
      echo "$recent_commits"
    else
      echo "- (no commits in window)"
    fi
    echo
    echo "## Review Checklist"
    echo
    echo "- [ ] Verify newly added/changed commands are reflected in docs."
    echo "- [ ] Update workflow/guardrail/policy sections."
    echo "- [ ] Remove stale instructions and dead links."
    echo "- [ ] Align CLAUDE.md and AGENTS.md on overlapping rules."
  } >> "$report_file"

  # Claude CLI review
  suggestion_file=""
  if [[ "$AI_REVIEW" == "true" ]]; then
    suggestion_file="$run_dir/${slug}-suggestions.md"
    if run_ai_review "$name" "$project_path" "$report_file" "$suggestion_file" "${docs_to_edit[@]}"; then
      ai_count=$((ai_count + 1))

      # 제안 반영된 문서 생성
      for dp in "${docs_to_edit[@]}"; do
        doc_basename="$(basename "$dp")"
        proposed_file="$run_dir/${slug}-${doc_basename%.md}.proposed.md"
        generate_applied_doc "$dp" "$suggestion_file" "$proposed_file" || true
      done
    fi
  fi

  rm -f "$report_file"

  if [[ "$OPEN_EDITOR" == "true" && "${#docs_to_edit[@]}" -gt 0 ]]; then
    "$EDITOR" "${docs_to_edit[@]}"
  fi

  if [[ "$DRY_RUN" != "true" ]]; then
    printf '%s\n' "$now_epoch" > "$state_file"
  fi

  reviewed_count=$((reviewed_count + 1))
done

log "✅ Done. reviewed=$reviewed_count skipped=$skipped_count"
if [[ "$AI_REVIEW" == "true" ]]; then
  log "   AI suggestions: $ai_count / $reviewed_count projects"
fi
log "   Output: $run_dir/"
# proposed 파일 목록 출력
for f in "$run_dir"/*.proposed.md; do
  [[ -f "$f" ]] && log "   📄 $(basename "$f")"
done
