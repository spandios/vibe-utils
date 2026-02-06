#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"
ln -sf "$ROOT_DIR/ai-call.sh" "$BIN_DIR/ai-call"

# ~/.local/bin이 PATH에 없으면 안내
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo "⚠ $BIN_DIR 이 PATH에 없습니다. 셸 설정에 추가하세요:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo ""
fi

echo "설치 완료: $BIN_DIR/ai-call → ai-call.sh"
