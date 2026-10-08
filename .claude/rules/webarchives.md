# Web archives: finding old copies of a URL

For any "was this page different before", "when was this text removed", or "find an archived copy"
question, use the `webarchives` tool before hand-rolling curl queries against archive APIs. Source:
`~/repos/webarchives` (private GitHub `aokellermann/webarchives`, uv project, `CLAUDE.md` + README
"Things worth knowing" hold the operational detail). Installed globally via
`uv tool install --editable ~/repos/webarchives`, so `webarchives` is on PATH in every repo; edits to
the source take effect immediately.

```sh
webarchives search <url> [--before 14h|3d|2026-10-06T02:00] [--sources wayback,archive.today]
webarchives fetch <capture-url> -o out.html      # Wayback raw bytes; archive.today -> captcha guidance
webarchives grep '<regex>' <file-or-capture-url>  # [visible] vs [embedded] (SSR JSON / scripts) hits
webarchives text <file-or-capture-url> [--all]
webarchives archivetoday-ip
```

Library: `from webarchives import search` → `SearchResult` with `.captures` (sorted, UTC) and
per-archive `.errors`, so "unreachable" stays distinct from "no copy".

Covers Wayback (CDX + raw `id_` fetch), archive.today, Ghostarchive, Megalodon, arquivo.pt, Common
Crawl, Memento. Key quirks it already handles (details in the repo README):

- archive.today DNS is poisoned for public resolvers (203.0.113.250); the client pins a real IP with
  correct SNI. Snapshot pages are reCAPTCHA-gated: never try to solve it, have the user open the URL in
  a browser (with the printed `/etc/hosts` line) and "Save as HTML only", then run `grep`/`text` on the file.
- archive.today snapshots are the rendered DOM with scripts stripped, so collapsed accordions and
  SSR JSON are absent. A snapshot cannot prove text was missing from the page.
- Wayback serves a "Temporarily Offline" page with HTTP 200 during maintenance (raised as
  `ArchiveOffline`, not treated as zero results); raw bodies may be gzip without a header.
- Read-only everywhere. Do not add page-saving or captcha-bypass features.
