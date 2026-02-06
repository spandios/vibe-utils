#!/bin/bash
# auto-commit/install.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMIT_SCRIPT="$SCRIPT_DIR/commit.sh"
BIN_DIR="$HOME/.local/bin"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Git Auto Commit 설치"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# commit.sh 실행 권한
if [ ! -f "$COMMIT_SCRIPT" ]; then
    echo "✗ commit.sh 파일을 찾을 수 없습니다"
    exit 1
fi
chmod +x "$COMMIT_SCRIPT"

# 명령어 이름
read -p "명령어 이름 (기본값: gac): " CMD_NAME
CMD_NAME=${CMD_NAME:-gac}

LINK_PATH="$BIN_DIR/$CMD_NAME"
mkdir -p "$BIN_DIR"

# 기존 링크/파일 있으면 덮어쓰기
if [ -L "$LINK_PATH" ] || [ -e "$LINK_PATH" ]; then
    echo "⚠ 기존 $LINK_PATH 덮어씁니다 (← $(readlink "$LINK_PATH" 2>/dev/null || echo "일반 파일"))"
fi

# symlink 생성 (기존 있으면 강제 덮어쓰기)
ln -sf "$COMMIT_SCRIPT" "$LINK_PATH"

# 기존 .zshrc alias 정리 안내
SHELL_RC="$HOME/.zshrc"
if grep -q "alias $CMD_NAME=.*commit.sh" "$SHELL_RC" 2>/dev/null; then
    echo ""
    echo "⚠️  ~/.zshrc에 기존 alias가 남아있습니다. 제거하는 게 좋습니다:"
    grep "alias $CMD_NAME=" "$SHELL_RC"
    read -p "자동으로 제거할까요? (Y/n): " REMOVE_ALIAS
    REMOVE_ALIAS=${REMOVE_ALIAS:-Y}
    if [[ "$REMOVE_ALIAS" =~ ^[Yy]$ ]]; then
        sed -i.bak "/# Git Auto Commit/d; /alias $CMD_NAME=.*commit.sh/d" "$SHELL_RC"
        echo "✓ 기존 alias 제거 완료"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  설치 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  $LINK_PATH → $COMMIT_SCRIPT"
echo ""
echo "  바로 사용 가능:"
echo "    $CMD_NAME"
echo ""

# PATH 확인
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
    echo "⚠️  $BIN_DIR 이(가) PATH에 없습니다."
    echo "   ~/.zshrc에 다음을 추가하세요:"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
