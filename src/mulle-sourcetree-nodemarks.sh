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
MULLE_SOURCETREE_NODEMARKS_SH="included"


_nodemarks_key_check()
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
_nodemarks_add()
{
   local marks="$1"
   local key="$2"

   _nodemarks_key_check "${key}"

   local i

   # is this faster than case ?
   set -o noglob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob
      if [ "$i" = "${key}" ]
      then
         echo "${marks}"   # already set
         return
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   comma_concat "${marks}" "${key}"
}


_nodemarks_remove()
{
   local marks="$1"
   local key="$2"

   _nodemarks_key_check "${key}"

   local result
   local i

   set -o noglob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      if [ "${i}" != "${key}" ]
      then
         result="`comma_concat "${result}" "${i}"`"
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   echo "${result}"
}


#
# node marking.
#
# If you add a no- mark or only- mark. That's OK
# Otherwise you are actually removing a no- or only- mark!
#
nodemarks_add()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      no-*)
         marks="`_nodemarks_remove "${marks}" "only-${key:3}"`"
         _nodemarks_add "${marks}" "${key}"
      ;;

      only-*)
         marks="`_nodemarks_remove "${marks}" "no-${key:5}"`"
         _nodemarks_add "${marks}" "${key}"
      ;;

      *)
         marks="`_nodemarks_remove "${marks}" "no-${key}"`"
         _nodemarks_remove "${marks}" "only-${key}"
      ;;
   esac
}


nodemarks_remove()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      no-*|only-*)
         _nodemarks_remove "${marks}" "${key}"
      ;;

      *)
         marks="`_nodemarks_remove "${marks}" "only-${key}"`"
         _nodemarks_add "${marks}" "no-${key}"
      ;;
   esac
}


_nodemarks_contain()
{
   local marks="$1"
   local key="$2"

   _nodemarks_key_check "${key}"

   local i

   # is this faster than case ?
   set -o noglob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob
      if [ "${i}" = "${key}" ]
      then
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

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

   set -o noglob ; IFS=","
   for key in ${anymarks}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob
      if nodemarks_contain "${marks}" "${key}"
      then
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   return 1
}


nodemarks_sort()
{
   local marks="$1"

   local result
   local i

   IFS="
"
   for i in `tr ',' '\n' <<< "${marks}" | sort -u`
   do
      result="`comma_concat "${result}" "${i}"`"
   done
   IFS="${DEFAULT_IFS}"

   echo "${result}"
}
