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


sourcetree_list_usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} list [options]

   List nodes in the sourcetree. You can restrict the nodes listed by
   nodetype and marks. The output can be formatted in printf like fashion.

   This command only reads config files.

Options:
   -l                       : output long information
   -ll                      : output full information
   -r                       : recursive list
   -g                       : output branch/tag information (use -G for raw output)
   -u                       : output URL information  (use -U for raw output)
   --nodetypes <value>      : node types to list (default: ALL)
   --marks <value>          : specify marks to match (e.g. build)
   --qualifier <value>      : specify marks qualifier
   --format <format>        : supply a custom format (abfimntu_)
   --output-banner          : print a banner with config information
   --output-format          : possible values (formatted, command, cmd2, raw)
   --output-eval            : show evaluated values as passed to ${MULLE_FETCH:-mulle-fetch}
   --output-full            : show url and various fetch options
   --output-no-header       : suppress header in raw and default lists
   --output-no-marks <list> : suppress output of certain marks (comma sep)
   --output-no-separator    : suppress separator line if header is printed
EOF
  exit 1
}


_sourcetree_banner()
{
   log_entry "_sourcetree_banner" "$@"

   local database="${1:-/}"

   local dbstate
   local dbsharedir

   dbstate="`db_state_description "${database}" `"
   dbsharedir="`db_get_shareddir "${database}" `"

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


r_sourcetree_remove_marks()
{
   log_entry "r_sourcetree_remove_marks" "$@"

   local marks="$1"
   local nomarks="$2"

   RVAL=
   set +f; IFS=","
   for mark in ${marks}
   do
      set +f; IFS="${DEFAULT_IFS}"

      if ! nodemarks_contain "${nomarks}" "${mark}"
      then
         r_comma_concat "${RVAL}" "${mark}"
      fi
   done
   set +f; IFS="${DEFAULT_IFS}"
}


list_walk_callback()
{
   log_entry "list_walk_callback" "$@"

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

   nodeline_parse "${nodeline}"

   if [ ! -z "${OPTION_NO_OUTPUT_MARKS}" ]
   then
      r_sourcetree_remove_marks "${_marks}" "${OPTION_NO_OUTPUT_MARKS}"
      _marks="${RVAL}"
   fi
   node_printf "${_mode}" "${formatstring}" "${cmdline}" "${WALK_INDENT}"
}


_list_sourcetree()
{
   log_entry "_list_sourcetree" "$@"

   local mode="$1"
   local filternodetypes="$2"
   local marksqualifier="$3"
   local formatstring="$4"
   local cmdline="$5"

   nodeline_printf_header "${mode}" "${formatstring}"

   sourcetree_walk "${filternodetypes}" \
                   "" \
                   "${marksqualifier}" \
                   "" \
                   "${mode}" \
                   list_walk_callback "${formatstring}" "${cmdline}"
}


sourcetree_list_sourcetree()
{
   log_entry "sourcetree_list_sourcetree" "$@"

   local mode="$1"

   if ! cfg_exists "${SOURCETREE_START}"
   then
      if [ -z "${IS_PRINTING}" ]
      then
         log_verbose "There is no sourcetree here (${PWD})"
      fi
      return
   fi

   if [ "${OPTION_OUTPUT_BANNER}" = 'YES' ]
   then
      _sourcetree_banner
   fi

   case ",${mode}," in
      *,output_column,*)
         _list_sourcetree "$@" | exekutor column -t -s ';'
      ;;

      *)
         _list_sourcetree "$@"
      ;;
   esac
}


# evil global variable stuff
r_sourcetree_list_convert_marks_to_qualifier()
{
   log_entry "r_sourcetree_list_convert_marks_to_qualifier" "$@"

   local marks="$1"
   local qualifier="$2"

   local mark

   IFS=","; set -o noglob
   for mark in ${marks}
   do
      r_concat "${qualifier}" "MATCHES ${mark}" " AND "
      qualifier="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   RVAL="${qualifier}"
}


r_sourcetree_augment_mode_with_output_options()
{
   log_entry "r_sourcetree_augment_mode_with_output_options" "$@"

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
      address|address-filename|address-url|filename|nodeline|nodeline-no-uuid|none|url|url-filename)
         r_comma_concat "${RVAL}" "dedupe-${OPTION_DEDUPE_MODE}"
      ;;

      *)
         fail "Unknown dedupe mode.
${C_INFO}Choose one of:
${C_RESET}   address address-filename address-url filename nodeline
             nodeline-no-uuid none url url-filename"
      ;;
   esac

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


sourcetree_list_main()
{
   log_entry "sourcetree_list_main" "$@"

   local ROOT_DIR

   ROOT_DIR="`pwd -P`"

   # must be empty initially for set
   local OPTION_OUTPUT_BANNER="DEFAULT"
   local OPTION_OUTPUT_COLOR="DEFAULT"
   local OPTION_OUTPUT_FORMAT="DEFAULT"
   local OPTION_OUTPUT_EVAL="DEFAULT"
   local OPTION_OUTPUT_FULL="DEFAULT"
   local OPTION_OUTPUT_HEADER="" # empty more convenient default
   local OPTION_OUTPUT_INDENT="DEFAULT"
   local OPTION_OUTPUT_SEPARATOR="DEFAULT"
   local OPTION_OUTPUT_COLUMN="DEFAULT"
   local OPTION_OUTPUT_UUID="DEFAULT"
   local OPTION_OUTPUT_URL="DEFAULT"
   local OPTION_UNSAFE='NO'
   local OPTION_OUTPUT_CMDLINE="${MULLE_USAGE_NAME} -N add"
   local OPTION_NODETYPES
   local OPTION_MARKS
   local OPTION_MARKS_QUALIFIER
   local OPTION_FORMAT='DEFAULT'
   local OPTION_DEDUPE_MODE='nodeline-no-uuid'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_list_usage
         ;;

         -m|--marks)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            # allow to concatenate multiple flags
            r_comma_concat "${OPTION_MARKS}" "$1"
            OPTION_MARKS="${RVAL}"
         ;;

         -q|--qualifier)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            # allow to concatenate multiple flags
            OPTION_MARKS_QUALIFIER="$1"
         ;;

         -n|--nodetype|--nodetypes)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            r_comma_concat "${OPTION_NODETYPES}" "$1"
            OPTION_NODETYPES="${RVAL}"

            [ "${OPTION_OUTPUT_INDENT}" = "DEFAULT" ] && OPTION_OUTPUT_INDENT="NO"
         ;;

         --format)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            OPTION_FORMAT="$1"
         ;;

         --output-format)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            case "$1" in
               formatted|fmt)
                  OPTION_OUTPUT_FORMAT="FMT"
               ;;

               cmd|command)
                  OPTION_OUTPUT_FULL='YES'
                  OPTION_OUTPUT_FORMAT="CMD"
               ;;

               cmd2|command2)
                  OPTION_OUTPUT_FULL='YES'
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

         --output-color)
            OPTION_OUTPUT_COLOR='YES'
         ;;

         --no-output-color|--output-no-color)
            OPTION_OUTPUT_COLOR='NO'
         ;;

         --output-column)
            OPTION_OUTPUT_COLUMN='YES'
         ;;

         --no-output-column|--output-no-column)
            OPTION_OUTPUT_COLUMN='NO'
         ;;

         --output-header)
            OPTION_OUTPUT_HEADER='YES'
         ;;

         --no-output-header|--output-no-header)
            OPTION_OUTPUT_HEADER='NO'
         ;;

         --output-separator)
            OPTION_OUTPUT_SEPARATOR='YES'
         ;;

         --no-output-separator|--output-no-separator)
            OPTION_OUTPUT_SEPARATOR='NO'
         ;;

         --no-output-indent)
            OPTION_OUTPUT_INDENT='NO'
         ;;

         --no-dedupe)
            OPTION_DEDUPE_MODE="none"
         ;;

         --dedupe-mode)
            [ $# -eq 1 ] && sourcetree_walk_usage "Missing argument to \"$1\""
            shift

            OPTION_DEDUPE_MODE="$1"
         ;;

         #
         #
         #
         -g|--output-git)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%t!;%b!\\n"
            else
               OPTION_FORMAT="${OPTION_FORMAT%??}"
               OPTION_FORMAT="${OPTION_FORMAT};%t!;%b!\\n"
            fi
         ;;

         -G)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%t;%b\\n"
            else
               OPTION_FORMAT="${OPTION_FORMAT%??}"
               OPTION_FORMAT="${OPTION_FORMAT};%t;%b\\n"
            fi
         ;;

         -l|--output-more)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%n;%m\\n"
            else
               OPTION_FORMAT="${OPTION_FORMAT%??}"
               OPTION_FORMAT="${OPTION_FORMAT};%n;%m\\n"
            fi
         ;;

         -r)
            FLAG_SOURCETREE_MODE="share"
         ;;

         -u)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%u!;%f\\n"
            else
               OPTION_FORMAT="${OPTION_FORMAT%??}"
               OPTION_FORMAT="${OPTION_FORMAT};%u!;%f\\n"
            fi
         ;;

         -U)
            if [ "${OPTION_FORMAT}" = 'DEFAULT' ]
            then
               OPTION_FORMAT="%a;%u;%f\\n"
            else
               OPTION_FORMAT="${OPTION_FORMAT%??}"
               OPTION_FORMAT="${OPTION_FORMAT};%u;%f\\n"
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

         --output-uuid)
            OPTION_OUTPUT_UUID='YES'
         ;;

         --no-output-uuid|--output-no-uuid)
            OPTION_OUTPUT_UUID='NO'
         ;;

         --output-banner)
            OPTION_OUTPUT_BANNER='YES'
         ;;

         --no-output-banner|--output-no-banner)
            OPTION_OUTPUT_BANNER='NO'
         ;;

         --output-eval)
            OPTION_OUTPUT_EVAL='YES'
         ;;

         --no-output-eval|--output-no-eval)
            OPTION_OUTPUT_EVAL='NO'
         ;;

         --no-output-marks|--output-no-marks)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            OPTION_NO_OUTPUT_MARKS="$1"
         ;;

         --output-cmdline)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            OPTION_OUTPUT_CMDLINE="$1"
         ;;

         -*)
            sourcetree_list_usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ -z "${DEFAULT_IFS}" ] && internal_fail "IFS fail"

   local _address
   local _url
   local key
   local mark
   local mode

   [ -z "${SOURCETREE_CONFIG_FILENAME}" ] && fail "Config filename is empty"

   [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && sourcetree_list_usage


   # if mode is not flat, we use output-banner by default
   if [ "${OPTION_OUTPUT_BANNER}" = "DEFAULT" ]
   then
      OPTION_OUTPUT_BANNER='NO'
   fi

   local mode

   #
   # generally we use flat, if the user didn't indicate otherwise
   # via flags
   #
   r_sourcetree_augment_mode_with_output_options "${FLAG_SOURCETREE_MODE:-flat}"
   mode="${RVAL}"

   r_sourcetree_list_convert_marks_to_qualifier "${OPTION_MARKS}" "${OPTION_MARKS_QUALIFIER}" ## UGLY
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

   sourcetree_list_sourcetree "${mode}" \
                              "${OPTION_NODETYPES}" \
                              "${OPTION_MARKS_QUALIFIER}" \
                              "${OPTION_FORMAT}" \
                              "${OPTION_OUTPUT_CMDLINE}"
}


sourcetree_list_initialize()
{
   log_entry "sourcetree_list_initialize"

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   fi
}


sourcetree_list_initialize

:
