---
name: commit-checkpoint-gac
description: "Proactively prevent oversized Git commits during deep coding sessions by pausing at logical checkpoints, asking whether to commit now, and executing a configurable commit command (default: gac) after explicit user confirmation. Use when users mention missed commit timing, commit checkpoint reminders, smaller commit cadence, or ask the agent to run commits for them."
---

# Commit Checkpoint Gac

## Goal
Keep commits small and frequent without breaking implementation flow.

## Checkpoint Workflow
1. Detect a commit checkpoint while working.
2. Summarize current changes.
3. Ask for explicit commit approval.
4. Run the configured commit command only after approval.
5. Report commit result and continue work.

## Detect Commit Checkpoints
Treat any of these as a checkpoint:
- Complete one logical task chunk (feature slice, bug fix slice, refactor slice).
- Notice broad scope growth (for example, many files or mixed concerns).
- Reach roughly 30 minutes of uninterrupted implementation on one task.
- See user phrasing that implies "pause here" or "checkpoint".

When in doubt, prefer asking earlier rather than batching into one large commit.

## Ask at Every Checkpoint
Before any commit command, show a compact summary from git context:
- `git status --short`
- `git diff --stat`

Then ask in one short line, for example:
- "커밋 지점입니다. 지금 커밋할까요?"

Also include one suggested commit message.

## Commit Execution Rules
- Never run a commit command without explicit yes/approval in the current turn.
- If the configured command needs a message and message is missing, propose one and confirm quickly.
- Use the command template in `references/command-customization.md`.
- Default template: `gac`
- If nothing is commit-ready, report that clearly instead of forcing a commit.
- Do not run `push` unless user explicitly requests it.

After commit, show:
- Commit command executed
- `git log -1 --oneline` result

## Failure Handling
If commit command fails:
1. Show the error in one short summary.
2. Offer the next safe action (fix command, adjust message, or skip).
3. Refer to `references/command-customization.md` to switch command style.
