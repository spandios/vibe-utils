으#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CODEX_DIR="$HOME/.codex"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CODEX_DIR/skills" "$CLAUDE_DIR/skills"

# 스킬 디렉토리만 개별 복사 (기존 스킬 유지, 새 스킬 추가/업데이트)
installed=()
for skill_dir in "$DIR"/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name="$(basename "$skill_dir")"
  [ "$skill_name" = "commit-checkpoint" ] && continue
  cp -R "$skill_dir" "$CODEX_DIR/skills/$skill_name"
  cp -R "$skill_dir" "$CLAUDE_DIR/skills/$skill_name"
  installed+=("$skill_name")
done

echo "설치 완료 (${#installed[@]}개 스킬):"
for name in "${installed[@]}"; do
  echo "  - $name"
done
echo ""
echo "설치 경로:"
echo "  - $CODEX_DIR/skills/"
echo "  - $CLAUDE_DIR/skills/"
