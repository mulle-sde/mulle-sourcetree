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



sourcetree::walk::usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} walk [options] <shell command>

   Walk over the nodes described by the config file and execute <shell command>
   for each node. Unprocessed node information is passed in the following
   environment variables:
EOF

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      cat <<EOF  >&2

      NODE_FILENAME     : the place where the node will be fetched to

      NODE_ADDRESS      : address part of WALK_NODE
      NODE_BRANCH       : branch part of WALK_NODE
      NODE_FETCHOPTIONS : the fetchoptions part of WALK_NODE
      NODE_MARKS        : the marks part of WALK_NODE
      NODE_TAG          : tag part of WALK_NODE
      NODE_TYPE         : the type (nodetype) part of the WALK_NODE
      NODE_URL          : the URL part of WALK_NODE
      NODE_USERINFO     : the userinfo part of WALK_NODE (possibly base64)
      NODE_UUID         : the uuid part of WALK_NODE

      WALK_NODE         : the complete contents of the node
      WALK_DATASOURCE   : the current node sourcetree config path
      WALK_DESTINATION  : what will be used to recurse the current node
      WALK_MODE         : current internal mode used for walking
      WALK_INDEX        : current node index of all nodes walked
      WALK_LEVEL        : recursion depth of current node

EOF
   else
      cat <<EOF  >&2
   NODE_URL, NODE_ADDRESS, NODE_BRANCH, NODE_TAG, NODE_FILENAME,
   NODE_TYPE, NODE_UUID, NODE_MARKS, NODE_FETCHOPTIONS, NODE_USERINFO,
   WALK_NODE. WALK_DESTINATION, WALK_MODE, WALK_INDEX, WALK_LEVEL.

EOF
   fi

      cat <<EOF  >&2
   The working directory will be the node (if it's a directory).
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
      cat <<EOF  >&2
   There is a little qualifier language available to query the marks of a node.
   (Use -v for more info about the qualifier language)
EOF
   fi

   cat <<EOF >&2

Examples:
   Dump the names of each node, that needs to be built in "singlephase" mode
   with index and indentation:
      mulle-sourcetree walk --qualifier 'MATCHES singlephase' \\
         printf "%s\n" "\${WALK_INDEX} \${WALK_INDENT}\${NODE_ADDRESS}"'

   Find the location of a dependency named foo:
      mulle-sourcetree walk --lenient '[ "\${NODE_ADDRESS}" = "foo" ] && \\
                                          echo "\${NODE_FILENAME}"'

   Dump marks as used for the same dependency by different other dependencies
   (aka search for stars):
      mulle-sourcetree walk --no-dedupe --lenient \\
         '[ "\${NODE_ADDRESS}" = "foo" ] && \\
         echo "\${NODE_MARKS} (\${WALK_DATASOURCE})"' | sort -u
EOF

   cat <<EOF >&2

Options:
   -n <value>       : node types to walk (default: ALL)
   -p <value>       : specify permissions (missing)
   -m <value>       : marks to match (e.g. build)
   -q <value>       : qualifier for marks to match (e.g. MATCHES build)
   --cd             : change directory to node's working directory
   --comments       : also walk comment nodes
   --lenient        : allow shell command to error
   --backwards      : walk tree nodes backwards, rarely useful
   --in-order       : walk tree depth first  (Root, Left, Right
   --no-dedupe      : walk all nodes in the tree (very slow)
   --bequeath       : ignore bequeath marks (this is erroneously inverted)
   --pre-order      : walk tree in pre-order  (Root, Left, Right)
   --breadth-first  : walk tree breadth first (first all top levels)
   --post-order     : walk tree depth first for all siblings (Left, Right, Root)
   --walk-db        : walk over information contained in the database instead
EOF

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      cat <<EOF >&2

[Callback] Options:
   --declare-function <f>      : declare a function to be used as a callback
   --callback-qualifier <q>    : qualifier to filter node, by default same as -q
   --callback-root             : callback for root node
   --cd                        : enter config directory before callback
   --configuration             : specify as Debug or Release
   --dedupe-mode <m>           : set deduplication mode (see sourcecode)
   --descend-qualifier <q>     : qualifier to use for descending nodes
   --did-descend-callback <c>  : callback for the descend (default)
   --did-walk-callback <c>     : callback after walk is done
   --eval                      : evaluate callback
   --max-walk-level            : restrict callbacks to max recursion depth
   --min-walk-level            : restrict callbacks to min recursion depth
   --no-callback-root          : don't execute callbacks for root level
   --no-callback-trace         : don't trace callbacks
   --no-cd                     : don't change directory for callback (default)
   --no-comments               : ignore comment nodes
   --no-eval                   : don't eval callback (default)
   --will-descend-callback <c> : callback before descending
EOF
   fi

   exit 1
}


#
# Walkers
#
# Possible permissions: "symlink,missing"
# Useful for craftorder it would seem
#
sourcetree::walk::_callback_permissions()
{
   log_entry "sourcetree::walk::_callback_permissions" "$@"

   local filename="$1"
   local marks="$2"
   local permissions="$3"

   [ -z "${filename}" ] && _internal_fail "empty filename"

   # it should be faster to put [ -e ] into each case statement
   case ",${permissions}," in
      *,fail-noexist,*|*,callback-fail-noexist,*)
         if [ ! -e "${filename}" ]
         then
            fail "Missing \"${filename}\" is not yet fetched."
         fi
      ;;

      *,warn-noexist,*|*,callback-warn-noexist,*)
         if [ ! -e "${filename}" ]
         then
            log_warning "Repository expected in \"${filename}\" is not yet fetched"
            return 0
         fi
      ;;

      *,skip-noexist,*|*,callback-skip-noexist,*)
         if [ ! -e "${filename}" ]
         then
            log_fluff "Repository expected in \"${filename}\" is not yet fetched, skipped"
            return 1
         fi
      ;;
   esac

   case ",${permissions}," in
      *,fail-symlink,*|*,callback-fail-symlink,*)
         if [ -L "${filename}" ]
         then
            fail "\"${filename}\" is a symlink."
         fi
      ;;

      *,warn-symlink,*|*,callback-warn-symlink,*)
         if [ -L "${filename}" ]
         then
            log_warning "\"${filename}\" is a symlink."
            return 0
         fi
      ;;

      *,skip-symlink,*|*,callback-skip-symlink,*)
         if [ -L "${filename}" ]
         then
            log_warning "\"${filename}\" is a symlink, skipped."
            return 1
         fi
      ;;
   esac

   log_debug "sourcetree::walk::_callback_permissions \"${filename}\" returns with 0"
   return 0
}


sourcetree::walk::_descend_permissions()
{
   log_entry "sourcetree::walk::_descend_permissions" "$@"

   local filename="$1"
   local marks="$2"
   local permissions="$3"

   [ -z "${filename}" ] && _internal_fail "empty filename"

   case ",${permissions}," in
      *,fail-noexist,*|*,descend-fail-noexist,*)
         if [ ! -e "${filename}" ]
         then
            fail "Missing \"${filename}\" is not yet fetched."
         fi
      ;;

      *,warn-noexist,*|*,descend-warn-noexist,*)
         if [ ! -e "${filename}" ]
         then
            log_warning "Repository expected in \"${filename}\" is not yet fetched"
            return 0
         fi
      ;;

      *,skip-noexist,*|*,descend-skip-noexist,*)
         if [ ! -e "${filename}" ]
         then
            log_fluff "Repository expected in \"${filename}\" is not yet fetched, skipped"
            return 1
         fi
      ;;
   esac

   case ",${permissions}," in
      *,fail-symlink,*|*,descend-fail-symlink,*)
         if [ -L "${filename}" ]
         then
            fail "\"${filename}\" is a symlink."
         fi
      ;;

      *,warn-symlink,*|*,descend-warn-symlink,*)
         if [ -L "${filename}" ]
         then
            log_warning "\"${filename}\" is a symlink."
         fi
      ;;


      *,skip-symlink,*|*,descend-skip-symlink,*)
         if [ -L "${filename}" ]
         then
            log_fluff "\"${filename}\" is a symlink, skipped."
            return 1
         fi
      ;;
   esac

   log_debug "\"${filename}\" will be descended into."
   return 0
}


sourcetree::walk::_callback_nodetypes()
{
   log_entry "sourcetree::walk::_callback_nodetypes" "$@"

   local nodetype="$1"; shift

   local evalednodetype

   r_expanded_string "${nodetype}"
   evalednodetype="${RVAL}"

   sourcetree::node::type_filter "${evalednodetype}" "$@"
}


sourcetree::walk::_callback_filter()
{
   log_entry "sourcetree::walk::_callback_filter" "$@"

   sourcetree::nodemarks::filter_with_qualifier "$@"
}


sourcetree::walk::_descend_filter()
{
   log_entry "sourcetree::walk::_descend_filter" "$@"

   sourcetree::nodemarks::filter_with_qualifier "$@"
}



#
# clobbers:
#
# local _old
#
sourcetree::walk::__docd_preamble()
{
   local directory="$1"

   _old="${PWD}"
   exekutor cd "${directory}"
}


sourcetree::walk::__docd_postamble()
{
   exekutor cd "${_old}"
}


#
# Easier to pass all in, because we need the trailing args to pass
#
# datasource
# virtual
# filternodetypes
# filterpermissions
# callbackqualifier
# descendqualifier
# mode
# callback
# ...
#
# Special return value 121 signals callbackqualifier was the reason
# this can be used by callers to not check for optimization purposes
#
sourcetree::walk::_visit_callback()
{
   log_entry "sourcetree::walk::_visit_callback" "$@"

   local datasource="$1"
   local virtual="$2"
   local next_datasource="$3"
   local next_virtual="$4"
   local filternodetypes="$5"
   local filterpermissions="$6"
   local callbackqualifier="$7"
   local descendqualifier="$8"
   local mode="$9"
   shift 9

   local callback="$1"; shift

   if [ ! -z "${callbackqualifier}" ]
   then
      if ! sourcetree::walk::_callback_filter "${_marks}" "${callbackqualifier}"
      then
         log_fluff "Node \"${_address}\" marks \"${_marks}\" don't jive with qualifier \"${callbackqualifier//$'\n'/ }\""
         return 121  # the 1 indicates that the filter was the reason (can be reused by descend maybe)
      fi
   fi

   if [ ! -z "${filternodetypes}" ]
   then
      if ! sourcetree::walk::_callback_nodetypes "${_nodetype}" "${filternodetypes}"
      then
         log_fluff "Node \"${_address}\": \"${_nodetype}\" doesn't jive with nodetypes \"${filternodetypes}\""
         return 0
      fi
   fi

   if [ ! -z "${filterpermissions}" ]
   then
      if ! sourcetree::walk::_callback_permissions "${_filename}" "${_marks}" "${filterpermissions}"
      then
         # filter should have fluffed already
         _log_debug "Node \"${_address}\" with filename \"${_filename}\" \
doesn't jive with permissions \"${filterpermissions}\""
         return 0
      fi
   fi

   if [ ! -z "${OPTION_IGNORE}" ]
   then
      local ignore

      .foreachpath ignore in ${OPTION_IGNORE}
      .do
         case "${_address}" in
            ${ignore})
               log_fluff "Node ${_address} ignored by filename ignore list"
               return 0
            ;;
         esac
      .done
   fi

   if [ ${WALK_LEVEL} -lt ${OPTION_MIN_WALK_LEVEL:-0} ]
   then
      return 0
   fi

   if [ ${WALK_LEVEL} -ge ${OPTION_MAX_WALK_LEVEL:-9999} ]
   then
      return 0
   fi

   local rval

   rval=0
   WALK_INDEX=$((WALK_INDEX + 1))
   case ",${mode}," in
      *,docd,*)
         local _old

         if [ -d "${_filename}" ]
         then
            sourcetree::walk::__docd_preamble "${_filename}"
               sourcetree::callback::call "${datasource}" "${virtual}" "${mode}" "${callback}" "$@"
               rval=$?
            sourcetree::walk::__docd_postamble
            log_debug "callback returned $rval"
         else
            log_fluff "\"${_filename}\" not there, so no callback"
         fi
      ;;

      *)
         sourcetree::callback::call "${datasource}" "${virtual}" "${mode}" "${callback}" "$@"
         rval=$?
         log_debug "callback returned $rval"
      ;;
   esac

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
# callbackqualifier
# descendqualifier
# mode
# callback
# ...
#
sourcetree::walk::_visit_descend()
{
   log_entry "sourcetree::walk::_visit_descend" "$@"

   local datasource="$1"
   local virtual="$2"
   shift 2

#   local next_datasource="$1"
#   local next_virtual="$2"
#
#   local filternodetypes="$3"
   local filterpermissions="$4"
#   local callbackqualifier="$5"
   local descendqualifier="$6"
   local mode="$7"

   if sourcetree::nodemarks::disable "${_marks}" "descend"
   then
      _log_debug "Do not recurse on \"${virtual}/${_destination}\" due to no-descend mark"
      return 0
   fi

   if [ ! -z "${descendqualifier}" ]
   then
      if ! sourcetree::walk::_descend_filter "${_marks}" "${descendqualifier}"
      then
         _log_debug "Node \"${_address}\" marks \"${_marks}\" don't jive \
with \"${descendqualifier}\""
         return 0
      fi
   fi

   if [ ! -z "${filterpermissions}" ]
   then
      if ! sourcetree::walk::_descend_permissions "${_filename}" \
                                                 "${_marks}" \
                                                 "${filterpermissions}"
      then
         _log_debug "Node \"${_address}\" with filename \"${_filename}\" \
doesn't jive with permissions \"${filterpermissions}\""
         return 0
      fi
   fi

   if [ ! -z "${WILL_DESCEND_CALLBACK}" ]
   then
      if ! "${WILL_DESCEND_CALLBACK}" "$@"
      then
         _log_debug "Do not visit on \"${virtual}/${_destination}\" due \
to WILL_DESCEND_CALLBACK"
         return 0
      fi
   fi

   if [ ! -z "${OPTION_IGNORE}" ]
   then
      local ignore

      .foreachpath ignore in ${OPTION_IGNORE}
      .do
         case "${_address}" in
            ${ignore})
               log_fluff "Node ${_address} ignored by filename ignore list"
               return 0
            ;;
         esac
      .done
   fi

   #
   # Preserve state and globals vars, so dont subshell
   #
   local old_walk_parent="${WALK_PARENT}"

   WALK_INDENT="${WALK_INDENT} "
   WALK_LEVEL=$((WALK_LEVEL + 1))
   WALK_PARENT="${_address}"

   local rval
   local symbol

   log_fluff "Descend into \"${next_datasource}\""

   case ",${mode}," in
      *,walkdb,*)
         sourcetree::walk::_walk_db_uuids "$@"
         rval=$?
      ;;

      *)
         sourcetree::walk::r_symbol_for_address "${_address}"
         symbol="${RVAL}"
         sourcetree::walk::_walk_config_uuids "${symbol}" "$@"
         rval=$?
      ;;
   esac

   WALK_LEVEL=$((WALK_LEVEL - 1))
   WALK_INDENT="${WALK_INDENT%?}"
   WALK_PARENT="${old_walk_parent}"

   if [ $rval -eq 0 -a ! -z "${DID_DESCEND_CALLBACK}" ]
   then
      "${DID_DESCEND_CALLBACK}" "$@"
      rval=$?
      log_debug "DID_DESCEND_CALLBACK of \"${virtual}/${_destination}\" returns $rval"
   fi
   return $rval
}




#
# 1 must visit
# 0 check lineid
#
sourcetree::walk::r_get_dedupe_lineid_from_node()
{
   log_entry "sourcetree::walk::r_get_dedupe_lineid_from_node" "$@"

   local mode="$1"

   case ",${mode}," in
      *,dedupe-none,*)
         RVAL=
         return 1
      ;;

      *,dedupe-address,*)
         RVAL="${_address}"
         return 0
      ;;

      *,dedupe-nodeline,*)
         RVAL="${_nodeline}"
         return 0
      ;;

      *,dedupe-nodeline-no-uuid,*)
         RVAL="${_address};${_nodetype};${_marks};\
${_url};${_branch};${_tag};${_fetchoptions};\
${_raw_userinfo}"
         return 0
      ;;

      *,dedupe-hacked-marks-nodeline-no-uuid,*)
         #
         # remove some marks which are inessential for link dupe detection
         # with the '*' on the left side
         sourcetree::list::r_remove_marks "${_marks}" "no-require,no-public,no-header"
         RVAL="${_address};${_nodetype};${RVAL};\
${_url};${_branch};${_tag};${_fetchoptions};\
${_raw_userinfo}"
         return 0
      ;;

      *,dedupe-address-url,*)
         RVAL="${_address};${_url}"
         return 0
      ;;

      *,dedupe-linkorder,*)
         local i
         local linkmarks

         shell_disable_glob ; IFS=","
         for i in ${_marks}
         do
            case "${i}" in
               no-configuration-${CONFIGURATION})
                  r_comma_concat "${linkmarks}" "${i}"
                  linkmarks="${RVAL}"
               ;;

               no-configuration-*)
                  # ignore these flag for deduping otherwise
               ;;

               *-platform-*|only-configuration-*|no-link)
                  r_comma_concat "${linkmarks}" "${i}"
                  linkmarks="${RVAL}"
               ;;
            esac
         done
         IFS="${DEFAULT_IFS}" ; shell_enable_glob

         RVAL="${_address};${linkmarks:-DEFAULT}" #;${_filename}"
         return 0
      ;;

      *,dedupe-address-marks-filename,*)
         RVAL="${_address};DEFAULT;${_filename}"
         return 0
      ;;

      *,dedupe-filename,*)
         RVAL="${_filename}"
         return 0
      ;;

      # libraries have no url...
      *,dedupe-url-filename,*)
         RVAL="${_url};${_filename}"
         return 0
      ;;

      *,dedupe-*,*)
        _internal_fail "Unknown dedupe mark in \"${mode}"
      ;;
   esac

# address-filename is default
#      *,address-filename,*)
   RVAL="${_address};${_filename}"
   return 0
}


#
# 0 has visited it
# 1 has not visited it
# 2 has not visited, should dedupe
#
sourcetree::walk::r_has_visited()
{
   local mode="$1"

   local lineid

   if ! sourcetree::walk::r_get_dedupe_lineid_from_node "${mode}"
   then
      RVAL=""
      return 1
   fi
   lineid="${RVAL}"

   if find_line "${VISITED}" "${lineid}"
   then
      log_debug "A node with lineid \"${lineid}\" has already been visited"
      return 0
   fi

   RVAL="${lineid}"
   return 2
}


sourcetree::walk::remember_visit()
{
   local lineid="$1"

   r_add_line "${VISITED}" "${lineid}"
   VISITED="${RVAL}"
}


sourcetree::walk::remove_from_visited()
{
   local mode="$1"

   local lineid

   if ! sourcetree::walk::r_get_dedupe_lineid_from_node "${mode}"
   then
      # not deduping anyway
      return
   fi

   r_remove_line "${VISITED}" "${RVAL}"
   VISITED="${RVAL}"
}


#
# datasource
# virtual
# next_datasource
# next_virtual
# filternodetypes
# filterpermissions
# callbackqualifier
# descendqualifier
# mode
# callback
# ...
#
sourcetree::walk::_visit_node()
{
   log_entry "sourcetree::walk::_visit_node" "$2/${_address}"

   local datasource="$1"
   local virtual="$2"
   local next_datasource="$3"
   local callbackqualifier="$7"
   local descendqualifier="$8"
   local mode="$9"

   case "${virtual}" in
      */)
         _internal_fail "virtual \"${virtual}\" not well formed"
      ;;
   esac

   case "${datasource}" in
      "//")
         _internal_fail "datasource \"${datasource}\" not well formed"
      ;;

      "/"|/*/)
      ;;

      *)
         _internal_fail "datasource \"${datasource}\" not well formed"
      ;;
   esac

   # don't dedupe in-flat post-flat and breadth-flat
   case ",${mode}," in
      *,in-flat,*|*,post-flat,*|*,breadth-flat,*|*,flat,*|*,pre-order,*)
         sourcetree::walk::r_has_visited "${mode}"
         case $? in
            0) # has visited
               return
            ;;

            2) # dedupe
               sourcetree::walk::remember_visit "${RVAL}"
            ;;
         esac
      ;;
   esac

   local rval

   case ",${mode}," in
      *,flat,*|*,in-flat,*|*,post-flat,*|*,breadth-flat,*)
         log_debug "No descend"
         sourcetree::walk::_visit_callback "$@"
         rval=$?
      ;;

      *,in-order,*)
         log_debug "In-order descend into ${next_datasource}"

         # this is on the second pass, the callback will have been called already
         sourcetree::walk::_visit_descend "$@"
         rval=$?
      ;;

      *,post-order,*)
         log_debug "Post-order descend into ${next_datasource}"

         # this is on the first pass, the callback will be called later
         sourcetree::walk::_visit_descend "$@"
         rval=$?
      ;;

      *,pre-order,*)
         sourcetree::walk::_visit_callback "$@"
         rval=$?

         #
         # we don't need to check the  descendqualifier if its the same
         # as the callbackqualifier and it has already failed in
         # sourcetree::walk::_visit_callback
         #
         if [ $rval -eq 121 ]
         then
            rval=0
            if [ "${descendqualifier}" = "${callbackqualifier}" ]
            then
               return $rval
            fi
         fi

         if [ $rval -eq 0 ]
         then
            log_debug "Pre-order descend into ${next_datasource}"
            sourcetree::walk::_visit_descend "$@"
            rval=$?
         fi
      ;;

      #
      # on the first ruin breadth-order will appear as flat, so no callback
      # here
      *,breadth-order,*)
         log_debug "Breadth-first descend into ${next_datasource}"
         sourcetree::walk::_visit_descend "$@"
         rval=$?
      ;;

      *)
         _internal_fail "Unknown visit mode"
      ;;
   esac

   if [ $rval -eq 121 ]
   then
      rval=0
   fi
   return $rval
}


sourcetree::walk::_share_node()
{
   log_entry "sourcetree::walk::_share_node" "$2/${_address}"

   local datasource="$1"
   local virtual="$2"
   local filternodetypes="$3"
   local filterpermissions="$4"
   local callbackqualifier="$5"
   local descendqualifier="$6"
   local mode="$7"
   shift 7

   # TODO: this was commented out, not sure anymore why, if this assert
   #       is wrong, comment out and note in comment why
   [ -z "${MULLE_SOURCETREE_STASH_DIR}" ] \
   && _internal_fail "MULLE_SOURCETREE_STASH_DIR is empty"

   #
   # So the node is shared, so virtual changes
   # The datasource may diverge though..
   #
   local _destination
   local _filename
   local _virtual_address

   _destination="${_address##*/}" # like basename --
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
         log_debug "Visit \"${next_datasource}\" as \"${_filename}\" doesn't exist yet"
      fi
   fi

   sourcetree::walk::_visit_node "${datasource}" \
                                 "${MULLE_SOURCETREE_STASH_DIR}" \
                                 "${next_datasource}" \
                                 "${next_virtual}" \
                                 "${filternodetypes}" \
                                 "${filterpermissions}" \
                                 "${callbackqualifier}" \
                                 "${descendqualifier}" \
                                 "${mode}" \
                                 "$@"
}


#
# datasource          // place of the config/db where we read the nodeline from
# virtual             // same but relative to project and possibly remapped
# filternodetypes
# filterpermissions
# callbackqualifier
# mode
# callback
# ...
#
sourcetree::walk::walk_nodeline()
{
#   log_entry "sourcetree::walk::walk_nodeline" "$@"

   local nodeline="$1"; shift
   local mode="$7"

   # rest are arguments

   [ -z "${nodeline}" ]  && _internal_fail "nodeline is empty"
   [ -z "${mode}" ]      && _internal_fail "mode is empty"

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
   local _raw_userinfo
   local _uuid

   sourcetree::nodeline::parse "${nodeline}"  # !!

   #
   # if we have a comment, ignore, unless comments are enabled but
   # even then only walk them as flat. Unfortunately we need to expand here
   #
   local evalednodetype

   r_expanded_string "${_nodetype}"
   evalednodetype="${RVAL}"

   case "${evalednodetype}" in
      comment)
         case ",${mode}," in
            *,comments,*)
               r_comma_concat "${mode}" "flat"
               mode="${RVAL}"
            ;;

            *)
               return 0
            ;;
         esac
      ;;
   esac

   #
   # Assume you have a -> b -> c.
   # By default c gets linked to a via b. If you mark c in b as no-bequeath
   # it is invisble to a.
   #
   case ",${mode}," in
      *,no-bequeath,*)
         if [ ${WALK_LEVEL} -gt 0 ]
         then
            # node marked as no-bequeath   : ignore
            if sourcetree::nodemarks::disable "${_marks}" "bequeath"
            then
               log_debug "Do not act on non-toplevel \"${virtual}/${_destination}\" with no-bequeath mark"
               return 0
            fi
         fi
      ;;
   esac


   local _nodeline

   _nodeline="${nodeline}"

   #
   # if we are walking in shared mode, then we fold the _address
   # into the shared directory.
   #
   case ",${mode}," in
      *,no-share,*)
         _internal_fail "shouldn't exist anymore"
      ;;

      *,share,*)
         if sourcetree::nodemarks::enable "${_marks}" "share"
         then
            sourcetree::walk::_share_node "$@"
            return $?
         fi

         # if marked share, change mode now
         # mode="$(sed -e 's/share/recurse/' <<< "${mode}")"
      ;;
   esac

   local datasource="$1"
   local virtual="$2"
   local filternodetypes="$3"
   local filterpermissions="$4"
   local callbackqualifier="$5"
   local descendqualifier="$6"
   local mode="$7"
   shift 7

   # "value addition" of a quasi global

   local _destination
   local _filename  # always absolute!
   local _virtual_address

   _destination="${_address%#*}"

   local next_virtual

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

   local next_datasource

   next_datasource="${datasource}${_destination}/"

   sourcetree::walk::_visit_node "${datasource}" \
                                 "${virtual}" \
                                 "${next_datasource}" \
                                 "${next_virtual}" \
                                 "${filternodetypes}" \
                                 "${filterpermissions}" \
                                 "${callbackqualifier}" \
                                 "${descendqualifier}" \
                                 "${mode}" \
                                 "$@"
}


sourcetree::walk::_print_info()
{
#   log_entry "sourcetree::walk::_print_info" "$@"

   local datasource="$1"
   local nodelines="$2"
   local mode="$3"

   local direction

   direction="forward"
   case ",${mode}," in
      *,backwards,*)
         direction="backwards"
      ;;
   esac

   case ",${mode}," in
      *,flat,*)
         log_debug "Flat ${direction} walk \"${datasource:-.}\""
      ;;

      *,in-order,*)
         log_debug "Recursive in-order ${direction} walk \"${datasource:-.}\""
      ;;

      *,pre-order,*)
         log_debug "Recursive pre-order ${direction} walk \"${datasource:-.}\""
      ;;

      *,post-order,*)
         log_debug "Recursive post-order ${direction} walk \"${datasource:-.}\""
      ;;

      *,breadth-order,*)
         log_debug "Recursive breadth-first ${direction} walk \"${datasource:-.}\""
      ;;

      *)
         _internal_fail "Mode \"${mode}\" lacks walk order"
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
sourcetree::walk::_walk_nodelines()
{
   log_entry "sourcetree::walk::_walk_nodelines" "$@"

   local nodelines="$1"; shift

   local datasource="$1"; shift
   local virtual="$1"; shift
   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local callbackqualifier="$1"; shift
   local descendqualifier="$1"; shift
   local mode="$1" ; shift

   sourcetree::walk::_print_info "${datasource}" "${nodelines}" "${mode}"

   case ",${mode}," in
      *,backwards,*)
         r_reverse_lines "${nodelines}"
         nodelines="${RVAL}"
      ;;
   esac

   local rval
   local tmpmode

   case ",${mode}," in
      *,breadth-order,*)

         r_comma_concat "${mode}" 'breadth-flat'
         tmpmode="${RVAL}"

         shell_disable_glob; IFS=$'\n'
         for nodeline in ${nodelines}
         do
            IFS="${DEFAULT_IFS}" ; shell_enable_glob

            [ -z "${nodeline}" ] && continue

            sourcetree::walk::walk_nodeline "${nodeline}" \
                                            "${datasource}" \
                                            "${virtual}" \
                                            "${filternodetypes}" \
                                            "${filterpermissions}" \
                                            "${callbackqualifier}" \
                                            "${descendqualifier}" \
                                            "${tmpmode}" \
                                            "$@"
            rval=$?
            [ $rval -ne 0 ] && return $rval
         done
         IFS="${DEFAULT_IFS}" ; shell_enable_glob
      ;;
   esac

   shell_disable_glob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      [ -z "${nodeline}" ] && continue

      sourcetree::walk::walk_nodeline "${nodeline}" \
                                      "${datasource}" \
                                      "${virtual}" \
                                      "${filternodetypes}" \
                                      "${filterpermissions}" \
                                      "${callbackqualifier}" \
                                      "${descendqualifier}" \
                                      "${mode}" \
                                      "$@"
      rval=$?
      [ $rval -ne 0 ] && return $rval

      case ",${mode}," in
         *,in-order,*)
            r_comma_concat "${mode}" 'post-flat'
            tmpmode="${RVAL}"


            sourcetree::walk::walk_nodeline "${nodeline}" \
                                            "${datasource}" \
                                            "${virtual}" \
                                            "${filternodetypes}" \
                                            "${filterpermissions}" \
                                            "${callbackqualifier}" \
                                            "${descendqualifier}" \
                                            "${tmpmode}" \
                                            "$@"
            rval=$?
            [ $rval -ne 0 ] && return $rval
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   case ",${mode}," in
      *,post-order,*)
         r_comma_concat "${mode}" 'post-flat'
         tmpmode="${RVAL}"

         shell_disable_glob; IFS=$'\n'
         for nodeline in ${nodelines}
         do
            IFS="${DEFAULT_IFS}" ; shell_enable_glob

            [ -z "${nodeline}" ] && continue

            sourcetree::walk::walk_nodeline "${nodeline}" \
                                            "${datasource}" \
                                            "${virtual}" \
                                            "${filternodetypes}" \
                                            "${filterpermissions}" \
                                            "${callbackqualifier}" \
                                            "${descendqualifier}" \
                                            "${tmpmode}" \
                                            "$@"
            rval=$?
            [ $rval -ne 0 ] && return $rval
         done
         IFS="${DEFAULT_IFS}" ; shell_enable_glob
      ;;
   esac
}


sourcetree::walk::dedupe()
{
   local datasource="$1"
   local mode="$2"

   case ",${mode}," in
      *,dedupe-none,*)
         return 1
      ;;
   esac

   # on zsh find_line is faster than a case with all walked in one line 
   if find_line "${WALKED}" "${datasource}"
   then
      log_debug "Datasource \"${datasource#${MULLE_USER_PWD}/}\" has already been walked"
      return 0
   fi

   r_add_line "${WALKED}" "${datasource}"
   WALKED="${RVAL}"

   return 1
}


sourcetree::walk::remove_from_deduped()
{
   local datasource="$1"

   r_remove_line "${WALKED}" "${datasource}"
   WALKED="${RVAL}"
}


sourcetree::walk::r_symbol_for_address()
{
   log_entry "sourcetree::walk::r_symbol_for_address" "$@"

   local address="$1"

   include "case"

   r_basename "${address}"
   r_de_camel_case_upcase_identifier "${RVAL}"

   [ ! -z "${RVAL}" ]
}


sourcetree::walk::__common_configfile()
{
   log_entry "sourcetree::walk::__common_configfile" "$@"

   local symbol="$1" ; shift

   set -x
   if [ -z "${symbol}" ]
   then
      sourcetree::cfg::__common_configfile "$@"
      set +x
      return
   fi

   # for descends we need to reset some internal variables temporarily
   # make local copies of previous values, only valid for the lifetime
   # of this function call

   local SOURCETREE_CONFIG_NAMES="config"
   local SOURCETREE_SCOPE=""
   local SOURCETREE_CONFIG_DIR="${MULLE_SOURCETREE_PROJECT_DIR}/"
   local SOURCETREE_FALLBACK_CONFIG_DIR=""

   #
   # override with environment variables
   #
   local var
   local value

   var="SOURCETREE_CONFIG_NAMES_${symbol}"
   if [ ! -z "${ZSH_VERSION}" ]
   then
      value="${(P)var}"
   else
      value="${!var}"
   fi
   SOURCETREE_CONFIG_NAMES="${value:-${SOURCETREE_CONFIG_NAMES}}"
   log_setting "${var}        : ${value}"

   var="SOURCETREE_CONFIG_DIR_${symbol}"
   if [ ! -z "${ZSH_VERSION}" ]
   then
      value="${(P)var}"
   else
      value="${!var}"
   fi
   SOURCETREE_CONFIG_DIR="${value:-${SOURCETREE_CONFIG_DIR}}"
   log_setting "${var}          : ${value}"

   var="SOURCETREE_FALLBACK_CONFIG_DIR_${symbol}"
   if [ ! -z "${ZSH_VERSION}" ]
   then
      value="${(P)var}"
   else
      value="${!var}"
   fi
   SOURCETREE_FALLBACK_CONFIG_DIR="${value:-${SOURCETREE_FALLBACK_CONFIG_DIR}}"
   log_setting "${var} : ${value}"

   var="SOURCETREE_SCOPE_${symbol}"
   if [ ! -z "${ZSH_VERSION}" ]
   then
      value="${(P)var}"
   else
      value="${!var}"
   fi
   SOURCETREE_SCOPE="${value:-${SOURCETREE_SCOPE}}"
   log_setting "${var}               : ${value}"

   sourcetree::cfg::__common_configfile "$@"
   set +x
}


sourcetree::walk::cfg_read()
{
   log_entry "sourcetree::walk::cfg_read" "$@"

   local symbol="$1" ; shift

   local _configfile
   local _fallback_configfile

   sourcetree::walk::__common_configfile "${symbol}" "$1" "" "$2"

   if ! sourcetree::cfg::__resolve_configfile
   then
      return 1
   fi

   sourcetree::cfg::__read
}


#
# these can be prefixed for external queries
#
sourcetree::walk::r_config_exists()
{
   log_entry "sourcetree::walk::r_config_exists" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::walk::__common_configfile "$1"

   if [ -f "${_configfile}" ]
   then
      log_debug "\"${_configfile}\" exists"
      RVAL="${_configfile}"
      return 0
   fi

   if [ ! -z "${_fallback_configfile}" ] && [ -f "${_fallback_configfile}" ]
   then
      log_debug "\"${_fallback_configfile}\" exists"
      RVAL="${_fallback_configfile}"
      return 0
   fi

   log_debug "\"${_configfile}\" not found"
   RVAL=
   return 1
}


#
# walk_auto_uuid settingname,callback,permissions,SOURCETREE_DB_FILENAME ...
#
# datasource:  this is the current offset from ${PWD} where the config or
#              database resides  PWD=/
# virtual:     what to prefix addres with. Can be different than datasource
#              also is empty for PWD. (used in shared configuration)
#
# datasource
# virtual
#
# filternodetypes
# filterpermissions
# callbackqualifier
# descendqualifier
# mode
# ...
#
sourcetree::walk::_walk_config_uuids()
{
   log_entry "sourcetree::walk::_walk_config_uuids" "$@"

   local symbol="$1" ; shift

   local datasource="$1"
   local virtual="$2"
   local mode="$7"

   if sourcetree::walk::dedupe "${datasource}" "${mode}"
   then
      return 0
   fi

   # _address is in WALK_PARENT

   local nodelines

   if ! nodelines="`sourcetree::walk::cfg_read "${symbol}" "${datasource}" `"
   then
      log_debug "Config \"${datasource#${MULLE_USER_PWD}/}\" does not exist"
      return 0
   fi

   if [ -z "${nodelines}" ]
   then
      log_debug "Config \"${datasource#${MULLE_USER_PWD}/}\" has no nodes"
      return 0
   fi

   log_debug "Walking config \"${datasource#${MULLE_USER_PWD}/}\" nodes"
   sourcetree::walk::_walk_nodelines "${nodelines}" "$@"
}


sourcetree::walk::walk_config_uuids()
{
   log_entry "sourcetree::walk::walk_config_uuids" "$@"

   local VISITED
   local WALKED
   local rval
   local WALK_INDENT=""
   local WALK_LEVEL=0
   local WALK_INDEX=0
   local WALK_PARENT="${WALK_PARENT:-.}"

   WALKED=
   VISITED=
   sourcetree::walk::_walk_config_uuids "" "${SOURCETREE_START}" "" "$@"
   rval=$?

   # on 2, which is preempt we dont call the callback
   if [ $rval -eq 0 -a ! -z "${DID_WALK_CALLBACK}" ]
   then
      # keep callback signature somewhat uniform with other callbacks
      "${DID_WALK_CALLBACK}" "${SOURCETREE_START}" "" "$@"
   fi

   return $rval
}


#
# sourcetree::walk::walk_db_uuids
#
#
# datasource
# virtual
#
# filternodetypes
# filterpermissions
# callbackqualifier
# descendqualifier
# mode
#
# callback
# ...
#
sourcetree::walk::_walk_db_uuids()
{
   log_entry "sourcetree::walk::_walk_db_uuids" "$@"

   local symbol="$1" ; shift

   local datasource="$1"
   local virtual="$2"
   local mode="$7"

   if sourcetree::walk::dedupe "${datasource}" "${mode}"
   then
      return 0
   fi

   case ",${mode}," in
      *,no-dbcheck,*)
      ;;

      *)
         if sourcetree::walk::r_config_exists "${symbol}" "${datasource}" \
            && ! sourcetree::db::is_ready "${datasource}"
         then
            fail "The sourcetree at \"${datasource}\" is not updated fully \
yet, can not proceed"
         fi
      ;;
   esac

   local nodelines

   nodelines="`sourcetree::db::fetch_all_nodelines "${datasource}" `"  || exit 1
   if [ -z "${nodelines}" ]
   then
      log_fluff "Database \"${datasource}\" has no nodes"
      return 0
   fi

   log_fluff "Walking database \"${datasource}\" nodes"
   sourcetree::walk::_walk_nodelines "${nodelines}" "$@"
}


sourcetree::walk::walk_db_uuids()
{
   log_entry "sourcetree::walk::walk_db_uuids" "$@"

   # this is a subshell, so that the callback max call "exit"
   # to preempt walking
   local VISITED
   local WALKED
   local WALK_INDENT=""
   local WALK_LEVEL=0
   local WALK_INDEX=0

   WALKED=
   VISITED=
   sourcetree::walk::_walk_db_uuids "" "${SOURCETREE_START}" "" "$@"
   rval=$?

   if [ ! -z "${DID_WALK_CALLBACK}" ]
   then
      "${DID_WALK_CALLBACK}" "${SOURCETREE_START}" "" "$@"
      rval=$?
   fi

   return $rval
}


sourcetree::walk::_visit_root_callback()
{
   log_entry "sourcetree::walk::_visit_root_callback" "$@"

   local _address="."
   local _branch
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _raw_userinfo
   local _userinfo
   local _uuid

   sourcetree::walk::_visit_callback "" \
                   "${SOURCETREE_START}" \
                   "" \
                   "" \
                   "" \
                   "" \
                   "" \
                   "$@"
}


sourcetree::walk::do()
{
   log_entry "sourcetree::walk::do" "$@"

   local mode="$5"
   local callback="$6"

   [ -z "${mode}" ] && _internal_fail "mode can't be empty"

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
            *,pre-order,*|*,breadth-order,*)
               sourcetree::walk::_visit_root_callback "${mode}" "${callback}" "$@"
               rval=$?
            ;;
         esac
      ;;
   esac

   if [ $rval -eq 0 ]
   then
      case ",${mode}," in
         *,walkdb,*)
            sourcetree::walk::walk_db_uuids "$@"
            rval=$?
         ;;

         *)
            sourcetree::walk::walk_config_uuids "$@"
            rval=$?
         ;;
      esac
   fi

   if [ $rval -eq 0 ]
   then
      case ",${mode}," in
         *,callroot,*)
            case ",${mode}," in
               *,pre-order,*|*,breadth-order,*)
               ;;

               *)
                  sourcetree::walk::_visit_root_callback "${mode}" "${callback}" "$@"
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

   log_debug "sourcetree::walk::do rval=$rval"
   return $rval
}


sourcetree::walk::walk_internal()
{
   log_entry "sourcetree::walk::walk_internal" "$@"

   sourcetree::walk::do "" "" "" "" "$@"
}


sourcetree::walk::main()
{
   log_entry "sourcetree::walk::main" "$@"

   local MULLE_ROOT_DIR

   local OPTION_BEQUEATH='NO'
   local OPTION_CALLBACK_QUALIFIER=""
   local OPTION_CALLBACK_ROOT='DEFAULT'
   local OPTION_CALLBACK_TRACE='YES'
   local OPTION_CD='DEFAULT'
   local OPTION_COMMENTS='DEFAULT'
   local OPTION_DESCEND_QUALIFIER=""
   local OPTION_DIRECTION="FORWARD"
   local OPTION_EVAL='YES'
   local OPTION_EXTERNAL_CALL='YES'
   local OPTION_IGNORE
   local OPTION_LENIENT='NO'
   local OPTION_MARKS=""
   local OPTION_NODETYPES=""
   local OPTION_PERMISSIONS=""
   local OPTION_COMMENTS="D"
   local OPTION_QUALIFIER=""
   local OPTION_TRAVERSE_STYLE="PREORDER"
   local OPTION_WALK_DB='DEFAULT'
   local CONFIGURATION="Release"
   local WALK_VISIT_CALLBACK=
   local WALK_DESCEND_CALLBACK=
   local OPTION_DEDUPE_MODE=''
   local OPTION_MIN_WALK_LEVEL=
   local OPTION_MAX_WALK_LEVEL=

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::walk::usage
         ;;

         --configuration)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            CONFIGURATION="$1"
         ;;

         --comments)
            OPTION_COMMENTS='YES'
         ;;

         --no-comments)
            OPTION_COMMENTS='NO'
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

         --no-dedupe)
            OPTION_DEDUPE_MODE="none"
         ;;

         --bequeath)
            OPTION_BEQUEATH='YES'
         ;;

         --no-bequeath)
            OPTION_BEQUEATH='NO'
         ;;

         --dedupe|--dedupe-mode)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            OPTION_DEDUPE_MODE="$1"
         ;;

         --flat)
            OPTION_TRAVERSE_STYLE="FLAT"
         ;;

         --in-order)
            OPTION_TRAVERSE_STYLE="INORDER"
         ;;

         --pre-order)
            OPTION_TRAVERSE_STYLE="PREORDER"
         ;;

         --post-order|--breadth-last)
            OPTION_TRAVERSE_STYLE="POSTORDER"
         ;;

         --breadth-order|--breadth-first)
            OPTION_TRAVERSE_STYLE="BREADTH"
         ;;

         --backwards)
            OPTION_DIRECTION="BACKWARDS"
         ;;

         -l|--lenient)
            OPTION_LENIENT='YES'
         ;;

         --no-lenient)
            OPTION_LENIENT='NO'
         ;;

         --will-descend-callback|--will-recurse-callback)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            WILL_DESCEND_CALLBACK="$1"
         ;;

         --did-descend-callback|--did-recurse-callback)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            DID_DESCEND_CALLBACK="$1"
         ;;

         --did-walk-callback)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            DID_WALK_CALLBACK="$1"
         ;;

         --min-walk-level)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            OPTION_MIN_WALK_LEVEL="$1"
         ;;

         --max-walk-level)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            OPTION_MAX_WALK_LEVEL="$1"
         ;;

         #
         # filter flags
         #
         --declare-function)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            eval "$1" || fail "Callback \"${input}\" could not be parsed"
         ;;

         --callback-qualifier)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_CALLBACK_QUALIFIER="$1"
         ;;

         --descend-qualifier)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_DESCEND_QUALIFIER="$1"
         ;;

         -m|--marks)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${OPTION_MARKS}" "$1"
            OPTION_MARKS="${RVAL}"
         ;;

         --ignore)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            r_colon_concat "${OPTION_IGNORE}" "$1"
            OPTION_IGNORE="${RVAL}"
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            OPTION_NODETYPES="$1"
         ;;

         -p|--perm*)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            OPTION_PERMISSIONS="$1"
         ;;

         -q|--qualifier|--marks-qualifier)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_QUALIFIER="$1"
         ;;

         -*)
            sourcetree::walk::usage "Unknown walk option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -gt 1 ] && \
      shift && \
      sourcetree::walk::usage "Superflous arguments \"$*\". Pass callback \
as one string and use quotes."

   local mode

   mode="${SOURCETREE_MODE}"

   local callback

   if [ $# -eq 0 ]
   then
      callback='printf "%s\n" "${WALK_NODE}"'
      r_comma_concat "${mode}" "eval"
      mode="${RVAL}"
   else
      callback="$1"
      shift
   fi


   #
   # MEMO: as we are not binary tree but really a graph with multiple
   # siblings per node, an in-order traversal does not seem to make much sense
   # as the node would be visited repeatedly for each set of nodelines
   #
   case "${OPTION_TRAVERSE_STYLE}" in
      "FLAT")
         r_comma_concat "${mode}" "flat"
         mode="${RVAL}"
      ;;

      "INORDER")
         r_comma_concat "${mode}" "in-order"
         mode="${RVAL}"
      ;;

      "POSTORDER")
         r_comma_concat "${mode}" "post-order"
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

   case "${OPTION_DEDUPE_MODE}" in
      address|address-filename|address-marks-filename|address-url|filename|\
hacked-marks-nodeline-no-uuid|\
linkorder|nodeline|nodeline-no-uuid|none|url|url-filename)
         r_comma_concat "${mode}" "dedupe-${OPTION_DEDUPE_MODE}"
         mode="${RVAL}"
      ;;

      "")
      ;;

      *)
         fail "Unknown dedupe mode \"${OPTION_DEDUPE_MODE}\".
${C_INFO}Choose one of:
${C_RESET}   address address-filename address-marks-filename address-url
${C_RESET}   filename linkorder nodeline nodeline-no-uuid none url url-filename"
   esac

   # this usually adhere to the no-bequeath flags unless set to YES
   if [ "${OPTION_BEQUEATH}" = 'NO' ]
   then
      r_comma_concat "${mode}" "no-bequeath"
      mode="${RVAL}"
   fi
   if [ "${OPTION_CALLBACK_ROOT}" = 'YES' ]
   then
      r_comma_concat "${mode}" "callroot"
      mode="${RVAL}"
   fi
   if [ "${OPTION_CALLBACK_TRACE}" = 'NO' ]
   then
      r_comma_concat "${mode}" "no-trace"
      mode="${RVAL}"
   fi
   if [ "${OPTION_CD}" = 'YES' ]
   then
      r_comma_concat "${mode}" "docd"
      mode="${RVAL}"
   fi
   if [ "${OPTION_COMMENTS}" = 'YES' ]
   then
      r_comma_concat "${mode}" "comments"
      mode="${RVAL}"
   fi
   if [ "${OPTION_DIRECTION}" = "BACKWARDS" ]
   then
      r_comma_concat "${mode}" "backwards"
      mode="${RVAL}"
   fi
   if [ "${OPTION_EVAL}" = 'YES' ]
   then
      r_comma_concat "${mode}" "eval"
      mode="${RVAL}"
   fi
   if [ "${OPTION_EXTERNAL_CALL}" = 'YES' ]
   then
      r_comma_concat "${mode}" "external"
      mode="${RVAL}"
   fi
   if [ "${OPTION_LENIENT}" = 'YES' ]
   then
      r_comma_concat "${mode}" "lenient"
      mode="${RVAL}"
   fi
   if [ "${OPTION_WALK_DB}" = 'YES' ]
   then
      r_comma_concat "${mode}" "walkdb"
      mode="${RVAL}"
   fi

   # convert marks into a qualifier with globals
   if [ ! -z "${OPTION_MARKS}" ]
   then
      local mark

      IFS=","; shell_disable_glob
      for mark in ${OPTION_MARKS}
      do
         r_concat "${OPTION_QUALIFIER}" "MATCHES ${mark}" " AND "
         OPTION_QUALIFIER="${RVAL}"
      done
      IFS="${DEFAULT_IFS}"; shell_enable_glob
   fi

   #
   # Qualifier works for both, but you can specify each differently
   # use ANY to ignore one
   #
   OPTION_CALLBACK_QUALIFIER="${OPTION_CALLBACK_QUALIFIER:-${OPTION_QUALIFIER}}"

   sourcetree::walk::do "${OPTION_NODETYPES}" \
                   "${OPTION_PERMISSIONS}" \
                   "${OPTION_CALLBACK_QUALIFIER}" \
                   "${OPTION_DESCEND_QUALIFIER}" \
                   "${mode}" \
                   "${callback}" \
                   "$@"
}


sourcetree::walk::initialize()
{
   log_entry "sourcetree::walk::initialize"

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


sourcetree::walk::initialize

:

