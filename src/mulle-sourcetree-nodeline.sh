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
MULLE_SOURCETREE_NODELINE_SH="included"


# first field no -s

__nodeline_get_address()
{
   local nodeline="$1"

   _address="${nodeline%%;*}"
}


r_nodeline_get_address()
{
   RVAL="${*%%;*}"
}


nodeline_get_address()
{
   cut '-d;' -f 1 <<< "$*"
}


__nodeline_get_address_nodetype()
{
   local nodeline="$1"

   _nodetype="${nodeline#*;}"

   _address="${nodeline%%;*}"
   _nodetype="${_nodetype%%;*}"
}


__nodeline_get_address_nodetype_marks()
{
   local nodeline="$1"

   _nodetype="${nodeline#*;}"
   _marks="${_nodetype#*;}"

   _address="${nodeline%%;*}"
   _nodetype="${_nodetype%%;*}"
   _marks="${_marks%%;*}"
}


__nodeline_get_address_nodetype_marks_uuid()
{
   local nodeline="$1"

   _nodetype="${nodeline#*;}"
   _marks="${_nodetype#*;}"
   _uuid="${_marks#*;}"

   _address="${nodeline%%;*}"
   _nodetype="${_nodetype%%;*}"
   _marks="${_marks%%;*}"
   _uuid="${_uuid%%;*}"
}


nodeline_get_url()
{
   cut '-d;' -f 5 <<< "$*"
}

r_nodeline_get_url()
{
   RVAL="`nodeline_get_url "$@"`"
}


nodeline_get_evaled_url()
{
   eval echo "`cut '-d;' -f 5 <<< "$*"`"
}


r_nodeline_get_evaled_url()
{
   RVAL="`nodeline_get_evaled_url "$@"`"
}


#
# This function sets values of variables that should be declared
# in the caller! That's why they have a _ prefix
#
#   # nodeline_parse
#
#   local _branch
#   local _address
#   local _fetchoptions
#   local _nodetype
#   local _marks
#   local _raw_userinfo
#   local _userinfo
#   local _tag
#   local _url
#   local _uuid
#
# #   This is a bit faster but not by much
# #   _address="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _nodetype="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _marks="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _uuid="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _url="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _branch="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _tag="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _fetchoptions="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _raw_userinfo="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"

nodeline_parse()
{
   log_entry "nodeline_parse" "$@"

   local nodeline="$1"

   [ -z "${nodeline}" ] && internal_fail "nodeline_parse: nodeline is empty"

   IFS=";" \
      read -r _address _nodetype _marks _uuid \
              _url _branch _tag _fetchoptions \
              _raw_userinfo  <<< "${nodeline}"

   # set this to empty, so we know raw is not converted yet

   _userinfo=""
   [ -z "${_address}" ]   && internal_fail "_address is empty"
   [ -z "${_nodetype}" ]  && internal_fail "_nodetype is empty"
   [ -z "${_uuid}" ]      && internal_fail "_uuid is empty"

   if [ "$MULLE_FLAG_LOG_SETTINGS" = 'YES' ]
   then
      log_trace2 "ADDRESS:      \"${_address}\""
      log_trace2 "NODETYPE:     \"${_nodetype}\""
      log_trace2 "MARKS:        \"${_marks}\""
      log_trace2 "UUID:         \"${_uuid}\""
      log_trace2 "URL:          \"${_url}\""
      log_trace2 "BRANCH:       \"${_branch}\""
      log_trace2 "TAG:          \"${_tag}\""
      log_trace2 "FETCHOPTIONS: \"${_fetchoptions}\""
      log_trace2 "USERINFO:     \"${_raw_userinfo}\""
   fi

   :
}


#   local _raw_userinfo
#   local _userinfo
nodeline_raw_userinfo_parse()
{
   log_entry "nodeline_raw_userinfo_parse" "$@"

   _userinfo="$1"
   case "${_userinfo}" in
      base64:*)
         _userinfo="`base64 --decode <<< "${_raw_userinfo:7}"`"
         if [ "$?" -ne 0 ]
         then
            internal_fail "userinfo could not be base64 decoded."
         fi
      ;;
   esac
}


#
#
#
nodeline_remove()
{
   log_entry "nodeline_remove" "$@"

   local nodelines="$1"
   local addresstoremove="$2"

   local nodeline

   set -o noglob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob
      case "${nodeline}" in
         ^#*)
            printf "%s\n" "${nodeline}"
            continue
         ;;
      esac

      local _address

      __nodeline_get_address "${nodeline}"

      if [ "${_address}" != "${addresstoremove}" ]
      then
         printf "%s\n" "${nodeline}"
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


_r_nodeline_find()
{
   log_entry "_r_nodeline_find" "$@"

   local nodelines="$1"
   local value="$2"
   local lookup="$3"
   local fuzzy="$4"

   [ $# -ne 4 ] && internal_fail "API error"

   local nodeline
   local other

   if [ "${fuzzy}" = 'YES' ]
   then
      case "${value}" in
         *[\$\|\<\>]*)
            fail "Suspicious value \"${value}\" can't be matched"
         ;;
      esac
   fi

   set -o noglob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      "${lookup}" "${nodeline}"
      other="${RVAL}"

      if [ "${other}" = "${value}" ]
      then
         log_debug "Found \"${nodeline}\""
         RVAL="${nodeline}"
         return 0
      fi

      if [ "${fuzzy}" = 'YES' ]
      then
         case "${other}" in
            ${value})
               log_debug "Found \"${nodeline}\""
               RVAL="${nodeline}"
               return 0
            ;;
         esac
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   RVAL=
   return 1
}


nodeline_find()
{
   log_entry "nodeline_find" "$@"

   local nodelines="$1"
   local address="$2"
   local fuzzy="${3:-NO}"

   [ -z "${address}" ] && internal_fail "address is empty"

   if ! _r_nodeline_find "${nodelines}" "${address}" r_nodeline_get_address "${fuzzy}"
   then
      return 1
   fi
   printf "%s\n" "${RVAL}"
}


nodeline_find_by_url()
{
   log_entry "nodeline_find_by_url" "$@"

   local nodelines="$1"
   local url="$2"

   [ -z "${url}" ] && internal_fail "url is empty"

   if ! _r_nodeline_find "${nodelines}" "${url}" r_nodeline_get_url NO
   then
      return 1
   fi
   printf "%s\n" "${RVAL}"
}


nodeline_find_by_evaled_url()
{
   log_entry "nodeline_find_by_evaled_url" "$@"

   local nodelines="$1"
   local url="$2"

   [ -z "${url}" ] && internal_fail "url is empty"

   if ! _r_nodeline_find "${nodelines}" "${url}" r_nodeline_get_evaled_url NO
   then
      return 1
   fi
   printf "%s\n" "${RVAL}"
}


nodeline_has_duplicate()
{
   log_entry "nodeline_has_duplicate" "$@"

   local nodelines="$1"
   local address="$2"
   local uuid="$3"

   set -o noglob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      local _address
      local _nodetype
      local _marks
      local _uuid

      __nodeline_get_address_nodetype_marks_uuid "${nodeline}"

      if [ "${address}" = "${_address}" ]
      then
         if [ -z "${uuid}" ] || [ "${uuid}" = "${_uuid}" ]
         then
            return 0
         fi
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   return 1
}


nodeline_read_file()
{
   log_entry "nodeline_read_file" "$@"

   local filename="$1"

   [ -z "${filename}" ] && internal_fail "file is empty"

   egrep -s -v '^#' "${filename}"
}


r_get_sep()
{
   log_entry "r_get_sep" "$@"

   local mode="$1"

   case ",${mode}," in
      *,output_column,*)
         RVAL="; "
      ;;

      *)
         RVAL=";"
      ;;
   esac
}


r_get_formatstring()
{
   log_entry "r_get_formatstring" "$@"

   local mode="$1"
   local formatstring="$2"
   local sep="$3"

   # this could be much better

   RVAL="${formatstring}"

   if [ -z "${RVAL}" ]
   then
      RVAL="%a${sep}%n${sep}%m${sep}%i"
      case ",${mode}," in
         *,output_url,*)
            RVAL="${RVAL}${sep}%u"
         ;;
      esac

      case ",${mode}," in
         *,output_full,*)
            RVAL="${RVAL}${sep}%b${sep}%t${sep}%f"
         ;;
      esac

      case ",${mode}," in
         *,output_uuid,*)
            RVAL="${RVAL}${sep}%_"
         ;;
      esac
      RVAL="${RVAL}\\n"
   fi

   log_debug "Format: ${RVAL}"
}


nodeline_printf_header()
{
   log_entry "nodeline_printf_header" "$@"

   local mode="$1"
   local formatstring="$2"

   case ",${mode}," in
      *,output_header,*)
      ;;

      *)
         return
      ;;
   esac

   local sep

   r_get_sep "${mode}"
   sep="${RVAL}"

   r_get_formatstring "${mode}" "${formatstring}" "${sep}"
   formatstring="${RVAL}"

   local h_line
   local s_line

   local name
   local dash

   while [ ! -z "${formatstring}" ]
   do
      case "${formatstring}" in
         %a*)
            name="address"
            dash="-------"
         ;;

         %b!*)
            name="branch"
            dash="------"
            formatstring="${formatstring:1}"
         ;;

         %b*)
            name="branch"
            dash="------"
         ;;

         %f!*)
            name="fetchoptions"
            dash="------------"
            formatstring="${formatstring:1}"
         ;;

         %f*)
            name="fetchoptions"
            dash="------------"
         ;;

         %i*|%v*)
            if [ "${formatstring:2:2}" = "={" ]
            then
               name="`sed -n 's/%.={[^,]*,\([^,]*\)[,]*[^}]*}.*/\1/p' <<< "${formatstring}" `"
               if [ -z "${name}" ]
               then
                  name="`sed -n 's/%.={\([^,]*\)[,]*[^,]*[,]*[^}]*}.*/\1/p' <<< "${formatstring}" `"
               fi
               dash="`sed -n 's/%.={[^,]*,[^,]*,\([^}]*\)}.*/\1/p' <<< "${formatstring}" `"
               if [ -z "${dash}" ]
               then
                  dash="------"
               fi
               # skip over format string
               local tmp

               tmp="`sed 's/%.={[^}]*}//' <<< "${formatstring}" `"
               if [ "${tmp}" != "${formatstring}" ]
               then
                  formatstring="XX${tmp}"
               fi
            else
               name="userinfo"
               dash="--------"
            fi
         ;;

         %m*)
            name="marks"
            dash="-----"
         ;;

         %n*)
            name="nodetype"
            dash="--------"
         ;;

         %t!*)
            name="tag"
            dash="---"
            formatstring="${formatstring:1}"
         ;;

         %t*)
            name="tag"
            dash="---"
         ;;

         %[uU]!*)
            name="url"
            dash="---"
            formatstring="${formatstring:1}"
         ;;

         %[uU]*)
            name="url"
            dash="---"
         ;;

         %_*)
            name="uuid"
            dash="----"
         ;;

         %*)
            fail "unknown format character \"${formatstring:1:1}\""
         ;;

         \\n)
            case ",${mode}," in
               *,output_cmd,*|*,output_cmd2,*)
                  name=""
                  dash=""
               ;;

               *)
                  name="
"
                  dash="
"
               ;;
            esac
         ;;

         *)
            h_line="${h_line}${formatstring:0:1}"
            s_line="${s_line}${formatstring:0:1}"
            formatstring="${formatstring:1}"
            continue
         ;;
      esac

      h_line="${h_line}${name}"
      s_line="${s_line}${dash}"

      formatstring="${formatstring:2}"
   done

   rexekutor printf "%s" "${h_line}"
   case ",${mode}," in
      *,output_separator,*)
         rexekutor printf "%s" "${s_line}"
      ;;
   esac
}


nodeline_printf()
{
   local nodeline=$1; shift

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _uuid
   local _raw_userinfo
   local _userinfo

   nodeline_parse "${nodeline}"

   node_printf "$@"
}


sourcetree_nodeline_initialize()
{
   log_entry "sourcetree_nodeline_initialize"

   if [ -z "${MULLE_SOURCETREE_NODE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodemarks.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-node.sh"|| exit 1
   fi
   if [ -z "${MULLE_SOURCETREE_NODEMARKS_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodemarks.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodemarks.sh"|| exit 1
   fi
}

sourcetree_nodeline_initialize

:
