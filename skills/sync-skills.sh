#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${VIBE_SKILLS_DIR:-$DIR}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
OPENCODE_SKILLS_DIR="${OPENCODE_SKILLS_DIR:-}"
MARKETPLACES_DIR="${MARKETPLACES_DIR:-$HOME/.claude/plugins/marketplaces}"

usage() {
  cat <<'EOF'
Usage:
  sync-skills.sh scan
  sync-skills.sh import --all
  sync-skills.sh import <skill-name> [skill-name...]
  sync-skills.sh install

Environment overrides:
  VIBE_SKILLS_DIR
  CLAUDE_SKILLS_DIR
  CODEX_SKILLS_DIR
  OPENCODE_SKILLS_DIR
  MARKETPLACES_DIR
EOF
}

is_hidden_name() {
  local name="$1"
  [[ "${name#*.}" != "$name" ]]
}

is_valid_source_skill_dir() {
  local skill_dir="$1"
  local skill_name
  [ -d "$skill_dir" ] || return 1
  [ -f "$skill_dir/SKILL.md" ] || return 1
  skill_name="$(basename "$skill_dir")"
  is_hidden_name "$skill_name" && return 1
  [ "$skill_name" = ".system" ] && return 1
  return 0
}

is_repo_skill_dir() {
  local skill_dir="$1"
  local skill_name
  [ -d "$skill_dir" ] || return 1
  [ -f "$skill_dir/SKILL.md" ] || return 1
  skill_name="$(basename "$skill_dir")"
  is_hidden_name "$skill_name" && return 1
  [ "$skill_name" = "commit-checkpoint" ] && return 1
  return 0
}

resolve_dir() {
  local path="$1"
  (cd "$path" && pwd -P)
}

cleanup_imported_skill() {
  local skill_dir="$1"
  [ -d "$skill_dir" ] || return 0

  find "$skill_dir" -name '.DS_Store' -type f -exec unlink {} \;
  find "$skill_dir" -type l -mindepth 1 -exec unlink {} \;
}

repo_has_skill() {
  local skill_name="$1"
  [ -f "$SKILLS_DIR/$skill_name/SKILL.md" ]
}

print_marketplace_candidates() {
  [ -d "$MARKETPLACES_DIR" ] || return 0
  local skill_md skill_dir skill_name rel repo_name
  while IFS= read -r -d '' skill_md; do
    skill_dir="$(dirname "$skill_md")"
    skill_name="$(basename "$skill_dir")"
    is_hidden_name "$skill_name" && continue
    [ "$skill_name" = ".system" ] && continue
    repo_has_skill "$skill_name" && continue
    rel="${skill_dir#"$MARKETPLACES_DIR"/}"
    repo_name="${rel%%/*}"
    printf '%s\t%s\t%s\n' "marketplace:$repo_name" "$skill_name" "$skill_dir"
  done < <(find "$MARKETPLACES_DIR" -name 'SKILL.md' -not -path '*/.git/*' -print0)
}

find_marketplace_candidate_path() {
  local wanted_name="$1"
  [ -d "$MARKETPLACES_DIR" ] || return 1
  local skill_md skill_dir skill_name rel repo_name
  while IFS= read -r -d '' skill_md; do
    skill_dir="$(dirname "$skill_md")"
    skill_name="$(basename "$skill_dir")"
    [ "$skill_name" = "$wanted_name" ] || continue
    is_hidden_name "$skill_name" && continue
    rel="${skill_dir#"$MARKETPLACES_DIR"/}"
    repo_name="${rel%%/*}"
    printf '%s\t%s\n' "marketplace:$repo_name" "$skill_dir"
    return 0
  done < <(find "$MARKETPLACES_DIR" -name 'SKILL.md' -not -path '*/.git/*' -print0)
  return 1
}

collect_all_candidates() {
  print_candidates claude "$CLAUDE_SKILLS_DIR" codex "$CODEX_SKILLS_DIR" opencode "$OPENCODE_SKILLS_DIR"
  print_marketplace_candidates
}

print_candidates() {
  local source_name source_root skill_dir skill_name
  while [ "$#" -gt 1 ]; do
    source_name="$1"
    source_root="$2"
    shift 2
    [ -d "$source_root" ] || continue
    for skill_dir in "$source_root"/*/; do
      is_valid_source_skill_dir "$skill_dir" || continue
      skill_name="$(basename "$skill_dir")"
      repo_has_skill "$skill_name" && continue
      printf '%s\t%s\t%s\n' "$source_name" "$skill_name" "$(resolve_dir "$skill_dir")"
    done
  done
}

scan_command() {
  local output
  output="$(collect_all_candidates)"
  if [ -z "$output" ]; then
    echo "vibe-utils/skills에 없는 외부 스킬 없음"
    return 0
  fi

  while IFS=$'\t' read -r source_name skill_name skill_path; do
    echo "[$source_name] $skill_name <- $skill_path"
  done <<<"$output"
}

find_candidate_path() {
  local wanted_name="$1"
  local source_name source_root skill_dir skill_name
  shift
  while [ "$#" -gt 1 ]; do
    source_name="$1"
    source_root="$2"
    shift 2
    [ -d "$source_root" ] || continue
    for skill_dir in "$source_root"/*/; do
      is_valid_source_skill_dir "$skill_dir" || continue
      skill_name="$(basename "$skill_dir")"
      [ "$skill_name" = "$wanted_name" ] || continue
      printf '%s\t%s\n' "$source_name" "$(resolve_dir "$skill_dir")"
      return 0
    done
  done
  return 1
}

import_one() {
  local skill_name="$1"
  local candidate source_name source_path

  if repo_has_skill "$skill_name"; then
    echo "skip: 이미 존재함 ($skill_name)"
    return 0
  fi

  candidate="$(find_candidate_path "$skill_name" claude "$CLAUDE_SKILLS_DIR" codex "$CODEX_SKILLS_DIR" opencode "$OPENCODE_SKILLS_DIR")" || \
  candidate="$(find_marketplace_candidate_path "$skill_name")" || {
    echo "error: 외부에서 찾지 못함 ($skill_name)" >&2
    return 1
  }

  IFS=$'\t' read -r source_name source_path <<<"$candidate"
  cp -R "$source_path" "$SKILLS_DIR/$skill_name"
  cleanup_imported_skill "$SKILLS_DIR/$skill_name"
  echo "imported: $skill_name <- [$source_name] $source_path"
}

import_all() {
  local output imported_any=0
  output="$(collect_all_candidates)"
  if [ -z "$output" ]; then
    echo "import할 외부 스킬 없음"
    return 0
  fi

  while IFS=$'\t' read -r _source_name skill_name _skill_path; do
    import_one "$skill_name"
    imported_any=1
  done <<<"$output"

  [ "$imported_any" -eq 1 ]
}

import_command() {
  local arg
  [ "$#" -gt 0 ] || {
    usage
    return 1
  }

  if [ "$1" = "--all" ]; then
    shift
    [ "$#" -eq 0 ] || {
      echo "error: --all 과 skill 이름을 함께 쓸 수 없음" >&2
      return 1
    }
    import_all
    return 0
  fi

  for arg in "$@"; do
    import_one "$arg"
  done
}

install_command() {
  VIBE_SKILLS_DIR="$SKILLS_DIR" \
  CLAUDE_SKILLS_DIR="$CLAUDE_SKILLS_DIR" \
  CODEX_SKILLS_DIR="$CODEX_SKILLS_DIR" \
  bash "$DIR/install.sh"
}

command_name="${1:-}"
[ -n "$command_name" ] || {
  usage
  exit 1
}
shift || true

case "$command_name" in
  scan)
    scan_command "$@"
    ;;
  import)
    import_command "$@"
    ;;
  install)
    install_command "$@"
    ;;
  *)
    usage
    exit 1
    ;;
esac
