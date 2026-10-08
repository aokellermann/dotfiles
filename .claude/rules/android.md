# Android phone over ADB (real-device web checks)

Antony's phone is a **Pixel 10** (Android 17, 1080×2424 @ 420 dpi → 411 CSS px wide, dpr 2.625). It is reachable
over USB with `adb` (`android-tools`, installed 2026-09-29; USB debugging on, this laptop authorised). Browsers on it:
**Firefox** (`org.mozilla.firefox`, his daily browser, bottom toolbar) and Chrome (`com.android.chrome`). Use it to
verify mobile layouts of CSAI web UIs (site, blast, ...) instead of trusting desktop Chromium's device emulation,
which missed a real bug (2026-09-29: `100dvh` mis-laid the safeai.org landing page in Firefox Android).

## `phone-page` (dotfiles, `~/.local/bin/phone-page`, bun)

```
phone-page <url> [--browser firefox|chrome] [--shot out.png] [--eval '<js>'] [--wait ms] [--no-nav]
```

- Opens the URL on the phone and screencaps the whole screen (`adb exec-out screencap -p`) to `--shot`
  (default `./phone.png`); Read the PNG to look at it.
- Evaluates JS in the page and prints it as JSON: by default a layout dump (innerWidth/Height, scroll size,
  visualViewport, what `100vh` and `100dvh` resolve to, boxes of `.mark`/`h1`/`footer`/`iframe`); `--eval` for any
  expression (must be JSON-serialisable).
- **Chrome**: works with USB debugging alone (socket `@chrome_devtools_remote`, forwarded to :9222, playwright
  `connectOverCDP`). Navigation goes through `page.goto` in the existing tab.
- **Firefox**: needs Firefox's own toggle, Settings → Advanced → **Remote debugging via USB** (enabled 2026-09-29;
  the socket is the abstract `@org.mozilla.firefox/firefox-debugger-socket`, package-prefixed, forwarded to :6000). The script speaks Firefox's remote debugging protocol directly
  (`listTabs` → `getTarget` → console `evaluateJSAsync`); playwright cannot attach to Firefox Android. Without the
  toggle you still get the screenshot, just no metrics. Navigation is `location.href` in the selected tab, then a
  reconnect (the console actor dies with the document).
- `--no-nav` inspects whatever tab is in front (useful after Antony navigated by hand).
- `adb shell 'cat /proc/net/unix' | grep -iE 'devtools|debugger'` lists the exposed sockets;
  `adb devices` must say `device`, not `unauthorized` (accept the prompt on the phone).

Other handy bits: `adb shell am start -a android.intent.action.VIEW -d <url> <pkg>` opens a URL in a given browser;
`scrcpy` (installed) mirrors the screen live; `adb shell input tap X Y` / `input swipe` for interaction.

Desktop emulation (`site/scripts/mobile-shots.ts`, playwright device descriptors) is still fine for a first pass at
many sizes; confirm on the phone before calling a mobile issue fixed.

Measured 2026-09-29 on the fixed safeai.org page: Firefox 156 reports innerHeight 774, `100vh` 839, `100dvh` 774
(correct), yet the earlier `min-height: 100dvh` build had laid the page out far taller in Antony's screenshot, so the
trigger is state-dependent (toolbar/first paint) and not reproduced on demand. Percentage heights sidestep it.
