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
   ${MULLE_USAGE_NAME} walk [options] <shell command>

   Walk over the nodes described by the config file and execute <shell command>
   for each node. The working directory will be the node (if it is a directory).

   Unprocessed node information is passed in the following environment
   variables:

   MULLE_URL  MULLE_ADDRESS  MULLE_BRANCH  MULLE_TAG  MULLE_NODETYPE
   MULLE_UUID  MULLE_MARKS  MULLE_FETCHOPTIONS  MULLE_USERINFO
   MULLE_NODE

   Additional information is passed in:

   MULLE_DESTINATION  MULLE_MODE  MULLE_DATABASE  MULLE_PROJECTDIR  MULLE_ROOT_DIR.

   There is a little qualifier language available to query the marks of a node.
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = "YES" ]
   then
         cat <<EOF >&2
   The syntax is:
      <expr>  : <sexpr> AND <expr>
              | <sexpr> OR <expr>
              | <sexpr>
              ;

      <sexpr> : (<expr>)
              | NOT <sexpr>
              | MATCHES <pattern>
              ;

      <pattern> | <mark> '*'
                | <mark>
                ;

      <mark>    | only-[a-z-]*
                | not-[a-z-]*
                ;
   AND/OR have the same precedence.
EOF
   fi
         cat <<EOF >&2

Options:
   -n <value>       : node types to walk (default: ALL)
   -p <value>       : specify permissions (missing)
   -m <value>       : marks to match (e.g. build)
   -q <value>       : qualifier for marks to match (e.g. MATCHES build)
   --cd             : change directory to node's working directory
   --lenient        : allow shell command to error
   --pre-order      : walk tree in pre-order  (Root, Left, Right)
   --in-order       : walk tree in in-order (Left, Root, Right)
   --walk-db        : walk over information contained in the database instead
EOF
  exit 1
}


#
# Walkers
#
# Possible permissions: "symlink\nmissing"
# Useful for buildorder it would seem
#
walk_filter_permissions()
{
   log_entry "walk_filter_permissions" "$@"

   local filename="$1"
   local permissions="$2"

   [ -z "${filename}" ] && internal_fail "empty filename"

   if [ ! -e "${filename}" ]
   then
      log_fluff "${filename} does not exist (yet)"
      case "${permissions}" in
         *fail-noexist*)
            fail "Missing \"${filename}\" is not yet fetched."
         ;;

         *warn-noexist*)
            log_verbose "Repository expected in \"${filename}\" is not yet fetched"
            return 0
         ;;

         *skip-noexist*)
            log_fluff "Repository expected in \"${filename}\" is not yet fetched, skipped"
            return 1
         ;;

         *)
            return 0
         ;;
      esac
   fi

   #
   # this check is not good enough for shared stuff
   #
   if [ ! -L "${filename}" ]
   then
      return 0
   fi

   log_fluff "${filename} is a symlink"

   case "${permissions}" in
      *fail-symlink*)
         fail "Missing \"${filename}\" is a symlink."
      ;;

      *warn-symlink*)
         log_verbose "\"${filename}\" is a symlink."
         return 2
      ;;

      *skip-symlink*)
         log_fluff "\"${filename}\" is a symlink, skipped"
         return 1
      ;;

      *descend-symlink*)
         log_fluff "\"${filename}\" is a symlink, will be descended into"
         return 0
      ;;
   esac

   return 2
}


walk_filter_nodetypes()
{
   log_entry "walk_filter_nodetypes" "$@"

   nodetype_filter "$@"
}


#
# you can pass a qualifier of the form <all>;<one>;<none>;<override>
# inside all,one,none,override there are comma separated marks
#
walk_filter_marks()
{
   log_entry "walk_filter_marks" "$@"

   nodemarks_filter_with_qualifier "$@"
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

   old="${PWD}"
   exekutor cd "${directory}"
}

__docd_postamble()
{
   exekutor cd "${old}"
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
# marksqualifier
# mode
# callback
# ...
#
_visit_callback()
{
   log_entry "_visit_callback" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift
   local next_datasource="$1"; shift
   local next_virtual="$1"; shift

   shift 3

   local mode="$1"; shift
   local callback="$1"; shift

   if [ -z "${callback}" ]
   then
      log_debug "No callback, why am I doing this ?"
      return
   fi

   case ",${mode}," in
      *,docd,*)
         local old
         local directory

         if [ -d "${_filename}" ]
         then
            __docd_preamble "${_filename}"
               __call_callback "${datasource}" "${virtual}" "${mode}" "${callback}" "$@"
            __docd_postamble
         else
            log_fluff "\"${_filename}\" not there, so no callback"
         fi
         return
      ;;

      *)
         __call_callback "${datasource}" "${virtual}" "${mode}" "${callback}" "$@"
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
# marksqualifier
# mode
# callback
# ...
#
_visit_recurse()
{
   log_entry "_visit_recurse" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift
   local next_datasource="$1" ; shift
   local next_virtual="$1" ; shift

   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local marksqualifier="$1"; shift
   local mode="$1" ; shift


   case ",${mode}," in
      *,flat,*)
         log_debug "Non-recursive walk doesn't recurse on \"${_address}\""
         return 0
      ;;
   esac

   if ! nodemarks_contain "${_marks}" "recurse"
   then
      log_debug "Do not recurse on \"${virtual}/${_destination}\" due to no-recurse mark"
      return 0
   fi

   #
   # Preserve state and globals vars, so dont subshell
   #
   case ",${mode}," in
      *,walkdb,*)
         _walk_db_uuids "${next_datasource}" \
                        "${next_virtual}" \
                        "${filternodetypes}" \
                        "${filterpermissions}" \
                        "${marksqualifier}" \
                        "${mode}" \
                        "$@"
      ;;

      *)
         _walk_config_uuids "${next_datasource}" \
                            "${next_virtual}" \
                            "${filternodetypes}" \
                            "${filterpermissions}" \
                            "${marksqualifier}" \
                            "${mode}" \
                            "$@"
      ;;
   esac
}


#
# datasource
# virtual
# next_datasource
# next_virtual
# filternodetypes
# filterpermissions
# marksqualifier
# mode
# callback
# ...
#
_visit_node()
{
   log_entry "_visit_node" "$@"

   local datasource="$1"
   local virtual="$2"
   local mode="$8"

   case "${virtual}" in
      */)
         internal_fail "virtual \"${virtual}\" not well formed"
      ;;
   esac

   case "${datasource}" in
      "//")
         internal_fail "datasource \"${datasource}\" not well formed"
      ;;

      "/"|/*/)
      ;;

      *)
         internal_fail "datasource \"${datasource}\" not well formed"
      ;;
   esac

   #
   # filename comes from "environment"
   #
   if [ "${VISIT_TWICE}" != "YES" ]
   then
      case ":${VISITED}:" in
         *\:${_filename}\:*)
            log_fluff "A node \"${_filename}\" has already been visited"
            return 0  # error condition too hard
         ;;
      esac
      VISITED="${VISITED}:${_filename}"
   fi

   case ",${mode}," in
      *,flat,*)
         _visit_callback "$@"
      ;;

      *,in-order,*)
         _visit_recurse "$@"
         _visit_callback "$@"
      ;;

      *,pre-order,*)
         _visit_callback "$@"
         _visit_recurse "$@"
      ;;
   esac
}


#
# datasource          // place of the config/db where we read the nodeline from
# virtual             // same but relative to project and possibly remapped
# filternodetypes
# filterpermissions
# marksqualifier
# mode
# callback
# ...
#
_visit_filter_nodeline()
{
   log_entry "_visit_filter_nodeline" "$@"

   local nodeline="$1"; shift
   local datasource="$1"; shift
   local virtual="$1"; shift
   local filternodetypes="$1" ; shift
   local filterpermissions="$1"; shift
   local marksqualifier="$1"; shift
   local mode="$1"; shift

   # rest are arguments

   [ -z "${nodeline}" ]  && internal_fail "nodeline is empty"
   [ -z "${mode}" ]      && internal_fail "mode is empty"

   #
   # These values are now defined for all the "_" prefix functions
   # that we call from now on!
   #
   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _userinfo
   local _uuid

   nodeline_parse "${nodeline}"

   local _nodeline

   _nodeline="${nodeline}"

   if ! walk_filter_marks "${_marks}" "${marksqualifier}"
   then
      log_fluff "Node \"${_address}\": \"${_marks}\" doesn't jive with marks \"${marksqualifier}\""
      return 0
   fi

   if ! walk_filter_nodetypes "${_nodetype}" "${filternodetypes}"
   then
      log_fluff "Node \"${_address}\": \"${_nodetype}\" doesn't jive with nodetypes \"${filternodetypes}\""
      return 0
   fi


   #
   # if we are walking in shared mode, then we fold the _address
   # into the shared directory.
   #
   case ",${mode}," in
      *,no-share,*)
         internal_fail "shouldn't exist anymore"
      ;;

      *,share,*)
         if nodemarks_contain "${_marks}" "share"
         then
            _visit_share_node "${datasource}" \
                              "${virtual}" \
                              "${filternodetypes}" \
                              "${filterpermissions}" \
                              "${marksqualifier}" \
                              "${mode}" \
                              "$@"
            return $?
         fi

         # if marked share, change mode now
         # mode="$(sed -e 's/share/recurse/' <<< "${mode}")"
      ;;
   esac

   # "value addition" of a quasi global

   local _destination
   local _filename  # always absolute!
   local _virtual_address

   _destination="${_address}"

   local next_virtual

   # must be fast cant use concat
   if [ -z "${virtual}" ]
   then
      next_virtual="${_destination}"
   else
      next_virtual="${virtual}/${_destination}"
   fi

   _virtual_address="${next_virtual}"

   _filename="${next_virtual}"
   case "${_filename}" in
      /*)
         # happens for share all the time
      ;;

      *)
         _filename="${MULLE_VIRTUAL_ROOT}/${_filename}"
      ;;
   esac

   walk_filter_permissions "${_filename}" "${filterpermissions}"
   case $? in
      2)
         mode="${mode} flat"  # don't recurse into symlinks unless asked to
      ;;

      1)
         log_fluff "Node \"${_address}\" with filename \"${_filename}\" doesn't jive with permissions \"${filterpermissions}\""
         return 0
      ;;
   esac

   local next_datasource

   next_datasource="${datasource}${_destination}/"

   _visit_node "${datasource}" \
               "${virtual}" \
               "${next_datasource}" \
               "${next_virtual}" \
               "${filternodetypes}" \
               "${filterpermissions}" \
               "${marksqualifier}" \
               "${mode}" \
               "$@"
}


_visit_share_node()
{
   log_entry "_visit_share_node" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift
   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local marksqualifier="$1"; shift
   local mode="$1" ; shift

#   [ -z "${MULLE_SOURCETREE_SHARE_DIR}" ] && internal_fail "MULLE_SOURCETREE_SHARE_DIR is empty"

   #
   # So the node is shared, so virtual changes
   # The datasource may diverge though..
   #
   local _destination
   local _filename
   local _virtual_address

   _destination="${_address##*/}" # like fast_basename

   local next_virtual

   next_virtual="${MULLE_SOURCETREE_SHARE_DIR}/${_destination}"

   _virtual_address="${next_virtual}"

   _filename="${next_virtual}"
   case "${_filename}" in
      /*)
      ;;

      *)
         _filename="${MULLE_VIRTUAL_ROOT}/${next_virtual}"
      ;;
   esac

   walk_filter_permissions "${_filename}" "${filterpermissions}"
   case $? in
      2)
         local RVAL

         r_comma_concat "${mode}" "flat"  # don't recurse into symlinks unless asked to
         mode="${RVAL}"
      ;;

      1)
         log_fluff "Node \"${_address}\" with filename \"${_filename}\" doesn't jive with permissions \"${filterpermissions}\""
         return 0
      ;;
   esac

   #
   # hacky hack. If shareddir exists visit that.
   # Otherwise optimistically look for it where it would be in
   # recursive mode.
   #
   local next_datasource

   next_datasource="${next_virtual}/"

   if [ ! -e "${_filename}" ]
   then
      local va
      local vaf

      # must be fast can't use concat
      case "${virtual}" in
         "")
            va="${_address}"
            vaf="${MULLE_VIRTUAL_ROOT}/${va}"
         ;;

         /*)
            va="${virtual}/${_address}"
            vaf="${va}"
         ;;

         *)
            va="${virtual}/${_address}"
            vaf="${MULLE_VIRTUAL_ROOT}/${va}"
         ;;
      esac

      if [ -e "${vaf}" ]
      then
         case "${va}" in
            /*)
               next_datasource="${va}/"
            ;;

            *)
               next_datasource="/${va}/"
            ;;
         esac
      else
         log_debug "Visit \"${next_datasource}\" as \"${_filename}\" doesn't exist yet"
      fi
   fi

   _visit_node "${datasource}" \
               "${MULLE_SOURCETREE_SHARE_DIR}" \
               "${next_datasource}" \
               "${next_virtual}" \
               "${filternodetypes}" \
               "${filterpermissions}" \
               "${marksqualifier}" \
               "${mode}" \
               "$@"
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

   set -o noglob ; IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      [ -z "${nodeline}" ] && continue

      if ! _visit_filter_nodeline "${nodeline}" "$@"
      then
         return 1
      fi
   done

   IFS="${DEFAULT_IFS}" ; set +o noglob
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
         log_debug "Nothing to walk over ($PWD)"
      else
         log_debug "Nothing to walk over ($datasource)"
      fi
      return 1
   fi

   case ",${mode}," in
      *,flat,*)
         log_verbose "Flat walk \"${datasource:-.}\""
      ;;

      *,in-order,*)
         log_debug "Recursive depth-first walk \"${datasource:-.}\""
      ;;

      *,pre-order,*)
         log_debug "Recursive pre-order walk \"${datasource:-.}\""
      ;;

      *)
         internal_fail "Mode \"${mode}\" incomplete"
      ;;
   esac

   return 0
}


#
# walk_auto_uuid settingname,callback,permissions,SOURCETREE_DB_NAME ...
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
# marksqualifier
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

   nodelines="`cfg_read "${datasource}" `"
   _walk_nodelines "${nodelines}" "${datasource}" "${virtual}" "$@"
}


walk_config_uuids()
{
   log_entry "walk_config_uuids" "$@"

   local VISITED

   VISITED=
   _walk_config_uuids "${SOURCETREE_START}" "" "$@"
}


#
# walk_db_uuids
#
#
# datasource
# virtual
# filternodetypes
# filterpermissions
# marksqualifier
# mode
# callback
# ...
#
_walk_db_uuids()
{
   log_entry "_walk_db_uuids" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift
   local mode="$4"

   case ",${mode}," in
      *,no-dbcheck,*)
      ;;

      *)
         if cfg_exists "${datasource}" && ! db_is_ready "${datasource}"
         then
            fail "The sourcetree at \"${datasource}\" is not updated fully yet, can not proceed"
         fi
      ;;
   esac

   local nodelines

   nodelines="`db_fetch_all_nodelines "${datasource}" `"
   _walk_nodelines "${nodelines}" "${datasource}" "${virtual}" "$@"
}


walk_db_uuids()
{
   log_entry "walk_db_uuids" "$@"

   local VISITED

   VISITED=
   _walk_db_uuids "${SOURCETREE_START}" "" "$@"
}


_visit_root_callback()
{
   log_entry "_visit_root_callback" "$@"

   local _address="."
   local _branch
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _userinfo
   local _uuid

   _visit_callback "" \
                   "${SOURCETREE_START}" \
                   "" \
                   "" \
                   "" \
                   "" \
                   "" \
                   "$@"
}


sourcetree_walk()
{
   log_entry "sourcetree_walk" "$@"

   local filternodetypes="${1}"; shift
   local filterpermissions="${1}"; shift
   local marksqualifier="${1}"; shift
   local mode="${1}" ; shift
   local callback="${1}"; shift

   [ -z "${mode}" ] && internal_fail "mode can't be empty"

   MULLE_ROOT_DIR="`pwd -P`"
   export MULLE_ROOT_DIR

   #
   # make pre-order default if no order set for share or recurse
   #
   case ",${mode}," in
      ,flat,|*-order,*)
      ;;

      *)
         local RVAL

         r_comma_concat "${mode}" "pre-order"
         mode="${RVAL}"
      ;;
   esac

   case ",${mode}," in
      *,callroot,*)
         case ",${mode}," in
            *,pre-order,*)
               _visit_root_callback "${mode}" "${callback}" "$@"
            ;;
         esac
      ;;
   esac

   case ",${mode}," in
      *,walkdb,*)
         walk_db_uuids "${filternodetypes}" \
                       "${filterpermissions}" \
                       "${marksqualifier}" \
                       "${mode}" \
                       "${callback}" \
                       "$@"
      ;;

      *)
         walk_config_uuids "${filternodetypes}" \
                           "${filterpermissions}" \
                           "${marksqualifier}" \
                           "${mode}" \
                           "${callback}" \
                           "$@"
      ;;
   esac

   case ",${mode}," in
      *,callroot,*)
         case ",${mode}," in
            *,pre-order,*)
            ;;

            *)
               _visit_root_callback "${mode}" "${callback}" "$@"
            ;;
         esac
      ;;
   esac
}


sourcetree_walk_internal()
{
   log_entry "sourcetree_walk_internal" "$@"

   sourcetree_walk "" "" "" "$@"
}


# evil global variable stuff
_sourcetree_convert_marks_to_qualifier()
{
   if [ ! -z "${OPTION_MARKS}" ]
   then
      if [ ! -z "${OPTION_MARKS_QUALIFIER}" ]
      then
         fail "You can not specify --marks and --qualifier at the same time"
      fi

      local mark

      IFS=","; set -o noglob
      for mark in ${OPTION_MARKS}
      do
         local RVAL

         r_concat "${OPTION_MARKS_QUALIFIER}" "MATCHES ${mark}" " AND "
         OPTION_MARKS_QUALIFIER="${RVAL}"
      done
      IFS="${DEFAULT_IFS}"; set +o noglob
   fi
}


sourcetree_walk_main()
{
   log_entry "sourcetree_walk_main" "$@"

   local MULLE_ROOT_DIR

   local OPTION_CALLBACK_ROOT="DEFAULT"
   local OPTION_CD="DEFAULT"
   local OPTION_TRAVERSE_STYLE="PREORDER"
   local OPTION_EXTERNAL_CALL="YES"
   local OPTION_LENIENT="NO"
   local OPTION_MARKS=""
   local OPTION_MARKS_QUALIFIER=""
   local OPTION_NODETYPES=""
   local OPTION_PERMISSIONS="" # empty!
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_EVAL_EXEKUTOR="YES"
   local OPTION_PASS_TECHNICAL_FLAGS="NO"
   local RVAL

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_walk_usage
         ;;

         --callback-root)
            OPTION_CALLBACK_ROOT="YES"
         ;;

         -N|--no-eval-exekutor)
            OPTION_EVAL_EXEKUTOR="NO"
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

         --in-order)
            OPTION_TRAVERSE_STYLE="INORDER"
         ;;

         --pre-order)
            OPTION_TRAVERSE_STYLE="PREORDER"
         ;;

         -l|--lenient)
            OPTION_LENIENT="YES"
         ;;

         --no-lenient)
            OPTION_LENIENT="NO"
         ;;

         --pass-flags)
            OPTION_PASS_TECHNICAL_FLAGS="YES"
         ;;

         --no-pass-flags)
            OPTION_PASS_TECHNICAL_FLAGS="NO"
         ;;

         #
         # filter flags
         #
         -m|--marks)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            r_comma_concat "${OPTION_MARKS}" "$1"
            OPTION_MARKS="${RVAL}"
         ;;

         -q|--qualifier|--marks-qualifier)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_MARKS_QUALIFIER="$1"
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_NODETYPES="$1"
         ;;

         -p|--permissions)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
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

   case "${OPTION_TRAVERSE_STYLE}" in
      "INORDER")
         r_comma_concat "${mode}" "in-order"
         mode="${RVAL}"
      ;;

      *)
         r_comma_concat "${mode}" "pre-order"
         mode="${RVAL}"
      ;;
   esac

   if [ "${OPTION_LENIENT}" = "YES" ]
   then
      r_comma_concat "${mode}" "lenient"
      mode="${RVAL}"
   fi
   if [ "${OPTION_CD}" = "YES" ]
   then
      r_comma_concat "${mode}" "docd"
      mode="${RVAL}"
   fi
   if [ "${OPTION_EXTERNAL_CALL}" = "YES" ]
   then
      r_comma_concat "${mode}" "external"
      mode="${RVAL}"
   fi
   if [ "${OPTION_WALK_DB}" = "YES" ]
   then
      r_comma_concat "${mode}" "walkdb"
      mode="${RVAL}"
   fi
   if [ "${OPTION_CALLBACK_ROOT}" = "YES" ]
   then
      r_comma_concat "${mode}" "callroot"
      mode="${RVAL}"
   fi

   # convert marks into a qualifier with globals
   _sourcetree_convert_marks_to_qualifier

   sourcetree_walk "${OPTION_NODETYPES}" \
                   "${OPTION_PERMISSIONS}" \
                   "${OPTION_MARKS_QUALIFIER}" \
                   "${mode}" \
                   "${callback}" \
                   "$@"
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
   if [ -z "${MULLE_SOURCETREE_CALLBACK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-callback.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-callback.sh" || exit 1
   fi
}


sourcetree_walk_initialize

:

