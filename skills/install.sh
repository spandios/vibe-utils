#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${VIBE_SKILLS_DIR:-$DIR}"

CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

mkdir -p "$CODEX_SKILLS_DIR" "$CLAUDE_SKILLS_DIR"

installed=()
for skill_dir in "$SKILLS_DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  [ "${skill_name#*.}" != "$skill_name" ] && continue
  [ "$skill_name" = "commit-checkpoint" ] && continue
  [ -f "$skill_dir/SKILL.md" ] || continue
  rm -rf "$CODEX_SKILLS_DIR/$skill_name" "$CLAUDE_SKILLS_DIR/$skill_name"
  ln -sfn "$skill_dir" "$CODEX_SKILLS_DIR/$skill_name"
  ln -sfn "$skill_dir" "$CLAUDE_SKILLS_DIR/$skill_name"
  installed+=("$skill_name")
done

echo "설치 완료 (${#installed[@]}개 스킬):"
for name in "${installed[@]}"; do
  echo "  - $name"
done
echo ""
echo "설치 경로:"
echo "  - $CODEX_SKILLS_DIR"
echo "  - $CLAUDE_SKILLS_DIR"
echo ""
echo "외부 의존성 선설치:"
echo "  - $SKILLS_DIR/install-prereqs.sh --dry-run"
