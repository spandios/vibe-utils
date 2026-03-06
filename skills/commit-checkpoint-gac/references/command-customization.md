# Commit Command Customization

## Command Template Contract
Use one command template string.

- Default: `gac`
- If the command accepts commit message argument, use `{message}` placeholder in template.
- Replace `{message}` with the confirmed commit message before execution.

## Recommended Templates
- `gac`
- `gac "{message}"`
- `git add -A && git commit -m "{message}"`
- `git commit -m "{message}"` (staged-only workflow)
- `git commit -am "{message}"` (tracked files only)

## If Your `gac` Script Is Different
- If your local `gac` handles message internally, keep template as `gac`.
- If your local `gac` accepts message argument, use `gac "{message}"`.
- Or switch template to a plain git command that accepts `"{message}"`.

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
