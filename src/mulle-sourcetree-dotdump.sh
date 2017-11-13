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
MULLE_SOURCETREE_DOTDUMP_SH="included"


sourcetree_dotdump_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} dotdump [options]

   Produces a picture of your sourcetree by emitting .dot output.

Options:
   -n <value>    : node types to walk (default: ALL)
   -p <value>    : specify permissions (missing)
   -m <value>    : specify marks to match (e.g. build)
   --no-recurse  : do not recurse
   --walk-config : traverse the config file (default)
   --walk-db     : walk over information contained in the database instead
   --output-html : emit HTML Graphviz nodes, for more information
EOF
  exit 1
}


html_escape()
{
   tr '[&<>]' '.' <<< "$*"
}


html_print_title()
{
   local html="$1"
   local title="$2"
   local fontcolor="$3"
   local bgcolor="$4"

   title="`html_escape "${title}"`"
   fontcolor="`html_escape "${fontcolor}"`"
   bgcolor="`html_escape "${bgcolor}"`"

   echo "<TR><TD BGCOLOR=\"${bgcolor}\" COLSPAN=\"2\"><FONT COLOR=\"${fontcolor}\">${title}</FONT></TD></TR>"
}


html_print_row()
{
   local key="$1"
   local value="$2"
   local defaultvalue="$3"

   key="`html_escape "${key}"`"
   value="`html_escape "${value}"`"
   if [ "${value}" != "${defaultvalue}" ]
   then
      echo "<TR><TD>${key}</TD><TD>${value}</TD></TR>"
   fi
}


html_print_node()
{
   local identifier="$1"; shift

   local url="$1"
   local prefixed="$2"
   local branch="$3"
   local tag="$4"
   local nodetype="$5"
   local marks="$6"
   local fetchoptions="$7"
   local useroptions="$8"
   local uuid="$9"

   bgcolor="lightgray"
   fontcolor="black"
   shape="none"

   case "${nodetype}" in
      script)
         bgcolor="red"
         fontcolor="white"
      ;;

      file)
         bgcolor="green"
         fontcolor="white"
      ;;

      zip|tar)
      ;;

      git)
         bgcolor="blue"
         fontcolor="white"
      ;;
   esac

   html="<TABLE>"

   # admittedly this is a bit ungainly coded...
   title="`basename -- "${prefixed}"`"
   html="$(concat "${html}" "`html_print_title "${html}" "${title}" "${fontcolor}" "${bgcolor}"`")"
   html="$(concat "${html}" "`html_print_row "url" "${url}"`")"
   html="$(concat "${html}" "`html_print_row "address" "${prefixed}" "${title}"`")"
   html="$(concat "${html}" "`html_print_row "branch" "${branch}" "master"`")"
   html="$(concat "${html}" "`html_print_row "tag" "${tag}"`")"
   html="$(concat "${html}" "`html_print_row "nodetype" "${nodetype}" "git"`")"
   #      html="$(add_line "${html}" "`html_print_row "uuid" "${uuid}"`"")"
   html="$(concat "${html}" "`html_print_row "marks" "${marks}"`")"
   html="$(concat "${html}" "`html_print_row "fetchoptions" "${fetchoptions}"`")"
   html="$(concat "${html}" "`html_print_row "userinfo" "${userinfo}"`")"
   html="$(concat "${html}" "</TABLE>")"

   echo "${identifier} [ label=<${html}>, shape=\"${shape}\", URL=\"${url}\" ]"
}


walk_dotdump()
{
   log_entry "walk_dotdump" "$@"

   url="$1"
   prefixed="$2"
   branch="$3"
   tag="$4"
   nodetype="$5"
   uuid="$6"
   marks="$7"
   fetchoptions="$8"
   useroptions="$9"

   local identifier
   local relidentifier
   local previdentifier
   local relative
   local component

   relative=""
   IFS="/"

   for component in ${prefixed}
   do
      IFS="${DEFAULT_IFS}"

      if [ -z "${component}" ]
      then
         component="/"
      fi
      label="`html_escape "${component}"`" # yeah...

      relative="`filepath_concat "${relative}" "${component}"`"
      identifier="\"${relative}\""

      if [ -z "${previdentifier}" ]
      then
         relidentifier="${ROOT_IDENTIFIER} -> ${identifier}"
      else
         relidentifier="${previdentifier} -> ${identifier}"
      fi

      if ! fgrep -q -s -x "${relidentifier}" <<< "${ALL_RELATIONSHIPS}"
      then
         echo "${relidentifier}"
         ALL_RELATIONSHIPS="`add_line "${ALL_RELATIONSHIPS}" "${relidentifier}"`"
      fi

      if ! fgrep -q -s -x "${identifier}" <<< "${ALL_DIRECTORIES}"
      then
         ALL_DIRECTORIES="`add_line "${ALL_DIRECTORIES}" "${identifier}"`"
         if ! fgrep -q -s -x "${identifier}" <<< "${TOEMIT_DIRECTORIES}"
         then
            TOEMIT_DIRECTORIES="`add_line "${TOEMIT_DIRECTORIES}" "${identifier}"`"
            log_debug "TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"
         fi
      fi

      previdentifier="${identifier}"
   done
   IFS="${DEFAULT_IFS}"

   identifier="\"${prefixed}\""
   TOEMIT_DIRECTORIES="`fgrep -v -s -x "${identifier}" <<< "${TOEMIT_DIRECTORIES}"`"
   log_debug "TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   if [ "${OPTION_HTML}" = "YES" ]
   then
      html_print_node "${identifier}" "${url}" \
                                      "${address}" \
                                      "${branch}" \
                                      "${tag}" \
                                      "${nodetype}" \
                                      "${marks}" \
                                      "${fetchoptions}" \
                                      "${userinfo}" \
                                      "${uuid}"
   else
      echo "${identifier} [ penwidth=2, fillstyle=\"none\" \
label=\"`basename -- "${prefixed}"`\"]"
   fi

   IFS="${DEFAULT_IFS}"
}


emit_root()
{
   if [ "${OPTION_HTML}" = "YES" ]
   then
      html_print_node "${ROOT_IDENTIFIER}" "${url}" \
                                           "${PWD}" \
                                           "" \
                                           "" \
                                           "root"
   else
      echo "${ROOT_IDENTIFIER} [ penwidth=3 ]"
   fi
}

emit_remaining_directories()
{
   log_entry "emit_remaining_directories" "$@"

   local directories="$1"

   local identifier
   local name

   IFS="
"
   for identifier in ${directories}
   do
      IFS="${DEFAULT_IFS}"

      name="$(sed 's/^.\(.*\).$/\1/' <<< "${identifier}")"
      name="`basename -- "${name}"`"

      echo "${identifier} [ label=\"${name}\", style=\"\" ]"
   done
   IFS="${DEFAULT_IFS}"
}


sourcetree_dotdump_body()
{
   local filternodetypes="$1"
   local filterpermissions="$2"
   local filtermarks="$3"
   local mode="$4"

   #
   # ugly hacks to avoid drawing multiple lines
   #
   local ALL_RELATIONSHIPS=
   local ALL_DIRECTORIES=
   local TOEMIT_DIRECTORIES=
   local ROOT_IDENTIFIER="\"`basename -- "${PWD}"`\""

   log_debug "TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   case "${mode}" in
      *walkdb*)
         walk_db_uuids "walk_dotdump" \
                       "${filternodetypes}" \
                       "${filterpermissions}" \
                       "${filtermarks}" \
                       "${mode}" \
                       "" \
                       "$@"
      ;;

      *)
         walk_config_uuids "walk_dotdump" \
                           "${filternodetypes}" \
                           "${filterpermissions}" \
                           "${filtermarks}" \
                           "${mode}" \
                           "" \
                           "$@"
      ;;
   esac || return 1

   log_debug "TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   emit_root
   emit_remaining_directories "${TOEMIT_DIRECTORIES}"
}


sourcetree_dotdump()
{
   local output

   output="`sourcetree_dotdump_body "$@"`" || return 1

   cat <<EOF
digraph sourcetree
{
   node [ shape="box"; style="filled" ]

   ${output}
}
EOF
}


sourcetree_dotdump_main()
{
   log_entry "sourcetree_dotdump_main" "$@"

   local OPTION_MARKS="ANY"
   local OPTION_PERMISSIONS="" # empty!
   local OPTION_NODETYPES="ALL"
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_RECURSIVE
   local OPTION_HTML="NO"

   if db_is_recursive
   then
      OPTION_RECURSIVE="YES"
   else
      OPTION_RECURSIVE="NO"
   fi

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            sourcetree_dotdump_usage
         ;;

         --walk-db|--walk-db-dir)
            OPTION_WALK_DB="YES"
         ;;

         --walk-config|--walk-config-file)
            OPTION_WALK_DB="NO"
         ;;

         --html)
            OPTION_HTML="YES"
         ;;

         --no-html)
            OPTION_HTML="NO"
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
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown dotdump option $1"
            sourcetree_dotdump_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_dotdump_usage


   mode="prefix"
   if [ "${OPTION_RECURSIVE}" = "YES" ]
   then
      mode="`concat "${mode}" "recurse"`"
   fi

   if [ "${OPTION_WALK_DB}" = "YES" ]
   then
      if ! db_exists
      then
         log_info "There is no ${SOURCETREE_DB_DIR} here"
      fi

      mode="`concat "${mode}" "walkdb"`"
   else
      if ! nodeline_config_exists
      then
         log_info "There is no ${SOURCETREE_CONFIG_FILE} here"
      fi
   fi

   sourcetree_dotdump "${OPTION_NODETYPES}" \
                      "${OPTION_PERMISSIONS}" \
                      "${OPTION_MARKS}" \
                      "${mode}"
}


sourcetree_dotdump_initialize()
{
   log_entry "sourcetree_dotdump_initialize"

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


sourcetree_dotdump_initialize

:
