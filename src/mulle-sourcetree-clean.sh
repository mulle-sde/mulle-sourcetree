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
MULLE_SOURCETREE_CLEAN_SH="included"

sourcetree_clean_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} clean

   Remove everything fetched or symlinked.
EOF
  exit 1
}


walk_clean()
{
   log_entry "${C_RESET}walk_clean${C_DEBUG}" "${MULLE_FILENAME}" "${MULLE_MARKS}"

   local filename
   local marks

   filename="`db_fetch_filename_for_uuid "${MULLE_DATASOURCE}" "${MULLE_UUID}" `"
   marks="${MULLE_MARKS}"

   #
   # the actual desired filename for a config file is pretty complicated though
   #
   if nodemarks_contain_nodelete "${marks}"
   then
      log_verbose "${C_RESET_BOLD}${filename}${C_VERBOSE} is protected from delete"
      NO_DELETES="`add_line "${NO_DELETES}" "${filename}" `"
      return
   fi

   # could move stuff to graveyard, but we don't
   if [ -e "${filename}" ]
   then
      if [ ! -L "${filename}" ]
      then
         log_fluff "Symlink \"${filename}\" marked for delete."
         DELETE_FILES="`add_line "${DELETE_FILES}" "${filename}" `"
      else
         if [ -d "${filename}" ]
         then
            log_fluff "Dictionary \"${filename}\" marked for delete."
            DELETE_DIRECTORIES="`add_line "${DELETE_DIRECTORIES}" "${filename}" `"
         else
            log_fluff "File (or syml) \"${filename}\" marked for delete."
            DELETE_FILES="`add_line "${DELETE_FILES}" "${filename}" `"
         fi
      fi
   else
      log_fluff "Destination \"${filename}\" doesn't exist."
   fi
}


sourcetree_clean()
{
   log_entry "sourcetree_clean" "$@"

   local filternodetypes="$1"
   local filterpermissions="$2"
   local filtermarks="$3"
   local mode="$4"

   local OPTION_EVAL_EXEKUTOR

   OPTION_EVAL_EXEKUTOR="NO"

   #
   # because of share configuration we can have duplicates
   # but nodelete needs to be adhered to
   #
   local NO_DELETES
   local DELETE_FILES
   local DELETE_DIRECTORIES

   NO_DELETES=
   DELETE_FILES=
   DELETE_DIRECTORIES=

   VISIT_TWICE="YES"  # need to pick up nodeletes

   #
   # We must walk the dbs, because only the dbs know where
   # stuff eventually ended up being placed (think share)
   #
   walk_db_uuids "${filternodetypes}" \
                 "${filterpermissions}" \
                 "${filtermarks}" \
                 "${mode}" \
                 "walk_clean"

   local filename

   log_debug "DELETE_FILES:       ${DELETE_FILES}"
   log_debug "DELETE_DIRECTORIES: ${DELETE_DIRECTORIES}"
   log_debug "NO_DELETES:         ${NO_DELETES}"

   local uuid

   IFS="
"
   for filename in ${DELETE_FILES} ${DELETE_DIRECTORIES}
   do
      IFS="${DEFAULT_IFS}"

      if ! fgrep -q -x "${filename}" <<< "${NO_DELETES}"
      then
         uuid="`node_uuidgen`"

         db_bury "${SOURCETREE_START}" "${uuid}" "${filename}"
      fi
   done

   IFS="${DEFAULT_IFS}"
}


sourcetree_clean_main()
{
   log_entry "sourcetree_clean_main" "$@"

   local OPTION_MARKS="ANY"
   local OPTION_PERMISSIONS="" # empty!
   local OPTION_NODETYPES="ALL"
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_IS_UPTODATE="NO"
   local OPTION_OUTPUT_HEADER="DEFAULT"
   local OPTION_OUTPUT_RAW="YES"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            sourcetree_clean_usage
         ;;

         #
         # more common flags
         #
         -m|--marks)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_MARKS="$1"
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_NODETYPES="$1"
         ;;

         -p|--permissions)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_PERMISSIONS="$1"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PRECLEAN}: Unknown clean option $1"
            sourcetree_clean_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_clean_usage

   if ! cfg_exists "${SOURCETREE_START}"
   then
      log_info "There is no ${SOURCETREE_CONFIG_FILE} here"
   fi

   local mode

   mode="${SOURCETREE_MODE}"
   if [ "${SOURCETREE_MODE}" != "flat" ]
   then
      mode="`concat "${mode}" "pre-order"`"
   fi

   sourcetree_clean "${OPTION_NODETYPES}" \
                    "${OPTION_PERMISSIONS}" \
                    "${OPTION_MARKS}" \
                    "${mode}"
}


sourcetree_clean_initialize()
{
   log_entry "sourcetree_clean_initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   fi
}


sourcetree_clean_initialize

:
