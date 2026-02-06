# Git Auto Commit

Claude Code를 활용한 자동 커밋 메시지 생성 도구

## 요구사항

- Git
- 다음 CLI 중 **하나 이상** (우선순위 순): Claude Code, Gemini CLI, Codex CLI
- bash 또는 zsh

## 설치

```bash
git clone <repository-url> auto-commit
cd auto-commit
./install.sh
```

## 사용법

git 저장소에서 다음 명령어 실행:

```bash
gac  # 또는 설치 시 지정한 alias
```

## 동작 방식

1. 변경사항이 있으면 자동으로 staging
2. 설치된 CLI로 커밋 메시지 자동 생성 (Claude Code → Gemini CLI → Codex 순 fallback)
3. 생성된 메시지 확인 후 선택:
   - 그대로 커밋
   - 커밋 취소
   - 직접 메시지 입력
