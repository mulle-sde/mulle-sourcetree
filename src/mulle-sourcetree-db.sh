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


__db_common_rootdir()
{
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT is not set"

   case "${MULLE_SOURCETREE_SHARE_DIR}" in
      /*)
         if string_has_prefix "$1" "${MULLE_SOURCETREE_SHARE_DIR}"
         then
            case "$1" in
               "/")
                  rootdir="$1"
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
         internal_fail "database \"$1\" must start with '/'"
      ;;
   esac
}


__db_common_databasedir()
{
   [ -z "${SOURCETREE_DB_NAME}" ] && internal_fail "SOURCETREE_DB_NAME is not set"
   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT is not set"

   database="$1"

   case "${MULLE_SOURCETREE_SHARE_DIR}" in
      /*)
         if string_has_prefix "${database}" "${MULLE_SOURCETREE_SHARE_DIR}"
         then
            case "${database}" in
               "/")
                  databasedir="${SOURCETREE_DB_NAME}"
               ;;

               /*/)
                  databasedir="${database}${SOURCETREE_DB_NAME}"
               ;;

               *)
                  databasedir="${database}/${SOURCETREE_DB_NAME}"
               ;;
            esac
            return
         fi
      ;;
   esac

   case "${database}" in
      "/")
         databasedir="${MULLE_VIRTUAL_ROOT}/${SOURCETREE_DB_NAME}"
      ;;

      /*/)
         databasedir="${MULLE_VIRTUAL_ROOT}${database}${SOURCETREE_DB_NAME}"
      ;;

      /*)
         databasedir="${MULLE_VIRTUAL_ROOT}${database}/${SOURCETREE_DB_NAME}"
      ;;

      *)
         internal_fail "database \"${database}\" must start with '/'"
      ;;
   esac
}


__db_common_uuid()
{
   uuid="$1"

   if [ ! -z "${uuid}" ]
   then
      return 0
   fi

   internal_fail "Empty uuid"
}


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

   local database
   local databasedir

   __db_common_databasedir "$@"

   local uuid="$2"
   local nodeline="$3"
   local owner="$4"
   local filename="$5"
   local evaledurl="$6"

   [ -z "${nodeline}" ] && internal_fail "nodeline is missing"
   [ -z "${uuid}" ]     && internal_fail "uuid is missing"
   [ -z "${filename}" ] && internal_fail "filename is missing"

   case "${owner}" in
      .*/)
         internal_fail "owner starts with \".\""
      ;;
   esac

   case "${filename}" in
      /*)
#         if [ "${UNAME}" = "darwin" ]
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

   mkdir_if_missing "${databasedir}"
   dbfilepath="${databasedir}/${uuid}"

   content="${nodeline}
${owner}
${filename}
${evaledurl}"

   log_debug "Remembering uuid \"${uuid}\" ($databasedir)"

   redirect_exekutor "${dbfilepath}" echo "${content}"
}


db_recall()
{
   log_entry "db_recall" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if ! __db_common_dbfilepath "${databasedir}" "${uuid}"
   then
      return 1
   fi

   cat "${dbfilepath}"
}


db_forget()
{
   log_entry "db_forget" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if __db_common_dbfilepath "${databasedir}" "${uuid}"
   then
      log_debug "Forgetting about uuid \"${uuid}\" ($databasedir)"
      remove_file_if_present "${dbfilepath}"
   fi
}


#
# This buries a directory in the project by moving it into the graveyard.
#
# it must have been ascertained that filename is not in use by other nodes
# filename is relative to database here
#
db_bury()
{
   log_entry "db_bury" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local filename="$3"

   [ $# -eq 3 ] || internal_fail "api error"
   [ -z "${filename}" ] && internal_fail "filename is empty"

   local gravepath
   local graveyard

   graveyard="${databasedir}/../graveyard"
   gravepath="${graveyard}/${uuid}"

   local rootdir

   __db_common_rootdir "${database}"

   case "${filename}" in
      /*)
      ;;

      *)
         internal_fail "filename \"${filename}\" must be absolute"
      ;;
   esac

   if [ -L "${filename}" ]
   then
      log_verbose "Removing old symlink \"${filename}\""
      exekutor rm -f "${filename}" >&2
      return
   fi

   if [ ! -e "${filename}" ]
   then
      log_fluff "\"${filename}\" vanished or never existed ($databasedir)"
   fi

   if [ -e "${gravepath}" ]
   then
      local otheruuid
      local othergravepath

      otheruuid="`node_genuuid`"
      othergravepath="${graveyard}/${otheruuid}"

      log_fluff "Moving old grave with same uuid \"${gravepath}\" to \"${othergravepath}\""
      exekutor mv "${gravepath}" "${othergravepath}"
   else
      mkdir_if_missing "${graveyard}"
   fi

   log_info "Burying ${C_MAGENTA}${C_BOLD}${filename}${C_INFO} in grave \"${gravepath}\""
   exekutor mv ${OPTION_COPYMOVEFLAGS} "${filename}" "${gravepath}" >&2
}


__db_parse_dbentry()
{
   log_entry "__db_parse_dbentry" "$@"

   local dbentry="$1"

   if [ -z "${dbentry}" ]
   then
      return 1
   fi

   nodeline="`_db_nodeline <<< "${dbentry}"`"
   owner="`_db_owner <<< "${dbentry}"`"
   filename="`_db_filename <<< "${dbentry}"`"
   evaledurl="`_db_evaledurl <<< "${dbentry}"`"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = "YES" ]
   then
      log_trace2 "\
nodeline  : ${nodeline}
owner     : ${owner}
filename  : ${filename}
evaledurl : ${evaledurl}"
   fi
}


__db_recall_dbentry()
{
   log_entry "__db_recall_dbentry" "$@"

   local database="$1"
   local uuid="$2"

   local dbentry

   dbentry="`db_recall "${database}" "${uuid}"`"
   __db_parse_dbentry "${dbentry}"
}


db_get_rootdir()
{
   local rootdir

   __db_common_rootdir "$1"
   echo "${rootdir}"
}


db_fetch_nodeline_for_uuid()
{
   log_entry "db_fetch_nodeline_for_uuid" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if ! __db_common_dbfilepath "${databasedir}" "${uuid}"
   then
      return 1
   fi

   _db_nodeline <"${dbfilepath}"
}


db_fetch_owner_for_uuid()
{
   log_entry "db_fetch_owner_for_uuid" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if ! __db_common_dbfilepath "${databasedir}" "${uuid}"
   then
      return 1
   fi

   _db_owner < "${dbfilepath}"
}


db_fetch_filename_for_uuid()
{
   log_entry "db_fetch_filename_for_uuid" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if ! __db_common_dbfilepath "${databasedir}" "${uuid}"
   then
      return 1
   fi

   _db_filename < "${dbfilepath}"
}


db_fetch_evaledurl_for_uuid()
{
   log_entry "db_fetch_evaledurl_for_uuid" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local dbfilepath

   if ! __db_common_dbfilepath "${databasedir}" "${uuid}"
   then
      return 1
   fi

   _db_evaledurl < "${dbfilepath}"
}


db_fetch_all_uuids()
{
   log_entry "db_fetch_all_uuids" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   ( cd "${databasedir}" ; ls -1 ) 2> /dev/null
}


db_fetch_all_nodelines()
{
   log_entry "db_fetch_all_nodelines" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   (
      shopt -s nullglob

      local i

      for i in "${databasedir}"/*
      do
         head -1 "${i}"
      done
   )
}


db_fetch_uuid_for_address()
{
   log_entry "db_fetch_uuid_for_address" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   local address="$2"

   [ -z "${address}" ] && internal_fail "address is empty"

   if dir_has_files "${databasedir}" f
   then
      local pattern

      pattern="`escaped_grep_pattern "${address}"`"
      egrep -s "^${pattern};" "${databasedir}"/* | cut -s '-d;' -f 4
   fi
}


db_fetch_uuid_for_evaledurl()
{
   log_entry "db_fetch_uuid_for_evaledurl" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   local searchurl="$2"

   [ -z "${searchurl}" ] && internal_fail "url is empty"

   if ! dir_has_files "${databasedir}" f
   then
      return 1
   fi

   (
      local evaledurl
      local candidate

      cd "${databasedir}"
      IFS="
"
      for candidate in `fgrep -l -x -s "${evaledurl}" *`
      do
         IFS="${DEFAULT_IFS}"

         evaledurl="`_db_evaledurl < "${candidate}" `"
         if [ "${searchurl}" = "${evaledurl}" ]
         then
            echo "${candidate}"
            exit 0
         fi
      done
      exit 1
   )

   return 1
}


db_fetch_uuid_for_filename()
{
   log_entry "db_fetch_uuid_for_filename" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   local searchurl="$2"

   [ -z "${searchfilename}" ] && internal_fail "filename is empty"

   if ! dir_has_files "${databasedir}" f
   then
      return 1
   fi

   (
      local filename
      local candidate

      cd "${databasedir}"
      IFS="
"
      for candidate in `fgrep -l -x -s "${searchfilename}" *`
      do
         IFS="${DEFAULT_IFS}"

         filename="`_db_filename < "${candidate}" `"
         if [ "${searchfilename}" = "${filename}" ]
         then
            echo "${candidate}"
            exit 0
         fi
      done
      exit 1
   )

   return 1
}


db_fetch_all_filenames()
{
   log_entry "db_fetch_all_filenames" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   (
      shopt -s nullglob

      local i

      for i in "${databasedir}"/*
      do
         _db_filename < "${i}"
      done
   )
}


db_relative_filename()
{
   log_entry "db_relative_filename" "$@"

   local database
   local rootdir

   __db_common_rootdir "$@"

   local filename=$2

   symlink_relpath "${filename}" "${rootdir}"
}


#
# the user will use filename to retrieve stuff later
#
db_set_memo()
{
   log_entry "db_set_memo" "$@"

   local database
   local databasedir

   __db_common_databasedir "$1"

   local filename

   filename="${databasedir}/.db_memo"
   remove_file_if_present "${filename}"

   local nodelines="$2"

   redirect_exekutor "${filename}" echo "${nodelines}"

   echo "${filename}"
}


db_add_memo()
{
   log_entry "db_add_memo" "$@"

   local database
   local databasedir

   __db_common_databasedir "$1"

   local nodelines="$2"

   redirect_append_exekutor "${databasedir}/.db_memo" echo "${nodelines}"
}


db_add_missing()
{
   log_entry "db_add_missing" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local nodeline="$3"

   mkdir_if_missing "${databasedir}/.missing"
   redirect_exekutor "${databasedir}/.missing/${uuid}" echo "${nodeline}"
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

   local database
   local databasedir

   __db_common_databasedir "$@"

   # for -e tests
   _db_get_dbtype "${databasedir}"
}


db_set_dbtype()
{
   log_entry "db_set_dbtype" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   local dbtype="$2"

   [ -z "${dbtype}" ] && internal_fail "type is missing"

   mkdir_if_missing "${databasedir}"
   redirect_exekutor "${databasedir}/.db_type"  echo "${dbtype}"
}


db_clear_dbtype()
{
   log_entry "db_clear_dbtype" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   remove_file_if_present "${databasedir}/.db_type"
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
# these can be prefixed with ${database} to query inferior db state
# if there is some kind of .db file there we assume that's a database
# otherwise it's just a graveyard
#
db_dir_exists()
{
   log_entry "db_dir_exists" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   if [ -d "${databasedir}" ]
   then
      log_debug "\"${databasedir}\" exists"
      return 0
   else
      log_debug "\"${databasedir}\" not found"
      return 1
   fi
}


__db_environment()
{
   echo "${databasedir}
${MULLE_SOURCETREE_SHARE_DIR}"
}


db_environment()
{
   log_entry "db_is_ready" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   echo "${databasedir}
${MULLE_SOURCETREE_SHARE_DIR}"
}


db_is_ready()
{
   log_entry "db_is_ready" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   local dbdonefile

   dbdonefile="${databasedir}/.db_done"
   if [ ! -f "${dbdonefile}" ]
   then
      log_debug "\"${dbdonefile}\" not found (${databasedir})"
      return 1
   fi

   local oldenvironment
   local environment

   oldenvironment="`cat "${dbdonefile}" `"
   environment="`__db_environment`"

   if [ "${oldenvironment}" != "${environment}" ]
   then
      log_debug "\"${database}\" was made in a different environment. Needs reset"
      log_debug "Current environment : ${environment}"
      log_debug "Old environment     : ${oldenvironment}"
      return 2
   fi

   return 0
}


db_set_ready()
{
   log_entry "db_set_ready" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   mkdir_if_missing "${databasedir}"
   redirect_exekutor "${databasedir}/.db_done" __db_environment
}


db_clear_ready()
{
   log_entry "db_clear_ready" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   remove_file_if_present "${databasedir}/.db_done"
}


db_get_timestamp()
{
   log_entry "db_get_timestamp" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   if [ -f "${databasedir}/.db_done" ]
   then
      modification_timestamp "${databasedir}/.db_done"
   fi
}


#
# update
#
db_is_updating()
{
   log_entry "db_is_updating" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   if [ -f "${databasedir}/.db_update" ]
   then
      log_debug "\"${databasedir}/.db_done\" exists"
      return 0
   fi

   log_debug "\"${databasedir}/.db_update\" not found"
   return 1
}


db_set_update()
{
   log_entry "db_set_update" "$@"

   [ $# -eq 0 ] || internal_fail "api error"

   local database
   local databasedir

   __db_common_databasedir "$@"

   mkdir_if_missing "${databasedir}"
   redirect_exekutor "${databasedir}/.db_update"  echo "# intentionally left blank"
}


db_clear_update()
{
   log_entry "db_clear_update" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   remove_file_if_present "${databasedir}/.db_update"
}


db_set_shareddir()
{
   log_entry "db_set_shareddir" "$@"

   [ $# -eq 2 ] || internal_fail "api error"

   local database
   local databasedir

   __db_common_databasedir "$@"

   local shareddir="$2"

   # empty is OK

   mkdir_if_missing "${databasedir}"
   redirect_exekutor "${databasedir}/.db_shareddir"  echo "${shareddir}"
}


db_clear_shareddir()
{
   log_entry "db_clear_shareddir" "$@"

   [ $# -eq 1 ] || internal_fail "api error"

   local database
   local databasedir

   __db_common_databasedir "$@"

   remove_file_if_present "${databasedir}/.db_shareddir"
}


db_get_shareddir()
{
   log_entry "db_get_shareddir" "$@"

   [ $# -eq 1 ] || internal_fail "api error"

   local database
   local databasedir

   __db_common_databasedir "$@"

   cat "${databasedir}/.db_shareddir" 2> /dev/null || :
}

#
# If a previous update crashed, we wan't to let the user know.
#
db_ensure_consistency()
{
   log_entry "db_ensure_consistency" "$@"

   local database="$1"

   if db_is_updating "${database}" && [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
   then
      log_error "A previous update was incomplete.
Suggested resolution:
    ${C_RESET_BOLD}cd '${MULLE_VIRTUAL_ROOT}${database}'${C_ERROR}
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

   local rootdir

   # que ??
   if [ ! -z "${actualdbtype}"  ]
   then
      __db_common_rootdir "${database}"
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
         log_verbose "Database: ${C_RESET_BOLD}`filepath_concat "${PWD}" "${rootdir}"`${C_INFO} ${C_MAGENTA}${C_BOLD}${actualdbtype}${C_INFO}"
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

      *)
         internal_fail "unknown dbtype \"${dbtype}\""
      ;;
   esac

   if [ ! -z "${SOURCETREE_MODE}" ]
   then
      log_verbose "Mode: ${C_MAGENTA}${C_BOLD}${SOURCETREE_MODE}${C_INFO}"
      if [ "${SOURCETREE_MODE}" = share ]
      then
         [ -z "${MULLE_SOURCETREE_SHARE_DIR}" ] && internal_fail "MULLE_SOURCETREE_SHARE_DIR is empty"
         log_verbose "Shared directory: ${C_RESET_BOLD}${MULLE_SOURCETREE_SHARE_DIR}${C_INFO}"
      fi
   fi
}



db_has_graveyard()
{
   log_entry "db_has_graveyard" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   [ -d "${databasedir}/../graveyard" ]
}


db_graveyard_dir()
{
   log_entry "db_has_graveyard" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   echo "${databasedir}/../graveyard"
}



db_contains_entries()
{
   log_entry "db_contains_entries" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   (
      shopt -s nullglob

      # the echo snarfs the newline in the expansion
      controlfiles="`echo "${databasedir}"/.db*`"

      ! [ -z "${controlfiles}" ] # will have linefeed for some reason don't quote
   )
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

   local database
   local databasedir

   __db_common_databasedir "$@"

   if ! db_dir_exists "${database}"
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

   rmdir_safer "${databasedir}"
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

   zombiefile="${databasedir}/.zombies/${uuid}"
}


db_is_uuid_alive()
{
   log_entry "db_is_uuid_alive" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local zombiefile

   __db_zombiefile "${databasedir}" "${uuid}"

   [ ! -e "${zombiefile}" ]
}


db_set_uuid_alive()
{
   log_entry "db_set_uuid_alive" "$@"

   local database
   local databasedir
   local uuid

   __db_common_databasedir_uuid "$@"

   local zombiefile

   __db_zombiefile "${databasedir}" "${uuid}"
   if [ -e "${zombiefile}" ]
   then
      log_fluff "Marking \"${uuid}\" as alive"

      remove_file_if_present "${zombiefile}" || fail "failed to delete zombie ${zombiefile}"
   else
      log_fluff "\"${uuid}\" is alive as no zombie is present"
   fi
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


db_zombify_nodes()
{
   log_entry "db_zombify_nodes" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   log_fluff "Marking all nodes as zombies for now (${databasedir})"

   local zombiedir

   __db_zombiedir "${databasedir}"
   rmdir_safer "${zombiedir}"

   if dir_has_files "${databasedir}" f
   then
      mkdir_if_missing "${zombiedir}"

      exekutor cp ${OPTION_COPYMOVEFLAGS} "${databasedir}/"* "${zombiedir}/" >&2
   fi
}


_db_bury_zombiefile()
{
   log_entry "_db_bury_zombiefile" "$@"

   local database="$1"
   local zombiefile="$2"

   local nodeline
   local owner

   local nodeline
   local owner
   local entry
   local filename

   entry="`cat "${zombiefile}"`"

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

   local database
   local databasedir

   __db_common_databasedir "$@"

   local uuid="$2"

   [ -z "${uuid}" ] && internal_fail "uuid is empty"

   local zombiefile

   __db_zombiefile "${databasedir}" "${uuid}"

   if [ -e "${zombiefile}" ]
   then
      _db_bury_zombiefile "${database}" "${zombiefile}"
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
   local _tag
   local _url
   local _userinfo
   local _uuid

   nodeline_parse "${nodeline}"

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

   local database
   local databasedir

   __db_common_databasedir "$@"

   local zombiedir

   __db_zombiedir "${databasedir}"

   local zombiefile

   if dir_has_files "${zombiedir}" f
   then
      log_fluff "Moving zombies into graveyard"

      for zombiefile in `ls -1 "${zombiedir}/"* 2> /dev/null`
      do
         _db_bury_zombiefile "${database}" "${zombiefile}"
      done
   fi

   rmdir_safer "${zombiedir}"
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

         2)
            dbstate="incompatible"
         ;;
      esac

      local state
      state="`db_get_dbtype "${database}"`"

      dbstate="`comma_concat "${dbstate}" "${state}"`"
      if db_has_graveyard "${database}"
      then
         dbstate="`comma_concat "${dbstate}" "graveyard"`"
      fi
   fi

   echo "${dbstate}"
}


db_fetch_uuid_for_url()
{
   log_entry "db_fetch_uuid_for_url" "$@"

   local database="$1"
   local url="$2"

   local evaledurl

   evaledurl="`eval echo "${url}"`"
   if [ -z "${evaledurl}" ]
   then
      fail "URL \"${url}\" evaluates to empty"
   fi

   db_fetch_uuid_for_evaledurl "${database}" "${evaledurl}"
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
#  2: skip this node
#
db_update_determine_share_filename()
{
   log_entry "db_update_determine_share_filename" "$@"

   local database="$1"
   local address="$2"
   local url="$3"
   local nodetype="$4"
   local marks="$5"
   local uuid="$6"

   local filename
   local evaledurl

   evaledurl="`eval echo "${url}"`"
   if [ -z "${evaledurl}" ]
   then
      fail "URL \"${url}\" evaluates to empty"
   fi

   #
   # Check root database if there is not the same URL in there already.
   # It is assumed
   local otheruuid

   otheruuid="`db_fetch_uuid_for_evaledurl "/" "${evaledurl}"`"
   if [ ! -z "${otheruuid}" ]
   then
      if [ "${otheruuid}" = "${uuid}" ]
      then
         [ "${database}" != "/" ] && internal_fail "unexpected not root ($database)"

         # ok
      else
         log_debug "uuid     : ${uuid}"
         log_debug "otheruuid: ${otheruuid}"
         [ "${database}" = "/" ] && internal_fail "unexpected root"
         log_fluff "The \"${url}\" is already used in root. So skip it."
         return 2
      fi
   fi
   log_debug "Use root database for share node \"${address}\""

   #
   # Use the "${MULLE_SOURCETREE_SHARE_DIR}" for shared nodes, except when
   # marked "local". We do not check the whole tree for another local node
   # though.
   #
   if [ "${nodetype}" = "local" ]
   then
      log_debug "Use local minion node \"${address}\" as share"
      echo "${address}"
      return 0
   fi

   local name

   name="`fast_basename "${address}" `"
   filename="`filepath_concat "${MULLE_SOURCETREE_SHARE_DIR}" "${name}" `"
   log_debug "Set filename to share directory \"${filename}\""

   echo "${filename}"
   return 0
}



