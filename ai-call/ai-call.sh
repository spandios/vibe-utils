#!/bin/bash
# ai-call — AI CLI 통합 래퍼
#
# Usage:
#   ai-call "prompt"                   # 자동 감지된 provider + 기본 모델
#   ai-call -m sonnet "prompt"         # 모델 지정
#   ai-call -p gemini "prompt"         # provider 강제 지정
#   ai-call -p gemini -m 2.5-pro "prompt"
#   ai-call --name                     # provider 이름만 출력
#
# 환경변수:
#   AI_CALL_PROVIDER   - 강제 지정: claude, gemini, codex (미설정시 auto)
#
# 기본 모델:
#   claude: haiku | gemini: gemini-2.5-flash | codex: gpt-5.1-codex-mini
#
# 사용 가능한 모델:
#   claude: haiku, sonnet, opus
#   gemini: gemini-2.5-flash, gemini-2.5-pro, gemini-2.0-flash
#   codex:  gpt-5.1-codex-mini, o4-mini, o3

set -euo pipefail

# 기본 모델
DEFAULT_CLAUDE_MODEL="haiku"
DEFAULT_GEMINI_MODEL="gemini-2.5-flash"
DEFAULT_CODEX_MODEL="gpt-5.1-codex-mini"

# 옵션 파싱
PROVIDER="${AI_CALL_PROVIDER:-}"
MODEL=""
NAME_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--model)    MODEL="$2"; shift 2 ;;
        -p|--provider) PROVIDER="$2"; shift 2 ;;
        --name)        NAME_ONLY=true; shift ;;
        -h|--help)
            sed -n '2,/^[^#]/s/^# \{0,1\}//p' "$0"
            exit 0
            ;;
        -*) echo "✗ 알 수 없는 옵션: $1" >&2; exit 1 ;;
        *)  break ;;
    esac
done

PROMPT="${1:-}"

# provider 결정
resolve_provider() {
    if [ -n "$PROVIDER" ]; then
        if ! command -v "$PROVIDER" &> /dev/null; then
            echo "✗ $PROVIDER 이(가) 설치되어 있지 않습니다" >&2
            return 1
        fi
        echo "$PROVIDER"
        return 0
    fi

    for cli in claude gemini codex; do
        if command -v "$cli" &> /dev/null; then
            echo "$cli"
            return 0
        fi
    done

    echo "✗ 사용 가능한 AI CLI가 없습니다. 다음 중 하나를 설치하세요:" >&2
    echo "  - Claude Code: https://docs.anthropic.com/en/docs/claude-code" >&2
    echo "  - Gemini CLI:  https://github.com/google-gemini/gemini-cli" >&2
    echo "  - Codex CLI:   https://developers.openai.com/codex/cli" >&2
    return 1
}

RESOLVED=$(resolve_provider) || exit 1

# 모델 결정 (미지정 시 기본값)
case "$RESOLVED" in
    claude) MODEL="${MODEL:-$DEFAULT_CLAUDE_MODEL}" ;;
    gemini) MODEL="${MODEL:-$DEFAULT_GEMINI_MODEL}" ;;
    codex)  MODEL="${MODEL:-$DEFAULT_CODEX_MODEL}" ;;
esac

# --name: provider 이름만 출력
if $NAME_ONLY; then
    case "$RESOLVED" in
        claude) echo "Claude Code ($MODEL)" ;;
        gemini) echo "Gemini CLI ($MODEL)" ;;
        codex)  echo "Codex CLI ($MODEL)" ;;
        *)      echo "$RESOLVED" ;;
    esac
    exit 0
fi

# 프롬프트 필수
if [ -z "$PROMPT" ]; then
    echo "✗ 프롬프트가 비어있습니다" >&2
    echo "Usage: ai-call [-m MODEL] [-p PROVIDER] \"prompt\"" >&2
    exit 1
fi

# AI CLI 호출
case "$RESOLVED" in
    claude) claude --model "$MODEL" -p "$PROMPT" ;;
    gemini) gemini -m "$MODEL" -p "$PROMPT" 2>/dev/null | grep -vE '^MCP STDERR |^[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \[' | sed '/./,$!d' ;;
    codex)  codex exec -m "$MODEL" "$PROMPT" 2>/dev/null ;;
    *)      echo "✗ 알 수 없는 provider: $RESOLVED" >&2; exit 1 ;;
esac
