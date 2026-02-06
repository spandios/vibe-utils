#!/bin/bash
# auto-commit/start.sh

set -e

# git 저장소인지 확인
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "✗ git 저장소가 아닙니다"
    exit 1
fi

# git diff가 있는지 확인
if ! git diff --cached --quiet 2>/dev/null; then
    DIFF=$(git diff --cached)
elif ! git diff --quiet 2>/dev/null; then
    echo "모든 변경사항을 staging 중..."
    git add -A
    DIFF=$(git diff --cached)
else
    echo "커밋할 변경사항이 없습니다"
    exit 0
fi

# 커밋 메시지 생성용 프롬프트
PROMPT="다음 git diff를 분석해서 간결한 커밋 메시지를 생성해줘.
형식: <타입>: <설명>
타입은 feat/fix/refactor/docs/style/test/chore 중 하나.
설명은 한글로 작성해. 단, 변경이 아주 단순하면(오타 수정, 한 줄 변경 등) 영어로 작성해도 됨.
커밋 메시지만 반환하고 다른 설명은 하지 마.

Diff:
$DIFF"

# AI CLI로 커밋 메시지 생성
AI_PROVIDER_LABEL=$(ai-call -p claude -m haiku --name) || exit 1
echo "$AI_PROVIDER_LABEL 로 커밋 메시지 생성 중..."
COMMIT_MSG=$(ai-call -p claude -m haiku "$PROMPT")

# 생성 실패 시 처리
if [ -z "$COMMIT_MSG" ]; then
    echo "✗ 커밋 메시지 생성 실패"
    exit 1
fi

echo ""
echo "생성된 커밋 메시지 ($AI_PROVIDER_LABEL):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$COMMIT_MSG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1) 이 메시지로 커밋 (기본)"
echo "2) 커밋 안 함"
echo "3) 직접 입력"
read -p "선택 [1/2/3] (Enter=1): " choice
choice=${choice:-1}

case $choice in
    1)
        git commit -m "$COMMIT_MSG"
        echo "✓ 커밋 완료"
        ;;
    2)
        echo "커밋 취소됨"
        exit 0
        ;;
    3)
        read -p "커밋 메시지 입력: " CUSTOM_MSG
        if [ -z "$CUSTOM_MSG" ]; then
            echo "✗ 커밋 메시지가 비어있습니다"
            exit 1
        fi
        git commit -m "$CUSTOM_MSG"
        echo "✓ 직접 입력한 메시지로 커밋 완료"
        ;;
    *)
        echo "✗ 잘못된 선택입니다"
        exit 1
        ;;
esac