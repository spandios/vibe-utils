---
name: claude-to-codex
description: >
  Claude Code의 에이전트 정의(.claude/agents/*.md)와 스킬(.claude/skills/*/skill.md)을
  Codex 포맷(.codex/agents/*.toml, .agents/skills/*/SKILL.md)으로 변환한다.
  'codex로 변환', 'codex 동기화', 'claude to codex', '하네스 동기화' 같은 요청 시 사용.
---

# Claude-to-Codex Migrator

Claude Code의 에이전트/스킬 정의를 Codex CLI 포맷으로 변환한다.

## 변환 매핑

### 에이전트: `.claude/agents/*.md` → `.codex/agents/*.toml`

| Claude Code (MD frontmatter) | Codex (TOML) |
|------------------------------|--------------|
| `name:` | `name =` |
| `description:` | `description =` |
| 본문 전체 | `developer_instructions =` (팀 통신 프로토콜 제외) |
| — | `sandbox_mode =` (역할에 따라 결정) |

**sandbox_mode 결정 기준:**
- 파일 수정이 필요한 에이전트 (dev, builder) → `"workspace-write"`
- 읽기/검증만 하는 에이전트 (inspector, reviewer) → `"read-only"`
- 시스템 명령이 필요한 에이전트 → `"danger-full-access"` (주의)

**제외 항목 (Codex에 해당 없음):**
- `## 팀 통신 프로토콜` 섹션 — Codex에는 SendMessage가 없으므로 제거
- TeamCreate/SendMessage 참조 — `_workspace/` 파일 기반 전달로 대체

### 스킬: `.claude/skills/*/skill.md` → `.agents/skills/*/SKILL.md`

| Claude Code | Codex |
|-------------|-------|
| `skill.md` (소문자) | `SKILL.md` (대문자) |
| YAML frontmatter | YAML frontmatter (동일) |
| `name:` | `name:` (동일, hyphen-case로 변환) |
| `description:` | `description:` (최대 1024자) |
| `allowed-tools:` | `allowed-tools:` (동일) |
| TeamCreate/SendMessage 워크플로우 | 서브에이전트 spawn + 파일 기반 전달로 변환 |

## 변환 절차

### Step 1: 소스 파일 탐색
```
.claude/agents/*.md 파일 목록 수집
.claude/skills/*/skill.md 파일 목록 수집
```

### Step 2: 에이전트 변환
각 `.claude/agents/{name}.md`에 대해:
1. YAML frontmatter에서 name, description 추출
2. 본문에서 "팀 통신 프로토콜" 섹션 제거
3. SendMessage/TeamCreate 참조를 파일 기반 전달로 대체
4. sandbox_mode 결정
5. `.codex/agents/{name}.toml` 생성

### Step 3: 스킬 변환
각 `.claude/skills/{name}/skill.md`에 대해:
1. YAML frontmatter 추출 (description 1024자 제한 확인)
2. 본문에서 Claude Code 전용 도구 참조를 Codex 패턴으로 변환:
   - `TeamCreate(...)` → "서브에이전트 spawn" 설명
   - `SendMessage(...)` → "_workspace/ 파일 기반 전달"
   - `TaskCreate(...)` → 순차 실행 설명
3. `.agents/skills/{name}/SKILL.md` 생성

### Step 4: 검증
- .codex/agents/*.toml 파일에 name, description, developer_instructions 필수 필드 확인
- .agents/skills/*/SKILL.md 파일에 name, description frontmatter 확인
- description이 1024자를 초과하지 않는지 확인

## 주의사항

- Claude Code의 에이전트 팀(TeamCreate + SendMessage) 패턴은 Codex의 서브에이전트 + 파일 기반 전달로 변환된다. 이 과정에서 "실시간 통신" 능력이 "순차 파일 교환"으로 약화됨을 인지한다.
- Codex의 description은 최대 1024자, name은 hyphen-case만 허용 (^[a-z0-9-]+$, 최대 64자).
- 기존 Codex 파일이 있으면 덮어쓰기 전 확인한다.
