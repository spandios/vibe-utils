---
name: clarify-unclear-prompt
description: Enforce clarification-first behavior for ambiguous or underspecified user prompts. Use when the request has missing scope, unclear constraints, conflicting instructions, unknown targets, or vague success criteria; ask follow-up questions and pause execution until ambiguity is resolved.
---

# Clarify Unclear Prompt

## Objective

Prevent incorrect execution by requiring clarification before acting on ambiguous requests.

## Clarification Workflow

1. Parse the user prompt and extract intent, deliverable, scope, constraints, and success criteria.
2. Detect ambiguity signals:
   - Missing target files, modules, APIs, environments, or versions
   - Vague verbs or goals such as "fix", "improve", "optimize", "latest", or "best"
   - Multiple plausible interpretations
   - Conflicting constraints or missing acceptance criteria
   - Potentially risky actions without explicit confirmation
3. Stop execution when at least one ambiguity signal exists.
4. Ask 1-3 concise follow-up questions in priority order.
5. Resume execution only after answers resolve ambiguity.

## Non-Negotiable Rules

- Avoid guessing when uncertainty can change behavior, cost, safety, or quality.
- Avoid destructive or irreversible actions while prompt details are unclear.
- Ask again if ambiguity remains after the first clarification round.
- State assumptions explicitly and request confirmation before proceeding when the user declines to provide details.

## Questioning Pattern

Use this structure:

```text
To proceed accurately, I need to confirm a few points:
1) [highest-impact missing detail]
2) [next missing detail]
3) [optional final detail]
Once you confirm, I will execute immediately.
```

## Ambiguity Checklist

Check all items before execution:

- Goal: Is the exact output explicit?
- Scope: Are target files/components/services explicit?
- Constraints: Are performance, security, style, and deadline constraints explicit?
- Environment: Are runtime/framework/version requirements explicit?
- Source of truth: Is the reference spec or branch explicit?
- Validation: Is "done" measurable with clear acceptance criteria?

## Fast Path

Proceed without clarification only when the request is fully specified and low risk.

## Examples

- Ambiguous prompt: "API 느린 거 고쳐줘."
  - Ask:
    1) "어떤 API 엔드포인트를 기준으로 할까?"
    2) "목표 응답시간이나 처리량 기준이 있을까?"
    3) "코드 수정 범위를 백엔드만으로 제한할까?"

- Ambiguous prompt: "배포 설정 정리해줘."
  - Ask:
    1) "대상 환경이 dev/staging/prod 중 어디일까?"
    2) "인프라 변경까지 포함할까, 앱 설정만 다룰까?"
    3) "롤백 기준이나 다운타임 허용 범위가 있을까?"
