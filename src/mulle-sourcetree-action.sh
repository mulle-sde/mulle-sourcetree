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
MULLE_SOURCETREE_ACTION_SH="included"


r_mulle_fetch_eval_options()
{
   log_entry "r_mulle_fetch_eval_options" "$@"

   local options

   # this implictily sets --symlink
   case "${OPTION_FETCH_SYMLINK}" in
      'NO')
      ;;

      'YES')
         r_concat "${options}" "--symlink-returns-4"
         options="${RVAL}"
      ;;

      "DEFAULT")
         if [ "${MULLE_SOURCETREE_SYMLINK}" = 'YES' ]
         then
            r_concat "${options}" "--symlink-returns-4"
            options="${RVAL}"
         fi
      ;;
   esac

   if [ "${OPTION_FETCH_ABSOLUTE_SYMLINK}" = 'YES' ]
   then
      r_concat "${options}" "--absolute-symlink"
      options="${RVAL}"
   fi

   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = 'YES' ]
   then
      r_concat "${options}" "--check-system-includes"
      options="${RVAL}"
   fi

   if [ ! -z "${OPTION_FETCH_CACHE_DIR}"  ]
   then
      r_concat "${options}" "--cache-dir '${OPTION_FETCH_CACHE_DIR}'"
      options="${RVAL}"
   fi

   if [ ! -z "${OPTION_FETCH_MIRROR_DIR}" ]
   then
      r_concat "${options}" "--mirror-dir '${OPTION_FETCH_MIRROR_DIR}'"
      options="${RVAL}"
   fi

   if [ ! -z "${OPTION_FETCH_SEARCH_PATH}" ]
   then
      r_concat "${options}" "--search-path '${OPTION_FETCH_SEARCH_PATH}'"
      options="${RVAL}"
   fi

   case "${OPTION_FETCH_REFRESH}" in
      YES)
         r_concat "${options}" "--refresh"
         options="${RVAL}"
      ;;
      NO)
         r_concat "${options}" "--no-refresh"
         options="${RVAL}"
      ;;
   esac

   RVAL="${options}"
}



##
## CLONE
##
_has_system_include()
{
   log_entry "_has_system_include" "$@"

   local _uuid="$1"

   local include_search_path="${HEADER_SEARCH_PATH}"

   if [ -z "${include_search_path}" ]
   then
      case "${MULLE_UNAME}" in
         mingw)
            include_search_path="~/include"
         ;;

         "")
            fail "UNAME not set yet"
         ;;

         darwin)
            # should check xcode paths too
            include_search_path="/usr/local/include:/usr/include"
         ;;

         *)
            include_search_path="/usr/local/include:/usr/include"
         ;;
      esac
   fi

   local includedir
   local includefile

   includedir="${_uuid//-/_}"
   includefile="${includedir}.h"

   if [ "${includedir}" = "${_uuid}" ]
   then
      includedir=""
   fi

   local i

   shell_disable_glob ; IFS=':'
   for i in ${include_search_path}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      if [ -d "${i}/${_uuid}" -o -f "${i}/${includefile}" ]
      then
         return 0
      fi

      if [ ! -z "${includedir}" ] && [ -d "${i}/${includedir}" ]
      then
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   return 1
}


# _is_embedded()
# {
#    local marks="$1"
#
#    case ",${marks}," in
#       *,no-build,*)
#       ;;
#
#       *)
#          return 1
#       ;;
#    esac
#
#    case ",${marks}," in
#       *,no-share,*)
#       ;;
#
#       *)
#          return 1
#       ;;
#    esac
#    return 0
# }


_do_fetch_operation()
{
   log_entry "_do_fetch_operation" "$@"

   local _address="$1"        # address of this node
   shift

   local _url="$1"            # URL of the node
   local destination="$2"     # destination
   local _branch="$3"         # branch of the node
   local _tag="$4"            # tag to checkout of the node
   local _nodetype="$5"       # nodetype to use for this node
   local _marks="$6"          # marks on node
   local _fetchoptions="$7"   # options to use on _nodetype
   local _raw_userinfo="$8"   # unused
   local _uuid="$9"           # uuid of the node

   [ -z "${destination}" ] && internal_fail "destination is empty"

   [ $# -eq 9 ] || internal_fail "fail"

   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = 'YES' ] && _has_system_include "${_uuid}"
   then
      log_info "${C_MAGENTA}${C_BOLD}${_uuid}${C_INFO} is a system library, so not fetching it"
      return 1
   fi

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != 'YES' ] && [ -e "${destination}" ]
   then
      fail "Should have cleaned \"${destination}\" beforehand. It's in the way."
   fi

   local parent

   r_mkdir_parent_if_missing "${destination}"
   parent="${RVAL}"

   local rval

   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      _branch="${OPTION_OVERRIDE_BRANCH}"
   fi

   local options

   r_mulle_fetch_eval_options
   options="${RVAL}"

   #
   # To inhibit the fetch of no-require dependencies, we check for
   # an environment variable MULLE_SOURCETREE_<identifier>_FETCH
   # Because of the no-require, this shouldn't abort the whole sync.
   # The net effect will be that this will not be part of the craft.
   #
   local envvar

   if [ -z "${MULLE_CASE_SH}" ]
   then
      # shellcheck source=mulle-case.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh" || return 1
   fi

   r_basename "${_address}"
   r_tweaked_de_camel_case "${RVAL}"
   r_identifier "${RVAL}"
   r_uppercase "${RVAL}"
   envvar="MULLE_SOURCETREE_FETCH_${RVAL}"

   local value

   if [ ! -z "${ZSH_VERSION}" ]
   then
      value="${(P)envvar}"
   else
      value="${!envvar}"
   fi

   log_fluff "Check \"${envvar}\" for \"${_address}\""
   if [ "${value}" = 'NO' ]
   then
      log_warning "${_address} not fetched as \"${envvar}\" is NO"
      return 1
   fi

   #
   # if this variable is set to 'YES' then we use the
   # only-platform- and no-platform- marks (if present) to possibly inhibit
   # the fetch. That's not 100% but can be very nice for example on macOS
   # to not fetch any X11 dependencies, which are unneeded
   #
   if [ "${MULLE_SOURCETREE_USE_PLATFORM_MARKS_FOR_FETCH}" = 'YES' ]
   then
      if nodemarks_disable "${_marks}" "platform-${MULLE_UNAME}"
      then
         log_warning "${C_RESET_BOLD}${_address#${MULLE_USER_PWD}/}${C_WARNING} \
not fetched as ${C_MAGENTA}${C_BOLD}platform-${MULLE_UNAME}${C_WARNING} is \
disabled by marks. (MULLE_SOURCETREE_USE_PLATFORM_MARKS_FOR_FETCH)"
         return
      fi
   fi

   sourcetree_sync_operation "${opname}" "${options}" \
                                         "${_url}" \
                                         "${destination}" \
                                         "${_branch}" \
                                         "${_tag}" \
                                         "${_nodetype}" \
                                         "${_fetchoptions}"
   rval="$?"
   case $rval in
      0)
      ;;

      4)
      ;;

      111)
         log_fail "Source \"${_nodetype}\" is unknown"
      ;;

      *)
         return $rval
      ;;
   esac

   if nodemarks_disable "${_marks}" "readwrite"
   then
      log_verbose "Write protecting \"${_address}\""
      exekutor find "${_address}" -type f -exec chmod a-w {} \;
   fi

   if [ ! -z "${UPTODATE_MIRRORS_FILE}" ]
   then
      redirect_append_exekutor "${UPTODATE_MIRRORS_FILE}" printf "%s\n" "${_url}"
   fi

   return $rval
}


do_operation()
{
   log_entry "do_operation" "$@"

   local opname="$1" ; shift

   if [ "${opname}" = "fetch" ]
   then
      _do_fetch_operation "$@"
      return $?
   fi

   [ -z "${opname}" ] && internal_fail "operation is empty"

#   local _address="$1"
   local _url="$2"            # URL of the node
   local destination="$3"     # destination
   local _branch="$4"         # branch of the node
   local _tag="$5"            # tag to checkout of the node
   local _nodetype="$6"       # nodetype to use for this node
#   local _marks="$7"         # marks on node
   local _fetchoptions="$8"   # options to use on _nodetype
#   local _raw_userinfo="$9"  # userinfo
#   shift; local _uuid="$10"          # uuid of the node

   [ -z "${destination}" ] && internal_fail "Destination is empty"

   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      _branch="${OPTION_OVERRIDE_BRANCH}"
   fi

   local options

   r_mulle_fetch_eval_options
   options="${RVAL}"

   sourcetree_sync_operation "${opname}" "${options}" \
                                         "${_url}" \
                                         "${destination}" \
                                         "${_branch}" \
                                         "${_tag}" \
                                         "${_nodetype}" \
                                         "${_fetchoptions}"
}


update_safe_move_node()
{
   log_entry "update_safe_move_node" "$@"

   local previousfilename="$1"
   local filename="$2"
   local _marks="$3"

   [ -z "${previousfilename}" ] && internal_fail "empty previousfilename"
   [ -z "${filename}" ]         && internal_fail "empty filename"

   if nodemarks_disable "${_marks}" "delete"
   then
      fail "Can't move node ${_url} from to \"${previousfilename}\" \
to \"${filename}\" as it is marked no-delete"
   fi

   log_info "Moving \"${previousfilename}\" to \"${filename}\""

   r_mkdir_parent_if_missing "${filename}"
   if ! exekutor mv ${OPTION_COPYMOVEFLAGS} "${previousfilename}" "${filename}"  >&2
   then
      fail "Move of ${C_RESET_BOLD}${previousfilename}${C_ERROR_TEXT} failed!"
   fi
}


update_safe_remove_node()
{
   log_entry "update_safe_remove_node" "$@"

   local filename="$1"
   local _marks="$2"
   local _uuid="$3"
   local database="$4"

   [ -z "${filename}" ] && internal_fail "empty filename"
   [ -z "${_uuid}" ]    && internal_fail "empty _uuid"

   if nodemarks_disable "${_marks}" "delete"
   then
      fail "Can't remove \"${filename}\" as it is marked no-delete"
   fi

   db_bury "${database}" "${_uuid}" "${filename}"
   db_forget "${database}" "${_uuid}"
}


update_safe_clobber()
{
   log_entry "update_safe_clobber" "$@"

   local filename="$1"
   local database="$2"

   [ -z "${filename}" ] && internal_fail "empty filename"

   r_node_uuidgen
   db_bury "${database}" "${RVAL}" "${filename}"
}


##
## this produces actions, does not care about _marks
##
r_update_actions_for_node()
{
   log_entry "r_update_actions_for_node" "$@"

   local style="$1"
   local newnodeline="$2"
   local newfilename="$3"
   local previousnodeline="$4"
   local previousfilename="$5"
   local database="$6"
   local config="$7"

   shift 7

   local newaddress="$1"    # address of this node
   local newnodetype="$2"   # nodetype to use for this node
   local newmarks="$3"      # marks to use for this node
   local newuuid="$4"       # uuid of the node
   local newurl="$5"        # URL of the node
   local newbranch="$6"     # branch of the node
   local newtag="$7"        # tag to checkout of the node

   local ACTIONS

   #
   # sanitize here because of paranoia and shit happes
   #
   local sanitized

   r_node_sanitized_address "${newaddress}"
   sanitized="${RVAL}"
   if [ "${newaddress}" != "${sanitized}" ]
   then
      fail "New _address \"${newaddress}\" looks suspicious ($sanitized), \
chickening out"
   fi

   #
   # but in terms of filesystem checks, we use "newfilename" from now on
   #
   local newexists

   newexists='NO'
   if [ -e "${newfilename}" ]
   then
      log_fluff "\"${newfilename#${MULLE_USER_PWD}/}\" already exists"
      newexists='YES'
   else
      if [ -L "${newfilename}" ]
      then
         log_fluff "Node \"${newfilename#${MULLE_USER_PWD}/}\" references a broken symlink \
\"${newfilename}\". Clobbering it"
         remove_file_if_present "${newfilename}"
      else
         log_debug "\"${newfilename#${MULLE_USER_PWD}/}\" is not there"
      fi
   fi

   #
   # NEW
   #
   # We remember a node, when we have fetched it. This way next time
   # there is a previous record and we know its contents. We have to fetch it
   # and remember it otherwise we don't know what we have.
   #
   if [ -z "${previousnodeline}" ]
   then
      log_debug "This is a new node"

      if [ "${newexists}" = 'YES' ]
      then
         # hmm, but why ?
         # 1. it's some old cruft that we should clobber
         # 2. it's been created by a different host
         #    we have no db knowledge if this is the proper version
         #    (check fixinfo if present))
         # 2. it's a minion that resides in the place for shared repos
         #    where we assume that the minion is the same as the shared repo
         #    (a minion is a local copy of a subproject). That was checked
         #    before though.
         # 3. it's a shared repo, that's been already placed there. Though
         #    at this point in time, that should have already been checked
         #    against

         if nodemarks_disable "${newmarks}" "delete"
         then
            case "${newnodetype}" in
               local)
                  log_fluff "Local node is present at \"${newfilename#${MULLE_USER_PWD}/}\". \
Very well just remember it."
               ;;

               *)
                  log_fluff "Node is new but \"${newfilename#${MULLE_USER_PWD}/}\" exists. \
As node is marked \"no-delete\" just remember it."
               ;;
            esac

            ACTIONS="remember"
            RVAL="${ACTIONS}"
            return
         fi

         if [ -f "${newfilename}/${SOURCETREE_FIX_FILENAME}" ]
         then
            local oldnodeline

            oldnodeline="`rexekutor egrep -s -v '^#' "${newfilename#${MULLE_USER_PWD}/}/${SOURCETREE_FIX_FILENAME}"`"
            if [ "${oldnodeline}" = "${nodeline}" ]
            then
               log_fluff "Fix info was written by identical config, so it looks ok"
               ACTIONS="remember"
               RVAL="${ACTIONS}"
               return
            fi
         fi

         log_fluff "Node is new, but \"${newfilename#${MULLE_USER_PWD}/}\" exists. Clobber it."
         update_safe_clobber "${newfilename}" "${database}"
         ACTIONS="remember"
      else
         if [ -z "${_url}" ]
         then
            fail "Node \"${newfilename#${MULLE_USER_PWD}/}\" has no URL and \
it doesn't exist (${PWD#${MULLE_USER_PWD}/})"
         fi

         local pretty_config

         pretty_config="${config#/}"
         pretty_config="${pretty_config%/}"
         if [ -z "${pretty_config}" ]
         then
            pretty_config="."
         fi
         log_verbose "Node \"${newfilename#${MULLE_USER_PWD}/}\" of \
sourcetree \"${pretty_config}\" is missing, so fetch"

#         if [ "${newaddress}" = "Foundation" ]
#         then
#            exit 1
#        fi
      fi

      r_add_line "${ACTIONS}" "fetch"
      return
   fi

   #
   # UPDATE
   #
   # We know that there is a previous record. We assume that the user may
   # have moved it, but we do not assume that he has manipulated it to
   # contain another _branch or _tag.
   #

   log_debug "This is a node update"

   #
   # easy and cheap cop out
   #
   if [ "${previousnodeline}" = "${newnodeline}" ]
   then
      log_fluff "Node \"${newfilename#${MULLE_USER_PWD}/}\" is unchanged"

      if [ "${newexists}" = 'YES' ]
      then
         RVAL="${ACTIONS}"
         return
      fi

      # someone removed it, fetch again
      RVAL="fetch"
      return
   fi

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _userinfo
   local _raw_userinfo
   local _uuid

   nodeline_parse "${previousnodeline}"  # memo: _marks not used

   if [ "${_uuid}" != "${newuuid}" ]
   then
      internal_fail "uuid \"${newuuid}\" wrong (expected \"${_uuid}\")"
   fi

   r_node_sanitized_address "${_address}"
   sanitized="${RVAL}"
   if [ "${_address}" != "${sanitized}" ]
   then
      fail "Old address \"${_address}\" looks suspicious (${sanitized}), \
chickening out"
   fi

   log_debug "Change: \"${previousnodeline}\" -> \"${newnodeline}\""

   local previousexists

   previousexists='NO'
   if [ -e "${previousfilename}" ]
   then
      previousexists='YES'
   fi

   #
   # Source change is big (except if old is symlink and new is git)
   #
   if [ "${_nodetype}" != "${newnodetype}" ]
   then
      if ! [ "${_nodetype}" = "symlink" -a "${newnodetype}" = "git" ]
      then
         log_verbose "Nodetype has changed from \"${_nodetype}\" to \
\"${newnodetype}\", need to fetch"

         # no-delete check here ?
         if [ "${previousexists}" = 'YES' ]
         then
            ACTIONS="remove"
         fi
         r_add_line "${ACTIONS}" "fetch"
         return
      fi
   fi

   #
   # Nothing there ?
   #
   if [ "${newexists}" = 'NO' -a "${previousexists}" = 'NO' ]
   then
      log_fluff "Previous destination \"${previousfilename}\" and \
current destination \"${newfilename}\" do not exist."
      r_add_line "${ACTIONS}" "fetch"
      return
   fi

   #
   # Handle positional changes
   #
   if [ "${previousfilename}" != "${newfilename}" ]
   then
      if [ "${newexists}" = 'YES' ]
      then
         if [ "${previousexists}" = 'YES' ]
         then
            log_warning "Destinations new \"${newfilename}\" and \
old \"${previousfilename}\" exist. Doing nothing."
         else
            log_fluff "Destinations new \"${newfilename}\" and \
old \"${previousfilename}\" exist. Looks like a manual move. Doing nothing."
         fi
         ACTIONS="remember"
      else
         #
         # Just old is there, so move it. We already checked
         # for the case where both are absent.
         #
         log_verbose "Address changed from \"${_address}\" to \
\"${newaddress}\", need to move"
         ACTIONS="move"
      fi
   fi

   #
   # Check that the _nodetype can actually do the supported operation
   #
   case "${_nodetype}" in
      symlink)
         if [ "${newexists}" = 'YES' ]
         then
            log_fluff "\"${newfilename}\" is symlink. Ignoring possible \
differences in URL related info."
            RVAL="${ACTIONS}"
            return
         fi
      ;;
   esac

   if [ -z "${_url}" ]
   then
      log_fluff "\"${newfilename}\" has no URL. Ignoring possible differences \
in URL related info."
      RVAL="${ACTIONS}"
      return
   fi

   local available

   if [ "${_branch}" != "${newbranch}" -o \
        "${_tag}" != "${newtag}" -o \
        "${_url}" != "${newurl}" ]
   then
      # need to eval it...
      local evalednodetype

      r_expanded_string "${_nodetype}"
      evalednodetype="${RVAL}"
      r_sourcetree_list_operations "${evalednodetype}"
      available="${RVAL}" || return 1
   fi

   if [ "${_branch}" != "${newbranch}" ]
   then
      if find_line "${available}" "checkout"
      then
         log_verbose "Branch has changed from \"${_branch}\" to \
\"${newbranch}\", need to checkout"
         r_add_line "${ACTIONS}" "checkout"
         ACTIONS="${RVAL}"
      else
         log_verbose "Branch has changed from \"${_branch}\" to \
\"${newbranch}\", need to fetch"
         if [ "${previousexists}" = 'YES' ]
         then
            r_add_line "${ACTIONS}" "remove"
            ACTIONS="${RVAL}"
         fi

         r_add_line "${ACTIONS}" "fetch"
         return
      fi
   fi

   if [ "${_tag}" != "${newtag}" ]
   then
      if find_line "${available}" "checkout"
      then
         log_verbose "Tag has changed from \"${_tag}\" to \"${newtag}\", need \
to checkout"
         r_add_line "${ACTIONS}" "checkout"
         ACTIONS="${RVAL}"
      else
         log_verbose "Tag has changed from \"${_tag}\" to \"${newtag}\", need \
to fetch"
         if [ "${previousexists}" = 'YES' ]
         then
            r_add_line "${ACTIONS}" "remove"
            ACTIONS="${RVAL}"
         fi

         r_add_line "${ACTIONS}" "fetch"
         return
      fi
   fi

   if [ "${_url}" != "${newurl}" ]
   then
      if find_line "${available}" "upgrade" && find_line "${available}" "set-url"
      then
         log_verbose "URL has changed from \"${_url}\" to \"${newurl}\", need to \
set remote _url and fetch"
         r_add_line "${ACTIONS}" "set-url"
         r_add_line "${RVAL}" "upgrade"
         ACTIONS="${RVAL}"
      else
         log_verbose "URL has changed from \"${_url}\" to \"${newurl}\", need to \
fetch"
         if [ "${previousexists}" = 'YES' ]
         then
            r_add_line "${ACTIONS}" "remove"
            ACTIONS="${RVAL}"
         fi

         r_add_line "${ACTIONS}" "fetch"
         return
      fi
   fi

   RVAL="${ACTIONS}"
}


#
# uses variables from enclosing function
# just here for readability and to pipe stdout into stderr
#
__update_perform_item()
{
   log_entry "__update_perform_item"

   [ -z "${filename}" ] && internal_fail "filename is empty"

   case "${item}" in
      "checkout"|"upgrade"|"set-url")
         if ! do_operation "${item}" "${_address}" \
                                     "${_url}" \
                                     "${filename}" \
                                     "${_branch}" \
                                     "${_tag}" \
                                     "${_nodetype}" \
                                     "${_marks}" \
                                     "${_fetchoptions}" \
                                     "${_raw_userinfo}" \
                                     "${_uuid}"
         then
            # as these are shortcuts to remove/fetch, but the
            # fetch part didn't work out we need to remove
            # the previousaddress
            update_safe_remove_node "${previousfilename}" "${_marks}" "${_uuid}" "${database}"
            log_fluff "Failed to ${item} ${_url}" # operation should have errored already
            exit 1
         fi
         _contentschanged='YES'
         _remember='YES'
      ;;

      "fetch")
         do_operation "fetch" "${_address}" \
                              "${_url}" \
                              "${filename}" \
                              "${_branch}" \
                              "${_tag}" \
                              "${_nodetype}" \
                              "${_marks}" \
                              "${_fetchoptions}" \
                              "${_raw_userinfo}" \
                              "${_uuid}"

         case "$?" in
            0)
               _contentschanged='YES'
            ;;

            4)
               # if we used a symlink, we want to memorize that
               _nodetype="symlink"

               # we don't really want to update that
               _contentschanged='NO'
            ;;

            *)
               #
               # if the fetch fails, it can be that we get a partial remnant
               # here which can really mess up the next fetch. So we remove it
               #
               if [ -e "${filename}" ]
               then
                   if [ -L "${filename}" ]
                   then
                      log_verbose "Removing old symlink \"${filename}\""
                      exekutor rm -f "${filename}" >&2
                  else
                     update_safe_clobber "${database}" "${filename}"
                  fi
               fi

               if nodemarks_disable "${_marks}" "require" ||
                  nodemarks_disable "${_marks}" "require-os-${MULLE_UNAME}"
               then
                  log_info "${C_MAGENTA}${C_BOLD}${filename}${C_INFO} is not required."

                  db_add_missing "${database}" "${_uuid}" "${nodeline}"
                  _skip='YES'
                  return 1
               fi

               fail "The fetch of \"${_address}\" failed and it is required."
            ;;
         esac

         if [ -f "${filename}/.mulle-sourcetree/config" -a ! -f "${filename}/.mulle/etc/sourcetree/config" ]
         then
            log_warning "\"`basename -- "${filename}"`\" contains an old-fashioned sourcetree \
which must be upgraded to be usable."
         fi

         _remember='YES'
      ;;

      "remember")
         _remember='YES'
      ;;

      "move")
         update_safe_move_node "${previousfilename}" "${filename}" "${_marks}"
         _remember='YES'
      ;;

      "clobber")
         update_safe_clobber "${filename}" "${database}"
      ;;

      "remove")
         update_safe_remove_node "${previousfilename}" "${_marks}" "${_uuid}" "${database}"
      ;;

      *)
         internal_fail "Unknown action item \"${item}\""
      ;;
   esac
}


#
# these are the return values (outside of RVAL)
#
# _contentschanged
# _remember
# _skip
# _nodetype

__update_perform_actions()
{
   log_entry "__update_perform_actions" "$@"

   local style="$1"
   local nodeline="$2"
   local filename="$3"
   local previousnodeline="$4"
   local previousfilename="$5"
   local database="$6"  # used in _perform
   local config="$7"

   local _branch
   local _address
   local _fetchoptions
   local _marks
#   local _nodetype
   local _tag
   local _url
   local _userinfo
   local _raw_userinfo
   local _uuid

   nodeline_parse "${nodeline}"     # !!

   local actionitems
   local dbfilename

   r_update_actions_for_node "${style}" \
                             "${nodeline}" \
                             "${filename}" \
                             "${previousnodeline}" \
                             "${previousfilename}" \
                             "${database}" \
                             "${config}" \
                             "${_address}" \
                             "${_nodetype}" \
                             "${_marks}" \
                             "${_uuid}" \
                             "${_url}" \
                             "${_branch}" \
                             "${_tag}"
   actionitems="${RVAL}"

   log_debug "${C_INFO}Actions for \"${_address}\": ${actionitems:-none}"

   _contentschanged='NO'
   _remember='NO'
   _skip='NO'

   local item

   shell_disable_glob
   for item in ${actionitems}
   do
      shell_enable_glob

      if ! __update_perform_item
      then
         break
      fi
   done
   shell_enable_glob
}


_memorize_node_in_db()
{
   log_entry "_memorize_node_in_db" "$@"

   local database="$1"
   local config="$2"
   local filename="$3"
#
   local nodeline

   r_node_to_nodeline
   nodeline="${RVAL}"

   local _evaledurl
   local _evalednodetype
   local _evaledbranch
   local _evaledtag
   local _evaledfetchoptions

   node_evaluate_values

   log_debug "${C_INFO}Remembering ${_address} located at \"${filename}\" \
in \"${database}\"..."

   db_memorize "${database}" \
               "${_uuid}" \
               "${nodeline}" \
               "${config}" \
               "${filename}" \
               "${_evaledurl}"
}


write_fix_info()
{
   log_entry "write_fix_info" "$@"

   local nodeline="$1"
   local filename="$2"

   local output

   if [ -L "${filename}" ]
   then
      log_fluff "Not putting fix info into a symlink (${filename})"
      return
   fi

   # don't do this as it resolved symlinks that we might need
   # filename="`physicalpath "${filename}" `"

   [ -z "${SOURCETREE_FIX_FILENAME}" ] \
   && internal_fail "SOURCETREE_FIX_FILENAME is empty"

   r_filepath_concat "${filename}" "${SOURCETREE_FIX_FILENAME}"
   output="${RVAL}"

   log_fluff "Writing fix info into \"${output}\""

   local text

   text="# this file is generated by mulle-sourcetree
${nodeline}"

   r_mkdir_parent_if_missing "${output}"
   redirect_exekutor "${output}" printf "%s\n" "${text}" \
   || internal_fail "failed to write fixinfo \"${output}\""
}


_r_do_actions_with_nodeline()
{
   log_entry "_r_do_actions_with_nodeline" "$@"

   local nodeline="$1"
   local style="$2"
   local config="$3"
   local database="$4"

   [ "$#" -ne 4 ]     && internal_fail "api error"

   [ -z "$style" ]    && internal_fail "style is empty"
   [ -z "$nodeline" ] && internal_fail "nodeline is empty"

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _userinfo
   local _raw_userinfo
   local _uuid

   nodeline_parse "${nodeline}"  # !!

   if nodemarks_disable "${_marks}" "fs"
   then
      log_fluff "\"${_address}\" is marked as no-fs, so nothing to update"
      return 2
   fi

   local _evaledurl
   local _evalednodetype
   local _evaledbranch
   local _evaledtag
   local _evaledfetchoptions

   node_evaluate_values

   if [ "${_evalednodetype}" = 'comment' ]
   then
      log_debug "\"${_address}\" is a comment, so nothing to update"
      return 2
   fi

   #
   # the address is what is relative to the current config (configfile)
   # the filename is an absolute path
   #
   local filename

   if [ ! -z "${_evaledurl}" -a "${style}" = "share" ] \
      && nodemarks_enable "${_marks}" "share"
   then
      r_db_update_determine_share_filename "${_address%#*}" \
                                           "${_evaledurl}" \
                                           "${_evalednodetype}" \
                                           "${_marks}" \
                                           "${_uuid}" \
                                           "${database}"
      case $? in
         0)
            filename="${RVAL}"
         ;;

         1)
            exit 1
         ;;

         3)
            return 0
         ;;
         #

         *)
            internal_fail "unknown code"
         ;;
      esac
      database='/'
   else
      r_cfg_absolute_filename "${config}" "${_address%#*}" "${style}"
      filename="${RVAL}"
   fi

   r_simplified_absolutepath "${filename}"
   filename="${RVAL}"

   [ -z "${filename}" ] && internal_fail "Filename is empty for \"${_address}\""

   log_fluff "Filename for node \"${_address}\" is \"${filename}\""

   [ -z "${database}" ] && internal_fail "A share-only update gone wrong"

   if nodemarks_disable "${_marks}" "update"
   then
      if [ ! -e "${filename}"  ]
      then
         if nodemarks_disable "${_marks}" "require" ||
            nodemarks_disable "${_marks}" "require-os-${MULLE_UNAME}"
         then
            log_fluff "\"${_address}\" is marked as no-update and doesn't exist, \
but it is not required"
            return 2
         fi

         fail "\"${_address}\" is missing, marked as no-update, but its required"
      fi

      log_fluff "\"${_address}\" is marked as no-update and exists"

      # still need to memorize this though, so it can be shared
      if ! is_absolutepath "${filename}"
      then
         r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${filename}"
         filename="${RVAL}"
      fi

      _memorize_node_in_db "${database}" "${config}" "${filename}"
      RVAL="${_uuid}"
      return 0
   fi

   #
   # If we find something in the database for the same address,
   # check if it is ours. This could be a new entry/edit whatever.
   # But it could be old. If its not old, it has preference.
   # A general problem, why we check for _address here is, that the filename
   # due to symlinking is unpredictable.
   #
   # If we are in share mode, then the database is "/" here, so no worries
   # We don't have to check the owner, because the uuid will be different
   # to ours. (since it's coming from a different config)
   # Search for absolute path, as that is what gets stored into the DB
   #
   local otheruuid

   otheruuid="`db_fetch_uuid_for_address "${database}" "${_address}"`"
   if [ ! -z "${otheruuid}" ]
   then
      if db_is_uuid_alive "${database}" "${otheruuid}"
      then
         if [ "${otheruuid}" != "${_uuid}" ]
         then
            # this is _address is already taken
            log_fluff "Filename \"${filename}\" is already used by \
node \"${otheruuid}\" in database \"${database}\". Skip it."
            # don't set alive though
            # RVAL="${otheruuid}" (or set other alive ?)
            return 2
         fi
         log_debug "Filename \"${filename}\" belongs to this node"
      else
         log_debug "Prepare zombie \"${filename}\" for resurrection"
      fi
   else
      log_debug "Filename \"${filename}\" is not yet in \"${database}\""
   fi

   #
   # check if this nodeline is already known (this being an update)
   #
   local previousnodeline
   local previousfilename
   local previousaddress

   previousnodeline="`db_fetch_nodeline_for_uuid "${database}" "${_uuid}"`"

   #
   # find out, where it was previously located
   #
   if [ ! -z "${previousnodeline}" ]
   then
      previousfilename="`db_fetch_filename_for_uuid "${database}" "${_uuid}"`"

      [ -z "${previousfilename}" ] && internal_fail "corrupted db"
   else
      if [ -L "${filename}" ]
      then
         #
         # if we remove this old link, it could have been placed by a duplicate
         # and be valid, we should really check this differently...
         # But really, the duplicate should be marked as no-fs
         #
         log_verbose "Removing an old symlink \"${filename}\" for safety"
         exekutor rm -f "${filename}" || exit 1
#      else
#         if [ -e "${filename}" ]
#         then
#            log_fluff "${filename} is present"
#         fi
      fi
   fi

   #
   # For symlinks, we only care if the filename changes
   #
   if [ "${filename}" = "${previousfilename}" -a -L "${filename}" ]
   then
      log_debug "Skip update of \"${filename}\" since it's a symlink."

      _memorize_node_in_db "${database}" "${config}" "${filename}"
      RVAL="${_uuid}"
      return 0
   fi

   #
   # candidate for parallelization
   #
   local _contentschanged
   local _remember
   local _skip

   __update_perform_actions "${style}" \
                            "${nodeline}" \
                            "${filename}" \
                            "${previousnodeline}" \
                            "${previousfilename}" \
                            "${database}" \
                            "${config}"

   log_debug "\
contentschanged : ${_contentschanged}
remember        : ${_remember}
skip            : ${_skip}
nodetype        : ${_nodetype}"

   if [ "${_skip}" = 'YES' ]
   then
      log_debug "Skipping to next nodeline as indicated..."
      return 0
   fi

   if [ "${_remember}" = 'YES' ]
   then
      if ! is_absolutepath "${filename}"
      then
         r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${filename}"
         filename="${RVAL}"
      fi

      _memorize_node_in_db "${database}" "${config}" "${filename}"

      if [ "${OPTION_FIX}" != 'NO' ] && [ -d "${filename}" ]
      then
         # we memorize the original config nodeline for easier comparison
         write_fix_info "${nodeline}" "${filename}"
      fi
   else
      log_debug "Don't need to remember \"${nodeline}\" (should be unchanged)"
   fi

   RVAL="${_uuid}"
   return 0
}


do_actions_with_nodeline()
{
   log_entry "do_actions_with_nodeline" "$@"

#   local nodeline="$1"
#   local style="$2"
#   local config="$3"
   local database="$4"

   log_entry "do_actions_with_nodeline" "$@"
   if _r_do_actions_with_nodeline "$@"
   then
      # this could be executed in parallel ?
      db_set_uuid_alive "${database}" "${RVAL}"
   fi
}


do_actions_with_nodelines()
{
   log_entry "do_actions_with_nodelines" "$@"

   local nodelines="$1"
   local style="$2"
   local config="$3"
   local database="$4"

   [ -z "${style}" ] && internal_fail "style is empty"

   if [ -z "${nodelines}" ]
   then
      log_fluff "There is nothing to do for \"${style}\""
      return 0
   fi

   log_debug "\"${style}\" update \"${nodelines}\" for db \"${config:-ROOT}\" (${PWD#${MULLE_USER_PWD}/})"

   local nodeline
   local rval

   rval=0
   shell_disable_glob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      if [ ! -z "${nodeline}" ]
      then
         if ! do_actions_with_nodeline "${nodeline}" "${style}" "${config}" "${database}"
         then
            rval=1
            break
         fi
      fi
   done

   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   return $rval
}


do_actions_with_nodelines_parallel()
{
   log_entry "do_actions_with_nodelines_parallel" "$@"

   local nodelines="$1"
   local style="$2"
   local config="$3"
   local database="$4"

   [ -z "${style}" ] && internal_fail "style is empty"

   if [ -z "${nodelines}" ]
   then
      log_fluff "There is nothing to do for \"${style}\""
      return 0
   fi

   log_debug "\"${style}\" update \"${nodelines}\" for db \"${config:-ROOT}\" (${PWD#${MULLE_USER_PWD}/})"

   local nodeline

   local _parallel_statusfile
   local _parallel_maxjobs
   local _parallel_jobs
   local _parallel_fails

   _parallel_begin

   shell_disable_glob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      if [ ! -z "${nodeline}" ]
      then
         _parallel_execute do_actions_with_nodeline "${nodeline}" "${style}" "${config}" "${database}"
         _parallel_status $? do_actions_with_nodeline "${nodeline}" "${style}" "${config}" "${database}"
      fi
   done

   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   _parallel_end
}


sourcetree_action_initialize()
{
   log_entry "sourcetree_action_initialize"

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
   if [ -z "${MULLE_SOURCETREE_FETCH_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-callback.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-fetch.sh" || exit 1
   fi
   if [ -z "${MULLE_PARALLEL_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-parallel.sh" || exit 1
   fi
}


sourcetree_action_initialize

:
