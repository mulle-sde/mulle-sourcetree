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

   Print all sourcetree addresses according to the following rules with
   precedence give in that order:

   * ignore nodes marked as "no-build"
   * ignore nodes marked as "no-os-${MULLE_UNAME}"
   * ignore nodes marked as "no-os-${MULLE_UNAME}-build"
   * ignore nodes marked with "only-os-<platform>" except "only-os-${MULLE_UNAME}" or "only-os-${MULLE_UNAME}-build"

   In a make based project, this can be used to build everything like this:

      ${MULLE_EXECUTABLE_NAME} buildorder | while read _address
      do
         ( cd "${_address}" ; make ) || break
      done

Options:
   --output-marks            : output marks of sourcetree node
   --callback <f>            : a callback function to modiy the output
EOF
  exit 1
}


print_buildorder_line()
{
   log_entry "print_buildorder_line" "$@"

   #
   # if we are in root, we want to add no-memo marks to the output, but
   # only for subprojects
   #
   if [ ! -z "${OPTION_CALLBACK}" ]
   then
      "${OPTION_CALLBACK}" # "${line}"
   fi

   if [ "${SOURCETREE_MODE}" = "share" -a \
        "${OPTION_PRINT_ENV}" = 'YES' -a \
        ! -z "${MULLE_SOURCETREE_STASH_DIR}" -a \
        "${MULLE_SOURCETREE_STASH_DIR}" != "${MULLE_VIRTUAL_ROOT}" ]
   then
      local reduce

      reduce="${MULLE_FILENAME#${MULLE_SOURCETREE_STASH_DIR}}"
      if [ "${reduce}" != "${MULLE_FILENAME}" ]
      then
         MULLE_FILENAME='${MULLE_SOURCETREE_STASH_DIR}'"${reduce}"
      fi
   fi

   if [ "${OPTION_ABSOLUTE}" = 'NO' ]
   then
      MULLE_FILENAME="${MULLE_FILENAME#${MULLE_VIRTUAL_ROOT}/}"
   fi

   if [ "${OPTION_MARKS}" = 'YES' ]
   then
      rexekutor echo "${MULLE_FILENAME};${MULLE_MARKS}"
      return
   fi

   rexekutor echo "${MULLE_FILENAME}"
}



sourcetree_buildorder_main()
{
   log_entry "sourcetree_buildorder_main" "$@"

   local OPTION_MARKS='NO'
   local OPTION_PRINT_ENV='YES'
   local OPTION_CALLBACK
   local OPTION_ABSOLUTE='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_buildorder_usage
         ;;

         --output-marks)
            OPTION_MARKS='YES'
         ;;

         --output-absolute)
            OPTION_ABSOLUTE='YES'
         ;;

         --output-relative)
            OPTION_ABSOLUTE='NO'
         ;;

         --output-no-marks|--no-output-marks)
            OPTION_MARKS='NO'
         ;;

         --callback)
            [ $# -eq 1 ] && sourcetree_buildorder_usage "Missing argument to \"$1\""
            shift

            local input
            local callbackscript
            local randomstring

            #
            # remove possible cruft before function name
            #
            input="`egrep -v '^#' <<< "$1" | sed -e '/^ *$/d' `"
            randomstring="`uuidgen | cut -c'1-6'`"

            callbackscript="_cb_${randomstring}_${input#function}"
            OPTION_CALLBACK="`echo ${callbackscript%%(*}`"
            eval "function ${callbackscript}" || fail "Callback \"${input}\" could not be parsed"
         ;;

         --no-print-env)
            OPTION_PRINT_ENV='NO'
         ;;

         --print-qualifier)
            echo "${SOURCETREE_BUILDORDER_QUALIFIER}"
            exit 0
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


   sourcetree_walk "" \
                   "descend-symlink" \
                   "${SOURCETREE_BUILDORDER_QUALIFIER}" \
                   "${SOURCETREE_MODE},in-order" \
                   "print_buildorder_line"
}


r_make_buildorder_qualifier()
{
   log_entry "r_make_buildorder_qualifier"

   local qualifier="$1"

   if [ ! -z "${qualifier}" ]
   then
      qualifier="${qualifier} AND "
   fi

   if [ -z "${MULLE_OS_VERSION}" ]
   then
      case "${MULLE_UNAME}" in
         darwin)
            MULLE_OS_VERSION="`sw_vers -productVersion`"
         ;;
      esac
   fi

   qualifier="${qualifier} \
NOT MATCHES no-os-${MULLE_UNAME} \
AND NOT MATCHES no-os-${MULLE_UNAME}-build \
AND (NOT MATCHES only-os-* OR MATCHES only-os-${MULLE_UNAME} OR MATCHES only-os-${MULLE_UNAME}-build)"

   if [ ! -z "${MULLE_OS_VERSION}" ]
   then
      qualifier="${qualifier} \
AND VERSION version-min-${MULLE_UNAME} <= ${MULLE_OS_VERSION} \
AND VERSION version-max-${MULLE_UNAME} >= ${MULLE_OS_VERSION}"
   fi

   RVAL="${qualifier}"
}


sourcetree_buildorder_initialize()
{
   log_entry "sourcetree_buildorder_initialize"

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   fi

   if [ -z "${MULLE_VERSION_SH}" ]
   then
      # shellcheck source=../../mulle-bashfunctions/src/mulle-version.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-version.sh" || exit 1
   fi

   r_make_buildorder_qualifier "MATCHES build"
   SOURCETREE_BUILDORDER_QUALIFIER="${RVAL}"
}


sourcetree_buildorder_initialize

:

