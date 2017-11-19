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
MULLE_SOURCETREE_WALK_SH="included"


sourcetree_walk_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} walk [options] <shell command>

   Walk over the nodes described by the config file and execute <shell command>
   for each node. The working directory will be the node (if it is a directory).

   Unprocessed node information is passed in the following environment
   variables:

   MULLE_URL  MULLE_ADDRESS  MULLE_BRANCH  MULLE_TAG  MULLE_NODETYPE
   MULLE_UUID  MULLE_MARKS  MULLE_FETCHOPTIONS  MULLE_USERINFO
   MULLE_NODE

   Additional information is passed in:

   MULLE_DESTINATION  MULLE_MODE  MULLE_DATABASE  MULLE_PROJECTDIR  MULLE_ROOT_DIR.

Options:
   -n <value>       : node types to walk (default: ALL)
   -p <value>       : specify permissions (missing)
   -m <value>       : specify marks to match (e.g. build)
   --cd             : change directory to node's working directory
   --lenient        : allow shell command to error
   --no-depth-first : walk tree in pre-order
   --walk-db        : walk over information contained in the virtual instead
EOF
  exit 1
}


sourcetree_buildorder_usage()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} buildorder

   Print all sourcetree addresses according to the following rules:

   * ignore nodes marked as "nobuild"
   * ignore nodes marked as "norequire", whose address is missing
   * ignore nodes marked as "no${UNAME}" (platform dependent of course)

   In a make based project, this can be used to build everything like this:

      ${MULLE_EXECUTABLE_NAME} buildorder | while read address
      do
         ( cd "${address}" ; make ) || break
      done
EOF
  exit 1
}


#
# Walkers
#
# Possible permissions: "symlink\nmissing"
#
walk_filter_permissions()
{
   log_entry "walk_filter_permissions" "$@"

   local address="$1"
   local permissions="$2"
   local marks="$3"

   [ -z "${address}" ] && internal_fail "empty address"

   local match

   if [ -z "${permissions}" ]
   then
      return
   fi

   if [ ! -e "${address}" ]
   then
      log_fluff "${address} does not exist (yet)"
      case "${permissions}" in
         *fail-noexist*)
            fail "Missing \"${address}\" is not yet fetched."
         ;;

         *warn-noexist*)
            log_verbose "Repository expected in \"${address}\" is not yet fetched"
            return 0
         ;;

         *skip-noexist*)
            log_fluff "Repository expected in \"${address}\" is not yet fetched, skipped"
            return 1
         ;;

         *)
            return 0
         ;;
      esac
   fi

   if [ ! -L "${address}" ]
   then
      return 0
   fi

   log_fluff "${address} is a symlink"
   case "${permissions}" in
      *fail-symlink*)
         fail "Missing \"${address}\" is a symlink."
      ;;

      *warn-symlink*)
         log_verbose "\"${address}\" is a symlink."
         return 0
      ;;

      *skip-symlink*)
         log_fluff "\"${address}\" is a symlink, skipped"
         return 1
      ;;
   esac

   return 0
}


walk_filter_nodetypes()
{
   log_entry "walk_filter_nodetypes" "$@"

   local nodetype="$1"
   local allowednodetypes="$2"

   [ -z "${nodetype}" ] && internal_fail "empty nodetype"

   if [ "${allowednodetypes}" = "ALL" ]
   then
      return 0
   fi

   nodetypes_contain "${allowednodetypes}" "${nodetype}"
}


#
# you can pass a qualifier of the form <all>;<one>;<none>
# inside all,one,none are comma separated marks
#
walk_filter_marks()
{
   log_entry "walk_filter_marks" "$@"

   local marks="$1"
   local qualifier="$2"

   if [ "${qualifier}" = "ANY" ]
   then
      return 0
   fi

   local all
   local one
   local none

   all="$(cut -d';' -f 1 <<< "${qualifier}")"
   one="$(cut -s -d';' -f 2 <<< "${qualifier}")"
   none="$(cut -s -d';' -f 3 <<< "${qualifier}")"

   if [ ! -z "${all}" ]
   then
      IFS=","
      for i in ${all}
      do
         IFS="${DEFAULT_IFS}"
         if ! nodemarks_contain "${marks}" "${i}"
         then
            return 1
         fi
      done
      IFS="${DEFAULT_IFS}"
   fi

   if [ ! -z "${one}" ]
   then
      if ! nodemarks_intersect "${marks}" "${one}"
      then
         return 1
      fi
   fi

   if [ ! -z "${none}" ]
   then
      IFS=","
      for i in ${none}
      do
         IFS="${DEFAULT_IFS}"
         if nodemarks_contain "${marks}" "${i}"
         then
            return 1
         fi
      done
      IFS="${DEFAULT_IFS}"
   fi
}


#
# "cheat" and read values defined in _visit_node
# w/o passing them explicitly
#
# useful for running git on the repos or so
# this way the user can pass "echo '${MULLE_URL}'" and
# the value gets printed
#
__call_callback()
{
   log_entry "__call_callback" "$@"

   local mode="$1"; shift
   local callback="$1"; shift

   MULLE_ADDRESS="${address}" \
   MULLE_BRANCH="${branch}" \
   MULLE_DATASOURCE="${datasource}" \
   MULLE_DESTINATION="`filepath_concat "${virtual}" "${address}"`" \
   MULLE_FETCHOPTIONS="${fetchoptions}" \
   MULLE_MARKS="${marks}" \
   MULLE_MODE="${mode}" \
   MULLE_NODE="${nodeline}" \
   MULLE_NODETYPE="${nodetype}" \
   MULLE_PROJECTDIR="`__concat_datasource_address "${datasource}" "${address}"`" \
   MULLE_TAG="${tag}" \
   MULLE_URL="${url}" \
   MULLE_USERINFO="${userinfo}" \
   MULLE_UUID="${uuid}" \
   MULLE_VIRTUAL="${virtual}" \
      _eval_exekutor "'${callback}'" "$@"

   rval="$?"
   if [ "${rval}" -eq 0 ]
   then
      return 0
   fi

   case "${mode}" in
      *lenient*)
         log_warning "Command '${callback}' failed for \"${MULLE_ADDRESS}\""
         return 0
      ;;
   esac

   fail "Command '${callback}' failed for \"${MULLE_ADDRESS}\""

   return "$rval"
}


#
# clobbers:
#
# local old
# local oldshared
#
__docd_preamble()
{
   local directory="$1"

   local relative

   # these two are semi public
   old="${PWD}"
   oldshared="${MULLE_SOURCETREE_SHARED_DIR}"

   relative="`compute_relative "${directory}"`"
   MULLE_SOURCETREE_SHARED_DIR="`filepath_concat "${MULLE_SOURCETREE_SHARED_DIR}" "${relative}"`"
   MULLE_SOURCETREE_SHARED_DIR="`simplified_path "${MULLE_SOURCETREE_SHARED_DIR}"`"
   exekutor cd "${directory}"
}

__docd_postamble()
{
   exekutor cd "${old}"
   MULLE_SOURCETREE_SHARED_DIR="${oldshared}"
}


__concat_datasource_address()
{
   local datasource="$1"
   local address="$2"

   case "${datasource}" in
      "/")
         echo "${address}"
      ;;

      *)
         filepath_concat "${datasource}" "${address}"
      ;;
   esac
}

#
# this never returns non-zero
# it bails or ignores (lenient)
#
#
# datasource
# virtual
# filternodetypes
# filterpermissions
# filtermarks
# mode
# callback
# ...
#
_visit_callback()
{
   log_entry "_visit_callback" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift

   shift 3

   local mode="$1"; shift
   local callback="$1"; shift

   if [ -z "${callback}" ]
   then
      log_debug "No callback, why am I doing this ?"
      return
   fi

   case "${mode}" in
      *docd*)
         local old
         local oldshared
         local directory

         directory="`__concat_datasource_address "${datasource}" "${address}"`"

         if [ -d "${directory}" ]
         then
            __docd_preamble "${directory}"
               __call_callback "${mode}" "${callback}" "$@"
            __docd_postamble
         else
            log_fluff "\"${directory}\" not there, so no callback"
         fi
         return
      ;;

      *)
         __call_callback "${mode}" "${callback}" "$@"
      ;;
   esac
}


#
# this should always return 0 except
# if a callback failed and we are not lenient
#
#
# datasource
# virtual
# filternodetypes
# filterpermissions
# filtermarks
# mode
# callback
# ...
#
_visit_recurse()
{
   log_entry "_visit_recurse" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift

   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local filtermarks="$1"; shift
   local mode="$1" ; shift

   local actual

   actual="`__concat_datasource_address "${datasource}" "${address}"`"
   virtual="`filepath_concat "${virtual}" "${address}"`"

   case "${mode}" in
      *flat*)
         log_debug "Non-recursive walk doesn't recurse on \"${actual}\""
         return 0
      ;;

      *)
         if nodemarks_contain_norecurse "${marks}"
         then
            log_debug "Do not recurse on \"${actual}\" due to norecurse mark"
            return 0
         fi

         if ! [ -d "${actual}" ]
         then
            if [ -f "${actual}" ]
            then
               log_fluff "Do not recurse on \"${actual}\" as it's not a directory. ($PWD)"
            else
               log_debug "Can not recurse into \"${actual}\" as it's not there yet. ($PWD)"
            fi
            return 0
         fi
      ;;
   esac

   #
   # internally we want to preserve state and globals vars
   # so dont subshell
   #

   case "${mode}" in
      *walkdb*)
         _walk_db_uuids "${actual}" \
                        "${virtual}" \
                        "${filternodetypes}" \
                        "${filterpermissions}" \
                        "${filtermarks}" \
                        "${mode}" \
                        "$@"
      ;;

      *)
         _walk_config_uuids "${actual}" \
                            "${virtual}" \
                            "${filternodetypes}" \
                            "${filterpermissions}" \
                            "${filtermarks}" \
                            "${mode}" \
                            "$@"
      ;;
   esac
}

#
# datasource
# virtual
# filternodetypes
# filterpermissions
# filtermarks
# mode
# callback
# ...
#
_visit_node()
{
   log_entry "_visit_node" "$@"

   local mode="$6"

   #
   # pre-order callback first before recursion
   #
   case "${mode}" in
      *pre-order*)
         _visit_callback "$@"
         _visit_recurse "$@"
      ;;

      *)
         _visit_recurse "$@"
         _visit_callback "$@"
      ;;
   esac
}


_visit_share_node()
{
   log_entry "_visit_share_node" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift

   local mode="$4"


#   [ -z "${MULLE_SOURCETREE_SHARED_DIR}" ] && internal_fail "MULLE_SOURCETREE_SHARED_DIR is empty"

   local shareddir
   local actual
   local name
   local original

   original="${address}"
   name="`basename -- "${address}"`"
   address="`filepath_concat "${MULLE_SOURCETREE_SHARED_DIR}" "${name}"`"

   if fgrep -q -s -x "${address}" <<< "${VISITED}"
   then
      return
   fi
   VISITED="`add_line "${VISITED}" "${address}"`"

   #
   # hacky hack. If shareddir exists visit that
   # otherwise optimistically look for it where it is in
   # recursive mode
   #
   if [ ! -e "${address}" -a -e "${original}" ]
   then
      log_debug "Visiting \"${original}\" as \"${address}\" doesn't exist yet"
      address="${original}"
      _visit_node "${datasource}" \
                  "" \
                  "$@"
      return $?
   fi

   _visit_node "/" \
               "" \
               "$@"
}


#
# datasource
# virtual
# filternodetypes
# filterpermissions
# filtermarks
# mode
# callback
# ...
#
_visit_filter_nodeline()
{
   log_entry "_visit_filter_nodeline" "$@"

   local nodeline="$1"; shift

   local datasource="$1"
   local virtual="$2"

   local filternodetypes="$3"
   local filterpermissions="$4"
   local filtermarks="$5"
   local mode="$6"

   # rest are arguments

   [ -z "${nodeline}" ]  && internal_fail "nodeline is empty"
   [ -z "${mode}" ]      && internal_fail "mode is empty"

   # nodeline_parse
   local branch
   local address
   local fetchoptions
   local marks
   local nodetype
   local tag
   local url
   local useroptions
   local uuid

   nodeline_parse "${nodeline}"

   if ! walk_filter_marks "${marks}" "${filtermarks}"
   then
      log_fluff "Node \"${address}\": \"${marks}\" doesn't jive with marks \"${filtermarks}\""
      return 0
   fi

   if ! walk_filter_nodetypes "${nodetype}" "${filternodetypes}"
   then
      log_fluff "Node \"${address}\": \"${nodetype}\" doesn't jive with nodetypes \"${filternodetypes}\""
      return 0
   fi

   if ! walk_filter_permissions "${address}" "${filterpermissions}"
   then
      log_fluff "Node \"${address}\": \"${address}\" doesn't jive with permissions \"${filterpermissions}\""
      return 0
   fi

   log_debug "Node \"${address}\" passed the filters"

   #
   # if we are walking in shared mode, then we fold the address
   # into the shared directory.
   #
   case "${mode}" in
      *noshare*)
      ;;

      *share*)
         if nodemarks_contain_share "${marks}"
         then
            _visit_share_node "$@"
            return $?
         fi

         # if marked noshare, change mode now
         mode="$(sed -e 's/share/noshare/' <<< "${mode}")"
      ;;
   esac


   _visit_node "$@"
}


#
# Mode        | Description
# ------------|---------------------------------------------------------
# docd        | When visiting a node that's a directory cd there for the
#             | callback and recursive walk.
# ------------|---------------------------------------------------------
# recursive   | Visit children of nodes
# ------------|---------------------------------------------------------
# share       | The addresses are modified as when updating share
# ------------|---------------------------------------------------------
#
#
_walk_nodelines()
{
   log_entry "_walk_nodelines" "$@"

   local nodelines="$1"; shift

   local datasource="$1"
   local virtual="$2"
   local mode="$6"

   if ! _print_walk_info "${datasource}" "${nodelines}" "${mode}"
   then
      return
   fi

   IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"

      [ -z "${nodeline}" ] && continue

      if ! _visit_filter_nodeline "${nodeline}" "$@"
      then
         return 1
      fi
   done

   IFS="${DEFAULT_IFS}"
}


_print_walk_info()
{
   log_entry "_print_walk_info" "$@"

   local datasource="$1"
   local nodelines="$2"
   local mode="$3"

   if [ -z "${nodelines}" ]
   then
      if [ -z "${datasource}" ]
      then
         log_fluff "Nothing to walk over ($PWD)"
      else
         log_fluff "Nothing to walk over ($datasource)"
      fi
      return 1
   fi

   case "${mode}" in
      *flat*)
         log_verbose "Flat walk \"${datasource:-.}\""
      ;;

      *)
         case "${mode}" in
            *pre-order*)
               log_verbose "Recursive pre-order walk \"${datasource:-.}\""
            ;;

            *)
               log_verbose "Recursive depth-first walk \"${datasource:-.}\""
            ;;
         esac
      ;;
   esac

   return 0
}


#
# walk_auto_uuid settingname,callback,permissions,SOURCETREE_DB_DIR ...
#
# datasource:  this is the current offset from ${PWD} where the config or
#              database resides  PWD=/
# virtual:     what to prefix addres with. Can be different than datasource
#              also is empty for PWD. (used in shared configuration)
#
#
# datasource
# virtual
# filternodetypes
# filterpermissions
# filtermarks
# mode
# callback
# ...
#
_walk_config_uuids()
{
   log_entry "_walk_config_uuids" "$@"

   local datasource="$1"; shift # !
   local virtual="$1"; shift # !

   local nodelines

   nodelines="`cfg_read "${datasource}"`"
   _walk_nodelines "${nodelines}" "${datasource}" "${virtual}" "$@"
}


walk_config_uuids()
{
   log_entry "walk_config_uuids" "$@"

   local VISITED

   VISITED=
   _walk_config_uuids "/" "" "$@"
}


#
# walk_db_uuids
#
#
# datasource
# virtual
# filternodetypes
# filterpermissions
# filtermarks
# mode
# callback
# ...
#
_walk_db_uuids()
{
   log_entry "_walk_db_uuids" "$@"

   local nodelines

   local datasource="$1"; shift
   local virtual="$1"; shift

   nodelines="`db_fetch_all_nodelines "${datasource}"`"
   _walk_nodelines "${nodelines}" "${datasource}" "${virtual}" "$@"
}


walk_db_uuids()
{
   log_entry "walk_db_uuids" "$@"

   local VISITED

   VISITED=
   _walk_db_uuids "/" "" "$@"
}


_visit_root_callback()
{
   log_entry "_visit_root_callback" "$@"

   local virtual=""
   local datasource="/"

   local branch
   local address="."
   local fetchoptions
   local marks
   local nodetype
   local tag
   local url
   local useroptions
   local uuid

   _visit_callback "${datasource}" \
                   "${virtual}" \
                   "" \
                   "" \
                   "" \
                   "${mode}"  \
                   "${callback}" \
                   "$@"
}


sourcetree_walk()
{
   log_entry "sourcetree_walk" "$@"

   local filternodetypes="${1:-ALL}"; shift
   local filterpermissions="${1}"; shift
   local filtermarks="${1:-ANY}"; shift
   local mode="${1}" ; shift
   local callback="${1}"; shift

   [ -z "${mode}" ] && internal_fail "mode can't be empty"

   MULLE_ROOT_DIR="`pwd -P`"
   export MULLE_ROOT_DIR

   case "${mode}" in
      *pre-order*)
         case "${mode}" in
            *callroot*)
               _visit_root_callback "${mode}" "${callback}" "$@"
            ;;
         esac
      ;;
   esac

   case "${mode}" in
      *walkdb*)
         walk_db_uuids "${filternodetypes}" \
                       "${filterpermissions}" \
                       "${filtermarks}" \
                       "${mode}" \
                       "${callback}" \
                       "$@"
      ;;

      *)
         walk_config_uuids "${filternodetypes}" \
                           "${filterpermissions}" \
                           "${filtermarks}" \
                           "${mode}" \
                           "${callback}" \
                           "$@"
      ;;
   esac

   case "${mode}" in
      *pre-order*)
      ;;

      *)
         case "${mode}" in
            *callroot*)
               _visit_root_callback "${mode}" "${callback}" "$@"
            ;;
         esac
      ;;
   esac
}


sourcetree_walk_config_internal()
{
   log_entry "sourcetree_walk_config_internal" "$@"

   sourcetree_walk "" "" "" "$@"
}


sourcetree_walk_main()
{
   log_entry "sourcetree_walk_main" "$@"

   local MULLE_ROOT_DIR

   local OPTION_CALLBACK_ROOT="DEFAULT"
   local OPTION_CD="DEFAULT"
   local OPTION_DEPTH_FIRST="DEFAULT"
   local OPTION_EXTERNAL_CALL="YES"
   local OPTION_LENIENT="YES"
   local OPTION_MARKS="ANY"
   local OPTION_NODETYPES="ALL"
   local OPTION_PERMISSIONS="" # empty!
   local OPTION_WALK_DB="DEFAULT"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            sourcetree_walk_usage
         ;;

         --callback-root)
            OPTION_CALLBACK_ROOT="YES"
         ;;

         --no-callback-root)
            OPTION_CALLBACK_ROOT="NO"
         ;;

         --cd)
            OPTION_CD="YES"
         ;;

         --no-cd)
            OPTION_CD="NO"
         ;;

         --walk-db|--walk-db-dir)
            OPTION_WALK_DB="YES"
         ;;

         --walk-config|--walk-config-file)
            OPTION_WALK_DB="NO"
         ;;

         --depth-first)
            OPTION_DEPTH_FIRST="YES"
         ;;

         --no-depth-first)
            OPTION_DEPTH_FIRST="NO"
         ;;

         -l|--lenient)
            OPTION_LENIENT="YES"
         ;;

         --no-lenient)
            OPTION_LENIENT="NO"
         ;;


         #
         # filter flags
         #
         -m|--marks)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_MARKS="$1"
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_NODETYPES="$1"
         ;;

         -p|--permissions)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_PERMISSIONS="$1"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown walk option $1"
            sourcetree_walk_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] && sourcetree_walk_usage

   local callback

   callback="$1"
   shift

   local mode

   mode="${SOURCETREE_MODE}"

   if [ "${OPTION_DEPTH_FIRST}" != "NO" ] # is default
   then
      mode="`concat "${mode}" "pre-order"`"
   fi
   if [ "${OPTION_LENIENT}" = "YES" ]
   then
      mode="`concat "${mode}" "lenient"`"
   fi
   if [ "${OPTION_CD}" = "YES" ]
   then
      mode="`concat "${mode}" "docd"`"
   fi
   if [ "${OPTION_EXTERNAL_CALL}" = "YES" ]
   then
      mode="`concat "${mode}" "external"`"
   fi
   if [ "${OPTION_WALK_DB}" = "YES" ]
   then
      mode="`concat "${mode}" "walkdb"`"
   fi
   if [ "${OPTION_CALLBACK_ROOT}" = "YES" ]
   then
      mode="`concat "${mode}" "callroot"`"
   fi

   sourcetree_walk "${OPTION_NODETYPES}" \
                   "${OPTION_PERMISSIONS}" \
                   "${OPTION_MARKS}" \
                   "${mode}" \
                   "${callback}" \
                   "$@"
}


sourcetree_buildorder_main()
{
   log_entry "sourcetree_buildorder_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            sourcetree_buildorder_usage
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown buildorder option $1"
            sourcetree_buildorder_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_buildorder_usage

   sourcetree_walk "" "" "build,${UNAME}" "${SOURCETREE_MODE}" "echo" '${MULLE_DESTINATION}'
}


sourcetree_walk_initialize()
{
   log_entry "sourcetree_walk_initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-db.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh"
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
}


sourcetree_walk_initialize

:

