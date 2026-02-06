---
name: split-commit
description: "Split oversized Git working-tree changes into multiple logical commits by grouping files by concern, proposing a commit plan, and executing sequential git add + git commit. Use when users say one commit became too large, ask to split current changes before commit, or request automatic commit chunking during deep coding sessions."
---

# Split Commit

## Goal
Convert one oversized working tree into several small, scoped commits.

## Workflow
1. Inspect uncommitted changes.
2. Build logical commit groups.
3. Show the split plan and ask one confirmation.
4. Stage and commit each group in order.
5. Report final result and remaining changes.

## 1) Inspect Changes
Run:
- `git status --short`
- `git diff --stat`

If there is nothing to commit, stop and report.

## 2) Build Logical Groups
Create groups by concern, not by raw file count.

Preferred grouping order:
1. Core source changes by feature/fix unit
2. Test changes tied to each source unit
3. Config/build changes
4. Docs/changelog/readme changes

Rules:
- Keep one commit focused on one intent.
- Keep related tests with the source commit when possible.
- Avoid mixing refactor-only and behavior changes in one commit.
- If a file contains multiple concerns, use partial staging (`git add -p`).

## 3) Confirm Plan
Before committing, show:
- Group list (name, files, proposed message)
Ask once:
- "이 플랜대로 n개 커밋으로 분할 진행할까요?"

## 4) Execute Sequential Commits
For each group:
1. `git add <files>` — stage only that group's files (use `git add -p` for partial staging).
2. `git commit -m "{message}"` — commit staged changes.
3. Check `git log -1 --oneline` and continue.

## 5) Final Report
After all groups:
- List created commits in order.
- Show remaining unstaged/uncommitted files, if any.
- Suggest next checkpoint commit timing.

## Safety Rules
- Never commit without explicit user confirmation.
- Never push unless explicitly requested.
- If any commit fails, stop the sequence and ask how to proceed.
