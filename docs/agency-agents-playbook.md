---
title: Agency Agents Playbook
---

# Agency Agents Playbook

`agency-agents`를 여러 프로젝트에서 공통으로 활용하기 위한 실전 운영 문서.

새 세션에서는 이 파일 하나만 기준으로 쓰면 된다.

```text
/Users/dev_heo/Code/vibe-utils/docs/agency-agents-playbook.md 기준으로 다듬어줘.
[내 초안]
```

대상:
- 1인 스타트업 창업자
- 풀스택 개발자
- 제품, 디자인, 마케팅, 운영까지 혼자 커버해야 하는 사람

핵심 원칙:
- 한 번에 agent는 1개, 많아도 2개만 사용
- 역할, 목표, 제약, 기대 출력 형식을 항상 함께 적기
- agent를 많이 쓰는 것보다 병목에 맞는 agent를 고르는 것이 중요
- 구현용 agent와 리뷰용 agent를 한 프롬프트에 섞지 않기

## 새 세션 사용법

가장 단순한 요청:

```text
/Users/dev_heo/Code/vibe-utils/docs/agency-agents-playbook.md 기준으로 다듬어줘.
[내 초안]
```

예:

```text
/Users/dev_heo/Code/vibe-utils/docs/agency-agents-playbook.md 기준으로 다듬어줘.
가입률이 낮은 것 같고 랜딩도 좀 별로임
기존 구조는 크게 못 바꿈
```

그러면 아래를 자동으로 정리하는 기준으로 사용한다:
- 어떤 agent가 맞는지 선택
- 목표 정리
- 제약 보완
- focus 정리
- 바로 쓸 수 있는 프롬프트 형태로 재작성

## 추천 세트

다양한 프로젝트에서 가장 범용적으로 쓰기 좋은 10개:

### 제품/개발

1. `backend-architect`
2. `frontend-developer`
3. `rapid-prototyper`
4. `debugger`
5. `code-reviewer`

### UX/디자인

6. `design-ux-architect`
7. `design-ui-designer`

### 성장/마케팅

8. `marketing-growth-hacker`
9. `marketing-content-creator`
10. `marketing-seo-specialist`

## 언제 어떤 agent를 쓰는가

| 상황 | 추천 agent | 보조 agent | 메모 |
|---|---|---|---|
| 새 기능 설계 | `backend-architect` | `rapid-prototyper` | API, DB, 서비스 경계 |
| 빠른 MVP 제작 | `rapid-prototyper` | `frontend-developer` | 속도 우선 |
| 웹/앱 화면 구현 | `frontend-developer` | `design-ui-designer` | 구현과 화면 품질 |
| 가입/결제/온보딩 개선 | `design-ux-architect` | `marketing-growth-hacker` | 전환 개선 |
| 원인 모를 버그 추적 | `debugger` | 없음 | 해결책보다 원인 추적 먼저 |
| 배포 전 검수 | `code-reviewer` | 없음 | 회귀, 예외, 테스트 누락 |
| 랜딩 카피/콘텐츠 작성 | `marketing-content-creator` | `design-ui-designer` | 카피와 표현 정렬 |
| 검색 유입 늘리기 | `marketing-seo-specialist` | `marketing-content-creator` | SEO 구조와 글감 |
| 성장 실험 아이디어 | `marketing-growth-hacker` | `design-ux-architect` | 유입, 활성화, 전환 |

## 역할별 사용 목적

### `backend-architect`

사용 목적:
- API 설계
- 데이터 모델 구조화
- 서비스 책임 분리
- 인증/권한 흐름 설계

좋은 요청:
- 최소 변경으로 기능 추가
- 리스크와 트레이드오프 비교
- 구현 순서 제안

### `frontend-developer`

사용 목적:
- 화면 구현
- 반응형 정리
- 컴포넌트 구조 제안
- 상호작용 흐름 정리

좋은 요청:
- 특정 화면 구현
- 성능과 접근성 고려
- 기존 디자인 시스템 유지

### `rapid-prototyper`

사용 목적:
- 가장 작은 실행 가능한 버전 제작
- 빠른 MVP 스캐폴딩
- 검증용 기능 제작

좋은 요청:
- 하루 안에 검증 가능한 범위
- 기술부채 감수 가능한 작업
- 나중에 정리할 항목 구분

### `debugger`

사용 목적:
- 버그 원인 추적
- 환경 차이 분석
- 재현 조건 정리
- 로그/상태 흐름 해석

좋은 요청:
- 증상과 이미 확인한 사실 제공
- 가능한 원인 우선순위 요구
- 가장 작은 수정안 요청

### `code-reviewer`

사용 목적:
- 회귀 위험 검토
- 테스트 누락 탐지
- 예외 처리/운영 안정성 점검

좋은 요청:
- diff 범위 명확히 지정
- 스타일 지적 제외
- 심각도 순서로 결과 요청

### `design-ux-architect`

사용 목적:
- 가입/결제/온보딩 흐름 개선
- 이탈 포인트 탐지
- 전환율 개선

좋은 요청:
- 완료율, 클릭률 같은 목표 명시
- 현재 마찰 지점 설명
- 구현 가능한 수준 제약 제공

### `design-ui-designer`

사용 목적:
- 시각적 위계 개선
- CTA 가시성 향상
- 신뢰감 있는 화면 구성

좋은 요청:
- 무엇을 더 잘 보이게 해야 하는지 설명
- 브랜드 제약 제공
- 빠른 수정 가능한 수준 요청

### `marketing-growth-hacker`

사용 목적:
- 유입 실험 아이디어
- 활성화/전환 개선
- 저비용 성장 루프 설계

좋은 요청:
- 예산, 실행 인원, 기간 제약 제공
- acquisition / activation / conversion 중 하나로 초점 좁히기

### `marketing-content-creator`

사용 목적:
- 랜딩 카피 작성
- 블로그/이메일/런치 포스트 초안 작성
- 브랜드 톤에 맞는 메시지 정리

좋은 요청:
- 타겟 독자 명시
- 톤 지정
- 원하는 포맷 지정

### `marketing-seo-specialist`

사용 목적:
- 검색 유입 구조 설계
- 키워드 묶음 도출
- 랜딩/블로그 주제 우선순위 정리

좋은 요청:
- 제품 카테고리와 타겟 유저 제공
- 운영 가능한 콘텐츠 범위 제약 제공

## 운영 루틴

### 1. 기능 시작 전

추천:
- `backend-architect`
- 필요하면 `rapid-prototyper`

질문 예시:
- 최소한의 구조는 무엇인가
- 지금 당장 만들지 말아야 할 것은 무엇인가

### 2. 화면 작업 전

추천:
- `frontend-developer`
- 필요하면 `design-ui-designer`

질문 예시:
- 가장 중요한 CTA가 제대로 보이는가
- 모바일에서 핵심 행동이 쉬운가

### 3. 성장 정체 시

추천:
- `marketing-growth-hacker`
- `design-ux-architect`

질문 예시:
- 유입 문제인가, 전환 문제인가
- 가장 빨리 검증 가능한 실험은 무엇인가

### 4. 버그 발생 시

추천:
- `debugger`

질문 예시:
- 가능한 원인을 우선순위로 정리해줘
- 각 원인을 어떤 로그나 쿼리로 검증할 수 있나

### 5. 배포 직전

추천:
- `code-reviewer`

질문 예시:
- 회귀 가능성이 큰 부분은 어디인가
- 운영에서 바로 터질 만한 예외가 있는가

## Claude Code 프롬프트 템플릿

아래 구조를 기본으로 사용:

```text
Use the [Agent Name] agent for this task.

Product:
- [제품 또는 프로젝트]

Goal:
- [목표]

Constraints:
- [기술, 일정, 인력, 예산 등 제약]

Focus:
- [집중할 포인트]

Expected output:
- [원하는 결과물]
```

### 백엔드 설계

```text
Use the Backend Architect agent for this task.

Product:
- [제품 이름]

Goal:
- 새로운 기능을 최소한의 구조 변경으로 추가

Constraints:
- 기존 API 최대한 유지
- 짧은 일정 내 배포

Focus:
- API shape
- DB relations
- transaction boundaries

Expected output:
- 추천 설계안
- 구현 순서
- 리스크
```

### 프론트엔드 구현

```text
Use the Frontend Developer agent for this task.

Product:
- [제품 이름]

Goal:
- 핵심 화면 구현 또는 개선

Constraints:
- 모바일 우선
- 기존 스타일 유지

Focus:
- component structure
- responsive layout
- CTA clarity

Expected output:
- 구현 방향
- 핵심 UI 결정
- 빠르게 적용 가능한 변경안
```

### 빠른 프로토타입

```text
Use the Rapid Prototyper agent for this task.

Product:
- [제품 이름]

Goal:
- 검증 가능한 최소 기능 제작

Constraints:
- 하루 안에 구현
- 기술부채 감수 가능

Focus:
- smallest working version

Expected output:
- 가장 작은 구현안
- 나중에 정리할 항목
```

### 디버깅

```text
Use the Debugger agent for this task.

Product:
- [제품 이름]

Goal:
- 문제의 근본 원인 찾기

Constraints:
- 이미 확인한 사실만 기반으로 추정

Focus:
- ranked hypotheses
- verification steps
- smallest safe fix

Expected output:
- 가능한 원인 우선순위
- 확인 방법
- 수정안
```

### 코드 리뷰

```text
Use the Code Reviewer agent for this task.

Product:
- [제품 이름]

Goal:
- 배포 전 위험 요소 점검

Constraints:
- 스타일 논쟁 제외

Focus:
- regression risks
- missing tests
- error handling gaps

Expected output:
- findings first
- severity ordered
```

### UX 개선

```text
Use the UX Architect agent for this task.

Product:
- [제품 이름]

Goal:
- 가입 또는 결제 완료율 개선

Constraints:
- 큰 구조 변경은 어려움

Focus:
- friction points
- step clarity
- CTA flow

Expected output:
- UX 문제
- 우선순위 높은 수정안
```

### UI 개선

```text
Use the UI Designer agent for this task.

Product:
- [제품 이름]

Goal:
- 신뢰감과 클릭률 개선

Constraints:
- 구현 가능한 수준만

Focus:
- hierarchy
- spacing
- CTA visibility

Expected output:
- 시각적 문제점
- 빠른 개선안
```

### 성장 실험

```text
Use the Growth Hacker agent for this task.

Product:
- [제품 이름]

Goal:
- 유입 또는 전환 개선

Constraints:
- 적은 예산
- 혼자 실행 가능

Focus:
- low-cost experiments
- acquisition or conversion

Expected output:
- 실험 아이디어
- 성공 지표
- 실행 난이도
```

### 콘텐츠 작성

```text
Use the Content Creator agent for this task.

Product:
- [제품 이름]

Goal:
- 랜딩 또는 콘텐츠 초안 작성

Constraints:
- 타겟 독자와 톤 유지

Focus:
- clarity
- trust
- conversion

Expected output:
- 초안 카피
- headline options
- CTA options
```

### SEO 기획

```text
Use the SEO Specialist agent for this task.

Product:
- [제품 이름]

Goal:
- 검색 유입 증가

Constraints:
- 혼자 운영 가능한 수준

Focus:
- keyword themes
- landing pages
- blog topics

Expected output:
- 키워드 묶음
- 콘텐츠 아이디어
- 우선순위
```

## 빠른 호출 예시

### 예시 1

```text
Use the Backend Architect agent to design a minimal billing API for this SaaS MVP.
```

### 예시 2

```text
Use the Frontend Developer agent to improve this landing page for signup conversion.
```

### 예시 3

```text
Use the Debugger agent to find why this feature fails only in production.
```

### 예시 4

```text
Use the Code Reviewer agent to review this diff for regressions and missing tests.
```

### 예시 5

```text
Use the Growth Hacker agent to propose 5 low-cost acquisition experiments for this product.
```

## 하지 말아야 할 요청

피해야 할 예:

```text
Use the best agent and improve everything.
```

```text
Use frontend, backend, growth, and reviewer all at once and give me one final answer.
```

```text
This is broken. Fix it.
```

문제:
- 역할이 불명확함
- 목표가 불명확함
- 결과물 형태가 없음
- agent 간 역할 충돌이 생김

## 요약

가장 중요한 것은 agent 수가 아니라 요청 방식이다.

좋은 프롬프트는 항상 아래 다섯 가지를 포함한다:
- 역할
- 목표
- 제약
- 집중 포인트
- 기대 출력
