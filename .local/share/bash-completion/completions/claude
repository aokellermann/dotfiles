# Bash completion for Claude Code
# https://github.com/anthropics/claude-code

_claude_completions() {
    local cur prev words cword
    _init_completion || return

    local commands="mcp plugin setup-token doctor update install"
    local mcp_commands="serve add remove list get add-json add-from-claude-desktop reset-project-choices help"
    local plugin_commands="validate marketplace install i uninstall remove enable disable update help"
    local marketplace_commands="add list remove rm update help"

    local main_opts="-d --debug --verbose -p --print --output-format --json-schema
        --include-partial-messages --input-format --mcp-debug
        --dangerously-skip-permissions --allow-dangerously-skip-permissions
        --max-budget-usd --replay-user-messages --allowedTools --allowed-tools
        --tools --disallowedTools --disallowed-tools --mcp-config --system-prompt
        --append-system-prompt --permission-mode -c --continue -r --resume
        --fork-session --no-session-persistence --model --agent --betas
        --fallback-model --settings --add-dir --ide --strict-mcp-config
        --session-id --agents --setting-sources --plugin-dir
        --disable-slash-commands --chrome --no-chrome -v --version -h --help"

    local output_formats="text json stream-json"
    local input_formats="text stream-json"
    local permission_modes="acceptEdits bypassPermissions default delegate dontAsk plan"
    local model_aliases="sonnet opus haiku"
    local scopes="local user project"
    local transports="stdio sse http"

    # Determine command context
    local cmd="" subcmd=""
    local i
    for ((i=1; i < cword; i++)); do
        case "${words[i]}" in
            mcp|plugin|setup-token|doctor|update|install)
                cmd="${words[i]}"
                break
                ;;
        esac
    done

    # If we found a command, look for subcommand
    if [[ -n "$cmd" ]]; then
        for ((i=i+1; i < cword; i++)); do
            case "$cmd" in
                mcp)
                    case "${words[i]}" in
                        serve|add|remove|list|get|add-json|add-from-claude-desktop|reset-project-choices|help)
                            subcmd="${words[i]}"
                            break
                            ;;
                    esac
                    ;;
                plugin)
                    case "${words[i]}" in
                        validate|marketplace|install|i|uninstall|remove|enable|disable|update|help)
                            subcmd="${words[i]}"
                            break
                            ;;
                    esac
                    ;;
            esac
        done
    fi

    # Handle option arguments
    case "$prev" in
        --output-format)
            COMPREPLY=($(compgen -W "$output_formats" -- "$cur"))
            return
            ;;
        --input-format)
            COMPREPLY=($(compgen -W "$input_formats" -- "$cur"))
            return
            ;;
        --permission-mode)
            COMPREPLY=($(compgen -W "$permission_modes" -- "$cur"))
            return
            ;;
        --model|--fallback-model)
            COMPREPLY=($(compgen -W "$model_aliases" -- "$cur"))
            return
            ;;
        -s|--scope)
            COMPREPLY=($(compgen -W "$scopes" -- "$cur"))
            return
            ;;
        -t|--transport)
            COMPREPLY=($(compgen -W "$transports" -- "$cur"))
            return
            ;;
        --settings|--mcp-config)
            _filedir
            return
            ;;
        --add-dir|--plugin-dir)
            _filedir -d
            return
            ;;
        --setting-sources)
            COMPREPLY=($(compgen -W "user project local" -- "$cur"))
            return
            ;;
        -r|--resume|-d|--debug|--json-schema|--max-budget-usd|--allowedTools|--allowed-tools|--tools|--disallowedTools|--disallowed-tools|--system-prompt|--append-system-prompt|--agent|--betas|--session-id|--agents|-e|--env|-H|--header)
            # These take arguments but we can't predict them
            return
            ;;
    esac

    # Complete based on context
    case "$cmd" in
        "")
            # No command yet - complete commands or main options
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$main_opts" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "$commands" -- "$cur"))
            fi
            ;;
        mcp)
            case "$subcmd" in
                "")
                    # No subcommand yet
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                    else
                        COMPREPLY=($(compgen -W "$mcp_commands" -- "$cur"))
                    fi
                    ;;
                serve)
                    COMPREPLY=($(compgen -W "-d --debug --verbose -h --help" -- "$cur"))
                    ;;
                add)
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-s --scope -t --transport -e --env -H --header -h --help" -- "$cur"))
                    fi
                    ;;
                remove)
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-s --scope -h --help" -- "$cur"))
                    fi
                    ;;
                add-json)
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-s --scope -h --help" -- "$cur"))
                    fi
                    ;;
                add-from-claude-desktop)
                    COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                    ;;
                list|get|reset-project-choices)
                    COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                    ;;
            esac
            ;;
        plugin)
            case "$subcmd" in
                "")
                    # No subcommand yet
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                    else
                        COMPREPLY=($(compgen -W "$plugin_commands" -- "$cur"))
                    fi
                    ;;
                validate)
                    if [[ "$cur" != -* ]]; then
                        _filedir
                    else
                        COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                    fi
                    ;;
                marketplace)
                    # Check for marketplace subcommand
                    local mp_subcmd=""
                    for ((j=i+1; j < cword; j++)); do
                        case "${words[j]}" in
                            add|list|remove|rm|update|help)
                                mp_subcmd="${words[j]}"
                                break
                                ;;
                        esac
                    done
                    if [[ -z "$mp_subcmd" ]]; then
                        if [[ "$cur" == -* ]]; then
                            COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                        else
                            COMPREPLY=($(compgen -W "$marketplace_commands" -- "$cur"))
                        fi
                    else
                        COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                    fi
                    ;;
                install|i|uninstall|remove|enable|disable|update)
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-s --scope -h --help" -- "$cur"))
                    fi
                    ;;
            esac
            ;;
        install)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--force -h --help" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "stable latest" -- "$cur"))
            fi
            ;;
        setup-token|doctor|update)
            COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
            ;;
    esac
}

complete -F _claude_completions claude
