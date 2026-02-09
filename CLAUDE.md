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
- **Git**: `.config/git/config` - git config with SSH signing via Bitwarden
- **Startup**: `.local/bin/runsway` - environment setup for starting sway from TTY
- **Editor Config**: `.editorconfig` - indentation/formatting rules (4-space default, 2 for YAML/JSON/TOML/Lua)

### Scripts in `.local/bin/`

- `runsway` - sway startup with environment variables (Wayland, XDG, Java, etc.)
- `gw` - git worktree helper with GitHub PR integration (add, cd, merge, rm, ls, prune)
- `sfpi` - sandboxed IPFS wrapper using firejail
- `power-profile-ac-switcher` - daemon for AC/battery power profile switching
- `bw-ssh-agent` - SSH agent integrating with Bitwarden
- `sway-wins.sh`, `waybar-power-profile`, `upgrade-nitro.sh` - system utilities

## Sway Keybindings (Mod = Super)

- `Mod+Return` - kitty terminal
- `Mod+d` - rofi launcher
- `Mod+l` - lock screen (swaylock-corrupter)
- `Mod+c` - firefox
- `Mod+j` - cursor IDE
- `Mod+1-9` - switch workspace (via sway_win_extra)
- `Mod+Tab` - tab between windows (sway-overfocus)
- Scratchpads: `Mod+;` (terminal), `Mod+'` (python), `Mod+,` (spotify), `Mod+.` (beeper)

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
- `kgd` - kitten diff (kitty git diff viewer)
- `sway-tree` - dump sway window tree as JSON
- `eenv [file]` - source .env file
- `v` - opens `$EDITOR`
- `y` - yazi file manager with directory tracking
- `ltpdf` - compile LaTeX to PDF with live preview

## Notes

- SSH agent managed by Bitwarden desktop via `.bitwarden-ssh-agent.sock`
- Git commits are GPG signed using SSH keys (format = ssh)
- Electron apps require `--enable-features=UseOzonePlatform --ozone-platform=wayland` flags
- Docker uses containerd image store with XFS at `/xfs/containerd`
- IPFS runs sandboxed through firejail over a Mullvad WireGuard interface
- System updates managed by `topgrade` (`.config/topgrade.toml`)
