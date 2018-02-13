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
   set -o noglob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob
      if [ "$i" = "${key}" ]
      then
         echo "${marks}"
         return
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   comma_concat "${marks}" "${key}"
}


nodemarks_remove()
{
   local marks="$1"
   local key="$2"

   nodemarks_key_check "${key}"

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


_nodemarks_contain()
{
   local marks="$1"
   local key="$2"

   nodemarks_key_check "${key}"

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


#
# There are now more predefined marks than I ever expected
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

nodemarks_add_fs()
{
   log_entry "nodemarks_add_fs" "$@"

   nodemarks_remove "$1" "no-fs"
}

nodemarks_add_include()
{
   log_entry "nodemarks_add_include" "$@"

   nodemarks_remove "$1" "no-include"
}

nodemarks_add_link()
{
   log_entry "nodemarks_add_link" "$@"

   nodemarks_remove "$1" "no-link"
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

nodemarks_contain_fs()
{
   log_entry "nodemarks_contain_fs" "$@"

   ! _nodemarks_contain "$1" "no-fs"
}

nodemarks_contain_include()
{
   log_entry "nodemarks_contain_include" "$@"

   ! _nodemarks_contain "$1" "no-include"
}

nodemarks_contain_link()
{
   log_entry "nodemarks_contain_link" "$@"

   ! _nodemarks_contain "$1" "no-link"
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

nodemarks_remove_fs()
{
   log_entry "nodemarks_remove_fs" "$@"

   nodemarks_add "$1" "no-fs"
}

nodemarks_remove_include()
{
   log_entry "nodemarks_remove_include" "$@"

   nodemarks_add "$1" "no-include"
}

nodemarks_remove_link()
{
   log_entry "nodemarks_remove_link" "$@"

   nodemarks_add "$1" "no-link"
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

nodemarks_add_no_fs()
{
   log_entry "nodemarks_add_no_fs" "$@"

   nodemarks_add "$1" "no-fs"
}

nodemarks_add_no_include()
{
   log_entry "nodemarks_add_no_include" "$@"

   nodemarks_add "$1" "no-include"
}

nodemarks_add_no_link()
{
   log_entry "nodemarks_add_no_link" "$@"

   nodemarks_add "$1" "no-link"
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

nodemarks_contain_no_fs()
{
   log_entry "nodemarks_contain_no_fs" "$@"

   _nodemarks_contain "$1" "no-fs"
}

nodemarks_contain_no_include()
{
   log_entry "nodemarks_contain_no_include" "$@"

   _nodemarks_contain "$1" "no-include"
}

nodemarks_contain_no_link()
{
   log_entry "nodemarks_contain_no_link" "$@"

   _nodemarks_contain "$1" "no-link"
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

nodemarks_remove_no_fs()
{
   log_entry "nodemarks_remove_no_fs" "$@"

   nodemarks_remove "$1" "no-fs"
}

nodemarks_remove_no_include()
{
   log_entry "nodemarks_remove_no_include" "$@"

   nodemarks_remove "$1" "no-include"
}

nodemarks_remove_no_link()
{
   log_entry "nodemarks_remove_no_link" "$@"

   nodemarks_remove "$1" "no-link"
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

