# User-Level Claude Instructions

## Git Branch Naming

When creating git branches, always prefix them with `aokellermann/` followed by a descriptive kebab-case name.

Examples:
- `aokellermann/fix-login-bug`
- `aokellermann/add-user-settings`
- `aokellermann/refactor-api-client`

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
