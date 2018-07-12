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



__concat_config_absolute_filename()
{
   local config="$1"
   local _address="$2"

   case "${config}" in
      "/"|/*/)
      ;;

      *)
         internal_fail "config \"${config}\" is malformed"
      ;;
   esac

   case "${_address}" in
      /*)
         internal_fail "_address \"${config}\" is absolute"
      ;;
   esac

   echo "${MULLE_VIRTUAL_ROOT}${config}${_address}"
}


emit_mulle_fetch_eval_options()
{
   local options

   # this implictily sets --symlink
   case "${OPTION_FETCH_SYMLINK}" in
      "NO")
      ;;

      "YES")
         options="`concat "${options}" "--symlink-returns-2"`"
      ;;

      "DEFAULT")
         if [ "${MULLE_SYMLINK}" = "YES" -o "${MULLE_SOURCETREE_SYMLINK}" = "YES" ]
         then
            options="`concat "${options}" "--symlink-returns-2"`"
         fi
      ;;
   esac

   if [ "${OPTION_FETCH_ABSOLUTE_SYMLINK}" = "YES" ]
   then
      options="`concat "${options}" "--absolute-symlink"`"
   fi

   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = "YES" ]
   then
      options="`concat "${options}" "--check-system-includes"`"
   fi

   if [ ! -z "${OPTION_FETCH_CACHE_DIR}"  ]
   then
      options="`concat "${options}" "--cache-dir '${OPTION_FETCH_CACHE_DIR}'"`"
   fi

   if [ ! -z "${OPTION_FETCH_MIRROR_DIR}" ]
   then
      options="`concat "${options}" "--mirror-dir '${OPTION_FETCH_MIRROR_DIR}'"`"
   fi

   if [ ! -z "${OPTION_FETCH_SEARCH_PATH}" ]
   then
      options="`concat "${options}" "--search-path '${OPTION_FETCH_SEARCH_PATH}'"`"
   fi

   case "${OPTION_FETCH_REFRESH}" in
      YES)
         options="`concat "${options}" "--refresh"`"
      ;;
      NO)
         options="`concat "${options}" "--no-refresh"`"
      ;;
   esac

   echo "${options}"
}



##
## CLONE
##
_has_system_include()
{
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

   includedir="`echo "${_uuid}" | tr '-' '_'`"
   includefile="${includedir}.h"

   if [ "${includedir}" = "${_uuid}" ]
   then
      includedir=""
   fi

   local i

   set -o noglob ; IFS=":"
   for i in ${include_search_path}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      if [ -d "${i}/${_uuid}" -o -f "${i}/${includefile}" ]
      then
         return 0
      fi

      if [ ! -z "${includedir}" ] && [ -d "${i}/${includedir}" ]
      then
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   return 1
}


mkdir_parent_if_missing()
{
   local _address="$1"

   local parent

   parent="`fast_dirname "${_address}"`"
   case "${parent}" in
      ""|"\.")
      ;;

      *)
         mkdir_if_missing "${parent}" || exit 1
         echo "${parent}"
      ;;
   esac
}


_do_fetch_operation()
{
   log_entry "_do_fetch_operation" "$@"

   local _url="$1"            # URL of the node
   local _address="$2"        # address of this node (absolute or relative to $PWD)
   local _branch="$3"         # branch of the node
   local _tag="$4"            # tag to checkout of the node
   local _nodetype="$5"       # nodetype to use for this node
   local _marks="$6"          # marks on node
   local _fetchoptions="$7"   # options to use on _nodetype
   local _userinfo="$8"       # unused
   local _uuid="$9"           # uuid of the node

   [ $# -eq 9 ] || internal_fail "fail"

   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = "YES" ] && _has_system_include "${_uuid}"
   then
      log_info "${C_MAGENTA}${C_BOLD}${_uuid}${C_INFO} is a system library, so not fetching it"
      return 1
   fi

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ] && [ -e "${_address}" ]
   then
      fail "Should have cleaned \"${_address}\" before"
   fi

   local parent

   parent="`mkdir_parent_if_missing "${_address}"`"

   local options
   local rval

   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      _branch="${OPTION_OVERRIDE_BRANCH}"
   fi

   local options

   options="`emit_mulle_fetch_eval_options`"

   node_fetch_operation "${opname}" "${options}" \
                                    "${_url}" \
                                    "${_address}" \
                                    "${_branch}" \
                                    "${_tag}" \
                                    "${_nodetype}" \
                                    "${_fetchoptions}"


   rval="$?"
   case $rval in
      0)
      ;;

      2)
      ;;

      111)
         log_fail "Source \"${_nodetype}\" is unknown"
      ;;

      *)
         return $rval
      ;;
   esac

   if [ ! -z "${UPTODATE_MIRRORS_FILE}" ]
   then
      redirect_append_exekutor "${UPTODATE_MIRRORS_FILE}" echo "${_url}"
   fi

   return $rval
}


# useful for testing
update_actions_for_nodelines()
{
   log_entry "update_actions_for_nodelines" "$@"

   [ "$#" -ne 3  ] && internal_fail "api error"

   local style="$1"
   local previousnodeline="$2"
   local nodeline="$3"

   [ -z "${style}" ]   && internal_fail "style is empty"
   [ -z "${nodeline}" ] && internal_fail "nodeline is empty"

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

   local previousfilename
   local filename

   filename="${_address}"
   previousfilename="`nodeline_get_address "${previousnodeline}"`"

   # just _address as filename ?
   update_actions_for_node "${style}" \
                           "${nodeline}" \
                           "${filename}" \
                           "${previousnodeline}" \
                           "${previousfilename}" \
                           "${_address}" \
                           "${_nodetype}" \
                           "${_marks}" \
                           "${_uuid}" \
                           "${_url}" \
                           "${_branch}" \
                           "${_tag}"
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

   local _url="$1"            # URL of the node
   local destination="$2"     # destination
   local _branch="$3"         # branch of the node
   local _tag="$4"            # tag to checkout of the node
   local _nodetype="$5"       # nodetype to use for this node
#   local _marks="$6"         # marks on node
   local _fetchoptions="$7"   # options to use on _nodetype
#   local _userinfo="$8"      # userinfo
#   local _uuid="$9"          # uuid of the node


   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      _branch="${OPTION_OVERRIDE_BRANCH}"
   fi

   local options

   options="`emit_mulle_fetch_eval_options`"


   node_fetch_operation "${opname}" "${options}" \
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

   if ! nodemarks_contain "${_marks}" "delete"
   then
      fail "Can't move node ${_url} from to \"${previousfilename}\" \
to \"${filename}\" as it is marked no-delete"
   fi

   log_info "Moving \"${previousfilename}\" to \"${filename}\""

   mkdir_parent_if_missing "${filename}"
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
   [ -z "${_uuid}" ]     && internal_fail "empty _uuid"

   if ! nodemarks_contain "${_marks}" "delete"
   then
      fail "Can't remove \"${filename}\" as it is marked no-delete"
   fi

   db_forget "${database}" "${_uuid}"
   db_bury "${database}" "${_uuid}" "${filename}"
}


update_safe_clobber()
{
   log_entry "update_safe_clobber" "$@"

   local filename="$1"
   local database="$2"

   [ -z "${filename}" ] && internal_fail "empty filename"

   db_bury "${database}" "`node_uuidgen`" "${filename}"
}


##
## this produces actions, does not care about _marks
##
update_actions_for_node()
{
   log_entry "update_actions_for_node" "$@"

   local style="$1"; shift
   local newnodeline="$1" ; shift
   local newfilename="$1"; shift
   local previousnodeline="$1" ; shift
   local previousfilename="$1"; shift

   local newaddress="$1"    # address of this node
   local newnodetype="$2"   # nodetype to use for this node
   local newmarks="$3"      # nodetype to use for this node
   local newuuid="$4"       # uuid of the node
   local newurl="$5"        # URL of the node
   local newbranch="$6"     # branch of the node
   local newtag="$7"        # tag to checkout of the node

   #
   # sanitize here because of paranoia and shit happes
   #
   local sanitized

   sanitized="`node_sanitized_address "${newaddress}"`"
   if [ "${newaddress}" != "${sanitized}" ]
   then
      fail "New _address \"${newaddress}\" looks suspicious ($sanitized), \
chickening out"
   fi

   #
   # but in terms of filesystem checks, we use "newfilename" from now on
   #
   local newexists

   newexists="NO"
   if [ -e "${newfilename}" ]
   then
      log_fluff "\"${newfilename}\" already exists"
      newexists="YES"
   else
      if [ -L "${newfilename}" ]
      then
         log_fluff "Node \"${newfilename}\" references a broken symlink \
\"${newfilename}\". Clobbering it"
         remove_file_if_present "${newfilename}"
      else
         log_debug "\"${newfilename}\" is just not there"
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

      if [ "${newexists}" = "YES" ]
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

         if ! nodemarks_contain "${newmarks}" "delete"
         then
            case "${newnodetype}" in
               local)
                  log_fluff "Local node is present at \"${newfilename}\". \
Very well just remember it."
               ;;

               *)
                  log_fluff "Node is new but \"${newfilename}\" exists. \
As node is marked \"no-delete\" just remember it."
               ;;
            esac

            echo "remember"
            return
         fi

         if [ -f "${newfilename}/${SOURCETREE_FIX_FILE}" ]
         then
            local oldnodeline

            oldnodeline="`rexekutor egrep -s -v '^#' "${newfilename}/${SOURCETREE_FIX_FILE}"`"
            if [ "${oldnodeline}" = "${nodeline}" ]
            then
               log_fluff "Fix info was written by identical config, so it looks ok"
               echo "remember"
               return
            fi
         fi
         log_fluff "Node is new, but \"${newfilename}\" exists. Clobber it."
         echo "clobber"
      else
         if [ -z "${_url}" ]
         then
            fail "Node \"${newfilename}\" has no URL and it doesn't exist ($PWD)"
         fi

         log_fluff "Node \"${newfilename}\" is missing, so fetch"
      fi

      echo "fetch"
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
      log_fluff "Node \"${newfilename}\" is unchanged"

      if [ "${newexists}" = "YES" ]
      then
         return
      fi

      # someone removed it, fetch again
      echo "fetch"
      return
   fi

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

   nodeline_parse "${previousnodeline}"

   if [ "${_uuid}" != "${newuuid}" ]
   then
      internal_fail "uuid \"${newuuid}\" wrong (expected \"${_uuid}\")"
   fi

   local sanitized

   sanitized="`node_sanitized_address "${_address}"`"
   if [ "${_address}" != "${sanitized}" ]
   then
      fail "Old address \"${_address}\" looks suspicious (${sanitized}), \
chickening out"
   fi

   log_debug "Change: \"${previousnodeline}\" -> \"${newnodeline}\""

   local previousexists

   previousexists="NO"
   if [ -e "${previousfilename}" ]
   then
      previousexists="YES"
   fi

   #
   # Source change is big (except if old is symlink and new is git)
   #
   if [ "${_nodetype}" != "${newnodetype}" ]
   then
      if ! [ "${_nodetype}" = "symlink" -a "${newnodetype}" = "git" ]
      then
         log_fluff "Nodetype has changed from \"${_nodetype}\" to \
\"${newnodetype}\", need to fetch"

         # no-delete check here ?
         if [ "${previousexists}" = "YES" ]
         then
            echo "remove"
         fi
         echo "fetch"
         return
      fi
   fi

   #
   # Nothing there ?
   #
   if [ "${newexists}" = "NO" -a "${previousexists}" = "NO" ]
   then
      log_fluff "Previous destination \"${previousfilename}\" and \
current destination \"${newfilename}\" do not exist."
      echo "fetch"
      return
   fi

   local actions

   actions=
   #
   # Handle positional changes
   #
   if [ "${previousfilename}" != "${newfilename}" ]
   then
      if [ "${newexists}" = "YES" ]
      then
         if [ "${previousexists}" = "YES" ]
         then
            log_warning "Destinations new \"${newfilename}\" and \
old \"${previousfilename}\" exist. Doing nothing."
         else
            log_fluff "Destinations new \"${newfilename}\" and \
old \"${previousfilename}\" exist. Looks like a manual move. Doing nothing."
         fi
         actions="remember"
      else
         #
         # Just old is there, so move it. We already checked
         # for the case where both are absent.
         #
         log_fluff "Address changed from \"${_address}\" to \
\"${newaddress}\", need to move"
         actions="move"
      fi
   fi

   #
   # Check that the _nodetype can actually do the supported operation
   #
   local have_checkout
   local have_upgrade

   case "${_nodetype}" in
      symlink)
         if [ "${newexists}" = "YES" ]
         then
            log_fluff "\"${newfilename}\" is symlink. Ignoring possible \
differences in URL related info."
            echo "${actions}"
            return
         fi
      ;;
   esac

   if [ -z "${_url}" ]
   then
      log_fluff "\"${newfilename}\" has no URL. Ignoring possible differences \
in URL related info."
      echo "${actions}"
      return
   fi

   local available
   local have_upgrade
   local have_checkout
   local have_set_url
   local have_upgrade

   available="`node_list_operations "${_nodetype}"`" || return 1

   if [ "${_branch}" != "${newbranch}" ]
   then
      have_checkout="$(fgrep -s -x "checkout" <<< "${available}")" || :
      if [ ! -z "${have_checkout}" ]
      then
         log_fluff "Branch has changed from \"${_branch}\" to \
\"${newbranch}\", need to checkout"
         actions="`add_line "${actions}" "checkout"`"
      else
         log_fluff "Branch has changed from \"${_branch}\" to \
\"${newbranch}\", need to fetch"
         if [ "${previousexists}" = "YES" ]
         then
            echo "remove"
         fi
         echo "fetch"
         return
      fi
   fi

   if [ "${_tag}" != "${newtag}" ]
   then
      have_checkout="$(fgrep -s -x "checkout" <<< "${available}")" || :
      if [ ! -z "${have_checkout}" ]
      then
         log_fluff "Tag has changed from \"${_tag}\" to \"${newtag}\", need \
to checkout"
         actions="`add_line "${actions}" "checkout"`"
      else
         log_fluff "Tag has changed from \"${_tag}\" to \"${newtag}\", need \
to fetch"
         if [ "${previousexists}" = "YES" ]
         then
            echo "remove"
         fi
         echo "fetch"
         return
      fi
   fi

   if [ "${_url}" != "${newurl}" ]
   then
      have_upgrade="$(fgrep -s -x "upgrade" <<< "${available}")" || :
      have_set_url="$(fgrep -s -x "set-url" <<< "${available}")" || :
      if [ ! -z "${have_upgrade}" -a ! -z "${have_set_url}" ]
      then
         log_fluff "URL has changed from \"${_url}\" to \"${newurl}\", need to \
set remote _url and fetch"
         actions="`add_line "${actions}" "set-url"`"
         actions="`add_line "${actions}" "upgrade"`"
      else
         log_fluff "URL has changed from \"${_url}\" to \"${newurl}\", need to \
fetch"
         if [ "${previousexists}" = "YES" ]
         then
            echo "remove"
         fi
         echo "fetch"
         return
      fi
   fi

   if [ ! -z "${actions}" ]
   then
      echo "${actions}"
   fi
}


#
# uses variables from enclosing function
# just here for readability and to pipe stdout into stderr
#
__update_perform_item()
{
   log_entry "__update_perform_item"

   case "${item}" in
      "checkout"|"upgrade"|"set-url")
         if ! do_operation "${item}" "${_url}" \
                                     "${filename}" \
                                     "${_branch}" \
                                     "${_tag}" \
                                     "${_nodetype}" \
                                     "${_marks}" \
                                     "${_fetchoptions}" \
                                     "${_userinfo}" \
                                     "${_uuid}"
         then
            # as these are shortcuts to remove/fetch, but the
            # fetch part didn't work out we need to remove
            # the previousaddress
            update_safe_remove_node "${previousfilename}" "${_marks}" "${_uuid}" "${database}"
            fail "Failed to ${item} ${_url}"
         fi
         contentschanged="YES"
         remember="YES"
      ;;

      "fetch")
         do_operation "fetch" "${_url}" \
                              "${filename}" \
                              "${_branch}" \
                              "${_tag}" \
                              "${_nodetype}" \
                              "${_marks}" \
                              "${_fetchoptions}" \
                              "${_userinfo}" \
                              "${_uuid}"

         case "$?" in
            0)
               contentschanged="YES"
            ;;

            2)
               # if we used a symlink, we want to memorize that
               _nodetype="symlink"

               # we don't really want to update that
               contentschanged="NO"
            ;;

            *)
               if ! nodemarks_contain "${_marks}" "require"
               then
                  log_info "${C_MAGENTA}${C_BOLD}${_uuid}${C_INFO} is not required."

                  db_add_missing "${database}" "${_uuid}" "${nodeline}"
                  skip="YES"
                  return 1
               fi

               fail "The fetch of ${_url} failed and it is required."
            ;;
         esac
         remember="YES"
      ;;

      "remember")
         remember="YES"
      ;;

      "move")
         update_safe_move_node "${previousfilename}" "${filename}" "${_marks}"
         remember="YES"
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


_update_perform_actions()
{
   log_entry "_update_perform_actions" "$@"

   local style="$1"
   local nodeline="$2"
   local filename="$3"
   local previousnodeline="$4"
   local previousfilename="$5"
   local database="$6"  # used in _perform

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

   nodeline_parse "${nodeline}"

   local actionitems

   local filename
   local dbfilename

   actionitems="`update_actions_for_node "${style}" \
                                         "${nodeline}" \
                                         "${filename}" \
                                         "${previousnodeline}" \
                                         "${previousfilename}" \
                                         "${_address}" \
                                         "${_nodetype}" \
                                         "${_marks}" \
                                         "${_uuid}" \
                                         "${_url}" \
                                         "${_branch}" \
                                         "${_tag}"`" || exit 1

   log_debug "${C_INFO}Actions for \"${_address}\": ${actionitems:-none}"

   local contentschanged="NO"
   local remember="NO"
   local skip="NO"

   local item

   set -o noglob ; IFS="
"
   for item in ${actionitems}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      if ! __update_perform_item >&2
      then
         break
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   echo "-- VfL Bochum 1848 --"
   echo "${contentschanged}"
   echo "${remember}"
   echo "${skip}"
   echo "${_nodetype}"
}


_memorize_in_db()
{
   log_entry "_memorize_in_db" "$@"

   local nodeline="$1"
   local evaledurl="$2"
   local config="$3"
   local database="$4"
   local filename="$5"

   [ -z "${filename}" ] && internal_fail "Memorizing non existing file"

   log_debug "${C_INFO}Remembering ${nodeline} located at \"${filename}\"..."

   db_memorize "${database}" \
               "${_uuid}" \
               "${nodeline}" \
               "${config}" \
               "${filename}" \
               "${evaledurl}"
}


_memorize_nodeline_in_db()
{
   log_entry "_memorize_nodeline_in_db" "$@"

   local nodeline
   local evaledurl

   nodeline="`node_to_nodeline`"
   evaledurl="`eval echo "${_url}"`"

   _memorize_in_db "${nodeline}" "${evaledurl}" "$@"
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

   [ -z "${SOURCETREE_FIX_FILE}" ] && internal_fail "SOURCETREE_FIX_FILE is empty"
   output="`filepath_concat "${filename}" "${SOURCETREE_FIX_FILE}"`"

   log_fluff "Writing fix info into \"${output}\""

   local text

   text="# this file is generated by mulle-sourcetree
${nodeline}"

   redirect_exekutor "${output}" echo "${text}" || internal_fail "failed to write fixinfo \"${output}\""
}


do_actions_with_nodeline()
{
   log_entry "do_actions_with_nodeline" "$@"

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
   local _uuid

   nodeline_parse "${nodeline}"

   if ! nodemarks_contain "${_marks}" "fs"
   then
      log_fluff "\"${_address}\" is marked as no-fs, so there is nothing to update"
      return
   fi

   if ! nodemarks_contain "${_marks}" "fetch-${MULLE_UNAME}"
   then
      log_fluff "\"${_address}\" is marked as no-fs-${MULLE_UNAME}, so there is nothing to update"
      return
   fi

   #
   # the _address is what is relative to the current config (configfile)
   # the filename is an absolute path
   #
   local filename

   if [ ! -z "${_url}" -a "${style}" = "share" ] && nodemarks_contain "${_marks}" "share"
   then
      filename="`db_update_determine_share_filename "${database}" \
                                                    "${_address}" \
                                                    "${_url}" \
                                                    "${_nodetype}" \
                                                    "${_marks}" \
                                                    "${_uuid}" `"
      case $? in
         0)
         ;;

         1)
            exit 1
         ;;

         2)
            return
         ;;
      esac
      database="/"   # see only-share if you're tempted to change this
   else
      filename="`cfg_absolute_filename "${config}" "${_address}"`"
   fi

   [ -z "${database}" ] && internal_fail "A share-only update gone wrong"

   if ! nodemarks_contain "${_marks}" "update"
   then
      if [ ! -e "${filename}"  ]
      then
         if nodemarks_contain "${_marks}" "require"
         then
            log_fluff "\"${_address}\" is marked as no-update and doesnt exist, \
but it is not required"
            return
         fi
         fail "\"${_address}\" is missing, marked as no-update, but required"
      fi

      log_fluff "\"${_address}\" is marked as no-update and exists"
      # still need to memorize this though, so it can be shared

      if ! is_absolutepath "${filename}"
      then
         filename="`filepath_concat "${MULLE_VIRTUAL_ROOT}" "${filename}" `"
      fi

      _memorize_nodeline_in_db "${config}" "${database}" "${filename}"
      return
   fi

   #
   # If we find something in the database for the same address,
   # check if it is ours. This could be a new entry/edit whatever.
   # But it could be old. If its not old, it has preference.
   # A general problem, why we check for _address here is, that the filename
   # due to symlinking is unpredictable.
   #
   # If we are in share mode, then the database is "/" here, so no worries
   # We don't have to check the owner, because the _uuid will be different
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
            return 0
         fi
         log_debug "Filename \"${filename}\" belongs to this node"
      else
         log_debug "Zombie filename \"${filename}\" gets usurped"
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
   fi

   local results

   results="`_update_perform_actions "${style}" \
                                     "${nodeline}" \
                                     "${filename}" \
                                     "${previousnodeline}" \
                                     "${previousfilename}" \
                                     "${database}"`"
   if [ "$?" -ne 0 ]
   then
      exit 1
   fi

   local magic

   magic="$(sed -n '1p' <<< "${results}")"
   [ "${magic}" = "-- VfL Bochum 1848 --" ]|| internal_fail "stdout was polluted with \"magic\""

   local contentschanged
   local remember
   local skip
   local nodetype

   contentschanged="$(sed -n '2p' <<< "${results}")"
   remember="$(sed -n '3p' <<< "${results}")"
   skip="$(sed -n '4p' <<< "${results}")"
   nodetype="$(sed -n '5p' <<< "${results}")"

   log_debug "\
contentschanged : ${contentschanged}
remember        : ${remember}
skip            : ${skip}
nodetype        : ${nodetype}"

   if [ "${skip}" = "YES" ]
   then
      log_debug "Skipping to next nodeline as indicated..."
      return 0
   fi

   if [ "${remember}" = "YES" ]
   then
      if ! is_absolutepath "${filename}"
      then
         filename="`filepath_concat "${MULLE_VIRTUAL_ROOT}" "${filename}" `"
      fi

      _memorize_nodeline_in_db "${config}" "${database}" "${filename}"

      if [ "${OPTION_FIX}" != "NO" ] && [ -d "${filename}" ]
      then
         # we memorize the original config nodeline for easier comparison
         write_fix_info "${nodeline}" "${filename}"
      fi
   else
      log_debug "Don't need to remember \"${nodeline}\" (should be unchanged)"
   fi

   db_set_uuid_alive "${database}" "${_uuid}"
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

   log_debug "\"${style}\" update \"${nodelines}\" for db \"${config:-ROOT}\" ($PWD)"

   local nodeline

   set -o noglob ; IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      if [ -z "${nodeline}" ]
      then
         continue
      fi

      do_actions_with_nodeline "${nodeline}" "${style}" "${config}" "${database}"
   done

   IFS="${DEFAULT_IFS}" ; set +o noglob
}
