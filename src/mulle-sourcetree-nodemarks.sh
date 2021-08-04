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

      *[^a-z0-9._-]*)
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

   # avoid duplicates and reorg
   if ! _nodemarks_contain "${marks}" "${key}"
   then
      r_comma_concat "${marks}" "${key}"
   fi
}

#
# node marking
#
_r_nodemarks_find_prefix()
{
   local marks="$1"
   local prefix="$2"

   local i

   shell_disable_glob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob
      case "${i}" in
         "${prefix}"*)
            RVAL="$i"
            return
         ;;
      esac
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   RVAL=""
   return 1
}


_r_nodemarks_remove()
{
   local marks="$1"
   local key="$2"

   RVAL=",${marks},"
   RVAL=${RVAL//,${key},/,}
   RVAL=${RVAL##,}
   RVAL=${RVAL%%,}
}


#
# node marking.
#
# If you add a no- mark or only- mark. That's OK
# Otherwise you are actually removing a no- or only- mark!
#
r_nodemarks_add()
{
   log_entry "r_nodemarks_add" "$@"

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
         _r_nodemarks_add "${marks}" "${key}"
      ;;

      *)
         _r_nodemarks_remove "${marks}" "no-${key}"
         _r_nodemarks_remove "${RVAL}" "only-${key}"
      ;;
   esac

   log_debug "marks: ${RVAL}"
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

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"

   :
}


nodemarks_remove()
{
   r_nodemarks_remove "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"

   :
}

#
# check for existence of a no-key or an only-key
# case is a bit faster than IFS=, parsing but not much
#
_nodemarks_contain()
{
#   local marks="$1"
#   local key="$2"

   case ",${1}," in
      *",${2},"*)
         return 0
      ;;
   esac

   return 1
}


#
# check for version of
#
# like "version-min-darwin-0.12.0"
# like "version-max-darwin-0.16.0"
#
# 0 yes
# 1 no
# 2 no mark found
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

   shell_disable_glob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      case "$i" in
         "${key}"-*)
            if [ -z "${MULLE_VERSION_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-version.sh" || exit 1
            fi

            markvalue="${i#${key}-}"
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
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   return 2  # no match found
}



#
# The "clever" existence check. (Not thaaaat clever though, use
# nodemarks_enable for that)
#
# Input         | Matches
#               | absent   | no-<key> | only-<key>
# --------------|----------|----------|-----------
# <key>         | YES      | NO       | YES
# no-<key>      | NO       | YES      | NO
# only-<key>    | NO       | NO       | YES
#
# Note: The only-<key> needs to be queried explicitly for existence
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

   case "${pattern}" in
      "no-"*"*"*|"no-"*"["*"]"*|"only-"*"*"*|"only-"*"["*"]"*|"version-"*"*"*|"version-"*"["*"]"*)
         local rval

         rval=1
         pattern="${pattern//\*/*([^,])}"

         shell_is_extglob_enabled || internal_fail "extglob must be enabled"

         if [ ! -z "${ZSH_VERSION}" ]
         then
            case ",${marks}," in
               *\,${~pattern}\,*)
                  rval=0
               ;;
            esac
         else
            case ",${marks}," in
               *\,${pattern}\,*)
                  rval=0
               ;;
            esac
         fi
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


nodemarks_enable()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      'only-'*|'no-'*)
         internal_fail "key must not start with only or no"
      ;;
   esac

   # if key is enabled with only- like only-platform-linux it's cool
   if _nodemarks_contain "${marks}" "only-${key}"
   then
      return 0
   fi

   # a no key disables
   if _nodemarks_contain "${marks}" "no-${key}"
   then
      return 1
   fi

   # for platform-linux cut of last -linux and see if only-platform-* matches anything
   # if yes we disable
   ! nodemarks_match "${marks}" "only-${key%-*}-*"
}


nodemarks_disable()
{
   ! nodemarks_enable "$@"
}


nodemarks_compatible_with_nodemarks()
{
   local marks="$1"
   local anymarks="$2"

   local key

   shell_disable_glob ; IFS=","
   for key in ${anymarks}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob
      case "${key}" in
         no-*)
            key="${key:3}"
         ;;

         only-*)
            key="${key:5}"
         ;;

        version-*)
            continue
         ;;
      esac

      if nodemarks_enable "${marks}" "${key}"
      then
         if nodemarks_disable "${anymarks}" "${key}"
         then
            return 1
         fi
      else
         if nodemarks_enable "${anymarks}" "${key}"
         then
            return 1
         fi
      fi
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   return 0
}


# this is low level
nodemarks_intersect()
{
   local marks="$1"
   local anymarks="$2"

   local key

   shell_disable_glob ; IFS=","
   for key in ${anymarks}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob
      if _nodemarks_contain "${marks}" "${key}"
      then
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   return 1
}


#
# remove marks that cancel each other out
#
r_nodemarks_simplify()
{
   local marks="$1"

   local result
   local key

   shell_disable_glob ; IFS=","
   for key in ${marks}
   do
      r_nodemarks_add "${result}" "${key}"
      result="${RVAL}"
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   RVAL="${result}"
}


r_nodemarks_sort()
{
   local marks="$1"

   local result
   local i

   RVAL=
   IFS=$'\n'
   for i in `tr ',' '\n' <<< "${marks}" | LC_ALL=C sort -u`
   do
      r_comma_concat "${RVAL}" "${i}"
   done
   IFS="${DEFAULT_IFS}"
}


#
# A small parser
#
_nodemarks_filter_iexpr()
{
#   log_entry "_nodemarks_filter_iexpr" "$1" "$2" "(_s=${_s})"

   local marks="$1"
   local expr=$2
   local error_hint="$3"

   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${_s}" in
      AND*)
         _s="${_s:3}"
         _nodemarks_filter_expr "${marks}" "${error_hint}"
         if [ $? -eq 1  ]
         then
            return 1
         fi
         return $expr
      ;;

      OR*)
         _s="${_s:2}"
         _nodemarks_filter_expr "${marks}" "${error_hint}"
         if [ $? -eq 0  ]
         then
            return 0
         fi
         return $expr
      ;;

      ")")
         if [ "${expr}" = "" ]
         then
            fail "Missing expression after marks qualifier \"${error_hint}\""
         fi
         return $expr
      ;;

      "")
         if [ "${expr}" = "" ]
         then
            fail "Missing expression after marks qualifier \"${error_hint}\""
         fi
         return $expr
      ;;
   esac

   fail "Unexpected expression at ${_s} of marks qualifier \"${error_hint}\""
}


_nodemarks_filter_sexpr()
{
#   log_entry "_nodemarks_filter_sexpr" "$1" "(_s=${_s})"

   local marks="$1"
   local error_hint="$2"

   local expr
   local key
   local operator
   local value

   local memo

   memo="${_s}"

   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${_s}" in
      '('*)
         _s="${_s:1}"
         _nodemarks_filter_expr "${marks}" "${error_hint}"
         expr=$?

         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         if [ "${_closer}" != 'YES' ]
         then
            if [ "${_s:0:1}" != ")" ]
            then
               fail "Closing ) missing at \"${_s}\" of marks qualifier \"${error_hint}\""
            fi
            _s="${_s:1}"
         fi
         return $expr
      ;;

      NOT*)
         _s="${_s:3}"
         _nodemarks_filter_sexpr "${marks}" "${error_hint}"
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
         key="${_s%%[[:space:])]*}"
         _s="${_s#"${key}"}"

         if [ ! -z "${ZSH_VERSION}" ]
         then
            value="${(P)key}"
         else
            value="${!key}"
         fi
         [ ! -z "${value}" ]
         return $?
      ;;

      MATCHES*)
         _s="${_s:7}"
         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         key="${_s%%[[:space:])]*}"
         _s="${_s#"${key}"}"
         #log_entry nodemarks_match "${marks}" "${key}"
         nodemarks_match "${marks}" "${key}"
         return $?
      ;;

      # check if a key is enabled or disabled by marks (only- and no-)
      ENABLES*)
         _s="${_s:7}"
         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         key="${_s%%[[:space:])]*}"
         _s="${_s#"${key}"}"
         #log_entry nodemarks_match "${marks}" "${key}"
         nodemarks_enable "${marks}" "${key}"
         return $?
      ;;

      VERSION*)
         _s="${_s:7}"
         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         key="${_s%%[[:space:])]*}"
         [ -z "${key}" ] && fail "Missing version key after VERSION"
         _s="${_s#"${key}"}"

         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         operator="${_s%%[[:space:])]*}"
         [ -z "${operator}" ] && fail "Missing operator after version key"
         _s="${_s#"${operator}"}"

         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         value="${_s%%[[:space:])]*}"
         [ -z "${value}" ] && fail "Missing version value after operator"
         _s="${_s#"${value}"}"

         log_entry nodemarks_version_match "${marks}" "${key}"
         nodemarks_version_match "${marks}" "${key}" "${operator}" "${value}"
         [ $? -ne 1 ]  # 0 ok, 2 also ok
         return $?
      ;;

      "")
         fail "Missing expression after marks qualifier \"${error_hint}\""
      ;;
   esac

   fail "Unknown command at \"${_s}\" of marks qualifier \"${error_hint}\""
}


#
# local _s
#
# _s contains the currently parsed qualifier
#
_nodemarks_filter_expr()
{
#   log_entry "_nodemarks_filter_expr" "$1" "(_s=${_s})"

   local marks="$1"
   local error_hint="$2"

   local expr

   _nodemarks_filter_sexpr "${marks}" "${error_hint}"
   expr=$?

   while :
   do
      _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
      case "${_s}" in
         ")"*|"")
            break
         ;;
      esac
      _nodemarks_filter_iexpr "${marks}" "${expr}" "${error_hint}"
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

   shell_disable_glob ; IFS=","
   for i in ${marks}
   do
      IFS="${DEFAULT_IFS}" ; shell_enable_glob

      "${callback}" "${i}" "$@"
      rval=$?

      if [ $rval -ne 0 ]
      then
         break
      fi
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   return $rval
}


is_sane_nodemark()
{
#   log_entry "is_sane_nodemark" "$@"

   case "$1" in
      "")
         return 2
      ;;

      *[^a-z0-9._-]*)
         return 1
      ;;
   esac
}


assert_sane_nodemark()
{
#   log_entry "assert_sane_nodemark" "$@"

   if ! is_sane_nodemark "$1"
   then
      fail "mark \"$1\" must not contain characters other than a-z 0-9 . - _ \
and not be empty"
   fi
}


assert_sane_nodemarks()
{
   log_entry "assert_sane_nodemarks" "$@"

   local marks="$1"

   local mark

   IFS=","; shell_disable_glob
   for mark in ${marks}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      [ -z "${mark}" ] && continue

      assert_sane_nodemark "${mark}"
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob
}


#
# this checks combinations of nodemarks against each other and their possible
# lacking. In theory these consistency checkers should be added via plugins
# for now we have a small collection of hardcoded functions
#

nodemark_only_framework_consistency_check()
{
   local mark="$1"
   local marks="$2"
   local address="$3"

   if nodemarks_disable "${marks}" singlephase
   then
      log_warning "Framework \"${address}\" needs singlephase mark (singlephase)"
   fi

   if nodemarks_enable "${marks}" cmake-inherit
   then
      log_warning "Framework \"${address}\" should not inherit dependencies (no-cmake-inherit)"
   fi

   if nodemarks_enable "${marks}" cmake-add
   then
      log_info "Framework \"${address}\" doesn't need cmake-add. (Use no-cmake-add to make reflected files prettier)"
   fi
}

nodemark_no_cmake_inherit_consistency_check()
{
   local mark="$1"
   local marks="$2"
   local address="$3"

   if nodemarks_disable "${marks}" cmake-searchpath
   then
      log_warning "\"${address}\" mark (no-cmake-searchpath) is made superflous by no-cmake-inherit"
   fi

   if nodemarks_disable "${marks}" cmake-dependency
   then
      log_warning "\"${address}\" mark (no-cmake-dependency) is made superflous by no-cmake-inherit"
   fi

   if nodemarks_disable "${marks}" cmake-loader
   then
      log_warning "\"${address}\" mark (no-cmake-loader) is made superflous by no-cmake-inherit"
   fi
}


nodemarks_check_consistency()
{
   log_entry "nodemarks_check_consistency" "$@"

   local marks="$1"
   local address="$2"

   local f

   IFS=","; shell_disable_glob
   for mark in ${marks}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      [ -z "${mark}" ] && continue

      f="nodemark_${mark//-/_}_consistency_check"
      if shell_is_function "${f}"
      then
         ${f} "${mark}" "${marks}" "${address}"
      fi
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob
} 

