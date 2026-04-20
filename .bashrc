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

alias v="$EDITOR"
complete -o default -o filenames v

# ranger
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd <"$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# git
alias gs='git status'
alias gc='git commit'
alias gch='git checkout'
alias gl='git log'
alias ga='git add -A'
alias gd='git diff'
alias gf='git fetch --all'
alias gcp='git cherry-pick'

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

# sway
alias sway-tree='swaymsg -r -t get_tree'

# compile latex
alias ltpdf='latexmk -output-format=pdf -output-directory=out -pvc -interaction=nonstopmode'

# .env
alias eenv='f() { if [ -z "$1" ]; then FILE=".env"; else FILE="$1"; fi; if [ -f "$FILE" ]; then set -a; source "$FILE"; set +a; echo "Variables from $FILE exported"; else echo "File $FILE not found"; fi; }; f'

# chrome debugging
alias chromium-debug='chromium --remote-debugging-port=9222 --no-sandbox --disable-gpu'

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

# user completions
for f in "$HOME/.local/share/bash-completion/completions"/*; do
    [[ -f "$f" ]] && source "$f"
done

# cve-bench
source "$HOME/repos/cve-benchmark-stress/completions/run.bash"
# source "$HOME/repos/cve-aws/completions/run.bash"

# zoxide
eval "$(zoxide init bash)"
