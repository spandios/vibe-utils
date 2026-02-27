# Commit Command Customization

## Command Template Contract
Use one command template string.

- Default: `git add -A && git commit -m "{message}"`
- If the command accepts commit message argument, use `{message}` placeholder in template.
- Replace `{message}` with the confirmed commit message before execution.

## Recommended Templates
- `git add -A && git commit -m "{message}"`
- `git commit -m "{message}"` (staged-only workflow)
- `git commit -am "{message}"` (tracked files only)
- `your-wrapper-commit "{message}"` (custom local command)

## If You Use a Custom Wrapper Command
- If your local wrapper handles message internally, set template to the wrapper command itself.
- If your wrapper accepts message argument, use `"{message}"` placeholder.
- Keep behavior equivalent to a local commit only. Do not include auto-push.

## Message Guidance
- Keep message short and scoped to one logical change.
- Prefer Conventional Commit style when possible:
  - `feat: add oliveyoung crawler retry`
  - `fix: handle null brand mapping`
  - `refactor: split price sync service`

## Safety Rules
- Never auto-commit without explicit approval.
- Never auto-push without explicit approval.
- If command fails, report error and ask before retrying.
