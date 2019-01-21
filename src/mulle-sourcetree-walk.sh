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
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} walk [options] <shell command>

   Walk over the nodes described by the config file and execute <shell command>
   for each node. Unprocessed node information is passed in the following
   environment variables: MULLE_URL, MULLE_ADDRESS, MULLE_BRANCH, MULLE_TAG,
   MULLE_NODETYPE, MULLE_UUID, MULLE_MARKS, MULLE_FETCHOPTIONS, MULLE_USERINFO,
   MULLE_NODE.  Additional information is passed in: MULLE_DESTINATION,
   MULLE_MODE, MULLE_FILENAME, MULLE_DATABASE, MULLE_ROOT_DIR.

   The working directory will be the node (if it's a directory).

   This example dumps the full information of each node:

      mulle-sourcetree walk 'echo "\${MULLE_NODE}"'

   This example finds the location of a dependency named foo:

      mulle-sourcetree walk --lenient '[ "\${MULLE_ADDRESS}" = "foo" ] && \\
                                          echo "\${MULLE_FILENAME}"'

   There is a little qualifier language available to query the marks of a node.
EOF
   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      cat <<EOF >&2
   The syntax of a qualifier is:
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
   else
      cat <<EOF >&2
   (Use -v for more info about the qualifier language)
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
   --breadth-first  : walk tree breadth first (first all top levels)
   --walk-db        : walk over information contained in the database instead
EOF
  exit 1
}


#
# Walkers
#
# Possible permissions: "symlink,missing"
# Useful for buildorder it would seem
#


walk_filter_visit_permissions()
{
   log_entry "walk_filter_visit_permissions" "$@"

   local permissions="$1"
   local filename="$2"
   local marks="$3"


   [ -z "${filename}" ] && internal_fail "empty filename"

   # it should be faster to put [ -e ] into each case statement
   case ",${permissions}," in
      *,fail-noexist,*)
         if [ ! -e "${filename}" ]
         then
            fail "Missing \"${filename}\" is not yet fetched."
         fi
      ;;

      *,warn-noexist,*)
         if [ ! -e "${filename}" ]
         then
            log_warning "Repository expected in \"${filename}\" is not yet \
fetched"
            return 0
         fi
      ;;

      *,skip-noexist,*)
         if [ ! -e "${filename}" ]
         then
            log_fluff "Repository expected in \"${filename}\" is not yet \
fetched, skipped"
            return 1
         fi
      ;;
   esac

   case ",${permissions}," in
      *,fail-symlink,*)
         if [ -L "${filename}" ]
         then
            fail "\"${filename}\" is a symlink."
         fi
      ;;

      *,warn-symlink,*)
         if [ -L "${filename}" ]
         then
            log_warning "\"${filename}\" is a symlink."
            return 2    # make traversal flat (i.e. don't descent)
         fi
      ;;
   esac

   log_debug "\"${filename}\" returns with $rval"
   return 0
}


walk_filter_descend_permissions()
{
   log_entry "walk_filter_descend_permissions" "$@"

   local permissions="$1"
   local filename="$2"
   local marks="$3"

   local rval

   rval=0

   case ",${permissions}," in
      *,descend-mark,*)
         if nodemarks_contain "${marks}" "no-descend"
         then
            log_debug "permission \"descend-mark\" and mark \"no-descend\" match"
            rval=2
         fi
      ;;
   esac

   [ -z "${filename}" ] && internal_fail "empty filename"

   case ",${permissions}," in
      *,fail-noexist,*)
         if [ ! -e "${filename}" ]
         then
            fail "Missing \"${filename}\" is not yet fetched."
         fi
      ;;

      *,skip-noexist,*)
         if [ ! -e "${filename}" ]
         then
            log_fluff "Repository expected in \"${filename}\" is not yet \
fetched, skipped"
            return 1
         fi
      ;;
   esac

   if [ -L "${filename}" ]
   then
      case ",${permissions}," in
         *,fail-symlink,*)
            fail "\"${filename}\" is a symlink."
         ;;

         *,descend-symlink,*)
            log_debug "\"${filename}\" is a symlink - it will be descended into."
            return $rval
         ;;

         *)
            log_fluff "\"${filename}\" is a symlink, skipped."
            return 1
         ;;
      esac
   fi

   log_debug "\"${filename}\" returns with $rval"
   return $rval
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
# Easier to pass all in, because we need the trailing args to pass
#
# datasource
# virtual
# filternodetypes
# filterpermissions
# visitqualifier
# descendqualifier
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

   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local visitqualifier="$1"; shift
   local descendqualifier="$1"; shift
   local mode="$1" ; shift

   local callback="$1"; shift

   if [ -z "${callback}" ]
   then
      log_debug "No callback, why am I doing this ?"
      return 0
   fi

   if ! walk_filter_marks "${_marks}" "${visitqualifier}"
   then
      log_fluff "Node \"${_address}\": \"${_marks}\" doesn't jive with marks \"${visitqualifier}\""
      return 0
   fi

   if ! walk_filter_nodetypes "${_nodetype}" "${filternodetypes}"
   then
      log_fluff "Node \"${_address}\": \"${_nodetype}\" doesn't jive with nodetypes \"${filternodetypes}\""
      return 0
   fi

   local rval

   rval=0
   case ",${mode}," in
      *,docd,*)
         local old
         local directory

         if [ -d "${_filename}" ]
         then
            __docd_preamble "${_filename}"
               __call_callback "${datasource}" "${virtual}" "${mode}" "${callback}" "$@"
               rval=$?
            __docd_postamble
         else
            log_fluff "\"${_filename}\" not there, so no callback"
         fi
      ;;

      *)
         __call_callback "${datasource}" "${virtual}" "${mode}" "${callback}" "$@"
         rval=$?
      ;;
   esac

   if [ "${rval}" -ne 0 ]
   then
      log_fluff "Callback returned non-zero, walk will terminate"
   fi
   return $rval
}


#
# this should always return 0
#
#
# datasource
# virtual
# filternodetypes
# filterpermissions
# visitqualifier
# descendqualifier
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
   local visitqualifier="$1"; shift
   local descendqualifier="$1"; shift
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

   if ! walk_filter_marks "${_marks}" "${descendqualifier}"
   then
      log_fluff "Node \"${_address}\": \"${_marks}\" doesn't jive with marks \"${descendqualifier}\""
      return 0
   fi

   walk_filter_descend_permissions "${filterpermissions}" "${_filename}" "${_marks}"
   case $? in
      2)
         r_comma_concat "${mode}" "flat"  # don't recurse now
         mode="${RVAL}"
      ;;

      1)
         # filter should have fluffed already
         log_debug "Node \"${_address}\" with filename \"${_filename}\" \
doesn't jive with permissions \"${filterpermissions}\""
         return 0
      ;;
   esac

   if [ ! -z "${WILL_RECURSE_CALLBACK}" ]
   then
      if ! "${WILL_RECURSE_CALLBACK}" "${next_datasource}" \
                                      "${next_virtual}" \
                                      "${filternodetypes}" \
                                      "${filterpermissions}" \
                                      "${visitqualifier}" \
                                      "${descendqualifier}" \
                                      "${mode}" \
                                      "$@"
      then
         log_debug "Do not visit on \"${virtual}/${_destination}\" due to WILL_RECURSE_CALLBACK"
         return 0 # only callback can stop the train though
      fi
   fi

   local rval

   #
   # Preserve state and globals vars, so dont subshell
   #
   MULLE_WALK_INDENT="${MULLE_WALK_INDENT} "

   case ",${mode}," in
      *,walkdb,*)
         _walk_db_uuids "${next_datasource}" \
                        "${next_virtual}" \
                        "${filternodetypes}" \
                        "${filterpermissions}" \
                        "${visitqualifier}" \
                        "${descendqualifier}" \
                        "${mode}" \
                        "$@"
         rval=$?
      ;;

      *)
         _walk_config_uuids "${next_datasource}" \
                            "${next_virtual}" \
                            "${filternodetypes}" \
                            "${filterpermissions}" \
                            "${visitqualifier}" \
                            "${descendqualifier}" \
                            "${mode}" \
                            "$@"
         rval=$?
      ;;
   esac

   MULLE_WALK_INDENT="${MULLE_WALK_INDENT%?}"

   if [ ! -z "${DID_RECURSE_CALLBACK}" ]
   then
      "${DID_RECURSE_CALLBACK}" "${next_datasource}" \
                                "${next_virtual}" \
                                "${filternodetypes}" \
                                "${filterpermissions}" \
                                "${visitqualifier}" \
                                "${descendqualifier}" \
                                "${mode}" \
                                "${rval}" \
                                "$@"
   fi

   return $rval
}


r_visit_line_from_node()
{
   case "${WALK_DEDUPE_MODE}" in
      ''|'none')
         RVAL=
         return 1
      ;;

      'nodeline')
         RVAL="${_nodeline}"
      ;;

      'nodeline-no-uuid')
          RVAL="${_address};${_nodetype};${_marks};\
${_url};${_branch};${_tag};${_fetchoptions};\
${_raw_userinfo}"
      ;;

      'address')
         RVAL="${_address}"
      ;;

      'address-filename')
         RVAL="${_address};${_filename}"
      ;;

      'address-url')
         RVAL="${_address};${_url}"
      ;;

      'filename')
         RVAL="${_filename}"
      ;;

      # libraries have no url...
      'url-filename')
         RVAL="${_url};${_filename}"
      ;;

      *)
         internal_fail "unknown dedupe mode \"${WALK_DEDUPE_MODE}\""
      ;;
   esac
   return 0
}


walk_remove_from_visited()
{
   if r_visit_line_from_node
   then
      r_escaped_sed_pattern "${RVAL}"

      VISITED="`sed -e "/^${RVAL}$/d" <<< "${VISITED}"`"
   fi
}


walk_add_to_visited()
{
   if ! r_visit_line_from_node
   then
      return 0
   fi

   if find_line "${VISITED}" "${RVAL}"
   then
      log_fluff "A node \"${_address}/${_url}\" has already been visited"
      return 1
   fi

   r_add_line "${VISITED}" "${RVAL}"
   VISITED="${RVAL}"
}

#
# datasource
# virtual
# next_datasource
# next_virtual
# filternodetypes
# filterpermissions
# visitqualifier
# descendqualifier
# mode
# callback
# ...
#
_visit_node()
{
   log_entry "_visit_node" "$@"

   local datasource="$1"
   local virtual="$2"
   local next_datasource="$3"
   local mode="$9"

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

   local rval

   rval=0
   case ",${mode}," in
      *,flat,*)
         if ! walk_add_to_visited
         then
            return 0
         fi

         log_debug "No recursion"
         _visit_callback "$@"
         rval=$?
      ;;

      *,in-order,*)
         #
         # Dedupe now before going to callback and recursion
         #
         if ! walk_add_to_visited
         then
            return 0
         fi

         log_debug "In-order recursion into ${next_datasource}"
         _visit_recurse "$@"
         rval=$?
         if [ $rval -eq 0 ]
         then
            _visit_callback "$@"
            rval=$?
         fi
      ;;

      *,pre-order,*)
         if ! walk_add_to_visited
         then
            return 0
         fi

         log_fluff "Pre-order recursion into ${next_datasource}"
         _visit_callback "$@"
         rval=$?
         if [ $rval -eq 0 ]
         then
            _visit_recurse "$@"
            rval=$?
         fi
      ;;

      *,breadth-order,*)
         # node will already have been visited flat, so don't dedupe again
         rval=$?
         if [ $rval -eq 0 ]
         then
            log_fluff "Breadth-first recursion into ${next_datasource}"
            _visit_recurse "$@"
            rval=$?
         fi
      ;;
   esac

   return $rval
}


#
# datasource          // place of the config/db where we read the nodeline from
# virtual             // same but relative to project and possibly remapped
# filternodetypes
# filterpermissions
# visitqualifier
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
   local visitqualifier="$1"; shift
   local descendqualifier="$1"; shift
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
   local _raw_userinfo

   nodeline_parse "${nodeline}"

   local _nodeline

   _nodeline="${nodeline}"

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
                              "${visitqualifier}" \
                              "${descendqualifier}" \
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

   _destination="${_address%#*}"

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

   local rval

   if ! walk_filter_visit_permissions "${filterpermissions}" "${_filename}" "${_marks}"
   then
      # filter should have fluffed already
      log_debug "Node \"${_address}\" with filename \"${_filename}\" \
doesn't jive with permissions \"${filterpermissions}\""
      return 0
   fi

   local next_datasource

   next_datasource="${datasource}${_destination}/"

   _visit_node "${datasource}" \
               "${virtual}" \
               "${next_datasource}" \
               "${next_virtual}" \
               "${filternodetypes}" \
               "${filterpermissions}" \
               "${visitqualifier}" \
               "${descendqualifier}" \
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
   local visitqualifier="$1"; shift
   local descendqualifier="$1"; shift
   local mode="$1" ; shift

#   [ -z "${MULLE_SOURCETREE_STASH_DIR}" ] && internal_fail "MULLE_SOURCETREE_STASH_DIR is empty"

   #
   # So the node is shared, so virtual changes
   # The datasource may diverge though..
   #
   local _destination
   local _filename
   local _virtual_address

   _destination="${_address##*/}" # like fast_basename
   # get rid of duplicate marker
   _destination="${_destination%#*}"

   local next_virtual

   next_virtual="${MULLE_SOURCETREE_STASH_DIR}/${_destination}"

   _virtual_address="${next_virtual}"

   _filename="${next_virtual}"
   case "${_filename}" in
      /*)
      ;;

      *)
         _filename="${MULLE_VIRTUAL_ROOT}/${next_virtual}"
      ;;
   esac

   if ! walk_filter_visit_permissions "${filterpermissions}" "${_filename}" "${_marks}"
   then
      # filter should have fluffed already
      log_debug "Node \"${_address}\" with filename \"${_filename}\" \
doesn't jive with permissions \"${filterpermissions}\""
      return 0
   fi

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
         log_debug "Visit \"${next_datasource}\" as \"${_filename}\" \
doesn't exist yet"
      fi
   fi

   _visit_node "${datasource}" \
               "${MULLE_SOURCETREE_STASH_DIR}" \
               "${next_datasource}" \
               "${next_virtual}" \
               "${filternodetypes}" \
               "${filterpermissions}" \
               "${visitqualifier}" \
               "${descendqualifier}" \
               "${mode}" \
               "$@"
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
         log_debug "Flat walk \"${datasource:-.}\""
      ;;

      *,in-order,*)
         log_debug "Recursive depth-first walk \"${datasource:-.}\""
      ;;

      *,pre-order,*)
         log_debug "Recursive pre-order walk \"${datasource:-.}\""
      ;;

      *,breadth-order,*)
         log_debug "Recursive breadth-first walk \"${datasource:-.}\""
      ;;

      *)
         internal_fail "Mode \"${mode}\" incomplete"
      ;;
   esac

   return 0
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

   local datasource="$1"; shift
   local virtual="$1"; shift
   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local visitqualifier="$1"; shift
   local descendqualifier="$1"; shift
   local mode="$1" ; shift

   if ! _print_walk_info "${datasource}" "${nodelines}" "${mode}"
   then
      return 0
   fi

   local rval

   case ",${mode}," in
      *,breadth-order,*)
         local tmpmode

         r_comma_concat "${mode}" 'flat'
         tmpmode="${RVAL}"

         set -o noglob ; IFS="
"
         for nodeline in ${nodelines}
         do
            IFS="${DEFAULT_IFS}" ; set +o noglob

            [ -z "${nodeline}" ] && continue


            _visit_filter_nodeline "${nodeline}" \
                                   "${datasource}" \
                                   "${virtual}" \
                                   "${filternodetypes}" \
                                   "${filterpermissions}" \
                                   "${visitqualifier}" \
                                   "${descendqualifier}" \
                                   "${tmpmode}" \
                                   "$@"
            rval=$?
            if [ $rval -ne 0 ]
            then
               log_debug "Walk aborts"
               return 1
            fi
         done
      ;;
   esac


   set -o noglob ; IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      [ -z "${nodeline}" ] && continue

      _visit_filter_nodeline "${nodeline}" \
                             "${datasource}" \
                             "${virtual}" \
                             "${filternodetypes}" \
                             "${filterpermissions}" \
                             "${visitqualifier}" \
                             "${descendqualifier}" \
                             "${mode}" \
                             "$@"
      rval=$?
      if [ $rval -ne 0 ]
      then
         log_debug "Walk aborts"
         return $rval
      fi
   done

   IFS="${DEFAULT_IFS}" ; set +o noglob
}


#
# walk_auto_uuid settingname,callback,permissions,SOURCETREE_DB_FILENAME ...
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
# visitqualifier
# mode
# callback
# ...
#

_walk_config_uuids()
{
   log_entry "_walk_config_uuids" "$@"

   local datasource="$1"
   local virtual="$2"

   local nodelines

   nodelines="`cfg_read "${datasource}" `"
   if [ -z "${nodelines}" ]
   then
      log_fluff "Config \"${datasource}\" has no nodes"
      return 0
   fi

   log_fluff "Walking config \"${datasource}\" nodes"
   _walk_nodelines "${nodelines}" "$@"
}


walk_config_uuids()
{
   log_entry "walk_config_uuids" "$@"

   local MULLE_WALK_INDENT=""
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
#
# filternodetypes
# filterpermissions
# visitqualifier
# descendqualifier
# mode
#
# callback
# ...
#
_walk_db_uuids()
{
   log_entry "_walk_db_uuids" "$@"

   local datasource="$1"
   local virtual="$2"
   local mode="$7"

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
   if [ -z "${nodelines}" ]
   then
      log_fluff "Database \"${datasource}\" has no nodes"
      return 0
   fi

   log_fluff "Walking database \"${datasource}\" nodes"
   _walk_nodelines "${nodelines}" "$@"
}


walk_db_uuids()
{
   log_entry "walk_db_uuids" "$@"

   local MULLE_WALK_INDENT=""
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
   local visitqualifier="${1}"; shift
   local descendqualifier="${1}"; shift
   local mode="${1}" ; shift
   local callback="${1}"; shift

   [ -z "${mode}" ] && internal_fail "mode can't be empty"

   MULLE_ROOT_DIR="`pwd -P`"

   local rval

   rval=0
   #
   # make pre-order default if no order set for share or recurse
   #
   case ",${mode}," in
      ,flat,|*-order,*)
      ;;

      *)
         r_comma_concat "${mode}" "pre-order"
         mode="${RVAL}"
      ;;
   esac

   case ",${mode}," in
      *,callroot,*)
         case ",${mode}," in
            *,pre-order,breadth-order,*)
               _visit_root_callback "${mode}" "${callback}" "$@"
               rval=$?
            ;;
         esac
      ;;
   esac

   if [ $rval -eq 0 ]
   then
      case ",${mode}," in
         *,walkdb,*)
            walk_db_uuids "${filternodetypes}" \
                          "${filterpermissions}" \
                          "${visitqualifier}" \
                          "${descendqualifier}" \
                          "${mode}" \
                          "${callback}" \
                          "$@"
            rval=$?
         ;;

         *)
            walk_config_uuids "${filternodetypes}" \
                              "${filterpermissions}" \
                              "${visitqualifier}" \
                              "${descendqualifier}" \
                              "${mode}" \
                              "${callback}" \
                              "$@"
            rval=$?
         ;;
      esac
   fi

   if [ $rval -eq 0 ]
   then
      case ",${mode}," in
         *,callroot,*)
            case ",${mode}," in
               *,pre-order,*)
               ;;

               *)
                  _visit_root_callback "${mode}" "${callback}" "$@"
                  rval=$?
               ;;
            esac
         ;;
      esac
   fi

   if [ $rval -eq 2 ]
   then
      return 0
   fi

   return $rval
}


sourcetree_walk_internal()
{
   log_entry "sourcetree_walk_internal" "$@"

   sourcetree_walk "" "" "" "" "$@"
}


sourcetree_walk_main()
{
   log_entry "sourcetree_walk_main" "$@"

   local MULLE_ROOT_DIR

   local OPTION_CALLBACK_ROOT="DEFAULT"
   local OPTION_CD="DEFAULT"
   local OPTION_TRAVERSE_STYLE="PREORDER"
   local OPTION_EXTERNAL_CALL='YES'
   local OPTION_LENIENT='NO'
   local OPTION_MARKS=""
   local OPTION_QUALIFIER=""
   local OPTION_DESCEND_QUALIFIER=""
   local OPTION_VISIT_QUALIFIER=""
   local OPTION_NODETYPES=""
   local OPTION_PERMISSIONS="descend-symlink"
   local OPTION_CALLBACK_TRACE='YES'
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_EVAL='YES'

   local WALK_VISIT_CALLBACK=
   local WALK_RECURSE_CALLBACK=
   local WALK_DEDUPE_MODE=''

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_walk_usage
         ;;

         --callback-root)
            OPTION_CALLBACK_ROOT='YES'
         ;;

         -E|--eval)
            OPTION_EVAL='YES'
         ;;

         -N|--no-eval)
            OPTION_EVAL='NO'
         ;;

         --no-callback-trace)
            OPTION_CALLBACK_TRACE='NO'
         ;;

         --no-callback-root)
            OPTION_CALLBACK_ROOT='NO'
         ;;

         --cd)
            OPTION_CD='YES'
         ;;

         --no-cd)
            OPTION_CD='NO'
         ;;

         --walk-db|--walk-db-dir)
            OPTION_WALK_DB='YES'
         ;;

         --walk-config|--walk-config-file)
            OPTION_WALK_DB='NO'
         ;;

         --dedupe-mode)
            [ $# -eq 1 ] && sourcetree_walk_usage "Missing argument to \"$1\""
            shift

            WALK_DEDUPE_MODE="$1"
         ;;

         --in-order)
            OPTION_TRAVERSE_STYLE="INORDER"
         ;;

         --pre-order)
            OPTION_TRAVERSE_STYLE="PREORDER"
         ;;

         --breadth-order|--breadth-first)
            OPTION_TRAVERSE_STYLE="BREADTH"
         ;;

         -l|--lenient)
            OPTION_LENIENT='YES'
         ;;

         --no-lenient)
            OPTION_LENIENT='NO'
         ;;

         --will-recurse-callback)
            [ $# -eq 1 ] && sourcetree_walk_usage "Missing argument to \"$1\""
            shift

            WILL_RECURSE_CALLBACK="$1"
         ;;

         --did-recurse-callback)
            [ $# -eq 1 ] && sourcetree_walk_usage "Missing argument to \"$1\""
            shift

            DID_RECURSE_CALLBACK="$1"
         ;;

         #
         # filter flags
         #
         -m|--marks)
            [ $# -eq 1 ] && sourcetree_walk_usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${OPTION_MARKS}" "$1"
            OPTION_MARKS="${RVAL}"
         ;;

         -q|--qualifier|--marks-qualifier)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_QUALIFIER="$1"
         ;;

         --visit-qualifier)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_VISIT_QUALIFIER="$1"
         ;;

         --descend-qualifier)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_DESCEND_QUALIFIER="$1"
         ;;

         --prune)
            OPTION_PRUNE='YES'
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && sourcetree_walk_usage "Missing argument to \"$1\""
            shift

            OPTION_NODETYPES="$1"
         ;;

         -p|--perm*)
            [ $# -eq 1 ] && sourcetree_walk_usage "Missing argument to \"$1\""
            shift

            OPTION_PERMISSIONS="$1"
         ;;

         -*)
            sourcetree_walk_usage "Unknown walk option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -gt 1 ] && shift && sourcetree_walk_usage "Superflous arguments \"$*\". Pass callback as one string and use "

   local callback

   if [ $# -eq 0 ]
   then
      callback='echo "${MULLE_NODE}"'
   else
      callback="$1"
      shift
   fi

   local mode

   mode="${SOURCETREE_MODE}"

   case "${OPTION_TRAVERSE_STYLE}" in
      "INORDER")
         r_comma_concat "${mode}" "in-order"
         mode="${RVAL}"
      ;;

      "BREADTH")
         r_comma_concat "${mode}" "breadth-order"
         mode="${RVAL}"
      ;;

      *)
         r_comma_concat "${mode}" "pre-order"
         mode="${RVAL}"
      ;;
   esac

   if [ "${OPTION_LENIENT}" = 'YES' ]
   then
      r_comma_concat "${mode}" "lenient"
      mode="${RVAL}"
   fi
   if [ "${OPTION_CD}" = 'YES' ]
   then
      r_comma_concat "${mode}" "docd"
      mode="${RVAL}"
   fi
   if [ "${OPTION_EXTERNAL_CALL}" = 'YES' ]
   then
      r_comma_concat "${mode}" "external"
      mode="${RVAL}"
   fi
   if [ "${OPTION_WALK_DB}" = 'YES' ]
   then
      r_comma_concat "${mode}" "walkdb"
      mode="${RVAL}"
   fi
   if [ "${OPTION_CALLBACK_ROOT}" = 'YES' ]
   then
      r_comma_concat "${mode}" "callroot"
      mode="${RVAL}"
   fi
   if [ "${OPTION_EVAL}" = 'YES' ]
   then
      r_comma_concat "${mode}" "eval"
      mode="${RVAL}"
   fi
   if [ "${OPTION_CALLBACK_TRACE}" = 'NO' ]
   then
      r_comma_concat "${mode}" "no-trace"
      mode="${RVAL}"
   fi

   # convert marks into a qualifier with globals
   if [ ! -z "${OPTION_MARKS}" ]
   then
      local mark

      IFS=","; set -o noglob
      for mark in ${OPTION_MARKS}
      do
         r_concat "${OPTION_QUALIFIER}" "MATCHES ${mark}" " AND "
         OPTION_QUALIFIER="${RVAL}"
      done
      IFS="${DEFAULT_IFS}"; set +o noglob
   fi

   #
   # Qualifier works for both, but you can specify each differently
   # use ANY to ignore one
   #
   OPTION_VISIT_QUALIFIER="${OPTION_VISIT_QUALIFIER:-${OPTION_QUALIFIER}}"
   if [ "${OPTION_PRUNE}" = 'YES' ]
   then
      [ ! -z "${OPTION_DESCEND_QUALIFIER}" ] && fail "--prune and --descend-qualifier conflict"
      OPTION_DESCEND_QUALIFIER="${OPTION_VISIT_QUALIFIER}"
   fi

   sourcetree_walk "${OPTION_NODETYPES}" \
                   "${OPTION_PERMISSIONS}" \
                   "${OPTION_VISIT_QUALIFIER}" \
                   "${OPTION_DESCEND_QUALIFIER}" \
                   "${mode}" \
                   "${callback}" \
                   "$@"
}


sourcetree_walk_initialize()
{
   log_entry "sourcetree_walk_initialize"

   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-db.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh"
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

