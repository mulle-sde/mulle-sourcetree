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
   ${MULLE_USAGE_NAME} fix

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
      if [ -d "${directory}/.mulle/etc/sourcetree" ] # has no share!
      then
         printf "%s\n" "${directory}"
         return 0
      fi
      if [ "${directory}" = "${MULLE_VIRTUAL_ROOT}" ]
      then
         return 1
      fi
      r_dirname "${directory}"
      directory="${RVAL}"
   done
}


r_locate_fix_file()
{
   log_entry "r_locate_fix_file" "$@"

   local start="$1"
   local address="$2"

   r_absolutepath "${start}"
   start="`physicalpath "${RVAL}"`"

   local found
   local match
   local name

   r_basename "${address}"
   name="${RVAL}"

   local fixname

   r_basename "${SOURCETREE_FIX_FILENAME}"
   fixname=${RVAL}

   IFS=$'\n'
   for found in `rexekutor find "${start}" -name "${fixname}" -type f -print`
   do
      IFS="${DEFAULT_IFS}"

      if [ "${found}%${SOURCETREE_FIX_FILENAME}" = "${found}" ]
      then
         continue
      fi

      #
      # fix file contains the basename of the old directory
      #

      local nodeline
      local fix

      nodeline="`rexekutor egrep -s -v '^#' "${found}"`"
      fix="`nodeline_get_address "${nodeline}"`"

      if [ "${fix}" = "${address}" ]
      then
         log_debug "Found a perfect matching fix file \"${found}\""
         RVAL="${found}"
         return 0
      fi

      local fixname

      r_basename "${fix}"
      fixname="${RVAL}"
      if [ -z "${match}" ] && [ "${fixname}" = "${name}" ]
      then
         match="${found}"
      fi
   done

   IFS="${DEFAULT_IFS}"

   if [ -z "${match}" ]
   then
      log_debug "No matching fix file found"
      RVAL=
      return 1
   fi

   log_debug "Found a matching fix file \"${match}\""
   RVAL="${match}"
   return 0
}


_fixup_address_change()
{
   log_entry "_fixup_address_change" "$@"

   local datasource="$1"
   local address="$2"
   local fixfile="$3"

   local fixaddress

   r_dirname "${fixfile}"
   fixaddress="${RVAL#${MULLE_VIRTUAL_ROOT}}"
   fixaddress="${fixaddress#${datasource}}"

   r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${datasource}"

   exekutor echo "cd \"${RVAL#${MULLE_USER_PWD}/}\""
   exekutor echo "mulle-sourcetree set --address '${fixaddress}' '${address}'"
}


_fixup_manual_removal()
{
   log_entry "_fixup_manual_removal" "$@"

   local datasource="$1"
   local address="$2"

   r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${datasource}"

   exekutor echo "cd \"${RVAL#${MULLE_USER_PWD}/}\""
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

   local nodeline
   local fix

   nodeline="`rexekutor egrep -s -v '^#' "${filename}/${SOURCETREE_FIX_FILENAME}"`"
   if [ -z "${nodeline}" ] # can't determine looks ok
   then
      log_debug "There is no \"${filename}/${SOURCETREE_FIX_FILENAME}\""
      return
   fi

   fix="`nodeline_get_address "${nodeline}"`"
   if [ "${address}" = "${fix}" ]  # looks good
   then
      log_debug "Fix \"${fix}\" is in the right place"
      return
   fi

   # deal with
   # mv b tmp; mv a b; mv tmp a

   local fixfile

   r_locate_fix_file "${PWD}" "${address}"
   fixfile="${RVAL}"
   if [ -z "${fixfile}" ]
   then
      r_locate_fix_file "${MULLE_VIRTUAL_ROOT}" "${address}"
      fixfile="${RVAL}"
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

   r_locate_fix_file "${MULLE_VIRTUAL_ROOT}" "${address}"
   fixfile="${RVAL}"

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

   datasource="${WALK_DATASOURCE}"
   address="${NODE_ADDRESS}"
   filename="${NODE_FILENAME}"

   if [ -e "${filename}" ]
   then
      if [ -d "${filename}" ]
      then
         log_fluff "Destination \"${filename}\" exists."
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

   local mode="$1"

   walk_config_uuids "ALL" \
                     "" \
                     "" \
                     "" \
                     "${mode}" \
                     "walk_fix"
}


sourcetree_fix_main()
{
   log_entry "sourcetree_fix_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_fix_usage
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

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   fi

   if ! cfg_exists "${SOURCETREE_START}"
   then
      log_info "There is no \"${SOURCETREE_CONFIG_FILENAME}\" here"
   fi

   if ! db_is_ready "${SOURCETREE_START}"
   then
      fail "The sourcetree isn't updated. Can't fix config entries"
   fi

   local mode

   mode="${SOURCETREE_MODE}"
   if [ "${SOURCETREE_MODE}" != "flat" ]
   then
      mode="`comma_concat "${mode}" "pre-order"`"
   fi

   log_info "Run sourcetree fix"
   sourcetree_fix "${mode}"
}

