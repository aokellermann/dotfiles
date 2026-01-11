# return if not interactive
#
[[ $- != *i* ]] && return

# don't put duplicate lines in bash history
# don't put lines staring with space in bash history
HISTCONTROL=ignoreboth

# history size
HISTSIZE=10000
HISTFILESIZE=20000

# append to bash history file instead of overwriting
shopt -s histappend

# check window size after each command in order to update LINES and COLUMNS
shopt -s checkwinsize

# path - prepend to avoid duplicates on re-source
PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:${PATH}"

# colors
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"
MAGENTA2="$(tput setaf 13)"
RESET="$(tput sgr0)"

# use color
alias ls='ls --color=auto --hyperlink=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ls
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# PS1
PS1='\[${BLUE}\][\[${RESET}\]\[$MAGENTA\]\u\[${RESET}\]\[${MAGENTA2}\]@\[${RESET}\]\[${BLUE}\]\h\[${RESET}\] \[${MAGENTA}\]\W\[${RESET}\]\[${BLUE}\]]\[${RESET}\]\[${MAGENTA2}\]\$\[${RESET}\] '

# editors
export EDITOR=nvim
export VISUAL=nvim
alias v='nvim'
complete -o default -o filenames v

# ranger
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# VPN
alias vpn='nordvpn set killswitch on && nordvpn c United_States'
alias vpnd='nordvpn set killswitch off &&nordvpn d'

# git
export GIT_EMPTY_TREE_HASH="$(git hash-object -t tree /dev/null)"
alias gs='git status'
alias gc='git commit'
alias gch='git checkout'
alias gl='git log'
alias ga='git add -A'
alias gd='git diff'
alias gf='git fetch --all'
alias gcp='git cherry-pick'

# git worktree helper
source "$HOME/.local/bin/gw.bash"

# git alias completions
source /usr/share/git/completion/git-completion.bash
__git_complete gs _git_status
__git_complete gc _git_commit
__git_complete gch _git_checkout
__git_complete gl _git_log
__git_complete ga _git_add
__git_complete gd _git_diff
__git_complete gf _git_fetch
__git_complete gcp _git_cherry_pick

# docker
alias ddv='docker compose down --volumes'
alias dcu='docker compose up -d'
alias dcub='dcu --build'
alias dimg='docker history --no-trunc $1 | tac | tr -s " " | cut -d " " -f 5- | sed "s,^/bin/sh -c #(nop) ,,g" | sed "s,^/bin/sh -c,RUN,g" | sed "s, && ,\n  & ,g" | sed "s,\s*[0-9]*[\.]*[0-9]*\s*[kMG]*B\s*$,,g" | head -n -1'

# texlive (version-agnostic paths)
for texlive_dir in /usr/local/texlive/*/bin/x86_64-linux; do
    [ -d "$texlive_dir" ] && PATH="$PATH:$texlive_dir"
done
for texlive_man in /usr/local/texlive/*/texmf-dist/doc/man; do
    [ -d "$texlive_man" ] && MANPATH="$MANPATH:$texlive_man"
done
for texlive_info in /usr/local/texlive/*/texmf-dist/doc/info; do
    [ -d "$texlive_info" ] && INFOPATH="$INFOPATH:$texlive_info"
done

# sway
alias sway-tree='swaymsg -r -t get_tree'

# compile latex
alias ltpdf='latexmk -output-format=pdf -output-directory=out -pvc -interaction=nonstopmode'

# needed by some tools like flutter
export CHROME_EXECUTABLE=/usr/bin/chromium

# .env
alias eenv='f() { if [ -z "$1" ]; then FILE=".env"; else FILE="$1"; fi; if [ -f "$FILE" ]; then set -a; source "$FILE"; set +a; echo "Variables from $FILE exported"; else echo "File $FILE not found"; fi; }; f'

# mirrors
alias rank-mirrors='reflector --protocol https --latest 50 --fastest 8 --age 24 --sort rate --country us --save /etc/pacman.d/mirrorlist'

# chrome debugging
alias chromium-debug='chromium --remote-debugging-port=9222 --no-sandbox --disable-gpu'


# pnpm
export PNPM_HOME="/home/aokellermann/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun
export PATH="$HOME/.cache/.bun/bin:$PATH"

# haskell
export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"

# bitwarden secret (lazy-loaded on first use)
bws() {
    if [ -z "$BWS_ACCESS_TOKEN" ]; then
        export BWS_ACCESS_TOKEN=$(secret-tool lookup service bws account access-token)
    fi
    command bws "$@"
}

# kitten diff
alias kgd='git difftool --no-symlinks --dir-diff'
_kgd_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(compgen -W "$(git diff --name-only 2>/dev/null)" -- "$cur"))
}
complete -F _kgd_completion kgd

# claude code
source "$HOME/.local/share/bash-completion/completions/claude"

# cve-bench
source "$HOME/repos/cve-benchmark-bash-completions/completions/run.bash"

# zoxide
eval "$(zoxide init bash)"
