# shellcheck shell=bash
#
#   Copyright (c) 2021 Nat! - Mulle kybernetiK
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
MULLE_SOURCETREE_DIFF_SH='included'


sourcetree::diff::usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} diff [options] <config> [other]

   Compares two sourcetree configurations and diffs them. This can be used
   figure out if a sourcetree needs a complete sync.

   Returns if <config> as INSERT, DELETE or UPDATEd lines compare to other.

Options:

EOF
  exit 1
}


sourcetree::diff::r_commalist_add()
{
   log_entry "sourcetree::diff::r_commalist_add" "$@"

   local list="$1"
   local value="$2"

   case ",${list}," in
      *,${value},*)
         RVAL="${list}"
         return 0
      ;;
   esac
   r_comma_concat "${list}" "${value}"
}


sourcetree::diff::r_commalist_remove()
{
   log_entry "sourcetree::diff::r_commalist_remove" "$@"

   local list="$1"
   local value="$2"

   RVAL=",${list},"
   RVAL="${RVAL/,${value},/,}"
   RVAL="${RVAL%,}"
   RVAL="${RVAL#,}"
}


sourcetree::diff::r_diff_configs()
{
   log_entry "sourcetree::diff::r_diff_configs" "$@"

   local config_a="$1"
   local config_b="$2"
   local mode="$3"

   local result

   local a_nodelines
   local b_nodelines
   local matched


   r_absolutepath "${config_a}"
   config_a="${RVAL}"

   if [ -d "${config_a}" ]
   then
      a_nodelines="`sourcetree::cfg::read "#${config_a}" `" || fail "Can't read config of \"$1\""
   else
      a_nodelines="`grep -E -v '^#' "${config_a}" `" || fail "Can't read config file \"$1\""
   fi
   if [ -z "${a_nodelines}" ]
   then
      log_warning "${config_a#"${MULLE_USER_PWD}/"} is empty"
   fi

   r_absolutepath "${config_b}"
   config_b="${RVAL}"
   if [ -d "${config_b}" ]
   then
      b_nodelines="`sourcetree::cfg::read "#${config_b}" `" || fail "Can't read config of \"$2\""
   else
      b_nodelines="`grep -E -v '^#' "${config_b}" `" || fail "Can't read config file \"$2\""
   fi
   if [ -z "${b_nodelines}" ]
   then
      log_warning "${config_b#"${MULLE_USER_PWD}/"} is empty"
   fi

   local _branch
   local _address
   local _fetchoptions
   local _nodetype
   local _marks
   local _raw_userinfo
   local _tag
   local _url
   local _uuid
   local _userinfo

   local a_nodeline
   local b_nodeline
   local changedfields

   shell_disable_glob; IFS=$'\n'
   for a_nodeline in ${a_nodelines}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      # exact match is hopefully often and fast
      if find_line "${b_nodelines}" "${a_nodeline}"
      then
         r_add_line "${matched}" "${a_nodeline}"
         matched="${RVAL}"
         continue
      fi

      sourcetree::nodeline::parse "${a_nodeline}"  # memo: :_marks used raw

      b_nodeline=
      # now that we have a line, try to match uuid first, address second
      if sourcetree::nodeline::r_find_by_uuid "${b_nodelines}" "${_uuid}"
      then
         b_nodeline="${RVAL}"
      else
         if sourcetree::nodeline::r_find "${b_nodelines}" "${_address}"
         then
            b_nodeline="${RVAL}"
         else
            # this line is new in 'a'
            case "${mode}" in
               'summary')
                  sourcetree::diff::r_commalist_add "${list}" "INSERT"
               ;;

               'long-diff')
                  r_add_line "${list}" "+ ${a_nodeline}"
               ;;

               'diff')
                  r_add_line "${list}" "+ ${_address}"
               ;;
            esac
            list="${RVAL}"
            continue
         fi
      fi

      # wr matched it
      r_add_line "${matched}" "${b_nodeline}"
      matched="${RVAL}"

      sourcetree::nodeline::r_diff "${a_nodeline}" "${b_nodeline}" "field"
      changedfields="${RVAL}"
      # can happen if only UUID differ
      if [ -z "${changedfields}" ]
      then
         continue
      fi

      # is modifed. now there are two fields, that do not necessarily
      # require a refetch that is marks, userinfo. Everything else does
      # mark "bad" as UPDATE and "harmless" as MODIFY
      #

      case "${mode}" in
         'summary')
            sourcetree::diff::r_commalist_remove "${changedfields}" "marks"
            sourcetree::diff::r_commalist_remove "${RVAL}" "userinfo"
            changedfields="${RVAL}"
            if [ -z "${changedfields}" ]
            then
               sourcetree::diff::r_commalist_add "${list}" "MODIFY"
            else
               sourcetree::diff::r_commalist_add "${list}" "UPDATE"
            fi
         ;;

         'diff')
            sourcetree::nodeline::r_diff "${a_nodeline}" "${b_nodeline}" "diff"
            r_add_line "${list}" "<> ${_address} ${RVAL}"
         ;;

         'long-diff')
            sourcetree::nodeline::r_diff "${a_nodeline}" "${b_nodeline}" "diff"
            r_add_line "${list}" "<> ${RVAL}"
         ;;
      esac

      list="${RVAL}"
   done

   for b_nodeline in ${b_nodelines}
   do
      if ! find_line "${matched}" "${b_nodeline}"
      then
         case "${mode}" in
            'summary')
               sourcetree::diff::r_commalist_add "${list}" "DELETE"
            ;;

            'long-diff')
               r_add_line "${list}" "- ${b_nodeline}"
            ;;

            'diff')
               sourcetree::nodeline::r_get_address "${b_nodeline}"
               r_add_line "${list}" "- ${RVAL}"
            ;;
         esac
         list="${RVAL}"
         continue
      fi
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   RVAL="${list}"
}


sourcetree::diff::main()
{
   log_entry "sourcetree::diff::main" "$@"

   local OPTION_MODE=diff

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::diff::usage
         ;;

         --summary)
            OPTION_MODE="summary"
         ;;

         -*)
            sourcetree::diff::usage "Unknown clean option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sourcetree::diff::usage "Missing argument"

   local other="$1"
   shift

   [ $# -gt 1 ] && shift && sourcetree::diff::usage "Superflous arguments $*"


   local config

   config="${SOURCETREE_START}"
   if [ $# -ne 0 ]
   then
      config="${other}"
      other="$1"
   fi

   sourcetree::diff::r_diff_configs "${config}" "${other}" "${OPTION_MODE}"
   if ! [ -z "${RVAL}" ]
   then
      printf "%s\n" "${RVAL}"
      return 2
   fi

   log_info "No differences"
}

