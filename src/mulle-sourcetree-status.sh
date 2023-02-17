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
MULLE_SOURCETREE_STATUS_SH='included'


sourcetree::status::usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} status [options]

   Emit status of your sourcetree. The nodes listed are your projects
   sourcetree nodes and those nodes inherited by dependencies.

   status     - shows the state of the database if any.
   Filesystem - shows the type of the dependency (directory or symlink)
   Sourcetree - shows if that project has a sourcetree.
   Database   - shows if that project has synced at least once.

Options:
   --all             : visit all nodes, even if they are unused due to sharing
   --shallow         : don't visit sourcetrees of nodes
   --deep            : visit the sourcetrees of nodes (default)
   --is-uptodate     : return <> 0 if a sync is needed (preselects --shallow)
   --output-filename : add filename to output
   -n <value>        : node types to walk (default: ALL)
   -p <value>        : specify permissions (missing)
   -m <value>        : specify marks to match (e.g. build)

Returns:
   0 : OK
   1 : error
   3 : there is no sourcetree
   4 : needs update
EOF
  exit 1
}


#
# 0 : OK
# 1 : error
# 2 : needs update
# 3 : there is no sourcetree
#
sourcetree::status::is_uptodate()
{
   log_entry "sourcetree::status::is_uptodate" "$@"

   local datasource="$1"

   [ -z "${datasource}" ] && _internal_fail "datasource is empty"

   local configtimestamp
   local dbtimestamp

   configtimestamp="`sourcetree::cfg::timestamp "${datasource}"`"
   if [ -z "${configtimestamp}" ]
   then
      log_fluff "No timestamp available for \"${datasource}\""
      return 3
   fi

   dbtimestamp="`sourcetree::db::get_timestamp "${datasource}"`"

   log_debug "Timestamps: config=${configtimestamp} db=${dbtimestamp:-0}"

   if [ "${configtimestamp}" -gt "${dbtimestamp:-0}" ]
   then
      log_fluff "Sourcetree \"${datasource}\" is newer than the database"
      return 2
   fi

   return 0
}


#
# ensure that databases produced last time are
# compatible
#
sourcetree::status::is_db_compatible()
{
   log_entry "sourcetree::status::is_db_compatible" "$@"

   local database="$1"
   local mode="$2"

   local dbtype

   dbtype="`sourcetree::db::get_dbtype "${database}"`"
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
# return values:
# (keep 1 for fails, 2 for walk ?)
#
# ok=0
# missing=3
# absent=4
# optional=5
# stale=6
# updating=7
# outdated=8
# unready=9
#
sourcetree::status::r_emit()
{
   log_entry "sourcetree::status::r_emit" "$@"

   local address="$1"
   local directory="$2"
   local datasource="$3"
   local marks="$4"
   local mode="$5"
   local filename="$6"

   local output_address

   r_filepath_concat "${datasource}" "${address}"
   output_address="${RVAL}"

   # emit root
   if [ -z "${directory}" ]
   then
      datasource="${SOURCETREE_START}"
      r_filepath_concat "${SOURCETREE_START}" "${address}"
      output_address="${RVAL}"

      directory="."
      r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${SOURCETREE_START}"
      filename="${RVAL}"
   else
      if ! string_has_prefix "${filename}" "${MULLE_SOURCETREE_STASH_DIR}"
      then
         datasource="${filename#${MULLE_VIRTUAL_ROOT}}"
         if [ -z "${datasource}" ]
         then
            datasource="${WALK_VIRTUAL_ADDRESS}"
         fi
      else
         datasource="${filename}"
      fi
   fi

   if string_has_prefix "${output_address}" "${MULLE_SOURCETREE_STASH_DIR}"
   then
      output_address="${output_address#${MULLE_SOURCETREE_STASH_DIR}}"
#      output_address="\${MULLE_SOURCETREE_STASH_DIR}${output_address}"
   fi

   case "${datasource}" in
      "//")
         _internal_fail "malformed datasource"
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
   local treestatus
  
   configexists='-'
   dbexists='-'
   fs="library"      # not a fs (system) library
   treestatus="ok"

   log_setting "output_address : ${output_address}"
   log_setting "address        : ${address}"
   log_setting "directory      : ${directory}"
   log_setting "datasource     : ${datasource}"
   log_setting "marks          : ${marks}"
   log_setting "mode           : ${mode}"
   log_setting "filename       : ${filename}"

   if sourcetree::nodemarks::enable "${marks}" "fs"
   then
      fs="missing"
      configexists='NO'

      local name 
      local dir

      for dir in "${SOURCETREE_CONFIG_DIR:-.mulle/etc/sourcetree}" \
                 "${SOURCETREE_FALLBACK_CONFIG_DIR:-.mulle/share/sourcetree}"
      do
         for name in ${SOURCETREE_CONFIG_NAME:-config}
         do
            if [ -e "${filename}/${dir}/${name}" -o \
                 -e "${filename}/${dir}/${name}.${MULLE_UNAME}" ]
            then
               configexists='YES'
               dbexists='NO'
            fi
         done
      done

      if [ -d "${filename}/${SOURCETREE_DB_FILENAME}" ]
      then
         dbexists='YES'
      fi

      #
      # Here we are doing still filesystem checks, not database
      # or config
      #
      # Dstfile    | Url | Marks      | Output
      # -----------|-----|------------|------------------
      # not exists | no  | -          | missing (3)
      # not exists | yes | require    | absent (4)
      # not exists | yes | no-require | optional (5)
      #

      if [ ! -e "${filename}" ]
      then
         if [ -L "${filename}" ]
         then
            fs="broken"
         fi

         if sourcetree::nodemarks::disable "${marks}" "require" ||
            sourcetree::nodemarks::disable "${marks}" "require-os-${MULLE_UNAME}"
         then
            #
            # if we say not uptodate here, it will retrigger
            # build and updates for non-required stuff thats
            # never there. Fix: (always need a require node)
            #
            log_fluff "#5: \"${filename}\" does not exist but it isn't required (${PWD#"${MULLE_USER_PWD}/"})"
            RVAL="${output_address};optional;${fs};${configexists};${dbexists}" #;${filename}"
            return 5
         fi

         if [ -z "${_url}" ]
         then
            _log_fluff "#3 \"${filename}\" does not exist and is required \
($PWD), but _url is empty"
            RVAL="${output_address};missing;${fs};${configexists};${dbexists}" #;${filename}"
            return 3
         fi

         log_fluff "#4 \"${filename}\" does not exist and is required (${PWD#"${MULLE_USER_PWD}/"})"
         RVAL="${output_address};absent;${fs};${configexists};${dbexists}" #;${filename}"
         return 4
      fi

      fs="file"
      if [ -L "${filename}" ]
      then
         fs="symlink"
         RVAL="${output_address};ok;${fs};-;-" #;${filename}"
         return 0
      else
         if [ -d "${filename}" ]
         then
            fs="directory"
         fi
      fi

      case ",${mode}," in
         *,deep,*)
            #
            # Start of database/config checks
            #
            # Config     | Database   | Config > DB | Output
            # -----------|------------|-------------|----------
            # exists     | exists     | ?           | outdated (8)
            # not exists | *          | *           | ok (0)
            # exists     | not ready  | *           | unready (9)
            # exists     | updating   | *           | updating (7)
            # exists     | exists     | -           | ok (0)
            # exists     | exists     | +           | dirty (6)
            # exists     | not-exists | *           | dirty (6)
            #
            if [ "${configexists}" = 'NO' ]
            then
               # don't fluff zeroes
               _log_debug "#0: \"${directory}\" does not have a \
${SOURCETREE_CONFIG_DIR} (${PWD#"${MULLE_USER_PWD}/"})"

               RVAL="${output_address};ok;${fs};${configexists};${dbexists}" #;${filename}"
               return 0
            fi

            if [ "${dbexists}" = 'NO' ]
            then
               log_fluff "#6 \"${filename}\" is dirty (${PWD#"${MULLE_USER_PWD}/"})"
               RVAL="${output_address};dirty;${fs};\
${configexists};${dbexists}" #;${filename}"
               return 6
            fi

            if ! sourcetree::status::is_db_compatible "${datasource}" "${SOURCETREE_MODE}"
            then
               _log_fluff "#8 Database \"${datasource}\" is not compatible with \
\"${SOURCETREE_MODE}\" (${PWD#"${MULLE_USER_PWD}/"})"

               RVAL="${output_address};outdated;${fs};${configexists};${dbexists}" #;${filename}"
               return 8
            fi

            if ! sourcetree::db::is_ready "${datasource}"
            then
               log_fluff "#9 Database \"${datasource}\" is not ready"
               RVAL="${output_address};unready;${fs};\
${configexists};${dbexists}" #;${filename}"
               return 9
            fi

            if sourcetree::db::is_updating "${datasource}"
            then
               log_fluff "#7: \"${filename}\" is marked as updating (${PWD#"${MULLE_USER_PWD}/"})"
               RVAL="${output_address};updating;${fs};\
${configexists};${dbexists}" #;${filename}"
               return 7
            fi

            if ! sourcetree::status::is_uptodate "${datasource}"
            then
               log_fluff "#6: Database \"${datasource}\" is dirty (${PWD#"${MULLE_USER_PWD}/"})"
               RVAL="${output_address};dirty;${fs};\
${configexists};${dbexists}" #;${filename}"
              return 6
            fi
            treestatus="ok"
         ;;

         *)
            treestatus="unknown"
            configexists="unknown"
            dbexists="unknown"
         ;;
      esac
   fi

   RVAL="${output_address};${treestatus};${fs};${configexists};${dbexists}" # ;${filename}"
   return 0
}


sourcetree::status::walk()
{
   log_entry "sourcetree::status::walk" "$@"

   local rval

   sourcetree::status::r_emit "${NODE_ADDRESS}" \
                              "${WALK_VIRTUAL_ADDRESS}" \
                              "${WALK_DATASOURCE}" \
                              "${NODE_MARKS}" \
                              "${WALK_MODE}" \
                              "${NODE_FILENAME}"
   rval=$?

   case $rval in
      1)
         return 1 # real error
      ;;

      5)
         # optional missing  
      ;;

      *)
         #
         # if we are just quickly checking for
         #
         if [ "${OPTION_IS_UPTODATE}" = 'YES'  ]
         then
            return $rval  # any other non-0 will preempt
         fi
      ;;
   esac

   if [ "${OPTION_IS_UPTODATE}" = 'YES'  ]
   then
      return 0
   fi

   if [ "${OPTION_OUTPUT_FILENAME}" = 'YES' ]
   then
      if [ -e "${NODE_FILENAME}" ]
      then
         RVAL="${RVAL};${NODE_FILENAME#"${MULLE_USER_PWD}/"};YES"
      else
         RVAL="${RVAL};${NODE_FILENAME#"${MULLE_USER_PWD}/"};NO"
      fi
   fi

   printf "%s\n" "${RVAL}"
}


sourcetree::status::do()
{
   log_entry "sourcetree::status::do" "$@"

   local mode="$1"

   local output
   local output2
   local rval

   # empty parameters means local
   # output an entry for root node
   sourcetree::status::r_emit "" "" "" "" "${mode}" ""
   output="${RVAL}"

   output2="`sourcetree::walk::walk_config_uuids "ALL" \
                                                 "" \
                                                 "" \
                                                 "" \
                                                 "${mode}" \
                                                 "sourcetree::status::walk"`"
   rval="$?"
   if [ $rval -eq 2 ]
   then
      rval=0
   fi

   if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
   then
      return $rval
   fi

   if [ $rval -ne 0 ]
   then
      log_fluff "Walk errored out ($rval)"
      return $rval
   fi

   #
   # sorting lines is harmless and this removes some duplicates too
   # which we would otherwise have to filter
   #
   output2="$(sort -u <<< "${output2}")"

   r_add_line "${output}" "${output2}"
   output="${RVAL}"

   local header
   local separator

   case ",${mode}," in
      *,output-header,*)
         header="Node;treestatus;Filesystem;Sourcetree;Database" # ;Filename"
         if [ "${OPTION_OUTPUT_FILENAME}" = 'YES' ]
         then
            header="${header};Filename;Fetched"
         fi
         case ",${mode}," in
            *,output-separator,*)
               separator="-------;------;----------;------;--------"
               if [ "${OPTION_OUTPUT_FILENAME}" = 'YES' ]
               then
                  separator="${separator};--------;-------"
               fi
               r_add_line "${header}" "${separator}"
               header="${RVAL}"
            ;;
         esac
         r_add_line "${header}" "${output}"
         output="${RVAL}"
      ;;
   esac

   case ",${mode}," in
      *,output-formatted,*)
         printf "%s\n" "${output}" | rexecute_column_table_or_cat ";"
      ;;

      *)
         printf "%s\n" "${output}"
      ;;
   esac
}


sourcetree::status::main()
{
   log_entry "sourcetree::status::main" "$@"

   local OPTION_MARKS="ANY"
   local OPTION_PERMISSIONS=""
   local OPTION_NODETYPES=""
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_DEEP='DEFAULT'
   local OPTION_IS_UPTODATE='NO'
   local OPTION_OUTPUT_HEADER="DEFAULT"
   local OPTION_OUTPUT_FORMAT="FMT"
   local OPTION_OUTPUT_FILENAME='DEFAULT'
   local WALK_DEDUPE_MODE='filename'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::status::usage
         ;;

         --all)
            WALK_DEDUPE_MODE='none'
         ;;

         --deep)
            OPTION_DEEP='YES'
         ;;

         --shallow)
            OPTION_DEEP='NO'
         ;;

         --output-header)
            OPTION_OUTPUT_HEADER='YES'
         ;;

         --no-output-header|--output-no-header)
            OPTION_OUTPUT_HEADER='NO'
         ;;

         --output-filename)
            OPTION_OUTPUT_FILENAME='YES'
         ;;

         --no-output-filename)
            OPTION_OUTPUT_FILENAME='NO'
         ;;

         --output-format)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            case "$1" in
               formatted|fmt)
                  OPTION_OUTPUT_FORMAT="FMT"
               ;;

               cmd|command)
                  OPTION_OUTPUT_FORMAT="CMD"
               ;;

               cmd2|command2)
                  OPTION_OUTPUT_FORMAT="CMD2"
               ;;

               raw|csv)
                 OPTION_OUTPUT_FORMAT="RAW"
               ;;

               *)
                  sourcetree_list_usage "Unknown output format \"$1\""
               ;;
            esac
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

         -*)
            sourcetree::status::usage "Unknown option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree::status::usage "superflous arguments \"$*\""

   if ! sourcetree::cfg::is_config_present "${SOURCETREE_START}"
   then
      log_info "There is no sourcetree here (\"${SOURCETREE_CONFIG_DIR}\")"
      return 0
   fi

   if ! sourcetree::db::is_ready "${SOURCETREE_START}"
   then
      if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
      then
         log_fluff "db is not marked as ready"
         return 2
      fi

      log_fluff "Sync has not run yet (mode=${SOURCETREE_MODE})"
   fi

   local mode

   mode="${SOURCETREE_MODE}"
   if [ "${SOURCETREE_MODE}" != "flat" ]
   then
      r_comma_concat "${mode}" "pre-order"
      mode="${RVAL}"
   fi

   # usually deep, unless --is-uptodate is given or --shallow/--deep explicitly
   if [ "${OPTION_DEEP}" = 'YES' ] || [ "${OPTION_DEEP}" = 'DEFAULT' -a  "${OPTION_IS_UPTODATE}" != 'YES' ]
   then
      r_comma_concat "${mode}" "deep"
      mode="${RVAL}"
   fi
   if [ "${OPTION_OUTPUT_FORMAT}" = 'FMT' ]
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

   sourcetree::status::do "${mode}"
   rval=$?

   case $rval in
      0)
         if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
         then
            log_info "OK"
         fi
         return 0
      ;;

      2|3|4|5|6|7|8|9)
         if [ "${OPTION_IS_UPTODATE}" = 'YES' ]
         then
            log_warning "DIRTY"
         fi
         return 2
      ;;

      *)
         return 1
      ;;
   esac

}


sourcetree::status::initialize()
{
   log_entry "sourcetree::status::initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] &&
         _internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   fi
}


sourcetree::status::initialize

:
