---
name: improve-prompt
description: Use when a user asks to improve, rewrite, sharpen, structure, or operationalize a rough prompt into an execution-ready prompt, especially when goals, constraints, output format, focus, success criteria, or the best agent choice are missing, vague, or underspecified.
---

# Improve Prompt

## Overview

Turn a rough idea into a prompt that is immediately usable by an agent.

## Instructions

1. First read the playbook at `~/agent-playbook.md`.
If it is missing, ask one short question that requests the correct playbook path or asks the user to restore the file.

2. Extract the minimum needed context from the user's draft:
- goal
- constraints
- target user or audience
- desired focus
- expected output format
- success criteria

3. Choose the best agent set using the playbook rules:
- prefer 1 agent
- use at most 2 agents
- do not mix implementation and review agents in one prompt

4. Improve the draft without changing the user's intent.
- add only the minimum missing detail
- if a necessary assumption is added, label it as `가정:`
- replace vague wording with concrete instructions

5. Before returning the final prompt, internally check:
- is the goal clear in one sentence
- are the constraints actionable
- is the output format explicit
- does the agent choice match the playbook
- is there any ambiguity left that requires one question

6. Return exactly this structure in Korean:
- `추천 agent`
- `보완 포인트`
- `최종 프롬프트`

## Output Rules

- `최종 프롬프트` must be directly copy-pastable.
- `최종 프롬프트` must read like an immediately executable task instruction.
- replace vague phrases such as `적당히`, `잘`, `보기 좋게`, and `알아서`.
- Avoid long explanations.
- If the draft is too vague to improve safely, ask only one minimal clarifying question.
