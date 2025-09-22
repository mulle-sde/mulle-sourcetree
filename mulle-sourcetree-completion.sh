#!/usr/bin/env bash

# Bash completion script for mulle-sourcetree
# Generated for mulle-sourcetree version 1.5.0

_mulle_sourcetree_complete() {
    local cur prev words cword
    _get_comp_words_by_ref -n : cur prev words cword

    local commands="add clean json list mark move set status sync clean fix json list reset reuuid rewrite wrap status walk supermark config desecrate dotdump duplicate filter knownmarks plugin rcopy rename rename-marks remove info libexec-dir mode pwd etc-dir project-dir var-dir share-dir star-search tool-env touch uname shell test version"

    local global_options="-f --force -h --help --config-dir --config-name -d --directory --git-terminal-prompt -R --defer-root -T --defer-this -P --defer-parent -N --no-defer --virtual-root --mode -r --recurse --flat --share --share-dir --use-fallback --version --zprof"

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
        json)
            _mulle_sourcetree_json_complete
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
        set)
            _mulle_sourcetree_set_complete
            ;;
        status)
            _mulle_sourcetree_status_complete
            ;;
        sync)
            _mulle_sourcetree_sync_complete
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
        wrap)
            _mulle_sourcetree_wrap_complete
            ;;
        walk)
            _mulle_sourcetree_walk_complete
            ;;
        supermark)
            _mulle_sourcetree_supermark_complete
            ;;
        config)
            _mulle_sourcetree_config_complete
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
        filter)
            _mulle_sourcetree_filter_complete
            ;;
        knownmarks)
            _mulle_sourcetree_knownmarks_complete
            ;;
        plugin)
            _mulle_sourcetree_plugin_complete
            ;;
        rcopy)
            _mulle_sourcetree_rcopy_complete
            ;;
        rename)
            _mulle_sourcetree_rename_complete
            ;;
        rename-marks)
            _mulle_sourcetree_rename_marks_complete
            ;;
        remove)
            _mulle_sourcetree_remove_complete
            ;;
        info)
            _mulle_sourcetree_info_complete
            ;;
        libexec-dir)
            # No arguments
            COMPREPLY=()
            ;;
        mode)
            # No arguments
            COMPREPLY=()
            ;;
        pwd)
            # No arguments
            COMPREPLY=()
            ;;
        etc-dir)
            # No arguments
            COMPREPLY=()
            ;;
        project-dir)
            # No arguments
            COMPREPLY=()
            ;;
        var-dir)
            # No arguments
            COMPREPLY=()
            ;;
        share-dir)
            # No arguments
            COMPREPLY=()
            ;;
        star-search)
            _mulle_sourcetree_star_search_complete
            ;;
        tool-env)
            # No arguments
            COMPREPLY=()
            ;;
        touch)
            # No arguments
            COMPREPLY=()
            ;;
        uname)
            # No arguments
            COMPREPLY=()
            ;;
        shell)
            # No arguments
            COMPREPLY=()
            ;;
        test)
            _mulle_sourcetree_test_complete
            ;;
        version)
            # No arguments
            COMPREPLY=()
            ;;
        *)
            # Fallback to global options
            COMPREPLY=($(compgen -W "$global_options" -- "$cur"))
            ;;
    esac
}

_mulle_sourcetree_add_complete() {
    local add_options="-h --help --branch --address --fetchoptions --marks --tag --nodetype --url --userinfo --if-missing -a --address -b --branch -f --fetchoptions -m --marks -n --nodetype -t --tag -u --url -U --userinfo --extended-mark --no-extended-mark --fuzzy --no-fuzzy --regex --no-regex --update --no-update --raw-userinfo"

    if [[ "$prev" == --branch || "$prev" == -b ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --address || "$prev" == -a ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --fetchoptions || "$prev" == -f ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --marks || "$prev" == -m ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --tag || "$prev" == -t ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --nodetype || "$prev" == -n || "$prev" == --scm || "$prev" == -s ]]; then
        COMPREPLY=($(compgen -W "git tar zip local none symlink comment" -- "$cur"))
    elif [[ "$prev" == --url || "$prev" == -u ]]; then
        COMPREPLY=($(compgen -W "https://" -- "$cur"))
    elif [[ "$prev" == --userinfo || "$prev" == -U || "$prev" == --raw-userinfo ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$add_options" -- "$cur"))
    else
        # Address or URL argument
        COMPREPLY=($(compgen -W "https://" -- "$cur"))
    fi
}

_mulle_sourcetree_clean_complete() {
    local clean_options="-h --help"
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
    local list_options="-h --help --output-index --output-uuid --output-node --output-address --output-url --output-marks --output-nodetype --output-branch --output-tag --output-fetchoptions --output-userinfo --output-evaledurl --output-evalednodetype --output-evaledbranch --output-evaledtag --output-evaledfetchoptions"
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
    local set_options="-h --help --branch --address --fetchoptions --marks --tag --nodetype --url --userinfo --raw-userinfo -a --address -b --branch -f --fetchoptions -m --marks -n --nodetype -t --tag -u --url -U --userinfo"
    if [[ "$prev" == --branch || "$prev" == -b ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --address || "$prev" == -a ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --fetchoptions || "$prev" == -f ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --marks || "$prev" == -m ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --tag || "$prev" == -t ]]; then
        COMPREPLY=()
    elif [[ "$prev" == --nodetype || "$prev" == -n ]]; then
        COMPREPLY=($(compgen -W "git tar zip local none symlink comment" -- "$cur"))
    elif [[ "$prev" == --url || "$prev" == -u ]]; then
        COMPREPLY=($(compgen -W "https://" -- "$cur"))
    elif [[ "$prev" == --userinfo || "$prev" == -U || "$prev" == --raw-userinfo ]]; then
        COMPREPLY=()
    elif [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$set_options" -- "$cur"))
    else
        # Node argument
        COMPREPLY=()
    fi
}

_mulle_sourcetree_status_complete() {
    local status_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$status_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_sync_complete() {
    local sync_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$sync_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_reset_complete() {
    local reset_options="-h --help"
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
    local walk_options="-h --help --dedupe-mode --lenient --callback --output-format --output-no-header --output-eval --output-no-uuid --output-no-marks --output-no-address --output-no-url --output-no-nodetype --output-no-branch --output-no-tag --output-no-fetchoptions --output-no-userinfo --output-no-evaledurl --output-no-evalednodetype --output-no-evaledbranch --output-no-evaledtag --output-no-evaledfetchoptions"
    if [[ "$cur" == -* ]]; then
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
    local dotdump_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$dotdump_options" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

_mulle_sourcetree_duplicate_complete() {
    _mulle_sourcetree_add_complete
}

_mulle_sourcetree_filter_complete() {
    local filter_options="-h --help"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$filter_options" -- "$cur"))
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

_mulle_sourcetree_rename_marks_complete() {
    local rename_marks_options="-h --help --regex --extended-mark"
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$rename_marks_options" -- "$cur"))
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