#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SOURCE_COMMON="$DIR/COMMON-AGENTS.md"
SOURCE_CODEX_AGENTS="$DIR/AGENTS.md"
SOURCE_CLAUDE_MD="$DIR/CLAUDE.md"

CODEX_DIR="$HOME/.codex"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CODEX_DIR" "$CLAUDE_DIR"

if [[ -f "$SOURCE_CODEX_AGENTS" ]]; then
  cp -f "$SOURCE_CODEX_AGENTS" "$CODEX_DIR/AGENTS.md"
elif [[ -f "$SOURCE_COMMON" ]]; then
  cp -f "$SOURCE_COMMON" "$CODEX_DIR/AGENTS.md"
else
  echo "✗ 소스 파일 없음: $SOURCE_CODEX_AGENTS 또는 $SOURCE_COMMON" >&2
  exit 1
fi

if [[ -f "$SOURCE_CLAUDE_MD" ]]; then
  cp -f "$SOURCE_CLAUDE_MD" "$CLAUDE_DIR/CLAUDE.md"
elif [[ -f "$SOURCE_COMMON" ]]; then
  cp -f "$SOURCE_COMMON" "$CLAUDE_DIR/CLAUDE.md"
else
  echo "✗ 소스 파일 없음: $SOURCE_CLAUDE_MD 또는 $SOURCE_COMMON" >&2
  exit 1
fi

echo "설치 완료:"
echo "  - $CODEX_DIR/AGENTS.md"
echo "  - $CLAUDE_DIR/CLAUDE.md"
