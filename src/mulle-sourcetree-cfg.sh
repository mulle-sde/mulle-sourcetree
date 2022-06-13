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
# config file stuff. The fallback file is usally in "share" and the default
# in "etc"
#
# local _configfile
# local _fallback_configfile
#
# $1 is SOURCE_TREE_START usually '/'
# $2 is either "r" (default) or "w"
#
# Not sure of fallback should be even be set for "write"
#
# Globals:
#    SOURCETREE_CONFIG_NAMES
#    SOURCETREE_SCOPE
#    SOURCETREE_CONFIG_DIR
#    SOURCETREE_FALLBACK_CONFIG_DIR
#
# Environment:
#    MULLE_SOURCETREE_STASH_DIR
#    MULLE_UNAME
#    MULLE_VIRTUAL_ROOT
#
sourcetree::cfg::__common_configfile()
{
   [ -z "${SOURCETREE_CONFIG_NAMES}" ] \
      && _internal_fail "SOURCETREE_CONFIG_NAMES is not set"
   [ -z "${SOURCETREE_CONFIG_DIR}" ] \
      && _internal_fail "SOURCETREE_CONFIG_DIR is not set"
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && _internal_fail "MULLE_VIRTUAL_ROOT is not set"

   local names
   local scope

   scope="${SOURCETREE_SCOPE}"
   names="${SOURCETREE_CONFIG_NAMES}"

   #
   # for writing can only have one filename, as the file may not exist
   #
   case "$2" in
      *w)
         case "${scope}" in
            global)
               names="config"
            ;;

            "")
               _internal_fail "scope can't be empty"#
            ;;

            default)
               names="${SOURCETREE_CONFIG_NAMES%%:*}" # pick first to write
               scope="global"
            ;;

            *)
               names="${SOURCETREE_CONFIG_NAMES%%:*}" # pick first to write
                                                      # keep scope
            ;;
         esac
      ;;
   esac

   local name
   local lastname
   local filename
   local fallback_filename

   lastname="${names##*:}"

   IFS=":"
   for name in ${names}
   do
      IFS="${DEFAULT_IFS}"

      r_filepath_concat "${SOURCETREE_CONFIG_DIR}" "${name}"
      filename="${RVAL}"

      if [ ! -z "${SOURCETREE_FALLBACK_CONFIG_DIR}" ]
      then
         r_filepath_concat "${SOURCETREE_FALLBACK_CONFIG_DIR}" "${name}"
         fallback_filename="${RVAL}"
      fi

      _configfile=""
      _fallback_configfile=""

      # special handling for absolute stash
      if [ "${MULLE_SOURCETREE_STASH_DIR:0:1}" = '/' ] && \
         string_has_prefix "$1" "${MULLE_SOURCETREE_STASH_DIR}"
      then
         case "$1" in
            "/")
               # filename="${filename}"
               # fallback_filename="${fallback_filename}"
            ;;

            /*/)
               _configfile="$1${filename}"
               if [ ! -z "${fallback_filename}" ]
               then
                  _fallback_configfile="$1${fallback_filename}"
               fi
            ;;

            *)
               _configfile="$1/${filename}"
               if [ ! -z "${fallback_filename}" ]
               then
                  _fallback_configfile="$1/${fallback_filename}"
               fi
            ;;
         esac
      fi

      if [ -z "${_configfile}" ]
      then
         #
         # figure out actual _configfile _configfile
         # need not exist
         #
         case "$1" in
            "#/"*)  # hack for copy command for absolute names
               _configfile="${1#\#}/${filename}"
               if [ ! -z "${fallback_filename}" ]
               then
                  _fallback_configfile="${1#\#}/${fallback_filename}"
               fi
            ;;

            "/")
               _configfile="${MULLE_VIRTUAL_ROOT}/${filename}"
               if [ ! -z "${fallback_filename}" ]
               then
                  _fallback_configfile="${MULLE_VIRTUAL_ROOT}/${fallback_filename}"
               fi
            ;;

            /*/)
               _configfile="${MULLE_VIRTUAL_ROOT}$1${filename}"
               if [ ! -z "${fallback_filename}" ]
               then
                  _fallback_configfile="${MULLE_VIRTUAL_ROOT}$1${fallback_filename}"
               fi
            ;;

            /*)
               _configfile="${MULLE_VIRTUAL_ROOT}$1/${filename}"
               if [ ! -z "${fallback_filename}" ]
               then
                  _fallback_configfile="${MULLE_VIRTUAL_ROOT}$1/${fallback_filename}"
               fi
            ;;

            *)
               _internal_fail "database \"$1\" must start with '/'"
            ;;
         esac
      fi

      case "${scope}" in
         'default')
            if [ -f "${_configfile}.${MULLE_UNAME}" ]
            then
               _configfile="${_configfile}.${MULLE_UNAME}"
            fi
            if [ ! -z "${_fallback_configfile}" -a -f "${_fallback_configfile}.${MULLE_UNAME}"  ]
            then
               _fallback_configfile="${_fallback_configfile}.${MULLE_UNAME}"
            fi
         ;;

         'global')
         ;;

         # address custom scope (don't check for existance here)
         *)
            _configfile="${_configfile}.${scope}"
            if [ ! -z "${_fallback_configfile}" ]
            then
               _fallback_configfile="${_fallback_configfile}.${scope}"
            fi
         ;;
      esac

      #
      # if there are more names to search and there are no files here
      # keep going
      #
      if [ "$name" != "${lastname}" ]
      then
         if [ ! -f "${_configfile}" -a ! -f "${_fallback_configfile}" ]
         then
            continue
         fi
      fi

      break # found something
   done

   IFS="${DEFAULT_IFS}"

   [ -z "${_configfile}" ] && _internal_fail "_configfile must not be empty"
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
                  _rootdir="$(sed 's|/$||g' <<< "$1")"
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
         _rootdir="${MULLE_VIRTUAL_ROOT}/$(sed 's|/$||g' <<< "$1")"
      ;;

      /*)
         _rootdir="${MULLE_VIRTUAL_ROOT}/$1"
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
sourcetree::cfg::r_config_exists()
{
   log_entry "sourcetree::cfg::r_config_exists" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$1"

   if [ -f "${_configfile}" ]
   then
      log_debug "\"${_configfile}\" exists"
      RVAL="${_configfile}"
      return 0
   fi

   if [ ! -z "${_fallback_configfile}" ] && [ -f "${_fallback_configfile}" ]
   then
      log_debug "\"${_fallback_configfile}\" exists"
      RVAL="${_fallback_configfile}"
      return 0
   fi

   log_debug "\"${_configfile}\" not found"
   RVAL=
   return 1
}


sourcetree::cfg::timestamp()
{
   log_entry "sourcetree::cfg::timestamp" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$1"

   if [ -f "${_configfile}" ]
   then
      modification_timestamp "${_configfile}"
      return $?
   fi

   if [ ! -z "${_fallback_configfile}" ] && [ -f "${_fallback_configfile}" ]
   then
      modification_timestamp "${_fallback_configfile}"
      return $?
   fi
}


sourcetree::cfg::__resolve_configfile()
{
   if [ -f "${_configfile}" ]
   then
      _configfile="${_configfile}"
      return 0
   fi

   if [ ! -z "${_fallback_configfile}" ] && [ -f "${_fallback_configfile}" ]
   then
      _configfile="${_fallback_configfile}"
      return 0
   fi

   log_debug "No config file \"${_configfile#${MULLE_USER_PWD}/}\" or \"${_fallback_configfile#${MULLE_USER_PWD}/}\" found (${PWD#${MULLE_USER_PWD}/})"
   _configfile=
   return 1
}


#
# egrep return values 0: has lines
#                     1: no lines
#                     2: error
#
sourcetree::cfg::__read()
{
   log_debug "Read config file \"${_configfile#${MULLE_USER_PWD}/}\" (${PWD#${MULLE_USER_PWD}/})"
   egrep -s -v '^#' "${_configfile}"
}

sourcetree::cfg::__fallback_read()
{
   log_debug "Read fallback config file \"${_fallback_configfile#${MULLE_USER_PWD}/}\" (${PWD#${MULLE_USER_PWD}/})"
   egrep -s -v '^#' "${_fallback_configfile}"
}


sourcetree::cfg::read()
{
   log_entry "sourcetree::cfg::read" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$1" "" "$2"

   if ! sourcetree::cfg::__resolve_configfile
   then
      return 1
   fi

   sourcetree::cfg::__read
}


sourcetree::cfg::write()
{
   log_entry "sourcetree::cfg::write" "$@"

   [ -z "${MULLE_SOURCETREE_ETC_DIR}" ] && _internal_fail "MULLE_SOURCETREE_ETC_DIR is empty"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$1" "w"
   shift

   r_mkdir_parent_if_missing "${_configfile}"

   if ! redirect_exekutor "${_configfile}" printf "%s\n" "$*"
   then
      exit 1
   fi
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


#
# local _configfile
# local _fallback_configfile
#
sourcetree::cfg::_copy_to_etc_if_needed()
{
   log_entry "sourcetree::cfg::_copy_to_etc_if_needed" "$@"

   if [ ! -f "${_configfile}" -a -f "${_fallback_configfile}" ]
   then
      r_mkdir_parent_if_missing "${_configfile}"
      exekutor cp "${_fallback_configfile}" "${_configfile}" || exit 1
      exekutor chmod +w "${_configfile}" || exit 1
   fi
}


sourcetree::cfg::remove_nodeline()
{
   log_entry "sourcetree::cfg::remove_nodeline" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$1" "w"

   sourcetree::cfg::_copy_to_etc_if_needed

   local address="$2"

   local escaped

   log_debug "Removing \"${address}\" from  \"${_configfile}\""
   r_escaped_sed_pattern "${address}"
   escaped="${RVAL}"

   # linux don't like space after -i
   if ! inplace_sed -e "/^${escaped};/d" "${_configfile}"
   then
      _internal_fail "sed address corrupt ?"
   fi
}


sourcetree::cfg::remove_nodeline_by_uuid()
{
   log_entry "sourcetree::cfg::remove_nodeline_by_uuid" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$1" "w"

   sourcetree::cfg::_copy_to_etc_if_needed

   local uuid="$2"

   local escaped

   log_debug "Removing \"${uuid}\" from \"${_configfile}\""

   r_escaped_sed_pattern "${uuid}"
   escaped="${RVAL}"

   # linux don't like space after -i
   if ! inplace_sed -e "/^[^;]*;[^;]*;[^;]*;${escaped};/d" "${_configfile}"
   then
      _internal_fail "sed address corrupt ?"
   fi
}


sourcetree::cfg::file_remove()
{
   log_entry "sourcetree::cfg::file_remove" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$1" "w"

   remove_file_if_present "${_configfile}"
}


#
# This is in a fallback situation probably not the best idea, because then
# you couldn't remove everything. Depends though. So lets say if there is
# a fallback, then we don't otherwise we do. We can also remove if the
# fallback is identical to what we have now (win!)
#
sourcetree::cfg::remove_if_empty_and_no_fallback_exists()
{
   log_entry "sourcetree::cfg::remove_if_empty_and_no_fallback_exists" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$1" "w"

   local current_contents

   current_contents="`sourcetree::cfg::__read`"

   # if we have a fallback, then _configfile is not needed if the contents
   # are identical
   if [ ! -z "${_fallback_configfile}" ]
   then
      local fallback_contents

      fallback_contents="`sourcetree::cfg::__fallback_read`"
      if [ "${current_contents}" != "${fallback_contents}" ]
      then
         return
      fi
      log_debug "Safe to remove as contents of fallback and config are identical"
   else
      log_debug "No fallback configured"

      # With no fallback an empty _configfile is not needed
      if [ ! -z "${current_contents}" ]
      then
         return
      fi
   fi

   remove_file_if_present "${_configfile}"
   r_dirname "${_configfile}"
   rmdir_if_empty "${RVAL}"
}


sourcetree::cfg::change_nodeline()
{
   log_entry "sourcetree::cfg::change_nodeline" "$@"

   local _configfile
   local _fallback_configfile

   sourcetree::cfg::__common_configfile "$1" "w"

   sourcetree::cfg::_copy_to_etc_if_needed

   local oldnodeline="$2"
   local newnodeline="$3"

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

   log_debug "Editing \"${_configfile}\""

   # linux don't like space after -i
   if ! inplace_sed -e "s/^${oldescaped}$/${newescaped}/" "${_configfile}"
   then
      fail "Edit of config file failed unexpectedly"
   fi
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

   _log_debug "Searching for config \"${SOURCETREE_CONFIG_NAMES}\" \
(\"$SOURCETREE_CONFIG_DIR:$SOURCETREE_FALLBACK_CONFIG_DIR\") \
from \"${physdirectory}\" to \"${physceiling}\""

   (
      cd "${physdirectory}" || exit 1

      local _configfile
      local _fallback_configfile

      while :
      do
         sourcetree::cfg::__common_configfile "${SOURCETREE_START}"

         if [ ! -z "${_configfile}" -o ! -z "${_fallback_configfile}" ]
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
         if sourcetree::cfg::r_config_exists "${SOURCETREE_START}"
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
   local _configfile
   local _fallback_configfile

   while parent="`sourcetree::cfg::get_parent "${_rootdir}" `"
   do
      [ "${parent}" = "${_rootdir}" ] \
         && _internal_fail "${parent} endless loop"

      sourcetree::cfg::__common_configfile "${SOURCETREE_START}"

      # don't touch the fallback
      if [ -f "${_configfile}" ]
      then
         exekutor touch -f "${_configfile}"
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


sourcetree::cfg::r_absolute_filename()
{
   log_entry "sourcetree::cfg::r_absolute_filename" "$@"

   local config="$1"
   local address="$2"
   local style="$3"

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
   if [ "${config#${MULLE_SOURCETREE_STASH_DIR}}" != "${config}" ]
   then
      RVAL="${config}${address}"
   else
      RVAL="${MULLE_VIRTUAL_ROOT}${config}${address}"
   fi
}

