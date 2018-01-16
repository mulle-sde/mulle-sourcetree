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
         result="`${MULLE_FETCH:-mulle-fetch} ${MULLE_FETCH_FLAGS} guess -s "${nodetype}" "${evaledurl}"`"
         log_fluff "${MULLE_FETCH:-mulle-fetch} returned \"${result}\" as default address for url ($url)"
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
         log_fluff "${MULLE_FETCH:-mulle-fetch} determined \"${result}\" as _nodetype from \
url ($evaledurl)"
         echo "${result}"
      ;;
   esac
}


node_fetch_operation()
{
   log_entry "node_fetch_operation" "$@"

   local opname="$1"; shift
   local options="$1"; shift

   [ -z "${opname}" ] && internal_fail "opname is empty"

   local url="$1"; shift
   local address="$1"; shift
   local branch="$1"; shift
   local tag="$1"; shift
   local nodetype="$1"; shift
   local fetchoptions="$1"; shift

   [ -z "${url}" ] && fail "URL is empty"

   local rval
   local evaledurl
   local evaledbranch
   local evaledtag
   local evaledfetchoptions

   evaledurl="`eval echo "${url}"`"
   [ -z "${evaledurl}" ] && fail "URL \"${url}\" evaluates to empty"
   evaledtag="`eval echo "${tag}"`"
   evaledbranch="`eval echo "${branch}"`"
   evaledfetchoptions="`eval echo "${_fetchoptions}"`"

   log_info "Looking for local source of ${C_RESET_BOLD}${evaledurl}${C_INFO}"

   local localurl

   localurl="$( eval_exekutor ${MULLE_FETCH:-mulle-fetch} "search-local" --scm "'${nodetype}'" \
                                                            --tag "'${evaledtag}'" \
                                                            --branch "'${evaledbranch}'" \
                                                            --options "'${evaledfetchoptions}'" \
                                                            --url "'${evaledurl}'" \
                                                            "'${address}'" )"
   if [ ! -z "${localurl}" ]
   then
      evaledurl="${localurl}"
   fi

   log_info "Fetching ${C_MAGENTA}${C_BOLD}${address}${C_INFO} from \
${C_RESET_BOLD}${evaledurl}${C_INFO}"
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

   ${MULLE_FETCH:-mulle-fetch} ${MULLE_FETCH_FLAGS} operations -s "${nodetype}"
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
         # since they are local, they can not be deleted and are always required
         #
         local before

         before="${_marks}"

         if nodemarks_contain_delete "${_marks}"
         then
            _marks="`nodemarks_remove_delete "${_marks}"`"
         fi
         if ! nodemarks_contain_require "${_marks}"
         then
            _marks="`nodemarks_add_require "${_marks}"`"
         fi

         if [ "${before}" != "${_marks}" ]
         then
            log_verbose "Node of nodetype \"${_nodetype}\" gained marks \"no-delete,require\""
         fi
      ;;
   esac

   case "${mode}" in
      *unsafe*)
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


nodemarks_key_check()
{
   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"

   case "${1}" in
      "")
         internal_fail "Empty key"
      ;;

      no-*|only-*)
      ;;

      *)
         internal_fail "Nodemarks key \"$1\" must start with \"no-\" or \"only-\""
      ;;
   esac
}


#
# node marking
#
nodemarks_add()
{
   local marks="$1"
   local key="$2"

   nodemarks_key_check "${key}"

   local i

   # is this faster than case ?
   IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}"
      if [ "$i" = "${key}" ]
      then
         echo "${marks}"
         return
      fi
   done
   IFS="${DEFAULT_IFS}"

   comma_concat "${marks}" "${key}"
}


nodemarks_remove()
{
   local marks="$1"
   local key="$2"

   nodemarks_key_check "${key}"

   local result
   local i

   IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}"

      if [ "${i}" != "${key}" ]
      then
         result="`comma_concat "${result}" "${i}"`"
      fi
   done
   IFS="${DEFAULT_IFS}"

   echo "${result}"
}


_nodemarks_contain()
{
   local marks="$1"
   local key="$2"

   nodemarks_key_check "${key}"

   local i

   # is this faster than case ?
   IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}"
      if [ "${i}" = "${key}" ]
      then
         return 0
      fi
   done

   IFS="${DEFAULT_IFS}"
   return 1
}


nodemarks_contain()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      no-*|only-*)
         _nodemarks_contain "${marks}" "${key}"
      ;;

      *)
         ! _nodemarks_contain "${marks}" "no-${key}"
      ;;
   esac

}


nodemarks_intersect()
{
   local marks="$1"
   local anymarks="$2"

   local key

   IFS=","
   for key in ${anymarks}
   do
      IFS="${DEFAULT_IFS}"
      if nodemarks_contain "${marks}" "${key}"
      then
         return 0
      fi
   done

   IFS="${DEFAULT_IFS}"
   return 1
}


#
#
#
nodemarks_add_build()
{
   log_entry "nodemarks_add_build" "$@"

   nodemarks_remove "$1" "no-build"
}

nodemarks_add_delete()
{
   log_entry "nodemarks_add_delete" "$@"

   nodemarks_remove "$1" "no-delete"
}

nodemarks_add_dependency()
{
   log_entry "nodemarks_add_dependency" "$@"

   nodemarks_remove "$1" "no-dependency"
}


nodemarks_add_recurse()
{
   log_entry "nodemarks_add_recurse" "$@"

   nodemarks_remove "$1" "no-recurse"
}

nodemarks_add_require()
{
   log_entry "nodemarks_add_require" "$@"

   nodemarks_remove "$1" "no-require"
}

nodemarks_add_set()
{
   log_entry "nodemarks_add_set" "$@"

   nodemarks_remove "$1" "no-set"
}

nodemarks_add_share()
{
   log_entry "nodemarks_add_share" "$@"

   nodemarks_remove "$1" "no-share"
}

nodemarks_add_update()
{
   log_entry "nodemarks_add_update" "$@"

   nodemarks_remove "$1" "no-update"
}


nodemarks_contain_build()
{
   log_entry "nodemarks_contain_build" "$@"

   ! _nodemarks_contain "$1" "no-build"
}

nodemarks_contain_delete()
{
   log_entry "nodemarks_contain_delete" "$@"

   ! _nodemarks_contain "$1" "no-delete"
}


nodemarks_contain_dependency()
{
   log_entry "nodemarks_contain_dependency" "$@"

   ! _nodemarks_contain "$1" "no-dependency"
}


nodemarks_contain_recurse()
{
   log_entry "nodemarks_contain_recurse" "$@"

   ! _nodemarks_contain "$1" "no-recurse"
}

nodemarks_contain_require()
{
   log_entry "nodemarks_contain_require" "$@"

   ! _nodemarks_contain "$1" "no-require"
}

nodemarks_contain_set()
{
   log_entry "nodemarks_contain_set" "$@"

   ! _nodemarks_contain "$1" "no-set"
}

nodemarks_contain_share()
{
   log_entry "nodemarks_contain_share" "$@"

   ! _nodemarks_contain "$1" "no-share"
}

nodemarks_contain_update()
{
   log_entry "nodemarks_contain_update" "$@"

   ! _nodemarks_contain "$1" "no-update"
}


nodemarks_remove_build()
{
   log_entry "nodemarks_remove_build" "$@"

   nodemarks_add "$1" "no-build"
}

nodemarks_remove_delete()
{
   log_entry "nodemarks_remove_delete" "$@"

   nodemarks_add "$1" "no-delete"
}

nodemarks_remove_dependency()
{
   log_entry "nodemarks_remove_dependency" "$@"

   nodemarks_add "$1" "no-dependency"
}

nodemarks_remove_recurse()
{
   log_entry "nodemarks_remove_recurse" "$@"

   nodemarks_add "$1" "no-recurse"
}

nodemarks_remove_require()
{
   log_entry "nodemarks_remove_require" "$@"

   nodemarks_add "$1" "no-require"
}

nodemarks_remove_set()
{
   log_entry "nodemarks_remove_set" "$@"

   nodemarks_add "$1" "no-set"
}

nodemarks_remove_share()
{
   log_entry "nodemarks_remove_share" "$@"

   nodemarks_add "$1" "no-share"
}

nodemarks_remove_update()
{
   log_entry "nodemarks_remove_update" "$@"

   nodemarks_add "$1" "no-update"
}


#
#
#
nodemarks_add_no_build()
{
   log_entry "nodemarks_add_no_build" "$@"

   nodemarks_add "$1" "no-build"
}

nodemarks_add_no_delete()
{
   log_entry "nodemarks_add_no_delete" "$@"

   nodemarks_add "$1" "no-delete"
}

nodemarks_add_no_dependency()
{
   log_entry "nodemarks_add_no_dependency" "$@"

   nodemarks_add "$1" "no-dependency"
}

nodemarks_add_no_recurse()
{
   log_entry "nodemarks_add_no_recurse" "$@"

   nodemarks_add "$1" "no-recurse"
}

nodemarks_add_no_require()
{
   log_entry "nodemarks_add_no_require" "$@"

   nodemarks_add "$1" "no-require"
}

nodemarks_add_no_set()
{
   log_entry "nodemarks_add_no_set" "$@"

   nodemarks_add "$1" "no-set"
}

nodemarks_add_no_share()
{
   log_entry "nodemarks_add_no_share" "$@"

   nodemarks_add "$1" "no-share"
}

nodemarks_add_no_update()
{
   log_entry "nodemarks_add_no_update" "$@"

   nodemarks_add "$1" "no-update"
}


nodemarks_contain_no_build()
{
   log_entry "nodemarks_contain_no_build" "$@"

   _nodemarks_contain "$1" "no-build"
}

nodemarks_contain_no_delete()
{
   log_entry "nodemarks_contain_no_delete" "$@"

   _nodemarks_contain "$1" "no-delete"
}

nodemarks_contain_no_dependency()
{
   log_entry "nodemarks_contain_no_dependency" "$@"

   _nodemarks_contain "$1" "no-dependency"
}

nodemarks_contain_no_recurse()
{
   log_entry "nodemarks_contain_no_recurse" "$@"

   _nodemarks_contain "$1" "no-recurse"
}

nodemarks_contain_no_require()
{
   log_entry "nodemarks_contain_no_require" "$@"

   _nodemarks_contain "$1" "no-require"
}

nodemarks_contain_no_set()
{
   log_entry "nodemarks_contain_no_set" "$@"

   _nodemarks_contain "$1" "no-set"
}

nodemarks_contain_no_share()
{
   log_entry "nodemarks_contain_no_share" "$@"

   _nodemarks_contain "$1" "no-share"
}

nodemarks_contain_no_update()
{
   log_entry "nodemarks_contain_no_update" "$@"

   _nodemarks_contain "$1" "no-update"
}


nodemarks_remove_no_build()
{
   log_entry "nodemarks_remove_no_build" "$@"

   nodemarks_remove "$1" "no-build"
}

nodemarks_remove_no_delete()
{
   log_entry "nodemarks_remove_no_delete" "$@"

   nodemarks_remove "$1" "no-delete"
}


nodemarks_remove_no_dependency()
{
   log_entry "nodemarks_remove_no_dependency" "$@"

   nodemarks_remove "$1" "no-dependency"
}


nodemarks_remove_no_recurse()
{
   log_entry "nodemarks_remove_no_recurse" "$@"

   nodemarks_remove "$1" "no-recurse"
}

nodemarks_remove_no_require()
{
   log_entry "nodemarks_remove_no_require" "$@"

   nodemarks_remove "$1" "no-require"
}

nodemarks_remove_no_set()
{
   log_entry "nodemarks_remove_no_set" "$@"

   nodemarks_remove "$1" "no-set"
}

nodemarks_remove_no_share()
{
   log_entry "nodemarks_remove_no_share" "$@"

   nodemarks_remove "$1" "no-share"
}

nodemarks_remove_no_update()
{
   log_entry "nodemarks_remove_no_update" "$@"

   nodemarks_remove "$1" "no-update"
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


#
# this is unformatted
#
node_to_nodeline()
{
   log_entry "node_to_nodeline" "$@"

   case "${_url}" in
      *\;*)
         fail "_url \"${_url}\" contains semicolon"
      ;;
   esac

   case "${_address}" in
      *\;*)
         fail "Address \"${_address}\" contains semicolon"
      ;;

      "")
         internal_fail "Address \"${_address}\" is empty"
      ;;
   esac

   case "${_branch}" in
      *\;*)
         fail "Branch \"${_branch}\" contains semicolon"
      ;;
   esac

   case "${_tag}" in
      *\;*)
         fail "Tag \"${_tag}\" contains semicolon"
      ;;
   esac

   case "${_nodetype}" in
      *\;*)
         fail "Nodetype \"${_nodetype}\" contains semicolon"
      ;;
      *\,*)
         fail "Nodetype \"${_nodetype}\" contains comma"
      ;;
      "")
         internal_fail "_nodetype is empty"
      ;;
   esac

   case "${_uuid}" in
      *\;*)
         fail "UUID \"${_uuid}\" contains semicolon"
      ;;
      "")
         internal_fail "_uuid is empty"
      ;;
   esac

   case "${_marks}" in
      *\;*)
         fail "Marks \"${_marks}\" contain semicolon"
      ;;

      ,*|*,,*|*,)
         fail "Marks \"${_marks}\" are ugly, remove excess commata"
      ;;
   esac

   case "${_fetchoptions}" in
      *\;*)
         fail "Fetchoptions \"${_fetchoptions}\" contains semicolon"
      ;;

      ,*|*,,*|*,)
         fail "Fetchoptions \"${_fetchoptions}\" are ugly, remove excess commata"
      ;;
   esac

   if [ ! -z "${_userinfo}" ]
   then
      if egrep -q '[^-A-Za-z0-9%&/()=|+_.,$# ]' <<< "${_userinfo}"
      then
         _userinfo="base64:`base64 -b 0 <<< "${_userinfo}"`"
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


nodetypes_contain()
{
   log_entry "nodetypes_contain" "$@"

   local nodetypes="$1"
   local nodetype="$2"

   local key

   IFS=","
   for key in ${nodetypes}
   do
      IFS="${DEFAULT_IFS}"
      if [ "${nodetype}" = "${key}" ]
      then
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}"
   return 1
}


nodetype_filter_with_allowable_nodetypes()
{
   log_entry "nodetypes_filter_with_allowable_nodetypes" "$@"

   local nodetype="$1"
   local allowednodetypes="$2"

   [ -z "${nodetype}" ] && internal_fail "empty nodetype"

   if [ "${allowednodetypes}" = "ALL" ]
   then
      log_fluff "ALL matches all"
      return 0
   fi

   nodetypes_contain "${allowednodetypes}" "${nodetype}"
}


#
# you can pass a qualifier of the form <all>;<one>;<none>;<override>
# inside all,one,none,override there are comma separated marks
#
nodemarks_filter_with_qualifier()
{
   log_entry "nodemarks_filter_with_qualifier" "$@"

   local marks="$1"
   local qualifier="$2"

   if [ "${qualifier}" = "ANY" ]
   then
      log_fluff "ANY matches all"
      return 0
   fi

   local all
   local one
   local none
   local override

   all="$(cut -d';' -f 1 <<< "${qualifier}")"
   one="$(cut -s -d';' -f 2 <<< "${qualifier}")"
   none="$(cut -s -d';' -f 3 <<< "${qualifier}")"
   override="$(cut -s -d';' -f 4 <<< "${qualifier}")"

   local i

   if [ ! -z "${override}" ]
   then
      IFS=","
      for i in ${override}
      do
         IFS="${DEFAULT_IFS}"
         if nodemarks_contain "${marks}" "${i}"
         then
            log_fluff "Pass: override mark \"$i\" found"
            return 0
         fi
      done
      IFS="${DEFAULT_IFS}"
   fi

   if [ ! -z "${all}" ]
   then
      IFS=","
      for i in ${all}
      do
         IFS="${DEFAULT_IFS}"
         if ! nodemarks_contain "${marks}" "${i}"
         then
            log_fluff "Blocked: required mark \"$i\" not found"
            return 1
         fi
      done
      IFS="${DEFAULT_IFS}"
   fi

   if [ ! -z "${one}" ]
   then
      if ! nodemarks_intersect "${marks}" "${one}"
      then
         log_fluff "Blocked: mark \"$i\" not present"
         return 1
      fi
   fi

   if [ ! -z "${none}" ]
   then
      IFS=","
      for i in ${none}
      do
         IFS="${DEFAULT_IFS}"
         if nodemarks_contain "${marks}" "${i}"
         then
            log_fluff "Blocked: mark \"$i\" inhibits"
            return 1
         fi
      done
      IFS="${DEFAULT_IFS}"
   fi
}
