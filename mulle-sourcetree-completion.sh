#!/usr/bin/env bash

# Bash completion script for mulle-sourcetree
# Version 1.7.0
#
# Comprehensive context-aware completion. Options and aliases were verified
# against the mulle-sourcetree source (main dispatch + src/*.sh), not by
# trusting usage text, since several usage texts are stale.
#
# Strategy:
#   1. Dynamic discovery with caching (commands, node addresses, known marks)
#   2. Static fallbacks when the mulle-sourcetree binary is missing or fails
#   3. Accurate per-command option lists (short + long, flag vs argument)
#   4. Context-aware completions (addresses, marks, nodetypes, dedupe modes,
#      output formats, config names, subcommands)
#   5. Timeouts + caching so completion never blocks on a slow subprocess

# --------------------------------------------------------------------------
# Caches
# --------------------------------------------------------------------------
__mulle_sourcetree_cached_commands=""
__mulle_sourcetree_cached_marks=""
__mulle_sourcetree_cached_addresses=""
__mulle_sourcetree_cached_addresses_pwd=""
__mulle_sourcetree_cached_supermarks=""

# Prefix for guarded subprocess calls. `timeout` keeps slow invocations from
# blocking completion (not present on all platforms; then we run unguarded).
__mulle_sourcetree_timeout_cmd=""
if command -v timeout >/dev/null 2>&1
then
    __mulle_sourcetree_timeout_cmd="timeout 3"
fi

# --------------------------------------------------------------------------
# Static data
# --------------------------------------------------------------------------

# Full command list. `mulle-sourcetree commands` misses a few hidden/alias
# commands (copy, mode, path, plugins, share-dir, stash-dir, shell, tool-env,
# update, library-path), so the dynamic result is merged with this list.
__mulle_sourcetree_static_commands="
add
clean
commands
config
copy
craftorder
dbstatus
desecrate
dotdump
duplicate
editor
etc-dir
eval-add
filter
fix
get
info
json
knownmarks
libexec-dir
library-path
list
mark
mode
move
path
plugin
plugins
project-dir
pwd
rcopy
remove
rename
rename-marks
reset
reuuid
rewrite
set
share-dir
shell
sourcetree-dir
star-search
stash-dir
status
supermark
sync
test
tool-env
touch
uname
unmark
update
var-dir
version
walk
wrap
"

# Global (pre-command) flags accepted by the main parser plus the usual
# mulle-bashfunctions technical flags.
__mulle_sourcetree_global_options="
    -N --no-defer
    -R --defer-root
    -T --defer-this
    -P --defer-parent
    --virtual-root
    -f --force
    --flat
    -r --recurse --recursive
    --share
    --mode
    --config --config-name --config-names
    --config-dir
    --config-file
    -d --directory
    --share-dir --stash-dir
    --git-terminal-prompt
    --use-fallback
    -n --dry-run
    -s --silent
    --silent-but-warn
    -v --verbose
    -vv --very-verbose
    -vvv --very-very-verbose
    -ld --log-debug
    -le --log-environment
    -ls --log-settings
    -lx --log-exekutor --log-execution
    -lt --trace
    -lxx --trace-database
    -lxw --trace-walk
    --version
    --echo-args
"

# Node types usable for --nodetype / -n
__mulle_sourcetree_nodetypes="git tar zip local none symlink comment"

# Nodetype filter values (list/dotdump/walk/json allow ALL and no- prefixes)
__mulle_sourcetree_nodetype_filters="ALL no-git no-tar no-zip no-local no-none no-symlink no-comment"

# Permissions for -p (dotdump / walk)
__mulle_sourcetree_permissions="present missing directory symlink file"

# Dedupe modes for --dedupe-mode (verified against src/mulle-sourcetree-list.sh)
__mulle_sourcetree_dedupe_modes="
address address-filename address-marks-filename address-url filename
hacked-marks-nodeline-no-uuid linkorder nodeline nodeline-no-uuid
none url url-filename
"

# Output formats for --output-format
__mulle_sourcetree_output_formats="fmt cmd cmd2 raw formatted command command2 csv"

# Node field keys (for set/get/copy)
__mulle_sourcetree_field_keys="branch address fetchoptions marks nodetype tag url userinfo"

# Keys accepted by `get`
__mulle_sourcetree_get_keys="all address branch fetchoptions marks nodetype raw_userinfo tag url userinfo uuid"

# Known marks fallback (dynamic `mulle-sourcetree knownmarks` is preferred)
__mulle_sourcetree_static_marks="
no-actual-build no-actual-link no-all-load no-bequeath no-build no-clobber
no-cmake-add no-cmake-all-load no-cmake-dependency no-cmake-inherit
no-cmake-intermediate-link no-cmake-loader no-cmake-searchpath no-delete
no-dependency no-descend no-dynamic-link no-fs no-header no-include
no-import no-inplace no-intermediate-link no-link no-cmake-platform-mingw
no-cmake-platform-darwin no-cmake-platform-freebsd no-cmake-platform-linux
no-cmake-platform-webassembly no-cmake-platform-windows no-platform-mingw
no-platform-darwin no-platform-freebsd no-platform-linux
no-platform-webassembly no-platform-windows no-public no-readwrite
no-recurse no-require no-set no-singlephase no-singlephase-link
no-static-link no-share no-share-shirk no-symlink-mingw no-symlink-darwin
no-symlink-freebsd no-symlink-linux no-symlink-webassembly no-symlink-windows
no-update only-standalone only-framework only-cmake-platform-darwin
only-cmake-platform-freebsd only-cmake-platform-linux
only-cmake-platform-webassembly only-cmake-platform-windows
only-cmake-platform-mingw only-platform-darwin only-platform-freebsd
only-platform-linux only-platform-webassembly only-platform-windows
only-platform-mingw
"

# Supermark subcommands
__mulle_sourcetree_supermark_subcommands="list compose decompose"

# config subcommands
__mulle_sourcetree_config_subcommands="list status"

# --------------------------------------------------------------------------
# Dynamic discovery
# --------------------------------------------------------------------------

__mulle_sourcetree_commands()
{
    if [ -z "${__mulle_sourcetree_cached_commands}" ]
    then
        local dynamic
        dynamic="$(eval ${__mulle_sourcetree_timeout_cmd} mulle-sourcetree commands 2>/dev/null)"
        __mulle_sourcetree_cached_commands="$(
            printf "%s\n%s\n" "${__mulle_sourcetree_static_commands}" "${dynamic}" |
            sed '/^[[:space:]]*$/d' | sort -u | tr '\n' ' '
        )"
    fi
    printf "%s\n" "${__mulle_sourcetree_cached_commands}"
}

__mulle_sourcetree_commands_word()
{
    __mulle_sourcetree_commands | tr '\n' ' '
}

__mulle_sourcetree_marks()
{
    if [ -z "${__mulle_sourcetree_cached_marks}" ]
    then
        local marks
        marks="$(${__mulle_sourcetree_timeout_cmd} mulle-sourcetree knownmarks 2>/dev/null | sed '/^[[:space:]]*$/d')"
        if [ -z "${marks}" ]
        then
            marks="$(printf "%s\n" "${__mulle_sourcetree_static_marks}" | sed '/^[[:space:]]*$/d')"
        fi
        __mulle_sourcetree_cached_marks="$(printf "%s\n" "${marks}" | tr '\n' ' ')"
    fi
    printf "%s\n" "${__mulle_sourcetree_cached_marks}"
}

__mulle_sourcetree_marks_word()
{
    __mulle_sourcetree_marks | tr '\n' ' '
}

__mulle_sourcetree_addresses()
{
    if [ "${__mulle_sourcetree_cached_addresses_pwd}" != "${PWD}" ]
    then
        __mulle_sourcetree_cached_addresses="$(
            ${__mulle_sourcetree_timeout_cmd} mulle-sourcetree list --output-no-header 2>/dev/null |
            sed '/^[[:space:]]*$/d' | tr '\n' ' '
        )"
        __mulle_sourcetree_cached_addresses_pwd="${PWD}"
    fi
    printf "%s\n" "${__mulle_sourcetree_cached_addresses}"
}

__mulle_sourcetree_addresses_word()
{
    __mulle_sourcetree_addresses | tr '\n' ' '
}

__mulle_sourcetree_supermarks()
{
    if [ -z "${__mulle_sourcetree_cached_supermarks}" ]
    then
        __mulle_sourcetree_cached_supermarks="$(
            ${__mulle_sourcetree_timeout_cmd} mulle-sourcetree supermark list 2>/dev/null |
            sed '/^[[:space:]]*$/d' | tr '\n' ' '
        )"
    fi
    printf "%s\n" "${__mulle_sourcetree_cached_supermarks}"
}

# --------------------------------------------------------------------------
# Completion primitives
# --------------------------------------------------------------------------

__mulle_sourcetree_complete_words()
{
    local words="$1"

    COMPREPLY=($(compgen -W "${words}" -- "${cur}"))
}

__mulle_sourcetree_complete_addresses()
{
    __mulle_sourcetree_complete_words "$(__mulle_sourcetree_addresses_word)"
}

__mulle_sourcetree_complete_marks()
{
    __mulle_sourcetree_complete_words "$(__mulle_sourcetree_marks_word)"
}

__mulle_sourcetree_complete_nodetypes()
{
    __mulle_sourcetree_complete_words "${__mulle_sourcetree_nodetypes} ${__mulle_sourcetree_nodetype_filters}"
}

__mulle_sourcetree_complete_permissions()
{
    __mulle_sourcetree_complete_words "${__mulle_sourcetree_permissions}"
}

__mulle_sourcetree_complete_dedupe_modes()
{
    __mulle_sourcetree_complete_words "${__mulle_sourcetree_dedupe_modes//[[:space:]]+/ }"
}

__mulle_sourcetree_complete_output_formats()
{
    __mulle_sourcetree_complete_words "${__mulle_sourcetree_output_formats}"
}

__mulle_sourcetree_complete_files()
{
    COMPREPLY=($(compgen -f -- "${cur}"))
}

__mulle_sourcetree_complete_dirs()
{
    COMPREPLY=($(compgen -d -- "${cur}"))
}

__mulle_sourcetree_complete_urls()
{
    __mulle_sourcetree_complete_words "https:// http:// git:// ssh:// file://"
}

__mulle_sourcetree_complete_get_keys()
{
    __mulle_sourcetree_complete_words "${__mulle_sourcetree_get_keys}"
}

__mulle_sourcetree_complete_field_keys()
{
    __mulle_sourcetree_complete_words "${__mulle_sourcetree_field_keys} ALL uuid"
}

# Count non-option arguments typed before the current word. Arguments that
# belong to a value-taking option are skipped. The command word itself is
# skipped via __mulle_sourcetree_cmdindex (set by the main dispatcher).
__mulle_sourcetree_count_args()
{
    local valuemopts="$1"
    local i w count
    local prevopt=""
    local start="${__mulle_sourcetree_cmdindex:-1}"

    count=0
    for ((i=start + 1; i < COMP_CWORD; i++))
    do
        w="${COMP_WORDS[$i]}"
        if [ -n "${prevopt}" ]
        then
            prevopt=""
            continue
        fi
        if [[ "${w}" == -* ]]
        then
            if [[ " ${valuemopts} " == *" ${w} "* ]]
            then
                prevopt="${w}"
            fi
        else
            count=$((count + 1))
        fi
    done
    printf "%s\n" "${count}"
}

# --------------------------------------------------------------------------
# Option vocabulary for the "common" commands
# --------------------------------------------------------------------------

__mulle_sourcetree_common_options()
{
    echo "-a --address -b --branch -f --fetchoptions -m --marks -n --nodetype -s --scm -t --tag -u --url -U --userinfo --raw-userinfo -e --extended-mark --no-extended-mark --fuzzy --no-fuzzy --regex --no-regex --update --no-update --print-common-keys --print-common-options"
}

__mulle_sourcetree_common_extra_options()
{
    case "$1" in
        add)              echo "--if-missing" ;;
        mark)             echo "--set --show --show-marks" ;;
        move|remove|rm)   echo "--if-present --if-exists --error-if-missing" ;;
        set)              echo "--clear" ;;
    esac
}

# A string of the value-taking options of the common commands
__mulle_sourcetree_common_value_options()
{
    echo "--address -a --branch -b --fetchoptions -f --marks -m --nodetype -n --scm -s --tag -t --url -u --userinfo -U --raw-userinfo"
}

# --------------------------------------------------------------------------
# Completion for the "common" commands: add, copy, duplicate, get, mark,
# move, rcopy, remove, rename, rename-marks, set, unmark, info, knownmarks
# --------------------------------------------------------------------------
__mulle_sourcetree_common_complete()
{
    local cmd="$1"
    local common_options
    local value_options

    common_options="$(__mulle_sourcetree_common_options) $(__mulle_sourcetree_common_extra_options "${cmd}")"
    value_options="$(__mulle_sourcetree_common_value_options)"

    # value completion for the immediately preceding option
    case "${prev}" in
        --address|-a)
            __mulle_sourcetree_complete_dirs
            return 0
            ;;
        --url|-u)
            __mulle_sourcetree_complete_urls
            return 0
            ;;
        --marks|-m)
            __mulle_sourcetree_complete_marks
            return 0
            ;;
        --nodetype|-n|--scm|-s)
            __mulle_sourcetree_complete_nodetypes
            return 0
            ;;
        --set)
            __mulle_sourcetree_complete_marks
            return 0
            ;;
        --branch|-b|--fetchoptions|-f|--tag|-t|--userinfo|-U|--raw-userinfo)
            COMPREPLY=()
            return 0
            ;;
    esac

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "${common_options}"
        return 0
    fi

    local argcount
    argcount="$(__mulle_sourcetree_count_args "${value_options}")"

    case "${cmd}" in
        add|duplicate)
            __mulle_sourcetree_complete_addresses
            COMPREPLY+=( $(compgen -d -- "${cur}") )
            return 0
            ;;
        get)
            if [ "${argcount}" -eq 0 ]
            then
                __mulle_sourcetree_complete_addresses
            elif [ "${argcount}" -eq 1 ]
            then
                __mulle_sourcetree_complete_get_keys
            fi
            return 0
            ;;
        mark|unmark)
            if [ "${argcount}" -eq 0 ]
            then
                __mulle_sourcetree_complete_addresses
            else
                __mulle_sourcetree_complete_marks
            fi
            return 0
            ;;
        move)
            __mulle_sourcetree_complete_addresses
            return 0
            ;;
        copy)
            # copy <field> <dst> [config [src]]
            if [ "${argcount}" -eq 0 ]
            then
                __mulle_sourcetree_complete_field_keys
            elif [ "${argcount}" -eq 1 ]
            then
                __mulle_sourcetree_complete_addresses
            else
                __mulle_sourcetree_complete_words "config"
            fi
            return 0
            ;;
        rcopy)
            if [ "${argcount}" -eq 0 ]
            then
                __mulle_sourcetree_complete_addresses
            elif [ "${argcount}" -eq 1 ]
            then
                __mulle_sourcetree_complete_dirs
            fi
            return 0
            ;;
        rename)
            if [ "${argcount}" -eq 0 ]
            then
                __mulle_sourcetree_complete_addresses
            fi
            return 0
            ;;
        rename-marks)
            __mulle_sourcetree_complete_marks
            return 0
            ;;
        set)
            if [ "${argcount}" -eq 0 ]
            then
                __mulle_sourcetree_complete_addresses
            elif [ "${argcount}" -eq 1 ]
            then
                __mulle_sourcetree_complete_field_keys
            fi
            return 0
            ;;
        remove|rm)
            __mulle_sourcetree_complete_addresses
            return 0
            ;;
    esac
}

# --------------------------------------------------------------------------
# Per-command completion
# --------------------------------------------------------------------------

_mulle_sourcetree_add_complete()          { __mulle_sourcetree_common_complete add; }
_mulle_sourcetree_copy_complete()         { __mulle_sourcetree_common_complete copy; }
_mulle_sourcetree_duplicate_complete()    { __mulle_sourcetree_common_complete duplicate; }
_mulle_sourcetree_get_complete()          { __mulle_sourcetree_common_complete get; }
_mulle_sourcetree_mark_complete()         { __mulle_sourcetree_common_complete mark; }
_mulle_sourcetree_move_complete()         { __mulle_sourcetree_common_complete move; }
_mulle_sourcetree_rcopy_complete()        { __mulle_sourcetree_common_complete rcopy; }
_mulle_sourcetree_remove_complete()       { __mulle_sourcetree_common_complete remove; }
_mulle_sourcetree_rename_complete()       { __mulle_sourcetree_common_complete rename; }
_mulle_sourcetree_rename_marks_complete() { __mulle_sourcetree_common_complete rename-marks; }
_mulle_sourcetree_set_complete()          { __mulle_sourcetree_common_complete set; }
_mulle_sourcetree_unmark_complete()       { __mulle_sourcetree_common_complete unmark; }
_mulle_sourcetree_info_complete()         { __mulle_sourcetree_complete_words "-h --help"; }
_mulle_sourcetree_knownmarks_complete()   { __mulle_sourcetree_complete_words "-h --help"; }

_mulle_sourcetree_star_search_complete()
{
    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "-h --help"
    else
        __mulle_sourcetree_complete_addresses
    fi
}

_mulle_sourcetree_list_complete()
{
    local options="
        -h --help -l -ll -g -G -i -m -s -r -u -U -f
        --bequeath --no-bequeath
        --config-file --dedupe-mode
        --format --force-format
        --marks
        --no-dedupe
        --no-output-banner --no-output-color --no-output-column
        --no-output-eval --no-output-header --no-output-indent
        --no-output-index --no-output-marks --no-output-separator
        --no-output-url
        --nodetype --nodetypes
        --output-banner --output-cmdline --output-color --output-column
        --output-eval --output-format --output-full --output-header
        --output-index --output-marks --output-node --output-no-marks
        --output-no-separator --output-separator --output-url --output-uuid
        --qualifier --verbatim
    "

    case "${prev}" in
        --dedupe-mode)        __mulle_sourcetree_complete_dedupe_modes; return 0 ;;
        --output-format)      __mulle_sourcetree_complete_output_formats; return 0 ;;
        --marks|-m)            __mulle_sourcetree_complete_marks; return 0 ;;
        --nodetype|--nodetypes) __mulle_sourcetree_complete_nodetypes; return 0 ;;
        --qualifier)          COMPREPLY=(); return 0 ;;
        --config-file)        __mulle_sourcetree_complete_files; return 0 ;;
    esac

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "${options}"
    else
        __mulle_sourcetree_complete_addresses
    fi
}

_mulle_sourcetree_status_complete()
{
    local options="
        -h --help
        --all --shallow --deep
        --is-uptodate
        --output-filename --no-output-filename
        --output-header --no-output-header
        --output-separator --no-output-separator
        --output-format
    "

    case "${prev}" in
        --output-format) __mulle_sourcetree_complete_output_formats; return 0 ;;
    esac

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "${options}"
    fi
}

_mulle_sourcetree_dotdump_complete()
{
    local options="
        -h --help -m -n -p
        --lr --td
        --output-html --output-eval --output-state
        --no-output-html --no-output-eval --no-output-state
        --walk-config --walk-config-file --walk-db --walk-db-dir
    "

    case "${prev}" in
        -m|--marks)      __mulle_sourcetree_complete_marks; return 0 ;;
        -n|--nodetypes)  __mulle_sourcetree_complete_nodetypes; return 0 ;;
        -p|--permissions) __mulle_sourcetree_complete_permissions; return 0 ;;
    esac

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "${options}"
    fi
}

_mulle_sourcetree_walk_complete()
{
    local options="
        -h --help
        --backwards --bequeath --no-bequeath --breadth-first
        --cd --no-cd --comments --no-comments
        --callback --will-descend-callback --did-descend-callback --did-walk-callback
        --configuration --declaration --eval --leaf
        --lenient --no-lenient --no-dedupe
        --pre-order --post-order --in-order --breadth-order
        --qualifier --verbatim --walk-config --walk-db
        -n -p -m -q
    "

    case "${prev}" in
        -m|--marks)       __mulle_sourcetree_complete_marks; return 0 ;;
        -n|--nodetypes)   __mulle_sourcetree_complete_nodetypes; return 0 ;;
        -p|--permissions) __mulle_sourcetree_complete_permissions; return 0 ;;
        -q|--qualifier)   COMPREPLY=(); return 0 ;;
    esac

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "${options}"
    fi
}

_mulle_sourcetree_craftorder_complete()
{
    local options="
        -h --help
        --backwards --bequeath --no-bequeath --callback
        --no-print-env --no-output-marks --output-no-marks
        --output-absolute --output-relative --output-eval --output-raw-userinfo
        --print-qualifier
    "

    case "${prev}" in
        --callback) COMPREPLY=(); return 0 ;;
    esac

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "${options}"
    fi
}

_mulle_sourcetree_clean_complete()
{
    local options="-h --help --all-graveyards --config --fs --graveyard --no-db --no-share --share"

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "${options}"
    fi
}

_mulle_sourcetree_sync_complete()
{
    local options="
        -h --help
        --lenient --no-lenient --quick
        --parallel --no-parallel --serial
        --refresh --cache-refresh --mirror-refresh
        --no-refresh --no-cache-refresh --no-mirror-refresh
        --copy --symlink-copy --symlink --symlinks
        --no-symlink --no-symlinks --absolute-symlink --no-absolute-symlinks
        --resolve-tag --fixup --no-fixup
        --cache-dir --mirror-dir
        -l --search-path --local-search-path --locals-search-path
        --override-branch
    "

    case "${prev}" in
        --cache-dir|--mirror-dir|-l|--search-path|--local-search-path|--locals-search-path)
            __mulle_sourcetree_complete_dirs
            return 0
            ;;
        --override-branch)
            COMPREPLY=()
            return 0
            ;;
    esac

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "${options}"
    fi
}

_mulle_sourcetree_json_complete()
{
    local options="-h --help --expand --no-expand --raw --marks --nodetype --nodetypes --qualifier --version"

    case "${prev}" in
        --marks)             __mulle_sourcetree_complete_marks; return 0 ;;
        --nodetype|--nodetypes) __mulle_sourcetree_complete_nodetypes; return 0 ;;
        --qualifier)         COMPREPLY=(); return 0 ;;
    esac

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "${options}"
    fi
}

_mulle_sourcetree_filter_complete()
{
    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "-h --help"
    else
        __mulle_sourcetree_complete_marks
    fi
}

_mulle_sourcetree_test_complete()
{
    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "-h --help"
    else
        __mulle_sourcetree_complete_marks
    fi
}

_mulle_sourcetree_config_complete()
{
    local subcommand=""
    local i
    local start="${__mulle_sourcetree_cmdindex:-1}"

    for (( i=start + 1; i < COMP_CWORD; i++ ))
    do
        case "${COMP_WORDS[$i]}" in
            list|copy|status)
                subcommand="${COMP_WORDS[$i]}"
                break
                ;;
        esac
    done

    if [ -n "${subcommand}" ]
    then
        case "${subcommand}" in
            list)
                if [[ "${cur}" == -* ]]
                then
                    __mulle_sourcetree_complete_words "-h --help --name-only -n --no-warn -s --separator --fail-silently-if-missing"
                else
                    local names
                    names="$(${__mulle_sourcetree_timeout_cmd} mulle-sourcetree config list -n 2>/dev/null)"
                    COMPREPLY=($(compgen -W "${names}" -- "${cur}"))
                fi
                ;;
            copy)
                if [[ "${cur}" == -* ]]
                then
                    __mulle_sourcetree_complete_words "-h --help --all -a"
                fi
                ;;
            status)
                __mulle_sourcetree_complete_words "-h --help"
                ;;
        esac
        return 0
    fi

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "-h --help"
    else
        __mulle_sourcetree_complete_words "${__mulle_sourcetree_config_subcommands}"
    fi
}

_mulle_sourcetree_supermark_complete()
{
    local subcommand=""
    local i

    for ((i=2; i < COMP_CWORD; i++ ))
    do
        case "${COMP_WORDS[$i]}" in
            list|compose|decompose)
                subcommand="${COMP_WORDS[$i]}"
                break
                ;;
        esac
    done

    if [ -n "${subcommand}" ]
    then
        case "${subcommand}" in
            list)
                if [[ "${cur}" == -* ]]
                then
                    __mulle_sourcetree_complete_words "-h --help"
                else
                    __mulle_sourcetree_complete_words "$(__mulle_sourcetree_supermarks)"
                fi
                ;;
            compose|decompose)
                if [[ "${cur}" == -* ]]
                then
                    __mulle_sourcetree_complete_words "-h --help"
                else
                    local supermarks
                    supermarks="$(__mulle_sourcetree_supermarks)"
                    if [ -n "${supermarks}" ]
                    then
                        __mulle_sourcetree_complete_words "${supermarks}"
                    else
                        __mulle_sourcetree_complete_marks
                    fi
                fi
                ;;
        esac
        return 0
    fi

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "-h --help"
    else
        __mulle_sourcetree_complete_words "${__mulle_sourcetree_supermark_subcommands}"
    fi
}

_mulle_sourcetree_plugin_complete()
{
    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "-h --help"
    fi
}

_mulle_sourcetree_reset_complete()
{
    __mulle_sourcetree_complete_words "-h --help -g"
}

_mulle_sourcetree_eval_add_complete()
{
    case "${prev}" in
        --filename|--config-name)
            __mulle_sourcetree_complete_files
            return 0
            ;;
    esac

    if [[ "${cur}" == -* ]]
    then
        __mulle_sourcetree_complete_words "-h --help --filename --config-name"
    else
        __mulle_sourcetree_complete_files
    fi
}

_mulle_sourcetree_fix_complete()       { __mulle_sourcetree_complete_words "-h --help"; }
_mulle_sourcetree_reuuid_complete()    { __mulle_sourcetree_complete_words "-h --help"; }
_mulle_sourcetree_rewrite_complete()   { __mulle_sourcetree_complete_words "-h --help"; }
_mulle_sourcetree_wrap_complete()      { __mulle_sourcetree_complete_words "-h --help"; }

# Commands that announce a value and need no completion
_mulle_sourcetree_noargs_complete()    { COMPREPLY=(); }

# --------------------------------------------------------------------------
# Main completion entry point
# --------------------------------------------------------------------------
_mulle_sourcetree_complete()
{
    local cur prev
    local cword words

    if declare -F _get_comp_words_by_ref >/dev/null 2>&1
    then
        _get_comp_words_by_ref -n : cur prev words cword
        words=("${words[@]}")
    else
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        cword="${COMP_CWORD}"
        words=("${COMP_WORDS[@]}")
    fi

    # First word position: complete with commands + global flags.
    if [ "${cword}" -eq 1 ]
    then
        __mulle_sourcetree_complete_words "$(__mulle_sourcetree_commands_word) ${__mulle_sourcetree_global_options}"
        return 0
    fi

    # Global flags that take a value.
    case "${prev}" in
        --config|--config-name|--config-names)
            COMPREPLY=()
            return 0
            ;;
        --config-dir|--directory|-d|--share-dir|--stash-dir)
            __mulle_sourcetree_complete_dirs
            return 0
            ;;
        --config-file)
            __mulle_sourcetree_complete_files
            return 0
            ;;
        --mode)
            __mulle_sourcetree_complete_words "share flat recurse"
            return 0
            ;;
    esac

    # Locate the command: the first non-option token at index >= 1, skipping
    # values of value-taking global options. Handles e.g.
    # `mulle-sourcetree -v add ...` and `mulle-sourcetree --flat sync`.
    local cmdindex=1
    local i w
    for ((i=1; i < COMP_CWORD; i++))
    do
        w="${COMP_WORDS[$i]}"
        case "${w}" in
            -*)
                case "${w}" in
                    --config|--config-name|--config-names|--config-dir|--config-file|-d|--directory|--share-dir|--stash-dir|--mode|--git-terminal-prompt)
                        i=$((i + 1))
                        ;;
                esac
                ;;
            *)
                cmdindex="${i}"
                break
                ;;
        esac
    done
    __mulle_sourcetree_cmdindex="${cmdindex}"

    local cmd="${COMP_WORDS[${cmdindex}]}"

    case "${cmd}" in
        add)                  _mulle_sourcetree_add_complete ;;
        copy)                 _mulle_sourcetree_copy_complete ;;
        duplicate)            _mulle_sourcetree_duplicate_complete ;;
        get)                  _mulle_sourcetree_get_complete ;;
        mark)                 _mulle_sourcetree_mark_complete ;;
        move)                 _mulle_sourcetree_move_complete ;;
        rcopy)                _mulle_sourcetree_rcopy_complete ;;
        remove|rm)            _mulle_sourcetree_remove_complete ;;
        rename)               _mulle_sourcetree_rename_complete ;;
        rename-marks)         _mulle_sourcetree_rename_marks_complete ;;
        set)                  _mulle_sourcetree_set_complete ;;
        unmark)               _mulle_sourcetree_unmark_complete ;;
        info)                 _mulle_sourcetree_info_complete ;;
        knownmarks)           _mulle_sourcetree_knownmarks_complete ;;
        star-search)          _mulle_sourcetree_star_search_complete ;;
        list)                 _mulle_sourcetree_list_complete ;;
        status)               _mulle_sourcetree_status_complete ;;
        dotdump)              _mulle_sourcetree_dotdump_complete ;;
        walk)                 _mulle_sourcetree_walk_complete ;;
        craftorder)           _mulle_sourcetree_craftorder_complete ;;
        clean)                _mulle_sourcetree_clean_complete ;;
        desecrate)            _mulle_sourcetree_clean_complete ;;
        sync|update)          _mulle_sourcetree_sync_complete ;;
        json)                 _mulle_sourcetree_json_complete ;;
        filter)               _mulle_sourcetree_filter_complete ;;
        test)                 _mulle_sourcetree_test_complete ;;
        config)               _mulle_sourcetree_config_complete ;;
        supermark)            _mulle_sourcetree_supermark_complete ;;
        plugin|plugins)       _mulle_sourcetree_plugin_complete ;;
        reset)                _mulle_sourcetree_reset_complete ;;
        eval-add)             _mulle_sourcetree_eval_add_complete ;;
        fix)                  _mulle_sourcetree_fix_complete ;;
        reuuid)               _mulle_sourcetree_reuuid_complete ;;
        rewrite)              _mulle_sourcetree_rewrite_complete ;;
        wrap)                 _mulle_sourcetree_wrap_complete ;;
        dbstatus|etc-dir|libexec-dir|library-path|project-dir|pwd|path|share-dir|stash-dir|shell|tool-env|touch|uname|version|mode)
            _mulle_sourcetree_noargs_complete
            ;;
        *)
            __mulle_sourcetree_complete_words "$(__mulle_sourcetree_commands_word)"
            ;;
    esac

    return 0
}

# --------------------------------------------------------------------------
# Registration
# --------------------------------------------------------------------------
complete -F _mulle_sourcetree_complete mulle-sourcetree