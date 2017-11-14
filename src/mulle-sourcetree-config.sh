#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the name of Mulle kybernetiK nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without specific prior written permission.
#
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
#   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#   POSSIBILITY OF SUCH DAMAGE.
#
MULLE_SOURCETREE_COMMANDS_SH="included"


#
# All commands in here are not recursive!
#

sourcetree_add_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} add [options] <address|url>

   You can add without specifying an URL any existing subdirectory.
   This will create a node of nodetype "none"

   When specifying a nodetype other than node, you can also add git or
   svn repositories, be tar or zip archives.

   These will be fetched and possibly unpacked on the next update.

   Examples:
      ${MULLE_EXECUTABLE_NAME} add ./src
      ${MULLE_EXECUTABLE_NAME} add --url https://x.com/x external/x

Options:
   --branch <value>       : branch to use instead of the default
   --nodetype <value>     : the node type (default: none)
   --fetchoptions <value> : options for mulle-fetch --options
   --marks <value>        : key-value sourcetree marks (e.g. build=yes)
   --tag <value>          : tag to checkout
   --url <value>          : url to fetch the node from
   --userinfo <value>     : userinfo for node
EOF
  exit 1
}


sourcetree_remove_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} remove <address>

   Remove a nodes with the given url.

   This command only reads the local config file.
EOF
  exit 1
}


sourcetree_info_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} info

   Print the current sourcetree and the database configuration, if any.
   To check if the current directory is a sourcetree or sourcetree node:

      ${MULLE_EXECUTABLE_NAME} --no-defer info

EOF
  exit 1
}


sourcetree_list_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} list [options]

   List nodes in the sourcetree.

   This command only reads the local config file.

Options:
   --output-raw           : output as CSV (semicolon separated values)
   --output-cmd           : output as ${MULLE_EXECUTABLE_NAME} command line
   --output-full          : show url and various fetch options
   --output-eval          : show evaluated values as passed to ${MULLE_FETCH:-mulle-fetch}
   --no-output-header     : suppress header in raw and default lists
   --no-output-separator  : suppress separator line if header is printed
EOF
  exit 1
}


sourcetree_mark_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} mark <url> <mark>

   You can mark or unmark a node with this command. Examine the node values
   with \`${MULLE_EXECUTABLE_NAME} get <url> | sed -n '7p'\`.

   This command only affects the local config file.

Marks:
   [no]build     : the node contains a buildable project (used by buildorder)
   [no]delete    : the node may be deleted or moved
   [no]recurse   : the node takes part in recursive operations
   [no]require   : the node must exist
   [no]set       : the nodes properies can be changed
   [no]share     : the node may be shared with subtree nodes of the same url
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
   then
      cat <<EOF >&2
                   the effect is, that an URL is only fetched once and stored
                   in the main sourcetree, not the subtree.
EOF
   fi

   cat <<EOF >&2
   [no]update    : the node takes part in the update

   A node contains all positive marks, as only negative marks are actually
   stored in the node.

   Example:
      ${MULLE_EXECUTABLE_NAME} mark https://foo.com/bar nobuild
EOF


  exit 1
}


sourcetree_set_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} set [options] <address> [key [value]]*

   Change any value of a node with the set command. Changes are applied
   with the next update. You can can specify values with the options or
   parameter key value pairs, which have precedence.

   This command only reads the local config file.

Options:
   --branch <value>       : branch to use instead of the default (git)
   --address <dir>        : address of the node in the project
   --fetchoptions <value> : options for mulle-fetch --options
   --marks <value>        : key-value sourcetree marks (e.g. build=yes)
   --tag <value>          : tag to checkout for git
   --nodetype <value>     : the node type
   --url <url>            : url of the node
   --userinfo <value>     : userinfo for node
EOF
  exit 1
}


sourcetree_get_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} get <address> [fields]

   Emit config values. The possible value for field are

   address branch fetchoptions marks nodetype tag uuid url userinfo

   This command only reads the local config file.
EOF
  exit 1
}



#
#
#
sourcetree_add_node()
{
   log_entry "sourcetree_add_node" "$@"

   local input="$1"

   local addresss
   local branch="${OPTION_BRANCH}"
   local fetchoptions="${OPTION_FETCHOPTIONS}"
   local marks="${OPTION_MARKS}"
   local nodetype="${OPTION_NODETYPE}"
   local tag="${OPTION_TAG}"
   local url="${OPTION_URL}"
   local userinfo="${OPTION_USERINFO}"
   local uuid

   #
   # try to figure out nodetype. At this point adre
   #
   if [ -z "${nodetype}" -a ! -z "${url}" ]
   then
      nodetype="`node_guess_nodetype "${url}"`"
   fi

   if [ -z "${nodetype}" -a ! -z "${input}" ]
   then
      nodetype="`node_guess_nodetype "${input}"`"
   fi

   if [ -z "${nodetype}" ]
   then
      case "${input}" in
         *:*|~*|/*)
            fail "Please specify --nodetype"
         ;;

         *)
            if [ ! -z "${url}" ]
            then
               fail "Please specify --nodetype"
            fi
            nodetype="local"
         ;;
      esac
   fi

   #
   # try to figure out if input is an url
   # trivially, it is the address if url is empty
   #
   if [ -z "${url}" ]
   then
      case "${input}" in
         *:*)
            url="${input}"
            address="`node_guess_address "${url}" "${nodetype}"`"
         ;;

         /*|~*)
            case "${nodetype}" in
               none)
                  address="`symlink_relpath "${input}" "${PWD}"`"
               ;;

               *)
                  url="${input}"
                  address="`node_guess_address "${url}" "${nodetype}"`"
               ;;
            esac
         ;;
      esac
   fi

   if [ -z "${address}" ]
   then
      address="${input}"
   fi

   if nodeline_config_has_duplicate "${address}"
   then
      fail "There is already a node ${C_RESET_BOLD}${address}${C_ERROR_TEXT} \
in the sourcetree"
   fi

   if [ -z "${url}" ]
   then
      if ! [ -e "${address}" ]
      then
         log_warning "There is no directory or file named \"${address}\""
      fi
   else
      if [ -e "${address}" ]
      then
         log_warning "A directory or file named \"${address}\" already exists"
      fi
   fi

   #
   # now just some sanity checks and save it
   #
   local mode

   if [ "${OPTION_UNSAFE}" = "YES" ]
   then
      mode="`concat "${mode}" "nosafe"`"
   fi
   node_augment "${mode}"


   if nodeline_config_get_nodeline "${address}" > /dev/null
   then
      fail "${C_RESET_BOLD}${address}${C_ERROR_TEXT} already exists"
   fi

   local contents
   local nodeline
   local removed
   local appended


   contents="`egrep -s -v '^#' "${SOURCETREE_CONFIG_FILE}"`"
   nodeline="`node_print_nodeline`"
   appended="`add_line "${contents}" "${nodeline}"`"

   redirect_exekutor "${SOURCETREE_CONFIG_FILE}" echo "${appended}"
}


sourcetree_remove_node()
{
   log_entry "sourcetree_remove_node" "$@"

   local address="$1"

   if [ ! -f "${SOURCETREE_CONFIG_FILE}" ]
   then
      return 1
   fi

   local oldnodeline

   oldnodeline="`nodeline_config_get_nodeline "${address}"`" || return 1
   if [ ! -z "${oldnodeline}" ]
   then
      nodeline_config_remove_nodeline "${address}"
      if [ -z "`nodeline_config_read`" ]
      then
         remove_file_if_present "${SOURCETREE_CONFIG_FILE}"
      fi
   fi
}


sourcetree_change_nodeline()
{
   log_entry "sourcetree_change_nodeline" "$@"

   local oldnodeline="$1"
   local newnodeline="$2"
   local address="$3"

   if [ "${newnodeline}" = "${oldnodeline}" ]
   then
      log_info "Nothing changed"
      return
   fi

   nodeline_config_change_nodeline "${oldnodeline}" "${newnodeline}"

   local verifynodelines
   local verifynodeline

   verifynodelines="`nodeline_config_read`"
   verifynodeline="`nodeline_find "${verifynodelines}" "${address}"`"

   if [ "${verifynodeline}" != "${newnodeline}" ]
   then
      fail "Verify of config file failed."
   fi
}


_unfailing_get_nodeline()
{
   local address="$1"

   if ! nodeline_config_get_nodeline "${address}"
   then
      fail "A node \"${address}\" does not exist"
   fi

}

#
# we need to keep the position in the file as it is important
# so add/remove is not the solution
#
sourcetree_set_node()
{
   log_entry "sourcetree_set_node" "$@"

   local address="$1"; shift

   local oldnodeline

   oldnodeline="`_unfailing_get_nodeline "${address}"`" || exit 1

   local branch
   local address
   local fetchoptions
   local marks
   local nodetype
   local tag
   local url
   local uuid
   local userinfo

   nodeline_parse "${oldnodeline}"

   if nodemarks_contain_noset "${marks}"
   then
      fail "Node is marked as noset"
   fi

   branch="${OPTION_BRANCH:-${branch}}"
   address="${OPTION_ADDRESS:-${address}}"
   fetchoptions="${OPTION_FETCHOPTIONS:-${fetchoptions}}"
   marks="${OPTION_MARKS:-${marks}}"
   nodetype="${OPTION_NODETYPE:-${nodetype}}"
   url="${OPTION_URL:-${url}}"
   tag="${OPTION_TAG:-${tag}}"
   userinfo="${OPTION_USERINFO:-${userinfo}}"

   local key

   while [ "$#" -ge 2 ]
   do
      key="$1"
      shift

      case "${key}" in
         branch|address|fetchoptions|info|marks|nodetype|tag|url|userinfo)
            eval ${key}="'$1'"
            log_debug "Set $key to \"`eval echo \\\$${key}`\""
         ;;
         *)
            log_error "unknown keyword \"$1\""
            sourcetree_set_usage
         ;;
      esac
      shift
   done

   if [ "$#" -ne 0 ]
   then
      log_error "key \"$1\" without value"
      sourcetree_set_usage
   fi

   node_augment "${OPTION_AUGMENTMODE}"

   local newnodeline

   newnodeline="`node_print_nodeline`"

   if nodeline_config_has_duplicate "${address}" "${uuid}"
   then
      fail "There is already a node ${C_RESET_BOLD}${address}${C_ERROR_TEXT} \
in the sourcetree
"
   fi

   sourcetree_change_nodeline "${oldnodeline}" "${newnodeline}" "${address}"
}


sourcetree_get_node()
{
   log_entry "sourcetree_get_node" "$@"

   local address="$1"; shift

   local nodeline

   nodeline="`_unfailing_get_nodeline "${address}"`" || exit 1

   local branch
   local address
   local fetchoptions
   local marks
   local nodetype
   local tag
   local url
   local uuid
   local userinfo

   nodeline_parse "${nodeline}"

   if [ "$#" -eq 0 ]
   then
      exekutor echo "${url}"
      return
   fi

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         branch|address|fetchoptions|marks|nodetype|tag|url|uuid|userinfo)
            exekutor eval echo \$"${1}"
         ;;
         *)
            log_error "unknown keyword \"$1\""
            sourcetree_get_usage
         ;;
      esac
      shift
   done
}


sourcetree_mark_node()
{
   log_entry "sourcetree_mark_node" "$@"

   local address="$1"
   local mark="$2"

   [ -z "${address}" ] && fail "address is empty"
   [ -z "${mark}" ] && fail "mark is empty"

   local oldnodeline

   oldnodeline="`_unfailing_get_nodeline "${address}"`" || exit 1

   local branch
   local address
   local fetchoptions
   local marks
   local nodetype
   local tag
   local url
   local userinfo
   local uuid

   nodeline_parse "${oldnodeline}"
   if nodemarks_contain "${marks}" "${mark}"
   then
      case "${mark}" in
         no*)
            log_verbose "Node already marked as \"${mark}\""
         ;;

         *)
            log_info "Node implicitly marked as \"${mark}\". No need to mark it."
         ;;
      esac
      return
   fi

   local operation

   operation="nodemarks_add_${mark}"
   if [ "`type -t "${operation}"`" = "function" ]
   then
      marks="`${operation} "${marks}"`"
   else
      if [ "${OPTION_EXTENDED_MARKS}" != "YES" ]
      then
         fail "mark \"${mark}\" is unknown"
      fi

      case "${mark}" in
         "")
            fail "mark is empty"
         ;;

         no*)
            if egrep -q -s '[^a-z]' <<< "${mark}"
            then
               fail "mark must contain only lowercase letters"
            fi
         ;;

         *)
            fail "mark must start with no"
         ;;
      esac
      marks="${marks} ${mark}"
   fi

   local newnodeline

   newnodeline="`node_print_nodeline`"
   sourcetree_change_nodeline "${oldnodeline}" "${newnodeline}" "${address}"
}


_sourcetree_list_nodes()
{
   log_entry "sourcetree_list_nodes" "$@"

   local mode="$1"

   nodeline_print_header "${mode}"

   local nodeline
   local nodelines

   nodelines="`nodeline_config_read`" || exit 1

   IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -z "${nodeline}" ]
      then
         nodeline_print "${nodeline}" "${mode}"
      fi
   done
   IFS="${DEFAULT_IFS}"
}


_sourcetree_augment_mode_with_output_options()
{
   log_entry "_sourcetree_augment_mode_with_output_options" "$@"

   local mode="$1"

   if [ "${OPTION_OUTPUT_HEADER}" != "NO" ]
   then
      mode="`concat "${mode}" "output_header"`"
      if [ "${OPTION_OUTPUT_SEPARATOR}" != "NO" ]
      then
         mode="`concat "${mode}" "output_separator"`"
      fi
   fi
   if [ "${OPTION_OUTPUT_FULL}" = "YES" ]
   then
      mode="`concat "${mode}" "output_full"`"
   fi
   if [ "${OPTION_OUTPUT_EVAL}" = "YES" ]
   then
      mode="`concat "${mode}" "output_eval"`"
   fi
   if [ "${OPTION_OUTPUT_UUID}" = "YES" ]
   then
      mode="`concat "${mode}" "output_uuid"`"
   fi

   case "${OPTION_OUTPUT_FORMAT}" in
      "RAW")
         mode="`concat "${mode}" "output_raw"`"
      ;;

      "COMMANDLINE")
         mode="`concat "${mode}" "output_cmdline"`"
      ;;

      ""|*)
         [ -z "`command -v column`" ] && fail "Tool \"column\" is not available, use --output-raw"

         mode="`concat "${mode}" "output_column"`"
      ;;
   esac

   echo "${mode}"
}


sourcetree_list_node()
{
   log_entry "sourcetree_list_node" "$@"

   if [ ! -f "${SOURCETREE_CONFIG_FILE}" ]
   then
      log_fluff "${SOURCETREE_CONFIG_FILE} doesn't exist"
      return
   fi

   mode="`_sourcetree_augment_mode_with_output_options`"

   case "${mode}" in
      *output_column*)
         _sourcetree_list_nodes "${mode}" | column -t -s '|'
      ;;

      *)
         _sourcetree_list_nodes "${mode}"
      ;;
   esac
}


sourcetree_info_node()
{
   log_entry "sourcetree_info_node" "$@"

   [ -z "${MULLE_EXECUTABLE_PWD}" ] && internal_fail "MULLE_EXECUTABLE_PWD is empty"

   log_info "Mode: ${C_MAGENTA}${C_BOLD}${SOURCETREE_MODE}${C_INFO}"

   case "${SOURCETREE_MODE}" in
      share)
         if [ ! -z "${MULLE_SOURCETREE_SHARED_DIR}" ]
         then
            log_info "Mode: ${C_RESET_BOLD}${MULLE_SOURCETREE_SHARED_DIR}${C_INFO}"
         fi
      ;;
   esac

   if [ "${MULLE_EXECUTABLE_PWD}" = "${PWD}" ]
   then
      log_fluff "Is local (${MULLE_EXECUTABLE_PWD})"
      return
   fi

   if nodeline_config_exists "${MULLE_EXECUTABLE_PWD}/"
   then
      log_info "${C_RESET_BOLD}`basename -- ${MULLE_EXECUTABLE_PWD}`${C_INFO} is a subtree of its master"
      return
   fi

   if db_exists "${MULLE_EXECUTABLE_PWD}/"
   then
      log_info "${C_RESET_BOLD}`basename -- ${MULLE_EXECUTABLE_PWD}`${C_INFO} contains a graveyard"
      return
   fi
}


sourcetree_common_main()
{
   log_entry "sourcetree_common_main" "$@"

   local ROOT_DIR

   ROOT_DIR="`pwd -P`"

   # must be empty initially for set
   local OPTION_URL
   local OPTION_DSTFILE
   local OPTION_BRANCH
   local OPTION_TAG
   local OPTION_NODETYPE
   local OPTION_MARKS
   local OPTION_FETCHOPTIONS
   local OPTION_USERINFO

   local OPTION_FETCH_SEARCH_PATH
   local OPTION_CACHE_DIR
   local OPTION_MIRROR_DIR

   local OPTION_OUTPUT_FORMAT="DEFAULT"
   local OPTION_OUTPUT_COLOR="DEFAULT"
   local OPTION_OUTPUT_HEADER="DEFAULT"
   local OPTION_OUTPUT_SEPARATOR="DEFAULT"
   local OPTION_GUESS_NODETYPE="DEFAULT"
   local OPTION_EXTENDED_MARKS="DEFAULT"
   local OPTION_GUESS_DSTFILE="DEFAULT_IFS"
   local OPTION_UNSAFE="NO"
   local OPTION_OUTPUT_UUID="DEFAULT"
   local OPTION_OUTPUT_EVAL="NO"
   local OPTION_OUTPUT_FULL="NO"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            ${USAGE}
         ;;

         --output-format*)
            OPTION_OUTPUT_FORMAT="FORMATTED"
         ;;

         --output-cmd)
            OPTION_OUTPUT_FORMAT="COMMANDLINE"
         ;;

         --output-raw|--output-csv)
            OPTION_OUTPUT_FORMAT="RAW"
         ;;

         --output-color)
            OPTION_OUTPUT_COLOR="YES"
         ;;

         --no-output-color)
            OPTION_OUTPUT_COLOR="NO"
         ;;

         --output-header)
            OPTION_OUTPUT_HEADER="YES"
         ;;

         --no-output-header)
            OPTION_OUTPUT_HEADER="NO"
         ;;

         --output-separator)
            OPTION_OUTPUT_SEPARATOR="YES"
         ;;

         --no-output-separator)
            OPTION_OUTPUT_SEPARATOR="NO"
         ;;

         #
         # just for add
         #
         --guess-nodetype)
            OPTION_GUESS_NODETYPE="YES"
         ;;

         --no-guess-nodetype)
            OPTION_GUESS_NODETYPE="NO"
         ;;

         --guess-address)
            OPTION_GUESS_DESTINATION="YES"
         ;;

         --no-guess-address)
            OPTION_GUESS_DESTINATION="NO"
         ;;

         #
         # marks
         #
         --extended-marks)
            OPTION_EXTENDED_MARKS="YES"
         ;;

         --no-extended-marks)
            OPTION_EXTENDED_MARKS="NO"
         ;;

         #
         #
         #
         --output-full)
            OPTION_OUTPUT_FULL="YES"
         ;;

         --no-output-full)
            OPTION_OUTPUT_FULL="NO"
         ;;

         --output-uuid)
            OPTION_OUTPUT_UUID="YES"
         ;;

         --no-output-uuid)
            OPTION_OUTPUT_UUID="NO"
         ;;

         #
         # more common flags
         #
         -a|--address)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_ADDRESS="$1"
         ;;

         -b|--branch)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_BRANCH="$1"
         ;;

         -e|--output-eval)
            OPTION_OUTPUT_EVAL="YES"
         ;;

         --no-output-eval)
            OPTION_OUTPUT_EVAL="NO"
         ;;

         -f|--fetchoptions)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_FETCHOPTIONS="$1"
         ;;

         -m|--marks)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_MARKS="$1"
         ;;

         -n|--nodetype|-s|--scm)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_NODETYPE="$1"
         ;;

         -t|--tag)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_TAG="$1"
         ;;

         -u|--url)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_URL="$1"
         ;;

         -U|--userinfo)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_USERINFO="$1"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown ${COMMAND} option $1"
            ${USAGE}
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   local address
   local url
   local key
   local mark
   local mode

   [ -z "${SOURCETREE_CONFIG_FILE}" ] && fail "config file empty name"

   case "${COMMAND}" in
      add)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         address="$1"
         [ -z "${address}" ] && log_error "empty argument" && ${USAGE}
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree_add_node "${address}"
      ;;

      remove)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         address="$1"
         [ -z "${address}" ] && log_error "empty argument" && ${USAGE}
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}
         sourcetree_${COMMAND}_node "${address}"
      ;;

      get|set)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         address="$1"
         [ -z "${address}" ] && log_error "empty argument" && ${USAGE}
         shift
         sourcetree_${COMMAND}_node "${address}" "$@"
      ;;


      mark)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         address="$1"
         [ -z "${address}" ] && log_error "empty argument" && ${USAGE}
         shift
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         mark="$1"
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree_${COMMAND}_node "${address}" "${mark}"
      ;;

      list|info)
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree_${COMMAND}_node
      ;;
   esac
}


sourcetree_add_main()
{
   log_entry "sourcetree_add_main" "$@"

   USAGE="sourcetree_add_usage"
   COMMAND="add"
   sourcetree_common_main "$@"
}


sourcetree_remove_main()
{
   log_entry "sourcetree_remove_main" "$@"

   USAGE="sourcetree_remove_usage"
   COMMAND="remove"
   sourcetree_common_main "$@"
}


sourcetree_get_main()
{
   log_entry "sourcetree_get_main" "$@"

   USAGE="sourcetree_get_usage"
   COMMAND="get"
   sourcetree_common_main "$@"
}


sourcetree_set_main()
{
   log_entry "sourcetree_set_main" "$@"

   USAGE="sourcetree_set_usage"
   COMMAND="set"
   sourcetree_common_main "$@"
}


sourcetree_mark_main()
{
   log_entry "sourcetree_mark_main" "$@"

   USAGE="sourcetree_mark_usage"
   COMMAND="mark"
   sourcetree_common_main "$@"
}


sourcetree_info_main()
{
   log_entry "sourcetree_info_main" "$@"

   USAGE="sourcetree_info_usage"
   COMMAND="info"
   sourcetree_common_main "$@"
}


sourcetree_list_main()
{
   log_entry "sourcetree_list_main" "$@"

   USAGE="sourcetree_list_usage"
   COMMAND="list"
   sourcetree_common_main "$@"
}


sourcetree_commands_initialize()
{
   log_entry "sourcetree_commands_initialize"

   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
   # shellcheck source=mulle-sourcetree-db.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh"
   fi
   if [ -z "${MULLE_SOURCETREE_NODE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-node.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-node.sh" || exit 1
      # shellcheck source=mulle-sourcetree-nodeline.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodeline.sh" || exit 1
   fi

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi
}


sourcetree_commands_initialize

:
