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
   -m <value>       : specify _marks to match (e.g. build)
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
   * ignore nodes marked as "norequire", whose _address is missing
   * ignore nodes marked as "no${UNAME}" (platform dependent of course)

   In a make based project, this can be used to build everything like this:

      ${MULLE_EXECUTABLE_NAME} buildorder | while read _address
      do
         ( cd "${_address}" ; make ) || break
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

   local _address="$1"
   local permissions="$2"
   local _marks="$3"

   [ -z "${_address}" ] && internal_fail "empty _address"

   local match

   if [ -z "${permissions}" ]
   then
      return
   fi

   if [ ! -e "${_address}" ]
   then
      log_fluff "${_address} does not exist (yet)"
      case "${permissions}" in
         *fail-noexist*)
            fail "Missing \"${_address}\" is not yet fetched."
         ;;

         *warn-noexist*)
            log_verbose "Repository expected in \"${_address}\" is not yet fetched"
            return 0
         ;;

         *skip-noexist*)
            log_fluff "Repository expected in \"${_address}\" is not yet fetched, skipped"
            return 1
         ;;

         *)
            return 0
         ;;
      esac
   fi

   if [ ! -L "${_address}" ]
   then
      return 0
   fi

   log_fluff "${_address} is a symlink"
   case "${permissions}" in
      *fail-symlink*)
         fail "Missing \"${_address}\" is a symlink."
      ;;

      *warn-symlink*)
         log_verbose "\"${_address}\" is a symlink."
         return 0
      ;;

      *skip-symlink*)
         log_fluff "\"${_address}\" is a symlink, skipped"
         return 1
      ;;
   esac

   return 0
}


walk_filter_nodetypes()
{
   log_entry "walk_filter_nodetypes" "$@"

   local _nodetype="$1"
   local allowednodetypes="$2"

   [ -z "${_nodetype}" ] && internal_fail "empty _nodetype"

   if [ "${allowednodetypes}" = "ALL" ]
   then
      return 0
   fi

   nodetypes_contain "${allowednodetypes}" "${_nodetype}"
}


#
# you can pass a qualifier of the form <all>;<one>;<none>
# inside all,one,none are comma separated _marks
#
walk_filter_marks()
{
   log_entry "walk_filter_marks" "$@"

   local _marks="$1"
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
         if ! nodemarks_contain "${_marks}" "${i}"
         then
            return 1
         fi
      done
      IFS="${DEFAULT_IFS}"
   fi

   if [ ! -z "${one}" ]
   then
      if ! nodemarks_intersect "${_marks}" "${one}"
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
         if nodemarks_contain "${_marks}" "${i}"
         then
            return 1
         fi
      done
      IFS="${DEFAULT_IFS}"
   fi
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

#   oldshared=
#   if ! is_absolutepath "${MULLE_SOURCETREE_SHARE_DIR}"
#   then
#      oldshared="${MULLE_SOURCETREE_SHARE_DIR}"
#
#      local relative
#
#      relative="`compute_relative "${directory}"`"
#      MULLE_SOURCETREE_SHARE_DIR="`filepath_concat "${MULLE_SOURCETREE_SHARE_DIR}" "${relative}"`"
#      MULLE_SOURCETREE_SHARE_DIR="`simplified_path "${MULLE_SOURCETREE_SHARE_DIR}"`"
#   fi

   old="${PWD}"
   exekutor cd "${directory}"
}

__docd_postamble()
{
   exekutor cd "${old}"
#   if [ ! -z "${oldshared}" ]
#   then
#      MULLE_SOURCETREE_SHARE_DIR="${oldshared}"
#   fi
}


#
# "cheat" and read global _ values defined in _visit_node and friends
# w/o passing them explicitly
#
__call_callback()
{
   log_entry "__call_callback" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift
   local mode="$1"; shift
   local callback="$1"; shift

   [ -z "${callback}" ]  && internal_fail "callback is empty"

   local evaluator

   if [ "${OPTION_EVAL_EXEKUTOR}" = "YES" ]
   then
      evaluator="_eval_exekutor"
   else
      evaluator="eval"
   fi

   local technical_flags

   if [ "${OPTION_PASS_TECHNICAL_FLAGS}" = "YES" ]
   then
      technical_flags="${MULLE_TECHNICAL_OPTIONS}" # from bashfunctions
   fi

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" ]
   then
      log_trace2 "MULLE_ADDRESS:         \"${_address}\""
      log_trace2 "MULLE_BRANCH:          \"${_branch}\""
      log_trace2 "MULLE_DATASOURCE:      \"${datasource}\""
      log_trace2 "MULLE_DESTINATION:     \"${_destination}\""
      log_trace2 "MULLE_FETCHOPTIONS:    \"${_fetchoptions}\""
      log_trace2 "MULLE_FILENAME:        \"${_filename}\""
      log_trace2 "MULLE_MARKS:           \"${_marks}\""
      log_trace2 "MULLE_MODE:            \"${mode}\""
      log_trace2 "MULLE_NODE:            \"${_nodeline}\""
      log_trace2 "MULLE_NODETYPE:        \"${_nodetype}\""
      log_trace2 "MULLE_TAG:             \"${_tag}\""
      log_trace2 "MULLE_URL:             \"${_url}\""
      log_trace2 "MULLE_USERINFO:        \"${_userinfo}\""
      log_trace2 "MULLE_UUID:            \"${_uuid}\""
      log_trace2 "MULLE_VIRTUAL:         \"${virtual}\""
      log_trace2 "MULLE_VIRTUAL_ADDRESS: \"${_virtual_address}\""
   fi

   #
   # MULLE_NODE the current nodelines from config or database, unchanged
   #
   # MULLE_ADDRESS-MULLE_UUID as defined in nodeline, unchanged
   #
   # MULLE_DATASOURCE  : config or database "handle" where nodelines was read
   # MULLE_DESTINATION : either "_address" or in shared case basename of "_address"
   # MULLE_VIRTUAL     : either ${MULLE_SOURECTREE_SHARE_DIR} or ${MULLE_PROJECTDIR}
   #
   #
   MULLE_NODE="${_nodeline}" \
   MULLE_ADDRESS="${_address}" \
   MULLE_BRANCH="${_branch}" \
   MULLE_FETCHOPTIONS="${_fetchoptions}" \
   MULLE_MARKS="${_marks}" \
   MULLE_NODETYPE="${_nodetype}" \
   MULLE_URL="${_url}" \
   MULLE_USERINFO="${_userinfo}" \
   MULLE_TAG="${_tag}" \
   MULLE_UUID="${_uuid}" \
   MULLE_DATASOURCE="${datasource}" \
   MULLE_DESTINATION="${_destination}" \
   MULLE_FILENAME="${_filename}" \
   MULLE_MODE="${mode}" \
   MULLE_VIRTUAL="${virtual}" \
   MULLE_VIRTUAL_ADDRESS="${_virtual_address}" \
      "${evaluator}" "'${callback}'" "${technical_flags}" "$@"

   rval="$?"
   if [ "${rval}" -eq 0 ]
   then
      return 0
   fi

   case "${mode}" in
      *lenient*)
         log_warning "Command '${callback}' failed for node \"${_address}\""
         return 0
      ;;
   esac

   fail "Command '${callback}' failed for node \"${_address}\""

   return "$rval"
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

   case "${mode}" in
      *docd*)
         local old
         local directory

         if [ -d "${filename}" ]
         then
            __docd_preamble "${filename}"
               __call_callback "${datasource}" "${virtual}" "${mode}" "${callback}" "$@"
            __docd_postamble
         else
            log_fluff "\"${filename}\" not there, so no callback"
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
   local next_datasource="$1" ; shift
   local next_virtual="$1" ; shift

   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local filtermarks="$1"; shift
   local mode="$1" ; shift


   case "${mode}" in
      *flat*)
         log_debug "Non-recursive walk doesn't recurse on \"${_address}\""
         return 0
      ;;
   esac

   if nodemarks_contain_norecurse "${_marks}"
   then
      log_debug "Do not recurse on \"${virtual}/${_destination}\" due to norecurse mark"
      return 0
   fi

   #
   # Preserve state and globals vars, so dont subshell
   #
   case "${mode}" in
      *walkdb*)
         _walk_db_uuids "${next_datasource}" \
                        "${next_virtual}" \
                        "${filternodetypes}" \
                        "${filterpermissions}" \
                        "${filtermarks}" \
                        "${mode}" \
                        "$@"
      ;;

      *)
         _walk_config_uuids "${next_datasource}" \
                            "${next_virtual}" \
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
# next_datasource
# next_virtual
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

   local mode="$8"

   # filename comes from "environment"
   if [ "${VISIT_TWICE}" != "YES" ]
   then
      if fgrep -q -s -x "${_filename}" <<< "${VISITED}"
      then
         return 1
      fi
      VISITED="`add_line "${VISITED}" "${_filename}"`"
   fi

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


pretty_datasource()
{
   local datasource="$1"

   case "${datasource}" in
      /*)
      ;;

      *)
         datasource="/${datasource}"
      ;;
   esac

   case "${datasource}" in
      */)
      ;;

      *)
         datasource="${datasource}/"
      ;;
   esac

   echo "${datasource}"
}

#
# datasource          // place of the config/db where we read the nodeline from
# virtual             // same but relative to project and possibly remapped
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

   local datasource="$1"; shift
   local virtual="$1"; shift

   local filternodetypes="$1"
   local filterpermissions="$2"
   local filtermarks="$3"
   local mode="$4"

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

   if ! walk_filter_marks "${_marks}" "${filtermarks}"
   then
      log_fluff "Node \"${_address}\": \"${_marks}\" doesn't jive with _marks \"${filtermarks}\""
      return 0
   fi

   if ! walk_filter_nodetypes "${_nodetype}" "${filternodetypes}"
   then
      log_fluff "Node \"${_address}\": \"${_nodetype}\" doesn't jive with nodetypes \"${filternodetypes}\""
      return 0
   fi

   if ! walk_filter_permissions "${_address}" "${filterpermissions}"
   then
      log_fluff "Node \"${_address}\": \"${_address}\" doesn't jive with permissions \"${filterpermissions}\""
      return 0
   fi

   log_debug "Node \"${_address}\" passed the filters"

   #
   # if we are walking in shared mode, then we fold the _address
   # into the shared directory.
   #
   case "${mode}" in
      *noshare*)
         internal_fail "shouldn't exist anymore"
      ;;

      *share*)
         if nodemarks_contain_share "${_marks}"
         then
            _visit_share_node "${datasource}" "${virtual}" "$@"
            return $?
         fi

         # if marked share, change mode now
         mode="$(sed -e 's/share/recurse/' <<< "${mode}")"
      ;;
   esac

   # "value addition" of a quasi global

   local _destination

   _destination="${_address}"

   local next_datasource
   local next_virtual

   next_datasource="`filepath_concat "${datasource}" "${_destination}" `"
   next_datasource="`pretty_datasource "${next_datasource}" `"

   next_virtual="`filepath_concat "${virtual}" "${_destination}" `"

   # another quasi global

   local _filename  # always absolute!
   local _virtual_address

   _virtual_address="${next_virtual}"

   _filename="${next_virtual}"
   if ! is_absolutepath "${_filename}"
   then
      _filename="`filepath_concat "${MULLE_VIRTUAL_ROOT}" "${_filename}" `"
   fi

   _visit_node "${datasource}" \
               "${virtual}" \
               "${next_datasource}" \
               "${next_virtual}" \
               "$@"
}


_visit_share_node()
{
   log_entry "_visit_share_node" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift

   local mode="$4"

#   [ -z "${MULLE_SOURCETREE_SHARE_DIR}" ] && internal_fail "MULLE_SOURCETREE_SHARE_DIR is empty"

   #
   # So the node is shared so, virtual changes
   # The datasource may diverge though..

   local _destination
   local _filename

   _destination="`basename -- "${_address}"`"

   local next_virtual

   next_virtual="`filepath_concat "${MULLE_SOURCETREE_SHARE_DIR}" "${_destination}" `"

   local _virtual_address

   _virtual_address="${next_virtual}"

   _filename="${next_virtual}"
   if ! is_absolutepath "${_filename}"
   then
      _filename="`filepath_concat "${MULLE_VIRTUAL_ROOT}" "${next_virtual}" `"
   fi

   #
   # hacky hack. If shareddir exists visit that.
   # Otherwise optimistically look for it where it would be in
   # recursive mode.
   #
   local next_datasource

   next_datasource="${next_virtual}"

   if [ ! -e "${_filename}" ]
   then
      local optimistic

      optimistic="`filepath_concat "${MULLE_VIRTUAL_ROOT}" "${virtual}" "${_address}" `"
      if [ -e "${optimistic}" ]
      then
         next_datasource="`filepath_concat "${virtual}" "${_address}" `"

         log_debug "Visit \"${next_datasource}\" as \"${_filename}\" doesn't exist yet"
      fi
   fi

   next_datasource="`pretty_datasource "${next_datasource}" `"
   _visit_node "${datasource}" \
               "${MULLE_SOURCETREE_SHARE_DIR}" \
               "${next_datasource}" \
               "${next_virtual}" \
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
   local OPTION_DEPTH_FIRST="YES"
   local OPTION_EXTERNAL_CALL="YES"
   local OPTION_LENIENT="NO"
   local OPTION_MARKS="ANY"
   local OPTION_NODETYPES="ALL"
   local OPTION_PERMISSIONS="" # empty!
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_EVAL_EXEKUTOR="YES"
   local OPTION_PASS_TECHNICAL_FLAGS="NO"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
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

   if [ "${OPTION_DEPTH_FIRST}" = "NO" ] # is default
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

   local OPTION_MARKS="NO"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            sourcetree_buildorder_usage
         ;;

         --marks)
            OPTION_MARKS="YES"
         ;;

         --no-marks)
            OPTION_MARKS="NO"
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

   if [ "${OPTION_MARKS}" = "YES" ]
   then
      sourcetree_walk "" "" "build,${UNAME}" "${SOURCETREE_MODE}" \
         "echo" '"${MULLE_VIRTUAL_ADDRESS};${MULLE_MARKS}"'
   else
      sourcetree_walk "" "" "build,${UNAME}" "${SOURCETREE_MODE}" \
         "echo" '"${MULLE_VIRTUAL_ADDRESS}"'
   fi
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

