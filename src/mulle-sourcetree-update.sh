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


__concat_projectdir_address()
{
   local projectdir="$1"
   local address="$2"

   case "${projectdir}" in
      "/")
         echo "${address}"
      ;;

      *)
         filepath_concat "${projectdir}" "${address}"
      ;;
   esac
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
      fail "Should have cleaned \"${address}\" before"
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

   local style="$1"
   local previousnodeline="$2"
   local nodeline="$3"

   [ -z "${style}" ]   && internal_fail "style is empty"
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

   local previousfilename
   local filename

   filename="${address}"
   previousfilename="`nodeline_get_address "${previousnodeline}"`"

   # just address address as filename ?
   update_actions_for_node "${style}" \
                           "${nodeline}" \
                           "${filename}" \
                           "${previousnodeline}" \
                           "${previousfilename}" \
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
   local destination="$2"       # destination
   local branch="$3"         # branch of the node
   local tag="$4"            # tag to checkout of the node
   local nodetype="$5"       # nodetype to use for this node
#   local marks="$6"         # marks on node
   local fetchoptions="$7"   # options to use on nodetype
#   local useroptions="$8"   # options to use on nodetype
#   local uuid="$9"          # uuid of the node


   if [ ! -z "${OPTION_OVERRIDE_BRANCH}" ]
   then
      branch="${OPTION_OVERRIDE_BRANCH}"
   fi

   local options

   options="`emit_mulle_fetch_eval_options`"


   node_fetch_operation "${opname}" "${options}" \
                                    "${url}" \
                                    "${destination}" \
                                    "${branch}" \
                                    "${tag}" \
                                    "${nodetype}" \
                                    "${fetchoptions}"
}


update_safe_move_node()
{
   log_entry "update_safe_move_node" "$@"

   local previousfilename="$1"
   local filename="$2"
   local marks="$3"

   [ -z "${previousfilename}" ] && internal_fail "empty previousfilename"
   [ -z "${filename}" ]         && internal_fail "empty filename"

   if nodemarks_contain_nodelete "${marks}"
   then
      fail "Can't move node ${url} from to \"${previousfilename}\" \
to \"${filename}\" as it is marked nodelete"
   fi

   log_info "Moving node with URL ${C_MAGENTA}${C_BOLD}${url}${C_INFO} \
from \"${previousfilename}\" to \"${filename}\""

   mkdir_parent_if_missing "${filename}"
   if ! exekutor mv ${OPTION_COPYMOVEFLAGS} "${previousfilename}" "${filename}"  >&2
   then
      fail "Move of ${C_RESET_BOLD}${previousfilename}${C_ERROR_TEXT} failed!"
   fi
}


update_safe_remove_node()
{
   log_entry "update_safe_remove_node" "$@"

   local dbaddress="$1"
   local marks="$2"
   local uuid="$3"
   local database="$4"

   [ -z "${dbaddress}" ] && internal_fail "empty dbaddress"
   [ -z "${uuid}" ]      && internal_fail "empty uuid"

   if nodemarks_contain_nodelete "${marks}"
   then
      fail "Can't remove \"${dbaddress}\" as it is marked nodelete"
   fi

   db_forget "${database}" "${uuid}"
   db_bury "${database}" "${uuid}" "${dbaddress}"
}


update_safe_clobber()
{
   log_entry "update_safe_clobber" "$@"

   local dbaddress="$1"
   local database="$2"

   [ -z "${dbaddress}" ] && internal_fail "empty dbaddress"

   db_bury "${database}" "`node_uuidgen`" "${dbaddress}"
}

##
## this produces actions, does not care about marks
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
      fail "New address \"${newaddress}\" looks suspicious ($sanitized), \
chickening out"
   fi

   #
   # but in terms of filesystem checks, we use "newfilename" from now on
   #
   local newexists

   newexists="NO"
   if [ -e "${newfilename}" ]
   then
      newexists="YES"
   else
      if [ -L "${newfilename}" ]
      then
         log_fluff "Node \"${newfilename}\" references a broken symlink \
\"${newfilename}\". Clobbering it"
         remove_file_if_present "${newfilename}"
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
      if [ "${newexists}" = "YES" ]
      then
         # hmm, but why ?
         # 1. it's some old cruft that we should clobber
         # 2. it's a minion that resides in the place for shared repos
         #    where we assume that the minion is the same as the shared repo
         #    (a minion is a local copy of a subproject). That was checked
         #    before though.
         # 3. it's a shared repo, that's been already placed there. Though
         #    at this point in time, that should have already been checked
         #    against

         if nodemarks_contain_nodelete "${newmarks}"
         then
            case "${newnodetype}" in
               local)
                  log_fluff "Local node is present at \"${newfilename}\". \
Very well just remember it."
               ;;
               *)
                  log_fluff "Node is new but \"${newfilename}\" exists. \
As node is marked \"nodelete\" just remember it."
               ;;
            esac

            echo "remember"
            return
         fi

         log_fluff "Node is new, but \"${newfilename}\" exists. Clobber it."
         echo "clobber"
      else
         if [ -z "${url}" ]
         then
            fail "Node \"${newfilename}\" has no URL and it doesn't exist"
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
   # contain another branch or tag.
   #

   log_debug "This is an update"

   #
   # easy and cheap cop out
   #
   if [ "${previousnodeline}" = "${newnodeline}" ]
   then
      log_fluff "Node \"${newfilename}\" is unchanged"
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

   nodeline_parse "${previousnodeline}"

   if [ "${uuid}" != "${newuuid}" ]
   then
      internal_fail "uuid \"${newuuid}\" wrong (expected \"${uuid}\")"
   fi

   local sanitized

   sanitized="`node_sanitized_address "${address}"`"
   if [ "${address}" != "${sanitized}" ]
   then
      fail "Old address \"${address}\" looks suspicious (${sanitized}), \
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
   if [ "${nodetype}" != "${newnodetype}" ]
   then
      if ! [ "${nodetype}" = "symlink" -a "${newnodetype}" = "git" ]
      then
         log_fluff "Scm has changed from \"${nodetype}\" to \
\"${newnodetype}\", need to fetch"

         # nodelete check here ?
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
         log_fluff "Address changed from \"${address}\" to \
\"${newfilename}\", need to move"
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
            log_fluff "\"${newfilename}\" is symlink. Ignoring possible \
differences in URL related info."
            echo "${actions}"
            return
         fi
      ;;
   esac

   if [ -z "${url}" ]
   then
      log_fluff "\"${newfilename}\" has no URL. Ignoring possible differences \
in URL related info."
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
         log_fluff "Branch has changed from \"${branch}\" to \
\"${newbranch}\", need to checkout"
         actions="`add_line "${actions}" "checkout"`"
      else
         log_fluff "Branch has changed from \"${branch}\" to \
\"${newbranch}\", need to fetch"
         if [ "${previousexists}" = "YES" ]
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
         log_fluff "Tag has changed from \"${tag}\" to \"${newtag}\", need \
to checkout"
         actions="`add_line "${actions}" "checkout"`"
      else
         log_fluff "Tag has changed from \"${tag}\" to \"${newtag}\", need \
to fetch"
         if [ "${previousexists}" = "YES" ]
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
         log_fluff "URL has changed from \"${url}\" to \"${newurl}\", need to \
set remote url and fetch"
         actions="`add_line "${actions}" "set-url"`"
         actions="`add_line "${actions}" "upgrade"`"
      else
         log_fluff "URL has changed from \"${url}\" to \"${newurl}\", need to \
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
         if ! do_operation "${item}" "${url}" \
                                     "${filename}" \
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
            # the previousaddress
            update_safe_remove_node "${dbaddress}" "${marks}" "${uuid}" "${database}"
            fail "Failed to ${item} ${url}"
         fi
         contentschanged="YES"
         remember="YES"
      ;;

      "fetch")
         do_operation "fetch" "${url}" \
                              "${filename}" \
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

                  db_add_missing "${database}" "${uuid}" "${nodeline}"
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
         update_safe_move_node "${previousfilename}" "${filename}" "${marks}"
         remember="YES"
      ;;

      "clobber")
         update_safe_clobber "${dbaddress}" "${database}"
      ;;

      "remove")
         update_safe_remove_node "${previousdbaddress}" "${marks}" "${uuid}" "${database}"
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

   local filename
   local dbfilename

   actionitems="`update_actions_for_node "${style}" \
                                         "${nodeline}" \
                                         "${filename}" \
                                         "${previousnodeline}" \
                                         "${previousfilename}" \
                                         "${address}" \
                                         "${nodetype}" \
                                         "${marks}" \
                                         "${uuid}" \
                                         "${url}" \
                                         "${branch}" \
                                         "${tag}"`" || exit 1

   log_debug "${C_INFO}Actions for \"${address}\": ${actionitems:-local}"

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
   echo "${dbaddress}"
}


#
# Only allowable combinations are shown
#
# Style   | Projectdir | Database   || Owner
# --------|------------|------------||---------------
# flat    | /          | /          || -
#
# recurse | /          | /          || -
# recurse | foo        | foo        || -
#
# share   | /          | /          || -
# share   | foo        | /          || foo
# share   | foo        | foo        || -
#
# partial | /          | /          || -
# partial | foo        | foo        || -
#
update_with_nodeline()
{
   log_entry "update_with_nodeline" "$@"

   local nodeline="$1"
   local style="$2"
   local projectdir="$3"
   local database="$4"

   [ "$#" -ne 4 ]     && internal_fail "api error"

   [ -z "$style" ]    && internal_fail "style is empty"
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

   #
   # during shared operation we may revisit stuff, which is boring
   #
   local filename
   local dbaddress

   #
   # the address is what is relative to the current projectdir (configfile)
   # the dbaddress is what is relative to the current database
   # the filename is relative to the current PWD
   #
   if [ "${style}" = "share" -a ! -z "${url}" ] && \
      nodemarks_contain_share "${marks}"
   then
      filename="`node_guess_address "${url}" "${nodetype}"`"
      if [ -z "${filename}" ]
      then
         filename="${uuid}"
      fi
      filename="`filepath_concat "${MULLE_SOURCETREE_SHARE_DIR}" "${address}"`"
      log_fluff "Use guessed address \"${filename}\" for shared URL \"${url}\""

      # use shared root database for shared nodes
      database="/"
      dbaddress="${filename}"
   else
      filename="`__concat_projectdir_address "${projectdir}" "${address}"`"
      dbaddress="${address}"
   fi

   if nodemarks_contain_noupdate "${marks}"
   then
      if [ -e "${filename}"  ]
      then
         log_fluff "\"${filename}\" is marked as noupdate and exists"
         return
      fi

      if nodemarks_contain_norequire "${marks}"
      then
         log_fluff "\"${filename}\" is marked as noupdate and doesnt exist, \
but it is not required"
         return
      fi
      fail "\${filename}\" is missing, but required"
   fi

   #
   # check if this nodeline is known
   #
   local previousnodeline
   local previousaddress

   previousnodeline="`db_fetch_nodeline_for_uuid "${database}" "${uuid}"`"

   #
   # check if this .sourcetree is actually "responsible" for this
   # shared node (otherwise let someone else do it)
   # this can happen, when someone else shares the a node, which would
   # have the same name as a previous share
   #
   if [ ! -z "${previousnodeline}" ]
   then
      if [ "${style}" = "share" ]
      then
         local oldowner

         oldowner="`db_fetch_owner_for_uuid "${database}" "${uuid}"`"
         if [ "${database}" != "${oldowner}" ]
         then
            if db_is_uuid_alive "${database}" "${uuid}"
            then
               log_fluff "\"${projectdir}\" does not feel responsible for \"${address}\""
               return
            else
               log_fluff "\"${projectdir}\" takes over responsibility for \"${address}\" from \"${oldowner}\""
            fi
         fi
      fi
   fi

   #
   # If we find something in the database  for the same address,
   # check if it is not ours.
   # But it could be old. If its not old, it has preference.
   #
   local otheruuid

   otheruuid="`db_fetch_uuid_for_address "${database}" "${filename}"`"
   if [ ! -z "${otheruuid}" ] && db_is_uuid_alive "${database}" "${otheruuid}"
   then
      if [ "${otheruuid}" != "${uuid}" ]
      then
         # this is address is already taken
         log_fluff "Address \"${filename}\" is already used by \
node \"${otheruuid}\" in database \"${database}\". Skip it."
         return 0
      fi
   else
      log_debug "Address \"${filename}\" is unique in database \"${database}\""
   fi

   local previousfilename

   #
   # find out, where it was previously located relative to "projectdir"
   #
   if [ ! -z "${previousnodeline}" ]
   then
      previousfilename="`db_fetch_filename_for_uuid "${database}" "${uuid}"`"
      [ -z "${previousfilename}" ] && internal_fail "corrupted db"

      #
      # previousfilename is relative to database, but we want relative
      # to project directory too
      #
      local  rootdir

      rootdir="`db_get_rootdir "${database}"`"
      previousfilename="`filepath_concat "${rootdir}" "${previousfilename}"`"

      rootdir="`cfg_rootdir "${projectdir}"`"
      previousaddress="`relative_path_between "${rootdir}" "${previousfilename}"`"
   fi

   local magic
   local contentschanged
   local remember
   local skip
   local nodetype
   local results
   local dbaddress

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

   magic="$(sed -n '1p' <<< "${results}")"
   [ "${magic}" = "-- VfL Bochum 1848 --" ]|| internal_fail "stdout was polluted with \"magic\""

   contentschanged="$(sed -n '2p' <<< "${results}")"
   remember="$(sed -n '3p' <<< "${results}")"
   skip="$(sed -n '4p' <<< "${results}")"
   nodetype="$(sed -n '5p' <<< "${results}")"
   dbaddress="$(sed -n '6p' <<< "${results}")"

   log_debug "contentschanged: ${contentschanged}" \
             "remember: ${remember}" \
             "skip: ${skip}" \
             "nodetype: ${nodetype}"

   if [ "${skip}" = "YES" ]
   then
      log_debug "Skipping to next nodeline as indicated..."
      return 0
   fi

   if [ "${remember}" = "YES" ]
   then
      # branch could be overwritten
      log_debug "${C_INFO}Remembering ${nodeline} ..."

      local filename

      nodeline="`node_print_nodeline`"
      db_memorize "${database}" "${uuid}" "${nodeline}" "${projectdir}" "${dbaddress}"

      if [ "${OPTION_FIX}" != "NO" ] && [ -d "${filename}" ]
      then
         local  output

         [ -z "${SOURCETREE_FIX_FILE}" ] && internal_fail "SOURCETREE_FIX_FILE is empty"
         output="`filepath_concat "${filename}" "${SOURCETREE_FIX_FILE}"`"

         log_fluff "Writing fix info into \"${output}\""

         redirect_exekutor "${output}" echo "`basename -- "${address}"`"
      fi
   else
      log_debug "Don't need to remember \"${nodeline}\" (should be unchanged)"
   fi

   db_set_uuid_alive "${database}" "${uuid}"
}


update_with_nodelines()
{
   log_entry "update_with_nodelines" "$@"

   local nodelines="$1"
   local style="$2"
   local projectdir="$3"
   local database="$4"

   [ -z "${style}" ] && internal_fail "style is empty"

   if [ -z "${nodelines}" ]
   then
      log_fluff "There is nothing to do for \"${style}\""
      return 0
   fi

   log_debug "\"${style}\" update \"${nodelines}\" for db \"${projectdir:-ROOT}\" ($PWD)"

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

      update_with_nodeline "${nodeline}" "${style}" "${projectdir}" "${database}"
   done

   IFS="${DEFAULT_IFS}"
}


recursive_update_with_nodeline()
{
   log_entry "recursive_update_with_nodeline" "$@"

   local nodeline="$1"
   local style="$2"
   local projectdir="$3"
   local database="$4"

   [ "$#" -ne 4 ]     && internal_fail "api error"
   [ -z "$style" ]    && internal_fail "style is empty"
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
   if nodemarks_contain_norecurse "${marks}"
   then
      return
   fi

# try to throw away old database
#
#   if ! cfg_exists "${address}"
#   then
#      return
#   fi

   local filename

   filename="`db_fetch_filename_for_uuid "${database}" "${uuid}"`"
   projectdir="`__concat_projectdir_address "${database}" "${filename}"`"

   #
   # usually database is in projectdir, except when we update with share
   # and the node is shared. But this switch is not done here
   # but in update_with_nodeline
   #
   if [ ! -d "${projectdir}" ]
   then
      log_fluff "Will not recursively update \"${projectdir}\" as it's not \
a directory"
      return
   fi

   database="${projectdir}"
   if nodemarks_contain_noshare "${marks}"
   then
      style="noshare"
   fi

   sourcetree_update "${style}" "${projectdir}" "${database}"
}


recursive_update_with_nodelines()
{
   log_entry "recursive_update_with_nodelines" "$@"

   local nodelines="$1"
   local style="$2"
   local projectdir="$3"
   local database="$4"

   [ -z "${style}" ] && internal_fail "style is empty"

   if [ -z "${nodelines}" ]
   then
      log_fluff "There is nothing to do"
      return 0
   fi

   log_debug "\"${style}\" update \"${nodelines}\" for db \"${projectdir:-ROOT}\" ($PWD)"

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

      # needed for root database only
      if [ "${database}" = "/" ]
      then
         if fgrep -q -s -x "${nodeline}" <<< "${VISITED}"
         then
            continue
         fi
         VISITED="`add_line "${VISITED}" "${nodeline}"`"
      fi

      recursive_update_with_nodeline "${nodeline}" \
                                     "${style}" \
                                     "${projectdir}" \
                                     "${database}"
   done

   IFS="${DEFAULT_IFS}"
}


sourcetree_update()
{
   local style="$1"
   local projectdir="$2"
   local database="$3"

   db_zombify_nodes "${database}"

   log_verbose "Doing a \"${style}\" update for \"${projectdir}\"."
   log_fluff "Set dbtype to \"${style}\""

   if [ "${style}" = "share" -a "${database}" != "/" ]
   then
      # remember that not everything is saved here
      db_set_dbtype "${database}" "partial"
   else
      db_set_dbtype "${database}" "${style}"
   fi


   local nodelines

   nodelines="`cfg_read "${projectdir}"`"
   update_with_nodelines "${nodelines}" "${style}" "${projectdir}" "${database}" || return 1

   db_bury_zombies "${database}"


   case "${style}" in
      flat)
      ;;

      *)
         #
         # Run this in a loop for the benefit of the root database, where
         # shared nodes might be pushed into from a recursive update
         #
         nodelines="`db_fetch_all_nodelines "${database}" | sort`"
         recursive_update_with_nodelines "${nodelines}" \
                                         "${style}" \
                                         "${projectdir}" \
                                         "${database}"  || return 1

         if [ "${database}" = "/" -a ! -z "${nodelines}" ]
         then
            memofile="`db_set_memo "${database}" "${nodelines}"`"

            while :
            do
               #
               # Unsorted, the order of the recursive updates would depend on
               # the (random) uuid.
               # I don't see how this would be any problem. Yet let's sort
               # stuff anyway, for reproducability.
               #
               nodelines="`db_fetch_all_nodelines "${database}" | sort`"
               nodelines="`fgrep -v -x -f "${memofile}" <<< "${nodelines}"`"
               if [ -z "${nodelines}" ]
               then
                  break
               fi

               recursive_update_with_nodelines "${nodelines}" \
                                               "${style}" \
                                               "${projectdir}" \
                                               "${database}"  || return 1
               db_add_memo "${database}" "${nodelines}"
            done
         fi
      ;;
   esac

   db_set_shareddir "${database}" "${MULLE_SOURCETREE_SHARE_DIR}"
   db_clear_update "${database}"
   if db_contains_entries "${database}"
   then
      db_set_ready "${database}"
   fi
}


#
# STYLES:
#
# flat:      run through nodelines, fetch what is missing
# recurse:   do flat first, then run through db and do recurse in each folder
#            that has a config file (repeat)
# share:     the trick for "share" is, that we use a joined database
#            for nodes marked share and again (local) databases for those
#            marked noshare like in recurse.
#
sourcetree_update_root()
{
   log_entry "sourcetree_update_root" "$@" "($PWD)"

   local style

   style="${SOURCETREE_MODE}"

   db_ensure_consistency "/"
   db_ensure_compatible_dbtype "/" "${style}"

   # TODO: make this a MULLE_FETCH_ENVIRONMENT variable
   local SOURCETREE_UPDATE_CACHE

   SOURCETREE_UPDATE_CACHE="`absolutepath "${SOURCETREE_DB_DIR}/.update-cache"`"

   rmdir_safer "${SOURCETREE_UPDATE_CACHE}"
   mkdir_if_missing "${SOURCETREE_UPDATE_CACHE}"

   sourcetree_update "${style}" "/" "/"
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

   mulle_fetch_version="`${MULLE_FETCH:-mulle-fetch} version`"
   [ -z "${mulle_fetch_version}" ] && fail "${MULLE_FETCH:-mulle-fetch} not installed"

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

