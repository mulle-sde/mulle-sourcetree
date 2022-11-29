# shellcheck shell=bash
# shellcheck disable=SC2236
# shellcheck disable=SC2166
# shellcheck disable=SC2006
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
MULLE_SOURCETREE_CFG_SH="included"


# some old hack that I should get rid off (only used on one occasion)
sourcetree::cfg::r_old_absolute_filename()
{
   log_entry "sourcetree::cfg::r_old_absolute_filename" "$@"

   local config="$1"
   local address="$2"
#   local style="$3"

   case "${config}" in
      /|/*/)
      ;;

      *)
         _internal_fail "config \"${config}\" is malformed"
      ;;
   esac

   case "${address}" in
      /*)
         _internal_fail "address \"${address}\" is absolute"
      ;;
   esac

   # support test for global shared dir, which no-one uses
   #  "${style}" != "share" -a
   if [ "${config#"${MULLE_SOURCETREE_STASH_DIR}"}" != "${config}" ]
   then
      RVAL="${config}${address}"
   else
      RVAL="${MULLE_VIRTUAL_ROOT}${config}${address}"
   fi
}



sourcetree::cfg::r_absolute_filename()
{
   local config="$1"
   local filename="$2"

   local configfile

   # special handling for absolute stash
   if [ "${MULLE_SOURCETREE_STASH_DIR:0:1}" = '/' ] && \
      string_has_prefix "${config}" "${MULLE_SOURCETREE_STASH_DIR}"
   then
      case "${filename}" in
         "/")
            # filename="${filename}"
            # fallback_filename="${fallback_filename}"
         ;;

         /*)
            RVAL="${config}${filename}"
            return
         ;;

         *)
            RVAL="${config}/${filename}"
            return
         ;;
      esac
   fi

   #
   # figure out actual _configfile
   # need not exist
   #
   case "${config}" in
      "#/"*)  # hack for copy command for absolute names
         RVAL="${config#\#}/${filename}"
         return
      ;;

      "/")
         RVAL="${MULLE_VIRTUAL_ROOT}/${filename}"
         return
      ;;

      /*/)
         RVAL="${MULLE_VIRTUAL_ROOT}${config}${filename}"
         return
      ;;

      /*)
         RVAL="${MULLE_VIRTUAL_ROOT}${config}/${filename}"
         return
      ;;
   esac
   _internal_fail "Config \"${config}\" must start with '/'"
}


#
# local _configfile
# local _fallback_configfile
#
sourcetree::cfg::__common_configfile()
{
   log_entry "sourcetree::cfg::__common_configfile" "$@"

   local config="$1"

   [ -z "${SOURCETREE_CONFIG_NAME}" ] \
      && _internal_fail "SOURCETREE_CONFIG_NAME is not set"
   [ -z "${SOURCETREE_CONFIG_DIR}" ] \
      && _internal_fail "SOURCETREE_CONFIG_DIR is not set"
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && _internal_fail "MULLE_VIRTUAL_ROOT is not set"
   [ -z "${MULLE_UNAME}" ] && _internal_fail "MULLE_VIRTUAL_ROOT is not set"

   is_absolutepath "${SOURCETREE_CONFIG_DIR}" && _internal_fail "SOURCETREE_CONFIG_DIR must be relative"

   # this is usually the etc dir (relative)
   # we get something like .mulle/etc/sourcetree/config here
   r_filepath_concat "${SOURCETREE_CONFIG_DIR}" "${SOURCETREE_CONFIG_NAME}"
   sourcetree::cfg::r_absolute_filename "${config}" "${RVAL}"
   _configfile="${RVAL}"
   _fallback_configfile=

   # this is usually the share dir
   # we get something like .mulle/share/sourcetree/config here
   if [ ! -z "${SOURCETREE_FALLBACK_CONFIG_DIR}" ]
   then
      r_filepath_concat "${SOURCETREE_FALLBACK_CONFIG_DIR}" "${SOURCETREE_CONFIG_NAME}"
      sourcetree::cfg::r_absolute_filename "${config}" "${RVAL}"
      _fallback_configfile="${RVAL}"
   fi

   log_setting "_configfile          : ${_configfile}"
   log_setting "_fallback_configfile : ${_fallback_configfile}"
}


#
# config file stuff. The fallback file is usally in "share" and the default
# in "etc"
#
#
# $1 is SOURCE_TREE_START usually '/'
# $2 is either "" (default) or "fallback-only"
#
# Not sure of fallback should be even be set for "write"
#
# Globals:
#    SOURCETREE_CONFIG_NAME
#    SOURCETREE_CONFIG_DIR
#    SOURCETREE_FALLBACK_CONFIG_DIR
#
# Environment:
#    MULLE_SOURCETREE_STASH_DIR
#    MULLE_UNAME
#    MULLE_VIRTUAL_ROOT
#
sourcetree::cfg::r_configfile_for_read()
{
   log_entry "sourcetree::cfg::r_configfile_for_read" "$@"
   
   local config="$1"
   local mode="${2:-default}"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "${config}"

#  local scopes

#  scopes="${SOURCETREE_CONFIG_SCOPES:-default}"
#  if [ "${scopes}" = "default" ]
#  then
#     scopes="${MULLE_UNAME}:global"
#  fi

#   local scope
   local configfile
   local fallback_configfile

#   .foreachpath scope in ${scopes}
#   .do
#      case "${scope}" in
#         "")
#            .continue
#         ;;
#
#         'global')
            configfile="${_configfile}"
            fallback_configfile="${_fallback_configfile}"
#         ;;
#
#         # address custom scope (don't check for existance here)
#         *)
#            configfile="${_configfile}.${scope}"
#            fallback_configfile="${_fallback_configfile}.${scope}"
#         ;;
#      esac

      log_setting "configfile           : ${configfile}"
      log_setting "fallback_configfile  : ${fallback_configfile}"

      #
      # if there are more names to search and there are no files here
      # keep going
      #
      if [ -f "${configfile}" ]
      then
         if [ "${mode}" = "fallback-only" ]
         then
            if [ -f "${fallback_configfile}" ]
            then
               log_debug "return       : ${fallback_configfile}"
               RVAL="${fallback_configfile}"
               return 0
            fi
            log_debug "return       : NONE"
            RVAL=
            return 1
         fi

         log_debug "return       : ${configfile}"
         RVAL="${configfile}"
         return 0
      fi
#   .done

   #
   # in fallback-only we look for the fallback file matching the configfile
   # we return 1, if there is only the fallback file or of there was no
   # configfile match (!) ot there is no such fallback file
   #
   if [ "${mode}" = "fallback-only" ]
   then
      log_debug "return       : NONE"
      RVAL=""
      return 1
   fi

#   .foreachpath scope in ${scopes}
#   .do
#      case "${scope}" in
#         "")
#            .continue
#         ;;
#
#         'global')
            configfile="${_fallback_configfile}"
#         ;;
#
#         # address custom scope (don't check for existance here)
#         *)
#            configfile="${_fallback_configfile}.${scope}"
#         ;;
#      esac

      log_setting "configfile           : ${configfile}"

      #
      # if there are more names to search and there are no files here
      # keep going
      #
      if [ -f "${configfile}" ]
      then
         log_debug "return       : ${configfile}"
         RVAL="${configfile}"
         return 0
      fi
#   .done

   log_debug "return       : NONE"
   RVAL=
   return 1
}


#
# config file stuff. The fallback file is usally in "share" and the default
# in "etc"
#
# $1 is SOURCE_TREE_START usually '/'
# $2 is either "r" (default) or "w"
#
# Not sure of fallback should be even be set for "write"
#
# Globals:
#    SOURCETREE_CONFIG_NAME
#    SOURCETREE_CONFIG_SCOPES
#    SOURCETREE_CONFIG_DIR
#    SOURCETREE_FALLBACK_CONFIG_DIR
#
# Environment:
#    MULLE_SOURCETREE_STASH_DIR
#    MULLE_UNAME
#    MULLE_VIRTUAL_ROOT
#
sourcetree::cfg::r_configfile_for_write()
{
   log_entry "sourcetree::cfg::r_configfile_for_write" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$@"

   [ -z "${_configfile}" ] && _internal_fail "configfile must not be empty"

#   local scopes
#
#   scopes="${SOURCETREE_CONFIG_SCOPES:-default}"
#   if [ "${scopes}" = "default" ]
#   then
#      scopes="${MULLE_UNAME}:global"
#   fi

   #
   # pick the first one that exists, otherwise use last scope
   #
#   .foreachpath scope in ${scopes}
#   .do
#      case "${scope}" in
#         "")
#            .continue
#         ;;
#
#         'global')
            configfile="${_configfile}"
#         ;;
#
#         # address custom scope (don't check for existance here)
#         *)
#            configfile="${_configfile}.${scope}"
#         ;;
#      esac

      log_setting "configfile   : ${configfile}"

      #
      # if there are more names to search and there are no files here
      # keep going
      #
#      if [ -f "${configfile}" ]
#      then
#         log_debug "return       : ${configfile}"
         RVAL="${configfile}"
#         return 0
#      fi
#   .done
#   local lastscope
#
#   lastscope="${scopes##*:}"
#
#   case "${lastscope}" in
#      ''|'global')
#         RVAL="${_configfile}"
#      ;;
#
#      # address custom scope (don't check for existance here)
#      *)
#         RVAL="${_configfile}.${lastscope}"
#      ;;
#   esac
#
   log_debug "return       : ${RVAL}"
   return 0
}


sourcetree::cfg::__common_rootdir()
{
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && _internal_fail "MULLE_VIRTUAL_ROOT is not set"

   case "${MULLE_SOURCETREE_STASH_DIR}" in
      /*)
         if string_has_prefix "$1" "${MULLE_SOURCETREE_STASH_DIR}"
         then
            case "$1" in
               "/")
                  _rootdir="."
               ;;

               /*/)
                  _rootdir="${1%%\/}"
                  _rootdir="${_rootdir:-.}"  # if all were '///'
               ;;

               *)
                  _rootdir="$1"
               ;;
            esac
            return
         fi
      ;;
   esac

   case "$1" in
      "#/"*)
         r_dirname "$1"       # remove config
         r_dirname "${RVAL}"  # remove sourcetree
         r_dirname "${RVAL}"  # remove etc
         r_dirname "${RVAL}"  # remove .mulle
         _rootdir="${RVAL}"
      ;;

      "/")
         _rootdir="${MULLE_VIRTUAL_ROOT}"
      ;;

      /*/)
         _rootdir="${MULLE_VIRTUAL_ROOT}${1%%\/}"
      ;;

      /*)
         _rootdir="${MULLE_VIRTUAL_ROOT}$1"
      ;;

      *)
         _internal_fail "Config \"$1\" must start with '/'"
      ;;
   esac
}


sourcetree::cfg::rootdir()
{
   local _rootdir

   sourcetree::cfg::__common_rootdir "$1"
   printf "%s\n" "${_rootdir}"
}


#
# these can be prefixed for external queries
#
sourcetree::cfg::is_config_present()
{
   log_entry "sourcetree::cfg::is_config_present" "$@"

   local config="$1"

   sourcetree::cfg::r_configfile_for_read "${config}"
   if [ ! -z "${RVAL}" ]
   then
      log_debug "\"${config}\" exists as \"${RVAL}\""
      return 0
   fi

   log_debug "\"${config}\" not found"
   return 1
}


sourcetree::cfg::timestamp()
{
   log_entry "sourcetree::cfg::timestamp" "$@"

   local config="$1"

   if ! sourcetree::cfg::r_configfile_for_read "${config}"
   then
      return 1
   fi

   modification_timestamp "${RVAL}"
}


#
# egrep return values 0: has lines
#                     1: no lines
#                     2: error
#
sourcetree::cfg::_read()
{
   local configfile="$1"

   local  rval

   egrep -s -v '^#' "${configfile}"
   rval=$?

   log_debug "Read config file \"${configfile#"${MULLE_USER_PWD}/"}\" (${PWD#"${MULLE_USER_PWD}/"}) rval:${rval}"

   # egrep error is 2
   case $rval in 
      0|1)
         return 0
      ;;
   esac
   return $rval
}


sourcetree::cfg::read()
{
   log_entry "sourcetree::cfg::read" "$@"

   local config="$1"

   if ! sourcetree::cfg::r_configfile_for_read "${config}"
   then
      return 1
   fi

   sourcetree::cfg::_read "${RVAL}"
}


sourcetree::cfg::get_nodeline()
{
   log_entry "sourcetree::cfg::get_nodeline" "$@"

   local projectdir="$1"
   local address="$2"
   local fuzzy="$3"

   local nodelines

   nodelines="`sourcetree::cfg::read "${projectdir}"`"
   sourcetree::nodeline::find "${nodelines}" "${address}" "${fuzzy}"
}


sourcetree::cfg::get_nodeline_by_url()
{
   log_entry "sourcetree::cfg::get_nodeline_by_url" "$@"

   local projectdir="$1"
   local url="$2"

   local nodelines

   nodelines="`sourcetree::cfg::read "${projectdir}"`"
   sourcetree::nodeline::find_by_url "${nodelines}" "${url}"
}


sourcetree::cfg::get_nodeline_by_uuid()
{
   log_entry "sourcetree::cfg::get_nodeline_by_uuid" "$@"

   local projectdir="$1"
   local uuid="$2"

   local nodelines

   nodelines="`sourcetree::cfg::read "${projectdir}"`"
   sourcetree::nodeline::find_by_uuid "${nodelines}" "${uuid}"
}


sourcetree::cfg::get_nodeline_by_evaled_url()
{
   log_entry "sourcetree::cfg::get_nodeline_by_evaled_url" "$@"

   local projectdir="$1"
   local url="$2"

   local nodelines

   nodelines="`sourcetree::cfg::read "${projectdir}"`"
   sourcetree::nodeline::find_by_evaled_url "${nodelines}" "${url}"
}


sourcetree::cfg::has_duplicate()
{
   log_entry "sourcetree::cfg::has_duplicate" "$@"

   local projectdir="$1"
   local uuid="$2"
   local address="$3"

   local nodelines

   nodelines="`sourcetree::cfg::read "${projectdir}"`"
   sourcetree::nodeline::has_duplicate "${nodelines}" "${address}" "${uuid}"
}


sourcetree::cfg::r_prepare_for_write()
{
   log_entry "sourcetree::cfg::r_prepare_for_write" "$@"

   local config="$1"

   include "etc"

   #
   # need this beforehand to get proper write_configfile
   #
   local etcdir

   sourcetree::cfg::r_absolute_filename "${config}" "${SOURCETREE_CONFIG_DIR}"
   etcdir="${RVAL}"

   if [ ! -z "${SOURCETREE_FALLBACK_CONFIG_DIR}" ]
   then
      local sharedir

      sourcetree::cfg::r_absolute_filename "${config}" "${SOURCETREE_FALLBACK_CONFIG_DIR}"
      sharedir="${RVAL}"

      etc_setup_from_share_if_needed "${etcdir}" \
                                     "${sharedir}"
   fi

   sourcetree::cfg::r_configfile_for_write "${config}"
   write_configfile="${RVAL}"

   r_mkdir_parent_if_missing "${write_configfile}"

   if [ ! -z "${SOURCETREE_FALLBACK_CONFIG_DIR}" ]
   then
      etc_make_file_from_symlinked_file "${write_configfile}"
   fi

   RVAL="${write_configfile}"
}


sourcetree::cfg::finish_for_write()
{
   log_entry "sourcetree::cfg::finish_for_write" "$@"

   local config="$1"
   local write_configfile="$2"

   local sharedir

   if [ ! -z "${SOURCETREE_FALLBACK_CONFIG_DIR}" ]
   then
      sourcetree::cfg::r_absolute_filename "${config}" "${SOURCETREE_FALLBACK_CONFIG_DIR}"
      sharedir="${RVAL}"
      if [ ! -d "${sharedir}" ]
      then
         sharedir=""
      fi
   fi

   local rval

   if [ ! -z "${sharedir}" ]
   then
      etc_make_symlink_if_possible "${write_configfile}" "${sharedir}"
      rval=$?
      log_debug "rval=$rval"

      case $rval in
         0) # : did make symlink
            sourcetree::cfg::r_absolute_filename "${config}" "${SOURCETREE_CONFIG_DIR}"
            etcdir="${RVAL}"
            etc_remove_if_possible "${etcdir}" "${sharedir}"
            return
         ;;

         1) # : symlinking error
            fail "Could not create symlink for config file"
         ;;

         2) # : share file does not exist
            # so we can remove it
         ;;

         *) # : contents differ or nothing to do
            return 0
         ;;
      esac
   fi

   local current_contents

   current_contents="`sourcetree::cfg::_read "${write_configfile}"`"
   if [ -z "${current_contents}" ]
   then
      remove_file_if_present  "${write_configfile}"
      r_dirname "${write_configfile}"
      rmdir_if_empty "${RVAL}"
   fi
}


sourcetree::cfg::write()
{
   log_entry "sourcetree::cfg::write" "$@"

   local config="$1"; shift

   local write_configfile

   sourcetree::cfg::r_prepare_for_write "${config}"
   write_configfile="$RVAL"

   if ! redirect_exekutor "${write_configfile}" printf "%s\n" "$*"
   then
      exit 1
   fi

   sourcetree::cfg::finish_for_write "${config}" "${write_configfile}"
}

sourcetree::cfg::remove_nodeline()
{
   log_entry "sourcetree::cfg::remove_nodeline" "$@"

   local config="$1"
   local address="$2"

   local write_configfile

   sourcetree::cfg::r_prepare_for_write "${config}"
   write_configfile="$RVAL"

   local escaped

   log_debug "Removing \"${address}\" from  \"${write_configfile}\""
   r_escaped_sed_pattern "${address}"
   escaped="${RVAL}"

   # linux don't like space after -i
   if ! inplace_sed -e "/^${escaped};/d" "${write_configfile}"
   then
      _internal_fail "sed address corrupt ?"
   fi

   sourcetree::cfg::finish_for_write "${config}" "${write_configfile}"
}


sourcetree::cfg::remove_nodeline_by_uuid()
{
   log_entry "sourcetree::cfg::remove_nodeline_by_uuid" "$@"

   local config="$1"
   local uuid="$2"

   local write_configfile

   sourcetree::cfg::r_prepare_for_write "${config}"
   write_configfile="$RVAL"

   log_debug "Removing \"${uuid}\" from \"${write_configfile}\""

   local escaped

   r_escaped_sed_pattern "${uuid}"
   escaped="${RVAL}"

   # linux don't like space after -i
   if ! inplace_sed -e "/^[^;]*;[^;]*;[^;]*;${escaped};/d" "${write_configfile}"
   then
      _internal_fail "sed address corrupt ?"
   fi

   sourcetree::cfg::finish_for_write "${config}" "${write_configfile}"
}


sourcetree::cfg::change_nodeline()
{
   log_entry "sourcetree::cfg::change_nodeline" "$@"

   local config="$1"
   local oldnodeline="$2"
   local newnodeline="$3"

   local write_configfile

   sourcetree::cfg::r_prepare_for_write "${config}"
   write_configfile="$RVAL"

   if [ "${MULLE_FLAG_LOG_DEBUG}" = 'YES' ]
   then
      sourcetree::nodeline::r_diff "${oldnodeline}" "${newnodeline}"
      log_debug "diff ${RVAL}"
   fi

   local oldescaped
   local newescaped

   r_escaped_sed_pattern "${oldnodeline}"
   oldescaped="${RVAL}"
   r_escaped_sed_replacement "${newnodeline}"
   newescaped="${RVAL}"

   log_debug "Editing \"${write_configfile}\""

   # linux don't like space after -i
   if ! inplace_sed -e "s/^${oldescaped}$/${newescaped}/" "${write_configfile}"
   then
      fail "Edit of config file failed unexpectedly"
   fi

   sourcetree::cfg::finish_for_write "${config}" "${write_configfile}"
}



#
# returned path is always physical
# SOURCETREE_START should probably be passed in
#
sourcetree::cfg::search_for_configfile()
{
   log_entry "sourcetree::cfg::search_for_configfile" "$@"

   local physdirectory="$1"
   local ceiling="$2"

   [ -z "${physdirectory}" ] && _internal_fail "empty directory"

   local physceiling

   physceiling="$( cd "${ceiling}" ; pwd -P 2> /dev/null )"
   [ -z "${physceiling}" ] && fail "SOURCETREE_START/MULLE_VIRTUAL_ROOT does not exist (${ceiling})"

   # check that physdirectory is inside physceiling
   log_setting "physceiling  : ${physceiling}"
   log_setting "physdirectory: ${physdirectory}"

   case "${physdirectory}" in
      ${physceiling})
         printf "%s\n" "${physdirectory}"  # common cheap equality
         return 1
      ;;

      ${physceiling}/*)
      ;;

      *)
         if [ "${ceiling}" != "/" ]
         then
            log_debug "Start is outside of the ceiling"
            return 1
         fi
      ;;
   esac

   _log_debug "Searching for config \"${SOURCETREE_CONFIG_NAME}\" \
(\"$SOURCETREE_CONFIG_DIR:$SOURCETREE_FALLBACK_CONFIG_DIR\") \
from \"${physdirectory}\" to \"${physceiling}\""

   (
      cd "${physdirectory}" || exit 1

      while :
      do
         if sourcetree::cfg::r_configfile_for_read "${SOURCETREE_START}"
         then
            break
         fi

         # since we do physical paths, PWD is ok here
         if [ "${PWD}" = "${physceiling}" ]
         then
            log_debug "Touched the ceiling"
            exit 2
         fi &&
         cd ..
      done &&

      log_debug "Found \"${PWD}\"" &&
      printf "%s\n" "${PWD}"
   )
}


#
# Return the directory, that we should be using for the following defer
# possibilities. The returned directory is always a physical path
#
# NONE:    do not search
# NEAREST: search up until we find a sourcetree
# PARENT:  get the enveloping sourcetree of PWD (even if PWD has a sourcetree)
# ROOT:    get the outermost enveloping sourcetree (can be PWD)
#
#
sourcetree::cfg::determine_working_directory()
{
   log_entry "sourcetree::cfg::determine_working_directory" "$@"

   local defer="$1"
   local physpwd="$2"

   [ ! -z "${defer}" ]      || _internal_fail "empty defer"
   [ ! -z "${physpwd}" ]    || _internal_fail "empty phypwd"

   if [ -z "${MULLE_PATH_SH}" ]
   then
      fail "need mulle-path.sh for this to work"
   fi

   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
      fail "need mulle-sourcetree-db.sh for this to work"
   fi

   local ceiling

   #
   # make sure that the ceiling is thre
   # and we walk with symlinks removed, so that we hit the ceiling
   # Also make sure we only walk physical paths
   #
   if [ ! -z "${MULLE_VIRTUAL_ROOT}" ] && [ -d "${MULLE_VIRTUAL_ROOT}" ]
   then
      ceiling="${MULLE_VIRTUAL_ROOT}"
   else
      ceiling="${SOURCETREE_START}"
   fi

   local directory
   local parent
   local found

   case "${defer}" in
      'NONE')
         if sourcetree::cfg::is_config_present "${SOURCETREE_START}"
         then
            pwd -P
            return 0
         fi

         log_debug "No config found or db found"
         return 1
      ;;

      'NEAREST')
         if ! sourcetree::cfg::search_for_configfile "${physpwd}" "${ceiling}"
         then
            log_debug "No nearest config found or db found"
            return 1
         fi
         return 0
      ;;

      # used for touching parent configs in a sourcetree
      'PARENT')
         directory="`sourcetree::cfg::search_for_configfile "${physpwd}" "/"`"
         if [ $? -ne 0 ]
         then
            log_debug "No config found or db found"
            return 1
         fi

         if [ "${directory}" != "${physpwd}" ]
         then
            log_debug "Immediate parent found"
            printf "%s\n" "${directory}"
            return 0
         fi

         r_dirname "${directory}"
         parent="${RVAL}"

         sourcetree::cfg::search_for_configfile "${parent}" "/"
         if [ $? -eq 0 ]
         then
            log_debug "Actual parent found"
            return 0
         fi

         log_fluff "No parent found"
         return 1
      ;;

      'ROOT')
         directory="`sourcetree::cfg::search_for_configfile "${physpwd}" "${ceiling}"`"
         if [ $? -ne 0 ]
         then
            log_debug "No config found"
            return 1
         fi

         while :
         do
            found="${directory}"
            r_dirname "${directory}"
            parent="${RVAL}"
            if [ "${parent}" = "${SOURCETREE_START}" ]
            then
               break
            fi

            directory="`sourcetree::cfg::search_for_configfile "${parent}" "${ceiling}" `"
            if [ $? -ne 0 ]
            then
               break
            fi
         done

         printf "%s\n" "${found}"
         return 0
      ;;

      'VIRTUAL')
         directory="`sourcetree::cfg::search_for_configfile "/" "${ceiling}" `"
         if [ $? -ne 0 ]
         then
            log_debug "No config found in MULLE_VIRTUAL_ROOT ($MULLE_VIRTUAL_ROOT}"
            return 1
         fi
         printf "%s\n" "${directory}"
         return 0
      ;;

      *)
         _internal_fail "unknown defer type \"${defer}\""
      ;;
   esac

   return 1
}


sourcetree::cfg::get_parent()
{
   local start="$1"

   start="${start:-${MULLE_SOURCETREE_PROJECT_DIR}}"
   sourcetree::cfg::determine_working_directory "PARENT" "${start}"
}


#
#
# In a subproject/minion master configuration, we wanted to propagate changes
# upwards. Not 100% sure that this is still very useful (but: in a normal
# configuration, you don't have a parent anyway)
#
sourcetree::cfg::touch_parents()
{
   log_entry "sourcetree::cfg::touch_parents" "$@"

   local _rootdir

   sourcetree::cfg::__common_rootdir "$@"

   local parent

   while parent="`sourcetree::cfg::get_parent "${_rootdir}" `"
   do
      [ "${parent}" = "${_rootdir}" ] \
         && _internal_fail "${parent} endless loop"

      sourcetree::cfg::r_configfile_for_write "${SOURCETREE_START}"

      # don't touch the fallback
      if [ -f "${RVAL}" ]
      then
         exekutor touch -f "${RVAL}"
      fi

      _rootdir="${parent}"
   done
}


sourcetree::cfg::defer_if_needed()
{
   log_entry "sourcetree::cfg::defer_if_needed" "$@"

   local defer="$1"

   local directory
   local physpwd

   physpwd="${MULLE_SOURCETREE_PROJECT_DIR}"
   if directory="`sourcetree::cfg::determine_working_directory "${defer}" "${physpwd}"`"
   then
      if [ "${directory}" != "${physpwd}" ]
      then
         log_info "Using \"${directory}\" as sourcetree root"
         exekutor cd "${directory}"
      fi
   else
      return 1
   fi
}
