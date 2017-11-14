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
MULLE_SOURCETREE_RESET_SH="included"


sourcetree_db_reset()
{
   log_entry "sourcetree_db_reset" "$@"

   local prefix="$1"
   local keepgraveyard="${2:-YES}"

   case "${prefix}" in
      ""|*/)
      ;;

      *)
         prefix="${prefix}/"
      ;;
   esac

   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR is not set"

   if ! db_dir_exists "${prefix}"
   then
      return 0
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


walk_reset()
{
   log_entry "walk_reset" "$@"

   sourcetree_db_reset "${MULLE_PREFIX}${MULLE_RAW_ADDRESS}" "$@"
}


sourcetree_reset_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} reset [options]

   Throw away the local database for a fresh update. A graveyard will be kept,
   unless you use the -g option.

   This command only reads the local database.

Options:
   -g   : also remove the graveyard (where old zombies are buried)
   -r   : recursively reset all sub databases
EOF
  exit 1
}


sourcetree_reset_main()
{
   log_entry "sourcetree_reset_main" "$@"

   local OPTION_REMOVE_GRAVEYARD="DEFAULT"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            sourcetree_reset_usage
         ;;


         -g|--remove-graveyard)
            OPTION_REMOVE_GRAVEYARD="YES"
         ;;

         --no-remove-graveyard)
            OPTION_REMOVE_GRAVEYARD="NO"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown reset option $1"
            sourcetree_reset_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_reset_usage

   if [ "${SOURCETREE_MODE}" != "flat" ]
   then
      if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
      then
         # shellcheck source=mulle-sourcetree-nodeline.sh
         . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
      fi

      sourcetree_walk_config_internal "${SOURCETREE_MODE}" \
            _reset_walk "${OPTION_REMOVE_GRAVEYARD}"
   fi

   sourcetree_db_reset "" "${OPTION_REMOVE_GRAVEYARD}"
}


sourcetree_reset_initialize()
{
   log_entry "sourcetree_reset_initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-db.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh"
   fi
   if [ -z "${MULLE_SOURCETREE_NODE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-node.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-node.sh" || exit 1
   fi
   if [ -z "${MULLE_SOURCETREE_NODELINE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodeline.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodeline.sh" || exit 1
   fi
}


sourcetree_reset_initialize

:

