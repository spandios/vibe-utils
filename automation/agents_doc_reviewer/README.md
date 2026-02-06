# Agents Doc Reviewer

프로젝트의 `CLAUDE.md`, `AGENTS.md` 등 에이전트 설정 문서가 실제 코드와 동기화되어 있는지 주기적으로 리뷰하는 자동화 도구.

## 왜 필요한가

코드는 계속 바뀌지만 CLAUDE.md/AGENTS.md 같은 에이전트 설정 문서는 업데이트를 놓치기 쉬움. 이 도구는:

- 설정한 주기(기본 21일)마다 각 프로젝트의 git 변경 이력을 분석
- 문서가 코드 변경을 반영하고 있는지 리포트 생성
- **Claude CLI가 자동으로 리뷰 제안을 생성** (추가/수정/삭제 제안을 diff 형태로)

## 구조

```
automation/agents_doc_reviewer/
├── README.md                              # 이 문서
├── agents_doc_review.sh                   # 메인 리뷰 스크립트
├── agents_review_projects.example.json    # 설정 파일 예시
└── setup_schedule.sh                      # macOS launchd 스케줄 등록
```

## 빠른 시작

### 1. 설정 파일 생성

```bash
cd automation/agents_doc_reviewer
cp agents_review_projects.example.json agents_review_projects.json
```

`agents_review_projects.json`을 열어서 본인 프로젝트에 맞게 수정:

```json
{
  "defaults": {
    "interval_days": 21,
    "docs": ["CLAUDE.md", "AGENTS.md"]
  },
  "projects": [
    {
      "name": "my-api",
      "path": "/Users/me/Code/my-api",
      "interval_days": 14,
      "docs": ["CLAUDE.md", "AGENTS.md", "CONVENTIONS.md"]
    },
    {
      "name": "frontend",
      "path": "/Users/me/Code/frontend"
    }
  ]
}
```

| 필드 | 설명 | 기본값 |
|------|------|--------|
| `defaults.interval_days` | 리뷰 주기 (일) | 21 |
| `defaults.docs` | 리뷰 대상 문서 목록 | `["CLAUDE.md", "AGENTS.md"]` |
| `projects[].name` | 프로젝트 식별 이름 | (필수) |
| `projects[].path` | 프로젝트 절대 경로 | (필수) |
| `projects[].interval_days` | 프로젝트별 리뷰 주기 오버라이드 | defaults 값 사용 |
| `projects[].docs` | 프로젝트별 문서 목록 오버라이드 | defaults 값 사용 |

### 2. 수동 실행 (테스트)

```bash
./automation/agents_doc_reviewer/agents_doc_review.sh --force
```

### 3. 스케줄 등록

```bash
./automation/agents_doc_reviewer/setup_schedule.sh install
```

끝. 매일 오전 10시에 launchd가 스크립트를 실행하고, 각 프로젝트별 주기가 도래했을 때만 실제 리뷰가 수행됨.

## 스케줄 관리

```bash
# 상태 확인
./automation/agents_doc_reviewer/setup_schedule.sh status

# 즉시 실행
./automation/agents_doc_reviewer/setup_schedule.sh run-now

# 스케줄 해제
./automation/agents_doc_reviewer/setup_schedule.sh uninstall
```

### install 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `--interval <days>` | 리뷰 주기 | 21 |
| `--hour <0-23>` | 실행 시각 (시) | 10 |
| `--minute <0-59>` | 실행 시각 (분) | 0 |
| `--no-claude` | Claude 리뷰를 비활성화 | Claude 리뷰 활성화 |

## 리뷰 스크립트 옵션

```bash
./automation/agents_doc_reviewer/agents_doc_review.sh [options]
```

| 옵션 | 설명 |
|------|------|
| `--config <file>` | 설정 파일 경로 (기본: `automation/agents_doc_reviewer/agents_review_projects.json`) |
| `--output-dir <dir>` | 리포트 출력 경로 (기본: `output/agents-review`) |
| `--project <name>` | 특정 프로젝트만 실행 |
| `--force` | 주기 무시하고 즉시 실행 |
| `--dry-run` | state 파일 기록 없이 실행 |
| `--no-claude` | Claude 리뷰 비활성화 |
| `--claude-model <model>` | Claude 모델 지정 (기본: sonnet) |
| `--open-editor` | 리뷰 후 `$EDITOR`로 문서 열기 |

## 출력물

리포트는 `output/agents-review/<timestamp>/` 에 생성됨:

```
output/agents-review/20250207-100000/
├── SUMMARY.md              # 전체 요약
├── my-api.md               # 프로젝트별 변경 리포트
├── my-api-suggestions.md   # Claude 리뷰 제안
├── frontend.md
└── frontend-suggestions.md
```

### 리포트 내용
- 리뷰 기간 내 커밋 수, 변경 파일 목록
- 각 문서의 존재 여부, 리뷰 기간 내 업데이트 여부, head 대비 lag일수

### Claude 리뷰 제안 내용
- 주요 변경 사항 요약
- 추가/수정/삭제 제안 (구체적 diff 블록 포함)

## 의존성

- `git`, `jq` — 필수
- `claude` CLI — 리뷰 제안 생성에 필요 ([Claude Code](https://claude.com/claude-code))
- macOS `launchd` — 스케줄 등록 (setup_schedule.sh)
