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

sourcetree_dbstatus_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dbstatus

   Tests if a database is up to date.

Returns:
    0 : yes
    1 : error
    2 : no
EOF
  exit 1
}


sourcetree_status_usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} status [options]

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
   case ",${mode}," in
      *,flat,*)
         case "${dbtype}" in
            flat|recurse)
               return 0
            ;;
         esac
         log_debug "${dbtype} != flat|recurse"
         return 1
      ;;

      *,recurse,*)
         case "${dbtype}" in
            recurse)
               return 0
            ;;
         esac
         log_debug "${dbtype} != recurse"
         return 1
      ;;

      *,share,*)
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
r_emit_status()
{
   log_entry "r_emit_status" "$@"

   local address="$1"
   local directory="$2"
   local datasource="$3"
   local marks="$4"
   local mode="$5"
   local filename="$6"

   local output_adress

   r_filepath_concat "${datasource}" "${address}"
   output_adress="${RVAL}"

   # emit root
   if [ -z "${directory}" ]
   then
      datasource="${SOURCETREE_START}"
      output_adress="`filepath_concat "${SOURCETREE_START}" "${address}" `"
      directory="."
      r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${SOURCETREE_START}"
      filename="${RVAL}"
   else
      filename="`__walk_get_db_filename`"
      if ! string_has_prefix "${filename}" "${MULLE_SOURCETREE_SHARE_DIR}"
      then
         datasource="${filename#${MULLE_VIRTUAL_ROOT}}"
         if [ -z "${datasource}" ]
         then
            datasource="${MULLE_VIRTUAL_ADDRESS}"
         fi
      else
         datasource="${filename}"
      fi
   fi

   if string_has_prefix "${output_adress}" "${MULLE_SOURCETREE_SHARE_DIR}"
   then
      output_adress="${output_adress#${MULLE_SOURCETREE_SHARE_DIR}}"
      output_adress="\${MULLE_SOURCETREE_SHARE_DIR}${output_adress}"
   fi

   case "${datasource}" in
      "//")
         internal_fail "malformed datasource"
      ;;

      "/"|/*/)
      ;;

      /*)
         datasource="${datasource}/"
      ;;

      */)
         datasource="/${datasource}"
      ;;

      *)
         datasource="/${datasource}/"
      ;;
   esac

   local fs
   local configexists
   local dbexists
   local status

   configexists='NO'
   dbexists='NO'
   fs="library"
   status="unknown"

   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "address:    ${address}"
      log_trace2 "directory:  ${directory}"
      log_trace2 "datasource: ${datasource}"
      log_trace2 "marks:      ${marks}"
      log_trace2 "mode:       ${mode}"
      log_trace2 "filename:   ${filename}"
   fi

   if nodemarks_contain "${marks}" "fs"
   then
      fs="missing"

      if [ -e "${filename}/${SOURCETREE_CONFIG_FILE}" ]
      then
         configexists='YES'
      fi

      if [ -d "${filename}/${SOURCETREE_DB_NAME}" ]
      then
         dbexists='YES'
      fi

      #
      # Dstfile    | Url | Marks      | Output
      # -----------|-----|------------|------------------
      # not exists | no  | -          | missing
      # not exists | yes | require    | unhappy
      # not exists | yes | no-require | optional
      #

      if [ ! -e "${filename}" ]
      then
         if [ -L "${filename}" ]
         then
            fs="broken"
         fi

         if ! nodemarks_contain "${marks}" "require"
         then
            #
            # if we say not uptodate here, it will retrigger
            # build and updates for non-required stuff thats
            # never there. Fix: (always need a require node)
            #
            log_fluff "\"${filename}\" does not exist but it isn't required ($PWD)"
            if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
            then
               return 0
            fi
            RVAL="${output_adress};optional;${fs};${configexists};${dbexists}" #;${filename}"
         else
            if [ -z "${_url}" ]
            then
               log_fluff "\"${filename}\" does not exist and and is required \
($PWD), but _url is empty"
               if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
               then
                  log_fluff "exit with 2"
                  exit 2   # indicate brokenness
               fi
               RVAL="${output_adress};absent;${fs};${configexists};${dbexists}" #;${filename}"
               return 0
            fi

            log_fluff "\"${filename}\" does not exist and is required ($PWD)"
            if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
            then
               log_fluff "exit with 1"
               exit 1
            fi
            RVAL="${output_adress};absent;${fs};${configexists};${dbexists}" #;${filename}"
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

      if [ "${dbexists}" = 'YES' ] && \
         ! sourcetree_is_db_compatible "${datasource}" "${SOURCETREE_MODE}"
      then
         log_fluff "Database \"${datasource}\" is not compatible with \
\"${SOURCETREE_MODE}\" ($PWD)"

         if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
         then
            log_fluff "exit with 1"
            exit 1
         fi
         RVAL="${output_adress};outdated;${fs};${configexists};${dbexists}" #;${filename}"
         return 0
      fi

      status="ok"

      case ",${mode}," in
         *,flat,*)
         ;;

         *)
            #
            # Config     | Database | Config > DB | Output
            # -----------|----------|-------------|----------
            # not exists | *        | *           | ok
            #
            if [ "${configexists}" = 'NO' ]
            then
               log_fluff "\"${directory}\" does not have a \
${SOURCETREE_CONFIG_FILE} ($PWD)"

               if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
               then
                  return 0
               fi

               RVAL="${output_adress};ok;${fs};${configexists};${dbexists}" #;${filename}"
               return
            fi

            #
            # Config  | Database   | Config > DB | Output
            # --------|------------|-------------|----------
            # exists  | not exists | *           | update
            # exists  | updating   | *           | updating
            # exists  | exists     | -           | ok
            # exists  | exists     | +           | update
            #

            if ! db_is_ready "${datasource}"
            then
               log_fluff "Database \"${datasource}\" is not ready"
               status="unready"
            else
               if db_is_updating "${datasource}"
               then
                  log_fluff "\"${filename}\" is marked as updating ($PWD)"

                  if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
                  then
                     log_fluff "exit with 2"
                     exit 2  # only time we exit with 2 on IS_UPTODATE
                  fi

                  RVAL="${output_adress};updating;${fs};\
${configexists};${dbexists}" #;${filename}"
                  return 0
               fi

               if ! sourcetree_is_uptodate "${datasource}"
               then
                  if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
                  then
                     log_fluff "exit with 1"
                     exit 1
                  fi

                  log_fluff "Database \"${datasource}\" is stale ($PWD)"
                  status="stale"
               fi
            fi
         ;;
      esac
   fi

   if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
   then
      return 0
   fi

   if [ "${fs}" = "symlink" ]
   then
      status="ok"
   fi

   RVAL="${output_adress};${status};${fs};${configexists};${dbexists}" # ;${filename}"
}


walk_status()
{
   log_entry "walk_status" "$@"

   local filename
   local name
   local RVAL
   local rval

   filename="`__walk_get_db_filename`"

   r_emit_status "${MULLE_ADDRESS}" \
                 "${MULLE_VIRTUAL_ADDRESS}" \
                 "${MULLE_DATASOURCE}" \
                 "${MULLE_MARKS}" \
                 "${MULLE_MODE}" \
                 "${filename}"
   rval=$?
   [ ! -z "${RVAL}" ] && echo "${RVAL}"
   return $rval
}


sourcetree_status()
{
   log_entry "sourcetree_status" "$@"

   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local filtermarks="$1"; shift
   local mode="$1"; shift

   local output
   local output2
   local rval
   local RVAL

   r_emit_status
   output="${RVAL}"
   output2="`walk_config_uuids "${filternodetypes}" \
                               "${filterpermissions}" \
                               "${filtermarks}" \
                               "${mode}" \
                               "walk_status" \
                               "$@"`"
   rval="$?"
   if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
   then
      return $rval
   fi

   if [ $rval -ne 0 ]
   then
      fail "Walk errored out ($rval)"
   fi

   #
   # sorting lines is harmless and this remove some duplicates too
   # which we would otherwise have to filter
   #
   output2="$(sort -u <<< "${output2}")"

   local RVAL

   r_add_line "${output}" "${output2}"
   output="${RVAL}"

   local header

   case ",${mode}," in
      *,output-header,*)
         header="Node;Status;Filesystem;Config;Database" # ;Filename"

         case ",${mode}," in
            *,output-separator,*)
               r_add_line "${header}" \
                          "-------;------;----------;------;--------" # ;--------"
               header="${RVAL}"
            ;;
         esac
         r_add_line "${header}" "${output}"
         output="${RVAL}"
      ;;
   esac

   case ",${mode}," in
      *,output-formatted,*)
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
   local OPTION_PERMISSIONS="descend-symlink"
   local OPTION_NODETYPES=""
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_IS_UPTODATE='NO'
   local OPTION_OUTPUT_HEADER="DEFAULT"
   local OPTION_OUTPUT_FORMAT="FMT"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_status_usage
         ;;

         --all)
            VISIT_TWICE='YES'
         ;;

         --output-header)
            OPTION_OUTPUT_HEADER='YES'
         ;;

         --no-output-header|--output-no-header)
            OPTION_OUTPUT_HEADER='NO'
         ;;

         --output-raw)
            OPTION_OUTPUT_FORMAT='RAW'
         ;;

         --no-output-raw|--output-no-raw)
            OPTION_OUTPUT_FORMAT='FMT'
         ;;

         --output-separator)
            OPTION_OUTPUT_SEPERATOR='YES'
         ;;

         --no-output-separator|--output-no-separator)
            OPTION_OUTPUT_SEPERATOR='NO'
         ;;

         --is-uptodate)
            OPTION_IS_UPTODATE='YES'
         ;;

         #
         # more common flags
         #
         -m|--marks)
            [ $# -eq 1 ] && sourcetree_status_usage "Missing argument to \"$1\""
            shift

            OPTION_MARKS="$1"
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && sourcetree_status_usage "Missing argument to \"$1\""
            shift

            OPTION_NODETYPES="$1"
         ;;

         -p|--permissions)
            [ $# -eq 1 ] && sourcetree_status_usage "Missing argument to \"$1\""
            shift

            OPTION_PERMISSIONS="$1"
         ;;

         -*)
            sourcetree_status_usage "Unknown option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_status_usage "superflous arguments \"$*\""

   if ! cfg_exists "${SOURCETREE_START}"
   then
      log_info "There is no ${SOURCETREE_CONFIG_FILE} here"
      return 0
   fi

   if ! db_is_ready "${SOURCETREE_START}"
   then
      if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
      then
         log_fluff "db is not marked as ready"
         exit 1
      fi

      log_fluff "Update has not run yet (mode=${SOURCETREE_MODE})"
   fi

   local RVAL

   mode="${SOURCETREE_MODE}"
   if [ "${SOURCETREE_MODE}" != "flat" ]
   then
      r_comma_concat "${mode}" "pre-order"
      mode="${RVAL}"
   fi
   if [ "${OPTION_OUTPUT_FORMATTED}" = 'FMT' ]
   then
      r_comma_concat "${mode}" "output-formatted"
      mode="${RVAL}"
   fi
   if [ "${OPTION_OUTPUT_HEADER}" != 'NO' ]
   then
      r_comma_concat "${mode}" "output-header"
      mode="${RVAL}"
      if [ "${OPTION_OUTPUT_SEPARATOR}" != 'NO' ]
      then
         r_comma_concat "${mode}" "output-separator"
         mode="${RVAL}"
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
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] &&
         internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

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
