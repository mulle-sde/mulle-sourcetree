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
MULLE_SOURCETREE_BUILDORDER_SH="included"


sourcetree_buildorder_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} buildorder [options]

   Print all sourcetree addresses according to the following rules:

   * ignore nodes marked as "no-build"
   * ignore nodes marked as "no-require", whose are missing
   * ignore nodes marked as "no-os-${MULLE_UNAME}" (platform dependent of course)
   * include nodes marked as "only-os-${MULLE_UNAME}, regardless of the previous
     rules

   In a make based project, this can be used to build everything like this:

      ${MULLE_EXECUTABLE_NAME} buildorder | while read _address
      do
         ( cd "${_address}" ; make ) || break
      done

Options:
   --output-marks  : output marks of sourcetree node
EOF
  exit 1
}


print_buildorder_line()
{
   local line="$1"

   if [ ! -z "${MULLE_SOURCETREE_SHARE_DIR}" ]
   then
      case "${line}" in
         ${MULLE_SOURCETREE_SHARE_DIR}/*)
            echo '${MULLE_SOURCETREE_SHARE_DIR}'"${line#${MULLE_SOURCETREE_SHARE_DIR}}"
            return 0
         ;;
      esac
   fi

   echo "${line#${MULLE_VIRTUAL_ROOT}/}"
}



sourcetree_buildorder_main()
{
   log_entry "sourcetree_buildorder_main" "$@"

   local OPTION_MARKS="NO"
   local OPTION_PRINT_ENV="YES"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_buildorder_usage
         ;;

         --output-marks)
            OPTION_MARKS="YES"
         ;;

         --output-no-marks|--no-output-marks)
            OPTION_MARKS="NO"
         ;;

         --no-print-env)
            OPTION_PRINT_ENV="NO"
         ;;

         -*)
            sourcetree_buildorder_usage "Unknown buildorder option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_buildorder_usage "Superflous arguments \"$*\""

   local echocmd
   local formatstr

   echocmd="echo"
   formatstr='"${MULLE_FILENAME}"'

   if [ "${OPTION_PRINT_ENV}" = "YES" ]
   then
      echocmd="print_buildorder_line"
   fi

   if [ "${OPTION_MARKS}" = "YES" ]
   then
      formatstr='"${MULLE_FILENAME};${MULLE_MARKS}"'
   fi

   sourcetree_walk "" "" "build,os-${MULLE_UNAME};;;only-os-${MULLE_UNAME}" \
                   "${SOURCETREE_MODE} --in-order" \
                   "${echocmd}" "${formatstr}"
}


sourcetree_buildorder_initialize()
{
   log_entry "sourcetree_buildorder_initialize"

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   fi
}


sourcetree_buildorder_initialize

:

