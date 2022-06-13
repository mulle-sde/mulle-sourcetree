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


sourcetree::clean::usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} clean [options]

   Remove everything fetched or symlinked, except when you specify
   a graveyard option. You can combine both with a second --fs though.
   The database itself will not be removed. Use \`reset\` for that.
   
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
sourcetree::clean::walk()
{
   log_entry "${C_RESET}sourcetree::clean::walk${C_DEBUG}" "${NODE_FILENAME}" "${NODE_MARKS}"

   case "${NODE_TYPE}" in
      none)
         log_fluff "\"${NODE_FILENAME}\" with nodetype none is ignored"
         return
      ;;
   esac

   local filename
   local marks

   filename="`sourcetree::db::fetch_filename_for_uuid "${WALK_DATASOURCE}" "${NODE_UUID}" `"

   if [ -z "${filename}" ]
   then
      # database has nothing for it
      log_fluff "\"${NODE_FILENAME}\" has no known update in \"${WALK_DATASOURCE}\", so not cleaning it"
      return
   fi

   marks="${NODE_MARKS}"

   #
   # the actual desired filename for a config file is pretty complicated though
   #
   if sourcetree::nodemarks::disable "${marks}" "delete"
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


sourcetree::clean::bury()
{
   local filename="$1"

   local uuid

   sourcetree::node::r_uuidgen
   uuid="${RVAL}"

   sourcetree::db::bury "${SOURCETREE_START}" "${uuid}" "${filename}"
}


sourcetree::clean::do()
{
   log_entry "sourcetree::clean::do" "$@"

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

   # filternodetypes
   # filterpermissions
   # callbackqualifier
   # descendqualifier
   # mode
   commands="`sourcetree::walk::walk_db_uuids "ALL" \
                            "descend-skip-symlink" \
                            "" \
                            "" \
                            "${mode},no-dbcheck,no-trace,dedupe-filename" \
                            "sourcetree::clean::walk" `"


   log_debug "COMMANDS: ${commands}"

   local line
   local filename

   local protected

   shell_disable_glob; IFS=$'\n'
   for line in ${commands}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      filename="${line:2}"
      case "${line}" in
         P*)
            r_add_line "${protected}" "${filename}"
            protected=${RVAL}
         ;;
      esac
   done

   if [ -z "${MULLE_PARALLEL_SH}" ]
   then
      # shellcheck source=mulle-file.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-parallel.sh"      || return 1
   fi

   local uuid

   local _parallel_statusfile
   local _parallel_maxjobs
   local _parallel_jobs
   local _parallel_fails

   _parallel_begin

   shell_disable_glob; IFS=$'\n'
   for line in ${commands}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      filename="${line:2}"
      if find_line "${protected}" "${filename}"
      then
         continue
      fi

      case "${line}" in
         D*|F*)
            # doesn't work well in parallel for reasons to be determined
            sourcetree::clean::bury "${filename}"
         ;;

         L*)
            _parallel_execute remove_file_if_present "${filename}"
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   _parallel_end

   :
}


sourcetree::clean::main()
{
   log_entry "sourcetree::clean::main" "$@"

   local OPTION_WALK_DB="DEFAULT"
   local OPTION_IS_UPTODATE='NO'
   local OPTION_CLEAN_SHARE_DIR='DEFAULT'
   local OPTION_CLEAN_GRAVEYARD='DEFAULT'
   local OPTION_CLEAN_FS='DEFAULT'
   local OPTION_CLEAN_CONFIG_FILE='NO'

   [ -z "${MULLE_SOURCETREE_STASH_DIR}" ] && _internal_fail "MULLE_SOURCETREE_STASH_DIR is empty"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::clean::usage
         ;;

         --config)
            OPTION_CLEAN_CONFIG_FILE='YES'
            OPTION_CLEAN_FS='NO'
            OPTION_CLEAN_GRAVEYARD='NO'
            OPTION_CLEAN_SHARE_DIR='NO'
            OPTION_WALK_DB='NO'
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
            sourcetree::clean::usage "Unknown clean option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree::clean::usage "Superflous arguments $*"


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

         shell_enable_nullglob
         # clean for all hosts
         for graveyard in ${MULLE_SOURCETREE_VAR_DIR}/../../*/sourcetree/graveyard
         do
            r_simplified_path "${graveyard}"
            rmdir_safer "${RVAL}"
         done
         shell_disable_nullglob
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
      if ! sourcetree::cfg::r_config_exists "${SOURCETREE_START}"
      then
         log_verbose "There is no sourcetree here (\"${SOURCETREE_CONFIG_DIR}\")"
      fi

      local rval

      rval=0
      if sourcetree::db::exists "${SOURCETREE_START}"
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

         sourcetree::clean::do "${mode}"
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
      if [ "${OPTION_CLEAN_SHARE_DIR}" = 'DEFAULT' ]
      then
         rmdir_if_empty "${MULLE_SOURCETREE_STASH_DIR}"
      fi
   fi

   if [ "${OPTION_CLEAN_CONFIG_FILE}" = 'YES' ]
   then
      sourcetree::cfg::file_remove "${SOURCETREE_START}"
   fi
}

