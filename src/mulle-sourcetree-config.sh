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
   [ $# -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} add [options] <address|url>

   Add a node to the sourcetree. Generally you specify the url for
   external repositories and archives and the address for an existing
   subdirectory.

   Nodes with an url will be fetched and possibly unpacked on the next update.

   Examples:
      ${MULLE_EXECUTABLE_NAME} add ./src
      ${MULLE_EXECUTABLE_NAME} add --url https://x.com/x external/x

   This command only affects the local sourcetree.

Options:
   --branch <value>       : branch to use instead of the default
   --nodetype <value>     : the node type (default: local)
   --fetchoptions <value> : options for mulle-fetch --options
   --if-missing           : a duplicate node is not an error, do nothing
   --marks <value>        : key-value sourcetree marks (e.g. no-build)
   --tag <value>          : tag to checkout
   --url <value>          : url to fetch the node from
   --userinfo <value>     : userinfo for node
EOF
  exit 1
}


sourcetree_remove_usage()
{
   [ $# -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} remove <address>

   Remove a nodes with the given url.

   This command only affects the local sourcetree.
EOF
  exit 1
}


sourcetree_knownmarks_usage()
{
   [ $# -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} knownmarks

   List the marks known by ${MULLE_EXECUTABLE_NAME}.

   Note: You can specify other marks though.
EOF
  exit 1
}


sourcetree_nameguess_usage()
{
   [ $# -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} nameguess <url>

   Guess the project name of the given url.
EOF
  exit 1
}


sourcetree_typeguess_usage()
{
   [ $# -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} typeguess <url>

   Guess the nodetype of the given url.
EOF
  exit 1
}


sourcetree_info_usage()
{
   [ $# -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} info

   Print the current sourcetree and the database configuration, if any.
   To check if the current directory is a sourcetree or sourcetree node:

      ${MULLE_EXECUTABLE_NAME} --no-defer info

EOF
  exit 1
}


sourcetree_mark_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} mark [options] <node> <mark>

   You can mark or unmark a node with this command. Only negative marks
   are actually stored in the node. All positive marks are implicit.

   Examine the nodes marks with
       \`${MULLE_EXECUTABLE_NAME} -N list\`.

   This command only affects the local sourcetree.

Options:
   --extended-mark : allow the use of non-predefined marks

Marks:
   [no-]build     : the node contains a buildable project (used by buildorder)
   [no-]delete    : the node may be deleted or moved
   [no-]recurse   : the node takes part in recursive operations
   [no-]require   : the node must exist
   [no-]set       : the nodes properies can be changed
   [no-]share     : the node may be shared with subtree nodes of the same url
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

   Example:
      ${MULLE_EXECUTABLE_NAME} mark src/bar no-build
EOF

  exit 1
}


sourcetree_unmark_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} unmark [options] <node> <mark>

   Remove a negative mark from a node. A node stores only marks,
   prefixed by either "no-" or "only-". All positive marks are implicit set.

   This command only affects the local sourcetree.

Options:
   --extended-mark : allow the use of non-predefined marks

Marks:
   no-build
   no-delete
   no-recurse
   no-require
   no-set
   no-share
   no-update

   Example:
      ${MULLE_EXECUTABLE_NAME} unmark src/bar no-build
EOF

  exit 1
}


sourcetree_move_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} move <address> <top|bottom|up|down>

   Change the position of a node with a certain address in the sourcetree.
   This changes the buildorder, which may be very important.

EOF
  exit 1
}


sourcetree_set_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} set [options] <address> [key [value]]*

   Change any value of a node with the set command. Changes are applied
   with the next update. You can can specify values with the options or
   parameter key value pairs, which have precedence.

   This command only affects the local sourcetree.

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
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} get <address> [key]

   Prints the node values for a node with the given key.

Keys:
   address      :
   branch       :
   fetchoptions :
   marks        :
   nodetype     :
   tag          :
   uuid         :
   url          :
   userinfo     :

   This command only affects the local sourcetree.
EOF
  exit 1
}


#
# returns
#
#   _nodetype
#
_sourcetree_typeguess_node()
{
   log_entry "_sourcetree_typeguess_node" "$@"

   local input="$1"
   local nodetype="$2"
   local url="$3"

   _nodetype="${nodetype}"

   local guesssource

   guesssource="${input}"

   #
   # try to figure out _nodetype. At this point adress is empty
   #
   if [ -z "${_nodetype}" -a ! -z "${url}" ]
   then
      _nodetype="`node_guess_nodetype "${url}"`"
      guesssource="${url}"
   fi

   if [ -z "${_nodetype}" -a ! -z "${input}" ]
   then
      _nodetype="`node_guess_nodetype "${input}"`"
   fi

   if [ -z "${_nodetype}" ]
   then
      case "${input}" in
         *:*|~*|/*)
            fail "Please specify --nodetype"
         ;;

         ../*)
            _nodetype="symlink"
         ;;

         *)
            if [ ! -z "${url}" ]
            then
               fail "Please specify --nodetype"
            fi
            _nodetype="local"
         ;;
      esac
   fi

   log_fluff "Guessed nodetype \"${_nodetype}\" from \"${guesssource}\""
}


#
# returns
#
#   _nodetype
#   _address
#   _url
#
_sourcetree_nameguess_node()
{
   log_entry "_sourcetree_nameguess_node" "$@"

   local input="$1"
   local nodetype="$2"
   local url="$3"

   _sourcetree_typeguess_node "${input}" "${nodetype}" "${url}"

   _url="${url}"

   #
   # try to figure out if input is an _url
   # trivially, it is the _address if _url is empty and _address is set
   #
   if [ ! -z "${_url}" ]
   then
      log_fluff "Guessed URL \"${_url}\" from \"${url}\""
      return
   fi

   if [ ! -z "${_address}" ]
   then
      _url="${input}"
      log_fluff "Guessed URL \"${_url}\" from \"${input}\""
      return
   fi

   case "${input}" in
      *:*)
         _url="${input}"
         log_fluff "Guessed URL \"${_url}\" from \"${input}\""
         _address="`node_guess_address "${_url}" "${_nodetype}"`"
         log_fluff "Guessed address \"${_address}\" from \"${_url}\""
      ;;

      /*|~*)
         case "${_nodetype}" in
            local)
               _address="`symlink_relpath "${input}" "${PWD}"`"
               log_fluff "Guessed Address \"${_address}\" from \"${_nodetype}\" and \"${input}\""
            ;;

            *)
               _url="${input}"
               log_fluff "Guessed URL \"${_url}\" from \"${input}\""
               _address="`node_guess_address "${_url}" "${_nodetype}"`"
               log_fluff "Guessed address \"${_address}\" from \"${_url}\""
            ;;
         esac
      ;;

      *)
         _url="${input}"
         log_fluff "Guessed URL \"${_url}\" from \"${input}\""
         _address="${input%/*}"
         _address="`extensionless_basename "${_address}"`"
         log_fluff "Guessed address \"${_address}\" from \"${input}\""
      ;;
   esac
}


sourcetree_nameguess_node()
{
   log_entry "sourcetree_nameguess_node" "$@"

   local input="$1"

   local _address
   local _url
   local _nodetype

   _sourcetree_nameguess_node "${input}" "${OPTION_NODETYPE}" "${OPTION_URL}"

   echo "${_address}"
}


sourcetree_typeguess_node()
{
   log_entry "sourcetree_typeguess_node" "$@"

   local input="$1"

   local _address
   local _url
   local _nodetype

   _sourcetree_typeguess_node "${input}" "${OPTION_NODETYPE}" "${OPTION_URL}"

   echo "${_nodetype}"
}


_assert_sane_mark()
{
   log_entry "_assert_sane_mark" "$@"

   local mark="$1"

   case "${mark}" in
      "")
         fail "mark is empty"
      ;;

      *[^a-z-]*)
         fail "mark \"${mark}\" may only contain lowercase letters and hyphens"
      ;;

      no-*|only-*)
      ;;

      *)
         fail "mark \"${mark}\" must start with \"no-\" or \"only-\""
      ;;
   esac
}


_sanitized_marks()
{
   log_entry "_sanitized_marks" "$@"

   local marks="$1"

   local mark
   local result

   IFS=","; set -o noglob
   for mark in ${marks}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob
      case "${mark}" in
         "")
            continue
         ;;

         *[^a-z-]*)
            fail "mark \"${mark}\" may only contain lowercase letters and hyphens"
         ;;

         no-*|only-*)
            result="`comma_concat "${result}" "${mark}"`"
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   echo "${result}"
}


#
#
#
sourcetree_add_node()
{
   log_entry "sourcetree_add_node" "$@"

   local input="$1"

   # input could be url or address

   local _address="${OPTION_ADDRESS}"
   local _url="${OPTION_URL}"

   if [ ! -z "${OPTION_ADDRESS}" -a ! -z "${OPTION_URL}" ]
   then
      fail "Specifying --address and --url together conflicts with the main argument"
   fi

   local _nodetype

   _sourcetree_nameguess_node "${input}" "${OPTION_NODETYPE}" "${OPTION_URL}"

   local _branch="${OPTION_BRANCH}"
   local _fetchoptions="${OPTION_FETCHOPTIONS}"
   local _marks="${OPTION_MARKS}"
   local _tag="${OPTION_TAG}"
   local _userinfo="${OPTION_USERINFO}"
   local _uuid

   if [ -z "${_address}" ]
   then
      _address="${input}"
   fi

   _marks="`_sanitized_marks "${_marks}"`" || exit 1

   if [ -z "${_url}" ]
   then
      if ! [ -e "${_address}" ]
      then
         case ",${_marks}," in
            *,no-fs,*)
            ;;

            *)
               log_warning "There is no directory or file named \"${_address}\""
            ;;
         esac
      fi
   else
      if [ -e "${_address}" ]
      then
         log_warning "A directory or file named \"${_address}\" already exists"
      fi
   fi

   #
   # now just some sanity checks and save it
   #
   local mode

   if [ "${OPTION_UNSAFE}" = "YES" ]
   then
      mode="`comma_concat "${mode}" "unsafe"`"
   fi
   node_augment "${mode}"

   if cfg_get_nodeline "${SOURCETREE_START}" "${_address}" > /dev/null
   then
      if [ "${OPTION_IF_MISSING}" = "YES" ]
      then
         return 0
      fi
      fail "There is already a node ${C_RESET_BOLD}${_address}${C_ERROR_TEXT} \
in the sourcetree"
   fi

   local contents
   local nodeline
   local appended

   contents="`egrep -s -v '^#' "${SOURCETREE_CONFIG_FILE}"`"
   nodeline="`node_to_nodeline`"
   appended="`add_line "${contents}" "${nodeline}"`"

   cfg_write "${SOURCETREE_START}" "${appended}"
   cfg_touch_parents "${SOURCETREE_START}"

   log_info "Added ${C_MAGENTA}${C_BOLD}${_address}"
}


# get mit sed vermutlich einfacher
line_mover()
{
   log_entry "line_mover" "$@"

   local nodeline="$1"
   local direction="$2"

   case "${direction}" in
      top)
         echo "${nodeline}"
      ;;
      bottom|up|down)
      ;;

      *)
         sourcetree_move_usage "Unknown direction \"${direction}\""
      ;;
   esac

   local line
   local prev

   IFS="
"
   while read line
   do
      case "${direction}" in
         top|bottom)
            if [ "${line}" != "${nodeline}" ]
            then
               echo "${line}"
            fi
         ;;

         up)
            if [ "${line}" = "${nodeline}" ]
            then
               echo "${line}"
               if [ ! -z "${prev}" ]
               then
                  echo "${prev}"
                  prev=
               fi
               continue
            fi

            if [ ! -z "${prev}" ]
            then
               echo "${prev}"
            fi
            prev="${line}"
         ;;

         down)
            if [ "${line}" != "${nodeline}" ]
            then
               echo "${line}"
               if [ ! -z "${prev}" ]
               then
                  echo "${prev}"
                  prev=
               fi
            else
               prev="${nodeline}"
            fi
         ;;

      esac
   done

   case "${direction}" in
      up|down)
         if [ ! -z "${prev}" ]
         then
            echo "${prev}"
         fi
      ;;

      bottom)
         echo "${nodeline}"
      ;;
   esac
}


#
#
#
sourcetree_move_node()
{
   log_entry "sourcetree_add_node" "$@"

   local input="$1"
   local direction="$2"

   local _address
   local _url
   local _nodetype

   _sourcetree_nameguess_node "${input}" "${OPTION_NODETYPE}" "${OPTION_URL}"

   if [ -z "${_address}" ]
   then
      _address="${input}"
   fi

   local nodeline

   if ! nodeline="`cfg_get_nodeline "${SOURCETREE_START}" "${_address}"`"
   then
      fail "No node \"${_address}\" found"
   fi

   if ! moved="`line_mover "${nodeline}" "${direction}" < <( cfg_read "${SOURCETREE_START}" )`"
   then
      exit 1
   fi

   cfg_write "${SOURCETREE_START}" "${moved}"
   cfg_touch_parents "${SOURCETREE_START}"
}


sourcetree_remove_node()
{
   log_entry "sourcetree_remove_node" "$@"

   local address="$1"

   local oldnodeline

   if ! cfg_get_nodeline "${SOURCETREE_START}" "${address}" > /dev/null
   then
      log_warning "A node \"${address}\" does not exist"
      return 2  # also return non 0 , but lets's not be dramatic about it
   fi

   cfg_remove_nodeline "${SOURCETREE_START}" "${address}"
   cfg_file_remove_if_empty "${SOURCETREE_START}"
   cfg_touch_parents "${SOURCETREE_START}"
}


sourcetree_remove_node_by_url()
{
   log_entry "sourcetree_remove_node_by_url" "$@"

   local url="$1"

   [ -z "${url}" ] && fail "url is empty"

   url="`_matching_nodeline_url "${url}"`"

   local oldnodeline

   if [ ! -z "${url}" ]
   then
      log_warning "A node with URL \"${url}\" does not exist"
      return 2  # also return non 0 , but lets's not be dramatic about it
   fi

   cfg_remove_nodeline_by_url "${SOURCETREE_START}" "${url}"
   cfg_file_remove_if_empty "${SOURCETREE_START}"
   cfg_touch_parents "${SOURCETREE_START}"
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

   cfg_change_nodeline "${SOURCETREE_START}" "${oldnodeline}" "${newnodeline}"
   cfg_touch_parents "${SOURCETREE_START}"

   local verifynodelines
   local verifynodeline

   verifynodelines="`cfg_read "${SOURCETREE_START}"`"
   verifynodeline="`nodeline_find "${verifynodelines}" "${address}"`"

   if [ "${verifynodeline}" != "${newnodeline}" ]
   then
      fail "Verify of config file failed."
   fi
}


_unfailing_get_nodeline()
{
   local address="$1"

   if ! cfg_get_nodeline "${SOURCETREE_START}" "${address}"
   then
      fail "A node \"${address}\" does not exist (${MULLE_VIRTUAL_ROOT}${SOURCETREE_START})"
   fi
}


_matching_nodeline_url()
{
   local url="$1"

   [ -z "${url}" ] && fail "url is empty"

   if cfg_get_nodeline_by_url "${SOURCETREE_START}" "${url}" > /dev/null
   then
      echo "${url}"
      return 0
   fi

   if nodeline="`cfg_get_nodeline_by_evaled_url "${SOURCETREE_START}" "${url}"`"
   then
      nodeline_get_url "${nodeline}"
      return 0
   fi

   return 1
}


_unfailing_get_nodeline_by_url()
{
   local url="$1"

   if ! cfg_get_nodeline_by_url "${SOURCETREE_START}" "${url}"
   then
      fail "A node \"${url}\" does not exist (${MULLE_VIRTUAL_ROOT}${SOURCETREE_START})"
   fi
}


#
# we need to keep the position in the file as it is important
# so add/remove is not the solution
#
_sourcetree_set_node()
{
   log_entry "_sourcetree_set_node" "$@"

   local oldnodeline="$1"; shift

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _tag
   local _url
   local _uuid
   local _userinfo

   nodeline_parse "${oldnodeline}"

   if ! nodemarks_contain "${_marks}" "set"
   then
      fail "Node is marked as no-set"
   fi

   local oldaddress

   oldaddress="${address}"

   _branch="${OPTION_BRANCH:-${_branch}}"
   _address="${OPTION_ADDRESS:-${_address}}"
   _fetchoptions="${OPTION_FETCHOPTIONS:-${_fetchoptions}}"
   _marks="${OPTION_MARKS:-${_marks}}"
   _nodetype="${OPTION_NODETYPE:-${_nodetype}}"
   _url="${OPTION_URL:-${_url}}"
   _tag="${OPTION_TAG:-${_tag}}"
   _userinfo="${OPTION_USERINFO:-${_userinfo}}"

   _marks="`_sanitized_marks "${_marks}"`" || exit 1

   local key
   local value

   while [ "$#" -ge 2 ]
   do
      key="$1"
      shift
      value="$1"
      shift

      case "${key}" in
         branch|address|fetchoptions|marks|nodetype|tag|url|userinfo)
            eval "_${key}"="'${value}'"
            log_debug "Set ${key} to \"`eval echo \\\$_${key}`\""
         ;;

         *)
            log_error "unknown keyword \"$1\""
            sourcetree_set_usage
         ;;
      esac
   done

   if [ "$#" -ne 0 ]
   then
      log_error "Key \"$1\" without value"
      sourcetree_set_usage
   fi

   node_augment "${OPTION_AUGMENTMODE}"

   if [ "${oldaddress}" != "${_address}" ] &&
      cfg_has_duplicate "${SOURCETREE_START}" "${_uuid}" "${_address}"
   then
      fail "There is already a node ${C_RESET_BOLD}${_address}${C_ERROR_TEXT} \
in the sourcetree
"
   fi

   local newnodeline

   newnodeline="`node_to_nodeline`"
   sourcetree_change_nodeline "${oldnodeline}" "${newnodeline}" "${_address}"
}


sourcetree_set_node()
{
   log_entry "sourcetree_set_node" "$@"

   local address="$1"; shift

   local oldnodeline

   oldnodeline="`_unfailing_get_nodeline "${address}"`" || exit 1

   _sourcetree_set_node "${oldnodeline}" "$@"
}


sourcetree_set_node_by_url()
{
   log_entry "sourcetree_set_node_by_url" "$@"

   local url

   url="`_matching_nodeline_url "$1"`"
   url="${url:-$1}"

   shift

   local oldnodeline

   oldnodeline="`_unfailing_get_nodeline_by_url "${url}"`" || exit 1

   _sourcetree_set_node "${oldnodeline}" "$@"
}


_sourcetree_get_node()
{
   log_entry "_sourcetree_get_node" "$@"

   local nodeline="$1"; shift

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _uuid
   local _userinfo

   nodeline_parse "${nodeline}"

   if [ "$#" -eq 0 ]
   then
      exekutor echo "${_address}"
      return
   fi

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         branch|address|fetchoptions|marks|nodetype|tag|url|uuid|userinfo)
            exekutor eval echo \$"_${1}"
         ;;
         *)
            log_error "unknown keyword \"$1\""
            sourcetree_get_usage
         ;;
      esac
      shift
   done
}


sourcetree_get_node()
{
   log_entry "sourcetree_get_node" "$@"

   local address="$1"; shift

   local nodeline

   if ! nodeline="`cfg_get_nodeline "${SOURCETREE_START}" "${address}"`"
   then
      log_warning "Node \"${address}\" does not exist"
      return 1
   fi

   _sourcetree_get_node "${nodeline}" "$@"
}


sourcetree_get_node_by_url()
{
   log_entry "sourcetree_get_node_by_url" "$@"

   local url

   url="`_matching_nodeline_url "$1"`"
   url="${url:-$1}"

   shift

   local nodeline

   if ! nodeline="`cfg_get_nodeline "${SOURCETREE_START}" "${url}"`"
   then
      log_warning "Node with URL \"${1}\" does not exist"
      return 1
   fi

   _sourcetree_get_node "${nodeline}" "$@"
}

KNOWN_MARKS="\
no-all-load
no-build
no-defer
no-delete
no-fs
no-header
no-include
no-import
no-link
no-os-mingw
no-os-darwin
no-os-freebsd
no-os-linux
no-public
no-recurse
no-require
no-set
no-share
no-update"


_sourcetree_add_mark_known_absent()
{
   log_entry "_sourcetree_add_mark_known_absent" "$@"

   local mark="$1"

   _assert_sane_mark "${mark}"

   if [ "${OPTION_EXTENDED_MARK}" != "YES" ]
   then
      if ! fgrep -x -q "${mark}" <<< "${KNOWN_MARKS}"
      then
         fail "mark \"${mark}\" is unknown. If this is not a type use --extended-mark"
      fi
   fi

   _marks="`nodemarks_add "${_marks}" "${mark}" `"
   _marks="`nodemarks_sort "${_marks}"`"

   local newnodeline

   newnodeline="`node_to_nodeline`"
   sourcetree_change_nodeline "${oldnodeline}" "${newnodeline}" "${_address}"
}


_sourcetree_remove_mark_known_present()
{
   log_entry "_sourcetree_remove_mark_known_present" "$@"

   local mark="$1"

   local operation

   _assert_sane_mark "${mark}"

   if [ "${OPTION_EXTENDED_MARK}" != "YES" ]
   then
      if ! fgrep -x -q "${mark}" <<< "${KNOWN_MARKS}"
      then
         fail "mark \"${mark}\" is unknown. If this is not a typo use --extended-mark"
      fi
   fi

   _marks="`nodemarks_remove "${_marks}" "${mark}" `"
   _marks="`nodemarks_sort "${_marks}"`"

   local newnodeline

   newnodeline="`node_to_nodeline`"
   sourcetree_change_nodeline "${oldnodeline}" "${newnodeline}" "${_address}"
}


_sourcetree_mark_node()
{
   log_entry "_sourcetree_mark_node" "$@"

   local oldnodeline="$1"
   local mark="$2"

   [ -z "${mark}" ] && fail "mark is empty"

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   nodeline_parse "${oldnodeline}"

   case "${mark}" in
      no-*|only-*)
         if nodemarks_contain "${_marks}" "${mark}"
         then
            log_info "Node is already marked as \"${mark}\"."
            return
         fi
         _sourcetree_add_mark_known_absent "${mark}"
      ;;

      *)
         if nodemarks_contain "${_marks}" "no-${mark}"
         then
            mark="no-${mark}"
            _sourcetree_remove_mark_known_present "${mark}"
         fi

         if nodemarks_contain "${_marks}" "only-${mark}"
         then
            mark="only-${mark}"
            _sourcetree_remove_mark_known_present "${mark}"
         fi
      ;;
   esac
}


sourcetree_mark_node()
{
   log_entry "sourcetree_mark_node" "$@"

   local address="$1"; shift

   [ -z "${address}" ] && fail "address is empty"

   local oldnodeline

   oldnodeline="`_unfailing_get_nodeline "${address}"`" || exit 1

   _sourcetree_mark_node "${oldnodeline}" "$@"
}


sourcetree_mark_node_by_url()
{
   log_entry "sourcetree_mark_node_by_url" "$@"

   local url

   url="`_matching_nodeline_url "$1"`"
   url="${url:-$1}"

   shift

   local oldnodeline

   oldnodeline="`_unfailing_get_nodeline_by_url "${url}"`" || exit 1

   _sourcetree_mark_node "${oldnodeline}" "$@"
}


sourcetree_unmark_node()
{
   log_entry "sourcetree_unmark_node" "$@"

   local address="$1"
   local mark="$2"

   [ -z "${address}" ] && fail "address is empty"
   [ -z "${mark}" ] && fail "mark is empty"

   case "${mark}" in
      no-*)
         mark="${mark:3}"
      ;;

      only-*)
         mark="${mark:5}"
      ;;

      *)
         fail "Mark to unmark must start with \"no-\" or \"only-\""
      ;;
   esac

   sourcetree_mark_node "${address}" "${mark}"
}


sourcetree_unmark_node_by_url()
{
   log_entry "sourcetree_unmark_node_by_url" "$@"

   local url="$1"
   local mark="$2"

   [ -z "${mark}" ] && fail "mark is empty"

   url="`_matching_nodeline_url "${url}"`"
   url="${url:-$1}"

   case "${mark}" in
      no-*)
         mark="${mark:2}"
      ;;

      only-*)
         mark="${mark:5}"
      ;;

      *)
         fail "Mark to unmark must start with \"no-\" or \"only-\""
      ;;
   esac

   sourcetree_mark_node_by_url "${url}" "${mark}"
}


sourcetree_info_node()
{
   log_entry "sourcetree_info_node" "$@"

   [ -z "${MULLE_EXECUTABLE_PWD}" ] && internal_fail "MULLE_EXECUTABLE_PWD is empty"

   local database="${1:-/}"

   local dbstate

   dbstate="`db_state_description "${database}" `"

   printf "%b\n" "${C_INFO}--------------------------------------------------${C_RESET}"
   printf "%b\n" "${C_INFO}Sourcetree: ${C_RESET_BOLD}${PWD}${C_RESET}"
   printf "%b\n" "${C_INFO}Database: ${C_MAGENTA}${C_BOLD}${dbstate}${C_RESET}"

   if [ ! -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      printf "%b\n" "${C_INFO}Virtual Root: ${C_MAGENTA}${C_BOLD}${MULLE_VIRTUAL_ROOT}${C_RESET}"
   fi

   case "${SOURCETREE_MODE}" in
      share)
         if [ ! -z "${MULLE_SOURCETREE_SHARE_DIR}" ]
         then
            printf "%b\n" "${C_INFO}Shared directory: \
${C_RESET_BOLD}${MULLE_SOURCETREE_SHARE_DIR}${C_RESET}"
         fi
      ;;
   esac

   printf "%b\n" "${C_INFO}--------------------------------------------------${C_RESET}"
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
   local OPTION_EXTENDED_MARK="DEFAULT"
   local OPTION_OUTPUT_BANNER="DEFAULT"
   local OPTION_GUESS_DSTFILE="DEFAULT_IFS"
   local OPTION_UNSAFE="NO"
   local OPTION_OUTPUT_UUID="DEFAULT"
   local OPTION_OUTPUT_EVAL="NO"
   local OPTION_OUTPUT_FULL="NO"
   local OPTION_IF_MISSING="NO"

   local suffix

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
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

         --no-output-color|--output-no-color)
            OPTION_OUTPUT_COLOR="NO"
         ;;

         --output-header)
            OPTION_OUTPUT_HEADER="YES"
         ;;

         --no-output-header|--output-no-header)
            OPTION_OUTPUT_HEADER="NO"
         ;;

         --output-separator)
            OPTION_OUTPUT_SEPARATOR="YES"
         ;;

         --no-output-separator|--output-no-separator)
            OPTION_OUTPUT_SEPARATOR="NO"
         ;;

         #
         # just for add
         #
         --if-missing)
            OPTION_IF_MISSING="YES"
         ;;

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
         -e|--extended-mark)
            OPTION_EXTENDED_MARK="YES"
         ;;

         --no-extended-mark)
            OPTION_EXTENDED_MARK="NO"
         ;;

         #
         #
         #
         --output-full)
            OPTION_OUTPUT_FULL="YES"
         ;;

         --no-output-full|--output-no-full)
            OPTION_OUTPUT_FULL="NO"
         ;;

         --output-uuid)
            OPTION_OUTPUT_UUID="YES"
         ;;

         --no-output-uuid|--output-no-uuid)
            OPTION_OUTPUT_UUID="NO"
         ;;

         --output-banner)
            OPTION_OUTPUT_BANNER="YES"
         ;;

         --no-output-banner|--output-no-banner)
            OPTION_OUTPUT_BANNER="NO"
         ;;

         --output-eval)
            OPTION_OUTPUT_EVAL="YES"
         ;;

         --no-output-eval|--output-no-eval)
            OPTION_OUTPUT_EVAL="NO"
         ;;

         #
         # more common flags
         #
         --url-addressing)
            suffix="_by_url"
         ;;

         -a|--address)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_ADDRESS="$1"
         ;;

         -b|--branch)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_BRANCH="$1"
         ;;

         -f|--fetchoptions)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_FETCHOPTIONS="$1"
         ;;

         -m|--marks)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_MARKS="$1"
         ;;

         -n|--nodetype|-s|--scm)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_NODETYPE="$1"
         ;;

         -t|--tag)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_TAG="$1"
         ;;

         -u|--url)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_URL="$1"
         ;;

         -U|--userinfo)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
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
   local direction

   #
   # make simple commands flat by default, except if the user wants it
   #
   if [ -z "${FLAG_SOURCETREE_MODE}" ]
   then
      SOURCETREE_MODE="flat"
   fi

   [ -z "${SOURCETREE_CONFIG_FILE}" ] && fail "config file empty name"

   case "${COMMAND}" in
      add|nameguess|typeguess)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         argument="$1"
         [ -z "${argument}" ] && log_error "empty argument" && ${USAGE}
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree_${COMMAND}_node "${argument}"
      ;;

      move)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         address="$1"
         [ -z "${address}" ] && log_error "empty address" && ${USAGE}
         shift
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         direction="$1"
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree_${COMMAND}_node "${address}" "${direction}"
      ;;

      remove)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         address="$1"
         [ -z "${address}" ] && log_error "empty argument" && ${USAGE}
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}
         sourcetree_${COMMAND}_node${suffix} "${address}"
      ;;

      get|set)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         address="$1"
         [ -z "${address}" ] && log_error "empty argument" && ${USAGE}
         shift
         sourcetree_${COMMAND}_node${suffix} "${address}" "$@"
      ;;

      knownmarks)
         echo "${KNOWN_MARKS}"
      ;;

      mark|unmark)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         address="$1"
         [ -z "${address}" ] && log_error "empty argument" && ${USAGE}
         shift
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         mark="$1"
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree_${COMMAND}_node${suffix} "${address}" "${mark}"
      ;;

      info)
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

sourcetree_knownmarks_main()
{
   log_entry "sourcetree_knownmarks_main" "$@"

   USAGE="sourcetree_knownmarks_usage"
   COMMAND="knownmarks"
   sourcetree_common_main "$@"
}

sourcetree_mark_main()
{
   log_entry "sourcetree_mark_main" "$@"

   USAGE="sourcetree_mark_usage"
   COMMAND="mark"
   sourcetree_common_main "$@"
}

sourcetree_move_main()
{
   log_entry "sourcetree_move_main" "$@"

   USAGE="sourcetree_move_usage"
   COMMAND="move"
   sourcetree_common_main "$@"
}


sourcetree_nameguess_main()
{
   log_entry "sourcetree_nameguess_main" "$@"

   USAGE="sourcetree_nameguess_usage"
   COMMAND="nameguess"
   sourcetree_common_main "$@"
}


sourcetree_typeguess_main()
{
   log_entry "sourcetree_typeguess_main" "$@"

   USAGE="sourcetree_typeguess_usage"
   COMMAND="typeguess"
   sourcetree_common_main "$@"
}


sourcetree_unmark_main()
{
   log_entry "sourcetree_unmark_main" "$@"

   USAGE="sourcetree_unmark_usage"
   COMMAND="unmark"
   sourcetree_common_main "$@"
}


sourcetree_info_main()
{
   log_entry "sourcetree_info_main" "$@"

   USAGE="sourcetree_info_usage"
   COMMAND="info"
   sourcetree_common_main "$@"
}


#
# the general idea here was to use mulle-sourcetree as a library too
#
sourcetree_commands_initialize()
{
   log_entry "sourcetree_commands_initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi
   if [ -z "${MULLE_PATH_SH}" ]
   then
      # shellcheck source=mulle-path.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"      || return 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      # shellcheck source=mulle-file.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"      || return 1
   fi

   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
   # shellcheck source=mulle-sourcetree-db.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh"
   fi
   if [ -z "${MULLE_SOURCETREE_NODEMARKS_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodemarks.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodemarks.sh"|| exit 1
   fi
   if [ -z "${MULLE_SOURCETREE_NODE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-node.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-node.sh" || exit 1
   fi
   if [ -z "${MULLE_SOURCETREE_NODELINE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodeline.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodeline.sh" || exit 1
   fi
   if [ -z "${MULLE_SOURCETREE_CFG_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-cfg.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-cfg.sh" || exit 1
   fi
}


sourcetree_commands_initialize

:
