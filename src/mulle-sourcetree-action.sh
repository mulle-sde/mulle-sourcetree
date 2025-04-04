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
MULLE_SOURCETREE_ACTION_SH='included'


sourcetree::action::is_embedded()
{
   local marks="$1"

   case ",${marks}," in
      *,no-build,*)
      ;;

      *)
         return 1
      ;;
   esac

   case ",${marks}," in
      *,no-share,*)
      ;;

      *)
         return 1
      ;;
   esac
   return 0
}


sourcetree::action::r_fetch_eval_options()
{
   log_entry "sourcetree::action::r_fetch_eval_options" "$@"

   local marks="$1"

   local options
   local option_symlink="${OPTION_FETCH_SYMLINK}"

   if sourcetree::marks::disable "${marks}" "symlink" || \
      sourcetree::marks::disable "${marks}" "symlink-${MULLE_UNAME}"
   then
      r_concat "${options}" "--no-symlink"
      options="${RVAL}"
      option_symlink='NO'
   else
      case "${MULLE_UNAME}" in
         'windows'|'mingw'|'msys')
            # cl.exe/cmake.exe don't like embedded symlinks,so turn off
            if sourcetree::action::is_embedded "${marks}"
            then
               option_symlink='NO'
            fi
         ;;
      esac

      # this implictily sets --symlink
      case "${option_symlink}" in
         'NO')
            r_concat "${options}" "--no-symlink"
            options="${RVAL}"
         ;;

         'YES')
            r_concat "${options}" "--symlink-returns-4"
            options="${RVAL}"
            option_symlink='YES'
         ;;

         "DEFAULT")
            option_symlink='NO'
            if [ "${MULLE_SOURCETREE_SYMLINK}" = 'YES' ]
            then
               r_concat "${options}" "--symlink-returns-4"
               options="${RVAL}"
               option_symlink='YES'
            fi
         ;;
      esac

      if [ "${option_symlink}" = 'YES' -a "${OPTION_FETCH_ABSOLUTE_SYMLINK}" = 'YES' ]
      then
         r_concat "${options}" "--absolute-symlink"
         options="${RVAL}"
      fi
   fi
   
   if [ "${option_symlink}" = 'NO' ]
   then
      if sourcetree::marks::disable "${marks}" "readwrite"
      then
         r_concat "${options}" "--write-protect"
         options="${RVAL}"
      fi
   fi

#   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = 'YES' ]
#   then
#      r_concat "${options}" "--check-system-includes"
#      options="${RVAL}"
#   fi

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
         r_concat "${options}" "
         "
         options="${RVAL}"
      ;;
   esac

   RVAL="${options}"
}



##
## CLONE
##

#
# this is questionable and possibly even bad
#
sourcetree::action::has_system_include()
{
   log_entry "sourcetree::action::has_system_include" "$@"

   local uuid="$1"

   local include_search_path="${HEADER_SEARCH_PATH}"

   if [ -z "${include_search_path}" ]
   then
      case "${MULLE_UNAME}" in
         'mingw'|'msys'|'android')
            include_search_path="~/include"
         ;;

         "")
            fail "UNAME not set yet"
         ;;

         'darwin')
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

   includedir="${uuid//-/_}"
   includefile="${includedir}.h"

   if [ "${includedir}" = "${uuid}" ]
   then
      includedir=""
   fi

   local i

   .foreachpath i in ${include_search_path}
   .do
      if [ -d "${i}/${uuid}" -o -f "${i}/${includefile}" ]
      then
         return 0
      fi

      if [ ! -z "${includedir}" ] && [ -d "${i}/${includedir}" ]
      then
         return 0
      fi
   .done

   return 1
}



sourcetree::action::_do_fetch_operation()
{
   log_entry "sourcetree::action::_do_fetch_operation" "$@"

   local address="$1"        # address of this node
   shift

   local url="$1"            # URL of the node
   local destination="$2"    # destination
   local branch="$3"         # branch of the node
   local tag="$4"            # tag to checkout of the node
   local nodetype="$5"       # nodetype to use for this node
   local marks="$6"          # marks on node
   local fetchoptions="$7"    # options to use on nodetype
   local raw_userinfo="$8"   # unused
   local uuid="$9"           # uuid of the node

   [ -z "${destination}" ] && _internal_fail "destination is empty"

   [ $# -eq 9 ] || _internal_fail "fail"

   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = 'YES' ] && sourcetree::action::has_system_include "${uuid}"
   then
      log_info "${C_MAGENTA}${C_BOLD}${uuid}${C_INFO} is a system library, so not fetching it"
      return 1
   fi

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != 'YES' ] && [ -e "${destination}" ]
   then
      fail "Should have cleaned \"${destination#${MULLE_USER_PWD}/}\" beforehand. It's in the way."
   fi

   local parent

   r_mkdir_parent_if_missing "${destination}"
   parent="${RVAL}"

   local rval

   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      branch="${OPTION_OVERRIDE_BRANCH}"
   fi

   local options

   sourcetree::action::r_fetch_eval_options "${marks}"
   options="${RVAL}"

   #
   # To inhibit the fetch of no-require dependencies, we check for
   # an environment variable MULLE_SOURCETREE_<identifier>_FETCH
   # Because of the no-require, this shouldn't abort the whole sync.
   # The net effect will be that this will not be part of the craft.
   #
   local envvar

   include "case"

   r_basename "${address}"
   r_smart_file_upcase_identifier "${RVAL}"
   envvar="MULLE_SOURCETREE_FETCH_${RVAL}"

   local value

   r_shell_indirect_expand "${envvar}"
   value="${RVAL}"

   log_fluff "Check \"${envvar}\" for \"${address}\""
   if [ "${value}" = 'NO' ]
   then
      log_warning "${address} not fetched as \"${envvar}\" is NO"
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
      if sourcetree::marks::disable "${marks}" "platform-${MULLE_UNAME}"
      then
         _log_info "${C_RESET_BOLD}${address#"${MULLE_USER_PWD}/"}${C_INFO} \
not fetched as ${C_MAGENTA}${C_BOLD}platform-${MULLE_UNAME}${C_INFO} is \
disabled by marks. (MULLE_SOURCETREE_USE_PLATFORM_MARKS_FOR_FETCH)"
         return
      fi
   fi

   sourcetree::fetch::sync_operation "${opname}" "${options}" \
                                                 "${url}" \
                                                 "${destination}" \
                                                 "${branch}" \
                                                 "${tag}" \
                                                 "${nodetype}" \
                                                 "${fetchoptions}"
   rval="$?"
   case $rval in
      0)
      ;;

      4)
      ;;

      111)
         fail "Source \"${nodetype}\" is unknown"
      ;;

      *)
         return $rval
      ;;
   esac


   if [ ! -z "${UPTODATE_MIRRORS_FILE}" ]
   then
      redirect_append_exekutor "${UPTODATE_MIRRORS_FILE}" printf "%s\n" "${url}"
   fi

   return $rval
}


sourcetree::action::do_operation()
{
   log_entry "sourcetree::action::do_operation" "$@"

   local opname="$1" ; shift

   if [ "${opname}" = "fetch" ]
   then
      sourcetree::action::_do_fetch_operation "$@"
      return $?
   fi

   [ -z "${opname}" ] && _internal_fail "operation is empty"

#   local address="$1"
   local url="$2"            # URL of the node
   local destination="$3"    # destination
   local branch="$4"         # branch of the node
   local tag="$5"            # tag to checkout of the node
   local nodetype="$6"       # nodetype to use for this node
   local marks="$7"         # marks on node
   local fetchoptions="$8"   # options to use on nodetype
#   local raw_userinfo="$9"  # userinfo
#   shift; local uuid="$10"  # uuid of the node

   [ -z "${destination}" ] && _internal_fail "Destination is empty"

   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      branch="${OPTION_OVERRIDE_BRANCH}"
   fi

   local options

   sourcetree::action::r_fetch_eval_options "${marks}"
   options="${RVAL}"

   sourcetree::fetch::sync_operation "${opname}" "${options}" \
                                                 "${url}" \
                                                 "${destination}" \
                                                 "${branch}" \
                                                 "${tag}" \
                                                 "${nodetype}" \
                                                 "${fetchoptions}"
}


sourcetree::action::update_safe_move_node()
{
   log_entry "sourcetree::action::update_safe_move_node" "$@"

   local previousfilename="$1"
   local filename="$2"
   local marks="$3"

   [ -z "${previousfilename}" ] && _internal_fail "empty previousfilename"
   [ -z "${filename}" ]         && _internal_fail "empty filename"

   if sourcetree::marks::disable "${marks}" "delete"
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


sourcetree::action::update_safe_remove_node()
{
   log_entry "sourcetree::action::update_safe_remove_node" "$@"

   local filename="$1"
   local marks="$2"
   local uuid="$3"
   local database="$4"

   [ -z "${filename}" ] && _internal_fail "empty filename"
   [ -z "${uuid}" ]    && _internal_fail "empty uuid"

   if sourcetree::marks::disable "${marks}" "delete"
   then
      fail "Can't remove \"${filename}\" as it is marked no-delete"
   fi

   sourcetree::db::bury "${database}" "${uuid}" "${filename}" &&
   sourcetree::db::forget "${database}" "${uuid}"
}


sourcetree::action::update_safe_clobber()
{
   log_entry "sourcetree::action::update_safe_clobber" "$@"

   local filename="$1"
   local database="$2"

   [ -z "${filename}" ] && _internal_fail "empty filename"

   sourcetree::node::r_uuidgen
   sourcetree::db::bury "${database}" "${RVAL}" "${filename}"
}


sourcetree::action::is_squatted_filename()
{
   log_entry "sourcetree::action::is_squatted_filename" "$@"

   local newfilename="$1"

   local othernodeline

   if ! othernodeline="`sourcetree::db::fetch_nodeline_for_filename "/" "${newfilename}"`"
   then
      return 1
   fi

   local _nodetype
   local _address
   local _marks

   sourcetree::nodeline::__get_address_nodetype_marks "${othernodeline}"
   if ! sourcetree::marks::disable "${_marks}" "share-shirk"
   then
      return 1
   fi
   log_fluff "Node \"${newfilename}\" is squatted by ${_address}"
   return 0
}


##
## this produces actions, does not care about _marks
##
sourcetree::action::r_update_actions_for_node()
{
   log_entry "sourcetree::action::r_update_actions_for_node" "$@"

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

   sourcetree::node::r_sanitized_address "${newaddress}"
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
      log_fluff "\"${newfilename#"${MULLE_USER_PWD}/"}\" already exists"
      newexists='YES'
   else
      if [ -L "${newfilename}" ]
      then
         _log_fluff "Node \"${newfilename#"${MULLE_USER_PWD}/"}\" references a \
broken symlink \"${newfilename}\". Clobbering it"
         remove_file_if_present "${newfilename}"
      else
         log_debug "\"${newfilename#"${MULLE_USER_PWD}/"}\" is not there"
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
      log_debug "\"${_address}\" would be a new node"

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
         if sourcetree::marks::disable "${newmarks}" "clobber"
         then
            _log_fluff "Node \"${_address}\" is new but \"${newfilename#"${MULLE_USER_PWD}/"}\" exists. \
As node is marked \"no-clobber\" just remember it."
            ACTIONS="remember"
            RVAL="${ACTIONS}"
            return
         fi

         if sourcetree::marks::disable "${newmarks}" "delete"
         then
            case "${newnodetype}" in
               local)
                  _log_fluff "Local node \"${_address}\ is present at \"${newfilename#"${MULLE_USER_PWD}/"}\". \
Very well just remember it."
               ;;

               *)
                  _log_fluff "Node \"${_address}\" is new but \"${newfilename#"${MULLE_USER_PWD}/"}\" exists. \
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

            oldnodeline="`rexekutor grep -E -v '^#' "${newfilename}/${SOURCETREE_FIX_FILENAME}"`"
            if [ "${oldnodeline}" = "${nodeline}" ]
            then
               log_fluff "Fix info for \"${newfilename}\" was written by identical config, so it looks ok"
               ACTIONS="remember"
               RVAL="${ACTIONS}"
               return
            fi
         fi

         log_fluff "Node \"${_address}\" is new, but \"${newfilename#"${MULLE_USER_PWD}/"}\" exists. Clobber it."
         sourcetree::action::update_safe_clobber "${newfilename}" "${database}"
         ACTIONS="remember"
      else
         if [ -z "${_url}" ]
         then
            fail "Node \"${newfilename#"${MULLE_USER_PWD}/"}\" has no URL and \
it doesn't exist (${PWD#"${MULLE_USER_PWD}/"})"
         fi

         # could be that its an amalgamation, check that and if yes just ignore
         # An amalgamation writes two db entries, one for its embedding and
         # one squats out space, lets get that and check for no-share-shirk
         #
         if sourcetree::action::is_squatted_filename "${newfilename}"
         then
            _log_warning "Node \"${_address}\" is new but \"${newfilename#"${MULLE_USER_PWD}/"}\" has been \
squatted by an amalgamation. You should probably remove this node from your sourcetree.
Hint: Move mulle-testallocator to the bottom and/or run ${C_RESET_BOLD}mulle-sde clean -g"
            ACTIONS="skip"
            RVAL="${ACTIONS}"
            return
         fi

         local pretty_config

         pretty_config="${config#/}"
         pretty_config="${pretty_config%/}"
         if [ -z "${pretty_config}" ]
         then
            pretty_config="."
         fi
         _log_verbose "Node \"${newfilename#"${MULLE_USER_PWD}/"}\" of \
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
      log_fluff "Node \"${newfilename#"${MULLE_USER_PWD}/"}\" is unchanged"

      if [ "${newexists}" = 'YES' ]
      then
         RVAL="${ACTIONS}"
         return
      fi

      # someone removed it, fetch again
      r_add_line "${ACTIONS}" "fetch"
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

   sourcetree::nodeline::parse "${previousnodeline}"  # memo: _marks not used

   if [ "${_uuid}" != "${newuuid}" ]
   then
      _internal_fail "uuid \"${newuuid}\" wrong (expected \"${_uuid}\")"
   fi

   sourcetree::node::r_sanitized_address "${_address}"
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
   # Source change is big (except if old is symlink). If the nodetype changed
   # there should also be a change in URL..
   #
   if [ "${_nodetype}" != "${newnodetype}" -a "${_nodetype}" != "symlink" ]
   then
      _log_verbose "Nodetype has changed from \"${_nodetype}\" to \
\"${newnodetype}\", need to fetch"

      # no-delete check here ?
      if [ "${previousexists}" = 'YES' ]
      then
         ACTIONS="remove"
      fi

      if sourcetree::marks::disable "${newmarks}" "fetch"
      then
         RVAL="${ACTIONS}"
         return
      fi

      r_add_line "${ACTIONS}" "fetch"
      return
   fi

   #
   # Nothing there ?
   #
   if [ "${newexists}" = 'NO' -a "${previousexists}" = 'NO' ]
   then
      _log_fluff "Previous destination \"${previousfilename}\" and \
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
            _log_warning "Destinations new \"${newfilename}\" and \
old \"${previousfilename}\" exist. Doing nothing."
         else
            _log_fluff "Destinations new \"${newfilename}\" and \
old \"${previousfilename}\" exist. Looks like a manual move. Doing nothing."
         fi
         ACTIONS="remember"
      else
         #
         # Just old is there, so move it. We already checked
         # for the case where both are absent.
         #
         _log_verbose "Address changed from \"${_address}\" to \
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
            _log_fluff "\"${newfilename}\" is symlink. Ignoring possible \
differences in URL related info."
            RVAL="${ACTIONS}"
            return
         fi
      ;;
   esac

   if [ -z "${_url}" ]
   then
      _log_fluff "\"${newfilename}\" has no URL. Ignoring possible differences \
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
      sourcetree::fetch::r_list_operations "${evalednodetype}"
      available="${RVAL}" || return 1
   fi

   if [ "${_branch}" != "${newbranch}" ]
   then
      if find_line "${available}" "checkout"
      then
         _log_verbose "Branch has changed from \"${_branch}\" to \
\"${newbranch}\", need to checkout"
         r_add_line "${ACTIONS}" "checkout"
         ACTIONS="${RVAL}"
      else
         _log_verbose "Branch has changed from \"${_branch}\" to \
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
         _log_verbose "Tag has changed from \"${_tag}\" to \"${newtag}\", need \
to checkout"
         r_add_line "${ACTIONS}" "checkout"
         ACTIONS="${RVAL}"
      else
         _log_verbose "Tag has changed from \"${_tag}\" to \"${newtag}\", need \
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
         _log_verbose "URL has changed from \"${_url}\" to \"${newurl}\", need to \
set remote _url and fetch"
         r_add_line "${ACTIONS}" "set-url"
         r_add_line "${RVAL}" "upgrade"
         ACTIONS="${RVAL}"
      else
         _log_verbose "URL has changed from \"${_url}\" to \"${newurl}\", need to \
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
sourcetree::action::__update_perform_item()
{
   log_entry "sourcetree::action::__update_perform_item"

   local item="$1"

   [ -z "${_filename}" ] && _internal_fail "filename is empty"

   case "${item}" in
      "checkout"|"upgrade"|"set-url")
         if sourcetree::marks::disable "${_marks}" "fetch" ||
            sourcetree::marks::disable "${_marks}" "platform-${MULLE_UNAME}" ||
            sourcetree::marks::disable "${_marks}" "fetch-platform-${MULLE_UNAME}"
         then
            log_verbose "${C_MAGENTA}${C_BOLD}${_filename}${C_INFO} is set to no-fetch."

            sourcetree::db::add_missing "${_database}" \
                                        "${_uuid}" \
                                        "${_nodeline}"
            return 4
         fi

         if ! sourcetree::action::do_operation "${item}" "${_address}" \
                                                         "${_url}" \
                                                         "${_filename}" \
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
            sourcetree::action::update_safe_remove_node "${_previousfilename}" \
                                                        "${_marks}" \
                                                        "${_uuid}" \
                                                        "${_database}"
            log_fluff "Failed to ${item} ${_url}" # operation should have errored already
            return 1
         fi
         _contentschanged='YES'
         _remember='YES'
      ;;

      "fetch")
         if sourcetree::marks::disable "${_marks}" "fetch" ||
            sourcetree::marks::disable "${_marks}" "platform-${MULLE_UNAME}" ||
            sourcetree::marks::disable "${_marks}" "fetch-platform-${MULLE_UNAME}"
         then
            log_verbose "${C_MAGENTA}${C_BOLD}${_filename}${C_INFO} is set to no-fetch."

            sourcetree::db::add_missing "${_database}" \
                                        "${_uuid}" \
                                        "${_nodeline}"
            return 4
         fi

         sourcetree::action::do_operation "fetch" "${_address}" \
                                                  "${_url}" \
                                                  "${_filename}" \
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
               # if we used a symlink, we want to memorize that (why ?)
               _nodetype="symlink"

               # we don't really want to update that
               _contentschanged='NO'
            ;;

            *)
               #
               # if the fetch fails, it can be that we get a partial remnant
               # here which can really mess up the next fetch. So we remove it
               #
               if [ -e "${_filename}" ]
               then
                   if [ -L "${_filename}" ]
                   then
                      log_verbose "Removing old symlink \"${_filename}\""
                      exekutor rm -f "${_filename}" >&2
                  else
                     sourcetree::action::update_safe_clobber "${_database}" \
                                                             "${_filename}"
                  fi
               fi

               if sourcetree::marks::disable "${_marks}" "require" ||
                  sourcetree::marks::disable "${_marks}" "require-os-${MULLE_UNAME}"
               then
                  log_info "${C_MAGENTA}${C_BOLD}${_filename}${C_INFO} is not required."

                  sourcetree::db::add_missing "${_database}" \
                                              "${_uuid}" \
                                              "${_nodeline}"
                  return 4
               fi

               log_error "The fetch of \"${_address}\" failed and it is required."
               return 1
            ;;
         esac

         if [ -f "${_filename}/.mulle-sourcetree/config" -a \
              ! -f "${_filename}/.mulle/etc/sourcetree/config" ]
         then
            _log_warning "\"`basename -- "${_filename}"`\" contains an old-fashioned sourcetree \
which must be upgraded to be usable."
         fi

         _remember='YES'
      ;;

      "remember")
         _remember='YES'
      ;;

      "move")
         sourcetree::action::update_safe_move_node "${_previousfilename}" \
                                                   "${_filename}" \
                                                   "${_marks}"
         _remember='YES'
      ;;

      "clobber")
         sourcetree::action::update_safe_clobber "${_filename}" \
                                                 "${_database}"
      ;;

      "remove")
         sourcetree::action::update_safe_remove_node "${_previousfilename}" \
                                                     "${_marks}" \
                                                     "${_uuid}" \
                                                     "${_database}"
      ;;

      skip)
         return 4
      ;;

      *)
         _internal_fail "Unknown action item \"${item}\""
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

sourcetree::action::__update_perform_actions()
{
   log_entry "sourcetree::action::__update_perform_actions" "$@"

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

   sourcetree::nodeline::parse "${nodeline}"     # !!

   local actionitems

   sourcetree::action::r_update_actions_for_node "${style}" \
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

   local _filename
   local _previousfilename
   local _database
   local _nodeline

   _filename="${filename}"
   _previousfilename="${previousfilename}"
   _database="${database}"
   _nodeline="${nodeline}"

   local item
   local rval

   rval=0
   shell_disable_glob
   for item in ${actionitems}
   do
      shell_enable_glob

      # if this returns 4 its fine (like a non-required dependency)
      sourcetree::action::__update_perform_item "${item}" # this will exit on fail
      rval=$?

      log_debug "sourcetree::action::__update_perform_item returned $rval"

      case $rval in
         0)
            continue
         ;;

         4)
            _skip='YES'
            rval=0
            break
         ;;

         *)
            rval=1
            break
         ;;
      esac
   done
   shell_enable_glob

   log_debug "sourcetree::action::__update_perform_actions returns $rval"

   return $rval
}


sourcetree::action::write_fix_info()
{
   log_entry "sourcetree::action::write_fix_info" "$@"

   local nodeline="$1"
   local filename="$2"

   local output


   case "${MULLE_UNAME}" in
      mingw*)
         log_fluff "sourcetree fix is not supported on mingw"
         return
      ;;
   esac

   if [ -L "${filename}" ]
   then
      log_fluff "Not putting fix info into a symlink (${filename})"
      return
   fi

   # don't do this as it resolved symlinks that we might need
   # filename="`physicalpath "${filename}" `"

   [ -z "${SOURCETREE_FIX_FILENAME}" ] \
   && _internal_fail "SOURCETREE_FIX_FILENAME is empty"

   r_filepath_concat "${filename}" "${SOURCETREE_FIX_FILENAME}"
   output="${RVAL}"

   log_fluff "Writing fix info into \"${output}\""

   local text

   text="# this file is generated by mulle-sourcetree
${nodeline}"

   r_mkdir_parent_if_missing "${output}"
   redirect_exekutor "${output}" printf "%s\n" "${text}" \
   || _internal_fail "failed to write fixinfo \"${output}\""
}


#
# The node must be globally defined by
#
# _address
# _nodetype
# ...
#
sourcetree::action::_memorize_node_in_db()
{
   log_entry "sourcetree::action::_memorize_node_in_db" "$@"

   local database="$1"
   local config="$2"
   local filename="$3"
   local index="$4"
   local fix="${5:-NO}"

#   if ! is_absolutepath "${filename}"
#   then
#      r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${filename}"
#      filename="${RVAL}"
#   fi

   local rval
   local nodeline

   sourcetree::node::r_to_nodeline
   nodeline="${RVAL}"

   local _evaledurl
   local _evalednodetype
   local _evaledbranch
   local _evaledtag
   local _evaledfetchoptions

   sourcetree::node::__evaluate_values

   _log_debug "${C_INFO}Remembering ${_address} located at \"${filename}\" \
in \"${database}\"..."

   sourcetree::db::memorize "${database}" \
                            "${_uuid}" \
                            "${nodeline}" \
                            "${config}" \
                            "${filename}" \
                            "${_evaledurl}" \
                            "${index}"

   rval=$?

   if [ "${fix}" != 'NO' ] && [ -d "${filename}" ]
   then
      # we memorize the original config nodeline for easier comparison
      sourcetree::action::write_fix_info "${nodeline}" "${filename}"
   fi

   return $rval
}


# returns 0 1 2 3
sourcetree::action::_r_do_actions_with_nodeline()
{
   log_entry "sourcetree::action::_r_do_actions_with_nodeline" "$@"

   local nodeline="$1"
   local style="$2"
   local config="$3"
   local database="$4"
   local index="$5"

   [ $# -ne 5 ]       && _internal_fail "api error"

   [ -z "$style" ]    && _internal_fail "style is empty"
   [ -z "$nodeline" ] && _internal_fail "nodeline is empty"
   [ -z "$index" ]    && _internal_fail "nodeline is empty"

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

   sourcetree::nodeline::parse "${nodeline}"  # !!

   if sourcetree::marks::disable "${_marks}" "fs"
   then
      log_debug "\"${_address}\" is marked as no-fs, so nothing to update"
      RVAL="${_uuid}"
      return 2
   fi

   local _evaledurl
   local _evalednodetype
   local _evaledbranch
   local _evaledtag
   local _evaledfetchoptions

   sourcetree::node::__evaluate_values

   case "${_evalednodetype}" in
      'comment')
         log_debug "\"${_address}\" is a comment \"${_userinfo}\", so nothing to update"
         RVAL="${_uuid}"
         return 2
      ;;

      'error')
         sourcetree::node::show_error
         RVAL=
         return 1
      ;;
   esac

   #
   # ugliness that needs to be killed sometime
   #
   local enables_share

   enables_share='NO'
   if sourcetree::marks::enable "${_marks}" "share"
   then
      enables_share='YES'
   fi

   #
   # MULLE_SOURCETREE_SQUAT_ENABLED, this is Amalgamated. Amalgamations still
   #                                 need to be fetched if not present, this
   #                                 is how the amalgamation works, but then
   #                                 it has to prevent other share nodes from
   #                                 fetching
   #
   # with this enabled (default) repositories that are shadowed by amalgamated
   # ones (no-share-shirk), will not be fetched. This _can_ be bad, if the
   # sourcetree information of the amalgamated repository has some stuff, that
   # is interesting. But this mostly indicates a bug in the amalgamation.
   # Conceivably, if this ever becomes a concern you can disable squatting
   # with this, or we need to copy the sourcetree config into the amalgamated
   # repositories as well. I don't think that will happen though.
   #
   # if the amalgamation is in top level, then we would write twice the same
   # UUID, which would be bad. The add routine should check that an
   # amalgamation and a normal node occupy the same space (maybe)
   #
   local compare

   if [ "${MULLE_SOURCETREE_SQUAT_ENABLED}" != 'NO' -a "${database}" != '/' ]
   then
      if sourcetree::marks::disable "${_marks}" "share-shirk"
      then
         compare="${_address}"
         if sourcetree::marks::enable "${_marks}" "basename"
         then
            r_basename "${compare}"
            compare="${RVAL}"
         fi
         compare="${compare%[@#]*}" # not sure what this was for

         local squatfilename

         # figure out name in "share" to squat
         sourcetree::db::r_share_filename "${compare}" \
                                          "" \
                                          "${_evalednodetype}" \
                                          "${_marks}" \
                                          "${_uuid}" \
                                          "/"
         squatfilename="${RVAL}"

         log_fluff "Squatting share space \"${squatfilename}\" as \"${compare}\" since no-share-shirk is set"

         # avoid "really" clobbering
         (
            _address="${compare}"
            sourcetree::action::_memorize_node_in_db "/" \
                                                     "${config}" \
                                                     "${squatfilename}" \
                                                     "${index}" \
                                                     "NO"
         ) || fail "Failed to write into database"

         # need to still fetch it
         if [ "${style}" = 'only_share' ]
         then
            return
         fi

         enables_share='NO'  # we are not really a share node
      fi
   fi


   if [ "${style}" = 'only_share' ]
   then
      if [ ! -z "${_evaledurl}" -a ${enables_share} = 'NO' ]
      then
         RVAL=
         return 3
      fi
      style="share"
   fi

   #
   # the address is what is relative to the current config (configfile)
   # the filename is an absolute path
   #
   local filename

   if [ ! -z "${_evaledurl}" -a "${style}" = "share" -a "${enables_share}" = 'YES' ]
   then
      sourcetree::db::r_share_filename "${_address%[@#]*}" \
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
            return 1
         ;;

         3)
            return 0
         ;;
         #

         4)
            # this was handled by the root database,
            filename="${RVAL}"
         ;;

         *)
            _internal_fail "unknown code"
         ;;
      esac
      database='/'
   else
      # TODO: fix
      sourcetree::cfg::r_old_absolute_filename "${config}" \
                                               "${_address%#*}" \
                                               "${style}"
      filename="${RVAL}"
   fi

   [ -z "${database}" ] && _internal_fail "A share-only update gone wrong"
   [ -z "${filename}" ] && _internal_fail "Filename is empty for \"${_address}\""

   r_simplified_absolutepath "${filename}"
   filename="${RVAL}"

   log_debug "Filename for node \"${_address}\" is \"${filename}\""

   if sourcetree::marks::disable "${_marks}" "update"
   then
      if [ ! -e "${filename}"  ]
      then
         if sourcetree::marks::disable "${_marks}" "require" ||
            sourcetree::marks::disable "${_marks}" "require-os-${MULLE_UNAME}"
         then
            _log_fluff "\"${_address}\" is marked as no-update and doesn't exist, \
but it is not required"
            RVAL="${_uuid}"
            return 2
         fi

         fail "\"${_address}\" is missing, marked as no-update, but its required"
      fi


      log_fluff "\"${_address}\" is marked as no-update and exists"

      sourcetree::action::_memorize_node_in_db "${database}" \
                                               "${config}" \
                                               "${filename}" \
                                               "${index}"
      RVAL=${_uuid}
      return $?
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

   compare="${_address}"
   if sourcetree::marks::enable "${_marks}" "basename"
   then
      r_basename "${_address}"
      compare="${RVAL}"
   fi

   otheruuid="`sourcetree::db::fetch_uuid_for_address "${database}" \
                                                      "${compare}"`"

   if [ ! -z "${otheruuid}" ]
   then
      log_walk_fluff "UUID \"${otheruuid}\" found for \"${_address}\" (compared: \"${compare}\")"

      if sourcetree::db::is_uuid_alive "${database}" "${otheruuid}"
      then
         if [ "${otheruuid}" != "${_uuid}" ]
         then
            # this is _address is already taken
            _log_fluff "Filename \"${filename}\" is already used by \
node \"${otheruuid}\" in database \"${database}\". Skip it."
            # don't set alive though
            # RVAL="${otheruuid}" (or set other alive ?)
            RVAL=
            return 3
         fi
         log_walk_fluff "Filename \"${filename}\" belongs to this node"
      else
         log_walk_fluff "Prepare zombie \"${filename}\" for resurrection"
      fi
   else
      log_walk_fluff "Filename \"${filename}\" is not yet in \"${database}\""
   fi

   #
   # check if this nodeline is already known (this being an update)
   #
   local previousnodeline
   local previousfilename

   previousnodeline="`sourcetree::db::fetch_nodeline_for_uuid "${database}" "${_uuid}"`"

   #
   # find out, where it was previously located
   #
   if [ ! -z "${previousnodeline}" ]
   then
      previousfilename="`sourcetree::db::fetch_filename_for_uuid "${database}" "${_uuid}"`"

      [ -z "${previousfilename}" ] && _internal_fail "corrupted db"
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
      log_walk_fluff "Skip update of \"${filename}\" since it's a symlink."

      sourcetree::action::_memorize_node_in_db "${database}" \
                                               "${config}" \
                                               "${filename}" \
                                               "${index}"
      RVAL="${_uuid}"
      return 0
   fi

   #
   # candidate for parallelization
   #
   local _contentschanged
   local _remember
   local _skip
   local rval

   # return 0 or 1
   sourcetree::action::__update_perform_actions "${style}" \
                                                "${nodeline}" \
                                                "${filename}" \
                                                "${previousnodeline}" \
                                                "${previousfilename}" \
                                                "${database}" \
                                                "${config}"
   rval=$?

   case $rval in
      0)
      ;;

      1)
         return 1
      ;;

      *)
         _internal_fail "unexpected return code ${rval}"
      ;;
   esac

   _log_debug "\
contentschanged : ${_contentschanged}
remember        : ${_remember}
skip            : ${_skip}
nodetype        : ${_nodetype}"

   if [ "${_skip}" = 'YES' ]
   then
      log_debug "Skipping to next nodeline as indicated..."
      RVAL=${_uuid}
      return 0
   fi

   if [ "${_remember}" = 'YES' ]
   then
      if ! sourcetree::action::_memorize_node_in_db "${database}" \
                                                    "${config}" \
                                                    "${filename}" \
                                                    "${index}" \
                                                    "${OPTION_FIX}"
      then
         fail "Could not remember \"${filename}\" in database \"${database}\""
      fi
   else
      log_debug "Don't need to remember \"${nodeline}\" (should be unchanged)"
   fi

   RVAL="${_uuid}"
   return 0
}


sourcetree::action::do_actions_with_nodeline()
{
   log_entry "sourcetree::action::do_actions_with_nodeline" "$@"

#   local nodeline="$1"
#   local style="$2"
#   local config="$3"
   local database="$4"
#   local index=$5

   local uuid 
   local rval 

   sourcetree::action::_r_do_actions_with_nodeline "$@"
   rval=$?
   uuid="${RVAL}"

   case $rval in
      0|2)
      ;;

      3)
         return
      ;;

      *)
         return $rval
      ;;
   esac

   # this could be executed in parallel ?
   if ! sourcetree::db::set_uuid_alive "${database}" "${uuid}"
   then
      if sourcetree::db::set_uuid_alive "/" "${uuid}"
      then
         log_debug "${uuid} is alive as no zombie is present"
      fi
   fi
}


sourcetree::action::do_actions_with_nodelines()
{
   log_entry "sourcetree::action::do_actions_with_nodelines" "$@"

   local nodelines="$1"
   local style="$2"
   local config="$3"
   local database="$4"

   [ -z "${style}" ] && _internal_fail "style is empty"

   if [ -z "${nodelines}" ]
   then
      log_fluff "There is nothing to do for \"${style}\" as there are no nodes"
      return 0
   fi

   log_debug "\"${style}\" update \"${nodelines}\" for db \"${config:-ROOT}\" (${PWD#"${MULLE_USER_PWD}/"})"

   local nodeline
   local rval
   local index

   index=-1
   rval=0
   .foreachline nodeline in ${nodelines}
   .do
      index=$(( index + 1 ))
      [ -z "${nodeline}" ] && .continue

      if ! sourcetree::action::do_actions_with_nodeline "${nodeline}" \
                                                        "${style}" \
                                                        "${config}" \
                                                        "${database}" \
                                                        "${index}"
      then
         rval=1
         .break
      fi
   .done

   log_debug "sourcetree::action::do_actions_with_nodelines: $rval"

   return $rval
}


sourcetree::action::do_actions_with_nodelines_parallel()
{
   log_entry "sourcetree::action::do_actions_with_nodelines_parallel" "$@"

   local nodelines="$1"
   local style="$2"
   local config="$3"
   local database="$4"

   [ -z "${style}" ] && _internal_fail "style is empty"

   if [ -z "${nodelines}" ]
   then
      log_fluff "There is nothing to do for \"${style}\""
      return 0
   fi

   log_debug "\"${style}\" update \"${nodelines}\" for db \"${config:-ROOT}\" (${PWD#"${MULLE_USER_PWD}/"})"

   local nodeline
   local rval 
   local index

   index=-1

   local _parallel_statusfile
   local _parallel_maxjobs
   local _parallel_jobs
   local _parallel_fails

   __parallel_begin

   .foreachline nodeline in ${nodelines}
   .do
      index=$(( index + 1 ))
      if [ ! -z "${nodeline}" ]
      then
         __parallel_execute sourcetree::action::do_actions_with_nodeline "${nodeline}" \
                                                                         "${style}" \
                                                                         "${config}" \
                                                                         "${database}" \
                                                                         "${index}"
      fi
   .done

   __parallel_end
   rval=$? 

   log_debug "sourcetree::action::do_actions_with_nodelines_parallel: $rval"

   return $rval
}


sourcetree::action::initialize()
{
   log_entry "sourcetree::action::initialize"

   include "parallel"
   include "sourcetree::db"
   include "sourcetree::node"
   include "sourcetree::fetch"
}


sourcetree::action::initialize

:
