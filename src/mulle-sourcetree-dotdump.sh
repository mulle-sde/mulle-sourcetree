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
   local address="$2"
   local branch="$3"
   local tag="$4"
   local nodetype="$5"
   local marks="$6"
   local fetchoptions="$7"
   local useroptions="$8"
   local uuid="$9"

   case "${identifier}" in
      "")
         identifier="\"${address}\""
      ;;

      \"*\")
      ;;

      *)
         internal_fail "identifier \"${identifier}\" must be quoted"
      ;;
   esac


   bgcolor="lightgray"
   fontcolor="black"
   shape="local"

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
         bgcolor="dodgerblue"
         fontcolor="white"
      ;;

      svn)
         bgcolor="coral4"
         fontcolor="white"
      ;;

      git)
         bgcolor="blue"
         fontcolor="white"
      ;;
   esac

   html="<TABLE>"

   # admittedly this is a bit ungainly coded...
   title="`basename -- "${destination}"`"
   html="$(concat "${html}" "`html_print_title "${html}" "${title}" "${fontcolor}" "${bgcolor}"`")"
   html="$(concat "${html}" "`html_print_row "address" "${address}"`")"
   html="$(concat "${html}" "`html_print_row "nodetype" "${nodetype}"`")"
   html="$(concat "${html}" "`html_print_row "userinfo" "${userinfo}"`")"
   html="$(concat "${html}" "`html_print_row "marks" "${marks}"`")"
   html="$(concat "${html}" "`html_print_row "url" "${url}"`")"
   html="$(concat "${html}" "`html_print_row "branch" "${branch}"`")"
   html="$(concat "${html}" "`html_print_row "tag" "${tag}"`")"
   #      html="$(add_line "${html}" "`html_print_row "uuid" "${uuid}"`"")"
   html="$(concat "${html}" "`html_print_row "fetchoptions" "${fetchoptions}"`")"
   if [ ! -z "${MULLE_ORIGINATOR}" ]
   then
      html="$(concat "${html}" "`html_print_row "original" "${MULLE_ORIGINATOR}"`")"
   fi
   html="$(concat "${html}" "</TABLE>")"

   exekutor echo "${identifier} [ label=<${html}>, shape=\"${shape}\", URL=\"${url}\" ]"
}


print_node()
{
   local foldertype="$1"
   local destination="$2"
   local identifier="$3"
   local address="$4"

   case "${identifier}" in
      "")
         identifier="\"${destination}\""
      ;;
      \"*\")
      ;;
      *)
         internal_fail "identifier \"${identifier}\" must be quoted"
      ;;
   esac

   local shape
   local color

   color="black"
   shape="box"

   if [ ! -e "${destination}" ]
   then
      shape="invis"
   else
      color="dodgerblue"
      if [ "${OPTION_OUTPUT_STATE}" = "YES" ]
      then
         if [ -d "${destination}" ]
         then
            if [ -f "${destination}/${SOURCETREE_CONFIG_FILE}" ]
            then
               if db_is_ready "${destination}"
               then
                  color="limegreen"
               else
                  color="darkorchid"
               fi
            fi
            shape="folder"
         else
            shape="note"
         fi
      fi
   fi


   local penwidth
   local style

   case "${foldertype}" in
      root)
         penwidth="3"
      ;;

      other)
         color="honeydew4"
         penwidth=1
         style=""
      ;;

      *)
         penwidth="2"
      ;;
   esac

   exekutor echo "${identifier} [ shape=\"${shape}\", \
penwidth=\"${penwidth}\",  \
color=\"${color}\" \
style=\"${style}\" \
label=\"`basename -- "${address}"`\"]"
}


walk_dotdump()
{
   log_entry "walk_dotdump" "$@"

   local url="${MULLE_URL}"
   local address="${MULLE_ADDRESS}"
   local branch="${MULLE_BRANCH}"
   local tag="${MULLE_TAG}"
   local nodetype="${MULLE_NODETYPE}"
   local uuid="${MULLE_UUID}"
   local marks="${MULLE_MARKS}"
   local fetchoptions="${MULLE_FETCHOPTIONS}"
   local useroptions="${MULLE_USEROPTIONS}"
   local destination="${MULLE_DESTINATION}"

   local identifier
   local relidentifier
   local previdentifier
   local relative
   local component

   if [ "${OPTION_OUTPUT_EVAL}" = "YES" ]
   then
      url="`eval echo "${url}"`"
      branch="`eval echo "${branch}"`"
      tag="`eval echo "${tag}"`"
      fetchoptions="`eval echo "${fetchoptions}"`"
   fi

   relative=""
   IFS="/"

   for component in ${destination}
   do
      IFS="${DEFAULT_IFS}"

      if [ -z "${component}" ]
      then
         component="/"
      fi
      label="`html_escape "${component}"`" # yeah...

      relative="`filepath_concat "${relative}" "${component}"`"
      identifier="\"${relative}\""

      local style
      local label

      style=""
      label=""
      if [ "${OPTION_OUTPUT_STATE}" = "YES" ]
      then
         if [ -L "${relative}" ]
         then
            style="dotted"
            label="  symlink"
         fi
      fi

      if [ -z "${previdentifier}" ]
      then
         relidentifier="${ROOT_IDENTIFIER} -> ${identifier}"
      else
         relidentifier="${previdentifier} -> ${identifier}"
      fi

      if ! fgrep -q -s -x "${relidentifier}" <<< "${ALL_RELATIONSHIPS}"
      then
         exekutor echo "${relidentifier} [ style=\"${style}\" label=\"${label}\" ]"
         ALL_RELATIONSHIPS="`add_line "${ALL_RELATIONSHIPS}" "${relidentifier}"`"
      fi

      log_debug "[i] ALL_DIRECTORIES='${ALL_DIRECTORIES}'"

      if ! fgrep -q -s -x "${identifier}" <<< "${ALL_DIRECTORIES}"
      then
         ALL_DIRECTORIES="`add_line "${ALL_DIRECTORIES}" "${identifier}"`"
         log_debug "[+] ALL_DIRECTORIES='${ALL_DIRECTORIES}'"

         if ! fgrep -q -s -x "${identifier}" <<< "${TOEMIT_DIRECTORIES}"
         then
            TOEMIT_DIRECTORIES="`add_line "${TOEMIT_DIRECTORIES}" "${identifier}"`"
            log_debug "[+] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"
         fi
      fi

      previdentifier="${identifier}"
   done
   IFS="${DEFAULT_IFS}"

   identifier="\"${destination}\""
   TOEMIT_DIRECTORIES="`fgrep -v -s -x "${identifier}" <<< "${TOEMIT_DIRECTORIES}"`"
   log_debug "[-] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   if [ "${OPTION_OUTPUT_HTML}" = "YES" ]
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
      print_node "default" "${destination}" "${identifier}" "${address}"
   fi

   IFS="${DEFAULT_IFS}"

   :
}


emit_root()
{
   if [ "${OPTION_OUTPUT_HTML}" = "YES" ]
   then
      html_print_node "${ROOT_IDENTIFIER}" "${url}" \
                                           "${PWD}" \
                                           "" \
                                           "" \
                                           "root"
   else
      print_node "root" "." "${ROOT_IDENTIFIER}" "`basename -- "${PWD}"`"
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

      print_node "other" "${name}" "${identifier}"  "${name}"
   done
   IFS="${DEFAULT_IFS}"
}


sourcetree_dotdump_body()
{
   log_entry "sourcetree_dotdump_body" "$@"

   local filternodetypes="$1"; shift
   local filterpermissions="$1"; shift
   local filtermarks="$1"; shift
   local mode="$1"; shift

   #
   # ugly hacks to avoid drawing multiple lines
   #
   local ALL_RELATIONSHIPS=
   local ALL_DIRECTORIES=
   local TOEMIT_DIRECTORIES=
   local ROOT_IDENTIFIER="\"`basename -- "${PWD}"`\""

   log_debug "[*] ALL_DIRECTORIES='${ALL_DIRECTORIES}'"
   log_debug "[*] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   case "${mode}" in
      *walkdb*)
         walk_db_uuids "${filternodetypes}" \
                       "${filterpermissions}" \
                       "${filtermarks}" \
                       "${mode}" \
                       "walk_dotdump" \
                       "$@"
      ;;

      *)
         walk_config_uuids "${filternodetypes}" \
                           "${filterpermissions}" \
                           "${filtermarks}" \
                           "${mode}" \
                           "walk_dotdump" \
                           "$@"
      ;;
   esac || return 1

   log_debug "[†] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   emit_root
   emit_remaining_directories "${TOEMIT_DIRECTORIES}"
}


sourcetree_dotdump()
{
   log_entry "sourcetree_dotdump" "$@"

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
   local OPTION_OUTPUT_HTML="NO"
   local OPTION_OUTPUT_EVAL="NO"
   local OPTION_OUTPUT_STATE="NO"

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

         --output-eval)
            OPTION_OUTPUT_EVAL="YES"
         ;;

         --no-output-eval)
            OPTION_OUTPUT_EVAL="NO"
         ;;

         --output-state)
            OPTION_OUTPUT_STATE="YES"
         ;;

         --no-output-state)
            OPTION_OUTPUT_STATE="NO"
         ;;

         --output-html)
            OPTION_OUTPUT_HTML="YES"
         ;;

         --no-output-html)
            OPTION_OUTPUT_HTML="NO"
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

   mode="${SOURCETREE_MODE}"

   if [ "${OPTION_WALK_DB}" = "YES" ]
   then
      if ! db_dir_exists
      then
         log_info "There is no ${SOURCETREE_DB_DIR} here"
      fi

      mode="`concat "${mode}" "walkdb"`"
   else
      if ! cfg_exists "/"
      then
         log_info "There is no ${SOURCETREE_CONFIG_FILE} here"
      fi
   fi

   if ! db_is_ready "/"
   then
      log_warning "Update has not run yet (mode=${SOURCETREE_MODE})"
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
