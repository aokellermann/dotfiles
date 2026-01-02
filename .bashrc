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

# path
PATH=$PATH:"~/.local/bin"
PATH=$PATH:"~/.dotnet/tools"

# colors
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"
MAGENTA2="$(tput setaf 13)"
RESET="$(tput sgr0)"

# use color
alias ls='ls --color=auto'
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
export EDITOR=vim
export VISUAL=vim

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

# docker
alias ddv='docker compose down --volumes'
alias dcu='docker compose up -d'
alias dcub='dcu --build'
alias dimg='docker history --no-trunc $1 | tac | tr -s " " | cut -d " " -f 5- | sed "s,^/bin/sh -c #(nop) ,,g" | sed "s,^/bin/sh -c,RUN,g" | sed "s, && ,\n  & ,g" | sed "s,\s*[0-9]*[\.]*[0-9]*\s*[kMG]*B\s*$,,g" | head -n -1'

# check filesystem usage
alias sdu='du -csh $(find . -maxdepth 1 -mindepth 1) | sort -h'

# texlive
MANPATH=$MANPATH:"/usr/local/texlive/2025/texmf-dist/doc/man"
INFOPATH=$INFOPATH:"/usr/local/texlive/2025/texmf-dist/doc/info"
PATH=$PATH:"/usr/local/texlive/2025/bin/x86_64-linux"

# jetbrains
PATH=$PATH:"/home/aokellermann/.local/share/JetBrains/Toolbox/scripts"

# sway
alias sway-tree='swaymsg -r -t get_tree'

# compile latex
alias ltpdf='latexmk -output-format=pdf -output-directory=out -pvc -interaction=nonstopmode'

# needed by some tools like flutter
export CHROME_EXECUTABLE=/usr/bin/chromium

# kill tray chat apps
alias kall='killall slack Discord WhatsApp telegram-desktop'

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
export PATH="/home/aokellermann/.cache/.bun/bin:$PATH"

# haskell
export PATH="$HOME/.cabal/bin:$HOME/.ghcup/bin:$PATH"

# bitwarden secret
export BWS_ACCESS_TOKEN=$(secret-tool lookup service bws account access-token)
