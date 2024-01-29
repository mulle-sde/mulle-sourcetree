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
MULLE_SOURCETREE_CRAFTORDER_SH='included'


sourcetree::craftorder::usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} craftorder [options]

   Print all sourcetree addresses that are marked as "build" (i.e. don't
   have the mark "no-build")

   In a make based project, this can be used to build everything like this:

      ${MULLE_EXECUTABLE_NAME} craftorder | while read address
      do
         ( cd "\${address}" ; make ) || break
      done

Options:
   --callback <f>         : a callback function to modify the output
   --output-eval          : resolve variables in the output
   --output-no-marks      : don't output marks of sourcetree node
   --print-qualifier      : prints qualifier for sourcetree marks, then exits

Environment:
   MULLE_PLATFORM_VERSION  : the OS version used for the build
   MULLE_PLATFORM          : the platform used for the build
EOF
  exit 1
}


sourcetree::craftorder::r_create_filename()
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
      filename="${filename#"${MULLE_VIRTUAL_ROOT}/"}"
   fi

   RVAL="${filename%#*}"
}


#
# _filename
# _datasource
# _marks
# _remainder_collection
# _address
# _nodetype
# _raw_userinfo
#
sourcetree::craftorder::__augment_line()
{
   log_entry "sourcetree::craftorder::__augment_line" "$@"

   local filename

   sourcetree::craftorder::r_create_filename "${_filename}"
   filename="${RVAL}"

   if ! find_line "${_remainder_collection}" "${filename}"
   then
      return 0
   fi

   # remove file from remainders
   # we only remove the first file in the hope we can collect augmentations
   # for duplicates as well

   r_remove_line_once "${_remainder_collection}" "${filename}"
   _remainder_collection="${RVAL}"

   local marks

   marks="${_marks}"
   if [ ! -z "${OPTION_CALLBACK}" ]
   then
      if "${OPTION_CALLBACK}" "${_datasource}" "${_address}" "${_nodetype}" "${marks}" "${filename}"
      then
         marks="${RVAL}"
      fi
   fi

   log_debug "Augmented ${filename} with marks \"${marks}\" from ${_datasource#"${MULLE_USER_PWD}/"}${_address}"

   if [ "${OUTPUT_RAW_USERINFO}" = 'YES' ]
   then
      printf "%s\n" "${filename};${marks};${_raw_userinfo}"
   else
      printf "%s\n" "${filename};${marks}"
   fi

   if [ -z "${_remainder_collection}" ]
   then
      log_debug "Done with collection"
      return 2   # signal done but no error
   fi

   return 0
}

#
# _filename
#
sourcetree::craftorder::__collect_line()
{
   log_entry "sourcetree::craftorder::__collect_line" "$@"

   local filename

   sourcetree::craftorder::r_create_filename "${_filename}"
   filename="${RVAL}"

   printf "%s\n" "${filename}"

   return 0
}


sourcetree::craftorder::r_augment_marks()
{
   log_entry "sourcetree::craftorder::r_augment_marks" "$@"

   local craftorder_collection="$1"
   local augmented_collection="$2"

   local filename
   local lines
   local duplicates
   local line

   .foreachline filename in ${craftorder_collection}
   .do
      if find_line "${duplicates}" "${filename}"
      then
         .continue
      fi
      r_add_line "${duplicates}" "${filename}"
      duplicates="${RVAL}"

      r_escaped_grep_pattern "${filename}"
      line="`grep -E -e "^${RVAL};" <<< "${augmented_collection}"`"

      r_add_line "${lines}" "${line}"
      lines="${RVAL}"
   .done

   RVAL="${lines}"
}


sourcetree::craftorder::r_remove_amalgamated()
{
   log_entry "sourcetree::craftorder::r_remove_amalgamated" "$@"

   local lines="$1"

   local line
   local filename
   local marks
   local result
   local shadows

   .foreachline line in ${lines}
   .do
      filename="${line%;*}"
      marks="${line##*;}"

      log_debug "filename : ${filename}"
      log_debug "marks    : ${marks}"
      log_debug "name     : ${name}"

      r_basename "${filename##*\}}"  # remove ${MULLE_SOURCETREE_STASH_DIR} prefix, get name
      name="${RVAL}"

      # is its an augmented line
      if sourcetree::marks::disable "${marks}" "share-shirk"
      then
         # don't add it to results, also make sure that "proper" repo which
         # would exist in ${MULLE_SOURCETREE_STASH_DIR}, if it wasn't shadowed
         # by the amalgamation, isn't returned
         log_debug "${filename} is an amalgamation"

         r_add_line "${shadows}" "${name}"
         shadows="${RVAL}"
         .continue
      fi

      if find_line "${shadows}" "${name}"
      then
         log_fluff "${filename} was shadowed by an amalgamation"
         .continue
      fi

      r_add_line "${result}" "${line}"
      result="${RVAL}"
   .done

   RVAL="${result}"
}


sourcetree::craftorder::output()
{
   log_entry "sourcetree::craftorder::output" "$@"

   local collection="$1"

   if [ "${OUTPUT_EVAL}" = 'YES' ]
   then
      local line

      .foreachline line in ${collection}
      .do
         eval "echo \"${line}\""
      .done
   else
      printf "%s\n" "${collection}"
   fi
}


sourcetree::craftorder::main()
{
   log_entry "sourcetree::craftorder::main" "$@"

   local OPTION_CALLBACK
   local OPTION_ABSOLUTE='NO'
   local OUTPUT_BEQUEATH='YES'   # default for craftorder
   local OUTPUT_MARKS='YES'
   local OUTPUT_DIRECTION='FORWARD'
   local OUTPUT_RAW_USERINFO='NO'
   local OPTION_OUTPUT_COLLECTION='NO'
   local OUTPUT_EVAL='NO'
   local OPTION_PRINT_ENV='YES'
   local OPTION_PLATFORM
   local OPTION_CONFIGURATION
   local OPTION_SDK
   local OPTION_VERSION

   local input
   local callbackscript
   local randomstring


   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::craftorder::usage
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
            [ $# -eq 1 ] && sourcetree::craftorder::usage "Missing argument to \"$1\""
            shift

            #
            # remove possible cruft before function name
            #
            input="`grep -E -v '^#' <<< "$1" | sed -e '/^ *$/d' `"
            r_uuidgen
            randomstring="${RVAL:0:6}"
            callbackscript="_cb_${randomstring}_${input#function}"
            OPTION_CALLBACK="`echo ${callbackscript%%\(*}`"
            eval "function ${callbackscript}" || fail "Callback \"${input}\" could not be parsed"
         ;;

         --bequeath)
            OPTION_BEQUEATH='YES'
         ;;

         --no-bequeath)
            OPTION_BEQUEATH='NO'
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

         -*)
            sourcetree::craftorder::usage "Unknown craftorder option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree::craftorder::usage "Superflous arguments \"$*\""

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
   if [ "${OPTION_BEQUEATH}" = 'NO' ]
   then
      r_comma_concat "${mode}" "no-bequeath"
      mode="${RVAL}"
   fi

   local qualifier

   qualifier="MATCHES build OR MATCHES no-share-shirk"
   if [ "${OUTPUT_MARKS}" = 'NO' ]
   then
      qualifier="MATCHES build"
   fi

   local _craftorder_collection
   local rval

   _craftorder_collection="`sourcetree::walk::do "" \
                                                 "" \
                                                 "${qualifier}" \
                                                 "${qualifier}" \
                                                 "${mode},in-order" \
                                                 "sourcetree::craftorder::__collect_line"`"
   rval=$?
   case "${rval}" in
      1)
         exit 1
      ;;
   esac

   if [ -z "${_craftorder_collection}" ]
   then
      log_info "Craftorder is empty"
      return 0
   fi

   log_info "Craftorder"

   if [ "${OUTPUT_MARKS}" = 'NO' ]
   then
      sourcetree::craftorder::output "${_craftorder_collection}"
      return 0
   fi

   log_fluff "Collected \"${_craftorder_collection}\""

   # remainder is used by sourcetree::walk::do, it should ge inherited into
   # the subshell
   local _remainder_collection
   local _augmented_collection

   _remainder_collection="${_craftorder_collection}"
   _augmented_collection="`sourcetree::walk::do "" \
                                                "" \
                                                "${qualifier}" \
                                                "${qualifier}" \
                                                "${mode},breadth-order" \
                                                "sourcetree::craftorder::__augment_line"`"
   rval=$?

   case "${rval}" in
      1)
         exit 1
      ;;
   esac


   local lines

   sourcetree::craftorder::r_augment_marks "${_craftorder_collection}" \
                                           "${_augmented_collection}"
   lines="${RVAL}"
   log_fluff "After augmenting lines with marks: ${C_RESET}\"${lines}\""

   sourcetree::craftorder::r_remove_amalgamated "${lines}"
   lines="${RVAL}"

   log_fluff "After removing amalgamations: ${C_RESET}\"${lines}\""

   sourcetree::craftorder::output "${lines}"
}


sourcetree::craftorder::initialize()
{
   log_entry "sourcetree::craftorder::initialize"

   include "sourcetree::walk"
   include "version"
}


sourcetree::craftorder::initialize

:
