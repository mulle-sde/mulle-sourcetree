# shellcheck shell=bash
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
MULLE_SOURCETREE_COMMANDS_SH='included'


#
# All commands in here are not recursive!
#

SOURCETREE_COMMON_OPTIONS="\
--branch <value>       : branch to use instead of the default for git
--address <dir>        : address of the node in the project
--fetchoptions <value> : options for mulle-fetch --options
--marks <value>        : sourcetree marks of the node like no-require
--tag <value>          : tag to checkout for git
--nodetype <value>     : the node type
--url <url>            : url of the node
--userinfo <value>     : userinfo for node"

# MEMO: must be spaced like this for mulle-sde dependency!
SOURCETREE_COMMON_KEYS="\
branch            : branch to use instead of the default for git
address           : address of the node in the project
fetchoptions      : options for mulle-fetch --options
marks             : sourcetree marks of the node like no-require
tag               : tag to checkout for git
nodetype          : the node type
url               : url of the node
userinfo          : userinfo for node"


sourcetree::commands::print_common_keys()
{
   printf "%s\n" "${SOURCETREE_COMMON_KEYS}" | sed "s|^|$*|" | sort
}


sourcetree::commands::print_common_options()
{
   printf "%s\n" "${SOURCETREE_COMMON_OPTIONS}" | sed "s|^|$*|" | sort
}


sourcetree::commands::add_usage()
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
      ${MULLE_EXECUTABLE_NAME} add foo
      ${MULLE_EXECUTABLE_NAME} add --url https://x.com/x external/x
      ${MULLE_EXECUTABLE_NAME} add --nodetype comment "Was denn hier los ?"

   (This command only affects the local sourcetree.)

Options:
EOF
   (
      printf "%s\n" "${SOURCETREE_COMMON_OPTIONS}"
      echo "--if-missing           : only add, if a node with same adddress is not present"
   )  | sed "s|^|   |" | sort
   echo >&2
   exit 1
}


sourcetree::commands::copy_usage()
{
   [ $# -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} copy <field> <dst> [config [src]]

   Copy a node or parts of a node from another node. The copy command is
   special in that it allows you to copy from another sourcetree.

   "field" is one of the fields name (see below) or "ALL" to copy the whole
   node.

   "dst" is the node in the current sourcetree you want to copy too, it
   must already exist, if you are copying a field. If you are using "ALL" then
   it need not exist already.

   "config" is the complete path to the config file of another project. If
   you want to copy from the current sourcetree use ".". If left empty, then
   "." is used.

   "src" is the node in the sourcetree specified by "config". It must exist.
   If left empty then "dst" is used as "src", unless "config" is ".".

Examples:
   Copy marks from "b" of config in project "x" to "a" of the current project:

   ${MULLE_EXECUTABLE_NAME} copy marks a b marks ~/x/.mulle/etc/sourcetree/config

   Copy all fields of node "EOAccess" of same config into "EOControl":

   ${MULLE_EXECUTABLE_NAME} copy ALL EOControl . EOAccess

   (This command only affects the local sourcetree.)

Fields:
EOF
   sourcetree::commands::print_common_keys  "   " >&2
   exit 1
}


sourcetree::commands::duplicate_usage()
{
   [ $# -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} duplicate [options] <address>

   Duplicate a node in the sourcetree. The new node will have a #1 appended to
   it, if it's the first duplicate. Otherwise #2, #3 and so on. Its assumed
   this node is intended to reference the same URL so it marked as 'no-fs'
   to avoid duplicate fetches.

Example:
   ${MULLE_EXECUTABLE_NAME} duplicate foo

   (This command only affects the local sourcetree.)

Options:
EOF
   sourcetree::commands::print_common_options "   " >&2
   echo >&2
   exit 1
}


sourcetree::commands::remove_usage()
{
   [ $# -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} remove [options] <address|url> 

   Remove a nodes with the given url or address. You can specify
   multiple nodes to remove.

   (This command only affects the local sourcetree.)

Example:
   ${MULLE_EXECUTABLE_NAME} remove --if-present foo other-foo

Options:
   --if-present : don't complain if address is missing

EOF
  exit 1
}


sourcetree::commands::knownmarks_usage()
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


sourcetree::commands::info_usage()
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


sourcetree::commands::mark_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} mark [options] <node> <mark>

   You can mark or unmark a node with this command. Only negative marks
   are actually stored in the node. All positive marks are implicit.
   Marks are free-format, but there exist a number of predefined ones.

   Examine the nodes marks with
       \`${MULLE_EXECUTABLE_NAME} -N list\`.

   (This command only affects the local sourcetree.)

Options:
   --match         : use regular expression to find address to match
   --extended-mark : allow the use of non-predefined marks

Marks:
   Some commonly used marks:

   [no-]build     : the node contains a buildable project (used by craftorder)
   [no-]delete    : the node may be deleted or moved
   [no-]descend   : the nodes sourcetree takes part in recursive operations
   [no-]header    : the node produces one or more includable headers
   [no-]link      : the node produces a linkable library
   [no-]require   : the node must exist
   [no-]set       : the nodes properies can be changed
   [no-]share     : the node may be shared with subtree nodes of the same url
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      cat <<EOF >&2
                   the effect is, that an URL is only fetched once and stored
                   in the main sourcetree, not the subtree.
EOF
   fi

   cat <<EOF >&2
   [no-]update    : the node takes part in the update

   Example:
      ${MULLE_EXECUTABLE_NAME} mark src/bar no-build
EOF

  exit 1
}


sourcetree::commands::rename_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} rename <nodename> <newnodename>

   Rename a node

   Example:
      ${MULLE_EXECUTABLE_NAME} rename foo bar
EOF

  exit 1
}


sourcetree::commands::rename_marks_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} mark-rename [options] <node> <oldmark> <newmark>

   Rename a mark. Marks with leading "only-" and "no-" will be affected but
   no others.

   (This command only affects the local sourcetree.)

Options:
   --match         : use regular expression to find address to match
   --extended-mark : allow the use of non-predefined marks

   Example:
      ${MULLE_EXECUTABLE_NAME} mark-rename src/bar buildx build
EOF

  exit 1
}


sourcetree::commands::unmark_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} unmark [options] <node> <mark>

   Remove a negative mark from a node. A node stores only marks,
   prefixed by either "no-" or "only-". All positive marks are implicit set.

   (This command only affects the local sourcetree.)

Options:
   --match         : use regular expression to find address to match
   --extended-mark : allow the use of non-predefined marks

Marks:
   no-build
   no-delete
   no-descend
   no-require
   no-set
   no-share
   no-update

   Example:
      ${MULLE_EXECUTABLE_NAME} unmark src/bar no-build
EOF

  exit 1
}


sourcetree::commands::move_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} move <address> <top|bottom|up|down>

   Change the position of a node with a certain address in the sourcetree.
   This changes the craftorder, which may be very important.

EOF
  exit 1
}


sourcetree::commands::set_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} set <address> [key [value]]*

   Change any value of a node referenced by <address> with the set command.
   Changes are applied with the next sync.
   (This command only affects the local sourcetree.)

Keys:
EOF
  sourcetree::commands::print_common_keys "   " >&2
  echo >&2

  exit 1
}


sourcetree::commands::get_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} get <address> [key]

   Prints the node values for a node with the given key.

Keys:
   address      : the address of the node
   branch       : the (git) branch of the node
   fetchoptions : options passed to mulle-fetcg
   marks        : marks of the node
   nodetype     : type of the node
   tag          : the (git) tag of the node
   uuid         : the uuid of the node
   url          : the url of the node
   userinfo     : the userinfo of the node

   (This command only affects the local sourcetree.)
EOF
  exit 1
}


#
# returns
#
#  nodetype
#
sourcetree::commands::r_typeguess_node()
{
   log_entry "sourcetree::commands::r_typeguess_node" "$@"

   local input="$1"
   local nodetype="$2"
   local url="$3"

   RVAL="${nodetype}"

   local guesssource

   guesssource="${input}"

   #
   # try to figure out nodetype
   #
   if [ -z "${nodetype}" -a ! -z "${url}" ]
   then
      sourcetree::fetch::r_guess_nodetype "${url}"
      nodetype="${RVAL}"
      guesssource="${url}"
   fi

   if [ -z "${nodetype}" -a ! -z "${input}" ]
   then
      sourcetree::fetch::r_guess_nodetype "${input}"
      nodetype="${RVAL}"
   fi

   if [ -z "${nodetype}" ]
   then
      case "${input}" in
         *:*|~*|/*)
            fail "Please specify --nodetype"
         ;;

         ../*)
            nodetype="symlink"
         ;;

         *)
            if [ ! -z "${url}" ]
            then
               fail "Please specify --nodetype"
            else
               if [ -e "${url}" ]
               then
                  nodetype="local"
               else
                  nodetype="none"
               fi
            fi
         ;;
      esac
   fi

   log_fluff "Guessed nodetype \"${nodetype}\" from \"${guesssource}\""
   RVAL="${nodetype}"
}


#
# enters
#   _address: parameter given on cmdline as --address
#
# returns
#
#   _nodetype
#   _address
#   _url
#
sourcetree::commands::_nameguess_node()
{
   log_entry "sourcetree::commands::_nameguess_node" "$@"

   local input="$1"
   local nodetype="$2"
   local url="$3"

   if [ "${nodetype}" = "comment" ]
   then
      _address="${input}"
      _nodetype="${nodetype}"
      _url=""
      return
   fi

   local original_address

   original_address="${_address}"

   sourcetree::commands::r_typeguess_node "${input}" "${nodetype}" "${url}"
   _nodetype="${RVAL}"

   if [ -z "${_address}" ]
   then
      _address="${input}"
   fi
   _url="${url}"

   log_debug "1) _url set to \"${_url}\""
   log_debug "1) _address set to \"${_address}\""

   #
   # try to figure out if input is an _url
   #
   # locals and none have no URL usually
   #
   if [ -z "${_url}" ]
   then
      if [ -z "${_address}" ]
      then
         return 1
      fi

      if [ "${_nodetype}" = "local" -o "${_nodetype}" = "none" ]
      then
         log_fluff "Taken address \"${_address}\" and url \"${_url}\""
         return
      fi

      # must be an_url then

      _url="${input}"
      _address="${original_address}"

      log_debug "2) _url set to \"${_url}\""
      log_debug "2) _address set to \"${_address}\""
   fi

   # url is set
   if [ -z "${_address}" ]
   then
      local _evaledurl
      local _evalednodetype
      local _evaledbranch
      local _evaledtag
      local _evaledfetchoptions

      sourcetree::node::__evaluate_values

      if [ "${_evalednodetype}" = "local" -o "${_evalednodetype}" = "none" ]
      then
         _address="${_url}"
         _url=""

         log_debug "3) _url set to \"${_url}\""
         log_debug "3) _address set to \"${_address}\""

         log_fluff "Taken address \"${_address}\" from \"${_url}\""
         return
      fi

      sourcetree::fetch::r_guess_address "${_evaledurl}" "${_evalednodetype}"
      _address="${RVAL}"

      log_debug "4) _url set to \"${_url}\""
      log_debug "4) _address set to \"${_address}\""

      log_fluff "Guessed address \"${_address}\" from \"${_url}\""
   fi
}

# cmd
sourcetree::commands::nameguess_node()
{
   log_entry "sourcetree::commands::nameguess_node" "$@"

   local input="$1"

   local _address
   local _url
   local _nodetype

   sourcetree::commands::_nameguess_node "${input}" "${OPTION_NODETYPE}" "${OPTION_URL}"

   printf "%s\n" "${_address}"
}


sourcetree::commands::typeguess_node()
{
   log_entry "sourcetree::commands::typeguess_node" "$@"

   local input="$1"

   local _address
   local _url
   local _nodetype

   sourcetree::commands::r_typeguess_node "${input}" "${OPTION_NODETYPE}" "${OPTION_URL}"
   printf "%s\n" "${RVAL}"
}


sourcetree::commands::assert_sane_mark()
{
   log_entry "sourcetree::commands::assert_sane_mark" "$@"

   local mark="$1"

   sourcetree::nodemarks::assert_sane_nodemark "${mark}"

   case "${mark}" in
      no-*|only-*|version-*)
      ;;

      *)
         fail "mark \"${mark}\" must start with \"no-\" or \"only-\""
      ;;
   esac
}


#
# retrieve node line from user input which has previously beed
#
sourcetree::commands::get_nodeline_address_url_uuid()
{
   log_entry "sourcetree::commands::get_nodeline_address_url_uuid" "$@"

   local address="$1"
   local url="$2"
   local uuid="$3"

   if [ ! -z "${uuid}" ]
   then
      sourcetree::cfg::get_nodeline_by_uuid "${SOURCETREE_START}" "${uuid}"
      return $?
   fi

   if [ ! -z "${address}" ]
   then
      sourcetree::cfg::get_nodeline "${SOURCETREE_START}" "${address}" "${OPTION_MATCH}"
      return $?
   fi


   if sourcetree::cfg::get_nodeline_by_url "${SOURCETREE_START}" "${SOURCETREE_START}" "${url}" > /dev/null
   then
      return 0
   fi

   sourcetree::cfg::get_nodeline_by_evaled_url "${SOURCETREE_START}" "${url}"
}



#
# guess from input if user typed in a UUID a url or an address
#
#   local _address
#   local _url
#   local _nodetype
sourcetree::commands::_guess_address_url_uuid()
{
   _uuid=
   _url=
   _address=

   case "$1" in
      *-*-*-*-*)  # F630038D-4100-46D3-A610-E914294A8EE4
         if [ "${#1}" -eq 36 ]
         then
            _uuid="$1"
            return
         fi
      ;;

      *':'*|/*|\~*|\.*|\$*)
         _url="$1"
         return
      ;;
   esac

   _address="$1"
}


sourcetree::commands::get_nodeline()
{
   log_entry "sourcetree::commands::get_nodeline" "$@"

   local input="$1"
   local warn="${2:-YES}"

   [ -z "${input}" ] && fail "Node address is empty"

   local _uuid
   local _url
   local _address

   sourcetree::commands::_guess_address_url_uuid "${input}"

   if ! sourcetree::commands::get_nodeline_address_url_uuid "${_address}" "${_url}" "${_uuid}"
   then
      if [ "${warn}" = 'NO' ]
      then
         log_warning "A node \"${_address:-${_url:-${_uuid}}}\" does not exist"
      fi
      return 2  # also return non 0 , but lets's not be dramatic about it
   fi
}


sourcetree::commands::change_nodeline_uuid()
{
   log_entry "sourcetree::commands::change_nodeline_uuid" "$@"

   local oldnodeline="$1"
   local newnodeline="$2"
   local uuid="$3"

   if [ "${newnodeline}" = "${oldnodeline}" ]
   then
      log_info "Nothing changed"
      return
   fi

   sourcetree::cfg::change_nodeline "${SOURCETREE_START}" "${oldnodeline}" "${newnodeline}"
   sourcetree::cfg::touch_parents "${SOURCETREE_START}"

   local verifynodelines
   local verifynodeline

   verifynodelines="`sourcetree::cfg::read "${SOURCETREE_START}"`"
   sourcetree::nodeline::r_find_by_uuid "${verifynodelines}" "${uuid}"
   verifynodeline="${RVAL}"

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != 'YES' ]
   then
      if [ "${verifynodeline}" != "${newnodeline}" ]
      then
         fail "Verify of config file after write failed.
${C_RESET}---
${verifynodeline}
---
${newnodeline}
---"
      fi
   fi

   sourcetree::nodeline::r_get_address "${newnodeline}"
   log_info "Changed ${C_MAGENTA}${C_BOLD}${RVAL}${C_INFO}"
}


sourcetree::commands::log_add_remove()
{
   log_entry "sourcetree::commands::log_add_remove" "$@"

   if [ "${MULLE_FLAG_LOG_TERSE}" != 'YES' ]
   then
      sourcetree::cfg::r_configfile_for_write "${SOURCETREE_START}"
      r_basename "${RVAL}"

      log_info "$1 ${C_MAGENTA}${C_BOLD}$2${C_INFO} $3 ${C_RESET_BOLD}${RVAL}"
   fi
}


sourcetree::commands::_append_new_node()
{
   log_entry "sourcetree::commands::_append_new_node" "$@"

   local contents
   local appended

   [ ! -z "${_uuid}" ] && fail "UUID already set"

   log_setting "ADDRESS      : \"${_address}\""
   log_setting "NODETYPE     : \"${_nodetype}\""
   log_setting "MARKS        : \"${_marks}\""
   log_setting "UUID         : \"${_uuid}\""
   log_setting "URL          : \"${_url}\""
   log_setting "BRANCH       : \"${_branch}\""
   log_setting "TAG          : \"${_tag}\""
   log_setting "FETCHOPTIONS : \"${_fetchoptions}\""
   log_setting "USERINFO     : \"${_raw_userinfo}\""

   #
   # now just some sanity checks and save it
   #
   if sourcetree::cfg::get_nodeline "${SOURCETREE_START}" "${_address}" > /dev/null
   then
      if [ "${OPTION_IF_MISSING}" = 'YES' ]
      then
         return 0
      fi
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         if sourcetree::cfg::is_config_present "${SOURCETREE_START}"
         then
            fail "A node ${C_RESET_BOLD}${_address}${C_ERROR_TEXT} already exists \
in the sourcetree (${RVAL#"${MULLE_USER_PWD}/"}). Use -f to skip this check."
         else
            _internal_fail "Bizarre error"
         fi
      fi
   fi

   log_debug "uuid is ${_uuid}"

#   if [ "${OPTION_UNSAFE}" = 'YES' ]
#   then
#      r_comma_concat "${mode}" "unsafe"
#      mode="${RVAL}"
#   fi

   sourcetree::node::__augment  # safe by default

   contents="`sourcetree::cfg::read "${SOURCETREE_START}" `"
   sourcetree::node::r_to_nodeline
   r_add_line "${contents}" "${RVAL}"
   appended="${RVAL}"

   sourcetree::cfg::write "${SOURCETREE_START}" "${appended}"
   sourcetree::cfg::touch_parents "${SOURCETREE_START}"

   sourcetree::commands::log_add_remove "Added" "${_address}" "to"
}


#
#
#
sourcetree::commands::add()
{
   log_entry "sourcetree::commands::add" "$@"

   local input="$1"

   # input could be url or address

   local _address="${OPTION_ADDRESS}"
   local _url="${OPTION_URL}"
   local _branch="${OPTION_BRANCH}"
   local _nodetype="${OPTION_NODETYPE}"
   local _fetchoptions="${OPTION_FETCHOPTIONS}"
   local _marks="${OPTION_MARKS}"
   local _tag="${OPTION_TAG}"
   local _userinfo="${OPTION_USERINFO}"
   local _uuid
   local _raw_userinfo

   # local is just used for subprojects,
   # none is used for closed-source libraries ( like -ldl)
   case "${_nodetype}" in
      'local')
         r_comma_concat "${_marks}" "no-delete,no-update,no-share"
         _marks="${RVAL}"
      ;;

      'none')
         r_comma_concat "${_marks}" "no-delete,no-fs,no-update,no-share"
         _marks="${RVAL}"
      ;;

      'comment')
         _marks="no-fs"
      ;;
   esac

   sourcetree::nodemarks::assert_sane "${_marks}"

   if [ ! -z "${_address}" -a ! -z "${_url}" ]
   then
      fail "Specifying --address and --url together conflicts with the main argument"
   fi

   #
   # the following code is really poor and inscrutable
   #

   sourcetree::commands::_nameguess_node "${input}" "${_nodetype}" "${_url}"

   if [ -z "${_address}" ]
   then
      _address="${input}"
   fi

   if [ -z "${_url}" ]
   then
      if ! [ -e "${_address}" ]
      then
         case ",${_marks}," in
            *,no-fs,*)
            ;;

            *)
               _log_warning "There is no directory or file named \
\"${_address}\" (${PWD#"${MULLE_USER_PWD}/"})"
            ;;
         esac
      fi
   else
      if [ -e "${_address}" -a "${_nodetype}" != "local" ]
      then
         log_warning "A directory or file named \"${_address}\" already exists (${PWD#"${MULLE_USER_PWD}/"})"
      fi
   fi

   sourcetree::commands::_append_new_node
}


#
# unused currently
#
sourcetree::commands::duplicate()
{
   log_entry "sourcetree::commands::duplicate" "$@"

   local input="$1"

   local _address
   local _branch
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   local node

   node="`sourcetree::commands::get_nodeline "${input}"`"
   if [ -z "${node}" ]
   then
      fail "Node \"${input}\" not found"
   fi

   local newname
   local i

   i=1
   while :
   do
      newname="${input%%#*}#${i}"
      if [ -z "`sourcetree::cfg::get_nodeline "${SOURCETREE_START}" "${newname}"`" ]
      then
         break
      fi
      i=$(( i + 1))
   done

   sourcetree::nodeline::parse "${node}" # !!

   if [ ! -z "${OPTION_MARKS}" ]
   then
      _marks=
      if [ "${OPTION_MARKS}" != "NONE" ]
      then
         _marks="${OPTION_MARKS}"
      fi
   else
      sourcetree::nodemarks::r_remove "${_marks}" "fs"
      _marks="${RVAL}"
   fi

   _address="${newname}"
   _uuid=""

   sourcetree::commands::_append_new_node
}


# get mit sed vermutlich einfacher
sourcetree::commands::line_mover()
{
   log_entry "sourcetree::commands::line_mover" "$@"

   local nodeline="$1"
   local direction="$2"

   case "${direction}" in
      top)
         printf "%s\n" "${nodeline}"
      ;;
      bottom|up|down)
      ;;

      *)
         sourcetree::commands::move_usage "Unknown direction \"${direction}\""
      ;;
   esac

   local line
   local prev

   while IFS=$'\n' read -r line
   do
      case "${direction}" in
         top|bottom)
            if [ "${line}" != "${nodeline}" ]
            then
               printf "%s\n" "${line}"
            fi
         ;;

         up)
            if [ "${line}" = "${nodeline}" ]
            then
               printf "%s\n" "${line}"
               if [ ! -z "${prev}" ]
               then
                  printf "%s\n" "${prev}"
                  prev=
               fi
               continue
            fi

            if [ ! -z "${prev}" ]
            then
               printf "%s\n" "${prev}"
            fi
            prev="${line}"
         ;;

         down)
            if [ "${line}" != "${nodeline}" ]
            then
               printf "%s\n" "${line}"
               if [ ! -z "${prev}" ]
               then
                  printf "%s\n" "${prev}"
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
            printf "%s\n" "${prev}"
         fi
      ;;

      bottom)
         printf "%s\n" "${nodeline}"
      ;;
   esac
}


###
### NODE commands set/get/remove/move
###
sourcetree::commands::set()
{
   log_entry "sourcetree::commands::set" "$@"

   local input="$1"; shift

   local oldnodeline

   if ! oldnodeline="`sourcetree::commands::get_nodeline "${input}"`"
   then
      return 2
   fi

#
# we need to keep the position in the file as it is important
# so add/remove is not the solution
#
   local _address
   local _branch
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   sourcetree::nodeline::parse "${oldnodeline}"  # !!

   if sourcetree::nodemarks::disable "${_marks}" "set"
   then
      fail "Node is marked as no-set"
   fi

   local oldaddress

   oldaddress="${_address}"

   sourcetree::nodemarks::assert_sane "${_marks}"

   # override with options from command options
   _address="${OPTION_ADDRESS:-${_address}}"
   _url="${OPTION_URL:-${_url}}"
   _branch="${OPTION_BRANCH:-${_branch}}"
   _nodetype="${OPTION_NODETYPE:-${_nodetype}}"
   _fetchoptions="${OPTION_FETCHOPTIONS:-${_fetchoptions}}"
   _marks="${OPTION_MARKS:-${_marks}}"
   _tag="${OPTION_TAG:-${_tag}}"
   _userinfo="${OPTION_USERINFO:-${_userinfo}}"

   # but arguments override

   local key
   local value

   while [ "$#" -ge 2 ]
   do
      key="$1"
      shift
      value="$1"
      shift

      case "${key}" in
         branch|address|fetchoptions|marks|nodetype|tag|url)
            printf -v "_${key}" "%s" "${value}"
            log_verbose "Setting ${key} to \"${value}\" for \"${oldaddress}\""
         ;;

         raw_userinfo)
            userinfo=""
            printf -v "_${key}" "%s" "${value}"
            log_verbose "Setting ${key} to \"${value}\" for \"${oldaddress}\""
         ;;

         userinfo)
            _raw_userinfo=""
            printf -v "_${key}" "%s" "${value}"
            log_verbose "Setting ${key} to \"${value}\" for \"${oldaddress}\""
         ;;

         *)
            log_error "Unknown keyword \"${key}\""
            sourcetree::commands::set_usage
         ;;
      esac
   done

   if [ "$#" -ne 0 ]
   then
      log_error "Key \"${1}\" without value"
      sourcetree::commands::set_usage
   fi

   sourcetree::node::__augment "${OPTION_AUGMENTMODE}"

   if [ "${oldaddress}" != "${_address}" ] &&
      sourcetree::cfg::has_duplicate "${SOURCETREE_START}" "${_uuid}" "${_address}"
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ]
      then
         fail "There is already a node ${C_RESET_BOLD}${_address}${C_ERROR_TEXT} \
in the sourcetree (${PWD#"${MULLE_USER_PWD}/"})"
      fi
   fi

   sourcetree::node::r_to_nodeline
   sourcetree::commands::change_nodeline_uuid "${oldnodeline}" "${RVAL}" "${_uuid}"

   sourcetree::commands::log_add_remove "Changed node" "${_address}" "in"
}


sourcetree::commands::get()
{
   log_entry "sourcetree::commands::get" "$@"

   local input="$1"
   local fuzzy="$2"

   shift 2

   local nodeline

   if [ "${fuzzy}" = 'YES' ]
   then
      nodeline="`sourcetree::cfg::get_nodeline "${SOURCETREE_START}" "${input}" "${fuzzy}" `"
   else
      nodeline="`sourcetree::commands::get_nodeline "${input}"`"
   fi

   if [ -z "${nodeline}" ]
   then
      log_warning "Node \"${input}\" does not exist"
      return 1
   fi

   local _address
   local _branch
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   sourcetree::nodeline::parse "${nodeline}"  # !!

   if [ "$#" -eq 0 ]
   then
      rexekutor printf "%s\n" "${_address}"
      return
   fi

   while [ "$#" -ne 0 ]
   do
      case "$1" in
         branch|address|fetchoptions|marks|nodetype|tag|url|uuid)
            rexekutor eval echo \$"_${1}"
         ;;

         raw_userinfo)
            rexekutor printf "%s\n" "${_raw_userinfo}"
         ;;

         userinfo)
            sourcetree::node::r_decode_raw_userinfo "${_raw_userinfo}"
            _userinfo="${RVAL}"
            rexekutor printf "%s\n" "${_userinfo}"
         ;;

         *)
            log_error "unknown keyword \"$1\""
            sourcetree::commands::get_usage
         ;;
      esac
      shift
   done
}


sourcetree::commands::move()
{
   log_entry "sourcetree::commands::move" "$@"

   local input="$1"
   local direction="$2"

   local nodeline

   if ! nodeline="`sourcetree::commands::get_nodeline "${input}" 'NO'`"
   then
      fail "No node for \"${input}\" found"
   fi

   if ! moved="`sourcetree::commands::line_mover "${nodeline}" "${direction}" < <( sourcetree::cfg::read "${SOURCETREE_START}" )`"
   then
      return 1
   fi

   sourcetree::cfg::write "${SOURCETREE_START}" "${moved}"
   sourcetree::cfg::touch_parents "${SOURCETREE_START}"

   sourcetree::nodeline::r_get_address "${nodeline}"

   sourcetree::commands::log_add_remove "Moved" "${RVAL}" "${direction} in"
}


sourcetree::commands::remove()
{
   log_entry "sourcetree::commands::remove" "$@"

   local input
   local nodeline
   local uuid

   while [ $# -ne 0 ]
   do
      input="$1"
      shift 
      
      if ! nodeline="`sourcetree::commands::get_nodeline "${input}" `"
      then
         if [ "${OPTION_IF_PRESENT}" = 'YES' ]
         then
            continue
         fi
         log_error "No node found for \"${input}\""
         return 3  # also return non 0 , but lets's not be dramatic about it
                   # 1 is an error, 2 stacktraces
      fi

      sourcetree::nodeline::r_get_uuid "${nodeline}"
      uuid="${RVAL}"

      sourcetree::cfg::remove_nodeline_by_uuid "${SOURCETREE_START}" "${uuid}"
      sourcetree::cfg::touch_parents "${SOURCETREE_START}"

      sourcetree::nodeline::r_get_address "${nodeline}"

      sourcetree::commands::log_add_remove "Removed" "${RVAL}" "from"
   done
}


###
### NODE commands mark/unmark
###
#
# TODO: make this more stringent maybe no-- vs no-os-
#       so we can scope this nicer ?
KNOWN_MARKS="\
no-actual-link
no-all-load
no-bequeath
no-build
no-cmake-add
no-cmake-all-load
no-cmake-dependency
no-cmake-inherit
no-cmake-intermediate-link
no-cmake-loader
no-cmake-searchpath
no-delete
no-dependency
no-descend
no-dynamic-link
no-fs
no-header
no-include
no-import
no-inplace
no-intermediate-link
no-link
no-cmake-platform-mingw
no-cmake-platform-darwin
no-cmake-platform-freebsd
no-cmake-platform-linux
no-cmake-platform-windows
no-platform-mingw
no-platform-darwin
no-platform-freebsd
no-platform-linux
no-platform-windows
no-public
no-readwrite
no-require
no-set
no-singlephase
no-singlephase-link
no-static-link
no-share
no-update
only-standalone
only-framework
only-cmake-platform-darwin
only-cmake-platform-freebsd
only-cmake-platform-linux
only-cmake-platform-windows
only-cmake-platform-mingw
only-platform-darwin
only-platform-freebsd
only-platform-linux
only-platform-windows
only-platform-mingw
"


sourcetree::commands::_add_mark_known_absent()
{
   log_entry "sourcetree::commands::_add_mark_known_absent" "$@"

   local mark="$1"

   sourcetree::commands::assert_sane_mark "${mark}"

   if [ "${OPTION_EXTENDED_MARK}" != 'YES' ]
   then
      if ! grep -F -x -q -e "${mark}" <<< "${KNOWN_MARKS}"
      then
         case "${mark}" in
            version-min-*|version-max-*)
            ;;

            *)
               fail "mark \"${mark}\" is unknown.
${C_INFO}If this is not a typo use:
${C_RESET_BOLD}   ${MULLE_EXECUTABLE_NAME} mark -e ..."
            ;;
         esac
      fi
   fi

   sourcetree::nodemarks::r_add "${_marks}" "${mark}"
   _marks="${RVAL}"
}


sourcetree::commands::_remove_mark_known_present()
{
   log_entry "sourcetree::commands::_remove_mark_known_present" "$@"

   local mark="$1"

   local operation

   sourcetree::commands::assert_sane_mark "${mark}"

   if [ "${OPTION_EXTENDED_MARK}" != 'YES' ]
   then
      if ! grep -F -x -q -e "${mark}" <<< "${KNOWN_MARKS}"
      then
         fail "mark \"${mark}\" is unknown.
${C_INFO}If this is not a typo use:
${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} unmark -e ..."
      fi
   fi

   sourcetree::nodemarks::r_remove "${_marks}" "${mark}"
   _marks="${RVAL}"
}


sourcetree::commands::write_nodeline_changed_marks()
{
   local oldnodeline="$1"

   sourcetree::node::r_sanitized_marks "${_marks}"
   _marks="${RVAL}"

   sourcetree::node::r_to_nodeline
   sourcetree::commands::change_nodeline_uuid "${oldnodeline}" "${RVAL}" "${_uuid}"
}


sourcetree::commands::mark()
{
   log_entry "sourcetree::commands::mark" "$@"

   local input="$1"
   local marks="$2"

   local oldnodeline

   if ! oldnodeline="`sourcetree::commands::get_nodeline "${input}"`"
   then
      log_warning "Node \"${input}\" not found"
      return 2
   fi

   local _address
   local _branch
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   local rval
   local mark
   local blurb

   sourcetree::nodeline::parse "${oldnodeline}" # !!

   # this loop is suboptimal as we are constantly rewriting the line
   # it was added as an afterthought

   .foreachitem mark in ${marks}
   .do
      case "${mark}" in
         no-*|only-*|version-*)
            if sourcetree::nodemarks::_contain "${_marks}" "${mark}"
            then
               log_info "Node \"${_address}\" is already marked as \"${mark}\"."
               .continue
            fi
            sourcetree::commands::_add_mark_known_absent "${mark}"
            rval=$?
            [ $rval -ne 0 ] && return $rval
         ;;

         [a-z_]*)
            blurb='YES'
            if sourcetree::nodemarks::contain "${_marks}" "no-${mark}"
            then
               blurb='NO'
               sourcetree::commands::_remove_mark_known_present "no-${mark}"
               rval=$?
               [ $rval -ne 0 ] && return $rval
            fi

            if sourcetree::nodemarks::contain "${_marks}" "only-${mark}"
            then
               blurb='NO'
               sourcetree::commands::_remove_mark_known_present "only-${mark}"
               rval=$?
               [ $rval -ne 0 ] && return $rval
            fi

            if [ "${blurb}" = 'YES' ]
            then
               _log_info "Node \"${_address}\" is already implicitly marked as \
\"${mark}\" (as a negative is absent)"
            fi
         ;;

         *)
            fail "Malformed mark \"${mark}\" for node \"${_address}\" (only lowercase identifiers please)"
         ;;
      esac
   .done

   sourcetree::commands::write_nodeline_changed_marks "${oldnodeline}"
}


sourcetree::commands::unmark()
{
   log_entry "sourcetree::commands::unmark" "$@"

   local input="$1"
   local mark="$2"

   [ -z "${input}" ] && fail "input is empty"
   [ -z "${mark}" ] && fail "mark is empty"

   case "${mark}" in
      no-*)
         mark="${mark:3}"
      ;;

      only-*)
         mark="${mark:5}"
      ;;

      version-*)
         local oldnodeline

         if ! oldnodeline="`sourcetree::commands::get_nodeline "${input}"`"
         then
            return 2
         fi

         local _address
         local _branch
         local _fetchoptions
         local _marks
         local _nodetype
         local _raw_userinfo
         local _tag
         local _url
         local _userinfo
         local _uuid

         sourcetree::nodeline::parse "${oldnodeline}" # !!

         if sourcetree::nodemarks::contain "${_marks}" "${mark}"
         then
            sourcetree::commands::_remove_mark_known_present "${mark}"
            sourcetree::commands::write_nodeline_changed_marks "${oldnodeline}"
            return $?
         fi
         return 2
      ;;

      *)
         mark="no-${mark}"
      ;;
   esac

   sourcetree::commands::mark "${input}" "${mark}"
}


sourcetree::commands::r_rename_mark_nodeline()
{
   log_entry "sourcetree::commands::r_rename_mark_nodeline" "$@"

   local oldnodeline="$1"

   local _address
   local _branch
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   sourcetree::nodeline::parse "${oldnodeline}" # !!

   local mark
   local changed
   local tmp

   shell_disable_glob ; IFS=","
   for mark in ${_marks}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      if [ "${mark}" = "no-${oldmark}" ]
      then
         mark="no-${newmark}"
      else
         if [ "${mark}" = "only-${oldmark}" ]
         then
            mark="only-${newmark}"
         fi
      fi

      r_comma_concat "${changed}" "${mark}"
      changed="${RVAL}"
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   sourcetree::nodemarks::sort "${changed}"
   _marks="${RVAL}"

   sourcetree::node::r_to_nodeline
}


#
# copy a field or all from another config, possibly from another project
#
sourcetree::commands::get_nodeline_from_config()
{
   local config="$1"
   shift

   (
      if [ ! -z "${config}" ]
      then
         r_absolutepath "${config}"
         # hacky
         SOURCETREE_START="#${RVAL}"
      fi
      sourcetree::commands::get_nodeline "$@"
   )
}


sourcetree::commands::copy()
{
   log_entry "sourcetree::commands::copy" "$@"

   local fields="$1"
   local input="$2"
   local config="$3"
   local from="$4"

   local dst

   if ! dst="`sourcetree::commands::get_nodeline "${input}" `"
   then
      if [ "${fields}" != 'ALL' ]
      then
         fail "No node \"${input}\" found, to copy \"${field}\" to."
      fi
   fi

   local src

   if [ "${config}" = "." ]
   then
      if [ "${input}" = "${from}" ]
      then
         fail "Can't copy \"${input}\" unto itself"
      fi

      if ! src="`sourcetree::commands::get_nodeline "${from}" `"
      then
         fail "No node \"${from}\" found, to copy from."
      fi
   else
      if ! src="`sourcetree::commands::get_nodeline_from_config "${config}" "${from}" `"
      then
         fail "No node \"${from}\" found, to copy from ${config}."
      fi
   fi

   local _address
   local _branch
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   sourcetree::nodeline::parse "${src}"

   local memo
   local field

   if [ "${fields}" = "ALL" ]
   then
      if [ -z "${dst}" ]
      then
         _uuid=
         _address="${input}"
         sourcetree::commands::_append_new_node
         return $?
      fi

      # clobber all from src for now
      sourcetree::nodeline::parse "${dst}"

      # keep this
      memo="${_uuid}"
      sourcetree::nodeline::parse "${src}"
      _uuid="${memo}"
   else
      shell_disable_glob; IFS=","
      for field in ${fields}
      do
         IFS="${DEFAULT_IFS}"; shell_enable_glob
         case "${field}" in
            '*')
               fail "* can not be mixed with other fields"
            ;;

            address)
               memo="${_address}"
               sourcetree::nodeline::parse "${dst}"
               _address="${memo}"
            ;;

            branch)
               memo="${_branch}"
               sourcetree::nodeline::parse "${dst}"
               _branch="${memo}"
            ;;

            fetchoptions)
               memo="${_fetchoptions}"
               sourcetree::nodeline::parse "${dst}"
               _fetchoptions="${memo}"
            ;;

            marks)
               memo="${_marks}"
               sourcetree::nodeline::parse "${dst}"
               _marks="${memo}"
            ;;

            nodetype)
               memo="${_nodetype}"
               sourcetree::nodeline::parse "${dst}"
               _nodetype="${memo}"
            ;;

            tag)
               memo="${_tag}"
               sourcetree::nodeline::parse "${dst}"
               _tag="${memo}"
            ;;

            url)
               memo="${_url}"
               sourcetree::nodeline::parse "${dst}"
               _url="${memo}"
            ;;

            userinfo)
               memo="${_raw_userinfo}"
               sourcetree::nodeline::parse "${dst}"
               _raw_userinfo="${memo}"
            ;;

            uuid)
               fail "Field uuid can't be copied"
            ;;

            *)
               fail "Field ${field} unknown"
            ;;
         esac
      done
      IFS="${DEFAULT_IFS}"; shell_enable_glob
   fi

   sourcetree::node::r_to_nodeline
   sourcetree::commands::change_nodeline_uuid "${dst}" "${RVAL}" "${_uuid}"
}



sourcetree::commands::rename_marks()
{
   log_entry "sourcetree::commands::rename_marks" "$@"

   local oldmark="$1"
   local newmark="$2"

   case "${newmark}" in
      "")
         fail "Empty node mark"
      ;;

      *[^a-z0-9._-]*)
         fail "Node mark \"${newmark}\" contains invalid characters"
      ;;

      no-*|only-*|version-*)
         fail "Mark \"${newmark}\" must not start with no-/only-/version-"
      ;;
   esac

   case "${oldmark}" in
      "")
         fail "Empty node mark"
      ;;

      *[^a-z0-9._-]*)
         fail "Node mark \"${oldmark}\" contains invalid characters"
      ;;

      no-*|only-*|version-*)
         fail "Mark \"${oldmark}\" must not start with no-/only-/version-"
      ;;
   esac

   local oldnodelines
   local oldnodeline
   local nodelines

   oldnodelines="`sourcetree::cfg::read "${SOURCETREE_START}"`"

   shell_disable_glob ; IFS=$'\n'
   for oldnodeline in ${oldnodelines}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      sourcetree::commands::r_rename_mark_nodeline "${oldnodeline}"
      r_add_line "${nodelines}" "${RVAL}"
      nodelines="${RVAL}"
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   if [ "${nodelines}" != "${oldnodelines}" ]
   then
      sourcetree::cfg::write "${SOURCETREE_START}" "${nodelines}"
   fi
}


#
#
#
sourcetree::commands::info()
{
   log_entry "sourcetree::commands::info" "$@"

   [ -z "${MULLE_SOURCETREE_LIST_SH}" ] && \
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-list.sh"

   sourcetree::list::_sourcetree_banner "$@"
}


sourcetree::commands::common()
{
   log_entry "sourcetree::commands::common" "$@"

   # must be empty initially for set

   local OPTION_URL
   local OPTION_DSTFILE
   local OPTION_BRANCH
   local OPTION_TAG
   local OPTION_NODETYPE
   local OPTION_MARKS
   local OPTION_FETCHOPTIONS
   local OPTION_USERINFO

   local OPTION_EXTENDED_MARK="DEFAULT"
   local OPTION_IF_MISSING='NO'
   local OPTION_IF_PRESENT='NO'
   local OPTION_MATCH='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            ${USAGE}
         ;;

         --print-common-keys)
            shift
            sourcetree::commands::print_common_keys "$@"
            exit 0
         ;;

         --print-common-options)
            shift
            sourcetree::commands::print_common_options "$@"
            exit 0
         ;;

         #
         # just for add
         #
         --if-missing)
            OPTION_IF_MISSING='YES'
         ;;

         # just for remove
         --if-present)
            OPTION_IF_PRESENT='YES'
         ;;

         --error-if-missing)
            OPTION_IF_PRESENT='NO'
         ;;

         #
         # marks
         #
         -e|--extended-mark)
            OPTION_EXTENDED_MARK='YES'
         ;;

         --no-extended-mark)
            OPTION_EXTENDED_MARK='NO'
         ;;


         #
         # more common flags
         #
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

         --regex|--match)
            OPTION_MATCH='YES'
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

   [ -z "${DEFAULT_IFS}" ] && _internal_fail "IFS fail"

   local argument
   local config
   local direction
   local field
   local from
   local input
   local key
   local mark
   local mode
   local newaddress
   local newmark
   local oldmark
   local url

   #
   # make simple commands flat by default, except if the user wants it
   #
   if [ -z "${FLAG_SOURCETREE_MODE}" -a "${COMMAND}" != "info" ]
   then
      SOURCETREE_MODE="flat"
      log_fluff "Sourcetree mode set to \"flat\" for config operations"
   fi

   [ -z "${SOURCETREE_CONFIG_DIR}" ]   && fail "SOURCETREE_CONFIG_DIR is empty"
   [ -z "${SOURCETREE_CONFIG_NAME}" ] && fail "SOURCETREE_CONFIG_NAME is empty"

   case "${COMMAND}" in
      add|duplicate)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         argument="$1"
         [ -z "${argument}" ] && log_error "empty argument" && ${USAGE}
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree::commands::${COMMAND} "${argument}"
      ;;

      get)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         input="$1"
         [ -z "${input}" ] && log_error "empty argument" && ${USAGE}
         shift
         sourcetree::commands::get "${input}" "${OPTION_MATCH}" "$@"
      ;;

      set|remove)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         input="$1"
         [ -z "${input}" ] && log_error "empty argument" && ${USAGE}
         shift
         sourcetree::commands::${COMMAND} "${input}" "$@"
      ;;

      info)
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree::commands::info
      ;;

      knownmarks)
         printf "%s\n" "${KNOWN_MARKS}"
      ;;

      mark|unmark|move)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         input="$1"
         [ -z "${input}" ] && log_error "empty argument" && ${USAGE}
         shift
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         argument="$1"
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree::commands::${COMMAND} "${input}" "${argument}"
      ;;

      rename_marks)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         oldmark="$1"
         [ -z "${oldmark}" ] && log_error "empty oldmark argument" && ${USAGE}
         shift
         newmark="$1"
         [ -z "${newmark}" ] && log_error "empty newmark argument" && ${USAGE}
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree::commands::rename_marks "${oldmark}" "${newmark}"
      ;;

      rename)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         input="$1"
         [ -z "${input}" ] && log_error "empty input argument" && ${USAGE}
         shift
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         newaddress="$1"
         [ -z "${newaddress}" ] && log_error "empty newaddress argument" && ${USAGE}
         shift
         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree::commands::set "${input}" address "${newaddress}"
      ;;

      #
      # copy takes: input, what line to change
      #             field, what field to cnhange,
      #             from, where to copy from
      #             config, which file to copy from (can be empty)
      #
      copy)
         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         field="$1"
         [ -z "${field}" ] && log_error "empty field argument" && ${USAGE}
         shift

         [ $# -eq 0 ] && log_error "missing argument to \"${COMMAND}\"" && ${USAGE}
         input="$1"
         [ -z "${input}" ] && log_error "empty input argument" && ${USAGE}
         shift

         from="${input}"
         config="."

         if [ $# -ne 0 ]
         then
            config="$1"
            [ -z "${config}" ] && log_error "empty config argument" && ${USAGE}
            shift

            if [ $# -eq 1 ]
            then
               from="$1"
               [ -z "${from}" ] && log_error "empty from argument" && ${USAGE}
               shift
            fi
         fi

         [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && ${USAGE}

         sourcetree::commands::copy "${field}" "${input}" "${config}" "${from}"
      ;;

   esac
}


sourcetree::commands::add_main()
{
   log_entry "sourcetree::commands::add_main" "$@"

   USAGE="sourcetree::commands::add_usage"
   COMMAND="add"
   sourcetree::commands::common "$@"
}


sourcetree::commands::duplicate_main()
{
   log_entry "sourcetree::commands::duplicate_main" "$@"

   USAGE="sourcetree::commands::duplicate_usage"
   COMMAND="duplicate"
   sourcetree::commands::common "$@"
}


sourcetree::commands::rename_main()
{
   log_entry "sourcetree::commands::rename_main" "$@"

   USAGE="sourcetree::commands::rename_usage"
   COMMAND="rename"
   sourcetree::commands::common "$@"
}


sourcetree::commands::remove_main()
{
   log_entry "sourcetree::commands::remove_main" "$@"

   USAGE="sourcetree::commands::remove_usage"
   COMMAND="remove"
   sourcetree::commands::common "$@"
}


sourcetree::commands::get_main()
{
   log_entry "sourcetree::commands::get_main" "$@"

   USAGE="sourcetree::commands::get_usage"
   COMMAND="get"
   sourcetree::commands::common "$@"
}


sourcetree::commands::set_main()
{
   log_entry "sourcetree::commands::set_main" "$@"

   USAGE="sourcetree::commands::set_usage"
   COMMAND="set"
   sourcetree::commands::common "$@"
}

sourcetree::commands::knownmarks_main()
{
   log_entry "sourcetree::commands::knownmarks_main" "$@"

   USAGE="sourcetree::commands::knownmarks_usage"
   COMMAND="knownmarks"
   sourcetree::commands::common "$@"
}

sourcetree::commands::mark_main()
{
   log_entry "sourcetree::commands::mark_main" "$@"

   USAGE="sourcetree::commands::mark_usage"
   COMMAND="mark"
   sourcetree::commands::common "$@"
}

sourcetree::commands::move_main()
{
   log_entry "sourcetree::commands::move_main" "$@"

   USAGE="sourcetree::commands::move_usage"
   COMMAND="move"
   sourcetree::commands::common "$@"
}

# maybe move elsewhere
sourcetree::commands::rename_marks_main()
{
   log_entry "sourcetree::commands::rename_marks_main" "$@"

   USAGE="sourcetree::commands::rename_marks_usage"
   COMMAND="rename_marks"
   sourcetree::commands::common "$@"
}

# maybe move elsewhere
sourcetree::commands::copy_main()
{
   log_entry "sourcetree::commands::copy_main" "$@"

   USAGE="sourcetree::commands::copy_usage"
   COMMAND="copy"
   sourcetree::commands::common "$@"
}



sourcetree::commands::unmark_main()
{
   log_entry "sourcetree::commands::unmark_main" "$@"

   USAGE="sourcetree::commands::unmark_usage"
   COMMAND="unmark"
   sourcetree::commands::common "$@"
}


sourcetree::commands::info_main()
{
   log_entry "sourcetree::commands::info_main" "$@"

   USAGE="sourcetree::commands::info_usage"
   COMMAND="info"
   sourcetree::commands::common "$@"
}


#
# the general idea here was to use mulle-sourcetree as a library too
#
sourcetree::commands::initialize()
{
   log_entry "sourcetree::commands::initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && _internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

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
   if [ -z "${MULLE_SOURCETREE_FETCH_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-fetch.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-fetch.sh" || exit 1
   fi
}


sourcetree::commands::initialize

:
