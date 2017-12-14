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
   tail -1
}


#
# often used stuff that uses shared local variables
#
__db_common_rootdir()
{
   case "$1" in
      "/")
         rootdir=""
      ;;

      ""|.|./*)
         internal_fail "database must not be empty or start with '.' . use '/' for root"
      ;;

      */)
         rootdir="$(sed 's|/$||g' <<< "$1")"
      ;;

      *)
         rootdir="$1"
      ;;
   esac
}


__db_common_absolute_rootdir()
{
   case "$1" in
      "/")
         rootdir="${PWD}"
      ;;

      ""|.|./*)
         internal_fail "database must not be empty or start with '.' . use '/' for root"
      ;;

      */)
         rootdir="${PWD}/$(sed 's|/$||g' <<< "$1")"
      ;;

      *)
         rootdir="${PWD}/$1"
      ;;
   esac
}


__db_common_databasedir()
{
   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   database="$1"
   case "${database}" in
      "/")
         databasedir="${SOURCETREE_DB_DIR}"
      ;;

      ""|.|./*)
         internal_fail "database must not be empty or start with '.' . use '/' for root"
      ;;

      */)
         databasedir="$1${SOURCETREE_DB_DIR}"
      ;;

      *)
         databasedir="$1/${SOURCETREE_DB_DIR}"
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

   [ -z "${nodeline}" ] && internal_fail "nodeline is missing"
   [ -z "${uuid}" ]     && internal_fail "uuid is missing"
   [ -z "${filename}" ] && internal_fail "filename is missing"

   case "${owner}" in
      .*/)
         internal_fail "owner starts with \".\""
      ;;
   esac

   local content
   local dbfilepath

   mkdir_if_missing "${databasedir}"
   dbfilepath="${databasedir}/${uuid}"

   content="${nodeline}
${owner}
${filename}"

   log_debug "Remembering uuid \"${uuid}\" ($PWD)"

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

   if __db_common_dbfilepath "${databasedir}" "${uuid}"
   then
      cat "${dbfilepath}"
   fi
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
      log_debug "Forgetting about uuid \"${uuid}\" ($PWD)"
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

   graveyard="${databasedir}/.graveyard"
   gravepath="${graveyard}/${uuid}"

   local rootdir
   local actual

   __db_common_rootdir "${database}"

   actual="`filepath_concat "${rootdir}" "${filename}"`"

   if [ -L "${actual}" ]
   then
      log_verbose "Removing old symlink \"${actual}\""
      exekutor rm -f "${actual}" >&2
      return
   fi

   if [ ! -e "${actual}" ]
   then
      log_fluff "\"${actual}\" vanished or never existed ($PWD)"
   fi

   if [ -e "${gravepath}" ]
   then
      log_fluff "Repurposing old grave \"${actual}\""
      exekutor rm -rf "${gravepath}" >&2
   else
      mkdir_if_missing "${graveyard}"
   fi

   log_info "Burying ${C_MAGENTA}${C_BOLD}${actual}${C_INFO} in grave \"${gravepath}\""
   exekutor mv ${OPTION_COPYMOVEFLAGS} "${actual}" "${gravepath}" >&2
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

   log_debug "nodeline : ${nodeline}"
   log_debug "owner    : ${owner}"
   log_debug "filename : ${filename}"
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

   local nodeline
   local owner
   local filename

   __db_recall_dbentry "$@"

   if [ -z "${nodeline}" ]
   then
      return 1
   fi

   echo "${nodeline}"
   return 0
}


db_fetch_owner_for_uuid()
{
   log_entry "db_fetch_owner_for_uuid" "$@"

   local nodeline
   local owner

   __db_recall_dbentry "$@"

   if [ -z "${owner}" ]
   then
      return 1
   fi

   echo "${owner}"
   return 0
}


db_fetch_filename_for_uuid()
{
   log_entry "db_fetch_filename_for_uuid" "$@"

   local nodeline
   local owner
   local filename

   __db_recall_dbentry "$@"

   if [ -z "${filename}" ]
   then
      return 1
   fi

   echo "${filename}"
   return 0
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


db_fetch_uuid_for_filename()
{
   log_entry "db_fetch_uuid_for_filename" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   local searchfilename="$2"

   [ -z "${searchfilename}" ] && internal_fail "filename is empty"

   if ! dir_has_files "${databasedir}" f
   then
      return 1
   fi

   local nodeline
   local owner
   local filename
   local dbentry

   IFS="
"
   for candidate in `fgrep -l -x -s "${searchfilename}" "${databasedir}"/*`
   do
      IFS="${DEFAULT_IFS}"

      dbentry="`cat "${candidate}" `"

      __db_parse_dbentry "${dbentry}"

      if [ "${searchfilename}" = "${filename}" ]
      then
         _nodeline_get_uuid <<< "${nodeline}"
         return 0
      fi
   done

   IFS="${DEFAULT_IFS}"
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
         tail -1 "${i}"
      done
   )
}


db_relative_filename()
{
   log_entry "db_relative_filename" "$@"

   local database
   local rootdir

   __db_common_absolute_rootdir "$@"

   local filename=$2

   symlink_relpath "${filename}" "${rootdir}"
}


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
db_get_dbtype()
{
   log_entry "db_get_dbtype" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   # for -e tests
   if ! head -1 "${databasedir}/.db_type" 2> /dev/null
   then
      :
   fi
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
      log_debug "\"${PWD}/${databasedir}\" exists"
      return 0
   else
      log_debug "\"${PWD}/${databasedir}\" not found"
      return 1
   fi
}


db_environment()
{
   echo "${MULLE_SDE_VIRTUAL_ROOT}
${databasedir}
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
      log_debug "\"${dbdonefile}\" not found ($PWD)"
      return 1
   fi

   local oldenvironment
   local environment

   oldenvironment="`cat "${dbdonefile}" `"
   environment="`db_environment`"

   if [ "${oldenvironment}" != "${environment}" ]
   then
      log_debug "\"${database}\" was made in a different environment. Needs reset"
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
   redirect_exekutor "${databasedir}/.db_done" db_environment
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
      log_debug "\"${PWD}/${databasedir}/.db_done\" exists"
      return 0
   fi

   log_debug "\"${PWD}/${databasedir}/.db_update\" not found"
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

   mkdir_if_missing "${databasedir}"
   redirect_exekutor "${databasedir}/.db_shareddir"  echo "${shareddir}"
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
    ${C_RESET_BOLD}cd '${PWD}/${database}'${C_ERROR}
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
   local mode="$2"

   local dbtype

   dbtype="`db_get_dbtype "${database}"`"
   if [ -z "${dbtype}" -o "${dbtype}" = "${mode}" ]
   then
      return
   fi

   if [ "${dbtype}" = "flat" -a "${mode}" = "recurse" ]
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

   fail "Database in \"$PWD\" was constructed as $mode \.
If you want to change that do:
   ${C_RESET_BOLD}cd '$PWD'${C_ERROR}
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} clean${C_ERROR}
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} reset${C_ERROR}
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} update --mode${C_ERROR}"
}


# sets external variables!!
_db_set_default_mode()
{
   log_entry "_db_set_default_mode" "$@"

   local database="$1"
   local usertype="$2"


   local dbtype
   local actualdbtype

   actualdbtype="`db_get_dbtype "${database}"`"

   if [ ! -z "${actualdbtype}" -a -z "${MULLE_WALK_SUPRESS}" ]
   then
      local rootdir

      __db_common_rootdir "${database}"
   fi

   dbtype="${usertype}"
   if [ -z "${dbtype}" ]
   then
      dbtype="${actualdbtype}"
      if [ -z "${dbtype}" ]
      then
         dbtype="`egrep -s -v '^#' "${SOURCETREE_DEFAULT_FILE}"`"
         if [ -z "${dbtype}" ]
         then
            dbtype="recurse"
         fi
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

   [ -d "${databasedir}/.graveyard" ]
}


db_graveyard_dir()
{
   log_entry "db_has_graveyard" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   echo "${databasedir}/.graveyard"
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

   local keepgraveyard="${2:-YES}"

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

   if [ "${keepgraveyard}" = "YES" ] && db_has_graveyard "${database}"
   then
      local oldplace
      local newplace

      oldplace="${databasedir}/.graveyard"
      newplace="`dirname -- "${databasedir}"`/`uuidgen`.graveyard"

      mv "${oldplace}" "${newplace}"
   fi

   rmdir_safer "${databasedir}"
   return
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


db_is_address_inuse()
{
   log_entry "db_is_address_inuse" "$@"

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

   log_fluff "Marking all nodes as zombies for now ($PWD/${database})"

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

   local branch
   local address
   local fetchoptions
   local nodetype
   local marks
   local tag
   local url
   local userinfo
   local uuid

   nodeline_parse "${nodeline}"

   db_forget "${database}" "${uuid}"

   if nodemarks_contain_nodelete "${marks}"
   then
      log_fluff "${url} is marked as nodelete so not burying"
      return
   fi

   if db_is_address_inuse "${database}" "${filename}"
   then
      log_fluff "Another node is using \"${filename}\" now"
      return
   fi

   db_bury "${database}" "${uuid}" "${filename}"
}


db_bury_zombies()
{
   log_entry "db_bury_zombies" "$@"

   local database
   local databasedir

   __db_common_databasedir "$@"

   local zombiedir

   __db_zombiedir "${databasedir}"

   log_fluff "Burying zombie nodes ($PWD/${database})"

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
