# shellcheck shell=bash
#
#   Copyright (c) 2023 Nat! - Mulle kybernetiK
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
MULLE_SOURCETREE_SUPERMARKS_SH='included'


sourcetree::supermarks::usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} supermark [options] <command>

   A supermark is a combination of marks, basically a macro for marks.
   As an example the supermark 'Tool' decomposes to 'no-header,no-link'.
   supermarks are only used during input and output. The actual algorithms
   only deal with marks.

   List known supermarks and compose / decompose supermarks into marks.

   You can add to the list of supermarks with a mulle-sourcetree plugin.
   See the mulle-sde mulle-sde-supermarks.sh for reference.

Options:
   -h : help

Commands:
   list          : list known supermarks
   compose <s>   : try to compose a supermark from given marks
   decompose <s> : decompose supermark into marks

EOF
  exit 1
}


sourcetree::supermarks::list_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} supermark list [options]

   List known supermarks

Options:
   -h : help

EOF
  exit 1
}


sourcetree::supermarks::decompose_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} supermark decompose [options] <supermark> ...

   Decompose supermarks into marks

Options:
   -h : help

EOF
  exit 1
}


sourcetree::supermarks::compose_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} supermark compose [options] <mark> ...

   Compose supermarks from given marks

Options:
   -h : help

EOF
  exit 1
}


sourcetree::supermarks::r_supermarks_marks()
{
   local marks="$1"
   local other="$2"

   .foreachitem key in ${other}
   .do
      sourcetree::marks::_r_remove "${marks}" "only-${key}"
      sourcetree::marks::_r_remove "${RVAL}"  "no-${key}"
      marks="${RVAL}"
   .done
}


# yet another design blemish: here we know too much about mulle-sde
#
# local _type
#
sourcetree::supermarks::__r_supermarks()
{
   log_entry "sourcetree::supermarks::__r_supermarks" "$@"

   local remaining="$1"
   local marks="$2"

   # optionality applies to all so do it first
   if sourcetree::marks::disable "${remaining}" require
   then
      r_comma_concat "${_supermarks}" "Optional"
      _supermarks="${RVAL}"
   fi
   sourcetree::supermarks::r_supermarks_marks "${remaining}" require
   remaining="${RVAL}"


   if sourcetree::marks::disable "${remaining}" recurse
   then
      r_comma_concat "${_supermarks}" "TreeLeaf"
      _supermarks="${RVAL}"
   fi
   sourcetree::supermarks::r_supermarks_marks "${remaining}" recurse
   remaining="${RVAL}"

   if sourcetree::marks::disable "${remaining}" bequeath
   then
      r_comma_concat "${_supermarks}" "TreePrivate"
      _supermarks="${RVAL}"
   fi
   sourcetree::supermarks::r_supermarks_marks "${remaining}" bequeath
   remaining="${RVAL}"

   if sourcetree::marks::compatible_with_marks "${remaining}" \
         'no-fs,no-dependency,no-build,no-update,no-delete'
   then
      r_comma_concat "${_supermarks}" 'Library'
      _supermarks="${RVAL}"
      _type='LIBRARY'

      sourcetree::marks::r_clean_marks "${remaining}" \
                                       'fs,dependency,build,update,delete'
      remaining="${RVAL}"
   fi

   if sourcetree::marks::compatible_with_marks "${remaining}" \
         'fs,build,no-delete,no-share,no-update,no-header,no-link,no-readwrite'
   then
      r_comma_concat "${_supermarks}" 'Info'
      _supermarks="${RVAL}"
      sourcetree::supermarks::r_supermarks_marks "${remaining}" \
                                            'delete,header,link,share,update'
      remaining="${RVAL}"

      _type='EMBEDDED'
   fi

   # check if algamated, pretty much all the other flags are irrelevant
   # for display
   if sourcetree::marks::compatible_with_marks "${remaining}" \
         'fs,no-build,no-header,no-link,no-share,no-share-shirk,no-readwrite,no-clobber'
   then
      r_comma_concat "${_supermarks}" 'Amalgamated'
      _supermarks="${RVAL}"

      sourcetree::supermarks::r_supermarks_marks "${remaining}" \
                       'build,header,link,share,share-shirk,readwrite,clobber'
      remaining="${RVAL}"

      _type='EMBEDDED'
   fi

   # check if embedded, pretty much all the other flags are irrelevant
   # for display
   if sourcetree::marks::compatible_with_marks "${remaining}" \
         'fs,no-build,no-header,no-link,no-share'
   then
      r_comma_concat "${_supermarks}" 'Embedded'
      _supermarks="${RVAL}"

      sourcetree::supermarks::r_supermarks_marks "${remaining}" \
                                            'build,header,link,share'
      remaining="${RVAL}"

      _type='EMBEDDED'
   fi

   if [ "${_type}" != 'EMBEDDED' -a "${_type}" != 'LIBRARY' ]
   then
      if sourcetree::marks::compatible_with_marks "${remaining}" \
                                                      'fs,no-header,no-link'
      then
         r_comma_concat "${_supermarks}" 'Tool'
         _supermarks="${RVAL}"

         sourcetree::supermarks::r_supermarks_marks "${remaining}" \
                                               'header,link'
         remaining="${RVAL}"

         _type='TOOL'
      fi
   fi

   #
   # Subproject
   #
   if [ "${_type}" != 'EMBEDDED' -a "${_type}" != 'LIBRARY' ]
   then
      if sourcetree::marks::compatible_with_marks "${remaining}" \
            'fs,no-delete,no-mainproject,no-share,no-update'
      then
         r_comma_concat "${_supermarks}" 'Subproject'
         _supermarks="${RVAL}"
         sourcetree::supermarks::r_supermarks_marks "${remaining}" \
                                               'delete,share,update'
         remaining="${RVAL}"
         _type='SUBPROJECT'
      fi
   fi
   sourcetree::supermarks::r_supermarks_marks "${remaining}" 'mainproject'
   remaining="${RVAL}"

   # also some sort of subproject
   if [ "${_type}" != 'EMBEDDED' -a "${_type}" != 'LIBRARY' ]
   then
      if sourcetree::marks::compatible_with_marks "${remaining}" \
            'fs,no-delete,no-share,no-update'
      then
         r_comma_concat "${_supermarks}" 'Local'
         _supermarks="${RVAL}"
         sourcetree::supermarks::r_supermarks_marks "${remaining}" \
                                               'delete,share,update'
         remaining="${RVAL}"
         _type='SUBPROJECT'
      fi
   fi

   if sourcetree::marks::disable "${remaining}" readwrite
   then
      r_comma_concat "${_supermarks}" "WriteProtect"
      _supermarks="${RVAL}"
   fi
   sourcetree::supermarks::r_supermarks_marks "${remaining}" readwrite
   remaining="${RVAL}"

   RVAL="${remaining}"
}


sourcetree::supermarks::r_decompose_supermark()
{
   log_entry "sourcetree::supermarks::r_decompose_supermark" "$@"

   local supermark="$1"

   RVAL=
   case "${supermark}" in
      'Amalgamated')
         RVAL='no-build,no-clobber,no-header,no-link,no-readwrite,no-share,no-share-shirk'
         return 0
      ;;

      'Embedded')
         RVAL='no-build,no-header,no-link,no-share,no-readwrite'
         return 0
      ;;

      'Info')
         RVAL='build,no-delete,no-share,no-update,no-header,no-link'
         return 0
      ;;

      'Library')
         RVAL='no-fs,no-dependency,no-build,no-update,no-delete'
         return 0
      ;;

      'Local')
         RVAL='no-delete,no-public,no-share'
         return 0
      ;;

      'Optional')
         RVAL="no-require"
         return 0
      ;;

      'Subproject')
         RVAL='no-delete,no-mainproject,no-share,no-update'
         return 0
      ;;

      'Tool')
         RVAL='no-header,no-link'
         return 0
      ;;

      'TreeLeaf')
         RVAL='no-recurse'
         return 0
      ;;

      'TreePrivate')
         RVAL="no-bequeath"
         return 0
      ;;

      'WriteProtect')
         RVAL="no-readwrite"
         return 0
      ;;
   esac

   return 1
}


supermarks_detectors=( sourcetree::supermarks::__r_supermarks)
supermarks_list=( 'Amalgamated' 'Embedded' 'Info' 'Library' 'Local' 'Optional' 'Subproject' \
'Tool' 'TreeLeaf' 'TreePrivate' 'WriteProtect')
supermarks_decomposers=( sourcetree::supermarks::r_decompose_supermark )


sourcetree::supermarks::add_supermarks()
{
   log_entry "sourcetree::supermarks::add_supermarks" "$@"

   supermarks_list+=( "$@")
}


sourcetree::supermarks::add_detectors()
{
   log_entry "sourcetree::supermarks::add_detectors" "$@"

   supermarks_detectors+=( "$@")
}


sourcetree::supermarks::add_decomposers()
{
   log_entry "sourcetree::supermarks::add_decomposers" "$@"

   supermarks_decomposers+=( "$@")
}



sourcetree::supermarks::r_compose()
{
   log_entry "sourcetree::supermarks::r_compose" "$@"

   local marks="$1"

   local remaining
   local detector

   local _type

   _type='UNKNOWN'
   _supermarks=
   remaining="${marks}"

   .for detector in "${supermarks_detectors[@]}"
   .do
      ${detector} "${remaining}" "${marks}"
      remaining="${RVAL}"
   .done

   local marks

   sourcetree::marks::r_sort "${_supermarks}"
   marks="${RVAL}"

   sourcetree::marks::r_simplify "${remaining}"
   r_comma_concat "${marks}" "${RVAL}"
}



sourcetree::supermarks::r_decompose()
{
   log_entry "sourcetree::supermarks::r_decompose" "$@"

   local supermarks="$1"
   local keepunknowns="${2:-YES}"

   local marks
   local decomposer
   local supermark
   local found

   .foreachitem supermark in ${supermarks}
   .do
      found='NO'
      .for decomposer in "${supermarks_decomposers[@]}"
      .do
         if ${decomposer} "${supermark}"
         then
            log_debug "decomposed \"${supermark}\" into \"${RVAL}\""
            r_comma_concat "${marks}" "${RVAL}"
            marks="${RVAL}"
            found='YES'
            .break
         fi
      .done

      if [ "${found}" != 'YES' -a "${keepunknowns}" = 'YES' ]
      then
         r_comma_concat "${marks}" "${supermark}"
         marks="${RVAL}"
      fi
   .done

   RVAL="${marks}"
}



sourcetree::supermarks::list_main()
{
   local i

   (
      for i in "${supermarks_list[@]}"
      do
         printf "%s\n" "${i}"
      done
   ) | sort
}



sourcetree::supermarks::compose_main()
{
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::supermarks::compose_usage
         ;;

         -*)
            sourcetree::supermarks::compose_usage "Unknown compose option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local marks
   local i

   [ $# -eq 0 ] && sourcetree::supermarks::compose_usage "Missing supermarks"

   for i in "$@"
   do
      r_comma_concat "${marks}" "${i}"
      marks="${RVAL}"
   done

   r_remove_duplicate_separators "${marks}" ","
   marks="${RVAL}"

   sourcetree::supermarks::r_compose "${marks}"
   printf "%s\n" "${RVAL}"
}


sourcetree::supermarks::decompose_main()
{
   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::supermarks::decompose_usage
         ;;

         -*)
            sourcetree::supermarks::decompose_usage "Unknown decompose option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local marks
   local i

   [ $# -eq 0 ] && sourcetree::supermarks::decompose_usage "Missing supermarks"

   for i in "$@"
   do
      if ! sourcetree::supermarks::r_decompose "${i}"
      then
         fail "unknown supermark \"$i\""
      fi

      r_comma_concat "${marks}" "${RVAL}"
      marks="${RVAL}"
   done

# not good, loses "build" from "Info" for example
#   sourcetree::marks::r_simplify "${marks}"
   sourcetree::marks::r_sort "${marks}"

   printf "%s\n" "${RVAL}"
}



sourcetree::supermarks::main()
{
   log_entry "sourcetree::supermarks::main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::supermarks::usage
         ;;

         -*)
            sourcetree::supermarks::usage "Unknown supermarks option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   local cmd="${1:-list}"

   [ $# -ne 0 ] && shift

   case "${cmd}" in
      'compose')
         sourcetree::supermarks::compose_main "$@"
      ;;

      'decompose')
         sourcetree::supermarks::decompose_main "$@"
      ;;

      'list')
         sourcetree::supermarks::list_main "$@"
      ;;

      ''|*)
         sourcetree::supermarks::usage "Unknown command $cmd"
      ;;
   esac
}



sourcetree::supermarks::initialize()
{
   log_entry "sourcetree::supermarks::initialize"

   include "sourcetree::marks"
   include "sourcetree::plugin"

   sourcetree::plugin::load_all
}

sourcetree::supermarks::initialize

:
