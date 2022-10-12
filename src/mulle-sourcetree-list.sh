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
MULLE_SOURCETREE_LIST_SH="included"


sourcetree::list::dedupe_mode_help()
{
   cat <<EOF
   address                       : address
   address-filename              : combination of address and filename
   address-marks-filename        : combination of address marks url
   address-url                   : combination of address and url
   filename                      : name where sync will place it
   hacked-marks-nodeline-no-uuid : the default
   linkorder                     : used by linkorder
   nodeline                      : all fields
   nodeline-no-uuid              : all fields except uuid
   none                          : no dedupe
   url-filename                  : combination of url and filename
EOF
}


sourcetree::list::usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} list [options]

   List nodes in the sourcetree. You can restrict the nodes listed by
   nodetype and marks. The output can be formatted in printf like fashion.
   You can also list as mulle-sourcetree shell commands, to copy parts of
   the sourcetree to another project.

   This command only reads config files.

   A '-' indicates a no-bequeath entry.
   A '*' indicates a duplicate (most often conflicting marks). Use the 
        \`${MULLE_USAGE_NAME} star-search\` command to list duplicates by name.

   Use the \`mulle-sourcetree-export-json\` command to list the current config in
   JSON format.

EOF

   if [ "${MULLE_FLAG_LOG_VERBOSE}" = 'YES' ]
   then
      cat <<EOF >&2

Formatting:
EOF
      sourcetree::node::printf_format_help >&2
      cat <<EOF >&2

Deduping:
EOF
      sourcetree::list::dedupe_mode_help >&2
   else
      cat <<EOF >&2
   Use \`mulle-sourcetree -v list help\` to see a list of format characters.
EOF
   fi

   cat <<EOF >&2

Options:
   -l                       : output long information
   -ll                      : output full information (except UUID)
   -g                       : output branch/tag information (-G for raw output)
   -m                       : output marks
   -r                       : recursive list
   -u                       : output URL information  (use -U for raw output)
   --bequeath               : inherit from nodes marked no-bequeath
   --no-bequeath            : don't inherit from no-bequeath nodes (default)
   --config-file <file>     : list a specific config file (no recursion)
   --dedupe-mode <mode>     : change the way duplicates are detected
   --format <format>        : supply a custom format (abfimntu_)
   --marks <value>          : specify marks to match (e.g. build)
   --no-dedupe              : don't remove what are considered duplicates
   --nodetype <value>       : node type to list, can be used multiple times
   --output-banner          : print a banner with config information
   --output-eval            : show evaluated values as passed to ${MULLE_FETCH:-mulle-fetch}
   --output-format <value>  : possible values (fmt, cmd, raw)
   --output-full            : show url and various fetch options
   --output-no-column       : don't columnize output
   --output-no-header       : suppress header in raw and default lists
   --output-no-indent       : suppress indentation on recursive list
   --output-no-marks <list> : suppress output of certain marks (comma sep)
   --output-no-separator    : suppress separator line if header is printed
   --output-uuid            : print the UUID of each line
   --qualifier <value>      : specify marks qualifier (see \`walk\` command)

EOF
  exit 1
}


sourcetree::list::_sourcetree_banner()
{
   log_entry "sourcetree::list::_sourcetree_banner" "$@"

   local database="${1:-/}"

   local dbstate
   local dbsharedir

   dbstate="`sourcetree::db::state_description "${database}" `"
   dbsharedir="`sourcetree::db::get_shareddir "${database}" `"

   printf "%b\n" "${C_INFO}--------------------------------------------------${C_RESET}"
   printf "%b\n" "${C_INFO}Sourcetree   : ${C_RESET_BOLD}${PWD}${C_RESET}"
   printf "%b\n" "${C_INFO}Database     : ${C_MAGENTA}${C_BOLD}${dbstate}${C_RESET}"
   printf "%b\n" "${C_INFO}Mode         : ${C_MAGENTA}${C_BOLD}${SOURCETREE_MODE}${C_RESET}"

   case "${SOURCETREE_MODE}" in
      share)
         if [ ! -z "${dbsharedir}" ]
         then
            printf "%b\n" "${C_INFO}DB  Sharedir : ${C_RESET_BOLD}${dbsharedir}${C_RESET}"
         fi

         if [ ! -z "${MULLE_SOURCETREE_STASH_DIR}" ]
         then
            printf "%b\n" "${C_INFO}ENV Sharedir : \
${C_RESET_BOLD}${MULLE_SOURCETREE_STASH_DIR}${C_RESET}"
         fi
      ;;
   esac

   printf "%b\n" "${C_INFO}--------------------------------------------------${C_RESET}"
}


sourcetree::list::r_remove_marks()
{
   log_entry "sourcetree::list::r_remove_marks" "$@"

   local marks="$1"
   local nomarks="$2"

   RVAL=
   shell_disable_glob; IFS=","
   for mark in ${marks}
   do
      shell_enable_glob; IFS="${DEFAULT_IFS}"

      if ! sourcetree::nodemarks::contain "${nomarks}" "${mark}"
      then
         r_comma_concat "${RVAL}" "${mark}"
      fi
   done
   shell_enable_glob; IFS="${DEFAULT_IFS}"
}


sourcetree::list::walk_callback()
{
   log_entry "sourcetree::list::walk_callback" "$@"

   local formatstring="$1"
   local cmdline="$2"

   local nodeline

   nodeline="${_nodeline}"

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _userinfo
   local _uuid
   local _raw_userinfo

   sourcetree::nodeline::parse "${nodeline}"  # !!

   if [ ! -z "${OPTION_NO_OUTPUT_MARKS}" ]
   then
      sourcetree::list::r_remove_marks "${_marks}" "${OPTION_NO_OUTPUT_MARKS}"
      _marks="${RVAL}"
   fi

   local indent

   if [ "${OPTION_OUTPUT_INDENT}" != 'NO' ]
   then
      indent="${WALK_INDENT}"
   fi

   if sourcetree::nodemarks::disable "${_marks}" "bequeath" || \
      sourcetree::nodemarks::disable "${_marks}" "bequeath-os-${MULLE_UNAME}"
   then
      if [ "${OPTION_OUTPUT_INDENT}" != 'NO' ]
      then
         indent="-${WALK_INDENT# }"
      fi
      log_verbose "no-bequeath: ${_address}"
      sourcetree::node::printf "${_mode}" "${formatstring}" "${cmdline}" "${indent}"
   else
      if [ "${_nodetype}" != 'none' ] && find_line "${DUPLICATES}" "${_address}"
      then
         if [ "${OPTION_OUTPUT_INDENT}" != 'NO' ]
         then
            indent="*${WALK_INDENT# }"
         fi
         log_verbose "Duplicate: ${_address}"
         sourcetree::node::printf "${_mode}" "${formatstring}" "${cmdline}" "${indent}"
      else
         r_add_line "${DUPLICATES}" "${_address}"
         DUPLICATES="${RVAL}"

         sourcetree::node::printf "${_mode}" "${formatstring}" "${cmdline}" "${indent}"
      fi
   fi
}


sourcetree::list::walk()
{
   log_entry "sourcetree::list::walk" "$@"

   local mode="$1"
   local filternodetypes="$2"
   local marksqualifier="$3"
   local formatstring="$4"
   local cmdline="$5"

   sourcetree::nodeline::printf_header "${mode}" "${formatstring}"

   local DUPLICATES

   DUPLICATES=""
   sourcetree::walk::do "${filternodetypes}" \
                        "" \
                        "${marksqualifier}" \
                        "" \
                        "${mode}" \
                        sourcetree::list::walk_callback "${formatstring}" "${cmdline}"
}


sourcetree::list::do()
{
   log_entry "sourcetree::list::do" "$@"

   local mode="$1"

   if ! sourcetree::cfg::r_config_exists "${SOURCETREE_START}"
   then
      if [ -z "${IS_PRINTING}" ]
      then
         log_verbose "There is no sourcetree here (${PWD})"
      fi
      return 0
   fi

   if [ "${OPTION_OUTPUT_BANNER}" = 'YES' ]
   then
      sourcetree::list::_sourcetree_banner
   fi

   local result 
   
   case ",${mode}," in
      *,output_column,*)
         ( sourcetree::list::walk "$@" ; echo )  | rexecute_column_table_or_cat ';'
      ;;

      *)
         sourcetree::list::walk "$@"
      ;;
   esac
}


# evil global variable stuff
sourcetree::list::r_convert_marks_to_qualifier()
{
   log_entry "sourcetree::list::r_convert_marks_to_qualifier" "$@"

   local marks="$1"
   local qualifier="$2"

   local mark

   IFS=","; shell_disable_glob
   for mark in ${marks}
   do
      r_concat "${qualifier}" "MATCHES ${mark}" " AND "
      qualifier="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   RVAL="${qualifier}"
}


sourcetree::list::r_augment_mode_with_output_options()
{
   log_entry "sourcetree::list::r_augment_mode_with_output_options" "$@"

   local mode="$1"

   RVAL="${mode}"

   case ",${mode}," in
      *,flat,*|*,pre-order,*|*,post-order,*|*,breadth-order,*)
      ;;

      *)
         r_comma_concat "${RVAL}" "pre-order"
      ;;
   esac

   case "${OPTION_DEDUPE_MODE}" in
      address|address-filename|address-marks-filename|address-url|filename|\
hacked-marks-nodeline-no-uuid|\
linkorder|nodeline|nodeline-no-uuid|none|url|url-filename)
         r_comma_concat "${RVAL}" "dedupe-${OPTION_DEDUPE_MODE}"
      ;;

      *)
         fail "Unknown dedupe mode \"${OPTION_DEDUPE_MODE}\".
${C_INFO}Choose one of:
${C_RESET}   address address-filename address-url filename nodeline
             nodeline-no-uuid none url url-filename"
      ;;
   esac

   # this is the default for listing, ignore the bequeath flags
   if [ "${OPTION_BEQUEATH}" = 'NO' ]
   then
      r_comma_concat "${RVAL}" "no-bequeath"
   fi

   if [ "${OPTION_OUTPUT_URL}" != 'NO' ]
   then
      r_comma_concat "${RVAL}" "output_url"
   fi
   if [ "${OPTION_OUTPUT_FULL}" = 'YES' ]
   then
      r_comma_concat "${RVAL}" "output_full"
   fi
   if [ "${OPTION_OUTPUT_EVAL}" = 'YES' ]
   then
      r_comma_concat "${RVAL}" "output_eval"
   fi
   if [ "${OPTION_OUTPUT_UUID}" = 'YES' ]
   then
      r_comma_concat "${RVAL}" "output_uuid"
   fi

   case "${OPTION_OUTPUT_FORMAT}" in
      "RAW")
         r_comma_concat "${RVAL}" "output_raw"
         if [ "${OPTION_OUTPUT_HEADER}" != 'NO' ]
         then
            r_comma_concat "${RVAL}" "output_header"
         fi
         OPTION_OUTPUT_CMDLINE=""
      ;;

      "CMD")
         r_comma_concat "${RVAL}" "output_cmd"
      ;;

      "CMD2")
         r_comma_concat "${RVAL}" "output_cmd2"
      ;;

      *)
         [ -z "`command -v column`" ] && fail "Tool \"column\" is not available, use --output-format raw"

         if [ "${OPTION_OUTPUT_HEADER}" != 'NO' ]
         then
            r_comma_concat "${RVAL}" "output_header"
            if [ "${OPTION_OUTPUT_SEPARATOR}" != 'NO' ]
            then
               r_comma_concat "${RVAL}" "output_separator"
            fi
         fi

         if [ "${OPTION_OUTPUT_COLUMN}" != 'NO' ]
         then
            r_comma_concat "${RVAL}" "output_column"
         fi
         OPTION_OUTPUT_CMDLINE=""
      ;;
   esac

   if [ "${OPTION_OUTPUT_INDENT}" = 'NO' ]
   then
      r_comma_concat "${RVAL}" "no-indent"
   fi
}


sourcetree::list::r_add_format()
{
   log_entry "sourcetree::list::r_add_format" "$@"

   case ";$1;" in
      *\;$2\;*)
         RVAL="$1"
      ;;

      *\\n\;)
         # remove escaped linefeed
         # append format character
         RVAL="${1%??};$2\\n"
      ;;

      *)
         RVAL="$1;$2"
      ;;
   esac
}


sourcetree::list::warn_if_sync_outstanding()
{
   local memo 
   local rval 

   if [ -z "${MULLE_SOURCETREE_DBSTATUS_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-dbstatus.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-dbstatus.sh" || exit 1
   fi      

   memo="${MULLE_FLAG_LOG_TERSE}"
   MULLE_FLAG_LOG_TERSE='YES'
   sourcetree::dbstatus::main
   rval=$?
   MULLE_FLAG_LOG_TERSE="${memo}"

   if [ $rval -eq 2 ]
   then
      log_warning "Listing will be complete after a sync (${PWD#${MULLE_USER_PWD}/})."
   fi   
}

sourcetree::list::main()
{
   log_entry "sourcetree::list::main" "$@"

   # must be empty initially for set
   local OPTION_OUTPUT_BANNER='DEFAULT'
   local OPTION_OUTPUT_COLOR='DEFAULT'
   local OPTION_OUTPUT_FORMAT='DEFAULT'
   local OPTION_OUTPUT_EVAL='DEFAULT'
   local OPTION_OUTPUT_FULL='DEFAULT'
   local OPTION_OUTPUT_HEADER="" # empty more convenient default
   local OPTION_OUTPUT_INDENT='DEFAULT'
   local OPTION_OUTPUT_SEPARATOR='DEFAULT'
   local OPTION_OUTPUT_COLUMN='DEFAULT'
   local OPTION_OUTPUT_UUID='DEFAULT'
   local OPTION_OUTPUT_URL='DEFAULT'
   local OPTION_OUTPUT_CMDLINE="${MULLE_USAGE_NAME} -N add"
   local OPTION_NODETYPES
   local OPTION_BEQUEATH='NO'
   local OPTION_MARKS
   local OPTION_MARKS_QUALIFIER
   local OPTION_FORMAT='DEFAULT'
   local OPTION_DEDUPE_MODE='hacked-marks-nodeline-no-uuid'
   local OPTION_CONFIG_FILE='DEFAULT'
   local OPTION_NO_OUTPUT_MARKS

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::list::usage
         ;;

         --bequeath)
            OPTION_BEQUEATH='YES'
         ;;

         --no-bequeath)
            OPTION_BEQUEATH='NO'
         ;;

         --config-file)
            [ $# -eq 1 ] && sourcetree::list::usage "Missing argument to \"$1\""
            shift

            OPTION_CONFIG_FILE="$1"
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

            [ "${OPTION_OUTPUT_INDENT}" = "DEFAULT" ] && OPTION_OUTPUT_INDENT="NO"
         ;;

         --qualifier)
            [ $# -eq 1 ] && sourcetree::list::usage "Missing argument to \"$1\""
            shift

            # allow to concatenate multiple flags
            OPTION_MARKS_QUALIFIER="$1"
         ;;

         --dedupe-mode)
            [ $# -eq 1 ] && sourcetree::walk::usage "Missing argument to \"$1\""
            shift

            OPTION_DEDUPE_MODE="$1"
         ;;

         --no-dedupe)
            OPTION_DEDUPE_MODE="none"
         ;;

         --format)
            [ $# -eq 1 ] && sourcetree::list::usage "Missing argument to \"$1\""
            shift

            OPTION_FORMAT="$1"
         ;;

         --output-format)
            [ $# -eq 1 ] && sourcetree::list::usage "Missing argument to \"$1\""
            shift

            case "$1" in
               formatted|fmt)
                  OPTION_OUTPUT_FORMAT="FMT"
               ;;

               cmd|command)
                  OPTION_OUTPUT_FULL='YES'
                  OPTION_OUTPUT_FORMAT="CMD"
                  OPTION_OUTPUT_INDENT='NO'
               ;;

               cmd2|command2)
                  OPTION_OUTPUT_FULL='YES'
                  OPTION_OUTPUT_FORMAT="CMD2"
                  OPTION_OUTPUT_INDENT='NO'
               ;;

               raw|csv)
                 OPTION_OUTPUT_FORMAT="RAW"
                 OPTION_OUTPUT_INDENT='NO'
               ;;

               *)
                  sourcetree::list::usage "Unknown output format \"$1\""
               ;;
            esac
         ;;

         #
         #
         #
         -_|--output-uuid)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%_;%a\\n" #prepend
            else
               OPTION_FORMAT="%_;${OPTION_FORMAT}"
            fi
            OPTION_OUTPUT_UUID='YES' # needed for -ll
         ;;

         -g|--output-git)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%t!;%b!\\n"
            else
               sourcetree::list::r_add_format "${OPTION_FORMAT}" "%t!"
               sourcetree::list::r_add_format "${RVAL}" "%b!"
               OPTION_FORMAT="${RVAL}"
            fi
         ;;

         -G)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%t;%b\\n"
            else
               sourcetree::list::r_add_format "${OPTION_FORMAT}" "%t"
               sourcetree::list::r_add_format "${RVAL}" "%b"
               OPTION_FORMAT="${RVAL}"
            fi
         ;;

         -l|--output-more)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%n;%m\\n"
            else
               sourcetree::list::r_add_format "${OPTION_FORMAT}" "%n"
               sourcetree::list::r_add_format "${RVAL}" "%m"
               OPTION_FORMAT="${RVAL}"
            fi
         ;;

         -m|--output-marks)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%m\\n"
            else
               sourcetree::list::r_add_format "${RVAL}" "%m"
               OPTION_FORMAT="${RVAL}"
            fi
         ;;

         -r)
            FLAG_SOURCETREE_MODE="share"
            sourcetree::list::r_add_format "%v={WALK_DEPENDENCY}" "${OPTION_FORMAT}"
            OPTION_FORMAT="${RVAL}"
         ;;

         -m)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%m\\n"
            else
               sourcetree::list::r_add_format "${OPTION_FORMAT}" "%m"
               OPTION_FORMAT="${RVAL}"
            fi
            OPTION_NO_OUTPUT_MARKS=NO
         ;;

         -u)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%u!;%f\\n"
            else
               sourcetree::list::r_add_format "${OPTION_FORMAT}" "%u!"
               sourcetree::list::r_add_format "${RVAL}" "%f"
               OPTION_FORMAT="${RVAL}"
            fi
         ;;

         -U)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%u;%f\\n"
            else
               sourcetree::list::r_add_format "${OPTION_FORMAT}" "%u"
               sourcetree::list::r_add_format "${RVAL}" "%f"
               OPTION_FORMAT="${RVAL}"
            fi
         ;;

         -ll|--output-full)
            OPTION_OUTPUT_FULL='YES'
         ;;

         --output-url)
            OPTION_OUTPUT_URL='YES'
         ;;

         --no-output-url|--output-no-url)
            OPTION_OUTPUT_URL='NO'
         ;;

         --output-banner)
            OPTION_OUTPUT_BANNER='YES'
         ;;

         --no-output-banner|--output-no-banner)
            OPTION_OUTPUT_BANNER='NO'
         ;;

         --output-color)
            OPTION_OUTPUT_COLOR='YES'
         ;;

         --no-output-color|--output-no-color)
            OPTION_OUTPUT_COLOR='NO'
         ;;

         --output-cmdline)
            [ $# -eq 1 ] && sourcetree::list::usage "Missing argument to \"$1\""
            shift

            OPTION_OUTPUT_CMDLINE="$1"
         ;;

         --output-column)
            OPTION_OUTPUT_COLUMN='YES'
         ;;

         --no-output-column|--output-no-column)
            OPTION_OUTPUT_COLUMN='NO'
         ;;

         --output-eval)
            OPTION_OUTPUT_EVAL='YES'
         ;;

         --no-output-eval|--output-no-eval)
            OPTION_OUTPUT_EVAL='NO'
         ;;

         --output-header)
            OPTION_OUTPUT_HEADER='YES'
         ;;

         --no-output-header|--output-no-header)
            OPTION_OUTPUT_HEADER='NO'
         ;;

         --no-output-indent|--output-no-indent)
            OPTION_OUTPUT_INDENT='NO'
         ;;

         --no-output-marks|--output-no-marks)
            [ $# -eq 1 ] && sourcetree::list::usage "Missing argument to \"$1\""
            shift

            OPTION_NO_OUTPUT_MARKS="$1"
         ;;

         --output-separator)
            OPTION_OUTPUT_SEPARATOR='YES'
         ;;

         --no-output-separator|--output-no-separator)
            OPTION_OUTPUT_SEPARATOR='NO'
         ;;

         -*)
            sourcetree::list::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${DEFAULT_IFS}" ] && _internal_fail "IFS fail"

   [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && sourcetree::list::usage

   if [ "${OPTION_CONFIG_FILE}" != 'DEFAULT' ]
   then
      # hack hack hacky hack
      r_basename "${OPTION_CONFIG_FILE}"
      SOURCETREE_CONFIG_NAMES="${RVAL}"
      SOURCETREE_FALLBACK_CONFIG_DIR=

      r_dirname "${OPTION_CONFIG_FILE}"
      r_physicalpath "${RVAL}"
      MULLE_VIRTUAL_ROOT="${RVAL}"

      log_fluff "mulle-sourcetree (list) sets MULLE_VIRTUAL_ROOT to \"${MULLE_VIRTUAL_ROOT}\""

      FLAG_SOURCETREE_MODE="flat"
   fi

   [ -z "${SOURCETREE_CONFIG_DIR}" ]   && fail "SOURCETREE_CONFIG_DIR is empty"
   [ -z "${SOURCETREE_CONFIG_NAMES}" ] && fail "SOURCETREE_CONFIG_NAMES is empty"

   if [ "${FLAG_SOURCETREE_MODE}" = "share" ]
   then
      sourcetree::list::warn_if_sync_outstanding
   fi

   # if mode is not flat, we use output-banner by default
   if [ "${OPTION_OUTPUT_BANNER}" = "DEFAULT" ]
   then
      OPTION_OUTPUT_BANNER='NO'
   fi

   if [ "${OPTION_OUTPUT_INDENT}" = "DEFAULT" ]
   then
      if [ "${FLAG_SOURCETREE_MODE}" = 'share' ]
      then
         OPTION_OUTPUT_INDENT='YES'
      else
         OPTION_OUTPUT_INDENT='NO'
      fi
   fi

   local mode

   #
   # generally we use flat, if the user didn't indicate otherwise
   # via flags
   #
   sourcetree::list::r_augment_mode_with_output_options "${FLAG_SOURCETREE_MODE:-flat}"
   mode="${RVAL}"

   r_comma_concat "${mode}" "comments"
   mode="${RVAL}"

   sourcetree::list::r_convert_marks_to_qualifier "${OPTION_MARKS}" "${OPTION_MARKS_QUALIFIER}" ## UGLY
   OPTION_MARKS_QUALIFIER="${RVAL}"

   if [ "${OPTION_OUTPUT_FULL}" = 'YES' ]
   then
      OPTION_FORMAT=
   else
      if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
      then
         OPTION_FORMAT='%a\n'
      fi
   fi

   sourcetree::list::do "${mode}" \
                        "${OPTION_NODETYPES}" \
                        "${OPTION_MARKS_QUALIFIER}" \
                        "${OPTION_FORMAT}" \
                        "${OPTION_OUTPUT_CMDLINE}"
}


sourcetree::list::initialize()
{
   log_entry "sourcetree::list::initialize"

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   fi
}


sourcetree::list::initialize

:
