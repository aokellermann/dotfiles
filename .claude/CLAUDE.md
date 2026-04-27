# User-Level Claude Instructions

## Maintaining CLAUDE.md and Rules Files

Be liberal with updating `CLAUDE.md` files and `.claude/rules/*.md` as you work. When you learn something that would help a future Claude instance — a non-obvious build step, a repo convention, a gotcha that caused a failure, a tool invocation that took iteration to get right — add it to the appropriate CLAUDE.md or rule file. Prefer the most specific scope that still applies (task/challenge-level → project-level → user-level). Don't ask for permission for small additions; just make the edit alongside the work that taught you the lesson.

## Git Branch Naming

When creating git branches, always prefix them with `aokellermann/` followed by a descriptive kebab-case name.

Examples:
- `aokellermann/fix-login-bug`
- `aokellermann/add-user-settings`
- `aokellermann/refactor-api-client`

## Sudo

Never run `sudo` yourself. It is denied via permission rules and would fail anyway — Claude Code is non-interactive, so sudo can't prompt for a password, and each failed attempt feeds `pam_faillock`, which locks the user out for several minutes. When a step requires root, ask the user to run it themselves with the `!` prefix (e.g. `! sudo systemctl restart foo`) so output lands back in the conversation.

## Pull Requests

When creating GitHub PRs, do not include a "Test plan" section in the PR body unless explicitly requested.

## Python Package Management

Use `uv` as the default Python package manager. Prefer using `uv` for tasks such as:
- Managing dependencies in `pyproject.toml`
- Installing packages (`uv add`, `uv remove`)
- Running Python scripts (`uv run`)
- Creating virtual environments

## Python Development

- Use `ruff` for formatting
- Use `ty` for type checking
- Use the standard `logging` module instead of print statements

## JavaScript/TypeScript Package Management

Use `bun` as the default JavaScript/TypeScript runtime and package manager. Prefer using `bun` for tasks such as:
- Managing dependencies in `package.json`
- Installing packages (`bun add`, `bun remove`)
- Running scripts (`bun run`)
- Running tests (`bun test`)
