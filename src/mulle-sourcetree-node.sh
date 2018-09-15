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


node_uuidgen()
{
   log_entry "node_uuidgen" "$@"

   uuidgen || fail "Need uuidgen to wok"
}


node_guess_address()
{
   log_entry "node_guess_address" "$@"

   local url="$1"
   local nodetype="${2:-local}"

   [ -z "${url}" ] && fail "URL is empty"

   local evaledurl
   local result

   evaledurl="`eval echo "${url}"`"

   case "${evaledurl}" in
      "")
         fail "URL \"${url}\" evaluates to empty"
      ;;

      *)
         result="`${MULLE_FETCH:-mulle-fetch} ${MULLE_FETCH_FLAGS} \
                     nameguess -s "${nodetype}" "${evaledurl}"`"
         log_fluff "${MULLE_FETCH:-mulle-fetch} returned \"${result}\" as \
default address for url ($url)"
         echo "${result}"
      ;;
   esac
}


node_guess_nodetype()
{
   log_entry "node_guess_nodetype" "$@"

   local url="$1"

   [ -z "${url}" ] && fail "URL is empty"

   local evaledurl
   local result

   evaledurl="`eval echo "${url}"`"
   case "${evaledurl}" in
      "")
      ;;

      *)
         result="`${MULLE_FETCH:-mulle-fetch} ${MULLE_FETCH_FLAGS} typeguess "${evaledurl}"`"
         log_fluff "${MULLE_FETCH:-mulle-fetch} determined \"${result}\" as \
nodetype from url ($evaledurl)"
         echo "${result}"
      ;;
   esac
}


node_sanitized_address()
{
   log_entry "node_sanitized_address" "$@"

   local address="$1"

   local modified

   modified="`simplified_path "${address}"`"
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
   echo "${modified}"
}


node_fetch_operation()
{
   log_entry "node_fetch_operation" "$@"

   local opname="$1"
   local options="$2"

   [ -z "${opname}" ] && internal_fail "opname is empty"

   local url="$3"
   local address="$4"
   local branch="$5"
   local tag="$6"
   local nodetype="$7"
   local fetchoptions="$8"

   [ -z "${url}" ] && fail "URL is empty"

   local rval
   local evaledurl
   local evaledbranch
   local evaledtag
   local evaledfetchoptions

   evaledurl="`eval echo "${url}"`"
   evaledtag="`eval echo "${tag}"`"
   evaledbranch="`eval echo "${branch}"`"
   evaledfetchoptions="`eval echo "${_fetchoptions}"`"

   [ -z "${evaledurl}" ] && fail "URL \"${url}\" evaluates to empty"

   case "${nodetype}" in
      file)
         # does not implement local search
      ;;

      *)
         log_verbose "Looking for local copy of ${C_RESET_BOLD}${evaledurl}${C_INFO}"

         local localurl
         local localnodetype

         localurl="$( eval_exekutor ${MULLE_FETCH:-mulle-fetch} "search-local" --scm "'${nodetype}'" \
                                                                  --tag "'${evaledtag}'" \
                                                                  --branch "'${evaledbranch}'" \
                                                                  --options "'${evaledfetchoptions}'" \
                                                                  --url "'${evaledurl}'" \
                                                                  "'${address}'" )"
         if [ ! -z "${localurl}" ]
         then
            evaledurl="${localurl}"
            log_verbose "Local URL found \"${localurl}\""
            localnodetype="`node_guess_nodetype "${localurl}"`"
            if [ ! -z "${localnodetype}" ]
            then
               nodetype="${localnodetype}"
            fi
         else
            log_fluff "No local URL found"
         fi
      ;;
   esac

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${address#${MULLE_SOURCETREE_SHARE_DIR}/}${C_INFO} from \
${C_RESET_BOLD}${evaledurl}${C_INFO}."

   eval_exekutor ${MULLE_FETCH:-mulle-fetch} ${MULLE_FETCH_FLAGS} \
                                             "${opname}" --scm "'${nodetype}'" \
                                                         --tag "'${evaledtag}'" \
                                                         --branch "'${evaledbranch}'" \
                                                         --options "'${evaledfetchoptions}'" \
                                                         --url "'${evaledurl}'" \
                                                         ${options} \
                                                         "'${address}'"
}


node_list_operations()
{
   log_entry "node_list_operations" "$@"

   local nodetype="$1"

   ${MULLE_FETCH:-mulle-fetch} ${MULLE_FETCH_FLAGS} -s operation -s "${nodetype}" list
}

#
# This function sets values of variables that should be declared
# in the caller!
#
#   # node_augmentline
#
#   local _branch
#   local _address
#   local _fetchoptions
#   local _marks
#   local _nodetype
#   local _tag
#   local _url
#   local _userinfo
#   local _uuid
#
node_augment()
{
   local mode="$1"

   if [ -z "${_uuid}" ]
   then
      _uuid="$(node_uuidgen)"
   fi

   _nodetype="${_nodetype:-local}"

   case "${_nodetype}" in
      "local")
         #
         # since they are local, they can not be deleted and are always
         # required they are also never updated
         #
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
            fail "Node of nodetype \"${_nodetype}\" requires marks \"no-delete,no-update,no-share,require\""
         fi
      ;;

      "symlink")
         mode="unsafe"
      ;;
   esac

   case ",${mode}," in
      *,unsafe,*)
      ;;

      *)
         _address="`node_sanitized_address "${_address}"`" || exit 1
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

   local rval

   r_nodemarks_sort "${_marks}"
   _marks="${RVAL}"

   # this is done  during auto already
   # case "${_address}" in
   #    ..*|~*|/*)
   #     fail "_address \"${_address}\" is invalid ($nodeline)"
   #    ;;
   # esac

   [ -z "${_uuid}" ]     && internal_fail "_uuid is empty"
   [ -z "${_nodetype}" ] && internal_fail "_nodetype is empty"
   [ -z "${_address}" ]  && internal_fail "_address is empty"

   # does not work
   [ "${_address}" = "." ]  && fail "Node address is '.'"

   :
}


#
# this is unformatted
#
node_to_nodeline()
{
   log_entry "node_to_nodeline" "$@"

   case "${_url}" in
      *";"*)
         fail "_url \"${_url}\" contains semicolon"
      ;;
   esac

   case "${_address}" in
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

   if [ ! -z "${_userinfo}" ]
   then
      if [ `wc -l <<< "${_userinfo}"` -gt 1 ] ||
         egrep -q '[^-A-Za-z0-9%&/()=|+_.,$# ]' <<< "${_userinfo}"
      then
         case "${MULLE_UNAME}" in
            linux)
               _userinfo="base64:`base64 -w 0 <<< "${_userinfo}"`"
            ;;

            *)
               _userinfo="base64:`base64 -b 0 <<< "${_userinfo}"`"
            ;;
         esac
      fi
   fi

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

   echo "${_address};${_nodetype};${_marks};${_uuid};\
${_url};${_branch};${_tag};${_fetchoptions};\
${_userinfo}"
}


nodetype_filter()
{
   log_entry "nodetype_filter" "$@"

   local nodetype="$1"
   local filter="$2"

   [ -z "${nodetype}" ] && internal_fail "empty nodetype"

   [ -z "${filter}" ] && return 0

   case ",${filter}," in
      *,no-${nodetype},*)
         return 1
      ;;
   esac

   case ",${filter}," in
      *,ALL,*|*,${nodetype},*)
         return 0
      ;;
   esac

   return 1
}

