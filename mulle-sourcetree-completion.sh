#!/usr/bin/env bash

# Bash completion script for mulle-sourcetree
# Generated for mulle-sourcetree version 1.5.1

_mulle_sourcetree_complete() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    local commands="add clean config craftorder dbstatus desecrate dotdump duplicate editor etc-dir eval-add filter fix get info json knownmarks libexec-dir list mark mode move plugin project-dir pwd rcopy remove rename rename-marks reset reuuid rewrite set share-dir shell sourcetree-dir star-search status supermark sync test touch uname unmark var-dir version walk wrap"

    local global_options="-f --force -h --help --config-dir --config-name --config-file -d --directory --git-terminal-prompt -R --defer-root -T --defer-this -P --defer-parent -N --no-defer --virtual-root --mode -r --recurse --flat --share --share-dir --use-fallback --version --zprof"

    # If we're at the first word after the command, suggest commands
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands $global_options" -- "$cur"))
        return 0
    fi

    local cmd="${words[1]}"

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
            # No arguments
            COMPREPLY=()
            ;;
        etc-dir)
            # No arguments
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
            # No arguments
            COMPREPLY=()
            ;;
        list)
            _mulle_sourcetree_list_complete
            ;;
        mark)
            _mulle_sourcetree_mark_complete
            ;;
        mode)
            # No arguments
            COMPREPLY=()
            ;;
        move)
            _mulle_sourcetree_move_complete
            ;;
        plugin)
            _mulle_sourcetree_plugin_complete
            ;;
        project-dir)
            # No arguments
            COMPREPLY=()
            ;;
        pwd)
            # No arguments
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
        share-dir)
            _mulle_sourcetree_sourcetree_dir_complete
            ;;
        shell)
            # No arguments
            COMPREPLY=()
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
            # No arguments
            COMPREPLY=()
            ;;
        uname)
            # No arguments
            COMPREPLY=()
            ;;
        unmark)
            _mulle_sourcetree_unmark_complete
            ;;
        var-dir)
            # No arguments
            COMPREPLY=()
            ;;
        version)
            # No arguments
            COMPREPLY=()
            ;;
        walk)
            _mulle_sourcetree_walk_complete
            ;;
        wrap)
            _mulle_sourcetree_wrap_complete
            ;;
        *)
            # Fallback to global options
            COMPREPLY=($(compgen -W "$global_options" -- "$cur"))
            ;;
    esac
}

_mulle_sourcetree_add_complete() {
    local add_options="-h --help --address --branch --fetchoptions --marks --tag --nodetype --url --userinfo --if-missing"

    if [[ "$prev" == --branch ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --address ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --fetchoptions ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --marks ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --tag ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --nodetype ]]; then
        COMPREPLY=($(compgen -W "git tar zip local none symlink comment" -- "$cur"))
    elif [[ "$prev" == --url ]]; then
        COMPREPLY=($(compgen -W "https://" -- "$cur"))
    elif [[ "$prev" == --userinfo ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$add_options" -- "$cur"))
    else
        # Address or URL argument
        COMPREPLY=($(compgen -W "https://" -- "$cur"))
    fi
}

_mulle_sourcetree_clean_complete() {
    local clean_options="-h --help --all-graveyards --fs --graveyard --no-fs --no-graveyard --no-share --share"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$clean_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_json_complete() {
    local json_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$json_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_list_complete() {
    local list_options="-h --help -l -ll -g -m -s -r -u --bequeath --no-bequeath --config-file --dedupe-mode --format --force-format --marks --no-dedupe --nodetype --output-banner --output-eval --output-format --output-full --output-no-column --output-no-header --output-no-indent --output-no-marks --output-no-separator --output-uuid --qualifier --verbatim"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$list_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_mark_complete() {
    local mark_options="-h --help --extended-mark --regex --set"
    if [[ "$prev" == --set ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$mark_options" -- "$cur"))
    else
        # Node argument
        COMPREPLY=()
    fi
}

_mulle_sourcetree_move_complete() {
    local move_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$move_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_set_complete() {
    local set_options="-h --help --branch --address --fetchoptions --marks --tag --nodetype --url --userinfo"
    if [[ "$prev" == --branch ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --address ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --fetchoptions ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --marks ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --tag ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --nodetype ]]; then
        COMPREPLY=($(compgen -W "git tar zip local none symlink comment" -- "$cur"))
    elif [[ "$prev" == --url ]]; then
        COMPREPLY=($(compgen -W "https://" -- "$cur"))
    elif [[ "$prev" == --userinfo ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$set_options" -- "$cur"))
    else
        # Node argument
        COMPREPLY=()
    fi
}

_mulle_sourcetree_status_complete() {
    local status_options="-h --help --all --shallow --deep --is-uptodate --output-filename -n -p -m"
    if [[ "$prev" == -n ]]; then
        COMPREPLY=($(compgen -W "git tar zip local symlink comment ALL" -- "$cur"))
    elif [[ "$prev" == -p || "$prev" == -m ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$status_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_sync_complete() {
    local sync_options="-h --help -r --serial --parallel --quick-check --no-fix --override-branch --cache-dir --refresh --no-refresh"
    if [[ "$prev" == --override-branch ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --cache-dir ]]; then
        COMPREPLY=($(compgen -d -- "$cur"))
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$sync_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_reset_complete() {
    local reset_options="-h --help -g"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$reset_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_reuuid_complete() {
    local reuuid_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$reuuid_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_rewrite_complete() {
    local rewrite_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$rewrite_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_wrap_complete() {
    local wrap_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$wrap_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_walk_complete() {
    local walk_options="-h --help -n -p -m -q --backwards --bequeath --breadth-first --cd --comments --in-order --lenient --no-dedupe --pre-order --post-order --walk-db"
    if [[ "$prev" == -n ]]; then
        COMPREPLY=($(compgen -W "git tar zip local symlink comment ALL" -- "$cur"))
    elif [[ "$prev" == -p ]]; then
        COMPREPLY=($(compgen -W "missing" -- "$cur"))
    elif [[ "$prev" == -m || "$prev" == -q ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$walk_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_supermark_complete() {
    local supermark_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$supermark_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_config_complete() {
    local config_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$config_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_desecrate_complete() {
    local desecrate_options="-h --help --all-graveyards"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$desecrate_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_dotdump_complete() {
    local dotdump_options="-h --help -n -p -m --lr --td --walk-config --walk-db --output-html"
    if [[ "$prev" == -n ]]; then
        COMPREPLY=($(compgen -W "git tar zip local symlink comment ALL" -- "$cur"))
    elif [[ "$prev" == -p || "$prev" == -m ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$dotdump_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_duplicate_complete() {
    local duplicate_options="-h --help --address --branch --fetchoptions --marks --nodetype --tag --url --userinfo"
    if [[ "$prev" == --branch ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --address ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --fetchoptions ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --marks ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --tag ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --nodetype ]]; then
        COMPREPLY=($(compgen -W "git tar zip local none symlink comment" -- "$cur"))
    elif [[ "$prev" == --url ]]; then
        COMPREPLY=($(compgen -W "https://" -- "$cur"))
    elif [[ "$prev" == --userinfo ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$duplicate_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_filter_complete() {
    local filter_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$filter_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_rename_marks_complete() {
    local rename_marks_options="-h --help --regex --extended-mark"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$rename_marks_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_craftorder_complete() {
    local craftorder_options="-h --help --callback --output-eval --output-no-marks --print-qualifier"
    if [[ "$prev" == --callback ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$craftorder_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_dbstatus_complete() {
    local dbstatus_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$dbstatus_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_eval_add_complete() {
    local eval_add_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$eval_add_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_fix_complete() {
    local fix_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$fix_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_get_complete() {
    local get_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$get_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_unmark_complete() {
    local unmark_options="-h --help --regex --extended-mark"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$unmark_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_sourcetree_dir_complete() {
    local sourcetree_dir_options="-h --help --config-name --flat --recurse --share -N -n -s -v"
    if [[ "$prev" == --config-name ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$sourcetree_dir_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_knownmarks_complete() {
    local knownmarks_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$knownmarks_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_plugin_complete() {
    local plugin_commands="list"
    local plugin_options="-h --help"

    if [[ $cword -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$plugin_commands" -- "$cur"))
    else
        COMPREPLY=($(compgen -W "$plugin_options" -- "$cur"))
    fi
}

_mulle_sourcetree_rcopy_complete() {
    local rcopy_options="-h --help --update"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$rcopy_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_rename_complete() {
    local rename_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$rename_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_remove_complete() {
    local remove_options="-h --help --if-present"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$remove_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_info_complete() {
    local info_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$info_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_star_search_complete() {
    local star_search_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$star_search_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_test_complete() {
    local test_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$test_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

# Register the completion function
complete -F _mulle_sourcetree_complete mulle-sourcetree