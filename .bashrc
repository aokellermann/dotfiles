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
alias vpn='nordvpn c United_States'
alias vpnd='nordvpn d'

# nvm
source /usr/share/nvm/init-nvm.sh

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
MANPATH=$MANPATH:"/opt/texlive/2023/texmf-dist/doc/man"
INFOPATH=$INFOPATH:"/opt/texlive/2023/texmf-dist/doc/info"
PATH=$PATH:"/opt/texlive/2023/bin/x86_64-linux"

# jetbrains
PATH=$PATH:"/home/aokellermann/.local/share/JetBrains/Toolbox/scripts"

# sway
alias sway-tree='swaymsg -r -t get_tree'

# compile latex
alias ltpdf='latexmk -output-format=pdf -output-directory=out -pvc -interaction=nonstopmode'

# needed by some tools like flutter
export CHROME_EXECUTABLE=/bin/google-chrome-stable

# kill tray chat apps
alias kall='killall slack Discord WhatsApp telegram-desktop'

# .env
alias eenv='f() { if [ -z "$1" ]; then FILE=".env"; else FILE="$1"; fi; if [ -f "$FILE" ]; then set -a; source "$FILE"; set +a; echo "Variables from $FILE exported"; else echo "File $FILE not found"; fi; }; f'

