# Command Customization

## Default
Split commit uses standard git commands:
1. `git add <files>` or `git add -p` — stage only the target group's files/hunks.
2. `git commit -m "{message}"` — commit staged changes.

## Important
- Never use `git add -A` or `git add .` in split mode — it breaks group boundaries.
- Always stage per-group, then commit.

## Message Style
Use concise scoped messages:
- `feat: add brand filter API`
- `fix: prevent null price mapping`
- `test: cover crawler retry backoff`
- `docs: update setup steps`
