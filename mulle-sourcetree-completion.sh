#!/usr/bin/env bash

# Bash completion script for mulle-sourcetree
# Generated with comprehensive command analysis for mulle-sourcetree version 1.6.0

# Cache variables for performance
__mulle_sourcetree_cached_commands=""
__mulle_sourcetree_cached_addresses=""
__mulle_sourcetree_cached_marks=""

# Helper: Get list of commands dynamically with static fallback
__mulle_sourcetree_commands() {
    if [ -z "$__mulle_sourcetree_cached_commands" ]; then
        __mulle_sourcetree_cached_commands=$(mulle-sourcetree commands 2>/dev/null || echo "add clean config craftorder dbstatus desecrate dotdump duplicate editor etc-dir eval-add filter fix get info json knownmarks libexec-dir list mark move plugin project-dir pwd rcopy remove rename rename-marks reset reuuid rewrite set sourcetree-dir star-search status supermark sync test touch uname unmark var-dir version walk wrap")
    fi
    echo "$__mulle_sourcetree_cached_commands"
}

# Helper: Get list of node addresses from current sourcetree
__mulle_sourcetree_addresses() {
    if [ -z "$__mulle_sourcetree_cached_addresses" ]; then
        __mulle_sourcetree_cached_addresses=$(mulle-sourcetree list --output-format '%a\n' 2>/dev/null | grep -v '^/' | grep -v '^$')
    fi
    echo "$__mulle_sourcetree_cached_addresses"
}

# Helper: Get known marks
__mulle_sourcetree_marks() {
    if [ -z "$__mulle_sourcetree_cached_marks" ]; then
        __mulle_sourcetree_cached_marks=$(mulle-sourcetree knownmarks 2>/dev/null || echo "no-build no-delete no-descend no-header no-link no-require no-set no-share no-update only-standalone only-framework build delete descend header link require set share update")
    fi
    echo "$__mulle_sourcetree_cached_marks"
}

# Helper: Complete with node addresses
__mulle_sourcetree_complete_address() {
    local addresses
    addresses=$(__mulle_sourcetree_addresses)
    COMPREPLY=($(compgen -W "$addresses" -- "$cur"))
}

# Helper: Complete with marks
__mulle_sourcetree_complete_marks() {
    local marks
    marks=$(__mulle_sourcetree_marks)
    COMPREPLY=($(compgen -W "$marks" -- "$cur"))
}

# Main completion function
_mulle_sourcetree_complete() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    local global_options="-f --force -h --help -n --dry-run -s --silent -v --verbose -N --flat --recurse --share --config-name --config-dir --share-dir --version"

    # If we're at the first word after the command, suggest commands
    if [[ $cword -eq 1 ]]; then
        local commands
        commands=$(__mulle_sourcetree_commands)
        COMPREPLY=($(compgen -W "$commands $global_options" -- "$cur"))
        return 0
    fi

    # Handle global options that take arguments
    case "$prev" in
        --config-name|--config-dir|--share-dir)
            COMPREPLY=($(compgen -d -- "$cur"))
            return 0
            ;;
    esac

    local cmd="${words[1]}"

    # Dispatch to command-specific completion
    case "$cmd" in
        add)
            _mulle_sourcetree_add_complete
            ;;
        clean)
            _mulle_sourcetree_clean_complete
            ;;
        config)
            _mulle_sourcetree_config_complete
            ;;
        craftorder)
            _mulle_sourcetree_craftorder_complete
            ;;
        dbstatus)
            _mulle_sourcetree_dbstatus_complete
            ;;
        desecrate)
            _mulle_sourcetree_desecrate_complete
            ;;
        dotdump)
            _mulle_sourcetree_dotdump_complete
            ;;
        duplicate)
            _mulle_sourcetree_duplicate_complete
            ;;
        editor)
            COMPREPLY=()
            ;;
        etc-dir)
            COMPREPLY=()
            ;;
        eval-add)
            _mulle_sourcetree_eval_add_complete
            ;;
        filter)
            _mulle_sourcetree_filter_complete
            ;;
        fix)
            _mulle_sourcetree_fix_complete
            ;;
        get)
            _mulle_sourcetree_get_complete
            ;;
        info)
            _mulle_sourcetree_info_complete
            ;;
        json)
            _mulle_sourcetree_json_complete
            ;;
        knownmarks)
            _mulle_sourcetree_knownmarks_complete
            ;;
        libexec-dir)
            COMPREPLY=()
            ;;
        list)
            _mulle_sourcetree_list_complete
            ;;
        mark)
            _mulle_sourcetree_mark_complete
            ;;
        move)
            _mulle_sourcetree_move_complete
            ;;
        plugin)
            _mulle_sourcetree_plugin_complete
            ;;
        project-dir)
            COMPREPLY=()
            ;;
        pwd)
            COMPREPLY=()
            ;;
        rcopy)
            _mulle_sourcetree_rcopy_complete
            ;;
        remove)
            _mulle_sourcetree_remove_complete
            ;;
        rename)
            _mulle_sourcetree_rename_complete
            ;;
        rename-marks)
            _mulle_sourcetree_rename_marks_complete
            ;;
        reset)
            _mulle_sourcetree_reset_complete
            ;;
        reuuid)
            _mulle_sourcetree_reuuid_complete
            ;;
        rewrite)
            _mulle_sourcetree_rewrite_complete
            ;;
        set)
            _mulle_sourcetree_set_complete
            ;;
        sourcetree-dir)
            _mulle_sourcetree_sourcetree_dir_complete
            ;;
        star-search)
            _mulle_sourcetree_star_search_complete
            ;;
        status)
            _mulle_sourcetree_status_complete
            ;;
        supermark)
            _mulle_sourcetree_supermark_complete
            ;;
        sync)
            _mulle_sourcetree_sync_complete
            ;;
        test)
            _mulle_sourcetree_test_complete
            ;;
        touch)
            COMPREPLY=()
            ;;
        uname)
            COMPREPLY=()
            ;;
        unmark)
            _mulle_sourcetree_unmark_complete
            ;;
        var-dir)
            COMPREPLY=()
            ;;
        version)
            COMPREPLY=()
            ;;
        walk)
            _mulle_sourcetree_walk_complete
            ;;
        wrap)
            _mulle_sourcetree_wrap_complete
            ;;
        *)
            COMPREPLY=($(compgen -W "$global_options" -- "$cur"))
            ;;
    esac
}

# Command-specific completion functions

_mulle_sourcetree_add_complete() {
    local add_options="-h --help --address --branch --fetchoptions --marks --tag --nodetype --url --userinfo --if-missing"

    case "$prev" in
        --branch|--tag)
            COMPREPLY=()
            ;;
        --address)
            COMPREPLY=($(compgen -d -- "$cur"))
            ;;
        --fetchoptions|--userinfo)
            COMPREPLY=()
            ;;
        --marks)
            __mulle_sourcetree_complete_marks
            ;;
        --nodetype)
            COMPREPLY=($(compgen -W "git tar zip local none symlink comment" -- "$cur"))
            ;;
        --url)
            COMPREPLY=($(compgen -W "https:// http:// file://" -- "$cur"))
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$add_options" -- "$cur"))
            else
                # Address or URL argument - offer directory completion
                COMPREPLY=($(compgen -d -- "$cur"))
            fi
            ;;
    esac
}

_mulle_sourcetree_clean_complete() {
    local clean_options="-h --help --all-graveyards --fs --graveyard --no-fs --no-graveyard --no-share --share"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$clean_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_config_complete() {
    local config_options="-h --help"
    local config_commands="list copy remove status"

    # Check if we're at the subcommand position
    local i
    for ((i=2; i < cword; i++)); do
        case "${words[i]}" in
            -*) ;;
            *)
                # Found subcommand, complete its options
                case "${words[i]}" in
                    list)
                        local list_options="-h --help -n -s --no-warn"
                        case "$prev" in
                            -s)
                                COMPREPLY=()
                                ;;
                            *)
                                COMPREPLY=($(compgen -W "$list_options" -- "$cur"))
                                ;;
                        esac
                        return 0
                        ;;
                    copy|remove|status)
                        COMPREPLY=($(compgen -W "-h --help" -- "$cur"))
                        return 0
                        ;;
                esac
                ;;
        esac
    done

    # No subcommand yet, offer subcommands or options
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$config_options" -- "$cur"))
    else
        COMPREPLY=($(compgen -W "$config_commands" -- "$cur"))
    fi
}

_mulle_sourcetree_craftorder_complete() {
    local craftorder_options="-h --help --callback --output-eval --output-no-marks --print-qualifier"
    case "$prev" in
        --callback)
            COMPREPLY=()
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$craftorder_options" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
    esac
}

_mulle_sourcetree_dbstatus_complete() {
    local dbstatus_options="-h --help"
    COMPREPLY=($(compgen -W "$dbstatus_options" -- "$cur"))
}

_mulle_sourcetree_desecrate_complete() {
    local desecrate_options="-h --help --all-graveyards"
    COMPREPLY=($(compgen -W "$desecrate_options" -- "$cur"))
}

_mulle_sourcetree_dotdump_complete() {
    local dotdump_options="-h --help -n -p -m --lr --td --walk-config --walk-db --output-html"
    case "$prev" in
        -n)
            COMPREPLY=($(compgen -W "git tar zip local symlink comment ALL" -- "$cur"))
            ;;
        -p)
            COMPREPLY=($(compgen -W "missing" -- "$cur"))
            ;;
        -m)
            __mulle_sourcetree_complete_marks
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$dotdump_options" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
    esac
}

_mulle_sourcetree_duplicate_complete() {
    local duplicate_options="-h --help --address --branch --fetchoptions --marks --nodetype --tag --url --userinfo"
    case "$prev" in
        --branch|--tag|--fetchoptions|--userinfo)
            COMPREPLY=()
            ;;
        --address)
            COMPREPLY=($(compgen -d -- "$cur"))
            ;;
        --marks)
            __mulle_sourcetree_complete_marks
            ;;
        --nodetype)
            COMPREPLY=($(compgen -W "git tar zip local none symlink comment" -- "$cur"))
            ;;
        --url)
            COMPREPLY=($(compgen -W "https:// http:// file://" -- "$cur"))
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$duplicate_options" -- "$cur"))
            else
                __mulle_sourcetree_complete_address
            fi
            ;;
    esac
}

_mulle_sourcetree_eval_add_complete() {
    local eval_add_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$eval_add_options" -- "$cur"))
    else
        COMPREPLY=($(compgen -f -- "$cur"))
    fi
}

_mulle_sourcetree_filter_complete() {
    local filter_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$filter_options" -- "$cur"))
    else
        __mulle_sourcetree_complete_marks
    fi
}

_mulle_sourcetree_fix_complete() {
    local fix_options="-h --help"
    COMPREPLY=($(compgen -W "$fix_options" -- "$cur"))
}

_mulle_sourcetree_get_complete() {
    local get_options="-h --help"
    local get_keys="all address branch fetchoptions marks nodetype tag url userinfo uuid"
    
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$get_options" -- "$cur"))
    else
        # First non-option arg is address, second is key
        local argcount=0
        local i
        for ((i=2; i < cword; i++)); do
            if [[ "${words[i]}" != -* ]]; then
                ((argcount++))
            fi
        done
        
        if [ $argcount -eq 0 ]; then
            __mulle_sourcetree_complete_address
        elif [ $argcount -eq 1 ]; then
            COMPREPLY=($(compgen -W "$get_keys" -- "$cur"))
        else
            COMPREPLY=()
        fi
    fi
}

_mulle_sourcetree_info_complete() {
    local info_options="-h --help"
    COMPREPLY=($(compgen -W "$info_options" -- "$cur"))
}

_mulle_sourcetree_json_complete() {
    local json_options="-h --help"
    COMPREPLY=($(compgen -W "$json_options" -- "$cur"))
}

_mulle_sourcetree_knownmarks_complete() {
    local knownmarks_options="-h --help"
    COMPREPLY=($(compgen -W "$knownmarks_options" -- "$cur"))
}

_mulle_sourcetree_list_complete() {
    local list_options="-h --help -l -ll -g -G -m -s -r -u -U --bequeath --no-bequeath --config-file --dedupe-mode --format --force-format --marks --no-dedupe --nodetype --output-banner --output-eval --output-format --output-full --output-no-column --output-no-header --output-no-indent --output-no-marks --output-no-separator --output-uuid --qualifier --verbatim"
    
    case "$prev" in
        --dedupe-mode)
            COMPREPLY=($(compgen -W "address address-filename address-marks-filename address-url filename hacked-marks-nodeline-no-uuid linkorder nodeline nodeline-no-uuid none url-filename" -- "$cur"))
            ;;
        --format|--output-format)
            COMPREPLY=()
            ;;
        --marks|-m)
            __mulle_sourcetree_complete_marks
            ;;
        --nodetype)
            COMPREPLY=($(compgen -W "git tar zip local symlink comment ALL" -- "$cur"))
            ;;
        --qualifier)
            COMPREPLY=()
            ;;
        --config-file)
            COMPREPLY=($(compgen -f -- "$cur"))
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$list_options" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
    esac
}

_mulle_sourcetree_mark_complete() {
    local mark_options="-h --help --extended-mark --regex --set"
    
    case "$prev" in
        --set)
            __mulle_sourcetree_complete_marks
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$mark_options" -- "$cur"))
            else
                # Count non-option arguments
                local argcount=0
                local i
                for ((i=2; i < cword; i++)); do
                    if [[ "${words[i]}" != -* ]]; then
                        ((argcount++))
                    fi
                done
                
                if [ $argcount -eq 0 ]; then
                    __mulle_sourcetree_complete_address
                elif [ $argcount -eq 1 ]; then
                    __mulle_sourcetree_complete_marks
                else
                    COMPREPLY=()
                fi
            fi
            ;;
    esac
}

_mulle_sourcetree_move_complete() {
    local move_options="-h --help --before --after --top --bottom"
    case "$prev" in
        --before|--after)
            __mulle_sourcetree_complete_address
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$move_options" -- "$cur"))
            else
                __mulle_sourcetree_complete_address
            fi
            ;;
    esac
}

_mulle_sourcetree_plugin_complete() {
    local plugin_commands="list"
    local plugin_options="-h --help"

    # Check if subcommand already given
    local i
    for ((i=2; i < cword; i++)); do
        case "${words[i]}" in
            list)
                COMPREPLY=($(compgen -W "$plugin_options" -- "$cur"))
                return 0
                ;;
        esac
    done

    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$plugin_options" -- "$cur"))
    else
        COMPREPLY=($(compgen -W "$plugin_commands" -- "$cur"))
    fi
}

_mulle_sourcetree_rcopy_complete() {
    local rcopy_options="-h --help --update"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$rcopy_options" -- "$cur"))
    else
        COMPREPLY=($(compgen -d -- "$cur"))
    fi
}

_mulle_sourcetree_remove_complete() {
    local remove_options="-h --help --if-present"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$remove_options" -- "$cur"))
    else
        __mulle_sourcetree_complete_address
    fi
}

_mulle_sourcetree_rename_complete() {
    local rename_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$rename_options" -- "$cur"))
    else
        # First argument is old address
        local argcount=0
        local i
        for ((i=2; i < cword; i++)); do
            if [[ "${words[i]}" != -* ]]; then
                ((argcount++))
            fi
        done
        
        if [ $argcount -eq 0 ]; then
            __mulle_sourcetree_complete_address
        else
            COMPREPLY=()
        fi
    fi
}

_mulle_sourcetree_rename_marks_complete() {
    local rename_marks_options="-h --help --regex --extended-mark"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$rename_marks_options" -- "$cur"))
    else
        __mulle_sourcetree_complete_marks
    fi
}

_mulle_sourcetree_reset_complete() {
    local reset_options="-h --help -g"
    COMPREPLY=($(compgen -W "$reset_options" -- "$cur"))
}

_mulle_sourcetree_reuuid_complete() {
    local reuuid_options="-h --help"
    COMPREPLY=($(compgen -W "$reuuid_options" -- "$cur"))
}

_mulle_sourcetree_rewrite_complete() {
    local rewrite_options="-h --help"
    COMPREPLY=($(compgen -W "$rewrite_options" -- "$cur"))
}

_mulle_sourcetree_set_complete() {
    local set_options="-h --help --branch --address --fetchoptions --marks --tag --nodetype --url --userinfo"
    local set_keys="address branch fetchoptions marks nodetype tag url userinfo"
    
    case "$prev" in
        --branch|--tag|--fetchoptions|--userinfo)
            COMPREPLY=()
            ;;
        --address)
            COMPREPLY=($(compgen -d -- "$cur"))
            ;;
        --marks)
            __mulle_sourcetree_complete_marks
            ;;
        --nodetype)
            COMPREPLY=($(compgen -W "git tar zip local none symlink comment" -- "$cur"))
            ;;
        --url)
            COMPREPLY=($(compgen -W "https:// http:// file://" -- "$cur"))
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$set_options" -- "$cur"))
            else
                # Count non-option arguments
                local argcount=0
                local i
                for ((i=2; i < cword; i++)); do
                    if [[ "${words[i]}" != -* ]]; then
                        ((argcount++))
                    fi
                done
                
                if [ $argcount -eq 0 ]; then
                    __mulle_sourcetree_complete_address
                elif [ $argcount -eq 1 ]; then
                    COMPREPLY=($(compgen -W "$set_keys" -- "$cur"))
                else
                    COMPREPLY=()
                fi
            fi
            ;;
    esac
}

_mulle_sourcetree_sourcetree_dir_complete() {
    local sourcetree_dir_options="-h --help"
    COMPREPLY=($(compgen -W "$sourcetree_dir_options" -- "$cur"))
}

_mulle_sourcetree_star_search_complete() {
    local star_search_options="-h --help"
    COMPREPLY=($(compgen -W "$star_search_options" -- "$cur"))
}

_mulle_sourcetree_status_complete() {
    local status_options="-h --help --all --shallow --deep --is-uptodate --output-filename -n -p -m"
    case "$prev" in
        -n)
            COMPREPLY=($(compgen -W "git tar zip local symlink comment ALL" -- "$cur"))
            ;;
        -p)
            COMPREPLY=($(compgen -W "missing" -- "$cur"))
            ;;
        -m)
            __mulle_sourcetree_complete_marks
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$status_options" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
    esac
}

_mulle_sourcetree_supermark_complete() {
    local supermark_options="-h --help"
    COMPREPLY=($(compgen -W "$supermark_options" -- "$cur"))
}

_mulle_sourcetree_sync_complete() {
    local sync_options="-h --help -r --serial --parallel --quick-check --no-fix --override-branch --cache-dir --refresh --no-refresh"
    case "$prev" in
        --override-branch)
            COMPREPLY=()
            ;;
        --cache-dir)
            COMPREPLY=($(compgen -d -- "$cur"))
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$sync_options" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
    esac
}

_mulle_sourcetree_test_complete() {
    local test_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$test_options" -- "$cur"))
    else
        __mulle_sourcetree_complete_marks
    fi
}

_mulle_sourcetree_unmark_complete() {
    local unmark_options="-h --help --regex --extended-mark"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$unmark_options" -- "$cur"))
    else
        # First non-option arg is address, rest are marks
        local argcount=0
        local i
        for ((i=2; i < cword; i++)); do
            if [[ "${words[i]}" != -* ]]; then
                ((argcount++))
            fi
        done
        
        if [ $argcount -eq 0 ]; then
            __mulle_sourcetree_complete_address
        else
            __mulle_sourcetree_complete_marks
        fi
    fi
}

_mulle_sourcetree_walk_complete() {
    local walk_options="-h --help -n -p -m -q --backwards --bequeath --breadth-first --cd --comments --in-order --lenient --no-dedupe --pre-order --post-order --walk-db"
    case "$prev" in
        -n)
            COMPREPLY=($(compgen -W "git tar zip local symlink comment ALL" -- "$cur"))
            ;;
        -p)
            COMPREPLY=($(compgen -W "missing" -- "$cur"))
            ;;
        -m|-q)
            __mulle_sourcetree_complete_marks
            ;;
        *)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "$walk_options" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
    esac
}

_mulle_sourcetree_wrap_complete() {
    local wrap_options="-h --help"
    COMPREPLY=($(compgen -W "$wrap_options" -- "$cur"))
}

# Register the completion function
complete -F _mulle_sourcetree_complete mulle-sourcetree
