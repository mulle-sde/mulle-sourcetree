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


db_remember()
{
   log_entry "db_remember" "$@"

   local uuid="$1"
   local nodeline="$2"
   local parentnodeline="$3"
   local parentdb="$4"
   local relative="$5"

   [ -z "${nodeline}" ] && internal_fail "nodeline is missing"
   [ -z "${uuid}" ]     && internal_fail "uuid is missing"

   local content
   local filepath

   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   mkdir_if_missing "${SOURCETREE_DB_DIR}"
   filepath="${SOURCETREE_DB_DIR}/${uuid}"

   content="${nodeline}
${parentnodeline}
${parentdb}
${relative}"  ## a nodeline line

   log_debug "Remembering uuid \"${uuid}\" ($PWD)"

   redirect_exekutor "${filepath}" echo "${content}"
}


db_forget()
{
   log_entry "db_forget" "$@"

   local uuid="$1"      # uuid of the nodeline

   [ -z "${uuid}" ] && internal_fail "uuid is missing"

   local filepath

   filepath="${SOURCETREE_DB_DIR}/${uuid}"

   log_debug "Forgetting about uuid \"${uuid}\" ($PWD)"
   remove_file_if_present "${filepath}"
}


_db_nodeline()
{
   sed -n '1p'
}


_db_parentnodeline()
{
   sed -n '2p'
}


_db_parentdb()
{
   sed -n '3p'
}

_db_relative()
{
   sed -n '4p'
}


_db_nodeline_of_db_file()
{
   sed -n '1p' "$1"
}


_db_parentnodeline_of_db_file()
{
   sed -n '2p' "$1"
}


_db_parentdb_of_db_file()
{
   sed -n '3p' "$1"
}

_db_relative_of_db_file()
{
   sed -n '3p' "$1"
}


db_get_nodeline_for_url()
{
   log_entry "db_get_nodeline_for_url" "$@"

   local url="$1"

   [ -z "${url}" ] && internal_fail "Empty parameter"

   local nodeline
   local other

   IFS="
"
   for nodeline in `db_get_all_nodelines`
   do
      IFS="${DEFAULT_IFS}"

      other="`_nodeline_get_url "${nodeline}"`"
      if [ "${url}" = "${other}" ]
      then
         echo "${nodeline}"
         return
      fi
   done

   IFS="${DEFAULT_IFS}"
}


db_get_nodeline_for_uuid()
{
   log_entry "db_get_nodeline_for_uuid" "$@"

   local uuid="$1"

   [ -z "${uuid}" ]              && internal_fail "Empty parameter"
   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   local relpath

   relpath="${SOURCETREE_DB_DIR}/${uuid}"
   if [ -f "${relpath}" ]
   then
      log_debug "found \"${relpath}\""
      _db_nodeline_of_db_file "${relpath}"
   fi
}


db_get_address_of_uuid()
{
   log_entry "db_get_address_of_uuid" "$@"

   local nodeline

   nodeline="`db_get_nodeline_for_uuid "$@"`" || exit 1
   nodeline_get_address "${nodeline}"
}


db_get_parentnodeline_for_uuid()
{
   log_entry "db_get_parentnodeline_for_uuid" "$@"

   local uuid="$1"

   [ -z "${uuid}" ]              && internal_fail "Empty uuid"
   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   local reposfilepath

   reposfilepath="${SOURCETREE_DB_DIR}/${uuid}"
   if [ -f "${reposfilepath}" ]
   then
      log_debug "found \"${reposfilepath}\""
      _db_parentnodeline_of_db_file "${reposfilepath}"
   else
      log_debug "No address found for ${uuid} in ${SOURCETREE_DB_DIR}"
   fi
}


db_get_parentdb_for_uuid()
{
   log_entry "db_get_parentdb_for_uuid" "$@"

   local uuid="$1"

   [ -z "${uuid}" ]              && internal_fail "Empty uuid"
   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   local reposfilepath

   reposfilepath="${SOURCETREE_DB_DIR}/${uuid}"
   if [ -f "${reposfilepath}" ]
   then
      log_debug "found \"${reposfilepath}\""
      _db_parentdb_of_db_file "${reposfilepath}"
   else
      log_debug "No address found for ${uuid} in ${SOURCETREE_DB_DIR}"
   fi
}


db_get_owner_for_uuid()
{
   log_entry "db_get_owner_for_uuid" "$@"

   local uuid="$1"

   [ -z "${uuid}" ]              && internal_fail "Empty uuid"
   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   local reposfilepath

   reposfilepath="${SOURCETREE_DB_DIR}/${uuid}"
   if [ -f "${reposfilepath}" ]
   then
      log_debug "found \"${reposfilepath}\""
      _db_relative_of_db_file "${reposfilepath}"
   else
      log_debug "no address found for ${uuid} in ${SOURCETREE_DB_DIR}"
   fi
}


db_get_nodeline_of_zombie()
{
   local zombie="$1"

   _db_nodeline_of_db_file "${zombie}" || exit 1
}


db_get_all_uuids()
{
   log_entry "db_get_all_uuids" "$@"

   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   ( cd "${SOURCETREE_DB_DIR}" ; ls -1 ) 2> /dev/null
}


#
# can receive a prefix (for walking)
#
db_get_all_nodelines()
{
   log_entry "db_get_all_nodelines" "$@"

   local prefix="$1"

   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   if dir_has_files "${prefix}${SOURCETREE_DB_DIR}" f >&2
   then
      for i in "${prefix}${SOURCETREE_DB_DIR}"/*
      do
         head -1 "${i}"
      done
   fi
}


db_get_all_addresss()
{
   log_entry "db_get_all_addresss" "$@"

   db_get_all_nodelines | _nodeline_get_address
}


db_get_all_urls()
{
   log_entry "db_get_all_urls" "$@"

   db_get_all_nodelines | _nodeline_get_url
}

#
# dbtype
#
db_get_dbtype()
{
   log_entry "db_get_dbtype" "$@"

   # for -e tests
   if ! head -1 "${SOURCETREE_DB_DIR}/.db_type" 2> /dev/null
   then
      :
   fi
}


db_set_dbtype()
{
   log_entry "db_set_dbtype" "$@"

   [ -z "$1" ] && internal_fail "type is missing"

   mkdir_if_missing "${SOURCETREE_DB_DIR}"
   redirect_exekutor "${SOURCETREE_DB_DIR}/.db_type"  echo "$1"
}


db_clear_dbtype()
{
   log_entry "db_clear_dbtype" "$@"

   remove_file_if_present "${SOURCETREE_DB_DIR}/.db_type"
}


db_is_recursive()
{
   log_entry "db_is_recursive" "$@"

   case "`db_get_dbtype`" in
      share|recursive)
         return 0
      ;;
   esac

   return 1
}


#
# dbstate
# these can be prefixed with ${prefix} to query inferior db state
# if there is some kind of .db file there we assume that's a database
# otherwise it's just a graveyard
#
db_exists()
{
   log_entry "db_exists" "$@"

   local prefix="$1"

   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   if (
      shopt -s nullglob

      controlfiles="${prefix}${SOURCETREE_DB_DIR}"/.db*

      [ -z "${controlfiles}" ]
   )
   then
      log_debug "\"${PWD}/${prefix}${SOURCETREE_DB_DIR}\" not found"
      return 1
   else
      log_debug "\"${PWD}/${prefix}${SOURCETREE_DB_DIR}\" exists"
      return 0
   fi
}


db_is_ready()
{
   log_entry "db_is_ready" "$@"

   local prefix="$1"

   if [ -f "${prefix}${SOURCETREE_DB_DIR}/.db_done" ]
   then
      log_debug "\"${PWD}/${prefix}${SOURCETREE_DB_DIR}/.db_done\" exists"
      return 0
   fi

   log_debug "\"${PWD}/${prefix}${SOURCETREE_DB_DIR}/.db_done\" not found"
   return 1
}


db_set_ready()
{
   log_entry "db_set_dbtype" "$@"

   local prefix="$1"

   mkdir_if_missing "${prefix}${SOURCETREE_DB_DIR}"
   redirect_exekutor "${prefix}${SOURCETREE_DB_DIR}/.db_done"  echo "# intentionally left blank"
}


db_clear_ready()
{
   log_entry "db_set_dbtype" "$@"

   local prefix="$1"

   remove_file_if_present "${prefix}${SOURCETREE_DB_DIR}/.db_done"
}



db_timestamp()
{
   log_entry "db_timestamp" "$@"

   local prefix="$1"

   if [ -f "${prefix}${SOURCETREE_DB_DIR}/.db_done" ]
   then
      modification_timestamp "${prefix}${SOURCETREE_DB_DIR}/.db_done"
   fi
}



#
# update
#
db_is_updating()
{
   log_entry "db_is_updating" "$@"

   local prefix="$1"

   if [ -f "${prefix}${SOURCETREE_DB_DIR}/.db_update" ]
   then
      log_debug "\"${PWD}/${prefix}${SOURCETREE_DB_DIR}/.db_done\" exists"
      return 0
   fi

   log_debug "\"${PWD}/${prefix}${SOURCETREE_DB_DIR}/.db_update\" not found"
   return 1
}


db_set_update()
{
   log_entry "db_set_update" "$@"

   [ $# -eq 0 ] || internal_fail "api error"

   mkdir_if_missing "${SOURCETREE_DB_DIR}"
   redirect_exekutor "${SOURCETREE_DB_DIR}/.db_update"  echo "# intentionally left blank"
}


db_clear_update()
{
   log_entry "db_clear_update" "$@"

   [ $# -eq 0 ] || internal_fail "api error"

   remove_file_if_present "${SOURCETREE_DB_DIR}/.db_update"
}



#
# If a previous update crashed, we wan't to let the user know.
#
db_ensure_consistency()
{
   log_entry "db_ensure_consistency" "$@"

   [ $# -eq 0 ] || internal_fail "api error"

   if db_is_updating && [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
   then
      log_error "A previous update was incomplete.
Suggested resolution (in $PWD):
    ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME}clean${C_ERROR}
    ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME}update${C_ERROR}

Or do you feel lucky ? Then try again with
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} -f ${MULLE_ARGUMENTS}${C_ERROR}
But you've gotta ask yourself one question: Do I feel lucky ?
Well, do ya, punk?"
      exit 1
   fi
}


# DB is "" clean, then anything goes.
#
# DB is marked as "normal" or "recursive". Recursive is just a
# hint to output a warning to the user, that originally this
# DB was created recursively and maybe he forgot OPTION_RECURSIVE.
#
#  Mode       | Relative | Description
# ------------|----------|------------------------------
#  normal     | ""       | OK
#  normal     | relpath  | FAIL (not possible)
#  recursive  | ""       | OK
#  recursive  | relpath  | FAIL (not possible)
#  share      | *        | FAIL (not possible)

#
# DB is marked as "share". The db was created with OPTION_SHARE.
#
#  Mode    | Relative | Description
# ---------|----------|------------------------------
#  off     | *        | FAIL (not possible)
#  share   | *        | OK
#
#

#
# Other modes like print or clean are not checked
#
db_ensure_compatible_dbtype()
{
   log_entry "db_ensure_compatible_dbtype" "$@"

   local mode="$1"

   local dbtype

   dbtype="`db_get_dbtype`"
   case "${dbtype}" in
      "")
         return
      ;;

      normal)
         case "${mode}" in
            recursive)
               if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
               then
                  fail "Database was not constructed with the recursive option
This is not really problem. Restate your intention with
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} -f ${MULLE_ARGUMENTS}${C_ERROR}
or append the -r flag for recursion."
               fi
            ;;

            share|noshare)
               fail "Database was constructed with the $mode option. If you
want to promote it to shared operation do:
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME}clean${C_ERROR}
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME}${MULLE_ARGUMENTS} --share${C_ERROR}"
            ;;
         esac
         ;;

      recursive)
         case "${mode}" in
            normal)
               if [ "${MULLE_FLAG_MAGNUM_FORCE}" = "NONE" ]
               then
                  fail "Database was constructed with the recursive option
This is not really problem. Restate your intention with:
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} -f ${MULLE_ARGUMENTS}${C_ERROR}
or remove the -r flag for non-recursion."
               fi
            ;;

            share|noshare)
               fail "Database was not constructed with the share option. If you
want to promote it to shared operation do:
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME}clean${C_ERROR}
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME}${MULLE_ARGUMENTS} --share${C_ERROR}"
            ;;
         esac
         ;;

      share)
         case "${mode}" in
            recursive|normal)
               fail "Database was constructed with the shared option. You probably
want to run
   ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME} ${MULLE_ARGUMENTS} --share${C_ERROR}
Or, if you want to revert to non-shared operation do:
    ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME}clean${C_ERROR}
    ${C_RESET_BOLD}${MULLE_EXECUTABLE_NAME}update${C_ERROR}"
            ;;
         esac
      ;;
   esac
}


#
# 0 : OK
# 1 : needs update
# 2 : config file missing
#
db_is_uptodate()
{
   log_entry "db_is_uptodate" "$@"

   local prefixed="$1"

   local configtimestamp
   local dbtimestamp

   configtimestamp="`nodeline_config_timestamp "${prefixed}"`"
   if [ -z "${configtimestamp}" ]
   then
      return 2
   fi

   dbtimestamp="`db_timestamp "${prefixed}"`"

   log_debug "Timestamps: config=${configtimestamp} db=${dbtimestamp:-0}"

   [ "${configtimestamp}" -le "${dbtimestamp:-0}" ]
}


# sets external variables!!
_db_set_default_options()
{
   log_entry "_db_set_default_options" "$@"

   case "`db_get_dbtype`" in
      share)
         OPTION_RECURSIVE="YES"
         OPTION_SHARE="YES"
      ;;

      recursive)
         OPTION_RECURSIVE="YES"
         OPTION_SHARE="NO"
      ;;


      "")
         OPTION_RECURSIVE="YES"  # probably what one wants
         OPTION_SHARE="NO"
      ;;

      *)
         OPTION_RECURSIVE="NO"
         OPTION_SHARE="NO"
      ;;
   esac
}


_db_has_graveyard()
{
   log_entry "db_exists" "$@"

   local prefix="$1"

   [ -d "${prefix}${SOURCETREE_DB_DIR}/.graveyard" ]
}


_db_is_graveyard_only()
{
   if ! _db_has_graveyard
   then
      return 1
   fi

   (
      shopt -s nullglob
      files="${prefix}${SOURCETREE_DB_DIR}"/.db*

      [ -z "${files}" ]
   )
}


db_reset()
{
   log_entry "db_reset" "$@"

   local prefix="$1"
   local keepgraveyard="${2:-YES}"

   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   if ! db_exists "${prefix}"
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

   if [ "${keepgraveyard}" = "NO" ]|| ! _db_has_graveyard
   then
      rmdir_safer "${prefix}${SOURCETREE_DB_DIR}"
      return
   fi

   (
      shopt -s nullglob

      files="${prefix}${SOURCETREE_DB_DIR}"/* \
            "${prefix}${SOURCETREE_DB_DIR}"/.[^g]*
      if [ ! -z "${files}" ]
      then
         exekutor rm "${files}"
      fi
   )
}




db_reset_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} reset [options]

   Throw away the local database for a fresh update. A graveyard will be kept,
   unless you use the -g option.

   This command only reads the local database.

Options:
   -g   : also remove the graveyard (where old zombies are buried)
EOF
  exit 1
}


db_reset_main()
{
   log_entry "db_reset_main" "$@"

   local OPTION_REMOVE_GRAVEYARD="DEFAULT"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            db_reset_usage
         ;;


         -g|--remove-graveyard)
            OPTION_REMOVE_GRAVEYARD="YES"
         ;;

         --no-remove-graveyard)
            OPTION_REMOVE_GRAVEYARD="NO"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown clean option $1"
            db_reset_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || db_reset_usage

   db_reset "" "${OPTION_REMOVE_GRAVEYARD}"
}

