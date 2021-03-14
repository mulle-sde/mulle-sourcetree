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
MULLE_SOURCETREE_CFG_SH="included"


#
# config file stuff
#
__cfg_common_configfile()
{
   [ -z "${SOURCETREE_CONFIG_FILENAME}" ] && internal_fail "SOURCETREE_CONFIG_FILENAME is not set"
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT is not set"

   case "${MULLE_SOURCETREE_STASH_DIR}" in
      /*)
         if string_has_prefix "$1" "${MULLE_SOURCETREE_STASH_DIR}"
         then
            case "$1" in
               "/")
                  configfile="${SOURCETREE_CONFIG_FILENAME}"
               ;;

               /*/)
                  configfile="$1${SOURCETREE_CONFIG_FILENAME}"
               ;;

               *)
                  configfile="$1/${SOURCETREE_CONFIG_FILENAME}"
               ;;
            esac
            return
         fi
      ;;
   esac

   case "$1" in
      "/")
         configfile="${MULLE_VIRTUAL_ROOT}/${SOURCETREE_CONFIG_FILENAME}"
      ;;

      /*/)
         configfile="${MULLE_VIRTUAL_ROOT}$1${SOURCETREE_CONFIG_FILENAME}"
      ;;

      /*)
         configfile="${MULLE_VIRTUAL_ROOT}$1/${SOURCETREE_CONFIG_FILENAME}"
      ;;

      *)
         internal_fail "database \"$1\" must start with '/'"
      ;;
   esac

   #
   # allow "hacky" per-platform config files if all else fails
   #
   case "${SOURCETREE_SCOPE}" in
      'default')
         if [ -f "${configfile}.${MULLE_UNAME}" ]
         then
            configfile="${configfile}.${MULLE_UNAME}"
         fi
      ;;

      'global')
      ;;

      *)
         configfile="${configfile}.${SOURCETREE_SCOPE}"
      ;;
   esac
}


__cfg_common_rootdir()
{
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT is not set"

   case "${MULLE_SOURCETREE_STASH_DIR}" in
      /*)
         if string_has_prefix "$1" "${MULLE_SOURCETREE_STASH_DIR}"
         then
            case "$1" in
               "/")
                  rootdir="."
               ;;

               /*/)
                  rootdir="$(sed 's|/$||g' <<< "$1")"
               ;;

               *)
                  rootdir="$1"
               ;;
            esac
            return
         fi
      ;;
   esac

   case "$1" in
      "/")
         rootdir="${MULLE_VIRTUAL_ROOT}"
      ;;

      /*/)
         rootdir="${MULLE_VIRTUAL_ROOT}/$(sed 's|/$||g' <<< "$1")"
      ;;

      /*)
         rootdir="${MULLE_VIRTUAL_ROOT}/$1"
      ;;

      *)
         internal_fail "Config \"$1\" must start with '/'"
      ;;
   esac
}


cfg_rootdir()
{
   local rootdir

   __cfg_common_rootdir "$1"
   printf "%s\n" "${rootdir}"
}


#
# these can be prefixed for external queries
#
cfg_exists()
{
   log_entry "cfg_exists" "$@"

   local configfile

   __cfg_common_configfile "$@"

   if [ -f "${configfile}" ]
   then
      log_debug "\"${configfile}\" exists"
      return 0
   fi

   log_debug "\"${configfile}\" not found"
   return 1
}


cfg_timestamp()
{
   log_entry "cfg_timestamp" "$@"

   local configfile

   __cfg_common_configfile "$@"

   if [ -f "${configfile}" ]
   then
      modification_timestamp "${configfile}"
   fi
}


#
# can receive a configfile (for walking)
#
__cfg_read()
{
   if [ -f "${configfile}" ]
   then
      log_debug "Read config file \"${configfile}\" ($PWD)"
      egrep -s -v '^#' "${configfile}"
   else
      log_debug "No config file \"${configfile}\" found ($PWD)"
      return 1
   fi
}


cfg_read()
{
   log_entry "cfg_read" "$@"

   local configfile

   __cfg_common_configfile "$@"

   __cfg_read
}


cfg_write()
{
   log_entry "cfg_write" "$@"

   [ -z "${MULLE_SOURCETREE_ETC_DIR}" ] && internal_fail "MULLE_SOURCETREE_ETC_DIR is empty"

   local configfile

   __cfg_common_configfile "$@"
   shift

   mkdir_if_missing "${MULLE_SOURCETREE_ETC_DIR}"
   if ! redirect_exekutor "${configfile}" printf "%s\n" "$*"
   then
      exit 1
   fi
}


cfg_get_nodeline()
{
   log_entry "cfg_get_nodeline" "$@"

   local projectdir="$1"
   local address="$2"
   local fuzzy="$3"

   local nodelines

   nodelines="`cfg_read "${projectdir}"`"
   nodeline_find "${nodelines}" "${address}" "${fuzzy}"
}


cfg_get_nodeline_by_url()
{
   log_entry "cfg_get_nodeline_by_url" "$@"

   local projectdir="$1"
   local url="$2"

   local nodelines

   nodelines="`cfg_read "${projectdir}"`"
   nodeline_find_by_url "${nodelines}" "${url}"
}


cfg_get_nodeline_by_uuid()
{
   log_entry "cfg_get_nodeline_by_uuid" "$@"

   local projectdir="$1"
   local uuid="$2"

   local nodelines

   nodelines="`cfg_read "${projectdir}"`"
   nodeline_find_by_uuid "${nodelines}" "${uuid}"
}


cfg_get_nodeline_by_evaled_url()
{
   log_entry "cfg_get_nodeline_by_evaled_url" "$@"

   local projectdir="$1"
   local url="$2"

   local nodelines

   nodelines="`cfg_read "${projectdir}"`"
   nodeline_find_by_evaled_url "${nodelines}" "${url}"
}


cfg_has_duplicate()
{
   log_entry "cfg_has_duplicate" "$@"

   local projectdir="$1"
   local uuid="$2"
   local address="$3"

   local nodelines

   nodelines="`cfg_read "${projectdir}"`"
   nodeline_has_duplicate "${nodelines}" "${address}" "${uuid}"
}


cfg_remove_nodeline()
{
   log_entry "cfg_remove_nodeline" "$@"

   local configfile

   __cfg_common_configfile "$@"

   local address="$2"

   local escaped
   log_debug "Removing \"${address}\" from  \"${configfile}\""
   r_escaped_sed_pattern "${address}"
   escaped="${RVAL}"

   # linux don't like space after -i
   if ! inplace_sed -e "/^${escaped};/d" "${configfile}"
   then
      internal_fail "sed address corrupt ?"
   fi
}


cfg_remove_nodeline_by_uuid()
{
   log_entry "cfg_remove_nodeline_by_uuid" "$@"

   local configfile

   __cfg_common_configfile "$@"

   local uuid="$2"

   local escaped

   log_debug "Removing \"${uuid}\" from \"${configfile}\""

   r_escaped_sed_pattern "${uuid}"
   escaped="${RVAL}"

   # linux don't like space after -i
   if ! inplace_sed -e "/^[^;]*;[^;]*;[^;]*;${escaped};/d" "${configfile}"
   then
      internal_fail "sed address corrupt ?"
   fi
}


cfg_file_remove()
{
   log_entry "cfg_file_remove_if_empty" "$@"

   local configfile

   __cfg_common_configfile "$@"

   remove_file_if_present "${configfile}"
}


cfg_file_remove_if_empty()
{
   log_entry "cfg_file_remove_if_empty" "$@"

   local configfile

   __cfg_common_configfile "$@"

   if [ -z "`__cfg_read`" ]
   then
      remove_file_if_present "${configfile}"
   fi
}


cfg_change_nodeline()
{
   log_entry "cfg_change_nodeline" "$@"

   local configfile

   __cfg_common_configfile "$@"

   local oldnodeline="$2"
   local newnodeline="$3"

   local oldescaped
   local newescaped

   r_escaped_sed_pattern "${oldnodeline}"
   oldescaped="${RVAL}"
   r_escaped_sed_replacement "${newnodeline}"
   newescaped="${RVAL}"

   log_debug "Editing \"${SOURCETREE_CONFIG_FILENAME}\""

   # linux don't like space after -i
   if ! inplace_sed -e "s/^${oldescaped}$/${newescaped}/" "${configfile}"
   then
      fail "Edit of config file failed unexpectedly"
   fi
}


#
# returned path is always physical
# SOURCETREE_START should probably be passed in
#
cfg_search_for_configfile()
{
   log_entry "cfg_search_for_configfile" "$@"

   local physdirectory="$1"
   local ceiling="$2"

   [ -z "${physdirectory}" ] && internal_fail "empty directory"

   local physceiling

   physceiling="$( cd "${ceiling}" ; pwd -P 2> /dev/null )"
   [ -z "${physceiling}" ] && fail "SOURCETREE_START/MULLE_VIRTUAL_ROOT does not exist (${ceiling})"

   # check that physdirectory is inside physceiling
   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "physceiling  : ${physceiling}"
      log_trace2 "physdirectory: ${physdirectory}"
   fi

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

   log_debug "Searching for configfile \"${SOURCETREE_CONFIG_FILENAME}\" \
from \"${physdirectory}\" to \"${physceiling}\""

   (
      cd "${physdirectory}" &&
      while [ ! -f "${SOURCETREE_CONFIG_FILENAME}" ]
      do
         # since we do physical paths, PWD is ok here
         if [ "${PWD}" = "${physceiling}" ]
         then
            log_debug "Touched the ceiling"
            exit 1
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
cfg_determine_working_directory()
{
   log_entry "cfg_determine_working_directory" "$@"

   local defer="$1"
   local physpwd="$2"

   [ ! -z "${defer}" ]      || internal_fail "empty defer"
   [ ! -z "${physpwd}" ]    || internal_fail "empty phypwd"

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
         if cfg_exists "${SOURCETREE_START}"
         then
            pwd -P
            return 0
         fi

         log_debug "No config found or db found"
         return 1
      ;;

      'NEAREST')
         if ! cfg_search_for_configfile "${physpwd}" "${ceiling}"
         then
            log_debug "No nearest config found or db found"
            return 1
         fi
         return 0
      ;;

      # used for touching parent configs in a sourcetree
      'PARENT')
         directory="`cfg_search_for_configfile "${physpwd}" "/"`"
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

         cfg_search_for_configfile "${parent}" "/"
         if [ $? -eq 0 ]
         then
            log_debug "Actual parent found"
            return 0
         fi

         log_fluff "No parent found"
         return 1
      ;;

      'ROOT')
         directory="`cfg_search_for_configfile "${physpwd}" "${ceiling}"`"
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

            directory="`cfg_search_for_configfile "${parent}" "${ceiling}" `"
            if [ $? -ne 0 ]
            then
               break
            fi
         done

         printf "%s\n" "${found}"
         return 0
      ;;

      'VIRTUAL')
         directory="`cfg_search_for_configfile "/" "${ceiling}" `"
         if [ $? -ne 0 ]
         then
            log_debug "No config found in MULLE_VIRTUAL_ROOT ($MULLE_VIRTUAL_ROOT}"
            return 1
         fi
         printf "%s\n" "${directory}"
         return 0
      ;;

      *)
         internal_fail "unknown defer type \"${defer}\""
      ;;
   esac

   return 1
}


cfg_get_parent()
{
   local start="$1"

   start="${start:-${MULLE_SOURCETREE_PROJECT_DIR}}"
   cfg_determine_working_directory "PARENT" "${start}"
}


cfg_touch_parents()
{
   log_entry "cfg_touch_parents" "$@"

   local rootdir

   __cfg_common_rootdir "$@"

   local parent

   while parent="`cfg_get_parent "${rootdir}" `"
   do
      [ "${parent}" = "${rootdir}" ] && internal_fail "${parent} endless loop"

      exekutor touch "${parent}/${SOURCETREE_CONFIG_FILENAME}"
      rootdir="${parent}"
   done
}


cfg_defer_if_needed()
{
   log_entry "cfg_defer_if_needed" "$@"

   local defer="$1"

   local directory
   local physpwd

   physpwd="${MULLE_SOURCETREE_PROJECT_DIR}"
   if directory="`cfg_determine_working_directory "${defer}" "${physpwd}"`"
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


r_cfg_absolute_filename()
{
   log_entry "r_cfg_absolute_filename" "$@"

   local config="$1"
   local address="$2"
   local style="$3"

   case "${config}" in
      /|/*/)
      ;;

      *)
         internal_fail "config \"${config}\" is malformed"
      ;;
   esac

   case "${address}" in
      /*)
         internal_fail "address \"${address}\" is absolute"
      ;;
   esac

   # support test for global shared dir, which no-one uses
   #  "${style}" != "share" -a
   if [ "${config#${MULLE_SOURCETREE_STASH_DIR}}" != "${config}" ]
   then
      RVAL="${config}${address}"
   else
      RVAL="${MULLE_VIRTUAL_ROOT}${config}${address}"
   fi
}


cfg_reuuid()
{
   log_entry "cfg_reuuid" "$@"

   local config="$1"

   local nodelines
   local nodeline
   local output

   nodelines="`cfg_read "${config}"`" || exit 1

   [ -z "${nodelines}" ] && return 0

   set -o noglob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      local _branch
      local _address
      local _fetchoptions
      local _nodetype
      local _marks
      local _raw_userinfo
      local _tag
      local _url
      local _uuid
      local _userinfo

      nodeline_parse "${nodeline}"  # memo: :_marks used raw

      _uuid="`node_uuidgen`" || exit 1

      _r_node_to_nodeline
      r_add_line "${output}" "${RVAL}"
      output="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   cfg_write "${config}" "${output}"
}

