#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in nodetype and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of nodetype code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the uuid of Mulle kybernetiK nor the names of its contributors
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


sourcetree_add_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} add [options] <url> [dst]

   Nodes can be git or svn repositories. Nodes can be tar or zip archives.
   Nodes can also be files. Changes will applied on the
   next update. The URL must be unique. If you omit the destination, then
   mulle-sourcetree will try to guess a destination name and place it there.


Options:
   --branch <value>       : branch to use instead of the default (git)
   --type <value>         : the node type (default: git)
   --fetchoptions <value> : options for mulle-fetch --options
   --marks <value>        : key-value sourcetree marks (e.g. build=yes)
   --tag <value>          : tag to checkout for git
   --userinfo <value>     : userinfo for node
EOF
  exit 1
}


sourcetree_remove_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} remove <url>

   Remove a nodes with the given url.
EOF
  exit 1
}


sourcetree_list_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} [options] list

   List nodes in the sourcetree.

Options:
   --output-raw           : output as CSV (semicolon separate values)
   --output-cmd           : output as ${MULLE_EXECUTABLE_NAME} command line
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
   ${MULLE_EXECUTABLE_NAME} set [options] <url>

   Change any value of a node with the set command. Changes are applied
   with the next update.

Options:
   --branch <value>       : branch to use instead of the default (git)
   --destination <dir>    : destination of the node in the project
   --fetchoptions <value> : options for mulle-fetch --options
   --marks <value>        : key-value sourcetree marks (e.g. build=yes)
   --tag <value>          : tag to checkout for git
   --type <value>         : the node type (default: git)
   --url <url>            : url of the node
   --userinfo <value>     : userinfo for node
EOF
  exit 1
}


_sourcetree_get_nodeline_by_url()
{
   local nodelines

   nodelines="`nodeline_read_config`"
   nodeline_find_by_url "${nodelines}" "${url}"
}


sourcetree_get_nodeline_by_url()
{
   if ! _sourcetree_get_nodeline_by_url
   then
      fail "No node with url \"${url}\" found"
   fi
}


sourcetree_add_node()
{
   log_entry "sourcetree_add_node" "$@"

   local url="$1"
   local destination="$2"

   if _sourcetree_get_nodeline_by_url "${url}" > /dev/null
   then
      fail "Node with \"${url}\" already exists"
   fi

   local branch="${OPTION_BRANCH}"
   local fetchoptions="${OPTION_FETCHOPTIONS}"
   local nodetype="${OPTION_NODETYPE}"
   local marks="${OPTION_MARKS}"
   local tag="${OPTION_TAG}"
   local uuid
   local userinfo="${OPTION_USERINFO}"

   local mode

   if [ "${OPTION_GUESS_NODETYPE}" != "NO" ]
   then
      mode="`concat "${mode}" "guesstype"`"
   fi
   if [ "${OPTION_GUESS_DESTINATION}" != "NO" ]
   then
      mode="`concat "${mode}" "guessdst"`"
   fi
   if [ "${OPTION_UNSAFE}" = "YES" ]
   then
      mode="`concat "${mode}" "nosafe"`"
   fi

   node_augment "${mode}"

   if [ ! -f "${SOURCETREE_CONFIG_FILE}" ]
   then
      log_fluff "Empty config file, writing first line"
      redirect_exekutor "${SOURCETREE_CONFIG_FILE}" node_print_nodeline
      return $?
   fi

   local contents
   local nodeline
   local removed
   local appended

   contents="`cat "${SOURCETREE_CONFIG_FILE}"`"
   removed="`nodeline_remove_by_url "${contents}" "${url}"`" || exit 1

   nodeline="`node_print_nodeline`"
   appended="`add_line "${removed}" "${nodeline}"`"

   redirect_exekutor "${SOURCETREE_CONFIG_FILE}" echo "${appended}"
}


sourcetree_change_nodeline()
{
   log_entry "sourcetree_change_nodeline" "$@"

   local oldnodeline="$1"
   local newnodeline="$2"

   if [ "${newnodeline}" = "${oldnodeline}" ]
   then
      log_info "Nothing changed"
      return
   fi

   local oldescaped
   local newescaped

   oldescaped="`escaped_sed_pattern "${oldnodeline}"`"
   newescaped="`escaped_sed_pattern "${newnodeline}"`"

   log_debug "Editing \"${SOURCETREE_CONFIG_FILE}\""
   if ! exekutor sed -i '-bak' -e "s/^${oldescaped}$/${newescaped}/" "${SOURCETREE_CONFIG_FILE}"
   then
      fail "Edit of config file failed unexpectedly"
   fi

   local verifynodelines
   local verifynodeline

   verifynodelines="`nodeline_read_config`"
   verifynodeline="`nodeline_find_by_url "${verifynodelines}" "${url}"`"

   if [ "${verifynodeline}" != "${newnodeline}" ]
   then
      fail "Verify of config file failed."
   fi
}


#
# we need to keep the position in the file as it is important
# so add/remove is not the solution
#
sourcetree_set_node()
{
   log_entry "sourcetree_set_node" "$@"

   local url="$1"

   local oldnodeline

   oldnodeline="`sourcetree_get_nodeline_by_url "${url}"`" || exit 1

   local branch
   local destination
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
   destination="${OPTION_DESTINATION:-${destination}}"
   fetchoptions="${OPTION_FETCHOPTIONS:-${fetchoptions}}"
   marks="${OPTION_MARKS:-${marks}}"
   nodetype="${OPTION_NODETYPE:-${nodetype}}"
   url="${OPTION_URL:-${url}}"
   tag="${OPTION_TAG:-${tag}}"
   userinfo="${OPTION_USERINFO:-${userinfo}}"

   node_augment "${OPTION_AUGMENTMODE}"

   local newnodeline

   newnodeline="`node_print_nodeline`"

   sourcetree_change_nodeline "${oldnodeline}" "${newnodeline}"
}


sourcetree_get_node()
{
   log_entry "sourcetree_get_node" "$@"

   local url="$1"

   local oldnodelines
   local oldnodeline

   oldnodelines="`nodeline_read_config`"
   oldnodeline="`nodeline_find_by_url "${oldnodelines}" "${url}"`"

   if [ "$?" -ne 0 ]
   then
      fail "No node with url \"${url}\" found"
   fi

   IFS=";"
   for item in ${oldnodeline}
   do
      exekutor echo "${item}"
   done
   IFS="${DEFAULT_IFS}"
}


sourcetree_remove_node()
{
   log_entry "sourcetree_remove_node" "$@"

   local url="$1"

   if [ ! -f "${SOURCETREE_CONFIG_FILE}" ]
   then
      log_warning "${SOURCETREE_CONFIG_FILE} doesn't exist"
      return
   fi

   local contents
   local removed

   contents="`cat "${SOURCETREE_CONFIG_FILE}"`"
   removed="`nodeline_remove_by_url "${contents}" "${url}"`" || exit 1

   if [ ! -z "${removed}" ]
   then
      redirect_exekutor "${SOURCETREE_CONFIG_FILE}" echo "${removed}"
   else
      remove_file_if_present "${SOURCETREE_CONFIG_FILE}"
   fi
}


sourcetree_mark_node()
{
   log_entry "sourcetree_mark_node" "$@"

   local url="$1"
   local mark="$2"

   [ -z "${url}" ] && fail "url is empty"
   [ -z "${mark}" ] && fail "url is empty"

   local oldnodeline

   oldnodeline="`sourcetree_get_nodeline_by_url "${url}"`" || exit 1

   local branch
   local destination
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
   sourcetree_change_nodeline "${oldnodeline}" "${newnodeline}"
}


_sourcetree_list_nodes()
{
   log_entry "sourcetree_list_nodes" "$@"

   local mode="$1"

   local nodelines

   nodelines="`nodeline_read_config`" || exit 1

   local branch
   local destination
   local fetchoptions
   local marks
   local nodetype
   local tag
   local url
   local userinfo
   local uuid
   local sep

   sep=";"
   case "${mode}" in
      *column*)
         sep="|"
      ;;
   esac

   case "${mode}" in
      *header*)
         printf "%s" "url${sep}destination${sep}branch${sep}tag\
${sep}marks"
         if [ "${OPTION_OUTPUT_FULL}" = "YES" ]
         then
            printf "%s" "${sep}nodetype${sep}fetchoptions${sep}userinfo"
         fi
         if [ "${OPTION_OUTPUT_UUID}" = "YES" ]
         then
            printf "%s" "${sep}uuid"
         fi
         printf "\n"
      ;;
   esac

   case "${mode}" in
      *separator*)
         printf "%s" "---${sep}-------${sep}------${sep}---\
${sep}-----"
         if [ "${OPTION_OUTPUT_FULL}" = "YES" ]
         then
            printf "%s" "${sep}--------${sep}------------${sep}--------"
         fi
         if [ "${OPTION_OUTPUT_UUID}" = "YES" ]
         then
            printf "%s" "${sep}----"
         fi
         printf "\n"
      ;;
   esac

   local line

   IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -z "${nodeline}" ]
      then
         nodeline_parse "${nodeline}"

         if [ "${OPTION_OUTPUT_EVAL}" = "YES" ]
         then
            url="`eval echo "${url}"`"
            branch="`eval echo "${branch}"`"
            tag="`eval echo "${tag}"`"
            fetchoptions="`eval echo "${fetchoptions}"`"
         fi

         case "${mode}" in
            *cmdline*)
               local line
               local guess

               line="${MULLE_EXECUTABLE_NAME} add"

               guess="`node_guess_destination "${url}" "${nodetype}"`"
               if [ "${guess}" != "${destination}" ]
               then
                  line="`concat "${line}" "-d '${destination}'"`"
               fi
               if [ ! -z "${branch}" -a "${branch}" != "master" ]
               then
                  line="`concat "${line}" "--branch '${branch}'"`"
               fi
               if [ ! -z "${tag}" ]
               then
                  line="`concat "${line}" "--tag '${tag}'"`"
               fi
               if [ ! -z "${nodetype}" -a "${nodetype}" != "git" ]
               then
                  line="`concat "${line}" "--nodetype '${nodetype}'"`"
               fi
               if [ ! -z "${fetchoptions}" ]
               then
                  line="`concat "${line}" "--fetchoptions '${fetchoptions}'"`"
               fi
               if [ ! -z "${marks}" ]
               then
                  line="`concat "${line}" "--marks '${marks}'"`"
               fi
               if [ ! -z "${userinfo}" ]
               then
                  line="`concat "${line}" "--userinfo '${userinfo}'"`"
               fi

               line="`concat "${line}" "'${url}'"`"

               echo "${line}"
            ;;

            *column*)
               # need space for colum if empty
               printf "%s" "${url:-" "}${sep}${destination:-" "}${sep}\
${branch:-" "}${sep}${tag:-" "}${sep}${marks:-" "}"
               if [ "${OPTION_OUTPUT_FULL}" = "YES" ]
               then
                  printf "%s" "${sep}${nodetype:-" "}${sep}${fetchoptions:-" "}\
${sep}${userinfo:-" "}"
               fi
               if [ "${OPTION_OUTPUT_UUID}" = "YES" ]
               then
                  printf "%s" "${sep}${uuid:-" "}"
               fi
               printf "\n"
            ;;


            *)
               printf "%s" "${url}${sep}${destination}${sep}${branch}${sep}${tag}\
${sep}${marks}"
               if [ "${OPTION_OUTPUT_FULL}" = "YES" ]
               then
                  printf "%s" "${sep}${nodetype}${sep}${fetchoptions}${sep}\
${userinfo}"
               fi
               if [ "${OPTION_OUTPUT_UUID}" = "YES" ]
               then
                  printf "%s" "${sep}${uuid}"
               fi
               printf "\n"
            ;;
         esac
      fi
   done
   IFS="${DEFAULT_IFS}"
}


sourcetree_list_node()
{
   log_entry "sourcetree_list_node" "$@"

   if [ ! -f "${SOURCETREE_CONFIG_FILE}" ]
   then
      log_warning "${SOURCETREE_CONFIG_FILE} doesn't exist"
      return
   fi

   local mode

   if [ "${OPTION_OUTPUT_HEADER}" != "NO" ]
   then
      mode="header"
      if [ "${OPTION_OUTPUT_SEPARATOR}" != "NO" ]
      then
         mode="`concat "${mode}" "separator"`"
      fi
   fi

   case "${OPTION_OUTPUT_FORMAT}" in
      "RAW")
         _sourcetree_list_nodes "${mode}"
      ;;

      "COMMANDLINE")
         _sourcetree_list_nodes "cmdline"
      ;;

      "FORMATTED"|"DEFAULT")
         [ -z "`command -v column`" ] && fail "Tool \"column\" is not available, use --output-raw"

         mode="`concat "${mode}" "column"`"
         _sourcetree_list_nodes "${mode}" | column -t -s '|'
      ;;
   esac
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

         --guess-destination)
            OPTION_GUESS_DESTINATION="YES"
         ;;

         --no-guess-destination)
            OPTION_GUESS_DESTINATION="NO"
         ;;

         #
         #
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
         -b|--branch)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_BRANCH="$1"
         ;;

         -d|--destination|--destination)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_DESTINATION="$1"
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

   local destination
   local url
   local key
   local mark
   local mode

   [ -z "${SOURCETREE_CONFIG_FILE}" ] && fail "config file empty name"

   case "${COMMAND}" in
      add)
         url="${OPTION_URL}"
         if [ -z "${url}" ]
         then
            [ $# -eq 0 ] && log_error "missing url argument" && ${USAGE}
            url="$1"
            shift
         fi

         destination="${OPTION_DESTINATION}"
         if [ -z "${destination}" ]
         then
            # destination is optional
            if [ $# -ne 0 ]
            then
               destination="$1"
               shift
            fi
         fi
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree_add_node "${url}" "${destination}"
      ;;

      get|set|remove)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         url="$1"
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}
         sourcetree_${COMMAND}_node "${url}"
      ;;

      mark)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         url="$1"
         shift
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         mark="$1"
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}
         sourcetree_${COMMAND}_node "${url}" "${mark}"
      ;;

      list)
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree_${COMMAND}_node "${url}" "${mark}"
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
