# Facebook / Instagram read access via Playwright MCP

Authenticated facebook.com and instagram.com read access is wired up through an MCP server named `facebook` in `~/.claude.json`. Same architecture as the `twitter` MCP — cookie-based, no API costs.

## Architecture

Meta blocks login flows from Playwright-controlled browsers. The workaround is identical to the twitter MCP: log in via real Firefox once, extract session cookies, inject them into a headless Playwright-Chromium via `--storage-state`. Meta gates the *login page* against automation but authenticated browsing works fine from headless chromium once the right cookies are present.

Components:
- **MCP server**: `playwright-mcp` (shared with twitter MCP)
- **Browser**: Playwright-Chromium
- **Mode**: `--isolated --storage-state <path> --browser chromium`
- **Storage state**: `~/.config/claude-facebook-profile/storage-state.json` (chmod 600, in a 700 dir, ignored by dotfiles `*` gitignore)
- **Cookie extractor**: `~/.local/bin/facebook-cookies-export` (Python stdlib only)
- **Allowed origins**: facebook.com, fbcdn.net, instagram.com, cdninstagram.com + subdomains

The storage-state JSON is account-equivalent for both Facebook and Instagram (since IG auth flows through the same Meta SSO once a Firefox session has logged in there). Treat it like a Bitwarden secret — file perms are the only barrier against a user-level compromise.

## Refresh procedure

Run `facebook-cookies-export`. The script reads `cookies.sqlite` from the default Firefox profile, filters to exact-match `facebook.com`/`.facebook.com`/`instagram.com`/`.instagram.com` hosts, and writes Playwright storage-state JSON.

The script errors out if no `c_user` (Facebook user-id) or `xs` (Facebook session secret) cookie is found — those are the auth-equivalent of x.com's `auth_token` + `ct0`. If they're missing, Firefox isn't logged into facebook.com.

For Instagram-only access, the relevant cookie is `sessionid` on `.instagram.com`; the extractor pulls it automatically alongside FB cookies but doesn't require it to succeed.

Refresh cadence is similar to twitter (long-lived session cookies — months) — only needed when reads start failing.

## Using the MCP

Same tool surface as the twitter MCP — `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_evaluate`, `browser_wait_for`. Navigation is confined to the configured allowed origins.

### URL patterns

**Facebook:**
- `https://www.facebook.com/<page-or-user>` — profile/page wall
- `https://www.facebook.com/<page>/posts/<id>` — specific post
- `https://www.facebook.com/<page>/photos/<slug>/<id>` — photo post
- `https://www.facebook.com/<page>/videos/<id>` — video post

**Instagram:**
- `https://www.instagram.com/<handle>/` — profile (logged-out shows only metadata; logged-in shows recent posts)
- `https://www.instagram.com/p/<shortcode>/` — specific post
- `https://www.instagram.com/reel/<shortcode>/` — reel

### Reading content

- **Prefer `browser_snapshot` over `browser_take_screenshot`** for text extraction.
- **Infinite scroll**: Facebook walls and Instagram profiles use scroll-driven pagination; use `browser_evaluate` with `window.scrollBy(0, 4000)` repeatedly. Both sites render fewer items per scroll than X — be patient.
- **Wait before snapshotting**: both sites show skeleton loaders for 2-3s after navigation. `browser_wait_for` on a known string, or `setTimeout` 4s, before the first snapshot.
- **Post dates on Facebook**: hover over the relative timestamp (e.g. "3d") to see the absolute date in the tooltip — or read the `data-utime` attribute / `<time datetime=...>` element in the DOM via `browser_evaluate`.

### Gotchas

- **Checkpoint / `/checkpoint/` redirect = session flagged for security challenge**. Log into Firefox, complete the challenge (typically email confirmation), re-run `facebook-cookies-export`.
- **Rate limiting**: Meta is more aggressive than X. Human-paced reads only — don't loop `browser_navigate` over dozens of profiles back-to-back; insert delays. Account lockouts here are recoverable but more disruptive than on X.
- **No write operations**: read-only by convention. No posting, liking, commenting, friending.
- **Instagram requires the FB session for some endpoints** if Instagram-via-Facebook login was used; the extractor pulls both cookie sets to cover this.
- **`--isolated` means no localStorage** — fine for reading, breaks some Meta features (some draft persistence, some compose flows) that aren't relevant for reads.

## Do not propose

- Graph API / Instagram Graph API — both require a Meta business account, app review, and tightly scoped tokens; unsuitable for personal-scale reading.
- CrowdTangle — Meta sunset it in August 2024.
- Real Chrome from AUR — was considered for twitter, turned out unnecessary; same here.
- Playwright with `--browser firefox` — Meta blocks the login flow there too.
- `instaloader` / `facebook-scraper` / other reverse-engineered Python clients — break frequently and risk the account at any volume. Playwright path is more stable.
