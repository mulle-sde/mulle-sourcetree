# shellcheck shell=bash
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


sourcetree::nodemarks::_key_check()
{
   [ -z "${DEFAULT_IFS}" ] && _internal_fail "DEFAULT_IFS not set"

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
sourcetree::nodemarks::_r_add()
{
   local marks="$1"
   local key="$2"

   # avoid duplicates and reorg
   if ! sourcetree::nodemarks::_contain "${marks}" "${key}"
   then
      r_comma_concat "${marks}" "${key}"
   fi
}

#
# node marking
#
sourcetree::nodemarks::_r_find_prefix()
{
   local marks="$1"
   local prefix="$2"

   local i

   .foreachitem i in ${marks}
   .do
      case "${i}" in
         "${prefix}"*)
            RVAL="$i"
            return 0
         ;;
      esac
   .done

   RVAL=""
   return 1
}


sourcetree::nodemarks::_r_remove()
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
sourcetree::nodemarks::r_add()
{
   log_entry "sourcetree::nodemarks::r_add" "$@"

   local marks="$1"
   local key="$2"

   case "${key}" in
      "no-"*)
         sourcetree::nodemarks::_r_remove "${marks}" "only-${key:3}"
         sourcetree::nodemarks::_r_add "${RVAL}" "${key}"
      ;;

      "only-"*)
         sourcetree::nodemarks::_r_remove "${marks}" "no-${key:5}"
         sourcetree::nodemarks::_r_add "${RVAL}" "${key}"
      ;;

      "version-"*)
         # remove old version with same same prefix
         if sourcetree::nodemarks::_r_find_prefix "${marks}" "${key%-*}"
         then
            sourcetree::nodemarks::_r_remove "${marks}" "${RVAL}"
            marks="${RVAL}"
         fi
         sourcetree::nodemarks::_r_add "${marks}" "${key}"
      ;;

      *)
         sourcetree::nodemarks::_r_remove "${marks}" "no-${key}"
         sourcetree::nodemarks::_r_remove "${RVAL}" "only-${key}"
      ;;
   esac

   log_debug "marks: ${RVAL}"
}


sourcetree::nodemarks::r_remove()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      "no-"*|"only-"*|"version-"*)
         sourcetree::nodemarks::_r_remove "${marks}" "${key}"
      ;;

      *)
         sourcetree::nodemarks::_r_remove "${marks}" "only-${key}"
         sourcetree::nodemarks::_r_add    "${RVAL}"  "no-${key}"
      ;;
   esac
}


sourcetree::nodemarks::add()
{
   sourcetree::nodemarks::r_add "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"

   :
}


sourcetree::nodemarks::remove()
{
   sourcetree::nodemarks::r_remove "$@"

   [ ! -z "${RVAL}" ] && printf "%s\n" "${RVAL}"

   :
}

#
# check for existence of a no-key or an only-key
# case is a bit faster than IFS=, parsing but not much
#
sourcetree::nodemarks::_contain()
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
sourcetree::nodemarks::version_match()
{
   local marks="$1"
   local key="$2"
   local operator="$3"
   local value="$4"

   sourcetree::nodemarks::_key_check "${key}"

   local result
   local i
   local markvalue

   .foreachitem i in ${marks}
   .do
      case "$i" in
         "${key}"-*)
            if [ -z "${MULLE_VERSION_SH}" ]
            then
               . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-version.sh" || exit 1
            fi

            markvalue="${i#"${key}-"}"
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
                  _internal_fail "unknown operator \"${operator}\""
               ;;
            esac
      esac
   .done

   return 2  # no match found
}



#
# The "clever" existence check. (Not thaaaat clever though, use
# sourcetree::nodemarks::enable for that)
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
sourcetree::nodemarks::contain()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      "no-"*|"only-"*|"version-"*)
         sourcetree::nodemarks::_contain "${marks}" "${key}"
      ;;

      *)
         ! sourcetree::nodemarks::_contain "${marks}" "no-${key}"
      ;;
   esac
}


# match can use wildcard *
sourcetree::nodemarks::match()
{
   local marks="$1"
   local pattern="$2"

   case "${pattern}" in
      "no-"*"*"*|"no-"*"["*"]"*|"only-"*"*"*|"only-"*"["*"]"*|"version-"*"*"*|"version-"*"["*"]"*)
         local rval

         rval=1
         pattern="${pattern//\*/*([^,])}"

         shell_is_extglob_enabled || _internal_fail "extglob must be enabled"

         if [ ${ZSH_VERSION+x} ]
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
         sourcetree::nodemarks::_contain "${marks}" "${pattern}"
      ;;

      *)
         ! sourcetree::nodemarks::_contain "${marks}" "no-${pattern}"
      ;;
   esac
}


sourcetree::nodemarks::enable()
{
   local marks="$1"
   local key="$2"

   case "${key}" in
      'only-'*|'no-'*)
         _internal_fail "key must not start with only or no"
      ;;
   esac

   # if key is enabled with only- like only-platform-linux it's cool
   if sourcetree::nodemarks::_contain "${marks}" "only-${key}"
   then
      return 0
   fi

   # a no key disables
   if sourcetree::nodemarks::_contain "${marks}" "no-${key}"
   then
      return 1
   fi

   # for platform-linux cut of last -linux and see if only-platform-* matches anything
   # if yes we disable
   ! sourcetree::nodemarks::match "${marks}" "only-${key%-*}-*"
}


sourcetree::nodemarks::disable()
{
   ! sourcetree::nodemarks::enable "$@"
}


sourcetree::nodemarks::compatible_with_nodemarks()
{
   local marks="$1"
   local anymarks="$2"

   local key

   .foreachitem key in ${anymarks}
   .do
      case "${key}" in
         no-*)
            key="${key:3}"
         ;;

         only-*)
            key="${key:5}"
         ;;

        version-*)
            .continue
         ;;
      esac

      if sourcetree::nodemarks::enable "${marks}" "${key}"
      then
         if sourcetree::nodemarks::disable "${anymarks}" "${key}"
         then
            return 1
         fi
      else
         if sourcetree::nodemarks::enable "${anymarks}" "${key}"
         then
            return 1
         fi
      fi
   .done

   return 0
}


# this is low level
sourcetree::nodemarks::intersect()
{
   local marks="$1"
   local anymarks="$2"

   local key

   .foreachitem key in ${anymarks}
   .do
      if sourcetree::nodemarks::_contain "${marks}" "${key}"
      then
         return 0
      fi
   .done

   return 1
}


#
# remove marks that cancel each other out
#
sourcetree::nodemarks::r_simplify()
{
   local marks="$1"

   local result
   local key

   .foreachitem key in ${marks}
   .do
      sourcetree::nodemarks::r_add "${result}" "${key}"
      result="${RVAL}"
   .done

   RVAL="${result}"
}


sourcetree::nodemarks::sort()
{
   local marks="$1"

   local i
   local result

   .foreachline i in `tr ',' '\n' <<< "${marks}" | LC_ALL=C sort -u`
   .do
      r_comma_concat "${result}" "${i}"
      result="${RVAL}"
   .done

   RVAL="${result}"
}


#
# A small parser
#
sourcetree::nodemarks::do_filter_iexpr()
{
#   log_entry "sourcetree::nodemarks::do_filter_iexpr" "$1" "$2" "(_s=${_s})"

   local marks="$1"
   local expr=$2
   local error_hint="$3"

   _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
   case "${_s}" in
      AND*)
         _s="${_s:3}"
         sourcetree::nodemarks::do_filter_expr "${marks}" "${error_hint}"
         if [ $? -eq 1  ]
         then
            return 1
         fi
         return $expr
      ;;

      OR*)
         _s="${_s:2}"
         sourcetree::nodemarks::do_filter_expr "${marks}" "${error_hint}"
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


sourcetree::nodemarks::do_filter_sexpr()
{
#   log_entry "sourcetree::nodemarks::do_filter_sexpr" "$1" "(_s=${_s})"

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
         sourcetree::nodemarks::do_filter_expr "${marks}" "${error_hint}"
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
         sourcetree::nodemarks::do_filter_sexpr "${marks}" "${error_hint}"
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

         r_shell_indirect_expand "${key}"
         value="${RVAL}"

         [ ! -z "${value}" ]
         return $?
      ;;

      MATCHES*)
         _s="${_s:7}"
         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         key="${_s%%[[:space:])]*}"
         _s="${_s#"${key}"}"
         #log_entry sourcetree::nodemarks::match "${marks}" "${key}"
         sourcetree::nodemarks::match "${marks}" "${key}"
         return $?
      ;;

      # check if a key is enabled or disabled by marks (only- and no-)
      ENABLES*)
         _s="${_s:7}"
         _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
         key="${_s%%[[:space:])]*}"
         _s="${_s#"${key}"}"
         #log_entry sourcetree::nodemarks::match "${marks}" "${key}"
         sourcetree::nodemarks::enable "${marks}" "${key}"
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

         log_entry sourcetree::nodemarks::version_match "${marks}" "${key}"
         sourcetree::nodemarks::version_match "${marks}" "${key}" "${operator}" "${value}"
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
sourcetree::nodemarks::do_filter_expr()
{
#   log_entry "sourcetree::nodemarks::do_filter_expr" "$1" "(_s=${_s})"

   local marks="$1"
   local error_hint="$2"

   local expr

   sourcetree::nodemarks::do_filter_sexpr "${marks}" "${error_hint}"
   expr=$?

   while :
   do
      _s="${_s#"${_s%%[![:space:]]*}"}" # remove leading whitespace characters
      case "${_s}" in
         ")"*|"")
            break
         ;;
      esac
      sourcetree::nodemarks::do_filter_iexpr "${marks}" "${expr}" "${error_hint}"
      expr=$?
   done

   return $expr
}


sourcetree::nodemarks::filter_with_qualifier()
{
#   log_entry "sourcetree::nodemarks::filter_with_qualifier" "$@"

   local marks="$1"
   local qualifier="$2"

   if [ -z "${qualifier}" -o "${qualifier}" = "ANY" ]
   then
      log_debug "ANY matches all"
      return 0
   fi

   local _closer
   local _s

   _s="${qualifier}"

   sourcetree::nodemarks::do_filter_expr "${marks}" "${qualifier}"
}


sourcetree::nodemarks::walk()
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


sourcetree::nodemarks::is_sane_nodemark()
{
#   log_entry "sourcetree::nodemarks::is_sane_nodemark" "$@"

   case "$1" in
      "")
         return 2
      ;;

      *[^a-z0-9._-]*)
         return 1
      ;;
   esac
}


sourcetree::nodemarks::assert_sane_nodemark()
{
#   log_entry "sourcetree::nodemarks::assert_sane_nodemark" "$@"

   if ! sourcetree::nodemarks::is_sane_nodemark "$1"
   then
      fail "mark \"$1\" must not contain characters other than a-z 0-9 . - _ \
and not be empty"
   fi
}


sourcetree::nodemarks::assert_sane()
{
   log_entry "sourcetree::nodemarks::assert_sane" "$@"

   local marks="$1"

   local mark

   IFS=","; shell_disable_glob
   for mark in ${marks}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      [ -z "${mark}" ] && continue

      sourcetree::nodemarks::assert_sane_nodemark "${mark}"
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob
}


#
# this checks combinations of nodemarks against each other and their possible
# lacking. In theory these consistency checkers should be added via plugins
# for now we have a small collection of hardcoded functions
#

sourcetree::nodemarks::framework_consistency_check()
{
   log_entry "sourcetree::nodemarks::framework_consistency_check" "$@"

   local marks="$1"
   local mark="$2"
   local address="$3"

   if sourcetree::nodemarks::disable "${marks}" singlephase
   then
      log_warning "Framework \"${address}\" needs singlephase mark (singlephase)"
   fi

   if sourcetree::nodemarks::enable "${marks}" cmake-inherit
   then
      log_warning "Framework \"${address}\" should not inherit dependencies (no-cmake-inherit)"
   fi

#   if sourcetree::nodemarks::enable "${marks}" cmake-add
#   then
#      log_info "Framework \"${address}\" implicitly defines cmake-add, which generates superflous cmake code. (Use no-cmake-add)"
#   fi
}

sourcetree::nodemarks::no_cmake_inherit_consistency_check()
{
   log_entry "sourcetree::nodemarks::no_cmake_inherit_consistency_check" "$@"

   local marks="$1"
   local mark="$2"
   local address="$3"

   if sourcetree::nodemarks::disable "${marks}" cmake-searchpath
   then
      log_warning "\"${address}\": mark (no-cmake-searchpath) is made superflous by no-cmake-inherit"
   fi

   if sourcetree::nodemarks::disable "${marks}" cmake-dependency
   then
      log_warning "\"${address}\": mark (no-cmake-dependency) is made superflous by no-cmake-inherit"
   fi

   if sourcetree::nodemarks::disable "${marks}" cmake-loader
   then
      log_warning "\"${address}\": mark (no-cmake-loader) is made superflous by no-cmake-inherit"
   fi
}


sourcetree::nodemarks::check_consistency()
{
   log_entry "sourcetree::nodemarks::check_consistency" "$@"

   local marks="$1"
   local address="$2"

   local f

   IFS=","; shell_disable_glob
   for mark in ${marks}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      [ -z "${mark}" ] && continue

      f="sourcetree::nodemarks::${mark//-/_}_consistency_check"
      if shell_is_function "${f}"
      then
         ${f} "${marks}" "${mark}" "${address}"
      fi
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob
} 


sourcetree::nodemarks::r_diff()
{
   log_entry "sourcetree::nodemarks::r_diff" "$@"

   local nodemarks1="$1"
   local nodemarks2="$2"

   local matched
   local mark
   local differences


   IFS=","; shell_disable_glob
   for mark in ${nodemarks1}
   do
      if sourcetree::nodemarks::contain "${nodemarks2}" "${mark}"
      then
         r_comma_concat "${matched}" "${mark}"
         matched="${RVAL}"
         continue
      fi

      r_comma_concat "${differences}" "+${mark}"
      differences="${RVAL}"
   done

   for mark in ${nodemarks2}
   do
      if sourcetree::nodemarks::contain "${matched}" "${mark}"
      then
         continue
      fi

      r_comma_concat "${differences}" "-${mark}"
      differences="${RVAL}"
   done
   IFS="${DEFAULT_IFS}" ; shell_enable_glob

   RVAL="${differences}"
}
