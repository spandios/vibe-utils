---
name: assessing-feature-scope
description: Use when planning a new feature, refactor, or behavior change and Codex should inspect the existing codebase before implementation. Trigger on requests to estimate complexity, map impacted modules, understand architecture scale, identify hidden dependencies, or judge whether a change is small, medium, or large before writing code.
---

# Assessing Feature Scope

## Overview

Inspect the current codebase before implementing a feature. Map likely touch points, estimate code and architecture impact, and produce a short scope brief that makes the change size explicit before any implementation starts.

## Workflow

1. Read the request and restate the intended behavior in one or two lines.
2. Load only the minimum local context needed: `AGENTS.md`, architecture docs, ADRs, feature specs, or domain-specific context files when present.
3. Search the codebase with `rg` for domain nouns, routes, controllers, services, repositories, database tables, DTOs, feature flags, or UI screens related to the request.
4. Identify the likely entry point and follow the path across layers.
5. Count the change surface by module, boundary, and shared abstraction rather than by line count.
6. Score the work with the rubric in [references/complexity-rubric.md](references/complexity-rubric.md).
7. Present a scope brief and wait for confirmation before implementation unless the user explicitly wants immediate coding.

## Scope Brief Format

Use this structure for the initial answer:

- `Requested change`: brief restatement and assumptions
- `Relevant code surface`: concrete files, modules, layers, and boundaries likely involved
- `Architecture impact`: additive, localized modification, shared abstraction change, or cross-cutting change
- `Complexity score`: total score and band from the rubric
- `Key risks`: hidden coupling, schema/API changes, auth/permission impact, migration needs, or test blast radius
- `Recommended path`: smallest safe implementation slice
- `Unknowns`: what must be verified before coding if confidence is not high

## Investigation Rules

- Prefer concrete file and symbol references over vague architecture talk.
- Prefer existing module boundaries over proposed abstractions.
- Treat schema changes, shared component changes, auth/permission changes, async workflows, and external integrations as force multipliers.
- Do not use file count or LOC alone as the estimate.
- Call out uncertainty explicitly. If evidence is thin, say so.
- If the request is obviously small but touches shared code, still inspect the shared path before claiming it is small.
- Do not start implementation inside the same response unless the user asked for immediate execution.

## Escalation Heuristics

Treat the work as at least `Large` when one or more of these is true:

- More than three architectural layers are likely to change
- A database schema or API contract must change
- A shared abstraction used by multiple features must change
- Background jobs, caching, permissions, or pricing rules are involved
- The relevant code path is unclear after initial search
- Required regression coverage spans multiple modules or apps

## Examples

- "새 쿠폰 정책 추가하기 전에 이거 어디까지 바뀌는지 먼저 봐줘"
- "이 기능이 프론트만 바꾸면 되는지, 백엔드까지 번지는지 판단해줘"
- "구현 전에 변경 범위를 읽고 small/medium/large로 분류해줘"
- "리팩터링 말고 신규 모듈이 필요한 수준인지 먼저 분석해줘"

## References

- Use [references/complexity-rubric.md](references/complexity-rubric.md) for scoring.
- Use [references/scope-brief-template.md](references/scope-brief-template.md) when a reusable response skeleton helps.
