# Telegram read access via telegram-mcp

An MCP server named `telegram` (user scope in `~/.claude.json`) exposes the user's Telegram account through
[chigwell/telegram-mcp](https://github.com/chigwell/telegram-mcp) (Telethon / MTProto, Python). Installed 2026-09-06.

## Layout

- **Code**: `~/.local/share/telegram-mcp` (git clone, `uv sync`; dir is 700). Update with `git pull && uv sync`.
- **Config**: `~/.local/share/telegram-mcp/.env` (600). Holds `TELEGRAM_API_ID`, `TELEGRAM_API_HASH` (from
  https://my.telegram.org/apps) and `TELEGRAM_SESSION_STRING`. The session string is account-equivalent — treat it like
  the twitter/facebook storage-state files; file perms are the only barrier.
- **Command**: `uv run --directory ~/.local/share/telegram-mcp main.py` (stdio). `load_dotenv()` reads `.env` from that
  directory, so `--directory` is load-bearing.
- **Tool surface**: `TELEGRAM_EXPOSED_TOOLS=read-only` — only tools with `readOnlyHint` are registered (list chats,
  history, search, contacts, media download). No sending, joining, editing. To allow a specific write tool append it:
  `read-only+send_message`. Do not flip to `all` without asking.
- Do **not** `pip install telegram-mcp` / `uvx telegram-mcp`: that PyPI name is a different project.

## First-time login / re-login

Interactive, user runs it with the `!` prefix:
```
! uv run --directory ~/.local/share/telegram-mcp session_string_generator.py --qr
```
(`--phone` for phone+code login.) Paste the printed string into `TELEGRAM_SESSION_STRING` in `.env`, then
`claude mcp get telegram` should show connected (restart Claude Code to pick it up).

`CONNECTION_CLOSED` from `claude mcp get telegram` with empty credentials is expected until this is done.

## Usage notes

- Public channels can also be read without any login via the web preview `https://t.me/s/<channel>` (curl + parse
  `tgme_widget_message_text`); use that for quick public lookups. The MCP is needed for private groups/DMs.
- Telegram forbids one session from two IPs at once (`AuthKeyDuplicatedError`); if the MCP is also used from another
  machine, generate a second session string and set `TELEGRAM_SESSION_STRINGS` (pool).
- STC / Nexus context: channel `nexus_search`; the "Freetalks" group is where IPFS seeding details are discussed.
