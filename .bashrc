# return if not interactive
[[ $- != *i* ]] && return

# don't put duplicate lines in bash history
# don't put lines staring with space in bash history
HISTCONTROL=ignoreboth

# history size
HISTSIZE=1000
HISTFILESIZE=2000

# append to bash history file instead of overwriting
shopt -s histappend

# check window size after each command in order to update LINES and COLUMNS
shopt -s checkwinsize

# path
PATH=$PATH:.local/bin

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

# VPN
alias vpn='nordvpn c United_States'
alias vpnd='nordvpn d'

# nvm
source /usr/share/nvm/init-nvm.sh

# sway-win-extra
export MON0="SDC 0x4193 Unknown"
export MON1="AOC 2367 AJMG79A000532"
export MON2="AOC 2367 AJMG79A000521"

# git
alias gs='git status'
alias gc='git commit -m'
alias gch='git checkout'
alias gl='git log'
alias ga='git add -A'
alias gd='git diff'

# check filesystem usage
alias sdu='du -csh ./* | sort -h'