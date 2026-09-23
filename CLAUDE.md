# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for swaywm on Arch Linux. The home directory itself is the git repository, with a `.gitignore` containing `*` so only explicitly tracked files are versioned. Tracked files are scattered throughout standard XDG locations (`~/.config/`, `~/.local/`, etc.).

## Repository Structure

This is **not** a typical project repo. The git working tree root is `$HOME`. Use `git ls-files` to see all tracked files (~60 config files, scripts, and keys).

### Key Configuration Files

- **Shell**: `.bashrc` - bash config with aliases, PATH setup, completions
- **Window Manager**: `.config/sway/config` - swaywm keybindings and window rules
- **Terminal**: `.config/kitty/kitty.conf` - kitty terminal emulator
- **Editor**: `.config/nvim/init.lua` - Neovim with kickstart.nvim (lazy.nvim plugin manager)
- **Git**: `.config/git/config` - git config with SSH signing configured (currently disabled by default)
- **Startup**: `.local/bin/runsway` - environment setup for starting sway from TTY
- **Editor Config**: `.editorconfig` - indentation/formatting rules (4-space default, 2 for YAML/JSON/TOML/Lua)

### Scripts in `.local/bin/`

- `runsway` - sway startup with environment variables (Wayland, XDG, Java, etc.)
- `gw` - git worktree helper with GitHub PR integration (add, cd, merge, rm, ls, prune)
- `power-profile-ac-switcher` - daemon for AC/battery power profile switching
- `sk-keygen <name>` - create YubiKey-backed FIDO2 SSH key (resident, verify-required) at `~/.ssh/<name>`. Note: the script always sets `verify-required`; the git signing key intentionally does NOT use it (see `~/.claude/rules/security.md`), so don't use this script to regenerate it.
- `upgrade-nitro.sh` - bumps the `nitro-bin`/`nitro-beta-bin` AUR packages (`~/repos/aur/`). Versions come from the NuGet atom feed for `ChilliCream.Nitro.App`; ChilliCream's CDN often lags NuGet by days (or skips Linux for an insider build) and its `latest-linux.yml`/`insider-linux.yml` are stale, so the script probes the CDN with a 1-byte ranged GET (HEAD 404s there even for existing files) and skips versions with no AppImage instead of failing on `wget`
- `caja-dconf-dump` / `caja-dconf-load` - Caja (file manager) settings live in dconf, not files; the dump script writes the tracked snapshot `~/.config/caja/dconf.ini` (org.mate.caja minus window-state, plus terminal=kitty and desktop-icons=false). Run the dump after changing Caja prefs, the load on a new machine
- `gdrive-open <files>` - default handler (via `~/.local/share/applications/gdrive-open.desktop` + `mimeapps.list`) for Office MIME types (doc/docx/odt/rtf, xls/xlsx/ods/csv, ppt/pptx/odp). For a file under an rclone Drive mount at `~/gdrive/<remote>/...` it looks up the Drive id with `rclone lsjson` and opens `docs.google.com/<document|spreadsheets|presentation>/d/<id>/edit` in the default browser; anywhere else it falls back to LibreOffice. Native Google Docs on the mount are `.link.html` stubs and don't go through this (see `~/repos/csai/CLAUDE.md`)
- `drive-collaborators-to-contacts [--apply] [--list]` - adds every external person granted direct access to a Drive file (files antony@safeai.org owns + all items in the CSAI shared drives, inherited shared-drive membership skipped) to that user's personal Google Contacts under the "Doc collaborators" label, deduped by email against existing contacts; names come from Drive's `displayName` or Gmail "Other contacts". Dry run by default. Needs GAM with the `contacts` DWD scope and the People API enabled on `infra-safeai` (see `~/repos/csai/infra/CLAUDE.md`). Domain shared contacts were rejected as the target (that API is effectively non-functional for us)
- `sway-wins.sh`, `waybar-power-profile` - system utilities

## Sway Keybindings (Mod = Super)

- `Mod+Return` - kitty terminal
- `Mod+d` - rofi launcher
- `Mod+l` - lock screen (swaylock-corrupter)
- `Mod+c` - chromium
- `Mod+n` - caja, launched with `GDK_BACKEND=wayland` (native Wayland works in 1.28; XWayland is blurry at scale 2) and `--no-desktop` (Caja otherwise draws a desktop-icons window and lingers after the last window closes)
- `XF86Assistant` (the Copilot/assistant key, no modifier) - voxtype voice-to-text toggle (`voxtype record toggle`); see Notes
- `Mod+1-9` - switch workspace (via sway_win_extra)
- `Mod+Tab` - tab between windows (sway-overfocus)
- `Mod+q` - `sway-kill-or-hide`: kills the focused window, except app_ids listed in the script (Gmail and Google Calendar PWAs) which are hidden to the scratchpad instead
- Scratchpads: `Mod+;` (terminal), `Mod+'` (python), `Mod+,` (spotify), `Mod+Shift+.` (beeper), `Mod+Alt+.` (signal), `Mod+Ctrl+.` (slack), `Mod+Alt+,` (Gmail PWA), `Mod+Ctrl+,` (Google Calendar PWA), `Mod+Alt+n` (Caja; runs under `dbus-run-session` with `--name scratch_caja` because Caja is single-instance and would otherwise hand the window to the `Mod+n` instance)

## Neovim Setup

Kickstart.nvim config in `.config/nvim/init.lua`:
- **Plugin manager**: lazy.nvim
- **LSP servers**: bashls, ruff, ts_ls, ty, lua_ls
- **Formatting** (conform.nvim): stylua, shfmt, ruff_format
- **Completion**: blink.cmp with luasnip
- **Key tools**: telescope, treesitter, gitsigns, which-key
- **Leader key**: Space

## Useful Bash Aliases

- `gs`, `gc`, `gch`, `gl`, `ga`, `gd`, `gf`, `gcp` - git shortcuts
- `d` - kitten diff (kitty git diff viewer)
- `c` - `claude --dangerously-skip-permissions`
- `sway-tree` - dump sway window tree as JSON
- `eenv [file]` - source .env file
- `v` - opens `$EDITOR`
- `y` - yazi file manager with directory tracking
- `ltpdf` - compile LaTeX to PDF with live preview

## PDF Manipulation

Use `qpdf` for PDF operations (`pdftk` is not installed). Common patterns:
- Page count: `qpdf --show-npages file.pdf`
- Merge/reorder pages: `qpdf --empty --pages file1.pdf 1-6 file2.pdf 1 -- out.pdf`
- Split: `qpdf --pages file.pdf 1-3 -- out.pdf`

## Notes

- SSH agent provided by `rbw-agent` at `$XDG_RUNTIME_DIR/rbw/ssh-agent-socket` (signs with SSH-key entries from Bitwarden); run `rbw unlock` once per session
- Git commit/tag signing is currently disabled (`commit.gpgSign`/`tag.gpgSign` = false); the SSH signing infrastructure (`user.signingkey`, `gpg.format = ssh`, `allowedSignersFile`) remains configured, so re-enabling is a one-line flip. See `~/.claude/rules/security.md`
- Electron apps require `--enable-features=UseOzonePlatform --ozone-platform=wayland` flags
- Docker uses containerd image store with XFS at `/xfs/containerd`
- **Google Calendar PWA (PWAsForFirefox)**: site id `01M32VGE3QTNP9CESHNE60B0YQ` in its **own** profile `01M32VGAM8GTZ3GB7ZJ73T6G9Q` (reinstalled 2026-09-21; it originally shared Gmail's profile, but Firefox does session restore once per profile, so whichever PWA launched first "won" and Gmail came up with a single inbox tab instead of its four). Never install another site into Gmail's profile `00000000000000000000000000`. app_id `FFPWA-01M32VGE3QTNP9CESHNE60B0YQ`, scratchpad on `$mod+Ctrl+,`, hidden not killed by `$mod+q`. Installed from `https://calendar.google.com/calendar/manifest.json` with `--start-url https://calendar.google.com/calendar/u/0/r`. Google ships no desktop client for any OS; GNOME Calendar/Merkuro/Thunderbird only sync via CalDAV, hence the PWA.
- **Gmail PWA (PWAsForFirefox)**: site id `01KB2A6YB46NWKC0CDG5S1K126`, launch with `firefoxpwa site launch <id>`; sway app_id `FFPWA-<id>`. Prefs live in the shared profile `~/.local/share/firefoxpwa/profiles/00000000000000000000000000/user.js`: `firefoxpwa.enableTabsMode=true` shows the tab strip, but the `+`/Ctrl+T do nothing unless `firefoxpwa.linksTarget=3` (default 1 = "current tab" rewrites every addTab into the current tab). Kill the PWA before editing user.js; relaunch to apply. `browser.startup.page=3` restores the four inbox tabs if it is ever killed; normally `$mod+q` only hides it (see `sway-kill-or-hide`) and `$mod+Alt+,` toggles it.
- **voxtype (voice-to-text)**: `voxtype-bin` AUR package, daemon via `voxtype.service` (user, enabled). Engine is Parakeet `parakeet-tdt-0.6b-v3`, which only exists in the ONNX build, so `/usr/bin/voxtype` is manually symlinked (as root, 2026-09-23) to `/usr/lib/voxtype/voxtype-onnx-avx2` instead of the Whisper-only `voxtype-avx2` the package installs by default; re-check the symlink after package upgrades (`voxtype info variants`). `voxtype setup onnx --enable` would do the same but needs root and refuses to run under sudo. Config `~/.config/voxtype/config.toml`, models in `~/.local/share/voxtype/models`. Sway: `XF86Assistant` runs `voxtype record toggle` (`[hotkey] enabled = false`, so the evdev listener is off; `state_file = "auto"` is required for `toggle`) and `~/.config/sway/conf.d/voxtype-mode.conf` (generated by `voxtype setup compositor sway`, pulled in via `include ~/.config/sway/conf.d/*.conf`) defines the recording/suppress modes, entered via the `pre_recording_command`/`pre_output_command`/`post_output_command` hooks (`swaymsg mode ...`) in config.toml; F12 escapes if it wedges. It was `$mod+x` at first, but wtype's fake keypresses combine with a still-held Super, so voxtype's `wait_for_modifier_release` guard fell back to the clipboard with a "modifier key was held too long" notification whenever Super was held >750 ms after stopping; the guard is now off (`wait_for_modifier_release = false`) and a modifier-free key sidesteps the whole problem. Upstream docs: `docs/USER_MANUAL.md` "Compositor Keybindings", `docs/TROUBLESHOOTING.md` "Modifier Key Interference". Desktop notification `on_transcription` is off; the gtk4 OSD overlay is disabled (`[osd] enabled = false`) since the sway mode indicator in the bar already shows `voxtype_recording`. Parakeet is English-only and CPU-only (no Vulkan/Intel path; do not run `voxtype setup gpu --enable`, it swaps the binary to the Whisper Vulkan variant). The daemon does not hot-reload config: `systemctl --user restart voxtype` after edits; `voxtype config set` only knows a subset of keys, edit the file for the rest. Replaced voxd (`~/repos/voxd`, tray service removed) and talkat (`~/repos/talkat`, sway exec removed) on 2026-09-23.
- System updates managed by `topgrade` (`.config/topgrade.toml`)
- **acroread-dc-wine**: the Wine prefix (`~/.local/share/acroread-dc-wine`) has `HKCU\Software\Wine\Drivers\Graphics = wayland` set (2026-07-20). Default X11/XWayland driver caused two problems on sway at scale 2.0: blurry rendering (XWayland 1x buffers upscaled) and general X11 focus quirks. Revert with `wine reg delete "HKCU\Software\Wine\Drivers" /v Graphics /f`. Separately, text entries in the digital ID/signing dialogs were dead under BOTH drivers: those dialogs are rendered by RdrCEF.exe (Acrobat's embedded Chromium), whose input routing is broken under Wine — native Win32 dialogs were unaffected. Fix (two parts, both required): (1) `bEnableCEFBasedUI = 0` (DWORD) in `HKCU\Software\Adobe\Acrobat Reader\DC\Security\cPubSec` (also set in `HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cSecurity\cPubSec`), which reverts signing/digital-ID workflows to legacy native dialogs; (2) `*riched20 = builtin` DLL override — the legacy dialogs build their text fields as RichEdit controls, and the winetricks-native riched20.dll fails to load under Wine 11 WoW64, so with `native` the edit boxes silently don't render (labels with no fields). Verified working 2026-07-30 (fields render + accept typed input). Also set: `LogPixels = 144` (HKCU\Control Panel\Desktop) so Wine UI/dialogs aren't tiny on HiDPI outputs, and comdlg32 Placesbar entries pointing at `~/dl`, `~/docs`, `~`. Acrobat launches WITHOUT the Wine virtual desktop by default now (`ACROREAD_NO_VIRTUAL_DESKTOP=1` via `~/.local/bin/acroread-dc` wrapper + `~/.local/share/applications/acroread-dc.desktop` override) — the VD rendered as a fullscreen black backdrop and made dialogs jump around; the only VD benefit is Acrobat's tab bar. Delete the wrapper + desktop override to restore VD mode. If Acrobat signing ever breaks again, `pyhanko` (via uv) can sign PDFs with a PKCS#12 as a fallback.

## GIMP drawings

Headless drawing/editing via GIMP 3 Python batch mode is documented in `~/.claude/rules/gimp.md` (invocation, API cheat sheet, techniques); working example scripts and a runner are in `~/.local/share/gimp-drawings/`. Key trap: `--quit` is mandatory or GIMP never exits.
