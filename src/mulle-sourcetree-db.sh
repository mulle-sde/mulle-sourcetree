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
MULLE_SOURCETREE_DB_SH="included"


#
#
#
_db_nodeline()
{
   head -1
}


_db_owner()
{
   sed -n '2p'
}


_db_filename()
{
   sed -n '3p'
}


_db_evaledurl()
{
   tail -1
}


__db_common_sharedir()
{
   case "${MULLE_SOURCETREE_STASH_DIR}" in
      /*)
         if string_has_prefix "$1" "${MULLE_SOURCETREE_STASH_DIR}"
         then
            case "$1" in
               "/")
                  _rootdir="$1"
               ;;

               /*//)
                  __db_common_sharedir "${1%/}"
               ;;

               /*/)
                  _rootdir="${1%/}"
               ;;

               *)
                  _rootdir="$1"
               ;;
            esac
            return 0
         fi
      ;;
   esac

   return 1
}


__db_common___rootdir()
{
   case "$1" in
      "/")
         _rootdir="${MULLE_VIRTUAL_ROOT}"
      ;;

      /*//)
         __db_common___rootdir "${1%/}"
      ;;

      /*/)
         _rootdir="${MULLE_VIRTUAL_ROOT}/${1%/}"
      ;;

      /*)
         _rootdir="${MULLE_VIRTUAL_ROOT}/$1"
      ;;

      *)
         internal_fail "_database \"$1\" must start with '/'"
      ;;
   esac
}


__db_common__rootdir()
{
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT is not set"

   if __db_common_sharedir "$1"
   then
      return
   fi

   __db_common___rootdir "$1"
}


#
# local _database
# local _databasedir
#
__db_common_databasedir()
{
   [ -z "${SOURCETREE_DB_FILENAME}" ] && internal_fail "SOURCETREE_DB_FILENAME is not set"
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT is not set"

   _database="$1"  # not a local!

   case "${MULLE_SOURCETREE_STASH_DIR}" in
      /*)
         if string_has_prefix "${_database}" "${MULLE_SOURCETREE_STASH_DIR}"
         then
            case "${_database}" in
               "/")
                  _databasedir="${SOURCETREE_DB_FILENAME}"
               ;;

               /*/)
                  _databasedir="${_database}${SOURCETREE_DB_FILENAME}"
               ;;

               *)
                  _databasedir="${_database}/${SOURCETREE_DB_FILENAME}"
               ;;
            esac
            return
         fi
      ;;
   esac

   case "${_database}" in
      "/")
         _databasedir="${MULLE_VIRTUAL_ROOT}/${SOURCETREE_DB_FILENAME}"
      ;;

      /*/)
         _databasedir="${MULLE_VIRTUAL_ROOT}${_database}${SOURCETREE_DB_FILENAME}"
      ;;

      /*)
         _databasedir="${MULLE_VIRTUAL_ROOT}${_database}/${SOURCETREE_DB_FILENAME}"
      ;;

      *)
         internal_fail "_database \"${_database}\" must start with '/'"
      ;;
   esac
}


#
# local _uuid
#
__db_common_uuid()
{
   _uuid="$1"

   if [ ! -z "${_uuid}" ]
   then
      return 0
   fi

   internal_fail "Empty uuid"
}


#
# local _database
# local _databasedir
# local _uuid
#
__db_common_databasedir_uuid()
{
   __db_common_databasedir "$1"
   __db_common_uuid "$2"
}


__db_common_dbfilepath()
{
   local databasedir="$1"
   local uuid="$2"

   dbfilepath="${databasedir}/${uuid}"
   if [ ! -f "${dbfilepath}" ]
   then
      log_debug "No address found for ${uuid} in ${databasedir}"
      return 1
   fi
   log_debug "Found \"${dbfilepath}\""
   return 0
}


db_memorize()
{
   log_entry "db_memorize" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local uuid="$2"
   local nodeline="$3"
   local owner="$4"
   local filename="$5"
   local evaledurl="$6"

   [ -z "${nodeline}" ] && internal_fail "nodeline is missing"
   [ -z "${uuid}" ]     && internal_fail "uuid is missing"
   [ -z "${filename}" ] && internal_fail "filename is missing"

#   case "${owner}" in
#      .*/)
#         internal_fail "owner starts with \".\""
#      ;;
#   esac

   case "${filename}" in
      /*)
#         if [ "${MULLE_UNAME}" = "darwin" ]
#         then
#            internal_fail "non physical path"
#         fi
      ;;

      "")
      ;;

      *)
         internal_fail "filename \"${filename}\" must be absolute"
      ;;
   esac

   local content
   local dbfilepath

   mkdir_if_missing "${_databasedir}"
   dbfilepath="${_databasedir}/${uuid}"

   content="${nodeline}
${owner}
${filename}
${evaledurl}"

   log_debug "Remembering uuid \"${uuid}\" ($_databasedir)"

   redirect_exekutor "${dbfilepath}" printf "%s\n" "${content}"
}


db_recall()
{
   log_entry "db_recall" "$@"

   local _database
   local _databasedir
   local _uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if ! __db_common_dbfilepath "${_databasedir}" "${_uuid}"
   then
      return 1
   fi

   cat "${dbfilepath}"
}


db_forget()
{
   log_entry "db_forget" "$@"

   local _database
   local _databasedir
   local _uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if __db_common_dbfilepath "${_databasedir}" "${_uuid}"
   then
      log_debug "Forgetting about uuid \"${_uuid}\" ($_databasedir)"
      remove_file_if_present "${dbfilepath}"
   fi
}


#
# This buries a directory in the project by moving it into the graveyard.
#
# it must have been ascertained that filename is not in use by other nodes
# filename is relative to _database here
#
db_bury()
{
   log_entry "db_bury" "$@"

   local _database
   local _databasedir
   local _uuid

   __db_common_databasedir_uuid "$@"

   local filename="$3"

   [ $# -eq 3 ] || internal_fail "api error"
   [ -z "${filename}" ] && internal_fail "filename is empty"

   local gravepath
   local graveyard

   r_dirname "${_databasedir}"
   graveyard="${RVAL}/graveyard"
   gravepath="${graveyard}/${_uuid}"

   local _rootdir

   __db_common__rootdir "${_database}"

   case "${filename}" in
      /*)
      ;;

      *)
         internal_fail "filename \"${filename}\" must be absolute"
      ;;
   esac

# do removal now in action, we just skip this
    if [ -L "${filename}" ]
    then
#      log_verbose "Removing old symlink \"${filename}\""
#      exekutor rm -f "${filename}" >&2
      log_fluff "\"${filename}\" is a symlink so skipped"
      return
   fi

   if [ ! -e "${filename}" ]
   then
      log_fluff "\"${filename}\" vanished or never existed ($_databasedir)"
      return
   fi

   if [ "${MULLE_SOURCETREE_GRAVEYARD_ENABLED:-YES}" = 'NO' ]
   then
      if [ -d "${filename}" ]
      then
         rmdir_safer  "${filename}"
      else
         remove_file_if_present "${filename}"
      fi
      return $?
   fi

   #
   # protect from catastrophies
   #
   local project_dir

   [ -z "${SOURCETREE_DB_FILENAME_RELATIVE}" ] \
      && internal_fail "SOURCETREE_DB_FILENAME_RELATIVE is empty"


   r_simplified_absolutepath "${_databasedir}/${SOURCETREE_DB_FILENAME_RELATIVE}"
   project_dir="${RVAL}"

   r_simplified_absolutepath "${filename}"
   filename="${RVAL}"

   local phys_filename
   local phys_project_dir

   r_physicalpath "${filename}"
   phys_filename="${RVAL}"

   r_physicalpath "${project_dir}"
   phys_project_dir="${RVAL}"

   r_relative_path_between "${phys_filename}" "${phys_project_dir}"

   case "${RVAL}" in
      ../*)
         internal_fail "Bury path for \"${filename#${MULLE_USER_PWD}/}\" escapes \
project \"${project_dir#${MULLE_USER_PWD}/}\".
${C_INFO}If you recently renamed your project, this is not unusual. 
You need to clean it up manually (sorry). Suggested fix:
${C_RESET_BOLD} rm -rf .mulle/var kitchen stash dependency"
      ;;
   esac

   log_debug "project_dir: ${project_dir}"
   log_debug "filename:    ${filename}"
   log_debug "relative:    ${RVAL}"

   if [ -e "${gravepath}" ]
   then
      local otheruuid
      local othergravepath

      r_node_uuidgen
      otheruuid="${RVAL}"
      othergravepath="${graveyard}/${otheruuid}"

      log_fluff "Moving old grave with same uuid \"${gravepath}\" to \"${othergravepath}\""
      exekutor mv "${gravepath}" "${othergravepath}"
   else
      mkdir_if_missing "${graveyard}"
   fi

   #
   # if we have tar available, we archive the grave, because it takes less space
   # and we also don't accidentally find files in it. Otherwise at least write
   # protect to prevent accidental "surprise" edits.
   #
   TAR="`command -v "tar"`"
   if [ ! -z "${TAR}" -a -d "${gravepath}" ]
   then
      log_info "Burying charred \
${C_MAGENTA}${C_BOLD}${filename#${MULLE_USER_PWD}/}${C_INFO} in grave \
\"${gravepath#${MULLE_VIRTUAL_ROOT}/}\""
      exekutor mv ${OPTION_COPYMOVEFLAGS} "${filename}" "${gravepath}.tmp" >&2 &&
      (
         rexekutor cd "${gravepath}.tmp" &&
         exekutor "${TAR}" cfz "${gravepath}" . &&
         rmdir_safer "${gravepath}.tmp"
      ) &
   else
      log_info "Burying \
${C_MAGENTA}${C_BOLD}${filename#${MULLE_USER_PWD}/}${C_INFO} in grave \
\"${gravepath#${MULLE_VIRTUAL_ROOT}/}\""
      exekutor mv ${OPTION_COPYMOVEFLAGS} "${filename}" "${gravepath}" >&2
      exekutor find "${gravepath}" -type f -exec chmod a-w {} \;
   fi
}


#
# the owner is unused it seems
#
__db_parse_dbentry()
{
   log_entry "__db_parse_dbentry" "$@"

   local dbentry="$1"

   if [ -z "${dbentry}" ]
   then
      return 1
   fi

   while read -r nodeline
   do
      read -r owner
      read -r filename
      read -r evaledurl
      break
   done <<< "${dbentry}"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "\
nodeline  : ${nodeline}
owner     : ${owner}
filename  : ${filename}
evaledurl : ${evaledurl}"
   fi
}


# __db_recall_dbentry()
# {
#    log_entry "__db_recall_dbentry" "$@"
#
#    local _database="$1"
#    local uuid="$2"
#
#    local dbentry
#
#    dbentry="`db_recall "${_database}" "${uuid}"`"
#    __db_parse_dbentry "${dbentry}"
# }


db_get__rootdir()
{
   local _rootdir

   __db_common__rootdir "$1"
   printf "%s\n" "${_rootdir}"
}


db_fetch_nodeline_for_uuid()
{
   log_entry "db_fetch_nodeline_for_uuid" "$@"

   local _database
   local _databasedir
   local _uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if ! __db_common_dbfilepath "${_databasedir}" "${_uuid}"
   then
      return 1
   fi

   _db_nodeline <"${dbfilepath}"
}


#db_fetch_owner_for_uuid()
#{
#   log_entry "db_fetch_owner_for_uuid" "$@"
#
#   local _database
#   local _databasedir
#   local uuid
#
#   __db_common_databasedir_uuid "$@"
#
#   local dbfilepath
#
#   if ! __db_common_dbfilepath "${_databasedir}" "${uuid}"
#   then
#      return 1
#   fi
#
#   _db_owner < "${dbfilepath}"
#}

db_fetch_filename_for_uuid()
{
   log_entry "db_fetch_filename_for_uuid" "$@"

   local _database
   local _databasedir
   local _uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if ! __db_common_dbfilepath "${_databasedir}" "${_uuid}"
   then
      return 1
   fi

   _db_filename < "${dbfilepath}"
}


db_fetch_evaledurl_for_uuid()
{
   log_entry "db_fetch_evaledurl_for_uuid" "$@"

   local _database
   local _databasedir
   local _uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if ! __db_common_dbfilepath "${_databasedir}" "${_uuid}"
   then
      return 1
   fi

   _db_evaledurl < "${dbfilepath}"
}


db_fetch_all_uuids()
{
   log_entry "db_fetch_all_uuids" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   ( cd "${_databasedir}" ; ls -1 ) 2> /dev/null
}


db_fetch_all_nodelines()
{
   log_entry "db_fetch_all_nodelines" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local i

#   if shopt -poq noglob
#   then
#      internal_fail "noglob should be off"
#   fi

   shell_enable_nullglob
   for i in "${_databasedir}"/*
   do
      head -1 "${i}" || internal_fail "malformed file $i"
   done
   shell_disable_nullglob
}


db_fetch_uuid_for_address()
{
   log_entry "db_fetch_uuid_for_address" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local address="$2"

   [ -z "${address}" ] && internal_fail "address is empty"

   if dir_has_files "${_databasedir}" f
   then
      local pattern

      r_escaped_grep_pattern "${address}"
      pattern="${RVAL}"
      egrep -s "^${pattern};" "${_databasedir}"/* | cut -s '-d;' -f 4
   fi
}


r_db_fetch_uuid_for_evaledurl()
{
   log_entry "r_db_fetch_uuid_for_evaledurl" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local searchurl="$2"

   [ -z "${searchurl}" ] && internal_fail "url is empty"

   if ! dir_has_files "${_databasedir}" f
   then
      RVAL=
      return 1
   fi

   local evaledurl
   local candidate

   IFS=$'\n'
   for candidate in `( fgrep -l -x -s -e "${searchurl}" "${_databasedir}"/* )`
   do
      IFS="${DEFAULT_IFS}"

      evaledurl="`_db_evaledurl < "${candidate}" `"
      if [ "${searchurl}" = "${evaledurl}" ]
      then
         r_basename "${candidate}"
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}"

   RVAL=
   return 1
}

# unused
# db_fetch_uuid_for_filename()
# {
#    log_entry "db_fetch_uuid_for_filename" "$@"
#
#    local _database
#    local _databasedir
#
#    __db_common_databasedir "$@"
#
#    local searchurl="$2"
#
#    [ -z "${searchfilename}" ] && internal_fail "filename is empty"
#
#    if ! dir_has_files "${_databasedir}" f
#    then
#       return 1
#    fi
#
#    (
#       local filename
#       local candidate
#
#       cd "${_databasedir}"
#       IFS=$'\n'
#       for candidate in `fgrep -l -x -s -e "${searchfilename}" *`
#       do
#          IFS="${DEFAULT_IFS}"
#
#          filename="`_db_filename < "${candidate}" `"
#          if [ "${searchfilename}" = "${filename}" ]
#          then
#             printf "%s\n" "${candidate}"
#             exit 0
#          fi
#       done
#       exit 1
#    )
#
#    return 1
# }


db_fetch_all_filenames()
{
   log_entry "db_fetch_all_filenames" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   (
      shell_enable_nullglob

      local i

      for i in "${_databasedir}"/*
      do
         _db_filename < "${i}"
      done
   )
}


#
# the user will use filename to retrieve stuff later
#
db_set_memo()
{
   log_entry "db_set_memo" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$1"

   local filename

   filename="${_databasedir}/.db_memo"
   remove_file_if_present "${filename}"

   local nodelines="$2"

   redirect_exekutor "${filename}" printf "%s\n" "${nodelines}"

   printf "%s\n" "${filename}"
}


db_add_memo()
{
   log_entry "db_add_memo" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$1"

   local nodelines="$2"

   redirect_append_exekutor "${_databasedir}/.db_memo" printf "%s\n" "${nodelines}"
}


db_add_missing()
{
   log_entry "db_add_missing" "$@"

   local _database
   local _databasedir
   local _uuid

   __db_common_databasedir_uuid "$@"

   local nodeline="$3"

   mkdir_if_missing "${_databasedir}/.missing"
   redirect_exekutor "${_databasedir}/.missing/${_uuid}" printf "%s\n" "${nodeline}"
}

#
# dbtype
#

_db_get_dbtype()
{
   log_entry "_db_get_dbtype" "$@"

   local databasedir="$1"

   # for -e tests
   if ! head -1 "${databasedir}/.db_type" 2> /dev/null
   then
      log_fluff "\"${databasedir}/.db_type\" is missing"
      :
   fi
}


db_get_dbtype()
{
   log_entry "db_get_dbtype" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   # for -e tests
   _db_get_dbtype "${_databasedir}"
}


db_set_dbtype()
{
   log_entry "db_set_dbtype" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local dbtype="$2"

   [ -z "${dbtype}" ] && internal_fail "type is missing"

   mkdir_if_missing "${_databasedir}"
   redirect_exekutor "${_databasedir}/.db_type"  printf "%s\n" "${dbtype}"
}


db_clear_dbtype()
{
   log_entry "db_clear_dbtype" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   remove_file_if_present "${_databasedir}/.db_type"
}


db_is_recurse()
{
   log_entry "db_is_recurse" "$@"

   case "`db_get_dbtype "$@"`" in
      share|recurse)
         return 0
      ;;
   esac

   return 1
}


#
# dbstate
# these can be prefixed with ${_database} to query inferior db state
# if there is some kind of .db file there we assume that's a _database
# otherwise it's just a graveyard
#
db_dir_exists()
{
   log_entry "db_dir_exists" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   if [ -d "${_databasedir}" ]
   then
      log_debug "\"${_databasedir}\" exists"
      return 0
   else
      log_debug "\"${_databasedir}\" not found"
      return 1
   fi
}


__db_environment()
{
   printf "%s\n" "${_databasedir}
${MULLE_SOURCETREE_STASH_DIR}"
}


db_environment()
{
   log_entry "db_is_ready" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   printf "%s\n" "${_databasedir}
${MULLE_SOURCETREE_STASH_DIR}"
}


db_exists()
{
   log_entry "db_exists" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   [ -d "${_databasedir}" ]
}


db_is_ready()
{
   log_entry "db_is_ready" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local dbdonefile

   dbdonefile="${_databasedir}/.db_done"

   local oldenvironment
   local environment

   if ! oldenvironment="`cat "${dbdonefile}" 2> /dev/null`"
   then
      log_debug "\"${dbdonefile}\" not found (${_databasedir})"
      return 1
   fi
   environment="`__db_environment`"

   if [ "${oldenvironment}" != "${environment}" ]
   then
      log_debug "\"${_database}\" was made in a different environment. Needs reset"
      log_debug "Current environment : ${environment}"
      log_debug "Old environment     : ${oldenvironment}"
      return 2
   fi

   return 0
}


db_set_ready()
{
   log_entry "db_set_ready" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   mkdir_if_missing "${_databasedir}"
   redirect_exekutor "${_databasedir}/.db_done" __db_environment
}


# never
db_clear_ready()
{
   log_entry "db_clear_ready" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   remove_file_if_present "${_databasedir}/.db_done"
}


db_get_timestamp()
{
   log_entry "db_get_timestamp" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   if [ -f "${_databasedir}/.db_done" ]
   then
      modification_timestamp "${_databasedir}/.db_done"
   fi
}


#
# update
#
db_is_updating()
{
   log_entry "db_is_updating" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   if [ -f "${_databasedir}/.db_update" ]
   then
      log_debug "\"${_databasedir}/.db_done\" exists"
      return 0
   fi

   log_debug "\"${_databasedir}/.db_update\" not found"
   return 1
}


db_set_update()
{
   log_entry "db_set_update" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   mkdir_if_missing "${_databasedir}"
   redirect_exekutor "${_databasedir}/.db_update" \
      echo "# intentionally left blank"
}


db_clear_update()
{
   log_entry "db_clear_update" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   remove_file_if_present "${_databasedir}/.db_update"
}


db_set_shareddir()
{
   log_entry "db_set_shareddir" "$@"

   [ $# -eq 2 ] || internal_fail "api error"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local shareddir="$2"

   # empty is OK

   mkdir_if_missing "${_databasedir}"
   redirect_exekutor "${_databasedir}/.db_stashdir"  printf "%s\n" "${shareddir}"
}


db_clear_shareddir()
{
   log_entry "db_clear_shareddir" "$@"

   [ $# -eq 1 ] || internal_fail "api error"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   remove_file_if_present "${_databasedir}/.db_stashdir"
}


db_get_shareddir()
{
   log_entry "db_get_shareddir" "$@"

   [ $# -eq 1 ] || internal_fail "api error"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   if [ ! -f "${_databasedir}/.db_stashdir" ]
   then
      return 1
   fi
   rexekutor cat "${_databasedir}/.db_stashdir"
}


#
# If a previous update crashed, we want to let the user know.
#
db_ensure_consistency()
{
   log_entry "db_ensure_consistency" "$@"

   local database="$1"

   if db_is_updating "${database}" && [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
   then
      log_error "A previous update was incomplete.
Suggested resolution:
    ${C_RESET_BOLD}cd '${MULLE_VIRTUAL_ROOT}${_database}'${C_ERROR}
    ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} clean${C_ERROR}
    ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} reset${C_ERROR}
    ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} update${C_ERROR}

Or do you feel lucky ? Then try again with
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} -f ${MULLE_ARGUMENTS}${C_ERROR}
But you've gotta ask yourself one question: Do I feel lucky ?
Well, do ya, punk?"
      exit 1
   fi
}


#
# if DB is "" clean, then anything goes.
#
db_ensure_compatible_dbtype()
{
   log_entry "db_ensure_compatible_dbtype" "$@"

   local database="$1"
   local dbtype="$2"

   local actualdbtype

   actualdbtype="`db_get_dbtype "${database}"`"
   if [ -z "${actualdbtype}" -o "${actualdbtype}" = "${dbtype}" ]
   then
      return
   fi

   if [ "${actualdbtype}" = "flat" -a "${dbtype}" = "recurse" ]
   then
      if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
      then
         fail "Database in \"$PWD\" was constructed flat, not with the \
recurse option.
This is not really problem. Restate your intention with
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} -f ${MULLE_ARGUMENTS}${C_ERROR}
or append the -r flag for recurse."
      fi
      return
   fi

   fail "Database in \"$PWD\" was constructed as \"${actualdbtype}\".
If you want to change that to \"${dbtype}\" do:
   ${C_RESET_BOLD}cd '$PWD'${C_ERROR}
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} clean${C_ERROR}
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} reset${C_ERROR}
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} --${dbtype} update${C_ERROR}"
}


# sets external variables!!
_db_set_default_mode()
{
   log_entry "_db_set_default_mode" "$@"

   local database="$1"
   local usertype="$2"

   local actualdbtype

   actualdbtype="`db_get_dbtype "${database}"`"

   local _rootdir

   # que ??
   if [ ! -z "${actualdbtype}"  ]
   then
      __db_common__rootdir "${database}"
   fi

   local dbtype

   dbtype="${usertype}"
   if [ -z "${dbtype}" ]
   then
      dbtype="${actualdbtype}"
      if [ -z "${dbtype}" ]
      then
         dbtype="share"       # the default
      else
         r_simplified_absolutepath "${_rootdir}"
         log_fluff "Database: ${C_RESET_BOLD}${RVAL} ${C_MAGENTA}${C_BOLD}${actualdbtype}${C_INFO}"
      fi
   fi

   case "${dbtype}" in
      share|recurse|flat)
         SOURCETREE_MODE="${dbtype}"
      ;;

      partial)
         # partial means it's created by a parent share
         # but itself is not shared, but inherently partially recurse
         SOURCETREE_MODE="recurse"
      ;;

      no-share)
         SOURCETREE_MODE="recurse"
      ;;

      *)
         internal_fail "unknown dbtype \"${dbtype}\""
      ;;
   esac

   if [ ! -z "${SOURCETREE_MODE}" ]
   then
      log_debug "Mode: ${C_MAGENTA}${C_BOLD}${SOURCETREE_MODE}${C_INFO}"
      if [ "${SOURCETREE_MODE}" = share ]
      then
         [ -z "${MULLE_SOURCETREE_STASH_DIR}" ] && internal_fail "MULLE_SOURCETREE_STASH_DIR is empty"
         log_debug "Stash directory: ${C_RESET_BOLD}${MULLE_SOURCETREE_STASH_DIR}${C_INFO}"
      fi
   fi
}


db_has_graveyard()
{
   log_entry "db_has_graveyard" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   [ -d "${_databasedir}/../graveyard" ]
}


db_graveyard_dir()
{
   log_entry "db_has_graveyard" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   printf "%s\n" "${_databasedir}/../graveyard"
}


db_is_graveyard()
{
   log_entry "db_is_graveyard" "$@"

   local database="$1"

   if ! db_has_graveyard "${database}"
   then
      return 1
   fi

   db_contains_entries "${database}"
}


db_reset()
{
   log_entry "db_reset" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   if ! db_dir_exists "${_database}"
   then
      return 0
   fi

   if [ -z "${MULLE_PATH_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-path.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || exit 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-fike.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || exit 1
   fi

   rmdir_safer "${_databasedir}"
}


#
# zombie
#
__db_zombiedir()
{
   local databasedir="$1"

   zombiedir="${databasedir}/.zombies"
}


__db_zombiefile()
{
   local databasedir="$1"
   local uuid="$2"

   _zombiefile="${databasedir}/.zombies/${uuid}"
}


db_is_uuid_alive()
{
   log_entry "db_is_uuid_alive" "$@"

   local _database
   local _databasedir
   local _uuid

   __db_common_databasedir_uuid "$@"

   local _zombiefile

   __db_zombiefile "${_databasedir}" "${_uuid}"

   [ ! -e "${_zombiefile}" ]
}


db_set_uuid_alive()
{
   log_entry "db_set_uuid_alive" "$@"

   local _database
   local _databasedir
   local _uuid

   __db_common_databasedir_uuid "$@"

   local _zombiefile

   __db_zombiefile "${_databasedir}" "${_uuid}"
   if [ ! -e "${_zombiefile}" ]
   then
      return 1
   fi

   log_fluff "Marking \"${_uuid}\" as alive"

   remove_file_if_present "${_zombiefile}" \
   || fail "failed to delete zombie ${_zombiefile}"

   return 0
}


db_is_filename_inuse()
{
   log_entry "db_is_filename_inuse" "$@"

   local database="$1"
   local filename="$2"

   local inuse

   inuse="`db_fetch_all_filenames "${database}"`"
   fgrep -q -s -x "${filename}" <<< "${inuse}"
}


#
# The owner thing is never used IRL though
#
db_zombify_nodes()
{
   log_entry "db_zombify_nodes" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local owner="$2"

   log_fluff "Marking nodes as zombies for now (${_databasedir})"

   local zombiedir

   __db_zombiedir "${_databasedir}"
   rmdir_safer "${zombiedir}"

   local filename
   local set

   shell_enable_nullglob
   for filename in "${_databasedir}"/*
   do
      if [ ! -z "${owner}" ] && [ "`_db_owner < "${filename}"`" != "${owner}" ]
      then
         continue
      fi

      if [ -z "${set}" ]
      then
         mkdir_if_missing "${zombiedir}"
         set='YES'
      fi

      exekutor cp ${OPTION_COPYMOVEFLAGS} "${filename}" "${zombiedir}/" \
      || exit 1
   done
   shell_disable_nullglob
}


db_zombify_nodelines()
{
   log_entry "db_zombify_nodelines" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   log_fluff "Marking nodelines as zombies for now (${_databasedir})"

   local zombiedir

   __db_zombiedir "${_databasedir}"
   rmdir_safer "${zombiedir}"

   if [ -z "${nodelines}" ]
   then
      return
   fi

   mkdir_if_missing "${zombiedir}"

   local _branch
   local _address
   local _fetchoptions
   local _nodetype
   local _marks
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   shell_disable_glob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      if [ ! -z "${nodeline}" ]
      then
         nodeline_parse "${nodeline}"  # memo: _marks unused

         if __db_common_dbfilepath "${_databasedir}" "${_uuid}"
         then
            exekutor cp ${OPTION_COPYMOVEFLAGS} "${dbfilepath}" "${zombiedir}/"
         fi
      fi
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob
}


_db_bury_zombiefile()
{
   log_entry "_db_bury_zombiefile" "$@"

   local database="$1"
   local zombiefile="$2"

   local nodeline
   local owner
   local entry
   local filename

   entry="`cat "${zombiefile}"`" || exit 1

   __db_parse_dbentry "${entry}"

   db_safe_bury_dbentry "${database}" "${nodeline}" "${owner}" "${filename}"

   remove_file_if_present "${zombiefile}"
}


#
# a zombie remembers its associate file
# this will be buried
#
db_bury_zombie()
{
   log_entry "db_bury_zombie" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local uuid="$2"

   [ -z "${uuid}" ] && internal_fail "uuid is empty"

   local _zombiefile

   __db_zombiefile "${_databasedir}" "${uuid}"

   if [ -e "${_zombiefile}" ]
   then
      _db_bury_zombiefile "${_database}" "${_zombiefile}"
   else
      log_fluff "There is no zombie for \"${uuid}\""
   fi
}


db_safe_bury_dbentry()
{
   log_entry "db_safe_bury_dbentry" "$@"

   local database="$1"
   local nodeline="$2"
   local owner="$3"
   local filename="$4"

   local _branch
   local _address
   local _fetchoptions
   local _nodetype
   local _marks
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   nodeline_parse "${nodeline}"     # memo: _marks unused

   db_forget "${database}" "${_uuid}"

   case "${_marks}" in
      *no-delete|*no-delete,*)
         log_fluff "${_url} is marked as no-delete so not burying"
         return
      ;;
   esac

   if db_is_filename_inuse "${database}" "${filename}"
   then
      log_fluff "Another node is using \"${filename}\" now"
      return
   fi

   db_bury "${database}" "${_uuid}" "${filename}"
}


db_bury_zombies()
{
   log_entry "db_bury_zombies" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$1"

   local zombiedir

   __db_zombiedir "${_databasedir}"

   local zombiefile

   if dir_has_files "${zombiedir}" f
   then
      log_fluff "Moving zombies into graveyard"

      for zombiefile in `ls -1 "${zombiedir}/"* 2> /dev/null`
      do
         _db_bury_zombiefile "${_database}" "${zombiefile}"
      done
   fi

   rmdir_safer "${zombiedir}"
}


db_bury_flat_zombies()
{
   log_entry "db_bury_flat_zombies" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$1"

   local zombiedir

   __db_zombiedir "${_databasedir}"

   local zombiefile

   if dir_has_files "${zombiedir}" f
   then
      log_fluff "Moving flat zombies into graveyard"

      for zombiefile in `ls -1 "${zombiedir}/"* 2> /dev/null`
      do
         if [ "`_db_owner <"${zombiefile}" `" = "$1" ]
         then
            _db_bury_zombiefile "${_database}" "${zombiefile}"
         fi
      done
   fi
}


db_bury_zombie_nodelines()
{
   log_entry "db_bury_zombie_nodelines" "$@"

   local _database
   local _databasedir

   __db_common_databasedir "$@"

   local zombiedir

   __db_zombiedir "${_databasedir}"

   local _branch
   local _address
   local _fetchoptions
   local _nodetype
   local _marks
   local _raw_userinfo
   local _tag
   local _url
   local _userinfo
   local _uuid

   local zombiefile

   shell_disable_glob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      if [ ! -z "${nodeline}" ]
      then
         nodeline_parse "${nodeline}"     # memo: _marks unused

         zombiefile="${zombiedir}/${_uuid}"
         if [ -e "${zombiefile}" ]
         then
            _db_bury_zombiefile "${_database}" "${zombiefile}"
         fi
      fi
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   # will be done later
   # rmdir_if_empty "${zombiedir}"
}


db_state_description()
{
   log_entry "db_state_description" "$@"

   local database="${1:-/}"

   local dbstate

   dbstate="absent"
   if db_dir_exists "${database}"
   then
      db_is_ready "${database}"
      case "$?" in
         0)
            dbstate="ready"
         ;;

         1)
            dbstate="incomplete"
         ;;

         4)
            dbstate="incompatible"
         ;;

         *)
            internal_error "wrong code"
         ;;
      esac

      local state
      state="`db_get_dbtype "${database}"`"

      r_comma_concat "${dbstate}" "${state}"
      dbstate="${RVAL}"
      if db_has_graveyard "${database}"
      then
         r_comma_concat "${dbstate}" "graveyard"
         dbstate="${RVAL}"
      fi
   fi

   printf "%s\n" "${dbstate}"
}

#
# Figure out the filename for a node marked share (which is the default)
# It is assumed, that this particular node is not in the database yet.
# I.e. this is run during an update!
# The returned filename is not absolute.
#
# return values:
#  0: go ahead with update, use return value as filename
#  1: error
#  3: skip this node
#  4: skip this node, unless we are deleting it
#
r_db_update_determine_share_filename()
{
   log_entry "r_db_update_determine_share_filename" "$@"

   local address="$1"
   local evaledurl="$2"
   local evalednodetype="$3"
   local marks="$4"
   local uuid="$5"
   local database="$6"

   [ -z "${evaledurl}" ] && internal_fail "URL \"${evaledurl}\" is empty"

   #
   # Use the "${MULLE_SOURCETREE_STASH_DIR}" for shared nodes, except when
   # marked "local". We do not check the whole tree for another local node
   # though.
   #
   if [ "${evalednodetype}" = "local" ]
   then
      log_debug "Use local minion node \"${address}\" as share"
      filename="${address}"
   else
      local name
      local filename

      r_basename "${address}"
      name="${RVAL}"

      r_filepath_concat "${MULLE_SOURCETREE_STASH_DIR}" "${name}"
      filename="${RVAL}"

      log_debug "Set filename to share directory \"${filename}\" for \"${address}\""
   fi


   if [ "${database}" != "/" ]
   then
      #
      # Check root database if there is not the same URL in there already.
      # If it is and the filename exists, we skip. If it doesn't exist we
      # want to retry
      #
      local otheruuid
      local check

      r_db_fetch_uuid_for_evaledurl "/" "${evaledurl}"
      otheruuid="${RVAL}"

      if [ ! -z "${otheruuid}" ] 
      then
         # So its already there, is this good ?

         log_debug "address   : ${address}"
         log_debug "evaledurl : ${evaledurl}"
         log_debug "uuid      : ${uuid}"
         log_debug "otheruuid : ${otheruuid}"

         # if it's our uuid, than we need to treat it though (somewhat)
         if [ "${uuid}" = "${otheruuid}" ]
         then
            RVAL="${filename}"
            return 4
         fi

         if [ -e "${filename}" ]
         then
            log_fluff "The URL \"${evaledurl}\" is already used in root and \
exists. So skip \"${address}\" for database \"${database}\"."
            return 3
         fi
      fi
   fi

   RVAL="${filename}"
   return 0
#      # uuid same as in root ?
#      if [ "${otheruuid}" = "${uuid}" ]
#      then
#         # We are saving into root as this is known to be share. Or don't we ?
#         # We just skip this
#         return 3
#
#          if [ "${database}" != "/" ]
#          then
#             # we don't know if we got here because of a db actually being
#             # read or just from a config, in which case this could be ok
#             check="`db_fetch_uuid_for_evaledurl "${database}" "${evaledurl}"`"
#             log_debug "checkuuid : ${check}"
#             if [ ! -z "${check}" ]
#             then
#                if [ "${check}" != "${uuid}" ]
#                then
#                   internal_fail "Database corrupted. mulle-sde clean tidy everything."
#                fi
#
#                r_basename "${database}"
#                log_error "\
# Shared node \"${address}\" is not in the root database but in database (${database}).
# ${C_INFO}This can sometimes happen, if you added a dependency, that depends on
# a dependency that a previous dependency also depends on. This can trip up the
# database order, so try ${C_RESET_BOLD}mulle-sde clean tidy${C_INFO} first.
# Another problem could be a duplicated node that references the same stash
# directory.
#
# This could also mean, that \"${address}\" is simultaneously marked as 'share'
# and 'no-share' by two projects. And then it could also mean that
# \"${address}\" is used by two projects, but they reuse the same UUIDs in their
# mulle-sourcetree configurations.
#
# Check your uuids and marks with:
#
#    ${C_RESET_BOLD}mulle-sourcetree list -r --format \"%_;%a;%v={WALK_DATASOURCE};%m\\\\n\" \\
#       --output-no-indent --output-no-header --no-dedupe | sort -u${C_INFO}
#
# If you see a project using a 'no-share' marked  \"${address}\" and another
# without the mark, mark the second one 'no-share' (if possible).
#
# If you see duplicate UUIDs try this remedial action in the problematic
# project:${C_RESET_BOLD}
#    cd \"${MULLE_SOURCETREE_STASH_DIR}/${RVAL}\"
#    mulle-sourcetree -N reuuid
#    mulle-sourcetree -N reset"
#                return 1
#             fi
#          fi
#     else
#         [ "${_database}" = "/" ] &&
#            internal_fail "Unexpected root database for \"${address}\". \
#But uuids differ \"${uuid}\" vs \"${otheruuid}\""
#        if [ "${_database}" != "/" ]
#        then
#           log_fluff "The URL \"${evaledurl}\" is already used in root. So skip it."
#           return 3
#        fi
#     fi

}



