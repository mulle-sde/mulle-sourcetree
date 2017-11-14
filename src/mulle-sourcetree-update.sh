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

   Apply recent edits to the source tree. The configuration is read and
   the changes applies. This will fetch, if the destination is absent.

   Use ${MULLE_EXECUTABLE_NAME} fix instead, if you want to sync the source
   tree with changes you made  in the filesystem.

Options:
   -r                         : update recursively
   --no-fix                   : do not write ${SOURCETREE_FIX_FILE} files
   --share                    : create database in shared configuration
   --override-branch <branch> : temporary override of the branch for all nodes

   The following options are passed through to ${MULLE_FETCH:-mulle-fetch}.

   --cache-dir   --mirror-dir  --search-path
   --refresh     --symlinks    --absolute-symlinks
   --no-refresh  --no-symlinks --no-absolute-symlinks

   See the ${MULLE_FETCH:-mulle-fetch} usage for information.
EOF
  exit 1
}


emit_mulle_fetch_eval_options()
{
   local options

   if [ "${OPTION_FETCH_SYMLINK}" = "YES" ]
   then
      options="`concat "${options}" "--symlink-returns-2"`"
   fi

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

   local options

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
                           "${address}" \
                           "${nodetype}" \
                           "${marks}" \
                           "${uuid}" \
                           "${url}" \
                           "${branch}" \
                           "${tag}"
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


   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      branch="${OPTION_OVERRIDE_BRANCH}"
   fi

   local options

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
   log_entry "update_safe_move_node" "$@"

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
   log_entry "update_safe_remove_node" "$@"

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

   local newaddress="$1"    # address of this node (absolute or relative to $PWD)
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
      fail "New address \"${newaddress}\" looks suspicious ($sanitized), chickening out"
   fi

   local newexists

   newexists="NO"
   if [ -e "${newaddress}" ]
   then
      newexists="YES"
   else
      if [ -L "${newaddress}" ]
      then
         log_fluff "Node \"${newaddress}\" references a broken symlink. Clobbering it"
         remove_file_if_present "${newaddress}"
      fi
   fi

   #
   # NEW
   #
   # We remember a node, when we have fetched it. This way next time
   # there is a previous record and we know its contents. We have to fetch it
   # and remember it otherwise we don't know what we have.
   #
   if [ -z "${nodeline}" ]
   then
      if [ "${newexists}" = "YES" ]
      then
         if nodemarks_contain_nodelete "${newmarks}"
         then
            log_fluff "Node is new but \"${newaddress}\" exists. \
As it is marked \"nodelete\" don't fetch."
            echo "checkout"
            return
         fi

         log_fluff "Node is new, but \"${newaddress}\" exists. Clobber it."
      else
         if [ -z "${url}" ]
         then
            fail "Node \"${newaddress}\" has no URL and it doesn't exist"
         fi

         log_fluff "Node \"${newaddress}\" is missing, so fetch"
      fi

      echo "fetch"
      return
   fi

   #
   # UPDATE
   #
   # We know that there is a previous record. We assume that the user may
   # have moved it, but we do not assume that he has manipulated it to
   # contain another branch or tag.
   #

   log_debug "This is an update"

   #
   # easy and cheap cop out
   #
   if [ "${nodeline}" = "${newnodeline}" ]
   then
      log_fluff "Node \"${newaddress}\" is unchanged"
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

   local oldexists

   oldexists="NO"
   if [ -e "${address}" ]
   then
      oldexists="YES"
   fi

   #
   # Source change is big (except if old is symlink and new is git)
   #
   if [ "${nodetype}" != "${newnodetype}" ]
   then
      if ! [ "${nodetype}" = "symlink" -a "${newnodetype}" = "git" ]
      then
         log_fluff "Scm has changed from \"${nodetype}\" to \"${newnodetype}\", need to fetch"

         # nodelete check here ?
         if [ "${oldexists}" = "YES" ]
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
   if [ "${newexists}" = "NO" -a "${oldexists}" = "NO" ]
   then
      log_fluff "Previous address \"${address}\" and \
current address \"${newaddress}\" do not exist anymore."
      echo "fetch"
      return
   fi

   local actions

   #
   # Handle positional changes
   #
   if [ "${address}" != "${newaddress}" ]
   then
      if [ "${newexists}" = "YES" ]
      then
         if [ "${oldexists}" = "YES" ]
         then
            log_warning "Destinations new \"${newaddress}\" and \
old \"${address}\" exist. Doing nothing."
         else
            log_fluff "Destinations new \"${newaddress}\" and \
old \"${address}\" exist. Looks like a manual move. Doing nothing."
         fi
         actions="remember"
      else
         #
         # Just old is there, so move it. We already checked
         # for the case where both are absent.
         #
         log_fluff "Address changed from \"${address}\" to \
\"${newaddress}\", need to move"
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
         if [ "${newexists}" = "YES" ]
         then
            log_fluff "\"${newaddress}\" is symlink. Ignoring possible differences in URL related info."
            echo "${actions}"
            return
         fi
      ;;
   esac

   if [ -z "${url}" ]
   then
      log_fluff "\"${newaddress}\" has no URL. Ignoring possible differences in URL related info."
      echo "${actions}"
      return
   fi


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
         if [ "${oldexists}" = "YES" ]
         then
            echo "remove"
         fi
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
         if [ "${oldexists}" = "YES" ]
         then
            echo "remove"
         fi
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
         if [ "${oldexists}" = "YES" ]
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
   log_entry "_update_perform_actions" "$@"

   local mode="$1"
   local nodeline="$2"
   local previous="$3"
   local oldaddress="$4"  # used in _perform

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
      if [ ! -z "${url}" ] && nodemarks_contain_share "${marks}"
      then
         address="`node_guess_address "${url}" "${nodetype}"`"
         if [ -z "${address}" ]
         then
            address="${uuid}"
         fi
         address="`filepath_concat "${MULLE_SOURCETREE_SHARED_DIR}" "${address}"`"
         log_fluff "Use guessed address \"${address}\" for shared URL \"${url}\""
      fi
   fi

   actionitems="`update_actions_for_node "${mode}" \
                                         "${previous}" \
                                         "${nodeline}" \
                                         "${address}" \
                                         "${nodetype}" \
                                         "${marks}" \
                                         "${uuid}" \
                                         "${url}" \
                                         "${branch}" \
                                         "${tag}"`" || exit 1

   log_debug "${C_INFO}Actions for \"${url}\": ${actionitems:-local}"

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

   if nodemarks_contain_noupdate "${marks}"
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
      flat)
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
         nextmode="recurse"
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

      if [ "${OPTION_FIX}" != "NO" ] && [ -d "${address}" ]
      then
         redirect_exekutor "${address}/${SOURCETREE_FIX_FILE}" echo "${address}"
      fi
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


__sourcetree_subtree_update()
{
   local mode="$1"

   log_verbose "Recursively updating \"`basename -- "${PWD}"`\""

   db_clear_ready
   db_set_update
   db_set_dbtype "recurse"

   zombify_nodes

   case "${mode}" in
      "share")
         mode="noshare"
         #
         # The inferior is in our shared folder, but it needs some
         # non-shared stuff. We are in his folder. Everything is easy
         #
      ;;

      "recurse")
         #
         # We are in the inferior folder. Everything is easy.
         #
      ;;

      *)
         internal_fail "${mode} is unexpected here to say the least"
      ;;
   esac

   local nodelines

   # as we are in the local database there is no owner
   nodelines="`nodeline_config_read`"
   update_with_nodelines "${mode}" "" "${nodelines}" || return 1

   zombie_bury_zombies

   db_clear_update
   if db_contains_entries
   then
      db_set_ready
   fi
}


#
# Mode        | Result
# ------------|-----------------------
# flat        | FAIL
# recurse     | OK
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
      flat|noshare)
         return 0
      ;;
   esac

   log_verbose "Update ${C_RESET_BOLD}${relative}${C_VERBOSE} \
(mode=${C_MAGENTA}${C_BOLD}${mode}${C_VERBOSE})"

   local prefix

   prefix="${relative}"
   case "${prefix}" in
      ""|*/)
      ;;

      *)
         prefix="${prefix}/"
      ;;
   esac

   if ! nodeline_config_exists "${prefix}" && ! db_dir_exists "${prefix}"
   then
      log_debug "Nothing to do in \"${relative}\""
      return
   fi

   (
      cd "${relative}" &&
      db_ensure_consistency &&
      db_ensure_compatible_dbtype "${mode}"
   ) || exit 1

   if [ "${mode}" = "share" ]
   then
      local nodelines

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

      __sourcetree_subtree_update "${mode}"
   ) || exit 1
}


sourcetree_update_root()
{
   log_entry "sourcetree_update_root" "$@" "($PWD)"

   local mode

   mode="${SOURCETREE_MODE}"

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
   if db_contains_entries
   then
      db_set_ready
   fi
}


sourcetree_update_main()
{
   log_entry "sourcetree_update_main" "$@"

   local OPTION_FIX="DEFAULT"
   local OPTION_OVERRIDE_BRANCH

   local OPTION_FETCH_SEARCH_PATH
   local OPTION_FETCH_CACHE_DIR
   local OPTION_FETCH_MIRROR_DIR

   local OPTION_FETCH_REFRESH="DEFAULT"
   local OPTION_FETCH_SYMLINK="DEFAULT"
   local OPTION_FETCH_ABSOLUTE_SYMLINK="DEFAULT"

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

         --symlink)
            OPTION_FETCH_SYMLINK="YES"
         ;;

         --no-symlink)
            OPTION_FETCH_SYMLINK="NO"
         ;;

         --absolute-symlink)
            OPTION_FETCH_SYMLINK="YES"
            OPTION_FETCH_ABSOLUTE_SYMLINK="YES"
         ;;

         --no-absolute-symlinks)
            OPTION_FETCH_ABSOLUTE_SYMLINK="NO"
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
      # shellcheck source=mulle-sourcetree-zombie.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-zombie.sh"
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

