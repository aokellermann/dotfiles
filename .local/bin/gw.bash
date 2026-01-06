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
