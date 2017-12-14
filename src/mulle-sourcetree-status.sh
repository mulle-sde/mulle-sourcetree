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
EOF
  exit 1
}


#
# 0 : OK
# 1 : needs update
# 2 : config file missing
#
sourcetree_is_uptodate()
{
   log_entry "sourcetree_is_uptodate" "$@"

   local database="$1"
   local projectdir="$2"

   [ -z "${database}" ] && internal_fail "database is empty"
   [ -z "${projectdir}" ] && internal_fail "projectdir is empty"

   local configtimestamp
   local dbtimestamp

   configtimestamp="`cfg_timestamp "${projectdir}"`"
   if [ -z "${configtimestamp}" ]
   then
      return 2
   fi

   dbtimestamp="`db_get_timestamp "${database}"`"

   log_debug "Timestamps: config=${configtimestamp} db=${dbtimestamp:-0}"

   [ "${configtimestamp}" -le "${dbtimestamp:-0}" ]
}



#
# ensure that databases produced last time are
# compatible
#
sourcetree_is_db_compatible()
{
   log_entry "sourcetree_is_db_compatible" "$@"

   local database="$1"
   local mode="$2"

   [ -z "${database}" ] && internal_fail "database is empty"

   local dbtype

   dbtype="`db_get_dbtype "${database}"`"
   case "${mode}" in
      *flat*)
         case "${dbtype}" in
            flat|recurse)
               return 0
            ;;
         esac
         return 1
      ;;

      *recurse*)
         case "${dbtype}" in
            recurse)
               return 0
            ;;
         esac
         return 1
      ;;

      *share*)
         case "${dbtype}" in
            partial)
               if [ "${database}" != "/" ]
               then
                  return 0
               fi
            ;;

            share)
               return 0
            ;;
         esac
         return 1
      ;;
   esac
}


#
# we are arriving here in prefixed mode
#
emit_status()
{
   log_entry "emit_status" "$@"

   local address="$1"
   local directory="$2"
   local datasource="$3"
   local projectdir="$4"
   local marks="$5"
   local mode="$6"

   if [ -z "${directory}" ]
   then
      datasource="/"
      directory="."
      projectdir="/"
   fi

   log_debug "address:    ${address}"
   log_debug "directory:  ${directory}"
   log_debug "datasource: ${datasource}"
   log_debug "projectdir: ${projectdir}"
   log_debug "marks:      ${marks}"
   log_debug "mode:       ${mode}"

   local fs
   local configexists
   local dbexists

   configexists="NO"
   dbexists="NO"

   if cfg_exists "${projectdir}"
   then
      configexists="YES"
   fi

   if db_dir_exists "${projectdir}"
   then
      dbexists="YES"
   fi

   fs="missing"

   #
   # Dstfile    | Url | Marks     | Output
   # -----------|-----|-----------|------------------
   # not exists | no  | -         | missing
   # not exists | yes | require   | update
   # not exists | yes | norequire | norequire
   #

   if [ ! -e "${directory}" ]
   then
      if [ -L "${directory}" ]
      then
         fs="broken"
      fi

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
         exekutor echo "${directory};norequire;${fs};${configexists};${dbexists}"
      else
         if [ -z "${url}" ]
         then
            log_fluff "\"${directory}\" does not exist and and is required ($PWD), but url is empty"
            if [ "${OPTION_IS_UPTODATE}" = "YES" ]
            then
               exit 2   # indicate brokenness
            fi
            exekutor echo "${directory};update;${fs};${configexists};${dbexists}"
            return 0
         fi

         log_fluff "\"${directory}\" does not exist and is required ($PWD)"
         if [ "${OPTION_IS_UPTODATE}" = "YES" ]
         then
            exit 1
         fi
         exekutor echo "${directory};update;${fs};${configexists};${dbexists}"
      fi
      return
   else
      fs="file"
      if [ -L "${directory}" ]
      then
         fs="symlink"
      else
         if [ -d "${directory}" ]
         then
            fs="directory"
         fi
      fi
   fi

   if [ "${dbexists}" = "YES" ] && \
      ! sourcetree_is_db_compatible "${datasource}" "${mode}"
   then
      if [ "${OPTION_IS_UPTODATE}" = "YES" ]
      then
         exit 1
      fi
      exekutor echo "${directory};update;${fs};${configexists};${dbexists}"
      return 0
   fi

   local status

   status="ok"

   case "${mode}" in
      *flat*)
      ;;

      *)

         #
         # Config     | Database | Config > DB | Output
         # -----------|----------|-------------|----------
         # not exists | *        | *           | ok
         #
         if [ "${configexists}" = "NO" ]
         then
            log_fluff "\"${directory}\" does not have a ${SOURCETREE_CONFIG_FILE} ($PWD)"

            if [ "${OPTION_IS_UPTODATE}" = "YES" ]
            then
               return 0
            fi

            exekutor echo "${directory};ok;${fs};${configexists};${dbexists}"
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

         if ! db_is_ready "${datasource}"
         then
            status="update"
         else
            if db_is_updating "${datasource}"
            then
               log_fluff "\"${directory}\" is marked as updating ($PWD)"

               if [ "${OPTION_IS_UPTODATE}" = "YES" ]
               then
                  exit 2  # only time we exit with 2 on IS_UPTODATE
               fi

               exekutor echo "${directory};incomplete;${fs};${configexists};${dbexists}"
               return 0
            fi

            if ! sourcetree_is_uptodate "${datasource}" "${projectdir}"
            then
               log_fluff "\"${directory}\" database is stale ($PWD)"

               status="update"
            fi
         fi
      ;;
   esac

   if [ "${OPTION_IS_UPTODATE}" = "YES" ]
   then
      return 0
   fi
   exekutor echo "${directory};${status};${fs};${configexists};${dbexists}"
}


walk_status()
{
   log_entry "walk_status" "$@"

   emit_status "${MULLE_ADDRESS}" \
               "${MULLE_DESTINATION}" \
               "${MULLE_DATASOURCE}" \
               "${MULLE_PROJECTDIR}" \
               "${MULLE_MARKS}" \
               "${MULLE_MODE}"
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
   output2="`walk_config_uuids "${filternodetypes}" \
                               "${filterpermissions}" \
                               "${filtermarks}" \
                               "${mode}" \
                               "walk_status" \
                               "$@"`" || exit 1

   if [ "${OPTION_IS_UPTODATE}" = "YES" ]
   then
      return 0
   fi

   #
   # sorting lines is harmless and this remove some duplicates too
   # which we would otherwise have to filter
   #
   output2="$(sort -u <<< "${output2}")"

   output="`add_line "${output}" "${output2}"`"

   local header

   case "${mode}" in
      *header*)
         header="Address;Status;Filesystem;Config;Database"

         case "${mode}" in
            *separator*)
               header="`add_line "${header}" "-------;------;----------;------;--------"`"
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
   local OPTION_IS_UPTODATE="NO"
   local OPTION_OUTPUT_HEADER="DEFAULT"
   local OPTION_OUTPUT_RAW="DEFAULT"

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

   if ! cfg_exists "/"
   then
      log_info "There is no ${SOURCETREE_CONFIG_FILE} here"
      return 0
   fi

   if ! db_is_ready "/"
   then
      if [ "${OPTION_IS_UPTODATE}" = "YES" ]
      then
         log_fluff "db is not marked as ready"
         exit 1
      fi

      log_warning "Update has not run yet (mode=${SOURCETREE_MODE})"
   fi

   mode="${SOURCETREE_MODE}"
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
