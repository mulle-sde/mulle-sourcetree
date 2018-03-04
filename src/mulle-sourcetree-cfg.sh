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
   [ -z "${SOURCETREE_CONFIG_FILE}" ]     && internal_fail "SOURCETREE_CONFIG_FILE is not set"
   [ -z "${MULLE_VIRTUAL_ROOT}" ]         && internal_fail "MULLE_VIRTUAL_ROOT is not set"

   case "${MULLE_SOURCETREE_SHARE_DIR}" in
      /*)
         if string_has_prefix "$1" "${MULLE_SOURCETREE_SHARE_DIR}"
         then
            case "$1" in
               "/")
                  configfile="${SOURCETREE_CONFIG_FILE}"
               ;;

               /*/)
                  configfile="$1${SOURCETREE_CONFIG_FILE}"
               ;;

               *)
                  configfile="$1/${SOURCETREE_CONFIG_FILE}"
               ;;
            esac
            return
         fi
      ;;
   esac

   case "$1" in
      "/")
         configfile="${MULLE_VIRTUAL_ROOT}/${SOURCETREE_CONFIG_FILE}"
      ;;

      /*/)
         configfile="${MULLE_VIRTUAL_ROOT}$1${SOURCETREE_CONFIG_FILE}"
      ;;

      /*)
         configfile="${MULLE_VIRTUAL_ROOT}$1/${SOURCETREE_CONFIG_FILE}"
      ;;

      *)
         internal_fail "database \"$1\" must start with '/'"
      ;;
   esac
}


__cfg_common_rootdir()
{
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT is not set"

   case "${MULLE_SOURCETREE_SHARE_DIR}" in
      /*)
         if string_has_prefix "$1" "${MULLE_SOURCETREE_SHARE_DIR}"
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
         internal_fail "configfile \"$1\" must start with '/'"
      ;;
   esac
}


cfg_rootdir()
{
   local rootdir

   __cfg_common_rootdir "$1"
   echo "${rootdir}"
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

   local configfile

   __cfg_common_configfile "$@"
   shift

   mkdir_if_missing "${MULLE_SOURCETREE_ETC_DIR}"
   redirect_exekutor "${SOURCETREE_CONFIG_FILE}" echo "$*"
}


cfg_get_nodeline()
{
   log_entry "cfg_get_nodeline" "$@"

   local address="$2"

   local nodelines

   nodelines="`cfg_read "$1"`"
   nodeline_find "${nodelines}" "${address}"
}


cfg_get_nodeline_by_url()
{
   log_entry "cfg_get_nodeline_by_url" "$@"

   local address="$2"

   local nodelines

   nodelines="`cfg_read "$1"`"
   nodeline_find "${nodelines}" "${address}"
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
   escaped="`escaped_sed_pattern "${address}"`"
   # linux don't like space after -i
   if ! exekutor sed -i'' -e "/^${escaped};/d" "${configfile}"
   then
      internal_fail "sed address corrupt ?"
   fi
}


cfg_remove_nodeline_by_url()
{
   log_entry "cfg_remove_nodeline_by_url" "$@"

   local configfile

   __cfg_common_configfile "$@"

   local url="$2"

   local escaped

   log_debug "Removing \"${url}\" from \"${configfile}\""
   escaped="`escaped_sed_pattern "${url}"`"
   # linux don't like space after -i
   if ! exekutor sed -i'' -e "/^[^;]*;[^;]*[^;]*[^;]*${escaped};/d" "${configfile}"
   then
      internal_fail "sed address corrupt ?"
   fi
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

   oldescaped="`escaped_sed_pattern "${oldnodeline}"`"
   newescaped="`escaped_sed_pattern "${newnodeline}"`"

   log_debug "Editing \"${SOURCETREE_CONFIG_FILE}\""

   # linux don't like space after -i
   if ! exekutor sed -i'' -e "s/^${oldescaped}$/${newescaped}/" "${configfile}"
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

   local directory="$1"

   [ -z "${directory}" ] && internal_fail "empty directory"

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

   ceiling="`physicalpath "${ceiling}"`"
   directory="`physicalpath "${directory}"`"

   local relative

   relative="`symlink_relpath "${directory}" "${ceiling}"`"
   case "${relative}" in
      ..*)
         log_debug "Start is now outside of the ceiling"
         return 1
      ;;
   esac

   log_debug "Searching for configfile from \"${directory}\" to \"${ceiling}\""

   (
      cd "${directory}" &&
      while ! cfg_exists "${SOURCETREE_START}"
      do
         # since we do physical paths, PWD is ok here
         if [ "${PWD}" = "${ceiling}" ]
         then
            log_debug "Touched the ceiling"
            exit 1
         fi &&
         cd ..
      done &&

      log_debug "Found \"${PWD}\""
      echo "${PWD}"
   )
}



#
# Return the directory, that we should be using for the following defer
# possibilities. The returned directory is always a physical patha
#
# NONE:    do not search
# NEAREST: search up until we find a sourcetree
# PARENT:  get the enveloping sourcetree of PWD (even if PWD has a sourcetree)
# ROOT:    get the outermost enveloping sourcetree (can be PWD)
#
cfg_determine_working_directory()
{
   log_entry "cfg_determine_working_directory" "$@"

   local preference="$1"
   local deferflag="$2"

   local directory
   local parent
   local found
   local defer

   if [ -z "${MULLE_PATH_SH}" ]
   then
      fail "need mulle-path.sh for this to work"
   fi

   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
      fail "need mulle-sourcetree-db.sh for this to work"
   fi

   defer="${deferflag}"
   if [ "${defer}" = "DEFAULT" ]
   then
      defer="${preference}"
   fi

   case "${defer}" in
      NONE)
         if cfg_exists "${SOURCETREE_START}"
         then
            pwd -P
            return 0
         fi

         log_debug "No config found or db found"
         return 1
      ;;

      NEAREST)
         directory="`cfg_search_for_configfile "${PWD}"`"
         if [ $? -ne 0 ]
         then
            log_debug "No config found or db found"
            return 1
         fi
         echo "${directory}"
         return 0
      ;;

      # not sure when this is useful
      PARENT)
         directory="`cfg_search_for_configfile "${PWD}"`"
         if [ $? -ne 0 ]
         then
            log_debug "No config found or db found"
            return 1
         fi

         if [ "${directory}" != "`pwd -P`" ]
         then
            echo "${directory}"
            return 0
         fi

         parent="`fast_dirname "${directory}"`"
         directory="`cfg_search_for_configfile "${parent}"`"
         if [ $? -eq 0 ]
         then
            echo "${directory}"
            return 0
         fi

         log_debug "No parent found"
         return 1
      ;;

      ROOT)
         directory="`cfg_search_for_configfile "${PWD}"`"
         if [ $? -ne 0 ]
         then
            log_debug "No config found"
            return 1
         fi

         while :
         do
            found="${directory}"
            parent="`fast_dirname "${directory}"`"
            if [ "${parent}" = "${SOURCETREE_START}" ]
            then
               break
            fi

            directory="`cfg_search_for_configfile "${parent}"`"
            if [ $? -ne 0 ]
            then
               break
            fi
         done

         echo "${found}"
         return 0
      ;;

      *)
         internal_fail "unknown defer type \"${defer}\""
      ;;
   esac

   return 1
}


cfg_defer_if_needed()
{
   log_entry "cfg_defer_if_needed" "$@"

   local preference="$1"
   local defer="$2"

   local directory

   if directory="`cfg_determine_working_directory "${preference}" "${defer}"`"
   then
      if [ "${directory}" != "`pwd -P`" ]
      then
         log_info "Using \"${directory}\" as sourcetree root"
         exekutor cd "${directory}"
      fi
   fi
}


cfg_absolute_filename()
{
   log_entry "cfg_absolute_filename" "$@"

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
