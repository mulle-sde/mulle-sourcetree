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
MULLE_SOURCETREE_SYNC_SH="included"


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
   --quick-check              : if present in filesystem assume node is OK
   --no-fix                   : do not write ${SOURCETREE_FIX_FILENAME} files
   --share                    : create database in shared configuration
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
sourcetree::sync::_get_db_descendinfo()
{
   log_entry "sourcetree::sync::_get_db_descendinfo" "$@"

   local database="$1"
   local address="$2"
   local uuid="$3"

   _filename="`sourcetree::db::fetch_filename_for_uuid "${database}" "${uuid}" `"

   [ -z "${_filename}" ] && _internal_fail "corrupted db, better clean it"

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
sourcetree::sync::_get_config_descendinfo()
{
   log_entry "sourcetree::sync::_get_config_descendinfo" "$@"

   local config="$1"
   local address="$2"

   r_filepath_concat "${config}" "${address}"
   _config="${RVAL}"

   _filename="${_config}"
   if ! is_absolutepath "${_config}"
   then
      r_filepath_concat  "${MULLE_VIRTUAL_ROOT}" "${_config}"
      _filename="${RVAL}"
   fi

   _config="${_config}/"
   _database="${_config}"

   sourcetree::walk::r_symbol_for_address "SOURCETREE_CONFIG_NAME" "${address}"
   _symbol="${RVAL}"
}


# rval: 0 recurse
#     : 1 don't recurse
#     : 4 symlink
#
# input: parsed nodeline + filename
sourcetree::sync::_check_descend_nodeline()
{
   log_entry "sourcetree::sync::_check_descend_nodeline" "$@"

   local filename="$1"
   local marks="$2"

   if sourcetree::nodemarks::disable "${marks}" "descend"
   then
      log_fluff "Node \"${filename}\" is marked no-descend"
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
      log_fluff "\"${filename}\" is a symlink, so don't descend"
      return 4
   fi

   if [ ! -d "${filename}" ]
   then
      if [ -e "${filename}" ]
      then
         _log_fluff "Will not recursively update \"${filename}\" as it's not \
a directory"
         return 1
      fi

      if sourcetree::nodemarks::enable "${marks}" "share"
      then
         log_fluff "Destination \"${filename}\" does not exist."
      else
         log_verbose "Destination \"${filename}\" does not exist, possibly unexpectedly."
      fi

      return 1
   fi

   log_debug "Recurse as it's a directory"
   return 0
}


sourcetree::sync::_descend_db_nodeline()
{
   log_entry "sourcetree::sync::_descend_db_nodeline" "$@"

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

   sourcetree::sync::_get_db_descendinfo "${database}" "${_address}" "${_uuid}"

   # remove duplicate marker from _filename
   _filename="${_filename%#*}"

   log_setting "MULLE_VIRTUAL_ROOT : ${MULLE_VIRTUAL_ROOT}"
   log_setting "config             : ${config}"
   log_setting "database           : ${database}"
   log_setting "filename           : ${_filename}"
   log_setting "newconfig          : ${_config}"
   log_setting "newdatabase        : ${_database}"
   log_setting "symbol             : ${_symbol}"

   local _style
   local rval

   sourcetree::sync::_check_descend_nodeline "${_filename}" "${_marks}"
   rval=$?

   if sourcetree::sync::_style_for_${style} ${rval}
   then
      sourcetree::sync::_sync_${_style} "${_config}" "${_database}" "${_symbol}"
      return $?
   fi
}


sourcetree::sync::_descend_config_nodeline()
{
   log_entry "sourcetree::sync::_descend_config_nodeline" "$@"

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

   sourcetree::sync::_get_config_descendinfo "${config}" "${_address}"

   log_setting "MULLE_VIRTUAL_ROOT : ${MULLE_VIRTUAL_ROOT}"
   log_setting "config             : ${config}"
   log_setting "database           : ${database}"
   log_setting "filename           : ${_filename}"
   log_setting "newconfig          : ${_config}"
   log_setting "newdatabase        : ${_database}"
   log_setting "symbol             : ${_symbol}"

   sourcetree::sync::_check_descend_nodeline "${_filename}"

   [ $? -ne 0 ] && return 1

   sourcetree::sync::_sync_${style} "${_config}" "${_database}" "${_symbol}"
}


#
# A flat update has run. Now walk over the DB entries (actually existing
# stuff at proper position) and recursively do the inferior sourcetrees
#
sourcetree::sync::_descend_db_nodelines()
{
   log_entry "sourcetree::sync::_descend_db_nodelines" "$@"

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

   shell_disable_glob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      if [ -z "${nodeline}" ]
      then
         continue
      fi

      # needed for root database only
      if [ "${database}" = "/" ]
      then
         if find_line "${VISITED}" "${nodeline}"
         then
            continue
         fi
         r_add_line "${VISITED}" "${nodeline}"
         VISITED="${RVAL}"
      fi

      sourcetree::sync::_descend_db_nodeline "${nodeline}" "${style}" "${config}" "${database}"
      rval=$?

      # 127 is not really an error in a descendant 
      if [ $rval -ne 0 -a $rval -ne 127 ]
      then
         return $rval
      fi
   done

   IFS="${DEFAULT_IFS}" ; shell_enable_glob
}



#
# A flat update has run. Now walk over the DB entries (actually existing
# stuff at proper position) and recursively do the inferior sourcetrees
#
sourcetree::sync::_descend_config_nodelines()
{
   log_entry "sourcetree::sync::_descend_config_nodelines" "$@"

   local style="$1"; shift

   local config="$1"
   local database="$2"
   local symbol="$3"

   local nodelines

   nodelines="`sourcetree::walk::cfg_read "${symbol}" "${config}" `"
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
            log_fluff "\${nodeline}\" was already visited"
            .continue
         fi
         r_add_line "${VISITED}" "${nodeline}"
         VISITED="${RVAL}"
      fi

      sourcetree::sync::_descend_config_nodeline "${nodeline}" "${style}" "${config}" "${database}"
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
   local rval="$1"

   _style="only_share"

   case $rval in
      0|4)
         return 0
      ;;
   esac
   return 1
}


sourcetree::sync::_nodeline_sync_only_share()
{
   log_entry "sourcetree::sync::_nodeline_sync_only_share" "$@"

   local nodeline="$1"
   local config="$2"
   local database="$3"

   [ "$#" -ne 3 ]     && _internal_fail "api error"
   [ -z "$style" ]    && _internal_fail "style is empty"
   [ -z "$nodeline" ] && _internal_fail "nodeline is empty"

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

   sourcetree::nodeline::parse "${nodeline}" # !!!

   if [ ! -z "${_url}" ] && sourcetree::nodemarks::enable "${_marks}" "share"
   then
      sourcetree::action::do_actions_with_nodeline "${nodeline}" "share" "${config}" "${database}"
      return $?
   fi
}


sourcetree::sync::_sync_only_share()
{
   log_entry "sourcetree::sync::_sync_only_share" "$@"

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

   shell_disable_glob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      if [ -z "${nodeline}" ]
      then
         continue
      fi

      # needed for root database only
      if [ "${database}" = "/" ]
      then
         if find_line "${VISITED}" "${nodeline}"
         then
            continue
         fi

         r_add_line "${VISITED}" "${nodeline}"
         VISITED="${RVAL}"
      fi

      sourcetree::sync::_nodeline_sync_only_share "${nodeline}" "${config}" "${database}"
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   log_fluff "Doing a \"${style}\" update for \"${config}\"."

   sourcetree::sync::_descend_config_nodelines "only_share" "${config}" "${database}" "${symbol}" || return 1
}


sourcetree::sync::sync_only_share()
{
   log_entry "sourcetree::sync::sync_only_share" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"
   local startpoint="$4"

   local UPDATED
   local rval

   sourcetree::sync::_sync_only_share "${config}" "${database}" "${symbol}"
   rval=$?

   if [ $rval -eq 0 ]
   then
      log_debug "UPDATED: ${UPDATED}"

      if ! find_line "${UPDATED}" "${startpoint}"
      then
         fail "\"${MULLE_VIRTUAL_ROOT}${startpoint}\" is not reachable from \
the sourcetree root (${MULLE_VIRTUAL_ROOT})"
      fi
   else
      log_debug "sourcetree sync of ${config} failed ($rval)"
   fi
   return $rval
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
   local rval="$1"

   _style="share"

   case $rval in
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
   log_entry "sourcetree::sync::_sync_share" "$@"

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
   if ! sourcetree::walk::r_configfile "${symbol}" "${config}"
   then
      log_debug "There is no sourcetree configuration in \"${config}\""

      if [ "${database}" = '/' ]
      then
         log_debug "It's the root \"${database}\" so nothing more to do."
         sourcetree::db::clear_update "${database}"
         sourcetree::db::set_ready "${database}"
         return 127
      fi

      if ! sourcetree::db::dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\" so nothing to do."
         return 127
      fi
   fi

   local configfile

   configfile="${RVAL}"

   local nodelines

   nodelines="`sourcetree::cfg::_read "${configfile}" `"

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
   log_fluff "Doing a \"${style}\" update for \"${config}\"."

   if [ "${need_db}" = 'YES' ]
   then
      sourcetree::db::set_dbtype "${database}" "${style}"
      sourcetree::db::set_update "${database}" "${configfile}"
      sourcetree::db::set_shareddir "${database}" "${MULLE_SOURCETREE_STASH_DIR}"
      #
      # do a flat update first and remove what we don't have
      #
      sourcetree::db::zombify_nodes "${database}"
   fi

   local count
   local rval

   r_count_lines "${nodelines}"
   count="${RVAL}"

   if [ "${OPTION_PARALLEL}" = 'YES' -a ${count} -gt 1 ]
   then
      sourcetree::action::do_actions_with_nodelines_parallel "${nodelines}" "${style}" "${config}" "${database}"
      rval=$?
      log_debug "Parallel share update of ${config}: ${rval}"
   else
      sourcetree::action::do_actions_with_nodelines "${nodelines}" "${style}" "${config}" "${database}"
      rval=$?
      log_debug "Share update of ${config}: ${rval}"
   fi

   [ $rval -eq 0 ] || return 1

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

      sourcetree::sync::_descend_db_nodelines "share" "${config}" "${database}" \
      || return 1

      while :
      do
         nodelines="`sourcetree::db::fetch_all_nodelines "${database}" | LC_ALL=C sort`" \
         || exit 1

         if [ "${nodelines}" = "${before}" ]
         then
            break
         fi

         log_debug "Redo root because lines have changed"

         sourcetree::sync::_descend_db_nodelines "share" "${config}" "${database}" || return 1

         before="${nodelines}"
      done
   else
      sourcetree::sync::_descend_db_nodelines "share" "${config}" "${database}" || return 1
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
   log_entry "sourcetree::sync::sync_share" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"
   local startpoint="$4"

   local UPDATED
   local rval

   sourcetree::sync::_sync_share "${config}" "${database}" "${symbol}"
   rval=$?

   if [ $rval -eq 0 ]
   then
      log_debug "UPDATED: ${UPDATED}"

      if ! find_line "${UPDATED}" "${startpoint}"
      then
         fail "\"${MULLE_VIRTUAL_ROOT}${startpoint}\" is not reachable from \
the sourcetree root (${MULLE_VIRTUAL_ROOT})"
      fi
   else
      log_debug "sourcetree sync of ${config} failed ($rval)"
   fi
   return $rval
}


####
# RECURSE UPDATE
####

sourcetree::sync::_style_for_recurse()
{
   local rval="$1"

   _style="recurse"

   case $rval in
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
   log_entry "sourcetree::sync::_sync_recurse" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"

   local style

   style="recurse"

   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database then just bail
   #
   if ! sourcetree::walk::r_configfile "${symbol}" "${config}"
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      if ! sourcetree::db::dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\""
         return 127
      fi
   fi

   local configfile

   configfile="${RVAL}"

   local nodelines

   nodelines="`sourcetree::cfg::_read "${configfile}" `"

   log_fluff "Doing a \"${style}\" update for \"${config}\"."

   sourcetree::db::set_dbtype "${database}" "${style}"
   sourcetree::db::set_update "${database}" "${configfile}"

   sourcetree::db::clear_shareddir "${database}"

   # zombify everything
   sourcetree::db::zombify_nodes "${database}"

   local count
   local rval

   r_count_lines "${nodelines}"
   count="${RVAL}"

   if [ "${OPTION_PARALLEL}" = 'YES' -a ${count} -gt 1 ]
   then
      sourcetree::action::do_actions_with_nodelines_parallel "${nodelines}" \
                                                             "${style}" \
                                                             "${config}" \
                                                             "${database}"
      rval=$?
      log_debug "Parallel recurse update of ${config}: ${rval}"
   else
      sourcetree::action::do_actions_with_nodelines "${nodelines}" \
                                                    "${style}" \
                                                    "${config}" \
                                                    "${database}"
      rval=$?
      log_debug "Recurse update of ${config}: ${rval}"
   fi

   [ $rval -eq 0 ] || return 1

   sourcetree::db::bury_zombie_nodelines "${database}" "${nodelines}" || return 1

   # until now, it was just like flat. Now recurse through nodelines.

   sourcetree::sync::_descend_db_nodelines "recurse" "${config}" "${database}"  || return 1

   # bury rest of zombies
   sourcetree::db::bury_zombies "${database}" &&
   sourcetree::db::clear_update "${database}" &&
   sourcetree::db::set_ready "${database}" "${configfile}"
}


sourcetree::sync::sync_recurse()
{
   log_entry "sourcetree::sync::sync_recurse" "$@"

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
   log_entry "sourcetree::sync::_sync_flat" "$@"

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
   if ! sourcetree::walk::r_configfile "${symbol}" "${config}"
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      if ! sourcetree::db::dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\""
         return 127
      fi
   fi

   local configfile

   configfile="${RVAL}"

   local nodelines

   nodelines="`sourcetree::cfg::__read`"

   log_fluff "Doing a \"${style}\" update for \"${config}\"."

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
      rval=$?
      log_debug "Parallel flat update of ${config}: ${rval}"
   else
      sourcetree::action::do_actions_with_nodelines "${nodelines}" "${style}" "${config}" "${database}"
      rval=$?
      log_debug "Flat update of ${config}: ${rval}"
   fi
   [ $rval -eq 0 ] || return 1

   sourcetree::db::bury_zombies "${database}" &&
   sourcetree::db::clear_update "${database}" &&
   sourcetree::db::set_ready "${database}" "${configfile}"
}


sourcetree::sync::sync_flat()
{
   log_entry "sourcetree::sync::sync_flat" "$@"

   local config="$1"
   local database="$2"
   local symbol="$3"
#   local startpoint="$4"

   sourcetree::sync::_sync_flat "${config}" "${database}" "${symbol}"
}


sourcetree::sync::write_cachedir_tag()
{
   log_entry "sourcetree::sync::write_cachedir_tag" "$@"

   local stashdir="$1"

   [ "${MULLE_CACHEDIR_TAG}" != "YES" ] && return

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
   log_entry "sourcetree::sync::start" "$@" "(${PWD#"${MULLE_USER_PWD}/"})"

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

   local rval


   include "sourcetree::walk"

   sourcetree::sync::sync_${style} \
                          "${SOURCETREE_START}" \
                          "${SOURCETREE_START}" \
                          "" \
                          "${startpoint}"
   rval=$?

   # this is checked by 17-minions
   if [ $rval -eq 127 -a "${OPTION_LENIENT}" = 'YES' ]
   then
      # it's OK we can live with that
      log_verbose "There is no sourcetree here (\"${SOURCETREE_CONFIG_DIR}\"), but that's OK"
      return 0
   fi

   sourcetree::sync::write_cachedir_tag "${MULLE_SOURCETREE_STASH_DIR:-stash}"

   return $rval
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
   log_entry "sourcetree::sync::main" "$@"

   local OPTION_FIX="DEFAULT"
   local OPTION_OVERRIDE_BRANCH

   local OPTION_FETCH_SEARCH_PATH
   local OPTION_FETCH_CACHE_DIR
   local OPTION_FETCH_MIRROR_DIR

   local OPTION_FETCH_REFRESH="DEFAULT"
   local OPTION_FETCH_SYMLINK="DEFAULT"
   local OPTION_FETCH_ABSOLUTE_SYMLINK="DEFAULT"
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

         --quick)
            OPTION_QUICK='YES'
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
   log_entry "sourcetree::sync::initialize" "$@"

   if [ -z "${MULLE_STRING_SH}" ]
   then
      # shellcheck source=mulle-string.sh
      . "${MULLE_BASHFUNTCIONS_LIBEXEC_DIR}/mulle-string.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_ACTION_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-action.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-action.sh" || exit 1
   fi
}


sourcetree::sync::initialize

:
