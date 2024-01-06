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
MULLE_SOURCETREE_JSON_SH='included'


#! /usr/bin/env mulle-bash
# shellcheck shell=bash
#
#   Copyright (c) 2022 Nat! - Mulle kybernetiK
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
[ "${TRACE:-}" = 'YES' -o "${MULLE_SOURCETREE_EXPORT_JSON_TRACE:-}" = 'YES' ] && set -x && : "$0" "$@"


MULLE_EXECUTABLE_VERSION="1.1.0"


CONFIG="${1:-.mulle/etc/sourcetree/config}"


sourcetree::json::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} json [--expand]

      cat <<EOF >&2

   Show sourcetree config file as JSON. This will dump the current config
   flat. If you specify --expand, the variables will be expanded.

EOF
   exit 1
}


sourcetree::json::userinfo()
{
   log_entry "sourcetree::json::userinfo" "$@"

   local raw="$1"

   printf "      \"userinfo\":     {"

   local userinfo

   sourcetree::node::r_decode_raw_userinfo "${raw}"
   userinfo="${RVAL}"

   local delimiter=$'\n'

   .foreachline key in `assoc_array_all_keys "${userinfo}"`
   .do
      r_assoc_array_get "${userinfo}" "${key}"
      value="${RVAL}"

      if [ ! -z "${value}" ]
      then
         r_escaped_doublequotes "${value}"
         value="${RVAL}"
         printf "${delimiter}                          \"%s\": \"%s\"%s"  "${key}" "${value}"
         delimiter=","$'\n'
      fi
   .done

   printf "\n                      },\n"
}


sourcetree::json::callback()
{
   log_entry "sourcetree::json::callback" "$@"

   printf "%s" "${DELIMITER}"
   DELIMITER=","$'\n'

   printf "   {\n"
   printf "      \"address\":      \"${_address}\",\n"

   if [ ! -z "${_branch}" ]
   then
      printf "      \"branch\":       \"${_branch}\",\n"
   fi
   if [ ! -z "${_fetchoptions}" ]
   then
      printf "      \"fetchoptions\": \"${_fetchoptions}\",\n"
   fi
   if [ ! -z "${_marks}" ]
   then
      printf "      \"marks\":        \"${_marks}\",\n"
   fi
   if [ ! -z "${_nodetype}" ]
   then
      printf "      \"nodetype\":     \"${_nodetype}\",\n"
   fi
   if [ ! -z "${_tag}" ]
   then
      printf "      \"tag\":          \"${_tag}\",\n"
   fi
   if [ ! -z "${_url}" ]
   then
      printf "      \"url\":          \"${_url}\",\n"
   fi
   if [ ! -z "${_raw_userinfo}" ]
   then
      sourcetree::json::userinfo "${_raw_userinfo}"
   fi

   printf "      \"uuid\":         \"${_uuid}\"\n"
   printf "   }"
}



sourcetree::json::expandedcallback()
{
   log_entry "sourcetree::json::expandedcallback" "$@"

   printf "%s" "${DELIMITER}"
   DELIMITER=","$'\n'

   printf "   {\n"
   printf "      \"address\":      \"${_address}\",\n"

   if [ ! -z "${_branch}" ]
   then
      printf "      \"branch\":       \"${_evaledbranch}\",\n"
   fi
   if [ ! -z "${_evaledfetchoptions}" ]
   then
      printf "      \"fetchoptions\": \"${_evaledfetchoptions}\",\n"
   fi
   if [ ! -z "${_marks}" ]
   then
      printf "      \"marks\":        \"${_marks}\",\n"
   fi
   if [ ! -z "${_evalednodetype}" ]
   then
      printf "      \"nodetype\":     \"${_evalednodetype}\",\n"
   fi
   if [ ! -z "${_evaledtag}" ]
   then
      printf "      \"tag\":          \"${_evaledtag}\",\n"
   fi
   if [ ! -z "${_evaledurl}" ]
   then
      printf "      \"url\":          \"${_evaledurl}\",\n"
   fi
   if [ ! -z "${_raw_userinfo}" ]
   then
      sourcetree::json::userinfo "${_raw_userinfo}"
   fi

   printf "      \"uuid\":         \"${_uuid}\"\n"
   printf "   }"
}


sourcetree::json::main()
{
   local OPTION_SHAREDIR
   local OPTION_EXPAND
   local OPTION_MARKS
   local OPTION_NODETYPES
   local OPTION_MARKS_QUALIFIER

   #
   # simple option handling
   #
   while [ $# -ne 0 ]
   do
      if options_technical_flags "$1"
      then
         shift
         continue
      fi

      case "$1" in
         -h*|--help|help)
            sourcetree::json::usage
         ;;

         --expand)
            OPTION_EXPAND='YES'
         ;;

         --no-expand)
            OPTION_EXPAND='NO'
         ;;

         --marks)
            [ $# -eq 1 ] && sourcetree::list::usage "Missing argument to \"$1\""
            shift

            # allow to concatenate multiple flags
            r_comma_concat "${OPTION_MARKS}" "$1"
            OPTION_MARKS="${RVAL}"
         ;;

         --nodetype|--nodetypes)
            [ $# -eq 1 ] && sourcetree::list::usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${OPTION_NODETYPES}" "$1"
            OPTION_NODETYPES="${RVAL}"
         ;;

         --qualifier)
            [ $# -eq 1 ] && sourcetree::list::usage "Missing argument to \"$1\""
            shift

            # allow to concatenate multiple flags
            OPTION_MARKS_QUALIFIER="$1"
         ;;

         --version)
            printf "%s\n" "${MULLE_EXECUTABLE_VERSION}"
            exit 0
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown flag \"$1\""
            sourcetree::json::usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   include "array"
   include "sourcetree::node"
   include "sourcetree::walk"

   local options

   if [ ! -z "${OPTION_MARKS_QUALIFIER}" ]
   then
      r_escaped_singlequotes "${OPTION_MARKS_QUALIFIER}"
      r_concat "${options}" "--qualifier '${RVAL}'"
      options="${RVAL}"
   fi

   if [ ! -z "${OPTION_NODETYPES}" ]
   then
      r_escaped_singlequotes "${OPTION_NODETYPES}"
      r_concat "${options}" "--nodetypes '${RVAL}'"
      options="${RVAL}"
   fi

   if [ ! -z "${OPTION_MARKS}" ]
   then
      r_escaped_singlequotes "${OPTION_MARKS}"
      r_concat "${options}" "--marks '${RVAL}'"
      options="${RVAL}"
   fi

   local callback

   callback="sourcetree::json::callback"
   if [ "${OPTION_EXPAND}" = 'YES' ]
   then
      callback="sourcetree::json::expandedcallback"
   fi

   local text

   text="`eval_rexekutor sourcetree::walk::main \
                                        --lenient \
                                        --no-eval \
                                        --flat \
                                        "${options}" \
                                        "'${callback}'" `"
   if [ ! -z "${text}" ]
   then
      cat <<EOF
[
${text}
]
EOF
      return 0
   fi

   return 1
}

