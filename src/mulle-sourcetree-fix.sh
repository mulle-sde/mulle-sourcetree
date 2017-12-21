   local fixdir
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
MULLE_SOURCETREE_FIX_SH="included"

sourcetree_fix_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} fix

   Emit commands that would fix the sourcetree node, when nodes have been
   moved by the user.
   This will only have a chance of success, if the sourcetree was updated
   initially with the --fix option (which is the default).
EOF
  exit 1
}


locate_sourcetree()
{
   log_entry "locate_sourcetree" "$@"

   local start="$1"

   start="`absolutepath "${start}" `"
   start="`physicalpath "${start}" `"

   local directory

   directory="${start}"

   while :
   do
      if [ -d "${directory}/${SOURCETREE_DIR}" ]
      then
         echo "${directory}"
         return 0
      fi
      if [ "${directory}" = "${MULLE_VIRTUAL_ROOT}" ]
      then
         return 1
      fi
      directory="`dirname -- "${directory}"`"
   done
}


locate_fix_file()
{
   log_entry "locate_fix_file" "$@"

   local start="$1"
   local address="$2"

   start="`absolutepath "${start}" `"
   start="`physicalpath "${start}" `"

   local found
   local match
   local name

   name="`basename -- "${address}" `"

   local fix
   local fixname

   IFS="
"
   for found in `find "${start}" -name "${SOURCETREE_FIX_FILE}" -type f -print`
   do
      IFS="${DEFAULT_IFS}"

      #
      # fix file contains the basename of the old directory
      #
      fix="`egrep -s -v '^#' "${found}"`"

      if [ "${fix}" = "${address}" ]
      then
         log_debug "Found a perfect matching fix file \"${found}\""
         echo "${found}"
         return 0
      fi

      fixname="`basename -- "${fix}"`"
      if [ -z "${match}" ] && [ "${fixname}" = "${name}" ]
      then
         match="${found}"
      fi
   done

   IFS="${DEFAULT_IFS}"

   if [ -z "${match}" ]
   then
      return 1
   fi

   log_debug "Found a matching fix file \"${match}\""
   echo "${match}"
}


_fixup_address_change()
{
   log_entry "_fixup_address_change" "$@"

   local datasource="$1"
   local address="$2"
   local fixfile="$3"

   local fixdir

   fixdir="`dirname -- "${fixfile}"`"

   local fixaddress

   fixaddress="`string_remove_prefix "${fixdir}" "${MULLE_VIRTUAL_ADRESSS}" `"
   fixaddress="`string_remove_prefix "${fixaddress}" "${datasource}" `"

   exekutor echo "cd \"\${MULLE_VIRTUAL_ROOT}${datasource}\""
   exekutor echo "mulle-sourcetree set --address '${fixaddress}' '${address}'"
}


_fixup_manual_removal()
{
   log_entry "_fixup_manual_removal" "$@"

   local datasource="$1"
   local address="$2"

   exekutor echo "cd \"\${MULLE_VIRTUAL_ROOT}${datasource}\""
   exekutor echo "mulle-sourcetree remove '${address}'"
}


_fixup_dir_exists()
{
   log_entry "_fixup_dir_exists" "$@"

   local datasource="$1"
   local filename="$2"
   local address="$3"

   local fix
   local fixname

   fix="`egrep -s -v '^#' "${filename}/${SOURCETREE_FIX_FILE}"`"
   if [ -z "${fix}" ] # can't determine looks ok
   then
      return
   fi

   if [ "${address}" = "${fix}" ]  # looks good
   then
      return
   fi

   # deal with
   # mv b tmp; mv a b; mv tmp a

   local fixfile

   fixfile="`locate_fix_file "${PWD}" "${address}"`"
   if [ -z "${fixfile}" ]
   then
      fixfile="`locate_fix_file "${MULLE_VIRTUAL_ADRESSS}" "${address}"`"
   fi

   if [ -z "${fixfile}" ]
   then
      log_warning "\"${address}\" looks like it needs an update"
      return 1
   fi

   _fixup_address_change "${datasource}" "${address}" "${fixfile}"
}


_fixup_dir_not_found()
{
   log_entry "_fixup_dir_not_found" "$@"

   local datasource="$1"
   local filename="$2"
   local address="$3"

   local fixfile

   fixfile="`locate_fix_file "${MULLE_VIRTUAL_ADRESSS}" "${address}"`"
   if [ -z "${fixfile}" ]
   then
      _fixup_manual_removal "${datasource}" "${address}"
      return 0
   fi

   _fixup_address_change "${datasource}" "${address}" "${fixfile}"
}


walk_fix()
{
   log_entry "walk_fix" "$@"

   local datasource
   local filename
   local address

   datasource="${MULLE_DATASOURCE}"
   address="${MULLE_ADDRESS}"
   filename="${MULLE_FILENAME}"

   if [ -e "${filename}" ]
   then
      if [ -d "${filename}" ]
      then
         log_fluff "Dictionary \"${filename}\" exists."
         _fixup_dir_exists "${datasource}" "${filename}" "${address}"
      else
         log_warning "${filename} is a file, not sure what to do"
      fi
   else
      log_verbose "Destination \"${filename}\" doesn't exist."

      _fixup_dir_not_found "${datasource}" "${filename}" "${address}"
   fi
}


sourcetree_fix()
{
   log_entry "sourcetree_fix" "$@"

   local filternodetypes="$1"
   local filterpermissions="$2"
   local filtermarks="$3"
   local mode="$4"

   walk_config_uuids "${filternodetypes}" \
                     "${filterpermissions}" \
                     "${filtermarks}" \
                     "${mode}" \
                     "walk_fix"
}


sourcetree_fix_main()
{
   log_entry "sourcetree_fix_main" "$@"

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
            sourcetree_fix_usage
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
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown fix option $1"
            sourcetree_fix_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_fix_usage

   if ! cfg_exists "${SOURCETREE_START}"
   then
      log_info "There is no ${SOURCETREE_CONFIG_FILE} here"
   fi

   if ! db_is_ready "${SOURCETREE_START}"
   then
      fail "The sourcetree isn't updated. Can't fix config entries"
   fi

   sourcetree_fix "${OPTION_NODETYPES}" \
                  "${OPTION_PERMISSIONS}" \
                  "${OPTION_MARKS}" \
                  "${SOURCETREE_MODE}"
}


sourcetree_fix_initialize()
{
   log_entry "sourcetree_fix_initialize"

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


sourcetree_fix_initialize

:
