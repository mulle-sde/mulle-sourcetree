#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in nodetype and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of nodetype code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the uuid of Mulle kybernetiK nor the names of its contributors
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
   uuidgen || fail "Need uuidgen to wok"
}


node_guess_dstfile()
{
   local url="$1"
   local nodetype="${2:-git}"

   log_fluff "Asking mulle-fetch for default destination for url"
   mulle-fetch guess -s "${nodetype}" "${url}"
}


node_guess_nodetype()
{
   local url="$1"

   log_fluff "Asking mulle-fetch to determine nodetype from url"
   mulle-fetch typeguess "${url}"
}


#
# This function sets values of variables that should be declared
# in the caller!
#
#   # node_augmentline
#
#   local branch
#   local dstfile
#   local fetchoptions
#   local marks
#   local nodetype
#   local tag
#   local url
#   local userinfo
#   local uuid
#
node_augment()
{
   local mode="$1"

   if [ -z "${uuid}" ]
   then
      uuid="$(node_uuidgen)"
   fi

   if [ -z "${nodetype}" ]
   then
      case "${mode}" in
         *guesstype*)
            nodetype="`node_guess_nodetype "${url}"`"
         ;;
      esac

      nodetype="${nodetype:-git}"
   fi

   if [ "${nodetype}" = "git" -a -z "${branch}" ]
   then
      branch="master"
   fi

   if [ -z "${dstfile}" ]
   then
      case "${mode}" in
         *guessdst*)
            dstfile="`node_guess_dstfile "${url}" "${nodetype}"`"
         ;;
      esac

      dstfile="${dstfile:-${uuid}}"
   fi

   case "${mode}" in
      *nosafe*)
      ;;

      *)
         dstfile="`node_sanitized_dstfile "${dstfile}"`" || exit 1
      ;;
   esac

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" ]
   then
      log_trace2 "URL:          \"${url}\""
      log_trace2 "DST:          \"${dstfile}\""
      log_trace2 "BRANCH:       \"${branch}\""
      log_trace2 "TAG:          \"${tag}\""
      log_trace2 "NODETYPE:     \"${nodetype}\""
      log_trace2 "UUID:         \"${uuid}\""
      log_trace2 "MARKS:        \"${marks}\""
      log_trace2 "FETCHOPTIONS: \"${fetchoptions}\""
      log_trace2 "USERINFO:     \"${userinfo}\""
   fi

   # this is done  during auto already
   # case "${dstfile}" in
   #    ..*|~*|/*)
   #     fail "dstfile \"${dstfile}\" is invalid ($nodeline)"
   #    ;;
   # esac

   [ -z "${url}" ]      && internal_fail "url is empty"
   [ -z "${uuid}" ]     && internal_fail "uuid is empty"
   [ -z "${nodetype}" ] && internal_fail "dstfile is empty"
   [ -z "${dstfile}" ]  && internal_fail "dstfile is empty"

   :
}


nodemarks_key_check()
{
   [ -z "${DEFAULT_IFS}" ] && internal_fail "DEFAULT_IFS not set"

   case "${1}" in
      "")
         internal_fail "empty key"
      ;;

      no*)
      ;;

      *)
         #
         internal_fail "nodemarks key \"$1\" must start with \"no\""
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
      no*)
         _nodemarks_contain "${marks}" "${key}"
      ;;

      *)
         ! _nodemarks_contain "${marks}" "no${key}"
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

   nodemarks_remove "$1" "nobuild"
}

nodemarks_add_delete()
{
   log_entry "nodemarks_add_delete" "$@"

   nodemarks_remove "$1" "nodelete"
}

nodemarks_add_recurse()
{
   log_entry "nodemarks_add_recurse" "$@"

   nodemarks_remove "$1" "norecurse"
}

nodemarks_add_require()
{
   log_entry "nodemarks_add_require" "$@"

   nodemarks_remove "$1" "norequire"
}

nodemarks_add_set()
{
   log_entry "nodemarks_add_set" "$@"

   nodemarks_remove "$1" "noset"
}

nodemarks_add_share()
{
   log_entry "nodemarks_add_share" "$@"

   nodemarks_remove "$1" "noshare"
}

nodemarks_add_update()
{
   log_entry "nodemarks_add_update" "$@"

   nodemarks_remove "$1" "noupdate"
}


nodemarks_contain_build()
{
   log_entry "nodemarks_contain_build" "$@"

   ! _nodemarks_contain "$1" "nobuild"
}

nodemarks_contain_delete()
{
   log_entry "nodemarks_contain_delete" "$@"

   ! _nodemarks_contain "$1" "nodelete"
}

nodemarks_contain_recurse()
{
   log_entry "nodemarks_contain_recurse" "$@"

   ! _nodemarks_contain "$1" "norecurse"
}

nodemarks_contain_require()
{
   log_entry "nodemarks_contain_require" "$@"

   ! _nodemarks_contain "$1" "norequire"
}

nodemarks_contain_set()
{
   log_entry "nodemarks_contain_set" "$@"

   ! _nodemarks_contain "$1" "noset"
}

nodemarks_contain_share()
{
   log_entry "nodemarks_contain_share" "$@"

   ! _nodemarks_contain "$1" "noshare"
}

nodemarks_contain_update()
{
   log_entry "nodemarks_contain_update" "$@"

   ! _nodemarks_contain "$1" "noupdate"
}


nodemarks_remove_build()
{
   log_entry "nodemarks_remove_build" "$@"

   nodemarks_add "$1" "nobuild"
}

nodemarks_remove_delete()
{
   log_entry "nodemarks_remove_delete" "$@"

   nodemarks_add "$1" "nodelete"
}

nodemarks_remove_recurse()
{
   log_entry "nodemarks_remove_recurse" "$@"

   nodemarks_add "$1" "norecurse"
}

nodemarks_remove_require()
{
   log_entry "nodemarks_remove_require" "$@"

   nodemarks_add "$1" "norequire"
}

nodemarks_remove_set()
{
   log_entry "nodemarks_remove_set" "$@"

   nodemarks_add "$1" "noset"
}

nodemarks_remove_share()
{
   log_entry "nodemarks_remove_share" "$@"

   nodemarks_add "$1" "noshare"
}

nodemarks_remove_update()
{
   log_entry "nodemarks_remove_update" "$@"

   nodemarks_add "$1" "noupdate"
}


#
#
#
nodemarks_add_nobuild()
{
   log_entry "nodemarks_add_nobuild" "$@"

   nodemarks_add "$1" "nobuild"
}


nodemarks_add_nodelete()
{
   log_entry "nodemarks_add_nodelete" "$@"

   nodemarks_add "$1" "nodelete"
}

nodemarks_add_norecurse()
{
   log_entry "nodemarks_add_norecurse" "$@"

   nodemarks_add "$1" "norecurse"
}

nodemarks_add_norequire()
{
   log_entry "nodemarks_add_norequire" "$@"

   nodemarks_add "$1" "norequire"
}

nodemarks_add_noset()
{
   log_entry "nodemarks_add_noset" "$@"

   nodemarks_add "$1" "noset"
}

nodemarks_add_noshare()
{
   log_entry "nodemarks_add_noshare" "$@"

   nodemarks_add "$1" "noshare"
}

nodemarks_add_noupdate()
{
   log_entry "nodemarks_add_noupdate" "$@"

   nodemarks_add "$1" "noupdate"
}


nodemarks_contain_nobuild()
{
   log_entry "nodemarks_contain_nobuild" "$@"

   _nodemarks_contain "$1" "nobuild"
}

nodemarks_contain_nodelete()
{
   log_entry "nodemarks_contain_nodelete" "$@"

   _nodemarks_contain "$1" "nodelete"
}

nodemarks_contain_norecurse()
{
   log_entry "nodemarks_contain_norecurse" "$@"

   _nodemarks_contain "$1" "norecurse"
}

nodemarks_contain_norequire()
{
   log_entry "nodemarks_contain_norequire" "$@"

   _nodemarks_contain "$1" "norequire"
}

nodemarks_contain_noset()
{
   log_entry "nodemarks_contain_noset" "$@"

   _nodemarks_contain "$1" "noset"
}

nodemarks_contain_noshare()
{
   log_entry "nodemarks_contain_noshare" "$@"

   _nodemarks_contain "$1" "noshare"
}

nodemarks_contain_noupdate()
{
   log_entry "nodemarks_contain_noupdate" "$@"

   _nodemarks_contain "$1" "noupdate"
}


nodemarks_remove_nobuild()
{
   log_entry "nodemarks_remove_nobuild" "$@"

   nodemarks_remove "$1" "nobuild"
}

nodemarks_remove_nodelete()
{
   log_entry "nodemarks_remove_nodelete" "$@"

   nodemarks_remove "$1" "nodelete"
}

nodemarks_remove_norecurse()
{
   log_entry "nodemarks_remove_norecurse" "$@"

   nodemarks_remove "$1" "norecurse"
}

nodemarks_remove_norequire()
{
   log_entry "nodemarks_remove_norequire" "$@"

   nodemarks_remove "$1" "norequire"
}

nodemarks_remove_noset()
{
   log_entry "nodemarks_remove_noset" "$@"

   nodemarks_remove "$1" "noset"
}

nodemarks_remove_noshare()
{
   log_entry "nodemarks_remove_noshare" "$@"

   nodemarks_remove "$1" "noshare"
}

nodemarks_remove_noupdate()
{
   log_entry "nodemarks_remove_noupdate" "$@"

   nodemarks_remove "$1" "noupdate"
}


node_sanitized_dstfile()
{
   log_entry "node_sanitized_dstfile" "$@"

   local dstfile="$1"

   local modified

   modified="`simplified_path "${dstfile}"`"
   if is_absolutepath "${modified}"
   then
      fail "Destination \"${dstfile}\" is an absolute filepath"
   fi

   case "${modified}" in
      ..|../*)
         fail "Destination \"${modified}\" tries to escape project"
      ;;
   esac

   if [ "${modified}" != "${dstfile}" ]
   then
      log_fluff "Destination \"${dstfile}\" sanitized to \"${modified}\""
   fi
   echo "${modified}"
}


node_print_nodeline()
{
   log_entry "node_print_nodeline" "$@"

   case "${url}" in
      *\;*)
         fail "url \"${url}\" contains semicolon"
      ;;

      "")
         internal_fail "url \"${url}\" is empty"
      ;;
   esac

   case "${dstfile}" in
      *\;*)
         fail "dstfile \"${dstfile}\" contains semicolon"
      ;;

      "")
         internal_fail "dstfile \"${dstfile}\" is empty"
      ;;
   esac

   case "${branch}" in
      *\;*)
         fail "branch \"${branch}\" contains semicolon"
      ;;
   esac

   case "${tag}" in
      *\;*)
         fail "tag \"${tag}\" contains semicolon"
      ;;
   esac

   case "${nodetype}" in
      *\;*)
         fail "nodetype \"${nodetype}\" contains semicolon"
      ;;
      *\,*)
         fail "nodetype \"${nodetype}\" contains comma"
      ;;
      "")
         internal_fail "nodetype is empty"
      ;;
   esac

   case "${uuid}" in
      *\;*)
         fail "uuid \"${uuid}\" contains semicolon"
      ;;
      "")
         internal_fail "uuid is empty"
      ;;
   esac

   case "${marks}" in
      *\;*)
         fail "marks \"${marks}\" contains semicolon"
      ;;

      ,*|*,,*|*,)
         fail "marks \"${marks}\" are ugly, remove excess commata"
      ;;
   esac

   case "${fetchoptions}" in
      *\;*)
         fail "fetchoptions \"${fetchoptions}\" contains semicolon"
      ;;

      ,*|*,,*|*,)
         fail "fetchoptions \"${fetchoptions}\" are ugly, remove excess commata"
      ;;
   esac

   case "${userinfo}" in
      *\;*)
         fail "userinfo \"${userinfo}\" contains semicolon"
      ;;
   esac

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" ]
   then
      log_trace2 "URL:          \"${url}\""
      log_trace2 "DST:          \"${dstfile}\""
      log_trace2 "BRANCH:       \"${branch}\""
      log_trace2 "TAG:          \"${tag}\""
      log_trace2 "NODETYPE:     \"${nodetype}\""
      log_trace2 "UUID:         \"${uuid}\""
      log_trace2 "MARKS:        \"${marks}\""
      log_trace2 "FETCHOPTIONS: \"${fetchoptions}\""
      log_trace2 "USERINFO:     \"${userinfo}\""
   fi

   # remove superflous trailing ;
   echo "${url};${dstfile};${branch};${tag};${nodetype};${uuid};${marks};\
${fetchoptions};${userinfo}" | sed 's/;$//g'
}


nodetype_intersect_nodetypes()
{
   log_entry "nodetype_intersect_nodetypes" "$@"

   local nodetype="$1"
   local nodetypes="$2"

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

