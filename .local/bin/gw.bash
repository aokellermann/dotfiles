# gw shell function wrapper (source this file)
# The actual script is at ~/.local/bin/gw

gw() {
    if [[ "$1" == "cd" ]]; then
        local dir
        dir=$("$HOME/.local/bin/gw" cd "$2") && cd "$dir" || return
    else
        local output
        output=$("$HOME/.local/bin/gw" "$@")
        echo "$output" | grep -v '^__gw_cd:'
        local cd_path
        cd_path=$(echo "$output" | sed -n 's/^__gw_cd://p')
        [[ -n "$cd_path" ]] && { cd "$cd_path" || return; }
    fi
}

_gw_completions() {
    local cur prev words cword
    _init_completion || return

    if ((cword == 1)); then
        COMPREPLY=($(compgen -W "add cd ls rm" -- "$cur"))
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
            COMPREPLY=($(compgen -W "--cd" -- "$cur"))
        fi
        ;;
    esac
}
complete -F _gw_completions gw
