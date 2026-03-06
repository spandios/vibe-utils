# Command Customization

## Default
- Default template: `gac`

This default assumes your local `gac` behavior is compatible with split commits.

## Compatibility Check
For split commits, commit command must respect current staged content only.

- Compatible: command commits only staged hunks/files.
- Incompatible: command automatically runs `git add -A` or equivalent.

If incompatible, use a staged-only template.

## Recommended Templates
- `gac`
- `git commit -m "{message}"`
- `git add -A && git commit -m "{message}"` (single-commit mode only, not split mode)

## Split-Mode Recommended Pair
When splitting large changes safely:
1. Stage by group with `git add <files>` or `git add -p`
2. Commit with `git commit -m "{message}"`

## Message Style
Use concise scoped messages:
- `feat: add brand filter API`
- `fix: prevent null price mapping`
- `test: cover crawler retry backoff`
- `docs: update setup steps`
