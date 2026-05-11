# Twitter/X read access via Playwright MCP

Authenticated x.com read access is wired up through an MCP server named `twitter` in `~/.claude.json`. Cookie-based, no API costs, no Twitter API account needed.

## Architecture

X's anti-automation blocks login flows from Playwright-controlled browsers (both Chromium and Firefox channels, regardless of `--browser` flag). The workaround: log in via real Firefox once, extract session cookies, inject them into a headless Playwright-Chromium via `--storage-state`. X only gates the *login page* against automation — authenticated browsing works fine from headless chromium once `auth_token` + `ct0` are present.

Components:
- **MCP server**: `playwright-mcp` (global bun install: `bun add -g @playwright/mcp playwright`)
- **Browser**: Playwright-Chromium (downloaded via `playwright install chromium`)
- **Mode**: `--headless --isolated --storage-state <path> --browser chromium` (in-memory profile, cookies pre-loaded each launch, no visible window)
- **Storage state**: `~/.config/claude-twitter-profile/storage-state.json` (chmod 600, in a 700 dir, ignored by dotfiles `*` gitignore)
- **Cookie extractor**: `~/.local/bin/twitter-cookies-export` (Python stdlib only)
- **Allowed origins** (set on MCP server): x.com, twitter.com, twimg.com + subdomains

The storage-state JSON is account-equivalent. Treat it like a Bitwarden secret — file perms are the only barrier against a user-level compromise.

## Refresh procedure

Run `twitter-cookies-export`. The script reads `cookies.sqlite` from the default Firefox profile (resolved via `[Install*]` section in `profiles.ini`, NOT the stale `Default=1` profile flag), filters to exact-match `x.com`/`.x.com`/`twitter.com`/`.twitter.com` hosts, converts Firefox's millisecond-precision `expiry` to seconds (Firefox stores ms despite older docs saying seconds; Playwright rejects timestamps > 1e12), maps `sameSite` integers to strings, writes Playwright storage-state JSON.

Current `auth_token` expires ~2027-09-19, so refresh is infrequent — only needed when reads start failing (session invalidated, password change, X security challenge). The extractor errors out if no `auth_token` cookie is found, which means Firefox isn't logged into x.com.

## Using the MCP

Tools are exposed under names like `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_evaluate`, `browser_wait_for`. The MCP confines navigation to the configured allowed origins.

### URL patterns

- `https://x.com/home` — your timeline (For You / Following tabs)
- `https://x.com/<handle>` — user profile
- `https://x.com/<handle>/with_replies` — profile including replies
- `https://x.com/<handle>/media` — profile media tab
- `https://x.com/<handle>/status/<id>` — single tweet + thread
- `https://x.com/i/bookmarks` — your bookmarks
- `https://x.com/search?q=<query>&f=live` — latest results (omit `&f=live` for "Top")
- `https://x.com/i/lists/<list_id>` — list timeline
- `https://x.com/notifications` — notifications

### Reading content

- **Prefer `browser_snapshot` over `browser_take_screenshot`** for text extraction — it returns a structured accessibility-tree dump that's far cheaper than image tokens, and x.com's content is text-heavy.
- **Infinite scroll**: x.com only renders ~10-20 posts initially. To see more, use `browser_evaluate` with `window.scrollBy(0, 5000)` (or repeated), then re-snapshot. There's no "page 2" — it's all scroll-driven.
- **Wait before snapshotting**: x.com sometimes shows a "Something went wrong" placeholder for the first 1-2s after navigation. `browser_wait_for` on a known element, or sleep ~2s, before the first snapshot.

### Gotchas

- **`/i/flow/login` redirect = session invalidated**. Re-run `twitter-cookies-export`. If that doesn't help, log into Firefox again.
- **Rate limiting**: x.com is aggressive about flagging rapid navigation. Human-paced reads only — don't loop `browser_navigate` over hundreds of profiles. Account lockouts are recoverable by logging into the real Firefox and completing a challenge, but disruptive.
- **No write operations**: this setup is explicitly read-only by convention. Posting, liking, following etc. through the MCP risks the account in ways that aren't worth it. If write access is ever needed, use a separate authenticated session and accept the lockout risk knowingly.
- **`--isolated` means no localStorage/cache** — each MCP session is fresh cookies only. Rare X features that depend on localStorage state (some draft persistence, some prefs) won't work; reading doesn't need them.

## Do not propose

- Twitter API v2 — paywalled at $200/mo Basic tier for any useful read access.
- Real Google Chrome from AUR — was considered when cookie-injection seemed blocked; turned out unnecessary once `--storage-state` worked.
- Playwright with `--browser firefox` — tested, X blocks the login flow there too.
- ssh-agent-style cookie helpers / encrypted-at-rest wrappers around storage-state.json — overkill; file perms in a 700 dir are the accepted boundary, same threat model as the rest of the credentials section in `security.md`.
- `twikit` or other reverse-engineered GraphQL clients — break frequently when X changes endpoints, and using them at any volume risks the account. Playwright path is more stable.
