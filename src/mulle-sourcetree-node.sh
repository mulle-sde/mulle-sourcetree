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
MULLE_SOURCETREE_NODE_SH="included"


r_node_uuidgen()
{
   log_entry "r_node_uuidgen" "$@"

   #
   # ensure that case doesn't change on linux, uuidgen is lowercase
   # on macsos it's uppercase. Now this is likely not a problem IRL
   # but who knows if b314406e-371a-4d73-996f-9b5906564dcf !=
   # B314406E-371A-4D73-996F-9B5906564DCF isn't a subtle bug in the future
   #
   RVAL="`uuidgen`" || fail "Need uuidgen to work"
   r_uppercase "${RVAL}"
}


r_node_sanitized_address()
{
   log_entry "r_node_sanitized_address" "$@"

   local address="$1"

   local modified

   r_simplified_path "${address}"
   modified="${RVAL}"
   if is_absolutepath "${modified}"
   then
      fail "Address \"${address}\" is an absolute filepath"
   fi

   case "${modified}" in
      ..|../*)
         fail "Destination \"${modified}\" tries to escape project"
      ;;
   esac

   if [ "${modified}" != "${address}" ]
   then
      log_fluff "Destination \"${address}\" sanitized to \"${modified}\""
   fi
   RVAL="${modified}"
}


#
# This function sets values of variables that should be declared
# in the caller!
#
#   # node_augment
#
#   local _branch
#   local _address
#   local _fetchoptions
#   local _marks
#   local _nodetype
#   local _tag
#   local _url
#   local _raw_userinfo
#   local _uuid
#
node_augment()
{
   local mode="$1"

   if [ -z "${_uuid}" ]
   then
      r_node_uuidgen
      _uuid="${RVAL}"
   fi

   _nodetype="${_nodetype:-local}"

   case "${_nodetype}" in
      "local")
         #
         # since they are local, they can not be deleted and are always
         # required they are also never updated. So mode can be unsafe here
         #
         mode="unsafe"

         local before

         before="${_marks}"

         r_nodemarks_remove "${before}" "share"
         after="${RVAL}"
         r_nodemarks_remove "${after}" "delete"
         after="${RVAL}"
         r_nodemarks_remove "${after}" "update"
         after="${RVAL}"
         r_nodemarks_add "${after}" "require"
         after="${RVAL}"

         if [ "${before}" != "${after}" ]
         then
            log_warning "Node of nodetype \"${_nodetype}\" augmented with \
necessary marks \"no-delete,no-update,no-share,require\""
            _marks="${after}"
         fi

         # local has no URL
         _url=
      ;;

      "symlink")
         mode="unsafe"
      ;;
   esac

   case ",${mode}," in
      *,unsafe,*)
      ;;

      *)
         r_node_sanitized_address "${_address}"
         _address="${RVAL}" || exit 1
      ;;
   esac



   r_nodemarks_simplify "${_marks}"
   r_nodemarks_sort "${RVAL}"
   _marks="${RVAL}"

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

   # this is done  during auto already
   # case "${_address}" in
   #    ..*|~*|/*)
   #     fail "_address \"${_address}\" is invalid ($nodeline)"
   #    ;;
   # esac

   [ -z "${_uuid## }" ]     && internal_fail "_uuid is empty"
   [ -z "${_nodetype## }" ] && internal_fail "_nodetype is empty"
   [ -z "${_address## }" ]  && internal_fail "_address is empty"

   # does not work
   [ "${_address}" = "." ]  && fail "Node address is '.'"

   :
}


_r_node_to_nodeline()
{
   log_entry "_r_node_to_nodeline" "$@"

   if [ ! -z "${_userinfo}" ]
   then
      local convert

      convert="NO"
      case "${_userinfo}" in
         *$'\n'*)
            convert="YES"
         ;;

         *)
            # basically escape non-printables :isprint: and ';'
            if egrep -q '[^[:print:]]|;' <<< "${_userinfo}"
            then
               convert="YES"
            fi
         ;;
      esac

      if [ "${convert}" = "YES" ]
      then
         case "${MULLE_UNAME}" in
            linux|windows)
               _raw_userinfo="base64:`base64 -w 0 <<< "${_userinfo}"`"
            ;;

            *)
               _raw_userinfo="base64:`base64 -b 0 <<< "${_userinfo}"`"
            ;;
         esac
      else
         _raw_userinfo="${_userinfo}"
      fi
   fi

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

   RVAL="${_address};${_nodetype};${_marks};${_uuid};\
${_url};${_branch};${_tag};${_fetchoptions};\
${_raw_userinfo}"
}

#
# this is unformatted
#
r_node_to_nodeline()
{
   log_entry "r_node_to_nodeline" "$@"

   case "${_url}" in
      *";"*)
         fail "_url \"${_url}\" contains semicolon"
      ;;
   esac

   case "${_address}" in
      "/"*)
         fail "Address \"${_address}\" must be relative"
      ;;

      "."*)
         fail "Address \"${_address}\" starts with a dot"
      ;;

      *";"*)
         fail "Address \"${_address}\" contains semicolon"
      ;;

      "")
         internal_fail "Address \"${_address}\" is empty"
      ;;
   esac

   case "${_branch}" in
      *";"*)
         fail "Branch \"${_branch}\" contains semicolon"
      ;;
   esac

   case "${_tag}" in
      *";"*)
         fail "Tag \"${_tag}\" contains semicolon"
      ;;
   esac

   case "${_nodetype}" in
      *";"*)
         fail "Nodetype \"${_nodetype}\" contains semicolon"
      ;;
      *","*)
         fail "Nodetype \"${_nodetype}\" contains comma"
      ;;
      "")
         internal_fail "_nodetype is empty"
      ;;
   esac

   case "${_uuid}" in
      *";"*)
         fail "UUID \"${_uuid}\" contains semicolon"
      ;;
      "")
         internal_fail "_uuid is empty"
      ;;
   esac

   case "${_marks}" in
      *";"*)
         fail "Marks \"${_marks}\" contain semicolon"
      ;;

      ","*|*",,"*|*",")
         fail "Marks \"${_marks}\" are ugly, remove excess commata"
      ;;
   esac

   case "${_fetchoptions}" in
      *";"*)
         fail "Fetchoptions \"${_fetchoptions}\" contains semicolon"
      ;;

      ","*|*",,"*|*",")
         fail "Fetchoptions \"${_fetchoptions}\" are ugly, remove excess commata"
      ;;
   esac

   _r_node_to_nodeline "$@"
}


node_to_nodeline()
{
   log_entry "node_to_nodeline" "$@"

   r_node_to_nodeline "$@"
   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"
}


nodetype_filter()
{
   log_entry "nodetype_filter" "$@"

   local nodetype="$1"
   local filter="$2"

   [ -z "${nodetype}" ] && internal_fail "empty nodetype"

   case ",${filter}," in
      *,no-${nodetype},*)
         return 1
      ;;
   esac

   case ",${filter}," in
      *,ALL,*|,,)
         log_debug "ALL or empty matches always"
         return 0
      ;;

      *,${nodetype},*)
         log_debug "\"${nodetype}\" matches \"${filter}\""
         return 0
      ;;
   esac

   log_debug "\"${nodetype}\" doesn't match \"${filter}\""
   return 1
}


#
# returns _formatstring
# and key in RVAL
#
_r_get_format_key()
{
   log_entry "_r_get_format_key" "$@"

   local formatstring="$1"

   if [ -z "${MULLE_ARRAY_SH}" ]
   then
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-array.sh" || \
         internal_fail "Could not load mulle-array.sh via \"${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}\""
   fi

   RVAL="`sed -n 's/%.={\([^,]*\)[,]*[^,]*[,]*[^}]*}.*/\1/p' <<< "${formatstring}" `"

   local remainder

   remainder="`sed 's/^%.={[^}]*}//' <<< "${formatstring}" `"
   if [ -z "${RVAL}" -o "${remainder}" = "${formatstring}" ]
   then
      fail "malformed formatstring \"${formatstring:1}\". Need ={<title>,<dashes>,<key>}"
   fi
   _formatstring="XX${remainder}" ## XX is used for skipping first two chars
}

#
# specify indentfor ':' with parameter
# use sed to shift the output to right or left
#
node_printf_format_help()
{
   local i="$1"

   cat <<EOF
   a        ${i}: address
   b        ${i}: branch
   b!       ${i}: evaluated branch
   f        ${i}: fetchoptions
   f!       ${i}: evaluated fetchoptions
   i        ${i}: userinfo (e.g. aliases). You can influence the formatting
            ${i}  with i={key,header,separators}
   m        ${i}: marks
   n        ${i}: nodetype
   n!       ${i}: evaluated nodetype
   t        ${i}: tag
   t!       ${i}: evaluated tag
   u        ${i}: url
   u!       ${i}: evaluated url
   U        ${i}: url or address, if url is missing
   U!       ${i}: evaluated url or address, if url is missing
   v={name} ${i}: contents of environment variable
   _        ${i}: uuid
   \\n       ${i}: linefeed
EOF
}


#  local _evaledurl
#  local _evalednodetype
#  local _evaledbranch
#  local _evaledtag
#  local _evaledfetchoptions
node_evaluate_values()
{
   log_entry "node_evaluate_values" "$@"

   r_expanded_string "${_nodetype}"
   _evalednodetype="${RVAL}"
   r_expanded_string "${_branch}"
   _evaledbranch="${RVAL}"
   r_expanded_string "${_tag}"
   _evaledtag="${RVAL}"

   MULLE_BRANCH="${_evaledbranch}" \
   MULLE_TAG="${_evaledtag}"
      r_expanded_string "${_url}"
      _evaledurl="${RVAL}"

   MULLE_BRANCH="${_evaledbranch}" \
   MULLE_TAG="${_evaledtag}" \
   MULLE_URL="${_evaledurl}" \
      r_expanded_string "${_fetchoptions}"
      _evaledfetchoptions="${RVAL}"
}


node_printf()
{
   log_entry "node_printf" "$@"

   local mode="$1"
   local formatstring="$2"
   local cmdline="$3"
   local indent="$4"

   local sep

   r_get_sep "${mode}"
   sep="${RVAL}"

   r_get_formatstring "${mode}" "${formatstring}" "${sep}"
   formatstring="${RVAL}"

   case ",${mode}," in
      *,no-indent,*)
         indent=""
      ;;
   esac

   local _evaledurl
   local _evalednodetype
   local _evaledbranch
   local _evaledtag
   local _evaledfetchoptions

   node_evaluate_values

   local _url="${_url}"
   local _nodetype="${_nodetype}"
   local _branch="${_branch}"
   local _tag="${_tag}"
   local _fetchoptions="${_fetchoptions}"

   case ",${mode}," in
      *,output_eval,*)
         _url="${_evaledurl}"
         _nodetype="${_evalednodetype}"
         _branch="${_evaledbranch}"
         _tag="${_evaledtag}"
         _fetchoptions="${_evaledfetchoptions}"
      ;;
   esac

   local line
   local lf=$'\n'

   if [ -z "${cmdline}" ]
   then
      cmdline="${MULLE_USAGE_NAME} -N add"
   fi

   local _formatstring
   local extended

   while [ ! -z "${formatstring}" ]
   do
      local value
      local switch

      case "${formatstring}" in
         %a*)
            switch=""
            value="${_address}"
         ;;

         # memP: ! before non ! for case order
         %b!*)
            switch="--branch"
            value="${_evaledbranch}"
            formatstring="${formatstring:1}" # for '!'
         ;;

         %b*)
            switch="--branch"
            value="${_branch}"
         ;;

         %f!*)
            switch="--fetchoptions"
            value="${_evaledfetchoptions}"
            formatstring="${formatstring:1}"
         ;;

         %f*)
            switch="--fetchoptions"
            value="${_fetchoptions}"
         ;;

         %i*)
            switch="--userinfo"

            case ",${mode}," in
               *,output_cmd,*|*,output_cmd2,*)
                  value="${_raw_userinfo}"
               ;;

               *)
            if [ ! -z "${_raw_userinfo}" -a -z "${_userinfo}" ]
            then
                     r_nodeline_raw_userinfo_parse "${_raw_userinfo}"
                     _userinfo="${RVAL}"
            fi

            extended='NO'
            if [ "${formatstring:2:2}" = "={" ]
            then
               _r_get_format_key "${formatstring}"
               key="${RVAL}"
               formatstring="${_formatstring}"
               extended='YES'

                     switch="--${key}"

                     r_assoc_array_get "${_userinfo}" "${key}"
                     value="${RVAL}"
                  else
                     value="${_userinfo//${lf}/:}"
                     value="${value%%;}"
                     value="${value#:}"
                     value="${value%:}"
                  fi
               ;;
            esac
         ;;


         %m*)
            switch="--marks"
            value="${_marks}"
         ;;

         %n!*)
            switch="--nodetype"
            value="${_evalednodetype}"
            formatstring="${formatstring:1}"
         ;;

         %n*)
            switch="--nodetype"
            value="${_nodetype}"
         ;;

         %t!*)
            switch="--tag"
            value="${_evaledtag}"
            formatstring="${formatstring:1}"
         ;;

         %t*)
            switch="--tag"
            value="${_tag}"
         ;;

         %u!*)
            switch="--url"
            value="${_evaledurl}"
            formatstring="${formatstring:1}"
         ;;

         %u*)
            switch="--url"
            value="${_url}"
         ;;

         %U!*)
            switch="--url"
            if [ -z "${_url}" ]
            then
               value="${_address}"
            else
               value="${_evaledurl}"
            fi
            formatstring="${formatstring:1}"
         ;;

         %U*)
            switch="--url"
            if [ -z "${_url}" ]
            then
               value="${_address}"
            else
               value="${_url}"
            fi
         ;;

         # output an "environment" variable
         %v*)
            switch=""
            if [ "${formatstring:2:1}" = "=" ]
            then
               _r_get_format_key "${formatstring}"
               key="${RVAL}"
               formatstring="${_formatstring}"
               switch=""

               value="${!key}"
            else
               value="failed format"
            fi
         ;;

         %_*)
            switch=""
            value="${_uuid}"
         ;;

         %*)
            fail "unknown format character \"${formatstring:0:2}\""
         ;;

         \\n)
            switch=""
            value=$'\n'
         ;;

         *)
            case ",${mode}," in
               *,output_cmd,*|*,output_cmd2,*)
               ;;

               *)
                  line="${line}${formatstring:0:1}"
               ;;
            esac
            formatstring="${formatstring:1}"
            continue
         ;;
      esac

      formatstring="${formatstring:2}"

      case ",${mode}," in
         *,output_column,*)
            if [ -z "${value}" ]
            then
               value=" "
            fi
         ;;
      esac

      line="${line}${value}"

      if [ ! -z "${switch}" -a ! -z "${value}" ]
      then
         r_concat "${cmdline}" "${switch} '${value}'"
         cmdline="${RVAL}"
      fi
   done

   local prefix

   prefix=""
   case "${_evalednodetype}" in
      comment)
         prefix="# "
      ;;
   esac

   case ",${mode}," in
      *,output_cmd,*)
         rexekutor printf "%s %s\n" "${cmdline}" "'${_address}'"
      ;;

      *,output_cmd2,*)
         rexekutor printf "%s %s\n" "${cmdline}" "'${_url:-${_address}}'"
      ;;

      *,output_raw,*)
         rexekutor printf "%s%s" "${indent}" "${line}" | sed 's/;$//g'
      ;;

      *)
         rexekutor printf "%s%s%s" "${prefix}" "${indent}" "${line}"
      ;;
   esac
}
