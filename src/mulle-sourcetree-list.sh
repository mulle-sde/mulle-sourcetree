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
   --nodetypes <value>      : node types to list (default: ALL)
   --marks <value>          : specify marks to match (e.g. build)
   --qualifier <value>      : specify marks qualifier
   --format <format>        : supply a custom format (abfimntu_)
   --output-banner          : print a banner with config information
   --output-cmd             : output as ${MULLE_EXECUTABLE_NAME} command line
   --output-eval            : show evaluated values as passed to ${MULLE_FETCH:-mulle-fetch}
   --output-full            : show url and various fetch options
   --output-no-header       : suppress header in raw and default lists
   --output-no-marks <list> : suppress output of certain marks (comma sep)
   --output-no-separator    : suppress separator line if header is printed
   --output-raw             : output as CSV (semicolon separated values)
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
   printf "%b\n" "${C_INFO}Sourcetree : ${C_RESET_BOLD}${PWD}${C_RESET}"
   printf "%b\n" "${C_INFO}Database   : ${C_MAGENTA}${C_BOLD}${dbstate}${C_RESET}"

   if [ ! -z "${dbsharedir}" ]
   then
      printf "%b\n" "${C_INFO}Sharedir   : ${C_RESET_BOLD}${dbsharedir}${C_RESET}"
   fi

   case "${SOURCETREE_MODE}" in
      share)
         if [ ! -z "${MULLE_SOURCETREE_SHARE_DIR}" ]
         then
            printf "%b\n" "${C_INFO}Shared directory: \
${C_RESET_BOLD}${MULLE_SOURCETREE_SHARE_DIR}${C_RESET}"
         fi
      ;;
   esac

   printf "%b\n" "${C_INFO}--------------------------------------------------${C_RESET}"
}


_sourcetree_augment_mode_with_output_options()
{
   log_entry "_sourcetree_augment_mode_with_output_options" "$@"

   local mode="$1"

   if [ "${OPTION_OUTPUT_URL}" != "NO" ]
   then
      mode="`concat "${mode}" "output_url"`"
   fi
   if [ "${OPTION_OUTPUT_FULL}" = "YES" ]
   then
      mode="`concat "${mode}" "output_full"`"
   fi
   if [ "${OPTION_OUTPUT_EVAL}" = "YES" ]
   then
      mode="`concat "${mode}" "output_eval"`"
   fi
   if [ "${OPTION_OUTPUT_UUID}" = "YES" ]
   then
      mode="`concat "${mode}" "output_uuid"`"
   fi

   case "${OPTION_OUTPUT_FORMAT}" in
      "RAW")
         mode="`concat "${mode}" "output_raw"`"
         if [ "${OPTION_OUTPUT_HEADER}" != "NO" ]
         then
            mode="`concat "${mode}" "output_header"`"
         fi
      ;;

      "CMD")
         mode="`concat "${mode}" "output_cmd"`"
      ;;

      *)
         [ -z "`command -v column`" ] && fail "Tool \"column\" is not available, use --output-raw"

         if [ "${OPTION_OUTPUT_HEADER}" != "NO" ]
         then
            mode="`concat "${mode}" "output_header"`"
            if [ "${OPTION_OUTPUT_SEPARATOR}" != "NO" ]
            then
               mode="`concat "${mode}" "output_separator"`"
            fi
         fi

         if [ "${OPTION_OUTPUT_COLUMN}" != "NO" ]
         then
            mode="`concat "${mode}" "output_column"`"
         fi
      ;;
   esac

   echo "${mode}"
}


_sourcetree_nodeline_remove_marks()
{
   log_entry "_sourcetree_nodeline_remove_marks" "$@"

   local nodeline="$1"
   local nomarks="$2"

   local _branch
   local _address
   local _fetchoptions
   local _nodetype
   local _marks
   local _tag
   local _raw_userinfo
   local _url
   local _uuid
   local _userinfo

   nodeline_parse "${nodeline}"

   local marks

   marks="${_marks}"
   _marks=

   set -f; IFS=","
   for mark in ${marks}
   do
      if ! nodemarks_contain "${nomarks}" "${mark}"
      then
         _marks="`comma_concat "${_marks}" "${mark}" `"
      fi
   done
   set +f; IFS="${DEFAULT_IFS}"

   node_to_nodeline
}


_sourcetree_contents()
{
   log_entry "_sourcetree_contents" "$@"

   local mode="$1"
   local filternodetypes="$2"
   local marksqualifier="$3"
   local formatstring="$4"

   local nodeline
   local nodelines

   nodelines="`cfg_read "${SOURCETREE_START}"`" || exit 1

   nodeline_printf_header "${mode}" "${formatstring}"

   set -o noglob ; IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      if [ -z "${nodeline}" ]
      then
         continue
      fi

      local _address
      local _nodetype
      local _marks

      __nodeline_get_address_nodetype_marks "${nodeline}"

      if ! nodetype_filter "${_nodetype}" "${filternodetypes}"
      then
         log_fluff "Node \"${nodeline}\": \"${_nodetype}\" doesn't jive with nodetypes filter \"${filternodetypes}\""
         continue
      fi

      if ! nodemarks_filter_with_qualifier "${_marks}" "${marksqualifier}"
      then
         log_fluff "Node \"${nodeline}\": \"${_marks}\" doesn't jive with marks \"${marksqualifier}\""
         continue
      fi

      if [ ! -z "${OPTION_NO_OUTPUT_MARKS}" ]
      then
         nodeline="`_sourcetree_nodeline_remove_marks "${nodeline}" "${OPTION_NO_OUTPUT_MARKS}" `"
      fi

      nodeline_printf "${nodeline}" "${mode}" "${formatstring}"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


_list_nodes()
{
   log_entry "_list_nodes" "$@"

   local mode="$1"

   if ! cfg_exists "${SOURCETREE_START}"
   then
      if [ -z "${IS_PRINTING}" ]
      then
         log_verbose "There is no sourcetree here (${PWD})"
      fi
      return
   fi

   if [ "${OPTION_OUTPUT_BANNER}" = "YES" ] ||
      [ "${OPTION_OUTPUT_BANNER}" = "DEFAULT" -a "${OPTION_OUTPUT_FORMAT}" = "FMT" ]
   then
      _sourcetree_banner
   fi

   case "${mode}" in
      *output_column*)
         _sourcetree_contents "$@" | exekutor column -t -s ';'
      ;;

      *)
         _sourcetree_contents "$@"
      ;;
   esac
}


emit_commandline_flag()
{
   log_entry "emit_commandline_flag" "$@"

   local value="$1"
   local flag="$2"

   case "${value}" in
      "NO")
         echo "--no-${flag}"
      ;;

      "YES")
         echo "--${flag}"
      ;;
   esac
}


list_nodes()
{
   log_entry "list_nodes" "$@"

   local rval
   local formatstring="$4"

   _list_nodes "$@"
   rval=$?

   if [ "${SOURCETREE_MODE}" = "flat" ]
   then
      return $rval
   fi

   # shellcheck source=src/mulle-sourcetree-walk.sh
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh"

   local arguments
   local flag

   arguments=

   if [ ! -z "${formatstring}" ]
   then
      arguments="`concat "${arguments}" "--format" `"
      arguments="`concat "${arguments}" "${formatstring}" `"
   fi

   flag="`emit_commandline_flag "${OPTION_OUTPUT_BANNER}" "output-banner" `"
   arguments="`concat "${arguments}" "${flag}" `"

   flag="`emit_commandline_flag "${OPTION_OUTPUT_EVAL}" "output-eval" `"
   arguments="`concat "${arguments}" "${flag}" `"

   flag="`emit_commandline_flag "${OPTION_OUTPUT_UUID}" "output-uuid" `"
   arguments="`concat "${arguments}" "${flag}" `"

   flag="`emit_commandline_flag "${OPTION_OUTPUT_FULL}" "output-full" `"
   arguments="`concat "${arguments}" "${flag}" `"

   flag="`emit_commandline_flag "${OPTION_OUTPUT_SEPARATOR}" "output-separator" `"
   arguments="`concat "${arguments}" "${flag}" `"

   flag="`emit_commandline_flag "${OPTION_OUTPUT_COLOR}" "output-color" `"
   arguments="`concat "${arguments}" "${flag}" `"


#   if [ "${OPTION_OUTPUT_HEADER}" = "NO" ]
#   then
#      arguments="`concat "${arguments}" "--no-output-header" `"
#   fi

   case "${OPTION_OUTPUT_FORMAT}" in
      "RAW")
         arguments="`concat "${arguments}" "--output-raw" `"
         if [ -z "${OPTION_OUTPUT_HEADER}" ]
         then
            OPTION_OUTPUT_HEADER="NO"
         fi
      ;;

      "CMD")
         arguments="`concat "${arguments}" "--output-cmd" `"
         OPTION_OUTPUT_HEADER="NO"
      ;;

      "FMT")
         arguments="`concat "${arguments}" "--output-fmt" `"
         if [ -z "${OPTION_OUTPUT_HEADER}" ]
         then
            if [ "${IS_PRINTING}" != "YES" ]
            then
               OPTION_OUTPUT_HEADER="NO"
            else
               OPTION_OUTPUT_HEADER="YES"
            fi
         fi
      ;;
   esac

   #
   # some special treatment
   #
   flag="`emit_commandline_flag "${OPTION_OUTPUT_HEADER}" "output-header" `"
   arguments="`concat "${arguments}" "${flag}" `"

   IS_PRINTING="YES"; export IS_PRINTING

   sourcetree_walk_main --pre-order --cd \
         "${MULLE_EXECUTABLE}" "${MULLE_TECHNICAL_FLAGS}" --flat -e list ${arguments}
}


# evil global variable stuff
_sourcetree_list_convert_marks_to_qualifier()
{
   if [ ! -z "${OPTION_MARKS}" ]
   then
      if [ ! -z "${OPTION_MARKS_QUALIFIER}" ]
      then
         fail "You can not specify --marks and --qualifier at the same time"
      fi

      local mark

      IFS=","; set -o noglob
      for mark in ${OPTION_MARKS}
      do
         OPTION_MARKS_QUALIFIER="`concat "${OPTION_MARKS_QUALIFIER}" "MATCHES ${mark}" " AND "`"
      done
      IFS="${DEFAULT_IFS}"; set +o noglob
   fi
}


sourcetree_list_main()
{
   log_entry "sourcetree_list_main (1)" "$@"

   local ROOT_DIR

   ROOT_DIR="`pwd -P`"

   # must be empty initially for set
   local OPTION_OUTPUT_BANNER="DEFAULT"
   local OPTION_OUTPUT_COLOR="DEFAULT"
   local OPTION_OUTPUT_FORMAT="DEFAULT"
   local OPTION_OUTPUT_EVAL="DEFAULT"
   local OPTION_OUTPUT_FULL="DEFAULT"
   local OPTION_OUTPUT_HEADER="" # empty more convenient default
   local OPTION_OUTPUT_SEPARATOR="DEFAULT"
   local OPTION_OUTPUT_COLUMN="DEFAULT"
   local OPTION_OUTPUT_UUID="DEFAULT"
   local OPTION_OUTPUT_URL="DEFAULT"
   local OPTION_UNSAFE="NO"

   local OPTION_NODETYPES
   local OPTION_MARKS
   local OPTION_MARKS_QUALIFIER
   local OPTION_FORMAT

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
            OPTION_MARKS="`comma_concat "${OPTION_MARKS}" "$1" `"
         ;;

         -q|--qualifier)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            # allow to concatenate multiple flags
            OPTION_MARKS_QUALIFIER="$1"
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            OPTION_NODETYPES="`comma_concat "${OPTION_NODETYPES}" "$1" `"
         ;;

         --format)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            OPTION_FORMAT="$1"
         ;;

         --output-fmt|--output-format*)
            OPTION_OUTPUT_FORMAT="FMT"
         ;;

         --output-cmd|--out-command)
            OPTION_OUTPUT_FORMAT="CMD"
         ;;

         --output-raw|--output-csv)
            OPTION_OUTPUT_FORMAT="RAW"
         ;;

         --output-color)
            OPTION_OUTPUT_COLOR="YES"
         ;;

         --no-output-color|--output-no-color)
            OPTION_OUTPUT_COLOR="NO"
         ;;

         --output-column)
            OPTION_OUTPUT_COLUMN="YES"
         ;;

         --no-output-column|--output-no-column)
            OPTION_OUTPUT_COLUMN="NO"
         ;;

         --output-header)
            OPTION_OUTPUT_HEADER="YES"
         ;;

         --no-output-header|--output-no-header)
            OPTION_OUTPUT_HEADER="NO"
         ;;

         --output-separator)
            OPTION_OUTPUT_SEPARATOR="YES"
         ;;

         --no-output-separator|--output-no-separator)
            OPTION_OUTPUT_SEPARATOR="NO"
         ;;

         #
         #
         #
         --output-full)
            OPTION_OUTPUT_FULL="YES"
         ;;

         --no-output-full|--output-no-full)
            OPTION_OUTPUT_FULL="NO"
         ;;

         --output-url)
            OPTION_OUTPUT_URL="YES"
         ;;

         --no-output-url|--output-no-url)
            OPTION_OUTPUT_URL="NO"
         ;;

         --output-uuid)
            OPTION_OUTPUT_UUID="YES"
         ;;

         --no-output-uuid|--output-no-uuid)
            OPTION_OUTPUT_UUID="NO"
         ;;

         --output-banner)
            OPTION_OUTPUT_BANNER="YES"
         ;;

         --no-output-banner|--output-no-banner)
            OPTION_OUTPUT_BANNER="NO"
         ;;

         --output-eval)
            OPTION_OUTPUT_EVAL="YES"
         ;;

         --no-output-eval|--output-no-eval)
            OPTION_OUTPUT_EVAL="NO"
         ;;

         --no-output-marks|--output-no-marks)
            [ $# -eq 1 ] && sourcetree_list_usage "Missing argument to \"$1\""
            shift

            OPTION_NO_OUTPUT_MARKS="$1"
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

   [ -z "${SOURCETREE_CONFIG_FILE}" ] && fail "Config filename is empty"

   [ $# -ne 0 ] && log_error "superflous arguments \"$*\" to \"${COMMAND}\"" && sourcetree_list_usage

   #
   # generally we use flat, if the user didn't indicate otherwise
   # via flags
   #
   if [ -z "${FLAG_SOURCETREE_MODE}" ]
   then
      SOURCETREE_MODE="flat"
   fi

   # if mode is not flat, we use output-banner by default
   if [ "${OPTION_OUTPUT_BANNER}" = "DEFAULT" -a "${SOURCETREE_MODE}" != "flat" ]
   then
      OPTION_OUTPUT_BANNER="YES"
   fi

   local mode

   mode="`_sourcetree_augment_mode_with_output_options`"

   _sourcetree_list_convert_marks_to_qualifier  ## UGLY

   list_nodes "${mode}" "${OPTION_NODETYPES}" "${OPTION_MARKS_QUALIFIER}" "${OPTION_FORMAT}"
}


sourcetree_list_initialize()
{
   log_entry "sourcetree_list_initialize"


   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
   # shellcheck source=mulle-sourcetree-db.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh"
   fi
   if [ -z "${MULLE_SOURCETREE_NODEMARKS_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodemarks.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodemarks.sh"|| exit 1
   fi
   if [ -z "${MULLE_SOURCETREE_NODE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-node.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-node.sh" || exit 1
   fi
   if [ -z "${MULLE_SOURCETREE_NODELINE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodeline.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodeline.sh" || exit 1
   fi
   if [ -z "${MULLE_SOURCETREE_CFG_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-cfg.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-cfg.sh" || exit 1
   fi
}


sourcetree_list_initialize

:
