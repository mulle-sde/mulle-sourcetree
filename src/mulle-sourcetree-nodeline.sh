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
_nodeline_get_address()
{
   cut '-d;' -f 1
}


nodeline_get_address()
{
  cut '-d;' -f 1 <<< "$*"
}


nodeline_get_nodetype()
{
   cut -s '-d;' -f 2 <<< "$*"
}


nodeline_get_marks()
{
   cut '-d;' -f 3 <<< "$*"
}


_nodeline_get_uuid()
{
   cut -s '-d;' -f 4
}


nodeline_get_uuid()
{
   cut '-d;' -f 4 <<< "$*"
}


_nodeline_get_url()
{
   cut -s '-d;' -f 5
}

nodeline_get_url()
{
   cut '-d;' -f 5 <<< "$*"
}


nodeline_get_branch()
{
   cut -s '-d;' -f 6 <<< "$*"
}


nodeline_get_tag()
{
   cut -s '-d;' -f 7 <<< "$*"
}


nodeline_get_fetchoptions()
{
   cut '-d;' -f 8 <<< "$*"
}


# if _userinfo was last it could contain unquoted ;
# but who cares ?
nodeline_get_userinfo()
{
   cut '-d;' -f 9 <<< "$*"
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
#   local _tag
#   local _url
#   local _uuid
#   local _userinfo
#
nodeline_parse()
{
   log_entry "nodeline_parse" "$@"

   local nodeline="$1"

   [ -z "${nodeline}" ] && internal_fail "nodeline_parse: nodeline is empty"

   IFS=";" \
      read -r _address _nodetype _marks _uuid \
              _url _branch _tag _fetchoptions \
              _userinfo  <<< "${nodeline}"

   [ -z "${_address}" ]   && internal_fail "_address is empty"
   [ -z "${_nodetype}" ]  && internal_fail "_nodetype is empty"
   [ -z "${_uuid}" ]      && internal_fail "_uuid is empty"

   case "${_userinfo}" in
      base64:*)
         _userinfo="`base64 --decode <<< "${_userinfo:7}"`"
         if [ "$?" -ne 0 ]
         then
            internal_fail "userinfo could not be base64 decoded."
         fi
      ;;
   esac

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" ]
   then
      log_trace2 "ADDRESS:      \"${_address}\""
      log_trace2 "NODETYPE:     \"${_nodetype}\""
      log_trace2 "MARKS:        \"${_marks}\""
      log_trace2 "UUID:         \"${_uuid}\""
      log_trace2 "URL:          \"${_url}\""
      log_trace2 "BRANCH:       \"${_branch}\""
      log_trace2 "TAG:          \"${_tag}\""
      log_trace2 "FETCHOPTIONS: \"${_fetchoptions}\""
      log_trace2 "USERINFO:     \"${_userinfo}\""
   fi

   :
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
   local address

   set -o noglob ; IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob
      case "${nodeline}" in
         ^#*)
            echo "${nodeline}"
            continue
         ;;
      esac

      address="`nodeline_get_address "${nodeline}"`" || internal_fail "nodeline_get_address \"${nodeline}\""
      if [ "${address}" != "${addresstoremove}" ]
      then
         echo "${nodeline}"
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


_nodeline_find()
{
   log_entry "nodeline_find" "$@"

   local nodelines="$1"
   local value="$2"
   local lookup="$3"

   [ $# -ne 3 ] && internal_fail "API error"

   local nodeline
   local other

   set -o noglob ; IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      other="`"${lookup}" "${nodeline}"`"
      if [ "${value}" = "${other}" ]
      then
         log_debug "Found \"${nodeline}\""
         echo "${nodeline}"
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   return 1
}


nodeline_find()
{
   log_entry "nodeline_find" "$@"

   local nodelines="$1"
   local address="$2"

   [ -z "${address}" ] && internal_fail "address is empty"

   _nodeline_find "${nodelines}" "${address}" nodeline_get_address
}


nodeline_find_by_url()
{
   log_entry "nodeline_find_by_url" "$@"

   local nodelines="$1"
   local address="$2"

   [ -z "${address}" ] && internal_fail "address is empty"

   _nodeline_find_url "${nodelines}" "${address}" nodeline_get_url
}


nodeline_has_duplicate()
{
   log_entry "nodeline_has_duplicate" "$@"

   local nodelines="$1"
   local address="$2"
   local uuid="$3"

   set -o noglob ; IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob
      if [ "${address}" = "`nodeline_get_address "${nodeline}"`" ]
      then
         if [ -z "${uuid}" ] || [ "${uuid}" = "`nodeline_get_uuid "${nodeline}"`" ]
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


nodeline_printf_header()
{
   log_entry "nodeline_printf_header" "$@"

   local mode="$1"
   local formatstring="$2"

   case "${mode}" in
      *output_header*)
      ;;

      *)
         return
      ;;
   esac

   sep=";"
   case "${mode}" in
      *output_column*)
         sep="|"
      ;;
   esac

   if [ -z "${formatstring}" ]
   then
      formatstring="anmiu"
      case "${mode}" in
         *output_full*)
            formatstring="${formatstring}btf"
         ;;
      esac
      case "${mode}" in
         *output_uuid*)
            formatstring="${formatstring}_"
         ;;
      esac
   fi

   local h_line
   local s_line

   local name
   local dash

   while [ ! -z "${formatstring}" ]
   do
      case "${formatstring:0:1}" in
         a)
            name="address"
            dash="-------"
         ;;

         b)
            name="branch"
            dash="------"
         ;;

         f)
            name="fetchoptions"
            dash="------------"
         ;;

         i)
            if [ "${formatstring:1:1}" = "=" ]
            then
               name="`sed -n 's/i={[^,]*,\([^,]*\)[,]*[^}]*}.*/\1/p' <<< "${formatstring}" `"
               if [ -z "${name}" ]
               then
                  name="`sed -n 's/i={\([^,]*\)[,]*[^,]*[,]*[^}]*}.*/\1/p' <<< "${formatstring}" `"
               fi
               dash="`sed -n 's/i={[^,]*,[^,]*,\([^}]*\)}.*/\1/p' <<< "${formatstring}" `"
               if [ -z "${dash}" ]
               then
                  dash="------"
               fi
               # skip over format string
               formatstring="`sed 's/i={[^,]*,[^,]*[,]*[^}]*}\(.*\)/i\1/' <<< "${formatstring}" `"
            else
               name="userinfo"
               dash="--------"
            fi
         ;;

         m)
            name="marks"
            dash="-----"
         ;;

         n)
            name="nodetype"
            dash="--------"
         ;;

         t)
            name="tag"
            dash="---"
         ;;

         u)
            name="url"
            dash="---"
         ;;

         _)
            name="uuid"
            dash="----"
         ;;

         *)
            fail "unknown format character \"${formatstring:1:1}\""
         ;;
      esac

      h_line="`concat "${h_line}" "${name}" "${sep}" `"
      s_line="`concat "${s_line}" "${dash}" "${sep}" `"

      formatstring="${formatstring:1}"
   done

   echo "${h_line}"

   case "${mode}" in
      *output_separator*)
         echo "${s_line}"
      ;;
   esac
}


nodeline_printf()
{
   log_entry "nodeline_printf" "$@"

   local nodeline=$1
   local mode="$2"
   local formatstring="$3"

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _userinfo
   local _uuid

   nodeline_parse "${nodeline}"

   case "${mode}" in
      *output_eval*)
         _url="`eval echo "${_url}"`"
         _branch="`eval echo "${_branch}"`"
         _tag="`eval echo "${_tag}"`"
         _fetchoptions="`eval echo "${_fetchoptions}"`"
      ;;
   esac

   local sep

   sep=";"
   case "${mode}" in
      *output_column*)
         sep="|"
      ;;
   esac

   if [ -z "${formatstring}" ]
   then
      formatstring="anmiu"
      case "${mode}" in
         *output_full*)
            formatstring="${formatstring}btf"
         ;;
      esac
      case "${mode}" in
         *output_uuid*)
            formatstring="${formatstring}_"
         ;;
      esac
   fi

   local line
   local cmd_line

   cmd_line="${MULLE_EXECUTABLE_NAME} -N add"

   while [ ! -z "${formatstring}" ]
   do
      local guess
      local value
      local switch

      guess=
      case "${mode}" in
         *output_cmd*)
            if [ ! -z "${_url}" ]
            then
               guess="`node_guess_nodetype "${_url}"`"
            fi
         ;;
      esac

      case "${formatstring:0:1}" in
         a)
            switch=""
            value="${_address}"
         ;;

         b)
            switch="--branch"
            value="${_branch}"
         ;;

         f)
            switch="--fetchoptions"
            value="${_fetchoptions}"
         ;;

         i)
            if [ "${formatstring:1:1}" = "=" ]
            then
               if [ -z "${MULLE_ARRAY_SH}" ]
               then
                  . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" || \
                     internal_fail "Could not load mulle-array.sh via \"${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}\""
               fi
               switch=""
               key="`sed -n 's/i={\([^,]*\)[,]*[^,]*[,]*[^}]*}.*/\1/p' <<< "${formatstring}" `"
               if [ -z "${key}" ]
               then
                  fail "malformed formatstring \"${formatstring:1}\". Need ={<title>,<dashes>,<key>}"
               fi
               value="`assoc_array_get "${_userinfo}" "${key}" `"

               # skip over format string
               formatstring="`sed 's/i={[^,]*[,]*[^,]*[,]*[^}]*}\(.*\)/i\1/' <<< "${formatstring}" `"
            else
               switch="--userinfo"
               value="${_userinfo}"
            fi

         ;;

         m)
            switch="--marks"
            value="${_marks}"
         ;;

         n)
            switch="--nodetype"
            value="${_nodetype}"

            if [ "${_nodetype}" = "git" -o "${guess}" = "git" ]
            then
               switch=""
            fi
         ;;

         t)
            switch="--tag"
            value="${_tag}"
         ;;

         u)
            switch="--url"
            value="${_url}"
         ;;

         _)
            switch=""
            value="${_uuid}"
         ;;

         *)
            fail "unknown format character \"${formatstring:1:1}\""
         ;;
      esac

      case "${mode}" in
         *output_column*)
            if [ -z "${value}" ]
            then
               value=" "
            fi
            line="`concat "${line}" "${value}" "${sep}" `"
         ;;

         *output_raw*)
            if [ -z "${line}" ]
            then
               line="${value}"
            else
               line="${line}${sep}${value}"
            fi
         ;;

         *)
            line="`concat "${line}" "${value}" "${sep}" `"
         ;;
      esac

      if [ ! -z "${switch}" -a ! -z "${value}" ]
      then
         cmd_line="`concat "${cmd_line}" "${switch} '${value}'"`"
      fi

      formatstring="${formatstring:1}"
   done

   case "${mode}" in
      *output_cmd*)
         echo "${cmd_line}" "'${_address}'"
      ;;

      *output_raw*)
         sed 's/;$//g' <<< "${line}"
      ;;

      *)
         echo "${line}"
      ;;
   esac
}
