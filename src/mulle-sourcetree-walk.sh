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

   MULLE_URL, MULLE_RAW_DSTFILE, MULLE_BRANCH, MULLE_TAG, MULLE_NODETYPE,
   MULLE_UUID, MULLE_MARKS, MULLE_FETCHOPTIONS, MULLE_USERINFO
   MULLE_NODE

   Additional processed information is passed in:

   MULLE_DSTFILE and MULLE_ROOT_DIR.

Options:
   -n <value>       : node types to walk (default: ALL)
   -p <value>       : specify permissions (missing)
   -m <value>       : specify marks to match (e.g. build)
   --no-depth-first : walk tree breadth first
   --internal       : callback gets internal parameter scheme
   --lenient        : allow shell command to error
   --no-cd          : don't cd into node's working directory
   --no-prefix      : do not prefix MULLE_DSTFILE
   --no-recurse     : do not recurse
   --walk-db-dir    : walk over information contained in the database instead
EOF
  exit 1
}


sourcetree_buildorder_main()
{
   cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} buildorder

   Print all sourcetree addresss according to the following rules:

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

   nodetype_intersect_nodetypes "${nodetype}" "${allowednodetypes}"
}


walk_filter_marks()
{
   log_entry "walk_filter_marks" "$@"

   local marks="$1"
   local anymarks="$2"

   if [ "${anymarks}" = "ANY" ]
   then
      return 0
   fi

   nodemarks_intersect "${marks}" "${anymarks}"
}


#
# useful for running git on the repos or so
#
__call_external()
{
   log_entry "__call_external" "$@"

   local callback="${1}"; shift

   MULLE_NODE="${nodeline}" \
   MULLE_URL="${url}" \
   MULLE_DSTFILE="${prefixed}" \
   MULLE_RAW_DSTFILE="${address}" \
   MULLE_BRANCH="${branch}" \
   MULLE_TAG="${tag}" \
   MULLE_NODETYPE="${nodetype}" \
   MULLE_UUID="${uuid}" \
   MULLE_MARKS="${marks}" \
   MULLE_FETCHOPTIONS="${fetchoptions}" \
   MULLE_USERINFO="${userinfo}" \
      eval_exekutor "${callback}" "$@"
}


#
# "cheat" and read values defined in _visit_nodeline
# w/o passing them
#
__call_internal()
{
   log_entry "__call_internal" "$@"

   local callback="${1}"; shift

   NODE="${nodeline}" \
   RAW_DSTFILE="${address}" \
      "${callback}" ${OPTION_CALLBACK_FLAGS} \
                    "${url}" \
                    "${prefixed}" \
                    "${branch}" \
                    "${tag}" \
                    "${nodetype}" \
                    "${marks}" \
                    "${fetchoptions}" \
                    "${useroptions}" \
                    "${uuid}" \
                    "$@"
}


_visit_callback()
{
   log_entry "_visit_callback" "$@"

   local callback="$1"; shift
   local address="$1"; shift
   local mode="$1"; shift

   local rval
   local old

   case "${mode}" in
      *external*)
         if [ -d "${address}" ]
         then
            case "${mode}" in
               *docd*)
                  (
                     exekutor cd "${address}" &&
                     __call_external "${callback}" "$@"
                  )
                  return "$?"
               ;;
            esac
         fi

         __call_external "${callback}" "$@"
         return $?
      ;;
   esac

   if [ -d "${address}" ]
   then
      case "${mode}" in
         *docd*)
            # internally we want to preserve state and globals vars
            # so dont subshell
            old="${PWD}"
            exekutor cd "${address}" &&
            __call_internal "${callback}" "$@"
            rval="$?"
            cd "${old}"
            return $rval
         ;;
      esac
   fi

   __call_internal "${callback}" "$@"
}


_visit_recurse()
{
   log_entry "_visit_recurse" "$@"

   local prefixed="$1"; shift
   local marks="$1"; shift
   local address="$1"; shift

   local prefix="$1"; shift
   local callback="$1"; shift
   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local filtermarks="$1"; shift
   local mode="$1" ; shift

   case "${mode}" in
      *recurse*)
         if nodemarks_contain_norecurse "${marks}"
         then
            log_debug "Do not recurse on \"${prefixed}\" due to norecurse mark"
            return 0
         fi

         if ! [ -d "${prefixed}" ]
         then
            if [ -f "${prefixed}" ]
            then
               log_fluff "Do not recurse on \"${prefixed}\" as it's not a directory. ($PWD)"
            else
               log_debug "Can not recurse into \"${prefixed}\" as it's not there yet. ($PWD)"
            fi
            return 0
         fi
      ;;

      *)
         log_debug "Non-recursive walk doesn't recurse on \"${prefixed}\""
         return 0
      ;;
   esac

   #
   # internally we want to preserve state and globals vars
   # so dont subshell
   #
   local old
   local rval

   case "${mode}" in
      *docd*)
         old="${PWD}"
         cd "${address}" || return 1
      ;;

      *prefix*)
         prefix="${prefixed}/"
      ;;
   esac

   case "${mode}" in
      *walkdb*)
         _walk_db_uuids "${prefix}" \
                        "${callback}" \
                        "${filternodetypes}" \
                        "${filterpermissions}" \
                        "${filtermarks}" \
                        "${mode}" \
                        "$@"
      ;;

      *)
         _walk_config_uuids "${prefix}" \
                            "${callback}" \
                            "${filternodetypes}" \
                            "${filterpermissions}" \
                            "${filtermarks}" \
                            "${mode}" \
                            "$@"
      ;;
   esac
   rval="$?"

   case "${mode}" in
      *docd*)
         cd "${old}" || return 1
      ;;
   esac

   return $rval
}


_visit_nodeline()
{
   log_entry "_visit_nodeline" "$@"

   local prefix="$1"; shift
   local nodeline="$1"; shift

   local callback="${1}"; shift
   local filternodetypes="${1:-ALL}"; shift
   local filterpermissions="${1}"; shift
   local filtermarks="${1:-ANY}"; shift
   local mode="${1}" ; shift

   # rest are arguments

   [ -z "${callback}" ]  && internal_fail "callback is empty"
   [ -z "${nodeline}" ]  && internal_fail "nodeline is empty"

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
      log_fluff "Node \"${url}\": \"${marks}\" doesn't jive with marks \"${filtermarks}\""
      return 0
   fi

   if ! walk_filter_nodetypes "${nodetype}" "${filternodetypes}"
   then
      log_fluff "Node \"${url}\": \"${nodetype}\" doesn't jive with nodetypes \"${filternodetypes}\""
      return 0
   fi

   if ! walk_filter_permissions "${address}" "${filterpermissions}"
   then
      log_fluff "Node \"${url}\": \"${address}\" doesn't jive with permissions \"${filterpermissions}\""
      return 0
   fi

   log_debug "Node \"${url}\" passed the filter"

   local prefixed

   # will be used by __call_internal
   prefixed="${address}"
   case "${mode}" in
      *docd*)
         # if we cd into, prefixing is pointless
      ;;

      *prefix*)
         prefixed="${prefix}${address}"
      ;;
   esac

   #
   # depth-first recurses before calling callback
   #
   case "${mode}" in
      *depth-first*)
         if ! _visit_recurse "${prefixed}" \
                             "${marks}" \
                             "${address}" \
\
                             "${prefix}" \
                             "${callback}" \
                             "${filternodetypes}" \
                             "${filterpermissions}" \
                             "${filtermarks}" \
                             "${mode}" \
                             "$@"
         then
            return 1
         fi
      ;;
   esac

   _visit_callback "${callback}" \
                   "${address}" \
                   "${mode}" \
                   "$@"
   rval=$?

   if [ ${rval} -ne 0 ]
   then
      case "${mode}" in
         *lenient*)
            log_warning "Command '${callback}' failed for \"${prefixed}\""
         ;;

         *)
            fail "Command '${callback}' failed for \"${prefixed}\""
            return 1
         ;;
      esac
   fi

   case "${mode}" in
      *depth-first*)
         return
      ;;
   esac

   _visit_recurse "${prefixed}" \
                  "${marks}" \
                  "${address}" \
\
                  "${prefix}" \
                  "${callback}" \
                  "${filternodetypes}" \
                  "${filterpermissions}" \
                  "${filtermarks}" \
                  "${mode}" \
                  "$@"
}


_walk_nodelines()
{
   log_entry "_walk_nodelines" "$@"

   local prefix="$1"; shift
   local nodelines="$1"; shift

   IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"

      [ -z "${nodeline}" ] && continue

      if ! _visit_nodeline "${prefix}" "${nodeline}" "$@"
      then
         return 1
      fi
   done

   IFS="${DEFAULT_IFS}"
}


_print_walk_info()
{
   local prefix="$1"
   local nodelines="$2"
   local mode="$3"

   if [ -z "${nodelines}" ]
   then
      if [ -z "${prefix}" ]
      then
         log_info "Nothing to walk over"
      else
         log_fluff "Nothing to walk over ($PWD)"
      fi
      return 1
   fi

   case "${mode}" in
      *recurse*)
         log_verbose "Recursive walk \"${prefix:-.}\""
      ;;

      *)
         log_verbose "Flat walk \"${prefix:-.}\""
      ;;
   esac

   return 0
}


#
# walk_auto_uuid settingname,callback,permissions,SOURCETREE_DB_DIR ...
#
_walk_config_uuids()
{
   log_entry "_walk_config_uuids" "$@"

   local nodelines

   local prefix="$1"; shift
   local mode="$5"

   case "${prefix}" in
      */|"")
      ;;

      *)
         prefix="${prefix}/"
      ;;
   esac

   nodelines="`nodeline_config_read "${prefix}"`"
   if ! _print_walk_info "${prefix}" "${nodelines}" "${mode}"
   then
      return
   fi

   _walk_nodelines "${prefix}" "${nodelines}" "$@"
}


walk_config_uuids()
{
   log_entry "walk_config_uuids" "$@"

   _walk_config_uuids "" "$@"
}


#
# walk_db_uuids unused,callback,permissions,SOURCETREE_DB_DIR ...
#
_walk_db_uuids()
{
   log_entry "_walk_db_uuids" "$@"

   local nodelines

   local prefix="$1"; shift
   case "${prefix}" in
      */|"")
      ;;

      *)
         prefix="${prefix}/"
      ;;
   esac

   nodelines="`db_get_all_nodelines "${prefix}"`"
   if ! _print_walk_info "${prefix}" "${nodelines}" "${mode}"
   then
      return
   fi

   _walk_nodelines "${prefix}" "${nodelines}" "$@"
}


walk_db_uuids()
{
   log_entry "walk_db_uuids" "$@"

   _walk_db_uuids "" "$@"
}


sourcetree_walk_main()
{
   log_entry "sourcetree_walk_main" "$@"

   local MULLE_ROOT_DIR

   MULLE_ROOT_DIR="`pwd -P`"
   export MULLE_ROOT_DIR

   local OPTION_MARKS="ANY"
   local OPTION_PERMISSIONS="" # empty!
   local OPTION_NODETYPES="ALL"
   local OPTION_CD="DEFAULT"
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_RECURSIVE
   local OPTION_CALLBACK_FLAGS
   local OPTION_EXTERNAL_CALL="YES"
   local OPTION_LENIENT="YES"
   local OPTION_PREFIX="YES"
   local OPTION_DEPTH_FIRST="DEFAULT"

   _db_set_default_options

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            sourcetree_walk_usage
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

         --internal)
            OPTION_EXTERNAL_CALL="NO"
         ;;

         --external)
            OPTION_EXTERNAL_CALL="YES"
         ;;

         --depth-first)
            OPTION_DEPTH_FIRST="YES"
         ;;

         --no-depth-first)
            OPTION_DEPTH_FIRST="NO"
         ;;

         --no-prefix)
            OPTION_PREFIX="NO"
         ;;

         --no-lenient)
            OPTION_LENIENT="NO"
         ;;

         --callback-flags)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_CALLBACK_FLAGS="$1"
         ;;

         #
         # more common flags
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

         -l|--lenient)
            OPTION_LENIENT="YES"
         ;;

         -r|--recurse|--recursive)
            OPTION_RECURSIVE="YES"
         ;;

         --no-recurse|--no-recursive)
            OPTION_RECURSIVE="NO"
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

   mode=""

   if [ "${OPTION_RECURSIVE}" = "YES" ]
   then
      mode="`concat "${mode}" "recurse"`"
   fi
   if [ "${OPTION_DEPTH_FIRST}" != "NO" ] # is default
   then
      mode="`concat "${mode}" "depth-first"`"
   fi
   if [ "${OPTION_PREFIX}" = "YES" ]
   then
      mode="`concat "${mode}" "prefix"`"
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
       walk_db_uuids "${callback}" \
                     "${OPTION_NODETYPES}" \
                     "${OPTION_PERMISSIONS}" \
                     "${OPTION_MARKS}" \
                     "${mode}" \
                     "$@"
   else
       walk_config_uuids "${callback}" \
                         "${OPTION_NODETYPES}" \
                         "${OPTION_PERMISSIONS}" \
                         "${OPTION_MARKS}" \
                         "${mode}" \
                         "$@"
   fi
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

   [ "$#" -eq 0 ] && sourcetree_buildorder_usage

   sourcetree_walk_main -m "nobuild no${UNAME}" "echo '${MULLE_DSTFILE}'"
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

