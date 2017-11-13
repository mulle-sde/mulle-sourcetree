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
MULLE_SOURCETREE_UPDATE_SH="included"


sourcetree_update_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} update [options]

   Apply recent node additions and removals.

Options:
   -r       : update recursively (git)
   --no-fix : do not write ${SOURCETREE_FIX_FILE} files
   --share  : create database in shared configuration
EOF
  exit 1
}


emit_mulle_fetch_eval_options()
{
   local options
   local refresh="${OPTION_REFRESH_GIT_MIRROR}"
   local match

   if [ "${refresh}" = "YES" -a ! -z "${UPTODATE_MIRRORS_FILE}" ]
   then
      log_debug "Mirror URLS: `cat "${UPTODATE_MIRRORS_FILE}" 2>/dev/null`"

      match="`fgrep -s -x "${url}" "${UPTODATE_MIRRORS_FILE}" 2>/dev/null`"
      if [ ! -z "${match}" ]
      then
         refresh="NO"
      fi
   fi

   if [ "${MULLE_FLAG_CREATE_SYMLINKS}" = "YES" ]
   then
      options="--symlinks-return-2"
   fi

   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = "YES" ]
   then
      options="`concat "${options}" "--check-system-includes"`"
   fi

   if [ "${OPTION_ALLOW_ARCHIVE_CACHE}" = "YES" ]
   then
      options="`concat "${options}" "--cache-dir" "'${CACHE_DIR}'"`"
   fi

   if [ "${OPTION_ALLOW_GIT_MIRROR}" = "YES" ]
   then
      options="`concat "${options}" "--mirror-dir" "'${CACHE_DIR}'"`"
   fi

   if [ "${refresh}" = "NO" ]
   then
      options="`concat "${options}" "--no-refresh"`"
   fi

   if [ "${OPTION_SEARCH_LOCALS}" = "YES" ]
   then
      options="`concat "${options}" "-l" "${LOCAL_PATH}"`"
   fi

   echo "${options}"
}



##
## CLONE
##

_has_system_include()
{
   local uuid="$1"

   local include_search_path="${HEADER_SEARCH_PATH}"

   if [ -z "${include_search_path}" ]
   then
      case "${UNAME}" in
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

   includedir="`echo "${uuid}" | tr '-' '_'`"
   includefile="${includedir}.h"

   if [ "${includedir}" = "${uuid}" ]
   then
      includedir=""
   fi

   IFS=":"
   for i in ${include_search_path}
   do
      IFS="${DEFAULT_IFS}"

      if [ -d "${i}/${uuid}" -o -f "${i}/${includefile}" ]
      then
         return 0
      fi

      if [ ! -z "${includedir}" ] && [ -d "${i}/${includedir}" ]
      then
         return 0
      fi
   done

   IFS="${DEFAULT_IFS}"
   return 1
}


mkdir_parent_if_missing()
{
   local address="$1"

   local parent

   parent="`dirname -- "${address}"`"
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

   local url="$1"            # URL of the node
   local address="$2"        # address of this node (absolute or relative to $PWD)
   local branch="$3"         # branch of the node
   local tag="$4"            # tag to checkout of the node
   local nodetype="$5"       # nodetype to use for this node
   local marks="$6"          # marks on node
   local fetchoptions="$7"   # options to use on nodetype
   local userinfo="$8"       # unused
   local uuid="$9"           # uuid of the node

   [ $# -eq 9 ] || internal_fail "fail"

   if [ "${OPTION_CHECK_USR_LOCAL_INCLUDE}" = "YES" ] && _has_system_include "${uuid}"
   then
      log_info "${C_MAGENTA}${C_BOLD}${uuid}${C_INFO} is a system library, so not fetching it"
      return 1
   fi

   if [ -e "${address}" ]
   then
      zombie_bury_node "${address}" "${uuid}"
   fi

   local parent

   parent="`mkdir_parent_if_missing "${address}"`"

   local options
   local rval

   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      branch="${OPTION_OVERRIDE_BRANCH}"
   fi
   options="`emit_mulle_fetch_eval_options`"
   node_fetch_operation "${opname}" "${options}" \
                                    "${url}" \
                                    "${address}" \
                                    "${branch}" \
                                    "${tag}" \
                                    "${nodetype}" \
                                    "${fetchoptions}"


   rval="$?"
   case $rval in
      0)
         if [ "${OPTION_FIX}" != "NO" ] && [ -d "${address}" ]
         then
            redirect_exekutor "${address}/${SOURCETREE_FIX_FILE}" echo "${address}"
         fi
      ;;

      2)
      ;;

      111)
         log_fail "Source \"${nodetype}\" is unknown"
      ;;

      *)
         return $rval
      ;;
   esac

   if [ ! -z "${UPTODATE_MIRRORS_FILE}" ]
   then
      redirect_append_exekutor "${UPTODATE_MIRRORS_FILE}" echo "${url}"
   fi

   return $rval
}


# useful for testing
update_actions_for_nodelines()
{
   log_entry "update_actions_for_nodelines" "$@"

   [ "$#" -ne 3  ] && internal_fail "api error"

   local mode="$1"
   local previous="$2"
   local nodeline="$3"

   [ -z "${mode}" ]   && internal_fail "mode is empty"
   [ -z "${nodeline}" ] && internal_fail "nodeline is empty"

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

   update_actions_for_node "${mode}" \
                           "${previous}" \
                           "${nodeline}" \
                           "${url}" \
                           "${address}" \
                           "${branch}" \
                           "${tag}" \
                           "${nodetype}" \
                           "${uuid}"
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

   local url="$1"            # URL of the node
   local address="$2"        # address of this node (absolute or relative to $PWD)
   local branch="$3"         # branch of the node
   local tag="$4"            # tag to checkout of the node
   local nodetype="$5"       # nodetype to use for this node
#   local marks="$6"          # marks on node
   local fetchoptions="$7"   # options to use on nodetype
#   local useroptions="$8"    # options to use on nodetype
#   local uuid="$9"           # uuid of the node

   local options

   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      branch="${OPTION_OVERRIDE_BRANCH}"
   fi

   options="`emit_mulle_fetch_eval_options`"
   node_fetch_operation "${opname}" "${options}" \
                                    "${url}" \
                                    "${address}" \
                                    "${branch}" \
                                    "${tag}" \
                                    "${nodetype}" \
                                    "${fetchoptions}"
}


update_safe_move_node()
{
   local oldaddress="$1"
   local address="$2"
   local marks="$3"

   [ -z "${oldaddress}" ]  && internal_fail "empty oldaddress"
   [ -z "${address}" ]     && internal_fail "empty address"

   if nodemarks_contain_nodelete "${marks}"
   then
      fail "Can't move node ${url} from to \"${oldaddress}\" \
to \"${address}\" as it is marked nodelete"
   fi

   log_info "Moving node with URL ${C_MAGENTA}${C_BOLD}${url}${C_INFO} from \"${oldaddress}\" to \"${address}\""

   mkdir_parent_if_missing "${address}"
   if ! exekutor mv ${OPTION_COPYMOVEFLAGS} "${oldaddress}" "${address}"  >&2
   then
      fail "Move of ${C_RESET_BOLD}${oldaddress}${C_ERROR_TEXT} failed!"
   fi
}


update_safe_remove_node()
{
   local address="$1"
   local marks="$2"
   local uuid="$3"

   [ -z "${address}" ] && internal_fail "empty address"
   [ -z "${url}" ]     && internal_fail "empty url"

   if nodemarks_contain_nodelete "${marks}"
   then
      fail "Can't remove \"${address}\" as it is marked nodelete"
   fi

   zombie_bury_node "${address}" "${uuid}"
}


##
## this produces actions, does not care about marks
##
update_actions_for_node()
{
   log_entry "update_actions_for_node" "$@"

   local mode="$1"; shift
   local nodeline="$1" ; shift
   local newnodeline="$1" ; shift

   local newurl="$1"            # URL of the node
   local newaddress="$2"    # address of this node (absolute or relative to $PWD)
   local newbranch="$3"         # branch of the node
   local newtag="$4"            # tag to checkout of the node
   local newnodetype="$5"       # nodetype to use for this node
   local newuuid="$6"           # uuid of the node

   #
   # sanitize here because of paranoia and shit happes
   #
   local sanitized

   sanitized="`node_sanitized_address "${newaddress}"`"
   if [ "${newaddress}" != "${sanitized}" ]
   then
      fail "New address \"${newaddress}\" looks suspicious ($sanitized), chickening out"
   fi

   if [ -z "${nodeline}" ]
   then
      log_fluff "${url} is new"
      echo "fetch"
      return
   fi

   if [ "${nodeline}" = "${newnodeline}" ]
   then
      if [ -e "${newaddress}" ]
      then
         log_fluff "URL ${url} repository line is unchanged"
         return
      fi

      log_fluff "\"${newaddress}\" is missing, reget."
      echo "fetch"
      return
   fi

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

   if [ "${uuid}" != "${newuuid}" ]
   then
      internal_fail "uuid \"${newuuid}\" wrong (expected \"${uuid}\")"
   fi

   local sanitized

   sanitized="`node_sanitized_address "${address}"`"
   if [ "${address}" != "${sanitized}" ]
   then
      fail "Old address \"${address}\" looks suspicious (${sanitized}), chickening out"
   fi

   log_debug "Change: \"${nodeline}\" -> \"${newnodeline}\""

   #
   # Source change is big (except if old is symlink and new is git)
   #
   if [ "${nodetype}" != "${newnodetype}" ]
   then
      if ! [ "${nodetype}" = "symlink" -a "${newnodetype}" = "git" ]
      then
         log_fluff "Scm has changed from \"${nodetype}\" to \"${newnodetype}\", need to fetch"

         echo "remove"
         echo "fetch"
         return
      fi
   fi

   if [ ! -e "${newaddress}" -a ! -e "${address}" ]
   then
      log_fluff "Previous address \"${address}\" and \
current address \"${newaddress}\" do not exist."

      echo "fetch"
      return
   fi

   local actions

   #
   # Handle positional changes
   #
   if [ "${address}" != "${newaddress}" ]
   then
      if [ -e "${newaddress}" -a ! -e "${address}" ]
      then
         log_warning "The destination of \"${newaddress}\" already exists and \
\"${address}\" is gone. Assuming, that the move was done already."
         echo "remember" # if nothing else changed
      else
         log_fluff "Address changed from \"${address}\" to \
\"${newaddress}\", need to move"

         if [ ! -e "${address}" ]
         then
            log_warning "Can't find \"${address}\". Will fetch again"
            echo "fetch"
            return
         fi

         actions="move"
      fi
   fi

   #
   # Check that the nodetype can actually do the supported operation
   #
   local have_set_url
   local have_checkout
   local have_upgrade

   case "${nodetype}" in
      symlink)
         if [ -e "${newaddress}" ]
         then
            log_fluff "\"${newaddress}\" is symlink. Ignoring possible differences."
            return
         fi
      ;;
   esac

   local available
   local have_upgrade

   available="`node_list_operations "${nodetype}"`" || return 1

   if [ "${branch}" != "${newbranch}" ]
   then
      have_checkout="$(fgrep -s -x "checkout" <<< "${available}")" || :
      if [ ! -z "${have_checkout}" ]
      then
         log_fluff "Branch has changed from \"${branch}\" to \"${newbranch}\", need to checkout"
         actions="`add_line "${actions}" "checkout"`"
      else
         log_fluff "Branch has changed from \"${branch}\" to \"${newbranch}\", need to fetch"
         echo "remove"
         echo "fetch"
         return
      fi
   fi

   if [ "${tag}" != "${newtag}" ]
   then

      local have_checkout

      have_checkout="$(fgrep -s -x "checkout" <<< "${available}")" || :
      if [ ! -z "${have_checkout}" ]
      then
         log_fluff "Tag has changed from \"${tag}\" to \"${newtag}\", need to checkout"
         actions="`add_line "${actions}" "checkout"`"
      else
         log_fluff "Tag has changed from \"${tag}\" to \"${newtag}\", need to fetch"
         echo "remove"
         echo "fetch"
         return
      fi
   fi

   if [ "${url}" != "${newurl}" ]
   then

      local have_set_url
      local have_upgrade

      have_upgrade="$(fgrep -s -x "upgrade" <<< "${available}")" || :
      have_set_url="$(fgrep -s -x "set-url" <<< "${available}")" || :
      if [ ! -z "${have_upgrade}" -a ! -z "${have_set_url}" ]
      then
         log_fluff "URL has changed from \"${url}\" to \"${newurl}\", need to set remote url and fetch"
         actions="`add_line "${actions}" "set-url"`"
         actions="`add_line "${actions}" "upgrade"`"
      else
         log_fluff "URL has changed from \"${url}\" to \"${newurl}\", need to fetch"
         echo "remove"
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
         if ! do_operation "${item}" "${url}" \
                                     "${address}" \
                                     "${branch}" \
                                     "${tag}" \
                                     "${nodetype}" \
                                     "${marks}" \
                                     "${fetchoptions}" \
                                     "${userinfo}" \
                                     "${uuid}"
         then
            # as these are shortcuts to remove/fetch, but the
            # fetch part didn't work out we need to remove
            # the oldaddress
            update_safe_remove_node "${oldaddress}" "${marks}" "${uuid}"
            fail "Failed to ${item} ${url}"
         fi
         contentschanged="YES"
         remember="YES"
      ;;

      "fetch")
         do_operation "fetch" "${url}" \
                              "${address}" \
                              "${branch}" \
                              "${tag}" \
                              "${nodetype}" \
                              "${marks}" \
                              "${fetchoptions}" \
                              "${userinfo}" \
                              "${uuid}"

         case "$?" in
            0)
               contentschanged="YES"
            ;;

            2)
               # if we used a symlink, we want to memorize that
               nodetype="symlink"
               # we don't really want to update that
               contentschanged="NO"
            ;;

            *)
               if nodemarks_contain_norequire "${marks}"
               then
                  log_info "${C_MAGENTA}${C_BOLD}${uuid}${C_INFO} is not required."

                  merge_line_into_file "${SOURCETREE_DB_DIR}/.missing" "${uuid}"
                  skip="YES"
                  return 1
               fi

               fail "Don't continue with ${url}, because a required fetch failed"
            ;;
         esac
         remember="YES"
      ;;

      "remember")
         remember="YES"
      ;;

      "move")
         update_safe_move_node "${oldaddress}" "${address}" "${marks}"
         remember="YES"
      ;;

      "remove")
         update_safe_remove_node "${oldaddress}" "${marks}" "${uuid}"
      ;;

      *)
         internal_fail "Unknown action item \"${item}\""
      ;;
   esac
}


_update_perform_actions()
{
   log_entry "_update_perform_actions"

   local mode="$1"
   local nodeline="$2"
   local previous="$3"
   local oldaddress="$4"

   local branch
   local address
   local fetchoptions
   local marks
   local nodetype
   local tag
   local url
   local userinfo
   local uuid

   nodeline_parse "${nodeline}"

   local actionitems

   if [ "${mode}" = "share" ]
   then
      log_fluff "Use guessed name as directory for shared \"${url}\""
      address="`node_guess_address "${url}" "${nodetype}"`"
      if [ -z "${address}" ]
      then
         address="${uuid}"
      fi
      address="`filepath_concat "${SOURCETREE_SHARED_DIR}" "${address}"`"
   fi

   actionitems="`update_actions_for_node "${mode}" \
                                         "${previous}" \
                                         "${nodeline}" \
                                         "${url}" \
                                         "${address}" \
                                         "${branch}" \
                                         "${tag}" \
                                         "${nodetype}" \
                                         "${uuid}"`" || exit 1

   log_debug "${C_INFO}Actions for \"${url}\": ${actionitems:-none}"

   local skip="NO"
   local contentschanged="NO"
   local remember="NO"

   local item

   IFS="
"
   for item in ${actionitems}
   do
      IFS="${DEFAULT_IFS}"

      if ! __update_perform_item >&2
      then
         break
      fi
   done
   IFS="${DEFAULT_IFS}"

   echo "-- VfL Bochum 1848 --"
   echo "${contentschanged}"
   echo "${remember}"
   echo "${skip}"
   echo "${nodetype}"
   echo "${address}"
}


update_with_nodeline()
{
   log_entry "update_with_nodeline" "$@"

   local mode="$1"
   local owner="$2"
   local nodeline="$3"

   [ "$#" -ne 3 ]     && internal_fail "api error"
   [ -z "$mode" ]     && internal_fail "mode is empty"
   [ -z "$nodeline" ] && internal_fail "nodeline is empty"

   local branch
   local address
   local fetchoptions
   local marks
   local nodetype
   local tag
   local url
   local userinfo
   local uuid

   nodeline_parse "${nodeline}"

   if nodemarks_contain_noupdate "${marks}" || [ -z "${url}" ]
   then
      if [ -e "${address}"  ]
      then
         log_fluff "\"${address}\" has no URL (or is marked as noupdate) and exists"
         return
      fi

      if nodemarks_contain_norequire "${marks}"
      then
         log_fluff "\"${address}\" has no URL (or is marked as noupdate) and doesnt exist, \
but it is not required"
         return
      fi
      fail "\${address}\" is missing, but required"
   fi

   local nextmode

   nextmode="${mode}"

   case "${mode}" in
      normal)
      ;;

      share)
         if nodemarks_contain_noshare "${marks}"
         then
            log_fluff "\"${address}\" is marked as noshare (and we are sharing)"
            return
         fi
      ;;

      noshare)
         if nodemarks_contain_share "${marks}"
         then
            log_fluff "\"${address}\" is marked as share (and we are not sharing this time)"
            return
         fi

         #
         # for inferiors that are marked noshare, we have to fetch
         # everything, if we recurse
         #
         log_fluff "\"${address}\" is marked as noshare, recursion will get everything"
         nextmode="recursive"
      ;;
   esac

   #
   # check if this nodeline is known, and if yes
   # where it was previously
   #
   local previous
   local oldaddress

   previous="`db_get_nodeline_for_uuid "${uuid}"`"
   if [ ! -z "${previous}" ]
   then
      oldaddress="`nodeline_get_address "${previous}"`"
      [ -z "${oldaddress}" ] && internal_fail "corrupted db"

      log_fluff "Updating \"${address}\" last seen at \"${oldaddress}\"..."
   else
      log_fluff "Fetching \"${url}\" for \"${address}\"..."
   fi
   #
   # check if this .sourcetree is actually "responsible" for this
   # shared node (otherwise let someone else do it)
   #
   if [ ! -z "${previous}" -a "${mode}" = "share" ]
   then
      local oldowner

      oldowner="`db_get_owner_for_uuid "${uuid}"`"
      if [ "${owner}" != "${oldowner}" ]
      then
         if is_node_alive "${uuid}"
         then
            log_fluff "\"${owner}\" does not feel responsible for \"${address}\""
            return
         else
            log_fluff "\"${owner}\" takes over responsibility for \"${address}\""
         fi
      fi
   fi

   local magic
   local contentschanged
   local remember
   local skip
   local nodetype
   local results

   results="`_update_perform_actions "${mode}" \
                                     "${nodeline}" \
                                     "${previous}" \
                                     "${oldaddress}"`"
   if [ "$?" -ne 0 ]
   then
      exit 1
   fi

   magic="$(sed -n '1p' <<< "${results}")"
   [ "${magic}" = "-- VfL Bochum 1848 --" ]|| internal_fail "stdout was polluted with \"magic\""

   contentschanged="$(sed -n '2p' <<< "${results}")"
   remember="$(sed -n '3p' <<< "${results}")"
   skip="$(sed -n '4p' <<< "${results}")"
   nodetype="$(sed -n '5p' <<< "${results}")"
   address="$(sed -n '6p' <<< "${results}")"

   log_debug "contentschanged: ${contentschanged}" \
             "remember: ${remember}" \
             "skip: ${skip}" \
             "nodetype: ${nodetype}"

   if [ "${skip}" = "YES" ]
   then
      log_debug "Skipping to next nodeline as indicated..."
      return 0
   fi

   if nodemarks_contain_recurse "${marks}"
   then
      # for when it is
      if [ -d "${address}" ]
      then
         (
            _sourcetree_subtree_update "${nextmode}" "${address}"
         ) || exit 1
      else
         log_fluff "Will not recursively update \"${address}\" as it's not a directory"
      fi
   fi

   if [ "${remember}" = "YES" ]
   then
      # branch could be overwritten
      log_debug "${C_INFO}Remembering ${nodeline} ..."

      nodeline="`node_print_nodeline`"
      db_remember "${uuid}" "${nodeline}" "${PARENT_NODELINE}" "${PARENT_SOURCETREE}" "${owner}"
   else
      log_debug "Don't need to remember \"${nodeline}\" (should be unchanged)"
   fi

   diagnose_node_as_alive "${uuid}"
}


update_with_nodelines()
{
   log_entry "update_with_nodelines" "$@"

   local mode="$1"
   local owner="$2"
   local nodelines="$3"

   [ -z "${mode}" ] && internal_fail "mode is empty"

   if [ -z "${nodelines}" ]
   then
      log_fluff "There is nothing to do"
      return 0
   fi

   log_debug "\"${mode}\" update \"${nodelines}\" for db \"${owner:-ROOT}\" ($PWD)"

   local nodeline

   IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"

      if [ -z "${nodeline}" ]
      then
         continue
      fi

      update_with_nodeline "${mode}" "${owner}" "${nodeline}"
   done

   IFS="${DEFAULT_IFS}"
}



#
# Mode        | Result
# ------------|-----------------------
# normal      | FAIL
# recursive   | OK
# share       | OK
# noshare     | FAIL

_sourcetree_subtree_update()
{
   log_entry "_sourcetree_subtree_update" "$@" "($PWD)"

   local mode="$1"
   local relative="$2"

   [ -z "${mode}" ]                    && internal_fail "mode is empty"
   [ -z "${relative}" ]                && internal_fail "relative is empty"

   [ -z "${SOURCETREE_UPDATE_CACHE}" ] && internal_fail "don't call sourcetree_subtree_update yourself"

   case "${mode}" in
      normal|noshare)
         return 0
      ;;
   esac

   log_verbose "Update ${mode} of \"${relative}\""

   (
      cd "${relative}" &&
      db_ensure_consistency &&
      db_ensure_compatible_dbtype "${mode}"
   ) || exit 1

   local nodelines
   local configfile

   if [ "${mode}" = "share" ]
   then
      local prefix

      prefix="${relative}"
      case "${relative}" in
         ""|*/)
         ;;

         *)
            prefix="${prefix}/"
         ;;
      esac

      #
      # The inferior is in out shared folder .
      # We now read the other shared repos for this repo, like they
      # are ours. So relative is the owner of the fetched stuff.
      #
      nodelines="`nodeline_config_read "${prefix}"`"
      update_with_nodelines "${mode}" "${relative}" "${nodelines}" || return 1
   fi

   (
      cd "${relative}" &&

      db_clear_ready
      db_set_update
      db_set_dbtype "recursive"

      zombify_nodes

      case "${mode}" in
         "share")
            mode="noshare"
            #
            # The inferior is in our shared folder, but it needs some
            # non-shared stuff. We are in his folder. Everything is easy
            #
         ;;

         "recursive")
            #
            # We are in the inferior folder. Everything is easy.
            #
         ;;

         *)
            internal_fail "${mode} is unexpected here to say the least"
         ;;
      esac


      # as we are in the local database there is no owner
      nodelines="`nodeline_config_read`"
      update_with_nodelines "${mode}" "" "${nodelines}" || return 1

      zombie_bury_zombies

      db_clear_update
      db_set_ready
   ) || exit 1
}


sourcetree_update_root()
{
   log_entry "sourcetree_update_root" "$@" "($PWD)"

   local mode

   mode="normal"
   if [ "${OPTION_SHARE}" = "YES" ]
   then
      mode="share"
   else
      if [ "${OPTION_RECURSIVE}" = "YES" ]
      then
          mode="recursive"
      fi
   fi

   local opwd

   opwd="$PWD"
   while ! nodeline_config_exists && ! db_exists
   do
      case "${PWD}" in
         "/"|"")
            log_info "No sourcetree found"
            return 1
         ;;
      esac

      cd ..
   done

   db_ensure_consistency
   db_ensure_compatible_dbtype "${mode}"

   local SOURCETREE_UPDATE_CACHE

   SOURCETREE_UPDATE_CACHE="`absolutepath "${SOURCETREE_DB_DIR}/.update-cache"`"

   db_clear_ready
   db_set_update

   zombify_nodes

   rmdir_safer "${SOURCETREE_UPDATE_CACHE}"
   mkdir_if_missing "${SOURCETREE_UPDATE_CACHE}"

   log_verbose "Doing a \"${mode}\" update."
   log_fluff "Set dbtype to \"${mode}\""

   db_set_dbtype "${mode}"

   # as we are in the local database there is no owner
   nodelines="`nodeline_config_read`"
   update_with_nodelines "${mode}" "" "${nodelines}" || return 1

   if [ "${mode}" = "share" ]
   then
      update_with_nodelines "noshare" "" "${nodelines}" || return 1
   fi

   rmdir_safer "${SOURCETREE_UPDATE_CACHE}"

   zombie_bury_zombies

   db_clear_update
   db_set_ready
}


sourcetree_update_main()
{
   log_entry "sourcetree_update_main" "$@"


   local OPTION_SHARE
   local OPTION_RECURSIVE
   local OPTION_FIX="DEFAULT"
   local OPTION_OVERRIDE_BRANCH

   local OPTION_FETCH_SEARCH_PATH
   local OPTION_FETCH_CACHE_DIR
   local OPTION_FETCH_MIRROR_DIR
   local OPTION_FETCH_REFRESH
   local OPTION_FETCH_ABSOLUTE_SYMLINKS
   local OPTION_FETCH_ABSOLUTE_SYMLINKS

   _db_set_default_options

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            sourcetree_update_usage
         ;;

         #
         # stuff passed to mulle-fetch
         #
         --cache-refresh|--refresh|--mirror-refresh)
            OPTION_FETCH_REFRESH="YES"
         ;;

         --no-cache-refresh|--no-refresh|--no-mirror-refresh)
            OPTION_FETCH_REFRESH="NO"
         ;;

         --symlinks)
            OPTION_FETCH_SYMLINKS="YES"
         ;;

         --no-symlinks)
            OPTION_FETCH_ABSOLUTE_SYMLINKS="NO"
         ;;

         --absolute-symlinks)
            OPTION_FETCH_SYMLINKS="YES"
            OPTION_FETCH_ABSOLUTE_SYMLINKS="YES"
         ;;

         --no-absolute-symlinks)
            OPTION_FETCH_ABSOLUTE_SYMLINKS="NO"
         ;;

         --cache-dir)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_FETCH_CACHE_DIR="$1"
         ;;

         --mirror-dir)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_FETCH_MIRROR_DIR="$1"
         ;;

         -l|--search-path|--local-search-path|--locals-search-path)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_FETCH_SEARCH_PATH="$1"
         ;;


         #
         # update options
         #
         --override-branch)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_OVERRIDE_BRANCH="$1"
         ;;

         --fixup)
            OPTION_FIX="NO"
         ;;

         --no-fixup)
            OPTION_FIX="YES"
         ;;

         #
         # more common flags
         #
         -r|--recursive)
            OPTION_RECURSIVE="YES"
         ;;

         --no-recursive)
            OPTION_RECURSIVE="NO"
         ;;

         -s|--share)
            OPTION_SHARE="YES"
         ;;

         --no-share|--normal)
            OPTION_SHARE="NO"
         ;;

         --share-prefix)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            SOURCETREE_SHARED_DIR="$1"
            OPTION_SHARE="YES"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown update option $1"
            sourcetree_update_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local mulle_fetch_version

   mulle_fetch_version="`mulle-fetch version`"
   [ -z "${mulle_fetch_version}" ] && "mulle-fetch not installed"

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   sourcetree_update_root
}


sourcetree_update_initialize()
{
   log_entry "sourcetree_update_initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_ZOMBIFY_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-zombify.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-zombify.sh"
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


sourcetree_update_initialize

:

