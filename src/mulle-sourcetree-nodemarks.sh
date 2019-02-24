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
         fail "Empty node mark"
      ;;

      *[^a-z-_0-9.]*)
         fail "Node mark \"$1\" contains invalid characters"
      ;;

      no-*|only-*|version-*)
      ;;

      *)
         fail "Node mark \"$1\" must start with \"version-\" \"no-\" or \"only-\""
      ;;
   esac
}


#
# node marking
#
_r_nodemarks_add()
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
         RVAL="${marks}"   # already set
         return
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   r_comma_concat "${marks}" "${key}"
}

#
# node marking
#
_r_nodemarks_find_prefix()
{
   local marks="$1"
   local prefix="$2"

   _nodemarks_key_check "${prefix}"

   local i

   set -o noglob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob
      case "${i}" in
         "${prefix}"*)
            RVAL="$i"
            return
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   RVAL=""
   return 1
}



_r_nodemarks_remove()
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
         r_comma_concat "${result}" "${i}"
         result="${RVAL}"
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   RVAL="${result}"
}


#
# node marking.
#
# If you add a no- mark or only- mark. That's OK
# Otherwise you are actually removing a no- or only- mark!
#
r_nodemarks_add()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      "no-"*)
         _r_nodemarks_remove "${marks}" "only-${key:3}"
         _r_nodemarks_add "${RVAL}" "${key}"
      ;;

      "only-"*)
         _r_nodemarks_remove "${marks}" "no-${key:5}"
         _r_nodemarks_add "${RVAL}" "${key}"
      ;;

      "version-"*)
         # remove old version with same same prefix
         if _r_nodemarks_find_prefix "${marks}" "${key%-*}"
         then
            _r_nodemarks_remove "${marks}" "${RVAL}"
            marks="${RVAL}"
         fi
         _r_nodemarks_add "${RVAL}" "${key}"
      ;;

      *)
         _r_nodemarks_remove "${marks}" "no-${key}"
         _r_nodemarks_remove "${RVAL}" "only-${key}"
      ;;
   esac
}


r_nodemarks_remove()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      "no-"*|"only-"*|"version-"*)
         _r_nodemarks_remove "${marks}" "${key}"
      ;;

      *)
         _r_nodemarks_remove "${marks}" "only-${key}"
         _r_nodemarks_add "${RVAL}" "no-${key}"
      ;;
   esac
}


nodemarks_add()
{
   r_nodemarks_add "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"

   :
}


nodemarks_remove()
{
   r_nodemarks_remove "$@"

   [ ! -z "${RVAL}" ] && echo "${RVAL}"

   :
}

#
# check for existance of a no-key or an only-key
#
_nodemarks_contain()
{
   local marks="$1"
   local key="$2"

   _nodemarks_key_check "${key}"

   # this is a bit faster than IFS=, parsing but not much
   case ",${marks}," in
      *",${key},"*)
         return 0
      ;;
   esac

   return 1
}


#
# check for version of
#
# like "version-darwin-min-0.12.0"
# like "version-darwin-max-0.16.0"
#
nodemarks_version_match()
{
   local marks="$1"
   local key="$2"
   local operator="$3"
   local value="$4"

   _nodemarks_key_check "${key}"

   local result
   local i
   local markvalue
   set -o noglob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      case "$i" in
         "${key}"-*)
            markvalue="${i##*-}"
            r_version_distance "${value}" "${markvalue}"
            case "${operator}" in
               ""|"="|"==")
                  [ "$RVAL" -eq 0 ]
                  return $?
               ;;

               "<>"|"!=")
                  [ "$RVAL" -ne 0 ]
                  return $?
               ;;

               ">")
                  [ "$RVAL" -gt 0 ]
                  return $?
               ;;

               "<")
                  [ "$RVAL" -lt 0 ]
                  return $?
               ;;

               "<=")
                  [ "$RVAL" -le 0 ]
                  return $?
               ;;

               ">=")
                  [ "$RVAL" -ge 0 ]
                  return $?
               ;;

               *)
                  internal_fail "unknown operator \"${operator}\""
               ;;
            esac
      esac
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   return 0
}



#
# The "clever" existance check:
#
# Input         | Matches
#               | absent   | no-<key> | only-<key>
# --------------|----------|----------|-----------
# <key>         | YES      | NO       | YES
# no-<key>      | NO       | YES      | NO
# only-<key>    | NO       | NO       | YES
#
# Note: The only-<key> needs to be queried explicitly for existance
#       It will not deny a no-<key>.In fact there must not be a
#       no-<key> present if there is a only-<key>
#
# The version keys are ignored
#
nodemarks_contain()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      "no-"*|"only-"*|"version-"*)
         _nodemarks_contain "${marks}" "${key}"
      ;;

      *)
         ! _nodemarks_contain "${marks}" "no-${key}"
      ;;
   esac
}


# match can use wildcard *
nodemarks_match()
{
   local marks="$1"
   local pattern="$2"

   local cmd
   local rval

   case "${pattern}" in
      "no-"*"*"*|"no-"*"["*"]"*|"only-"*"*"*|"only-"*"["*"]"*|"version-"*"*"*|"version-"*"["*"]"*)
         cmd="u"
         if shopt -q extglob
         then
            cmd="s"
         fi

         rval=1
         pattern="`LC_ALL=C sed -e 's/\*/*([^,])/g' <<< "${pattern}"`"

         shopt -s extglob
         case ",${marks}," in
            *","${pattern}","*)
               rval=0
            ;;
         esac
         shopt -${cmd} extglob
         return $rval
      ;;

      "no-"*|"only-"*|"version-"*)
         _nodemarks_contain "${marks}" "${pattern}"
      ;;

      *)
         ! _nodemarks_contain "${marks}" "no-${pattern}"
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


r_nodemarks_sort()
{
   local marks="$1"

   local result
   local i

   IFS=$'\n'
   for i in `tr ',' '\n' <<< "${marks}" | LC_ALL=C sort -u`
   do
      r_comma_concat "${result}" "${i}"
      result="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"

   RVAL="${result}"
}


#
# A small parser
#
_nodemarks_filter_iexpr()
{
#  log_entry "_nodemarks_filter_iexpr" "${marks}" "${_s}" "${expr}"

   local marks="$1"
   local qualifier="$2"
   local expr=$3

   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${_s}" in
      AND*)
         _s="${_s:3}"
         _nodemarks_filter_expr "${marks}" "${qualifier}"
         if [ $? -eq 1  ]
         then
            return 1
         fi
         return $expr
      ;;

      OR*)
         _s="${_s:2}"
         _nodemarks_filter_expr "${marks}" "${qualifier}"
         if [ $? -eq 0  ]
         then
            return 0
         fi
         return $expr
      ;;

      ")")
         if [ "${expr}" = "" ]
         then
            fail "Missing expression after marks qualifier \"${qualifier}\""
         fi
         return $expr
      ;;

      "")
         if [ "${expr}" = "" ]
         then
            fail "Missing expression after marks qualifier \"${qualifier}\""
         fi
         return $expr
      ;;
   esac

   fail "Unexpected expression at ${_s} of marks qualifier \"${qualifier}\""
}


_nodemarks_filter_sexpr()
{
#   log_entry "_nodemarks_filter_sexpr" "${marks}" "${_s}"

   local marks="$1"
   local qualifier="$2"

   local expr
   local key
   local operator
   local value

   local memo

   memo="${_s}"

   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${_s}" in
      "("*)
         _s="${_s:1}"
         _nodemarks_filter_expr "${marks}" "${qualifier}"
         expr=$?

         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         if [ "${_closer}" != 'YES' ]
         then
            if [ "${_s:0:1}" != ")" ]
            then
               fail "Closing ) missing at \"${_s}\" of marks qualifier \"${qualifier}\""
            fi
            _s="${_s:1}"
         fi
         return $expr
      ;;

      NOT*)
         _s="${_s:3}"
         _nodemarks_filter_sexpr "${marks}" "${qualifier}"
         if [ $? -eq 0  ]
         then
            return 1
         fi
         return 0
      ;;

      # experimental and untested
      IFDEF*)
         _s="${_s:5}"
         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         key="${_s%%[ )]*}"
         _s="${_s#"${key}"}"
         value="`eval echo \$\{__DEFINE__${key}\}`"
         [ ! -z "${value}" ]
         return $?
      ;;

      MATCHES*)
         _s="${_s:7}"
         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         key="${_s%%[ )]*}"
         _s="${_s#"${key}"}"
         log_entry nodemarks_match "${marks}" "${key}"
         nodemarks_match "${marks}" "${key}"
         return $?
      ;;

      VERSION*)
         _s="${_s:7}"
         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         key="${_s%%[ )]*}"
         [ -z "${key}" ] && fail "Missing version key after VERSION"
         _s="${_s#"${key}"}"

         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         operator="${_s%%[ )]*}"
         [ -z "${operator}" ] && fail "Missing operator after version key"
         _s="${_s#"${operator}"}"


         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         value="${_s%%[ )]*}"
         [ -z "${value}" ] && fail "Missing version value after operator"
         _s="${_s#"${value}"}"

         log_entry nodemarks_version_match "${marks}" "${key}"
         nodemarks_version_match "${marks}" "${key}" "${operator}" "${value}"
         return $?
      ;;

      "")
         fail "Missing expression after marks qualifier \"${qualifier}\""
      ;;
   esac

   fail "Unknown command at \"${_s}\" of marks qualifier \"${qualifier}\""
}


_nodemarks_filter_expr()
{
#  log_entry "_nodemarks_filter_expr" "${marks}" "${_s}"

   local marks="$1"
   local qualifier="$2"

   local expr

   _nodemarks_filter_sexpr "${marks}" "${qualifier}"
   expr=$?

   while :
   do
      _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
      case "${_s}" in
         ")"*|"")
            break
         ;;
      esac
      _nodemarks_filter_iexpr "${marks}" "${qualifier}" "${expr}"
      expr=$?
   done
   return $expr
}


nodemarks_filter_with_qualifier()
{
   log_entry "nodemarks_filter_with_qualifier" "$@"

   local marks="$1"
   local qualifier="$2"

   if [ -z "${qualifier}" -o "${qualifier}" = "ANY" ]
   then
      log_debug "ANY matches all"
      return 0
   fi

   local _s

   _s="${qualifier}"

   _nodemarks_filter_expr "${marks}" "${qualifier}"
}


nodemarks_walk()
{
   local marks="$1"; shift
   local callback="$1"; shift

   local i
   local rval=0

   set -o noglob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      "${callback}" "${i}" "$@"
      rval=$?

      if [ $rval -ne 0 ]
      then
         break
      fi
   done
   IFS="${DEFAULT_IFS}" ; set +o noglob

   return $rval
}

