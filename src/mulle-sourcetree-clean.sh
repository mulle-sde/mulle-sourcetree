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
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} clean [options]

   Remove everything fetched or symlinked, except when you specify
   a graveyard option. You can combine both with a second --fs though.

Options:
   --all-graveyards : remove all graveyards, implies --no-fs
   --fs             : remove fetched files (default)
   --graveyard      : remove host graveyard, implies --no-fs
   --no-fs          : don't remove fetched files
   --no-graveyard   : don't remove graveyards (default)
   --no-share       : don't forcibly remove share directory (default)
   --share          : forcibly remove share directory

EOF
  exit 1
}


#
# emit clean action
#
#  P - protect, don't delete
#  L - delete symlink
#  D - delete directory
#  F - delete file
#
walk_clean()
{
   log_entry "${C_RESET}walk_clean${C_DEBUG}" "${MULLE_FILENAME}" "${MULLE_MARKS}"

   case "${MULLE_NODETYPE}" in
      none)
         log_fluff "\"${MULLE_FILENAME}\" with nodetype none is ignored"
         return
      ;;
   esac

   local filename
   local marks

   filename="`db_fetch_filename_for_uuid "${MULLE_DATASOURCE}" "${MULLE_UUID}" `"

   if [ -z "${filename}" ]
   then
      # database has nothing for it
      log_fluff "\"${MULLE_FILENAME}\" has no known update in \"${MULLE_DATASOURCE}\", so not cleaning it"
      return
   fi

   marks="${MULLE_MARKS}"

   #
   # the actual desired filename for a config file is pretty complicated though
   #
   if ! nodemarks_contain "${marks}" "delete"
   then
      log_fluff "\"${filename}\" is protected from delete"
      echo "P ${filename}"
   fi

   if [ -e "${filename}" ]
   then
      if [ -L "${filename}" ]
      then
         log_fluff "Symlink \"${filename}\" marked for delete."
         echo "L ${filename}"
      else
         if [ -d "${filename}" ]
         then
            log_fluff "Directory \"${filename}\" marked for delete."
            echo "D ${filename}"
         else
            log_fluff "File \"${filename}\" marked for delete."
            echo "F ${filename}"
         fi
      fi
   else
      log_fluff "Destination \"${filename}\" doesn't exist."
   fi
}


sourcetree_clean()
{
   log_entry "sourcetree_clean" "$@"

   local mode="$1"

   local OPTION_EVAL_EXEKUTOR

   OPTION_EVAL_EXEKUTOR='NO'

   #
   # because of share configuration we can have duplicates
   # but no-delete needs to be adhered to
   #
   local NO_DELETES
   local DELETE_FILES
   local DELETE_SYMLINKS
   local DELETE_DIRECTORIES

   NO_DELETES=
   DELETE_FILES=
   DELETE_DIRECTORIES=
   DELETE_SYMLINKS=

   #
   # We must walk the dbs, because only the dbs know where
   # stuff eventually ended up being placed (think share)
   #
   local commands

   commands="`walk_db_uuids "ALL" \
                             "" \
                             "" \
                             "" \
                             "${mode},no-dbcheck,no-trace,dedupe-filename" \
                             "walk_clean" `"


   log_debug "COMMANDS: ${commands}"

   local line
   local filename

   local protected

   set -o noglob ; IFS=$'\n'
   for line in ${commands}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      filename="${line:2}"
      case "${line}" in
         P*)
            r_add_line "${protected}" "${filename}"
            protected=${RVAL}
         ;;
      esac
   done

   local uuid

   set -o noglob ; IFS=$'\n'
   for line in ${commands}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      filename="${line:2}"
      if find_line "${protected}" "${filename}"
      then
         continue
      fi

      case "${line}" in
         D*|F*)
            uuid="`node_uuidgen`"

            db_bury "${SOURCETREE_START}" "${uuid}" "${filename}"
         ;;

         L*)
            remove_file_if_present "${filename}"
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   :
}


sourcetree_clean_main()
{
   log_entry "sourcetree_clean_main" "$@"

   local OPTION_WALK_DB="DEFAULT"
   local OPTION_IS_UPTODATE='NO'
   local OPTION_CLEAN_SHARE_DIR='DEFAULT'
   local OPTION_CLEAN_GRAVEYARD='DEFAULT'
   local OPTION_CLEAN_FS='DEFAULT'

   [ -z "${MULLE_SOURCETREE_STASH_DIR}" ] && internal_fail "MULLE_SOURCETREE_STASH_DIR is empty"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_clean_usage
         ;;

         --share)
            OPTION_CLEAN_SHARE_DIR='YES'
         ;;

         --no-share)
            OPTION_CLEAN_SHARE_DIR='NO'
         ;;

         --graveyard)
            OPTION_CLEAN_GRAVEYARD='YES'
            OPTION_CLEAN_FS='NO'
         ;;

         --all-graveyards)
            OPTION_CLEAN_GRAVEYARD='ALL'
            OPTION_CLEAN_FS='NO'
         ;;

         --fs)
            OPTION_CLEAN_FS='YES'
         ;;

         --no-db)
            OPTION_CLEAN_FS='NO'
         ;;

         -*)
            sourcetree_clean_usage "Unknown clean option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_clean_usage "Superflous arguments $*"


   if [ -z "${MULLE_PATH_SH}" ]
   then
      # shellcheck source=mulle-path.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"      || return 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      # shellcheck source=mulle-file.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh"      || return 1
   fi

   case "${OPTION_CLEAN_GRAVEYARD}" in
      NO|DEFAULT)
      ;;

      ALL)
         local graveyard

         log_verbose "Removing all graveyards"

         shopt -s nullglob
         # clean for all hosts
         for graveyard in ${MULLE_SOURCETREE_VAR_DIR}/../../*/sourcetree/graveyard
         do
            r_simplified_path "${graveyard}"
            rmdir_safer "${RVAL}"
         done
         shopt -u nullglob
      ;;

      YES)
         local graveyard

         graveyard="${MULLE_SOURCETREE_VAR_DIR}/../../${MULLE_HOSTNAME}/sourcetree/graveyard"

         log_verbose "Removing host graveyard"
         r_simplified_path "${graveyard}"
         rmdir_safer "${RVAL}"
      ;;
   esac

   if [ "${OPTION_CLEAN_FS}" != 'NO' ]
   then
      if ! cfg_exists "${SOURCETREE_START}"
      then
         log_verbose "There is no \"${SOURCETREE_CONFIG_FILENAME}\" here"
      fi

      local rval

      rval=0
      if db_exists "${SOURCETREE_START}"
      then

         # shellcheck source=mulle-sourcetree-walk.sh
         [ -z "${MULLE_SOURCETREE_WALK_SH}" ] && \
            . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1

         local mode

         mode="${SOURCETREE_MODE}"
         if [ "${SOURCETREE_MODE}" != "flat" ]
         then
            r_comma_concat "${mode}" "breadth-order"
            mode="${RVAL}"
         fi

         r_comma_concat "${mode}" "ignore-bequeath"
         mode="${RVAL}"


         sourcetree_clean "${mode}"
      else
         log_verbose "Already clean"
      fi
   fi

   if [ "${OPTION_CLEAN_SHARE_DIR}" = 'YES' ]
   then
      # TODO: if MULLE_SOURCETREE_STASH_DIR is inside project remove it
      # if its outside probably not...
      rmdir_safer "${MULLE_SOURCETREE_STASH_DIR}"
   else
      rmdir_if_empty "${MULLE_SOURCETREE_STASH_DIR}"
   fi
}

