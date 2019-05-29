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
MULLE_SOURCETREE_CRAFTORDER_SH="included"


sourcetree_craftorder_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} craftorder [options]

   Print all sourcetree addresses according to the following rules with
   precedence give in that order:

   * ignore nodes marked as "no-build"
   * ignore nodes marked as "no-os-${MULLE_UNAME}"
   * ignore nodes marked as "no-os-${MULLE_UNAME}-build"
   * ignore nodes marked with "only-os-<platform>" except "only-os-${MULLE_UNAME}" or "only-os-${MULLE_UNAME}-build"

   In a make based project, this can be used to build everything like this:

      ${MULLE_EXECUTABLE_NAME} craftorder | while read address
      do
         ( cd "\${address}" ; make ) || break
      done

Options:
   --callback <f>    : a callback function to modify the output
   --output-eval     : resolve variables in the output
   --output-no-marks : don't output marks of sourcetree node
   --print-qualifier : prints qualifier for sourcetree marks, then exits

EOF
  exit 1
}


r_create_craftorder_filename()
{
   local filename="$1"

   if [ "${SOURCETREE_MODE}" = "share" -a \
        "${OPTION_PRINT_ENV}" = 'YES' -a \
        ! -z "${MULLE_SOURCETREE_STASH_DIR}" -a \
        "${MULLE_SOURCETREE_STASH_DIR}" != "${MULLE_VIRTUAL_ROOT}" ]
   then
      local reduce

      reduce="${filename#${MULLE_SOURCETREE_STASH_DIR}}"
      if [ "${reduce}" != "${filename}" ]
      then
         filename='${MULLE_SOURCETREE_STASH_DIR}'"${reduce}"
      fi
   fi

   if [ "${OPTION_ABSOLUTE}" = 'NO' ]
   then
      filename="${filename#${MULLE_VIRTUAL_ROOT}/}"
   fi

   RVAL="${filename%#*}"
}


collect_craftorder_line()
{
   log_entry "collect_craftorder_line" "$@"

   local filename

   r_create_craftorder_filename "${_filename}"
   filename="${RVAL}"

   rexekutor echo "${filename}"
}


augment_craftorder_line()
{
   log_entry "augment_craftorder_line" "$@"

   local filename
   local marks

   r_create_craftorder_filename "${_filename}"
   filename="${RVAL}"

   if ! find_line "${_remainder_collection}" "${filename}"
   then
      return 0
   fi
   _remainder_collection="`fgrep -x -v -e "${filename}" <<< "${_remainder_collection}"`"

   marks="${_marks}"
   if [ ! -z "${OPTION_CALLBACK}" ]
   then
      if "${OPTION_CALLBACK}" "${_datasource}" "${_address}" "${_nodetype}" "${marks}" "${filename}"
      then
         marks="${RVAL}"
      fi
   fi

   if [ "${OUTPUT_RAW_USERINFO}" = 'YES' ]
   then
      rexekutor echo "${filename};${marks};${_raw_userinfo}"
   else
      rexekutor echo "${filename};${marks}"
   fi

   if [ -z "${_remainder_collection}" ]
   then
      log_debug "Done with collection"
      exit 2  #signal done but no error
   fi

   return 0
}


output_craftorder()
{
   log_entry "output_craftorder" "$@"

   local collection="$1"

   if [ "${OUTPUT_EVAL}" = 'YES' ]
   then
      local line

      IFS=$'\n'; set -f
      for line in ${collection}
      do
         eval "echo \"${line}\""
      done
      IFS="${DEFAULT_IFS}"; set +f
   else
      echo "${collection}"
   fi
}


sourcetree_craftorder_main()
{
   log_entry "sourcetree_craftorder_main" "$@"

   local OPTION_PRINT_ENV='YES'
   local OPTION_CALLBACK
   local OPTION_ABSOLUTE='NO'
   local OUTPUT_MARKS='YES'
   local OUTPUT_DIRECTION='FORWARD'
   local OUTPUT_RAW_USERINFO='NO'
   local OPTION_OUTPUT_COLLECTION='NO'
   local OUTPUT_EVAL='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_craftorder_usage
         ;;

         --output-absolute)
            OPTION_ABSOLUTE='YES'
         ;;

         --output-relative)
            OPTION_ABSOLUTE='NO'
         ;;

         --backwards)
            OPTION_DIRECTION="BACKWARDS"
         ;;

         --callback)
            [ $# -eq 1 ] && sourcetree_craftorder_usage "Missing argument to \"$1\""
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

         --no-output-marks|--output-no-marks)
            OUTPUT_MARKS='NO'
         ;;

         --output-raw-userinfo)
            OUTPUT_RAW_USERINFO='YES'
         ;;

         --output-eval)
            OUTPUT_EVAL='YES'
         ;;

         --print-qualifier)
            echo "${SOURCETREE_CRAFTORDER_QUALIFIER}"
            exit 0
         ;;

         -*)
            sourcetree_craftorder_usage "Unknown craftorder option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_craftorder_usage "Superflous arguments \"$*\""

   #
   # First we walk post-order to get the filenames in the proper order
   # of compilation.
   #
   # Then we need to run it in breadth-first again to collect the proper
   # marks, since marks on the top should override those on the bottom.
   #
   # Finally we need to output again in the first order
   #
   local mode

   mode="${SOURCETREE_MODE},no-trace"
   if [ "${OPTION_DIRECTION}" = 'BACKWARD' ]
   then
      r_comma_concat "${mode}" "backwards"
      mode="${RVAL}"
   fi


   local _craftorder_collection

   _craftorder_collection="`sourcetree_walk "" \
                                            "" \
                                            "${SOURCETREE_CRAFTORDER_QUALIFIER}" \
                                            "${SOURCETREE_CRAFTORDER_QUALIFIER}" \
                                            "${mode},in-order" \
                                            "collect_craftorder_line"`"

   if [ -z "${_craftorder_collection}" ]
   then
      log_info "Craftorder is empty"
      return 0
   fi

   log_info "Craftorder"

   if [ "${OUTPUT_MARKS}" = 'NO' ]
   then
      output_craftorder "${_craftorder_collection}"
      return 0
   fi

   log_fluff "Collected \"${_craftorder_collection}\""

   local _remainder_collection
   local _augmented_collection

   _remainder_collection="${_craftorder_collection}"
   _augmented_collection="`sourcetree_walk "" \
                                           "" \
                                           "${SOURCETREE_CRAFTORDER_QUALIFIER}" \
                                           "${SOURCETREE_CRAFTORDER_QUALIFIER}" \
                                           "${mode},breadth-order" \
                                           "augment_craftorder_line"`"

   local pattern
   local collection
   local lines

   set -o noglob ; IFS=$'\n'
   for filename in ${_craftorder_collection}
   do
      r_escaped_sed_pattern "${filename}"
      line="`egrep -e "^${RVAL};" <<< "${_augmented_collection}"`"
      r_add_line "${lines}" "${line}"
      lines="${RVAL}"
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   output_craftorder "${lines}"
}


r_make_craftorder_qualifier()
{
   log_entry "r_make_craftorder_qualifier"

   local qualifier="$1"

   if [ ! -z "${qualifier}" ]
   then
      qualifier="${qualifier} AND "
   fi

   if [ -z "${MULLE_OS_VERSION}" ]
   then
      case "${MULLE_UNAME}" in
         darwin)
            MULLE_OS_VERSION="`sw_vers -productVersion`" || exit 1
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


sourcetree_craftorder_initialize()
{
   log_entry "sourcetree_craftorder_initialize"

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

   r_make_craftorder_qualifier "MATCHES build"
   SOURCETREE_CRAFTORDER_QUALIFIER="${RVAL}"
}


sourcetree_craftorder_initialize

:

