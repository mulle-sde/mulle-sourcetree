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
MULLE_SOURCETREE_SYNC_SH="included"


sourcetree_sync_usage()
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
        mulle-sourctree mark Foundation no-require-darwin

Options:
   -r                         : sync recursively
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
_get_db_descendinfo()
{
   log_entry "_get_db_descendinfo" "$@"

   local database="$1"
   local uuid="$2"

   _filename="`db_fetch_filename_for_uuid "${database}" "${uuid}" `"

   [ -z "${_filename}" ] && internal_fail "corrupted db, better clean it"

   _config="${_filename#${MULLE_VIRTUAL_ROOT}}"
   _config="${_config}/"
   _database="${_config}"
}

#
# local _config
# local _filename
# local _database
#
_get_config_descendinfo()
{
   log_entry "_get_config_descendinfo" "$@"

   local config="$1"
   local address="$2"

   r_filepath_concat "${config}" "${address}"
   _config="${RVAL}"
   r_filepath_concat  "${MULLE_VIRTUAL_ROOT}" "${_config}"
   _filename="${RVAL}"

   _config="${_config}/"
   _database="${_config}"
}


# rval: 0 recurse
#     : 1 don't recurse
#     : 4 symlink
#
# input: parsed nodeline + filename
_check_descend_nodeline()
{
   log_entry "_check_descend_nodeline" "$@"

   local filename="$1"
   local marks="$2"

   if nodemarks_disable "${marks}" "descend"
   then
      log_fluff "Node \"${filename}\" is marked no-descend"
      return 1
   fi

   #
   # usually database is in config, except when we update with share
   # and the node is shared. But this switch is not done here
   # but in do_actions_with_nodeline
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
         log_fluff "Will not recursively update \"${filename}\" as it's not \
a directory"
         return 1
      fi

      if nodemarks_enable "${marks}" "share"
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


_descend_db_nodeline()
{
   log_entry "_descend_db_nodeline" "$@"

   [ "$#" -ne 4 ] && internal_fail "api error"

   local nodeline="$1"; shift
   local style="$1"; shift

   local config="$1"
   local database="$2"

   [ -z "${nodeline}" ]   && internal_fail "nodeline is empty"
   [ -z "${style}" ]      && internal_fail "style is empty"

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

   nodeline_parse "${nodeline}"  # ??

   local _filename
   local _config
   local _database

   _get_db_descendinfo "${database}" "${_uuid}"

   # remove duplicate marker from _filename
   _filename="${_filename%#*}"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "MULLE_VIRTUAL_ROOT : ${MULLE_VIRTUAL_ROOT}"
      log_trace2 "config             : ${config}"
      log_trace2 "database           : ${database}"
      log_trace2 "filename           : ${_filename}"
      log_trace2 "newconfig          : ${_config}"
      log_trace2 "newdatabase        : ${_database}"
   fi

   local _style
   local rval

   _check_descend_nodeline "${_filename}"
   rval=$?

   if _style_for_${style} ${rval}
   then
      _sourcetree_sync_${_style} "${_config}" "${_database}"
   fi
}


_descend_config_nodeline()
{
   log_entry "_descend_config_nodeline" "$@"

   [ "$#" -ne 4 ] && internal_fail "api error"

   local nodeline="$1"; shift
   local style="$1"; shift

   local config="$1"
   local database="$2"

   [ -z "${nodeline}" ]   && internal_fail "nodeline is empty"
   [ -z "${style}" ]      && internal_fail "style is empty"

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

   nodeline_parse "${nodeline}"  # !!

   local _filename
   local _config
   local _database

   _get_config_descendinfo "${config}" "${_address}"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "MULLE_VIRTUAL_ROOT : ${MULLE_VIRTUAL_ROOT}"
      log_trace2 "config             : ${config}"
      log_trace2 "database           : ${database}"
      log_trace2 "filename           : ${_filename}"
      log_trace2 "newconfig          : ${_config}"
      log_trace2 "newdatabase        : ${_database}"
   fi

   _check_descend_nodeline "${_filename}"

   [ $? -ne 0 ] && return 1

   _sourcetree_sync_${style} "${_config}" "${_database}"
}


#
# A flat update has run. Now walk over the DB entries (actually existing
# stuff at proper position) and recursively do the inferior sourcetrees
#
_descend_db_nodelines()
{
   log_entry "_descend_db_nodelines" "$@"

   local style="$1"; shift

   local config="$1"
   local database="$2"

   local nodelines

   nodelines="`db_fetch_all_nodelines "${database}" `" || exit 1

   log_fluff "Continuing with a \"${style}\" update nodelines  \"${nodelines}\" of db \"${database:-ROOT}\" ($PWD)"

   local nodeline

   set -o noglob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

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

      _descend_db_nodeline "${nodeline}" "${style}" "${config}" "${database}"
   done

   IFS="${DEFAULT_IFS}" ; set +o noglob
}


#
# A flat update has run. Now walk over the DB entries (actually existing
# stuff at proper position) and recursively do the inferior sourcetrees
#
_descend_config_nodelines()
{
   log_entry "_descend_config_nodelines" "$@"

   local style="$1"; shift

   local config="$1"
   local database="$2"


   local nodelines

   nodelines="`cfg_read "${config}" `"
   if [ -z "${nodelines}" ]
   then
      log_fluff "No\"${style}\" update of config \"${config:-ROOT}\" as it is empty ($PWD)"
      return
   fi

   log_fluff "Continuing with a \"${style}\" update of \
nodelines \"${nodelines}\" from config \"${config:-ROOT}\" ($PWD)"

   local nodeline

   set -o noglob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      if [ -z "${nodeline}" ]
      then
         continue
      fi

      # needed for root database only
      if [ "${database}" = "/" ]
      then
         if find_line "${VISITED}" "${nodeline}"
         then
            log_fluff "\${nodeline}\" was already visited"
            continue
         fi
         r_add_line "${VISITED}" "${nodeline}"
         VISITED="${RVAL}"
      fi

      _descend_config_nodeline "${nodeline}" "${style}" "${config}" "${database}"
   done

   IFS="${DEFAULT_IFS}" ; set +o noglob
}



####
# ONLY_SHARE UPDATE
####
#
# config     : config relative to MULLE_VIRTUAL_ROOT
# database   : prefix relative to MULLE_VIRTUAL_ROOT
#
_style_for_only_share()
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


_sync_nodeline_only_share()
{
   log_entry "_sync_nodeline_only_share" "$@"

   local nodeline="$1"
   local config="$2"
   local database="$3"

   [ "$#" -ne 3 ]     && internal_fail "api error"
   [ -z "$style" ]    && internal_fail "style is empty"
   [ -z "$nodeline" ] && internal_fail "nodeline is empty"

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

   nodeline_parse "${nodeline}" # !!!

   if [ ! -z "${_url}" ] && nodemarks_enable "${_marks}" "share"
   then
      do_actions_with_nodeline "${nodeline}" "share" "${config}" "${database}"
   fi
}


_sourcetree_sync_only_share()
{
   log_entry "_sourcetree_sync_only_share" "$@"

   local config="$1"
   local database="$2"

   local style
   style="only_share"

   if ! find_line "${UPDATED}" "${config}"
   then
      log_debug "Add \"${config}\" to UPDATED"

      r_add_line "${UPDATED}" "${config}"
      UPDATED="${RVAL}"
   fi

   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database then just bail
   #
   local nodelines

   if ! nodelines="`cfg_read "${config}" `"
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      return 4
   fi

   local nodeline

   set -o noglob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

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

      _sync_nodeline_only_share "${nodeline}" "${config}" "${database}"
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   log_fluff "Doing a \"${style}\" update for \"${config}\"."

   _descend_config_nodelines "only_share" "${config}" "${database}" || return 1
}


####
# SHARE UPDATE
####
#
# config     : config relative to MULLE_VIRTUAL_ROOT
# database   : prefix relative to MULLE_VIRTUAL_ROOT
#

_style_for_share()
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
_sourcetree_sync_share()
{
   log_entry "_sourcetree_sync_share" "$@"

   local config="$1"
   local database="$2"

   local style

   style="share"

   if ! find_line "${UPDATED}" "${config}"
   then
      log_debug "Add \"${config}\" to UPDATED"
      r_add_line "${UPDATED}" "${config}"
      UPDATED="${RVAL}"
   fi

   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database then just bail
   #
   local nodelines

   if ! nodelines="`cfg_read "${config}" `"
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      if ! db_dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\" so nothing to do."
         return 127
      fi
   fi

   log_fluff "Doing a \"${style}\" update for \"${config}\"."

   db_set_dbtype "${database}" "${style}"
   db_set_update "${database}"

   db_set_shareddir "${database}" "${MULLE_SOURCETREE_STASH_DIR}"

   #
   # do a flat update first and remove what we don't have
   #
   db_zombify_nodes "${database}"

   do_actions_with_nodelines "${nodelines}" "${style}" "${config}" "${database}" || return 1

   db_bury_zombies "${database}"

   # until now, it was just pretty much like flat. Now recurse through nodelines.


   #
   # In the share case, we have done the flat and the recurse part already
   # Now recurse may have added stuff to our database. These haven't been
   # recursed yet. So we do this now. These can only be additions to
   # root, so we don't zombify.
   #
   if [ "${database}" = "/" ]
   then
      local before

      log_fluff "Root updates additions if any"

      before="`db_fetch_all_nodelines "${database}" | LC_ALL=C sort`"  || exit 1

      _descend_db_nodelines "share" "${config}" "${database}" || return 1

      while :
      do
         nodelines="`db_fetch_all_nodelines "${database}" | LC_ALL=C sort`" || exit 1
         if [ "${nodelines}" = "${before}" ]
         then
            break
         fi

         log_debug "Redo root because lines have changed"

         _descend_db_nodelines "share" "${config}" "${database}" || return 1

         before="${nodelines}"
      done
   else
      _descend_db_nodelines "share" "${config}" "${database}" || return 1
   fi

   db_clear_update "${database}"
   db_set_ready "${database}"
}


sourcetree_sync_share()
{
   log_entry "sourcetree_sync_share" "$@"

   local config="$1"
   local database="$2"

   local UPDATED
   local rval

   _sourcetree_sync_share "${config}" "${database}"
   rval=$?

   if [ $rval -eq 0 ]
   then
      log_debug "UPDATED: ${UPDATED}"

      if ! find_line "${UPDATED}" "${startpoint}"
      then
         fail "\"${MULLE_VIRTUAL_ROOT}${startpoint}\" is not reachable from the sourcetree root (${MULLE_VIRTUAL_ROOT})"
      fi
   fi
   return $rval
}


####
# RECURSE UPDATE
####

_style_for_recurse()
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
#
_sourcetree_sync_recurse()
{
   log_entry "_sourcetree_sync_recurse" "$@"

   local config="$1"
   local database="$2"

   local style

   style="recurse"

   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database then just bail
   #
   local nodelines

   if ! nodelines="`cfg_read "${config}" `"
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      if ! db_dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\""
         return 127
      fi
   fi

   log_fluff "Doing a \"${style}\" update for \"${config}\"."

   db_set_dbtype "${database}" "${style}"
   db_set_update "${database}"

   db_clear_shareddir "${database}"

   # zombify everything
   db_zombify_nodes "${database}"

   do_actions_with_nodelines "${nodelines}" "${style}" "${config}" "${database}" || return 1

   db_bury_zombie_nodelines "${database}" "${nodelines}"

   # until now, it was just like flat. Now recurse through nodelines.

   _descend_db_nodelines "recurse" "${config}" "${database}"  || return 1

   # bury rest of zombies
   db_bury_zombies "${database}"

   db_clear_update "${database}"
   db_set_ready "${database}"
}


sourcetree_sync_recurse()
{
   log_entry "sourcetree_sync_recurse" "$@"

   local config="$1"
   local database="$2"

   _sourcetree_sync_recurse "${config}" "${database}"
}


####
# FLAT UPDATE
####
#
# config     : config relative to MULLE_VIRTUAL_ROOT
# database   : prefix relative to MULLE_VIRTUAL_ROOT
#
_sourcetree_sync_flat()
{
   log_entry "_sourcetree_sync_flat" "$@"

   local config="$1"
   local database="$2"

   local style

   style="flat"

   #
   # if there are no nodelines that's OK, we still want to do zombification
   # but if there's also no database then just bail
   #
   local nodelines

   if ! nodelines="`cfg_read "${config}" `"
   then
      log_debug "There is no sourcetree configuration in \"${config}\""
      if ! db_dir_exists "${database}"
      then
         log_debug "There is also no database \"${database}\""
         return 127
      fi
   fi

   log_fluff "Doing a \"${style}\" update for \"${config}\"."

   db_set_dbtype "${database}" "${style}"
   db_set_update "${database}"

   db_clear_shareddir "${database}"
   db_zombify_nodes "${database}"

   do_actions_with_nodelines "${nodelines}" "${style}" "${config}" "${database}" || return 1

   db_bury_zombies "${database}"

   db_clear_update "${database}"
   db_set_ready "${database}"
}


sourcetree_sync_flat()
{
   log_entry "sourcetree_sync_flat" "$@"

   local config="$1"
   local database="$2"

   _sourcetree_sync_flat "${config}" "${database}"
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
sourcetree_sync_start()
{
   log_entry "sourcetree_sync_start" "$@" "($PWD)"

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

   local  rval

   "sourcetree_sync_${style}" "${SOURCETREE_START}" "${SOURCETREE_START}"
   rval=$?

   if [ $rval -eq 127 -a "${OPTION_LENIENT}" = 'YES' ]
   then
      # it's OK we can live with that
      log_verbose "There is no sourcetree in \"${MULLE_VIRTUAL_ROOT}${SOURCETREE_START}\""
      return 0
   fi

   return $rval
}


warn_dry_run()
{
   if [ "${MULLE_FLAG_EXEKUTOR_DRY_RUN}" = 'YES' ]
   then
      log_warning "***IMPORTANT REMINDER***

As fetches and zombification are not performed during a dry run (-n), the
actual commands of an update can not be shown. This is especially true for
recurse and share updates. And when updating an existing database, when
edits have been made to the configuration.
"
   fi
}


sourcetree_sync_main()
{
   log_entry "sourcetree_sync_main" "$@"

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

   # default is YES, but environment can override
   MULLE_SOURCETREE_RESOLVE_TAG="${MULLE_SOURCETREE_RESOLVE_TAG:-YES}"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_sync_usage
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

         --symlink)
            OPTION_FETCH_SYMLINK='YES'
         ;;

         --no-symlink)
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
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown update option $1"
            sourcetree_sync_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   MULLE_FETCH="${MULLE_FETCH:-`command -v mulle-fetch`}"
   [ -z "${MULLE_FETCH}" ] && fail "mulle-fetch not installed"

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   warn_dry_run

   sourcetree_sync_start
}


sourcetree_sync_initialize()
{
   log_entry "sourcetree_sync_initialize" "$@"

   if [ -z "${MULLE_SOURCETREE_ACTION_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-action.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-action.sh" || exit 1
   fi
}


sourcetree_sync_initialize

:
