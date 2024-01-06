# shellcheck shell=bash
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
MULLE_SOURCETREE_RESET_SH='included'



sourcetree::reset::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"
   
    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} reset [options]

   Throw away the local database for a fresh update. A graveyard will be kept,
   unless you use the -g option.

   You can use the -r flag, to clean recursively:

      ${MULLE_USAGE_NAME} -r reset

Options:
   -g   : also remove the graveyard (where old zombies are buried)
EOF
  exit 1
}

sourcetree::reset::db()
{
   log_entry "sourcetree::reset::db" "$@"

   local database="${1:-/}"

   log_verbose "Reset database \"${database}\""

   sourcetree::db::reset "${database}"
}


sourcetree::reset::walk()
{
   log_entry "sourcetree::reset::walk" "$@"

   sourcetree::reset::db "/${WALK_VIRTUAL_ADDRESS}"
}



sourcetree::reset::main()
{
   log_entry "sourcetree::reset::main" "$@"

   local OPTION_REMOVE_GRAVEYARD="DEFAULT"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::reset::usage
         ;;

         -g|--remove-graveyard)
            OPTION_REMOVE_GRAVEYARD='YES'
         ;;

         --no-remove-graveyard)
            OPTION_REMOVE_GRAVEYARD='NO'
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown reset option $1"
            sourcetree::reset::usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree::reset::usage

   if [ "${SOURCETREE_MODE}" != "flat" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      include "sourcetree::walk"

      sourcetree::walk::walk_internal "${SOURCETREE_MODE},pre-order,skip-symlink,walkdb,no-dbcheck,no-trace" \
            sourcetree::reset::walk
   fi

   sourcetree::reset::db "/"
}


sourcetree_reset_initialize()
{
   log_entry "sourcetree_reset_initialize"

   include "sourcetree::db"
   include "sourcetree::marks"
   include "sourcetree::node"
   include "sourcetree::nodeline"
}


sourcetree_reset_initialize

:

