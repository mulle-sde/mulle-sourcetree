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


__concat_config_absolute_filename()
{
   local config="$1"
   local address="$2"

   case "${config}" in
      /|/*/)
      ;;

      *)
         internal_fail "config \"${config}\" is malformed"
      ;;
   esac

   case "${address}" in
      /*)
         internal_fail "address \"${config}\" is absolute"
      ;;
   esac

   echo "${MULLE_VIRTUAL_ROOT}${config}${address}"
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
         if [ "${MULLE_SYMLINK}" = "YES" ]
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

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != "YES" ] && [ -e "${address}" ]
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

   # just address as filename ?
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
   local marks="$2"
   local uuid="$3"
   local database="$4"

   [ -z "${filename}" ] && internal_fail "empty filename"
   [ -z "${uuid}" ]     && internal_fail "empty uuid"

   if nodemarks_contain_nodelete "${marks}"
   then
      fail "Can't remove \"${filename}\" as it is marked nodelete"
   fi

   db_forget "${database}" "${uuid}"
   db_bury "${database}" "${uuid}" "${filename}"
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
      log_fluff "\"${newfilename}\" already exists"
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
      log_debug "This is a new node"

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
            update_safe_remove_node "${previousfilename}" "${marks}" "${uuid}" "${database}"
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
         update_safe_clobber "${filename}" "${database}"
      ;;

      "remove")
         update_safe_remove_node "${previousfilename}" "${marks}" "${uuid}" "${database}"
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

   log_debug "${C_INFO}Actions for \"${address}\": ${actionitems:-none}"

   local contentschanged="NO"
   local remember="NO"
   local skip="NO"

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
   local config="$3"
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

   #
   # the address is what is relative to the current config (configfile)
   # the filename is an absolute path
   #
   if [ "${style}" = "share" ] && nodemarks_contain_share "${marks}"
   then
      filename="`filepath_concat "${MULLE_SOURCETREE_SHARE_DIR}" "${address}"`"
      #
      # use shared root database for shared nodes
      #
      database="/"
      log_debug "using root database for share node \"${address}\""
   else
      filename="`__concat_config_absolute_filename "${config}" "${address}"`"
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
      fail "\${filename}\" is missing, marked as noupdate, but required"
   fi

   #
   # If we find something in the database for the same address,
   # check if it is ours. This could be a new entry/edit whatever.
   # But it could be old. If its not old, it has preference.
   #
   # If we are in share mode, then the database is "/" here, so no worries
   # We don't have to check the owner, because the uuid will be different
   # to ours. (since it's coming from a different config)
   # Search for absolute path, as that is what gets stored into the DB
   #
   local otheruuid

   otheruuid="`db_fetch_uuid_for_filename "${database}" "${filename}"`"
   if [ ! -z "${otheruuid}" ]
   then
      if db_is_uuid_alive "${database}" "${otheruuid}"
      then
         if [ "${otheruuid}" != "${uuid}" ]
         then
            # this is address is already taken
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

   previousnodeline="`db_fetch_nodeline_for_uuid "${database}" "${uuid}"`"

   #
   # find out, where it was previously located
   #
   if [ ! -z "${previousnodeline}" ]
   then
      previousfilename="`db_fetch_filename_for_uuid "${database}" "${uuid}"`"

      [ -z "${previousfilename}" ] && internal_fail "corrupted db"
   fi

   local magic
   local contentschanged
   local remember
   local skip
   local nodetype
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

   magic="$(sed -n '1p' <<< "${results}")"
   [ "${magic}" = "-- VfL Bochum 1848 --" ]|| internal_fail "stdout was polluted with \"magic\""

   contentschanged="$(sed -n '2p' <<< "${results}")"
   remember="$(sed -n '3p' <<< "${results}")"
   skip="$(sed -n '4p' <<< "${results}")"
   nodetype="$(sed -n '5p' <<< "${results}")"

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

      filename="`physicalpath "${filename}" `"
      [ -z "${filename}" ] && internal_fail "Memorizing non existing file"

      log_debug "${C_INFO}Remembering ${nodeline} located at \"${filename}\"..."

      nodeline="`node_print_nodeline`"
      db_memorize "${database}" "${uuid}" "${nodeline}" "${config}" "${filename}"

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

   IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"

      if [ -z "${nodeline}" ]
      then
         continue
      fi

      update_with_nodeline "${nodeline}" "${style}" "${config}" "${database}"
   done

   IFS="${DEFAULT_IFS}"
}


recursive_update_with_nodeline()
{
   log_entry "recursive_update_with_nodeline" "$@"

   local nodeline="$1"
   local style="$2"
   local config="$3"
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
   local newconfig
   local newdatabase

   filename="`db_fetch_filename_for_uuid "${database}" "${uuid}" `"

   [ -z "${filename}" ] && internal_fail "corrupted db"

   newconfig="`string_remove_prefix "${filename}" "${MULLE_VIRTUAL_ROOT}"`"
   newconfig="${newconfig}/"
   newdatabase="${newconfig}"

   log_debug "MULLE_VIRTUAL_ROOT : ${MULLE_VIRTUAL_ROOT}"
   log_debug "config         : ${config}"
   log_debug "database           : ${database}"
   log_debug "filename           : ${filename}"
   log_debug "newconfig      : ${newconfig}"
   log_debug "newdatabase        : ${newdatabase}"

   #
   # usually database is in config, except when we update with share
   # and the node is shared. But this switch is not done here
   # but in update_with_nodeline
   #
   if [ ! -d "${filename}" ]
   then
      log_fluff "Will not recursively update \"${filename}\" as it's not \
a directory"
      return
   fi

   if nodemarks_contain_noshare "${marks}"
   then
      style="noshare"
   fi

   sourcetree_update "${style}" "${newconfig}" "${newdatabase}"
}


recursive_update_with_nodelines()
{
   log_entry "${C_FLUFF}recursive_update_with_nodelines${C_DEBUG}" "$@"

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

   log_fluff "\"${style}\" update \"${nodelines}\" for db \"${config:-ROOT}\" ($PWD)"

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
                                     "${config}" \
                                     "${database}"
   done

   IFS="${DEFAULT_IFS}"
}


#
# style      : flat, recurse, share
# config     : config relative to MULLE_VIRTUAL_ROOT
# database   : prefix relative to MULLE_VIRTUAL_ROOT
#
sourcetree_update()
{
   log_entry "sourcetree_update" "$@"

   local style="$1"
   local config="$2"
   local database="$3"

   if ! fgrep -q -s -x "${database}" <<< "${UPDATED}"
   then
      log_debug "add \"${database}\" to UPDATED"
      UPDATED="`add_line "${UPDATED}" "${database}"`"
   fi

   #
   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database
   # then just bail
   #
   local nodelines

   if ! nodelines="`cfg_read "${config}"`"
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      if ! db_dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\" so nothing to do"
         return 2
      fi
   fi

   log_verbose "Doing a \"${style}\" update for \"${config}\"."
   log_fluff "Set dbtype to \"${style}\""

   # partial is no more
   db_set_dbtype "${database}" "${style}"

   #
   # Enclose updates in zombification
   #
   db_zombify_nodes "${database}"

   #
   # this is the "flat" update, that does the local "${config}" into
   # "${database}" only
   #
   update_with_nodelines "${nodelines}" "${style}" "${config}" "${database}" || return 1

   #
   # In the case of share and the root  database, we remember what the
   # flat nodelines where (could also just reread config ?)
   #
   local memofile

   if [ "${style}" = "share" -a "${database}" = "/" -a ! -z "${nodelines}" ]
   then
      memofile="`db_set_memo "${database}" "${nodelines}"`"
   fi

   db_bury_zombies "${database}"


   case "${style}" in
      recurse|share)
         #
         # This is the "recursive" part over the stuff generated during "flat".
         # Its the same for recurse and share.
         #
         # Unsorted, the order of the recursive updates would depend on
         # the (random) uuid.
         # I don't see how this would be any problem. Yet let's sort
         # stuff anyway by name, for reproducability.
         #
         nodelines="`db_fetch_all_nodelines "${database}" | sort`"
         recursive_update_with_nodelines "${nodelines}" \
                                         "${style}" \
                                         "${config}" \
                                         "${database}"
         if [ $? -eq 1 ] # 2 is OK
         then
            return 1
         fi
      ;;
   esac

   #
   # In the share case, we have done the flat and the recurse part already
   # Now recurse may have added stuff to our database. These haven't been
   # recursed yet. So we do this now. There can only be additions now to
   # root, so we don't zombify.
   #
   if [ ! -z "${memofile}" ]
   then
      #
      # Run this in a loop for the benefit of the root database, where
      # shared nodes might be have been pushed into from a recursive update
      #
      while :
      do
         nodelines="`db_fetch_all_nodelines "${database}" | sort`"
         nodelines="`fgrep -v -x -f "${memofile}" <<< "${nodelines}"`"
         if [ -z "${nodelines}" ]
         then
            break
         fi

         log_debug "Redo root because lines have changed"

         recursive_update_with_nodelines "${nodelines}" \
                                         "${style}" \
                                         "${config}" \
                                         "${database}"
         if [ $? -eq 1 ] # 2 is OK
         then
            return 1
         fi

         db_add_memo "${database}" "${nodelines}"
      done

      remove_file_if_present "${memofile}"
   fi

   if [ "${style}" = "share" ]
   then
      db_set_shareddir "${database}" "${MULLE_SOURCETREE_SHARE_DIR}"
   else
      db_clear_shareddir "${database}"
   fi

   db_clear_update "${database}"
   if db_contains_entries "${database}"
   then
      db_set_ready "${database}"
   fi
}


#
# Updating flat or recursive is simple. It can be done on any sourcetree,
# that is not share.
#
# Share is trickier though, when you are doing share, you always have to
# update from "/". So you have to set SOURCETREE_START to that. Then it could
# be that there is no configuration in "/", have to bail if that's the case.
# What should be checked is, that during the update the original
# SOURCETREE_START is reached, otherwise it's headscratching time.
#
# STYLES:
#
# flat:      run through nodelines, fetch what is missing
# recurse:   do flat first, then run through db and do recurse in each folder
#            that has a config file (repeat)
# share:     the trick for "share" is, that we use a joined database
#            for nodes marked share and again (local) databases for those
#            marked noshare like in recurse. This is stored in root.
#
sourcetree_update_start()
{
   log_entry "sourcetree_update_start" "$@" "($PWD)"

   local style
   local startpoint
   local UPDATED

   startpoint="${SOURCETREE_START}"

   style="${SOURCETREE_MODE}"
   case "${style}" in
      share)
         if [ "${SOURCETREE_START}" != "/" ]
         then
            log_info "Forced deferral to ${MULLE_VIRTUAL_ROOT} for share"
            SOURCETREE_START="/"
         fi
      ;;
   esac

   db_ensure_consistency "${SOURCETREE_START}"
   db_ensure_compatible_dbtype "${SOURCETREE_START}" "${style}"

   #
   # TODO: make this a MULLE_FETCH_ENVIRONMENT variable
   # SOURCETREE_UPDATE_CACHEis used to suppress asking git mirrors to refetch
   # superflously. For configurations where dependencies appear twice in
   # the sourcetree (recurse)
   #
   local SOURCETREE_UPDATE_CACHE

   SOURCETREE_UPDATE_CACHE="`absolutepath "${SOURCETREE_DB_NAME}/.update-cache"`"

   rmdir_safer "${SOURCETREE_UPDATE_CACHE}"
   mkdir_if_missing "${SOURCETREE_UPDATE_CACHE}"

   sourcetree_update "${style}" "${SOURCETREE_START}" "${SOURCETREE_START}"
   case $? in
      0)
      ;;

      1)
         return 1
      ;;

      2)
        fail "There is no sourcetree in \"${MULLE_VIRTUAL_ROOT}${SOURCETREE_START}\""
      ;;
   esac

   log_debug "UPDATED: ${UPDATED}"

   if ! fgrep -q -s -x "${startpoint}" <<< "${UPDATED}"
   then
      fail "\"${MULLE_VIRTUAL_ROOT}${startpoint}\" is not reachable from the sourcetree root (${MULLE_VIRTUAL_ROOT})"
   fi
}


warn_dry_run()
{
   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = "YES" ]
   then
      log_warning "***IMPORTANT REMINDER***

As fetches and zombification are not performed during a dry run (-n), the
actual commands of an update can not be shown. This is especially true for
recurse and share updates. And when updating an existing database, when
edits have been made to the configuration.
"
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

   mulle_fetch_version="`${MULLE_FETCH:-mulle-fetch} version`"
   [ -z "${mulle_fetch_version}" ] && fail "${MULLE_FETCH:-mulle-fetch} not installed"

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   warn_dry_run

   sourcetree_update_start
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

