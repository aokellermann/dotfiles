# gw shell function wrapper (source this file)
# The actual script is at ~/.local/bin/gw

_gw_set_kitty_tab() {
    [[ -n "$KITTY_WINDOW_ID" ]] && kitty @ set-tab-title "$1" 2>/dev/null
}

gw() {
    if [[ "$1" == "cd" ]]; then
        local result dir branch
        result=$("$HOME/.local/bin/gw" cd "$2") || return
        dir="${result%:*}"
        branch="${result##*:}"
        cd "$dir" || return
        _gw_set_kitty_tab "$branch"
    else
        local output
        output=$("$HOME/.local/bin/gw" "$@")
        echo "$output" | grep -v '^__gw_cd:'
        local cd_line dir branch
        cd_line=$(echo "$output" | sed -n 's/^__gw_cd://p')
        if [[ -n "$cd_line" ]]; then
            dir="${cd_line%:*}"
            branch="${cd_line##*:}"
            cd "$dir" || return
            _gw_set_kitty_tab "$branch"
        fi
    fi
}

_gw_completions() {
    local cur prev words cword
    _init_completion || return

    if ((cword == 1)); then
        COMPREPLY=($(compgen -W "add cd ls merge prune rm" -- "$cur"))
        return
    fi

    case "${words[1]}" in
    cd | rm)
        # Complete with worktree branch suffixes (part after last /)
        local branches
        branches=$(git worktree list --porcelain 2>/dev/null |
            awk -F/ '/^branch / { print $NF }')
        COMPREPLY=($(compgen -W "$branches" -- "$cur"))
        ;;
    add)
        if ((cword == 3)); then
            COMPREPLY=($(compgen -W "--no-cd" -- "$cur"))
        fi
        ;;
    merge)
        if ((cword == 2)); then
            COMPREPLY=($(compgen -W "--prune" -- "$cur"))
        fi
        ;;
    esac
}
complete -F _gw_completions gw
