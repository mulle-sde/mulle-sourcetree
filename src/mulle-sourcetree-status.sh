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
   --all          : visit all nodes, even if they are unused due to sharing
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

   local datasource="$1"

   [ -z "${datasource}" ] && internal_fail "datasource is empty"

   local configtimestamp
   local dbtimestamp

   configtimestamp="`cfg_timestamp "${datasource}"`"
   if [ -z "${configtimestamp}" ]
   then
      log_fluff "No timestamp available for \"${datasource}\""
      return 2
   fi

   dbtimestamp="`db_get_timestamp "${datasource}"`"

   log_debug "Timestamps: config=${configtimestamp} db=${dbtimestamp:-0}"

   if [ "${configtimestamp}" -gt "${dbtimestamp:-0}" ]
   then
      log_fluff "Config \"${datasource}\" is newer than the database"
      return 1
   fi

   return 0
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

   local dbtype

   dbtype="`db_get_dbtype "${database}"`"
   case "${mode}" in
      *flat*)
         case "${dbtype}" in
            flat|recurse)
               return 0
            ;;
         esac
         log_debug "${dbtype} != flat|recurse"
         return 1
      ;;

      *recurse*)
         case "${dbtype}" in
            recurse)
               return 0
            ;;
         esac
         log_debug "${dbtype} != recurse"
         return 1
      ;;

      *share*)
         case "${dbtype}" in
            share)
               return 0
            ;;
         esac
         log_debug "${dbtype} != share"
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
   local marks="$4"
   local mode="$5"
   local filename="$6"

   local output_address

   output_adress="`filepath_concat "${datasource}" "${address}" `"

   # emit root
   if [ -z "${directory}" ]
   then
      datasource="${SOURCETREE_START}"
      output_adress="`filepath_concat "${SOURCETREE_START}" "${address}" `"
      directory="."
      filename="`filepath_concat "${MULLE_VIRTUAL_ROOT}" "${SOURCETREE_START}" `"
   else
      filename="`__walk_get_filename`"
      if ! string_has_prefix "${filename}" "${MULLE_SOURCETREE_SHARE_DIR}"
      then
         datasource="`string_remove_prefix "${filename}" "${MULLE_VIRTUAL_ROOT}"`"
         if [ -z "${datasource}" ]
         then
            datasource="`pretty_datasource "${MULLE_VIRTUAL_ADDRESS}"`"
         fi
      else
         datasource="${filename}"
      fi
   fi


   log_debug "address:    ${address}"
   log_debug "directory:  ${directory}"
   log_debug "datasource: ${datasource}"
   log_debug "marks:      ${marks}"
   log_debug "mode:       ${mode}"
   log_debug "filename:   ${filename}"

   local fs
   local configexists
   local dbexists

   configexists="NO"
   dbexists="NO"

   if [ -e "${filename}/${SOURCETREE_CONFIG_FILE}" ]
   then
      configexists="YES"
   fi

   if [ -d "${filename}/${SOURCETREE_DB_NAME}" ]
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

   if [ ! -e "${filename}" ]
   then
      if [ -L "${filename}" ]
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
         log_fluff "\"${filename}\" does not exist but it isn't required ($PWD)"
         if [ "${OPTION_IS_UPTODATE}" = "YES" ]
         then
            return 0
         fi
         exekutor echo "${output_adress};norequire;${fs};${configexists};${dbexists};${filename}"
      else
         if [ -z "${_url}" ]
         then
            log_fluff "\"${filename}\" does not exist and and is required ($PWD), but _url is empty"
            if [ "${OPTION_IS_UPTODATE}" = "YES" ]
            then
               exit 2   # indicate brokenness
            fi
            exekutor echo "${output_adress};update;${fs};${configexists};${dbexists};${filename}"
            return 0
         fi

         log_fluff "\"${filename}\" does not exist and is required ($PWD)"
         if [ "${OPTION_IS_UPTODATE}" = "YES" ]
         then
            exit 1
         fi
         exekutor echo "${output_adress};update;${fs};${configexists};${dbexists};${filename}"
      fi
      return
   else
      fs="file"
      if [ -L "${filename}" ]
      then
         fs="symlink"
      else
         if [ -d "${filename}" ]
         then
            fs="directory"
         fi
      fi
   fi

   if [ "${dbexists}" = "YES" ] && \
      ! sourcetree_is_db_compatible "${datasource}" "${SOURCETREE_MODE}"
   then
      log_fluff "Database \"${datasource}\" is not compatible with \"${SOURCETREE_MODE}\" ($PWD)"

      if [ "${OPTION_IS_UPTODATE}" = "YES" ]
      then
         exit 1
      fi
      exekutor echo "${output_adress};update;${fs};${configexists};${dbexists};${filename}"
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

            exekutor echo "${output_adress};ok;${fs};${configexists};${dbexists};${filename}"
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
            log_fluff "Database \"${datasource}\" is not ready"
            status="update"
         else
            if db_is_updating "${datasource}"
            then
               log_fluff "\"${filename}\" is marked as updating ($PWD)"

               if [ "${OPTION_IS_UPTODATE}" = "YES" ]
               then
                  exit 2  # only time we exit with 2 on IS_UPTODATE
               fi

               exekutor echo "${output_adress};incomplete;${fs};${configexists};${dbexists};${filename}"
               return 0
            fi

            if ! sourcetree_is_uptodate "${datasource}"
            then
               log_fluff "\"${filename}\" database is stale ($PWD)"

               status="update"
            fi
         fi
      ;;
   esac

   if [ "${OPTION_IS_UPTODATE}" = "YES" ]
   then
      return 0
   fi
   exekutor echo "${output_adress};${status};${fs};${configexists};${dbexists};${filename}"
}


walk_status()
{
   log_entry "walk_status" "$@"

   local filename
   local name

   filename="`__walk_get_filename`"

   emit_status "${MULLE_ADDRESS}" \
               "${MULLE_VIRTUAL_ADDRESS}" \
               "${MULLE_DATASOURCE}" \
               "${MULLE_MARKS}" \
               "${MULLE_MODE}" \
               "${filename}"
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
                               "$@"`"
   if [ $? -ne 0 ]
   then
      fail "Walk errored out"
   fi

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
         header="Node;Status;Filesystem;Config;Database;Filename"

         case "${mode}" in
            *separator*)
               header="`add_line "${header}" "-------;------;----------;------;--------;--------"`"
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

         --all)
            VISIT_TWICE="YES"
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

   if ! cfg_exists "${SOURCETREE_START}"
   then
      log_info "There is no ${SOURCETREE_CONFIG_FILE} here"
      return 0
   fi

   if ! db_is_ready "${SOURCETREE_START}"
   then
      if [ "${OPTION_IS_UPTODATE}" = "YES" ]
      then
         log_fluff "db is not marked as ready"
         exit 1
      fi

      log_warning "Update has not run yet (mode=${SOURCETREE_MODE})"
   fi

   mode="${SOURCETREE_MODE}"
   if [ "${SOURCETREE_MODE}" != "flat" ]
   then
      mode="`concat "${mode}" "pre-order"`"
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
