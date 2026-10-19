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
MULLE_SOURCETREE_SYNC_SH='included'


# need this immediately for log_walk_fluff
include "sourcetree::walk"


sourcetree::sync::usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} sync [options]

   Apply recent edits in the source tree to the filesystem. The configuration
   is read and the changes applied. This will fetch repositories and archives,
   if the destination is absent.

   Use \`${MULLE_EXECUTABLE_NAME} fix\`, if you want to sync the source
   tree with changes you made  in the filesystem. You can inhibit the fetching
   of a dependency by setting MULLE_SOURCETREE_FETCH_<name> to 'NO'.
   e.g. mulle-sde environment --os darwin MULLE_SOURCETREE_FETCH_FOUNDATION NO.
        mulle-sourctree mark Foundation no-require-os-darwin

Options:
   -r                         : sync recursively
   --serial                   : don't fetch dependencies in parallel
   --parallel                 : fetch dependencies in parallel (default)
   --quick                    : skip sync, if configs, environment and
                                destinations are unchanged since the last
                                successful sync (not with -f)
   --no-fix                   : do not write ${SOURCETREE_FIX_FILENAME} files
   --override-branch <branch> : temporary override of the _branch for all nodes

   The following options are passed through to ${MULLE_FETCH:-mulle-fetch}.

   --cache-dir   --mirror-dir  --search-path
   --refresh     --symlinks    --absolute-symlinks
   --no-refresh  --no-symlinks --no-absolute-symlinks

   See the ${MULLE_FETCH:-mulle-fetch} usage for information.

Environment:
   MULLE_SOURCETREE_RESOLVE_TAG   : resolve tags using mulle-fetch resolve (YES)
   MULLE_SOURCETREE_FETCH_<name>  : set to NO to inhibit fetch of a dependency
EOF
  exit 1
}


#
# local _config
# local _filename
# local _database
#
sourcetree::sync::__get_db_descendinfo()
{
   log_walk_entry "sourcetree::sync::__get_db_descendinfo" "$@"

   local database="$1"
   local address="$2"
   local uuid="$3"

   sourcetree::db::r_fetch_filename_for_uuid "${database}" "${uuid}"
   _filename="${RVAL}"

   [ -z "${_filename}" ] && _internal_fail "corrupted db ${database} for ${uuid}, better clean it (${MULLE_VIRTUAL_ROOT:-$PWD})"

   _config="${_filename#${MULLE_VIRTUAL_ROOT}}"
   _config="${_config}/"
   _database="${_config}"

   sourcetree::walk::r_symbol_for_address "${address}"
   _symbol="${RVAL}"
}

#
# local _config
# local _filename
# local _database
#
sourcetree::sync::__get_config_descendinfo()
{
   log_walk_entry "sourcetree::sync::__get_config_descendinfo" "$@"

   local config="$1"
   local address="$2"

   r_filepath_concat "${config}" "${address}"
   _config="${RVAL}"

   # sic use config
   case "${config}" in
      /"${MULLE_SOURCETREE_STASH_DIRNAME}"/*)
         r_basename "${config}"
         r_filepath_concat "${MULLE_SOURCETREE_STASH_DIR}" \
                           "${_config#"/${MULLE_SOURCETREE_STASH_DIRNAME}"/}"
         _filename="${RVAL}"
      ;;

      /*)
         _filename="${RVAL}"
      ;;

      *)
         r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${_config}"
         _filename="${RVAL}"
      ;;
   esac

   _config="${_config}/"
   _database="${_config}"

   sourcetree::walk::r_symbol_for_address "SOURCETREE_CONFIG_NAME" "${address}"
   _symbol="${RVAL}"
}


# rc: 0 recurse
#     : 1 don't recurse
#     : 4 symlink
#
# input: parsed nodeline + filename
sourcetree::sync::check_descend_nodeline()
{
   log_walk_entry "sourcetree::sync::check_descend_nodeline" "$@"

   local filename="$1"
   local marks="$2"

   if sourcetree::marks::disable "${marks}" "descend"
   then
      log_walk_fluff "Node \"${filename}\" is marked no-descend"
      return 1
   fi

   #
   # usually database is in config, except when we update with share
   # and the node is shared. But this switch is not done here
   # but in sourcetree::action::do_actions_with_nodeline
   #
   if [ -L "${filename}" ]
   then
      # it's a symlink. We assume that this project has set up itself
      # properly, we also don't really want to write our .mulle-sourcetree
      # database into it.
      #
      log_walk_fluff "\"${filename}\" is a symlink"
      return 4
   fi

   if [ ! -d "${filename}" ]
   then
      if [ -e "${filename}" ]
      then
         log_walk_fluff "Will not recursively update \"${filename}\" as it's not a directory"
         return 1
      fi

      if sourcetree::marks::enable "${marks}" "share"
      then
         log_walk_fluff "Destination \"${filename}\" does not exist."
      else
         # not so unusal now, when we amalgamate
         log_walk_fluff "Destination \"${filename}\" does not exist, possibly unexpectedly."
      fi

      return 1
   fi

   log_debug "Recurse as it's a directory"
   return 0
}


sourcetree::sync::_descend_db_nodeline()
{
   log_walk_entry "sourcetree::sync::_descend_db_nodeline" "$@"

   [ "$#" -ne 4 ] && _internal_fail "api error"

   local nodeline="$1"; shift
   local style="$1"; shift

   local config="$1"
   local database="$2"

   [ -z "${nodeline}" ]   && _internal_fail "nodeline is empty"
   [ -z "${style}" ]      && _internal_fail "style is empty"

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _userinfo
   local _tag
   local _url
   local _uuid

   sourcetree::nodeline::parse "${nodeline}"  # ??

   local _filename
   local _config
   local _database
   local _symbol

   sourcetree::sync::__get_db_descendinfo "${database}" "${_address}" "${_uuid}"

   # remove duplicate marker from _filename
   _filename="${_filename%#*}"

   log_walk_setting "MULLE_VIRTUAL_ROOT : ${MULLE_VIRTUAL_ROOT}"
   log_walk_setting "config             : ${config}"
   log_walk_setting "database           : ${database}"
   log_walk_setting "filename           : ${_filename}"
   log_walk_setting "newconfig          : ${_config}"
   log_walk_setting "newdatabase        : ${_database}"
   log_walk_setting "symbol             : ${_symbol}"

   local _style
   local rc

   sourcetree::sync::check_descend_nodeline "${_filename}" "${_marks}"
   rc=$?

   if sourcetree::sync::_style_for_${style} ${rc}
   then
      sourcetree::sync::_sync_${_style} "${_config}" "${_database}" "${_symbol}"
      return $?
   fi
}


sourcetree::sync::descend_config_nodeline()
{
   log_walk_entry "sourcetree::sync::descend_config_nodeline" "$@"

   [ "$#" -ne 4 ] && _internal_fail "api error"

   local nodeline="$1"; shift
   local style="$1"; shift

   local config="$1"
   local database="$2"

   [ -z "${nodeline}" ] && _internal_fail "nodeline is empty"
   [ -z "${style}" ]    && _internal_fail "style is empty"

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _raw_userinfo
   local _userinfo
   local _tag
   local _url
   local _uuid

   sourcetree::nodeline::parse "${nodeline}"  # !!

   local _filename
   local _config
   local _database
   local _symbol

   sourcetree::sync::__get_config_descendinfo "${config}" "${_address}"

   log_walk_setting "MULLE_VIRTUAL_ROOT : ${MULLE_VIRTUAL_ROOT}"
   log_walk_setting "config             : ${config}"
   log_walk_setting "database           : ${database}"
   log_walk_setting "filename           : ${_filename}"
   log_walk_setting "newconfig          : ${_config}"
   log_walk_setting "newdatabase        : ${_database}"
   log_walk_setting "symbol             : ${_symbol}"

   if ! sourcetree::sync::check_descend_nodeline "${_filename}"
   then
      return 1
   fi

   sourcetree::sync::_sync_${style} "${_config}" "${_database}" "${_symbol}"
}


#
# A flat update has run. Now walk over the DB entries (actually existing
# stuff at proper position) and recursively do the inferior sourcetrees
#
sourcetree::sync::descend_db_nodelines()
{
   log_walk_entry "sourcetree::sync::descend_db_nodelines" "$@"

   local style="$1"; shift

   local config="$1"
   local database="$2"

   local nodelines

   nodelines="`sourcetree::db::fetch_all_nodelines "${database}" `" || exit 1
   if [ -z "${nodelines}" ]
   then
      _log_fluff "No \"${style}\" update of database \"${database:-ROOT}\" as \
it is empty (${PWD#"${MULLE_USER_PWD}/"})"
      return
   fi

   _log_debug "Continuing with a \"${style}\" update of nodelines \
\"${nodelines}\" of db \"${database:-ROOT}\" (${PWD#"${MULLE_USER_PWD}/"})"

   local nodeline

   .foreachline nodeline in ${nodelines}
   .do
      if [ -z "${nodeline}" ]
      then
         .continue
      fi

      # needed for root database only
      if [ "${database}" = "/" ]
      then
         if find_line "${VISITED}" "${nodeline}"
         then
            .continue
         fi
         r_add_line "${VISITED}" "${nodeline}"
         VISITED="${RVAL}"
      fi

      sourcetree::sync::_descend_db_nodeline "${nodeline}" \
                                             "${style}" \
                                             "${config}" \
                                             "${database}"
      rc=$?

      # 127 is not really an error in a descendant 
      if [ $rc -ne 0 -a $rc -ne 127 ]
      then
         return $rc
      fi
   .done

   return 0
}



#
# A flat update has run. Now walk over the DB entries (actually existing
# stuff at proper position) and recursively do the inferior sourcetrees
#
sourcetree::sync::descend_config_nodelines()
{
   log_walk_entry "sourcetree::sync::descend_config_nodelines" "$@"

   local style="$1"; shift

   local config="$1"
   local database="$2"
   local symbol="$3"

   local nodelines

   # caller may pass already read nodelines as 4th argument
   if [ $# -ge 4 ]
   then
      nodelines="$4"
   else
      nodelines="`sourcetree::walk::cfg_read "${symbol}" "${config}" `"
   fi

   if [ -z "${nodelines}" ]
   then
      _log_fluff "No\"${style}\" update of config \"${config:-ROOT}\" as it \
is empty (${PWD#"${MULLE_USER_PWD}/"})"
      return
   fi

   _log_debug "Continuing with a \"${style}\" update of \
nodelines \"${nodelines}\" from config \"${config:-ROOT}\" (${PWD#"${MULLE_USER_PWD}/"})"

   local nodeline

   .foreachline nodeline in ${nodelines}
   .do
      if [ -z "${nodeline}" ]
      then
         .continue
      fi

      # needed for root database only
      if [ "${database}" = "/" ]
      then
         if find_line "${VISITED}" "${nodeline}"
         then
            log_walk_fluff "\${nodeline}\" was already visited"
            .continue
         fi
         r_add_line "${VISITED}" "${nodeline}"
         VISITED="${RVAL}"
      fi

      sourcetree::sync::descend_config_nodeline "${nodeline}" \
                                                "${style}" \
                                                "${config}" \
                                                "${database}"
   .done
}



####
# ONLY_SHARE UPDATE
####
#
# config     : config relative to MULLE_VIRTUAL_ROOT
# database   : prefix relative to MULLE_VIRTUAL_ROOT
#
sourcetree::sync::_style_for_only_share()
{
   local rc="$1"

   _style="only_share"

   case $rc in
      0|4)
         return 0
      ;;
   esac
   return 1
}


sourcetree::sync::nodeline_sync_only_share()
{
   log_walk_entry "sourcetree::sync::nodeline_sync_only_share" "$@"

   local nodeline="$1"
   local config="$2"
   local database="$3"

   [ "$#" -ne 3 ]     && _internal_fail "api error"
   [ -z "$style" ]    && _internal_fail "style is empty"
   [ -z "$nodeline" ] && _internal_fail "nodeline is empty"

   sourcetree::action::do_actions_with_nodeline "${nodeline}" \
                                                "only_share" \
                                                "${config}" \
                                                "${database}"
}


sourcetree::sync::_sync_only_share()
{
   log_walk_entry "sourcetree::sync::_sync_only_share" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"

   local style

   style="only_share"

   if ! find_line "${UPDATED}" "${config}"
   then
      log_debug "Add config \"${config}\" to UPDATED"

      r_add_line "${UPDATED}" "${config}"
      UPDATED="${RVAL}"
   fi

   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database then just bail
   #
   local nodelines

   if ! nodelines="`sourcetree::walk::cfg_read "${symbol}" "${config}" `"
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      return 127
   fi

   local nodeline
   local index

   index=-1
   .foreachline nodeline in ${nodelines}
   .do
      index=$(( index + 1 ))
      if [ -z "${nodeline}" ]
      then
         .continue
      fi

      # needed for root database only
      if [ "${database}" = "/" ]
      then
         if find_line "${VISITED}" "${nodeline}"
         then
            .continue
         fi

         r_add_line "${VISITED}" "${nodeline}"
         VISITED="${RVAL}"
      fi

      log_debug "Perform actions for \"${nodeline}\" on an \"only_share\" update for \"${config}\""

      sourcetree::action::do_actions_with_nodeline "${nodeline}" \
                                                   "only_share" \
                                                   "${config}" \
                                                   "${database}" \
                                                   "${index}" || return 1
   .done

   log_debug "Doing a \"only_share\" update for \"${config}\"."

   sourcetree::sync::descend_config_nodelines "only_share" \
                                              "${config}" \
                                              "${database}" \
                                              "${symbol}" \
                                              "${nodelines}" || return 1
}


sourcetree::sync::sync_only_share()
{
   log_walk_entry "sourcetree::sync::sync_only_share" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"
   local startpoint="$4"

   local UPDATED
   local rc

   sourcetree::sync::_sync_only_share "${config}" "${database}" "${symbol}"
   rc=$?

   if [ $rc -eq 0 ]
   then
      log_debug "UPDATED: ${UPDATED}"

      if ! find_line "${UPDATED}" "${startpoint}"
      then
         fail "\"${MULLE_VIRTUAL_ROOT}${startpoint}\" is not reachable from \
the sourcetree root (${MULLE_VIRTUAL_ROOT})"
      fi
   else
      log_debug "sourcetree sync of ${config} failed ($rc)"
   fi
   return $rc
}


####
# SHARE UPDATE
####
#
# config     : config relative to MULLE_VIRTUAL_ROOT
# database   : prefix relative to MULLE_VIRTUAL_ROOT
#

sourcetree::sync::_style_for_share()
{
   local rc="$1"

   _style="share"

   case $rc in
      0)
         return 0
      ;;

      4)
         _style="only_share"
         return 0
      ;;
   esac
   return 1
}


#
# config     : config relative to MULLE_VIRTUAL_ROOT
# database   : prefix relative to MULLE_VIRTUAL_ROOT
#
sourcetree::sync::_sync_share()
{
   log_walk_entry "sourcetree::sync::_sync_share" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"

   local style

   style="share"

   if ! find_line "${UPDATED}" "${config}"
   then
      log_debug "Add config \"${config}\" to UPDATED"
      r_add_line "${UPDATED}" "${config}"
      UPDATED="${RVAL}"
   fi

   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database then just bail
   #
   local nodelines
   local rc

   nodelines="`sourcetree::walk::cfg_read "${symbol}" "${config}"`"
   rc=$?

   if [ $rc -eq 2 ]
   then
      log_debug "There is no sourcetree configuration in \"${config}\""

      if [ "${database}" = '/' ]
      then
         log_debug "It's the root \"${database}\" so nothing more to do."
         sourcetree::db::clear_update "${database}"
         sourcetree::db::set_ready "${database}" # "${config}"
         return 127
      fi

      if ! sourcetree::db::dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\" so nothing to do."
         return 127
      fi
   fi

   local need_db='NO'

   if [ "${database}" = "/" ]
   then
      need_db='YES'
   else
      case ";${nodelines};" in
         *[\;\,]no-share[\,\;]*)
            need_db='YES'
         ;;
      esac
   fi

   #
   # We run through the nodelines and check if there is a match for
   # no-share, if yes, then we will need to manage a database. Else it will
   # all be kept in root, so we don't bother/pollute.
   #
   log_debug "Doing a \"${style}\" update for \"${config}\"."

   if [ "${need_db}" = 'YES' ]
   then
      # Re-evaluate stash dir from mulle-env before persisting it.
      # This prevents writing back stale values after a reset when
      # MULLE_VIRTUAL_ROOT_ID changed and runtime env still carries
      # an old expanded MULLE_SOURCETREE_STASH_DIR.
      # This can't change during a sync, so ask mulle-env only once per run.
      if [ -z "${_SOURCETREE_PERSISTED_STASH_DIR+x}" ]
      then
         local env_stash_dir

         env_stash_dir="`"${MULLE_ENV:-mulle-env}" -s environment get --output-eval MULLE_SOURCETREE_STASH_DIR 2>/dev/null`"
         _SOURCETREE_PERSISTED_STASH_DIR="${env_stash_dir:-${MULLE_SOURCETREE_STASH_DIR}}"
      fi

      sourcetree::db::set_dbtype "${database}" "${style}"
      sourcetree::db::set_update "${database}" "${configfile}"
      sourcetree::db::set_shareddir "${database}" "${_SOURCETREE_PERSISTED_STASH_DIR}"
      #
      # do a flat update first and remove what we don't have
      #
      sourcetree::db::zombify_nodes "${database}"
   fi

   local count

   r_count_lines "${nodelines}"
   count="${RVAL}"

   if [ "${OPTION_PARALLEL}" = 'YES' -a ${count} -gt 1 ]
   then
      sourcetree::action::do_actions_with_nodelines_parallel "${nodelines}" \
                                                             "${style}" \
                                                             "${config}" \
                                                             "${database}"
      rc=$?
      log_debug "Parallel share update of ${config}: ${rc}"
   else
      sourcetree::action::do_actions_with_nodelines "${nodelines}" \
                                                    "${style}" \
                                                    "${config}" \
                                                    "${database}"
      rc=$?
      log_debug "Share update of ${config}: ${rc}"
   fi

   [ $rc -eq 0 ] || return 1

   #
   # Here we should bury all the zombies, that stemmed from the 
   # flat part of our config, so that we get rid of them and don't traverse
   # an outdated database.
   #
   sourcetree::db::bury_flat_zombies "${database}"

   #
   # In the share case, we have done the flat and the recurse part already
   # Now recurse may have added stuff to our root database. These haven't been
   # recursed yet. So lets do this now. These can only be additions to
   # root, so we don't zombify.
   #
   if [ "${database}" = "/" ]
   then
      local before

      log_fluff "Process root updates additions if any"

      before="`sourcetree::db::fetch_all_nodelines "${database}" | LC_ALL=C sort`"  \
      || return 1

      sourcetree::sync::descend_db_nodelines "share" "${config}" "${database}" \
      || return 1

      while :
      do
         nodelines="`sourcetree::db::fetch_all_nodelines "${database}" | LC_ALL=C sort`" \
         || return 1

         if [ "${nodelines}" = "${before}" ]
         then
            break
         fi

         log_debug "Redo root because lines have changed"

         sourcetree::sync::descend_db_nodelines "share" "${config}" "${database}" || return 1

         before="${nodelines}"
      done
   else
      sourcetree::sync::descend_db_nodelines "share" "${config}" "${database}" || return 1
   fi

   if [ "${need_db}" = 'YES' ]
   then
      sourcetree::db::bury_zombies "${database}" &&
      sourcetree::db::clear_update "${database}" &&
      sourcetree::db::set_ready "${database}" "${configfile}"
   fi
}


sourcetree::sync::sync_share()
{
   log_walk_entry "sourcetree::sync::sync_share" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"
   local startpoint="$4"

   local UPDATED
   local rc

   sourcetree::sync::_sync_share "${config}" "${database}" "${symbol}"
   rc=$?

   if [ $rc -eq 0 ]
   then
      log_debug "UPDATED: ${UPDATED}"

      if ! find_line "${UPDATED}" "${startpoint}"
      then
         fail "\"${MULLE_VIRTUAL_ROOT}${startpoint}\" is not reachable from \
the sourcetree root (${MULLE_VIRTUAL_ROOT})"
      fi
   else
      log_debug "sourcetree sync of ${config} failed ($rc)"
   fi
   return $rc
}


####
# RECURSE UPDATE
####

sourcetree::sync::_style_for_recurse()
{
   local rc="$1"

   _style="recurse"

   case $rc in
      0)
         return 0
      ;;
   esac
   return 1
}


#
# config     : config relative to MULLE_VIRTUAL_ROOT
# database   : prefix relative to MULLE_VIRTUAL_ROOT
# symbol     : suffix to resolve SOURCETREE_CONFIG_NAME
#
sourcetree::sync::_sync_recurse()
{
   log_walk_entry "sourcetree::sync::_sync_recurse" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"

   local style

   style="recurse"

   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database then just bail
   #
   local nodelines
   local rc

   nodelines="`sourcetree::walk::cfg_read "${symbol}" "${config}"`"
   rc=$?

   if [ $rc -eq 2 ]
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      if ! sourcetree::db::dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\""
         return 127
      fi
   fi

   log_debug "Doing a \"${style}\" update for \"${config}\"."

   sourcetree::db::set_dbtype "${database}" "${style}"
   sourcetree::db::set_update "${database}" "${configfile}"

   sourcetree::db::clear_shareddir "${database}"

   # zombify everything
   sourcetree::db::zombify_nodes "${database}"

   local count

   r_count_lines "${nodelines}"
   count="${RVAL}"

   if [ "${OPTION_PARALLEL}" = 'YES' -a ${count} -gt 1 ]
   then
      sourcetree::action::do_actions_with_nodelines_parallel "${nodelines}" \
                                                             "${style}" \
                                                             "${config}" \
                                                             "${database}"
      rc=$?
      log_debug "Parallel recurse update of ${config}: ${rc}"
   else
      sourcetree::action::do_actions_with_nodelines "${nodelines}" \
                                                    "${style}" \
                                                    "${config}" \
                                                    "${database}"
      rc=$?
      log_debug "Recurse update of ${config}: ${rc}"
   fi

   [ $rc -eq 0 ] || return 1

   sourcetree::db::bury_zombie_nodelines "${database}" "${nodelines}" || return 1

   # until now, it was just like flat. Now recurse through nodelines.

   sourcetree::sync::descend_db_nodelines "recurse" "${config}" "${database}"  || return 1

   # bury rest of zombies
   sourcetree::db::bury_zombies "${database}" &&
   sourcetree::db::clear_update "${database}" &&
   sourcetree::db::set_ready "${database}" "${configfile}"
}


sourcetree::sync::sync_recurse()
{
   log_walk_entry "sourcetree::sync::sync_recurse" "$@"

  local config="$1"
  local database="$2"
  local symbol="$3"
#  local startpoint="$4"

   sourcetree::sync::_sync_recurse "${config}" "${database}" "${symbol}"
}


####
# FLAT UPDATE
####
#
# config     : config relative to MULLE_VIRTUAL_ROOT
# database   : prefix relative to MULLE_VIRTUAL_ROOT
#
sourcetree::sync::_sync_flat()
{
   log_walk_entry "sourcetree::sync::_sync_flat" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"

   local style

   style="flat"

   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database then just bail. We remember the actual
   # config that was used, to make it easier to debug symlink problems later
   #

   local nodelines
   local rc

   nodelines="`sourcetree::walk::cfg_read "${symbol}" "${config}"`"
   rc=$?

   if [ $rc -eq 2 ]
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      if ! sourcetree::db::dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\""
         return 127
      fi
   fi

   log_debug "Doing a \"${style}\" update for \"${config}\"."

   sourcetree::db::set_dbtype "${database}" "${style}"
   sourcetree::db::set_update "${database}" "${configfile}"

   sourcetree::db::clear_shareddir "${database}"
   sourcetree::db::zombify_nodes "${database}"

   local count

   r_count_lines "${nodelines}"
   count="${RVAL}"

   if [ "${OPTION_PARALLEL}" = 'YES' -a ${count} -gt 1 ]
   then
      sourcetree::action::do_actions_with_nodelines_parallel "${nodelines}" "${style}" "${config}" "${database}"
      rc=$?
      log_debug "Parallel flat update of ${config}: ${rc}"
   else
      sourcetree::action::do_actions_with_nodelines "${nodelines}" "${style}" "${config}" "${database}"
      rc=$?
      log_debug "Flat update of ${config}: ${rc}"
   fi
   [ $rc -eq 0 ] || return 1

   sourcetree::db::bury_zombies "${database}" &&
   sourcetree::db::clear_update "${database}" &&
   sourcetree::db::set_ready "${database}" "${configfile}"
}


sourcetree::sync::sync_flat()
{
   log_walk_entry "sourcetree::sync::sync_flat" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"
#   local startpoint="$4"

   sourcetree::sync::_sync_flat "${config}" "${database}" "${symbol}"
}


sourcetree::sync::write_cachedir_tag()
{
   log_walk_entry "sourcetree::sync::write_cachedir_tag" "$@"

   local stashdir="$1"

   [ "${MULLE_CACHEDIR_TAG}" != 'YES' ] && return

   # assume one stat is faster than open/write/close
   [ ! -d "${stashdir}" ] || [ -f "${stashdir}/CACHEDIR.TAG" ] && return

   redirect_exekutor "${stashdir}/CACHEDIR.TAG" printf "%s\n" "\
Signature: 8a477f597d28d172789f06886806bc55

This file is a cache directory tag created by mulle-sourcetree.
If you use \`tar --exclude-caches-all\`, this directory will be excluded from
your archive.

You can suppress the generation of this file with:
   mulle-sde env --global set MULLE_CACHEDIR_TAG NO
"
}


####
# QUICK
####
#
# "sync --quick" skips the whole sync, if nothing relevant changed since the
# last successful sync. A stamp file ".db_quick" in the start database
# contains these lines:
#
#   E <name>=<value> : environment fingerprint, compared as a whole
#   U <name>=<value> : user variable referenced in a config file
#   C <file>         : config file that was read, must not be newer than ref
#   N <file>         : config file that was absent, must still be absent
#   D <file>         : memorized destination, must still exist
#   R <dir>          : memorized destination that is descended into, must
#                      still exist (and must have C/N lines for its config)
#
# ".db_quick_ref" is created at the start of a sync, its mtime is the
# reference for "C" files. During sync the C/N/D/M lines are appended to
# ".db_quick_log" (with builtins, so it works in parallel subshells).
# An "M" line (missing, not required node) prevents writing a stamp.
#
sourcetree::sync::r_quick_names()
{
   local names

   if [ ${ZSH_VERSION+x} ]
   then
      eval 'names=( ${(o)${(k)parameters[(I)MULLE_SOURCETREE_*]}}
                    ${(o)${(k)parameters[(I)SOURCETREE_*]}}
                    ${(o)${(k)parameters[(I)MULLE_FETCH_*]}}
                    ${(o)${(k)parameters[(I)OPTION_FETCH_*]}} )'
   else
      eval 'names=( ${!MULLE_SOURCETREE_@}
                    ${!SOURCETREE_@}
                    ${!MULLE_FETCH_@}
                    ${!OPTION_FETCH_@} )'
   fi

   names+=( MULLE_UNAME
            MULLE_CRAFT_PLATFORMS
            MULLE_VIRTUAL_ROOT
            OPTION_OVERRIDE_BRANCH
            OPTION_FIX
            OPTION_LENIENT )

   local name
   local result

   for name in "${names[@]}"
   do
      case "${name}" in
         # module include guards differ depending on what's loaded
         *_SH)
            continue
         ;;
      esac
      result="${result}${name}
"
   done

   RVAL="${result}"
}


sourcetree::sync::r_quick_value_line()
{
   local prefix="$1"
   local name="$2"

   r_shell_indirect_expand "${name}"
   # keep it to one line
   RVAL="${prefix} ${name}=${RVAL//$'\n'/\\n}"
}


sourcetree::sync::r_quick_fingerprint()
{
   log_entry "sourcetree::sync::r_quick_fingerprint" "$@"

   local name
   local result

   sourcetree::sync::r_quick_names

   .foreachline name in ${RVAL}
   .do
      sourcetree::sync::r_quick_value_line "E" "${name}"
      result="${result}${RVAL}
"
   .done

   RVAL="${result}"
}


#
# collect names of ${VARIABLE} references in a text
#
sourcetree::sync::r_add_referenced_variables()
{
   local names="$1"
   local s="$2"

   local name
   local nl=$'\n'

   while :
   do
      case "${s}" in
         *'${'*)
         ;;

         *)
            break
         ;;
      esac

      s="${s#*\$\{}"
      name="${s%%[!A-Za-z0-9_]*}"

      case "${name}" in
         ""|MULLE_TAG|MULLE_BRANCH|MULLE_URL|MULLE_TAG_OR_BRANCH)
            # these are computed during sync
            continue
         ;;
      esac

      # case is much faster than find_line in zsh
      case "${nl}${names}${nl}" in
         *"${nl}${name}${nl}"*)
         ;;

         *)
            names="${names:+${names}${nl}}${name}"
         ;;
      esac
   done

   RVAL="${names}"
}


sourcetree::sync::quick_is_uptodate()
{
   log_entry "sourcetree::sync::quick_is_uptodate" "$@"

   local database="$1"
   local fingerprint="$2"

   local _database
   local _databasedir

   sourcetree::db::__common_databasedir "${database}"

   local stamp="${_databasedir}/.db_quick"
   local ref="${_databasedir}/.db_quick_ref"

   if [ ! -f "${stamp}" -o ! -f "${ref}" ]
   then
      log_fluff "No quick stamp, need to sync"
      return 1
   fi

   if sourcetree::db::is_updating "${database}" || ! sourcetree::db::is_ready "${database}"
   then
      log_fluff "Database not ready, need to sync"
      return 1
   fi

   local line
   local filepath
   local name
   local value
   local env
   local stamptext

   # $(<file) is much faster than `read` in zsh
   stamptext="$(<"${stamp}")"

   .foreachline line in ${stamptext}
   .do
      filepath="${line:2}"

      case "${line}" in
         E\ *)
            env="${env}${line}
"
         ;;

         U\ *)
            name="${filepath%%=*}"
            sourcetree::sync::r_quick_value_line "U" "${name}"
            if [ "${RVAL}" != "${line}" ]
            then
               log_fluff "Variable \"${name}\" changed, need to sync"
               return 1
            fi
         ;;

         C\ *)
            if [ ! -f "${filepath}" ] || [ "${filepath}" -nt "${ref}" ]
            then
               log_fluff "Config \"${filepath}\" changed, need to sync"
               return 1
            fi
         ;;

         N\ *)
            if [ -e "${filepath}" ]
            then
               log_fluff "Config \"${filepath}\" appeared, need to sync"
               return 1
            fi
         ;;

         D\ *|R\ *)
            if [ ! -e "${filepath}" ]
            then
               log_fluff "Destination \"${filepath}\" is gone, need to sync"
               return 1
            fi
         ;;
      esac
   .done

   if [ "${env}" != "${fingerprint}" ]
   then
      log_fluff "Environment changed, need to sync"
      log_debug "old: ${env}"
      log_debug "new: ${fingerprint}"
      return 1
   fi

   return 0
}


sourcetree::sync::quick_begin()
{
   log_entry "sourcetree::sync::quick_begin" "$@"

   local database="$1"

   local _database
   local _databasedir

   sourcetree::db::__common_databasedir "${database}"

   mkdir_if_missing "${_databasedir}"

   # invalidate old stamp first, so a failed sync leaves none
   remove_file_if_present "${_databasedir}/.db_quick"

   _SOURCETREE_QUICK_LOG="${_databasedir}/.db_quick_log"

   # builtin truncation/creation, mtime of ref is our reference
   : > "${_SOURCETREE_QUICK_LOG}" || _SOURCETREE_QUICK_LOG=""
   : > "${_databasedir}/.db_quick_ref"
}


sourcetree::sync::quick_end()
{
   log_entry "sourcetree::sync::quick_end" "$@"

   local database="$1"
   local fingerprint="$2"
   local rc="$3"

   local logfile="${_SOURCETREE_QUICK_LOG}"

   _SOURCETREE_QUICK_LOG=""

   [ -z "${logfile}" ] && return

   local _database
   local _databasedir

   sourcetree::db::__common_databasedir "${database}"

   local stamp="${_databasedir}/.db_quick"
   local ref="${_databasedir}/.db_quick_ref"

   # if sync failed or the db was reset during the sync, write no stamp
   if [ "${rc}" -ne 0 ] || [ ! -f "${logfile}" -o ! -f "${ref}" ]
   then
      remove_file_if_present "${logfile}"
      return
   fi

   local line
   local lines
   local names
   local logtext
   local nl=$'\n'

   # $(<file) is much faster than `read` in zsh
   logtext="$(<"${logfile}")"

   .foreachline line in ${logtext}
   .do
      # dedupe, case is much faster than find_line in zsh
      case "${nl}${lines}${nl}" in
         *"${nl}${line}${nl}"*)
            .continue
         ;;
      esac

      case "${line}" in
         M\ *)
            log_fluff "Not all nodes were fetched, so no quick stamp"
            remove_file_if_present "${logfile}"
            return
         ;;

         C\ *)
            # collect ${VARIABLE} references
            sourcetree::sync::r_add_referenced_variables "${names}" "$(<"${line:2}")"
            names="${RVAL}"
         ;;
      esac

      lines="${lines:+${lines}${nl}}${line}"
   .done

   local name
   local uservars
   local rpath

   #
   # every directory we could descend into, must have been checked for a
   # config. If not (e.g. it was fetched during this sync and not descended
   # yet), don't write a stamp. The next sync will be complete. In flat mode
   # nothing is descended.
   #
   if [ "${SOURCETREE_MODE}" != 'flat' ]
   then
      .foreachline line in ${lines}
      .do
         case "${line}" in
            R\ *)
               rpath="${line:2}"
               case "${lines}" in
                  *"C ${rpath}/"*|*"N ${rpath}/"*)
                  ;;

                  *)
                     log_fluff "\"${rpath}\" was not descended, so no quick stamp"
                     remove_file_if_present "${logfile}"
                     return
                  ;;
               esac
            ;;
         esac
      .done
   fi

   .foreachline name in ${names}
   .do
      sourcetree::sync::r_quick_value_line "U" "${name}"
      uservars="${uservars}${RVAL}
"
   .done

   printf "%s%s%s\n" "${fingerprint}" "${uservars}" "${lines}" > "${stamp}"
   remove_file_if_present "${logfile}"

   log_fluff "Wrote quick stamp \"${stamp}\""
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
#            marked no-share like in recurse. The shares are stored in root.
#
sourcetree::sync::start()
{
   log_walk_entry "sourcetree::sync::start" "$@" "(${PWD#"${MULLE_USER_PWD}/"})"

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

   sourcetree::db::ensure_consistency "${SOURCETREE_START}"
   sourcetree::db::ensure_compatible_dbtype "${SOURCETREE_START}" "${style}"

   #
   # quick check: skip everything if nothing changed since last sync
   # the fingerprint is computed here, so it sees the same state as the
   # next run will
   #
   local quick_fingerprint
   local _SOURCETREE_QUICK_LOG

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != 'YES' ]
   then
      sourcetree::sync::r_quick_fingerprint
      quick_fingerprint="${RVAL}"

      if [ "${OPTION_QUICK}" = 'YES' -a "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' ] &&
         sourcetree::sync::quick_is_uptodate "${SOURCETREE_START}" "${quick_fingerprint}"
      then
         log_verbose "Sourcetree is unchanged since last sync (--quick)"
         return 0
      fi

      sourcetree::sync::quick_begin "${SOURCETREE_START}"
   fi

   local rc

   sourcetree::sync::sync_${style} \
                          "${SOURCETREE_START}" \
                          "${SOURCETREE_START}" \
                          "" \
                          "${startpoint}"
   rc=$?

   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" != 'YES' ]
   then
      sourcetree::sync::quick_end "${SOURCETREE_START}" "${quick_fingerprint}" "${rc}"
   fi

   # this is checked by 17-minions
   if [ $rc -eq 127 -a "${OPTION_LENIENT}" = 'YES' ]
   then
      # it's OK we can live with that
      log_verbose "There is no sourcetree here (\"${SOURCETREE_CONFIG_DIR}\"), but that's OK"
      return 0
   fi

   sourcetree::sync::write_cachedir_tag "${MULLE_SOURCETREE_STASH_DIR:-stash}"

   return $rc
}


sourcetree::sync::warn_dry_run()
{
   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      _log_warning "***IMPORTANT REMINDER***

As fetches and zombification are not performed during a dry run (-n), the
actual commands of an update can not be shown. This is especially true for
recurse and share updates. And when updating an existing database, when
edits have been made to the configuration.
"
   fi
}


sourcetree::sync::main()
{
   log_walk_entry "sourcetree::sync::main" "$@"

   local OPTION_FIX='DEFAULT'
   local OPTION_OVERRIDE_BRANCH

   local OPTION_FETCH_SEARCH_PATH
   local OPTION_FETCH_CACHE_DIR
   local OPTION_FETCH_MIRROR_DIR

   local OPTION_FETCH_REFRESH='DEFAULT'
   local OPTION_FETCH_SYMLINK='DEFAULT'
   local OPTION_FETCH_ABSOLUTE_SYMLINK='DEFAULT'
   local OPTION_LENIENT='YES'
   local OPTION_QUICK='NO'
   local OPTION_PARALLEL='YES'

   # default is YES, but environment can override
   MULLE_SOURCETREE_RESOLVE_TAG="${MULLE_SOURCETREE_RESOLVE_TAG:-YES}"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::sync::usage
         ;;

         #
         # stuff passed to mulle-fetch
         #
         --lenient)
            OPTION_LENIENT='YES'
         ;;

         --no-lenient)
            OPTION_LENIENT='NO'
         ;;

         --quick|--quick-check)
            OPTION_QUICK='YES'
         ;;

         --no-quick|--no-quick-check)
            OPTION_QUICK='NO'
         ;;

         --cache-refresh|--refresh|--mirror-refresh)
            OPTION_FETCH_REFRESH='YES'
         ;;

         --no-cache-refresh|--no-refresh|--no-mirror-refresh)
            OPTION_FETCH_REFRESH='NO'
         ;;

         --parallel)
            OPTION_PARALLEL='YES'
         ;;

         --no-parallel|--serial)
            OPTION_PARALLEL='NO'
         ;;

         --copy|--symlink-copy)
            OPTION_FETCH_SYMLINK='COPY'
         ;;

         --symlink|--symlinks)
            OPTION_FETCH_SYMLINK='YES'
         ;;

         --no-symlink|--no-symlinks)
            OPTION_FETCH_SYMLINK='NO'
         ;;

         --absolute-symlink)
            OPTION_FETCH_SYMLINK='YES'
            OPTION_FETCH_ABSOLUTE_SYMLINK='YES'
         ;;

         --no-absolute-symlinks)
            OPTION_FETCH_ABSOLUTE_SYMLINK='NO'
         ;;

         --resolve-tag)
            MULLE_SOURCETREE_RESOLVE_TAG='YES'
         ;;

         --no-fixup)
            MULLE_SOURCETREE_RESOLVE_TAG='NO'
         ;;

         --cache-dir)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_FETCH_CACHE_DIR="$1"
         ;;

         --mirror-dir)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_FETCH_MIRROR_DIR="$1"
         ;;

         -l|--search-path|--local-search-path|--locals-search-path)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_FETCH_SEARCH_PATH="$1"
         ;;


         #
         # update options
         #
         --override-branch)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_OVERRIDE_BRANCH="$1"
         ;;

         --fixup)
            OPTION_FIX='NO'
         ;;

         --no-fixup)
            OPTION_FIX='YES'
         ;;

         #
         # more common flags
         #
         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown sync option $1"
            sourcetree::sync::usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   MULLE_FETCH="${MULLE_FETCH:-`command -v mulle-fetch`}"
   [ -z "${MULLE_FETCH}" ] && fail "mulle-fetch not installed"

   [ -z "${DEFAULT_IFS}" ] && _internal_fail "IFS fail"

   sourcetree::sync::warn_dry_run

   sourcetree::sync::start
}


sourcetree::sync::initialize()
{
   log_walk_entry "sourcetree::sync::initialize" "$@"

   include "string"
   include "sourcetree::action"
}


sourcetree::sync::initialize

:
