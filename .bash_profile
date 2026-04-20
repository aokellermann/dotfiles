# Env vars + PATH: run once per login, inherited by children.
# Edits here require re-login (or `source ~/.bash_profile`) to take effect.

# XDG
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"

# Editor / pager
export EDITOR=nvim
export VISUAL=nvim
export PAGER="bat -p"
export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"

# Language toolchains
export GOPATH="$HOME/.go"
export PNPM_HOME="$HOME/.local/share/pnpm"

# Misc
export YDOTOOL_SOCKET="$HOME/.ydotool_socket"
export CHROME_EXECUTABLE=/usr/bin/chromium

# PATH — idempotent prepend so re-sourcing is safe
_prepend_path() {
    case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac
}
_prepend_path "$HOME/.local/bin"
_prepend_path "$PNPM_HOME"
_prepend_path "$HOME/.cache/.bun/bin"
_prepend_path "$HOME/.cabal/bin"
_prepend_path "$HOME/.ghcup/bin"
unset -f _prepend_path

# Rust (sets PATH + env)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# TeX Live (version-agnostic)
for d in /usr/local/texlive/*/bin/x86_64-linux; do
    [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$PATH:$d" ;; esac
done
for d in /usr/local/texlive/*/texmf-dist/doc/man; do
    [ -d "$d" ] && MANPATH="${MANPATH}:$d"
done
for d in /usr/local/texlive/*/texmf-dist/doc/info; do
    [ -d "$d" ] && INFOPATH="${INFOPATH}:$d"
done
export PATH MANPATH INFOPATH

# Interactive shell setup
[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
