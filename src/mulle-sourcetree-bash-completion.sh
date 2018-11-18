#! /usr/bin/env bash
#
#   Copyright (c) 2018 Nat! - Mulle kybernetiK
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
[ "${TRACE}" = 'YES' ] && set -x && : "$0" "$@"


_mulle_sourcetree_complete()
{
   local cur=${COMP_WORDS[COMP_CWORD]}
   local prev=${COMP_WORDS[COMP_CWORD-1]}

   local list
   local i
   local context
   local mulle_uname

   for i in "${COMP_WORDS[@]}"
   do
      case "$i" in
         add|buildorder|clean|dotdump|fix|get|info|list|\
mark|move|nameguess|remove|reset|set|status|typeguess|unmark|update|walk)
            context="$i"
         ;;
      esac
   done

   case "$prev" in
      get|set|mark|move|unmark)
         list="`mulle-sourcetree -s -e list --output-no-header --format "%a\\n"`"
         COMPREPLY=( $( compgen -W "${list}" -- "$cur" ) )
         return
      ;;
   esac

   local prevprev

   if [ ${COMP_CWORD} -gt 1 ]
   then
      prevprev=${COMP_WORDS[COMP_CWORD-2]}
   fi

   case "${prevprev}" in
      mark|unmark)
         mulle_uname="`mulle-sourcetree -s -e uname`"
         COMPREPLY=( $( compgen -W "no-all-load no-build no-defer no-delete no-fs \
no-header no-include no-link no-recurse no-require no-set no-share \
no-update no-${mulle_uname} only-${mulle_uname}" -- "$cur" ) )
      ;;

      move)
         COMPREPLY=( $( compgen -W "up down top bottom" -- "$cur" ) )
      ;;

      *)
         COMPREPLY=( $( compgen -W "add buildorder clean dotdump fix get info \
list mark move nameguess remove reset set status typeguess unmark update walk" -- "$cur" ) )
      ;;
   esac
}


complete -F _mulle_sourcetree_complete mulle-sourcetree

