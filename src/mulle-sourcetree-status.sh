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
MULLE_SOURCETREE_STATUS_SH="included"


sourcetree_status_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} status [options]

   Emit status of your sourcetree.

Options:
   --is-uptodate  : return with 0 if sourcetree does not need to run update
   -n <value>     : node types to walk (default: ALL)
   -p <value>     : specify permissions (missing)
   -m <value>     : specify marks to match (e.g. build)
   --recurse      : recurse
   --no-recurse   : do not recurse
EOF
  exit 1
}


emit_status()
{
   log_entry "emit_status" "$@"

   local directory="$1"
   local marks="$2"

   local rval
   local prefix

   if [ -z "${directory}" ]
   then
      prefix=""
      directory="."
   else
      prefix="${directory}/"
   fi

   #
   # Dstfile    | Url | Marks     | Output
   # -----------|-----|-----------|------------------
   # not exists | no  | -         | missing
   # not exists | yes | require   | update
   # not exists | yes | norequire | norequire
   #

   if [ ! -e "${directory}" ]
   then
      if nodemarks_contain_norequire "${marks}"
      then
         #
         # if we say not uptodate here, it will retrigger
         # build and updates for non-required stuff thats
         # never there. Fix: (always need a require node)
         #
         log_fluff "\"${directory}\" does not exist but it isn't required ($PWD)"
         if [ "${OPTION_IS_UPTODATE}" = "YES" ]
         then
            return 0
         fi
         echo "${directory};norequire"
      else
         if [ -z "${url}" ]
         then
            log_fluff "\"${directory}\" does not exist and and is required ($PWD), but url is empty"
            if [ "${OPTION_IS_UPTODATE}" = "YES" ]
            then
               return 2   # indicate brokenness
            fi
            echo "${directory};missing"
            return 0
         fi

         log_fluff "\"${directory}\" does not exist and is required ($PWD)"
         if [ "${OPTION_IS_UPTODATE}" = "YES" ]
         then
            exit 1
         fi
         echo "${directory};update"
      fi
      return
   fi

   #
   # Config     | Database | Config > DB | Output
   # -----------|----------|-------------|----------
   # not exists | *        | *           | ok
   #

   if ! nodeline_config_exists "${prefix}"
   then
      log_fluff "\"${directory}\" does not have a ${SOURCETREE_CONFIG_FILE} ($PWD)"

      if [ "${OPTION_IS_UPTODATE}" = "YES" ]
      then
         return 0
      fi

      echo "${directory};ok"
      return
   fi

   #
   # Config  | Database   | Config > DB | Output
   # --------|------------|-------------|----------
   # exists  | not exists | *           | update
   # exists  | updating   | *           | incomplete
   # exists  | exists     | -           | ok
   # exists  | exists     | +           | update
   #

   if ! db_is_ready "${prefix}"
   then
      echo "${directory};update"
      return 0
   fi

   if db_is_updating "${prefix}"
   then
      log_fluff "\"${directory}\" is marked as updating ($PWD)"

      echo "${directory};incomplete"
      if [ "${OPTION_IS_UPTODATE}" = "YES" ]
      then
         exit 2  # only time we exit with 2 on IS_UPTODATE
      fi
      return 1
   fi

   if ! db_is_uptodate "${prefix}"
   then
      log_fluff "\"${directory}\" database is stale ($PWD)"

      echo "${directory};update"
      return 0
   fi

   if [ "${OPTION_IS_UPTODATE}" = "YES" ]
   then
      return 0
   fi
   echo "${directory};ok"
}


walk_status()
{
   log_entry "walk_status" "$@"

#   url="$1"
   prefixed="$2"
#   branch="$3"
#   tag="$4"
#   nodetype="$5"
    marks="$6"
#   fetchoptions="$7"
#   useroptions="$8"
#   uuid="$9"

   emit_status "${prefixed}" "${marks}"
}



sourcetree_status()
{
   log_entry "sourcetree_status" "$@"

   local filternodetypes="$1"
   local filterpermissions="$2"
   local filtermarks="$3"
   local mode="$4"

   local output
   local output2
   local rval

   output="`emit_status`"
   output2="`walk_config_uuids "walk_status" \
                               "${filternodetypes}" \
                               "${filterpermissions}" \
                               "${filtermarks}" \
                               "${mode}"`" || exit 1

   if [ "${OPTION_IS_UPTODATE}" = "YES" ]
   then
      return 0
   fi

   output="`add_line "${output}" "${output2}"`"

   local header

   case "${mode}" in
      *header*)
         header="Address;Status"
         case "${mode}" in
            *separator*)
               header="`add_line "${header}" "-----------;------"`"
            ;;
         esac
         output="`add_line "${header}" "${output}"`"
      ;;
   esac

   case "${mode}" in
      *formatted*)
         echo "${output}" | column -t -s';'
      ;;

      *)
         echo "${output}"
      ;;
   esac
}


sourcetree_status_main()
{
   log_entry "sourcetree_status_main" "$@"

   local OPTION_MARKS="ANY"
   local OPTION_PERMISSIONS="" # empty!
   local OPTION_NODETYPES="ALL"
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_RECURSIVE
   local OPTION_IS_UPTODATE="NO"
   local OPTION_OUTPUT_HEADER="DEFAULT"
   local OPTION_OUTPUT_RAW="DEFAULT"

   _db_set_default_options

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            sourcetree_status_usage
         ;;

         --output-header)
            OPTION_OUTPUT_HEADER="YES"
         ;;

         --no-output-header)
            OPTION_OUTPUT_HEADER="NO"
         ;;

         --output-raw)
            OPTION_OUTPUT_RAW="YES"
         ;;

         --no-output-raw)
            OPTION_OUTPUT_RAW="NO"
         ;;

         --output-separator)
            OPTION_OUTPUT_SEPERATOR="YES"
         ;;

         --no-output-separator)
            OPTION_OUTPUT_SEPERATOR="NO"
         ;;

         --is-uptodate)
            OPTION_IS_UPTODATE="YES"
         ;;

         --no-is-uptodate)
            OPTION_IS_UPTODATE="YES"
         ;;
         #
         # more common flags
         #
         -m|--marks)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_MARKS="$1"
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_NODETYPES="$1"
         ;;

         -p|--permissions)
            [ $# -eq 1 ] && fail "missing argument to \"$1\""
            shift

            OPTION_PERMISSIONS="$1"
         ;;

         -r|--recurse|--recursive)
            OPTION_RECURSIVE="YES"
         ;;

         --no-recurse|--no-recursive)
            OPTION_RECURSIVE="NO"
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown status option $1"
            sourcetree_status_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_status_usage

   if ! nodeline_config_exists
   then
      log_info "There is no ${SOURCETREE_CONFIG_FILE} here"
      return 0
   fi

   if ! db_is_ready
   then
      if [ "${OPTION_IS_UPTODATE}" = "YES" ]
      then
         log_fluff "db is not marked as ready"
         return 1
      fi

      log_warning "Update has not run yet"
   fi

   mode="prefix"
   if [ "${OPTION_RECURSIVE}" = "YES" ]
   then
      mode="`concat "${mode}" "recurse"`"
   fi
   if [ "${OPTION_OUTPUT_RAW}" != "YES" ]
   then
      mode="`concat "${mode}" "output-formatted"`"
   fi
   if [ "${OPTION_OUTPUT_HEADER}" != "NO" ]
   then
      mode="`concat "${mode}" "output-header"`"
      if [ "${OPTION_OUTPUT_SEPARATOR}" != "NO" ]
      then
         mode="`concat "${mode}" "output-separator"`"
      fi
   fi

   sourcetree_status "${OPTION_NODETYPES}" \
                     "${OPTION_PERMISSIONS}" \
                     "${OPTION_MARKS}" \
                     "${mode}"
}


sourcetree_status_initialize()
{
   log_entry "sourcetree_status_initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   fi
}


sourcetree_status_initialize

:
