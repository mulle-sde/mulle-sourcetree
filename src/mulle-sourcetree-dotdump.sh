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
   ${MULLE_USAGE_NAME} dotdump [options]

   Produces a picture of your sourcetree by emitting .dot output.

Options:
   -n <value>    : node types to walk (default: ALL)
   -p <value>    : specify permissions (missing)
   -m <value>    : specify marks to match (e.g. build)
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
   log_entry "html_print_title" "$@"

   local title="$1"
   local fontcolor="$2"
   local bgcolor="$3"

   title="`html_escape "${title}"`"
   fontcolor="`html_escape "${fontcolor}"`"
   bgcolor="`html_escape "${bgcolor}"`"

   echo "<TR><TD BGCOLOR=\"${bgcolor}\" COLSPAN=\"2\"><FONT COLOR=\"${fontcolor}\">${title}</FONT></TD></TR>"
}


html_print_row()
{
   log_entry "html_print_row" "$@"

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
   log_entry "html_print_node" "$@"

   local identifier="$1"; shift
   local isshared="$1"; shift

   local url="$1"
   local address="$2"
   local branch="$3"
   local tag="$4"
   local nodetype="$5"
   local marks="$6"
   local fetchoptions="$7"
   local userinfo="$8"
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


   # admittedly this is still a bit ungainly coded...
   r_basename "${destination}"
   title="${RVAL}"

   RVAL="<TABLE>"
   r_concat "${RVAL}" "`html_print_title "${title}" "${fontcolor}" "${bgcolor}"`"
   r_concat "${RVAL}" "`html_print_row "address" "${address}"`"
   r_concat "${RVAL}" "`html_print_row "nodetype" "${nodetype}"`"
   r_concat "${RVAL}" "`html_print_row "userinfo" "${userinfo}"`"
   r_concat "${RVAL}" "`html_print_row "marks" "${marks}"`"
   r_concat "${RVAL}" "`html_print_row "url" "${url}"`"
   r_concat "${RVAL}" "`html_print_row "branch" "${branch}"`"
   r_concat "${RVAL}" "`html_print_row "tag" "${tag}"`"
   #      html="$(add_line "${html}" "`html_print_row "uuid" "${uuid}"`"")"
   r_concat "${RVAL}" "`html_print_row "fetchoptions" "${fetchoptions}"`"
   if [ ! -z "${MULLE_ORIGINATOR}" ]
   then
      r_concat "${RVAL}" "`html_print_row "original" "${MULLE_ORIGINATOR}"`"
   fi
   r_concat "${RVAL}" "</TABLE>"

   html="${RVAL}"
   exekutor echo "   ${identifier} [ label=<${html}>, shape=\"${shape}\", URL=\"${url}\" ]"
}


#
# returns one of:
#
#  config
#  database
#  file
#  folder
#  missing
#  ready
#  reset
#
r_get_fs_status()
{
   log_entry "r_get_fs_status" "$@"

   local destination="$1"

   if [ ! -e "${destination}" ]
   then
      log_debug "${destination} does not exist"
      RVAL="missing"
      return
   fi

   if [ ! -d "${destination}" ]
   then
     log_debug "${destination} is a file (not a folder)"
     RVAL="file"
     return
   fi

   local datasource

   # rewrite
   case "${destination}" in
      "."|"/")
         datasource="${SOURCETREE_START}"
      ;;

      /*/)
      ;;

      /*)
         datasource="${destination}/"
      ;;

      */)
         datasource="/${destination}"
      ;;

      *)
         datasource="/${destination}/"
      ;;
   esac

   if ! cfg_exists "${datasource}"
   then
      log_debug "${destination} has no cfg (is a folder)"
      RVAL="folder"
      return
   fi

   if ! db_dir_exists "${datasource}"
   then
      log_debug "${datasource} has no db (but is a sourcetree)"
      RVAL="config"
      return
   fi

   db_is_ready "${datasource}"
   case $? in
      1)
         log_debug "\"${datasource}\" db not ready"
         RVAL="database"
         return 0
      ;;

      2)
         log_debug "\"${datasource}\" db needs reset"
         RVAL="reset"
         return 0
      ;;
   esac

   log_debug "${datasource} db ready"
   RVAL="ready"
}


print_node()
{
   log_entry "print_node" "$@"

   local foldertype="$1"
   local destination="$2"
   local identifier="$3"
   local address="$4"
   local isshared="$5"

   case "${identifier}" in
      "")
         [ -z "${destination}" ] && \
            internal_fail "destination and identifer are empty for \"${WALK_NODE}\""

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
   local state

   r_get_fs_status "${destination}"
   state="${RVAL}"

   if [ "${isshared}" = 'NO' ]
   then
      case "${state}" in
         ready)
            color="limegreen"
            shape="folder"
         ;;

         database)
            color="darkorchid"
            shape="folder"
         ;;

         config|reset)
            color="goldenrod"
            shape="folder"
         ;;

         folder)
            color="dodgerblue"
            shape="folder"
         ;;

         file)
            color="dodgerblue"
            shape="note"
         ;;

         missing)
            color="black"
            shape="folder"  # nicer default than node
         ;;

         *)
            internal_fail "state is empty"
         ;;
      esac
   else
      case "${state}" in
         ready)
            color="limegreen"
            shape="folder"
         ;;

         database)
            color="darkorchid"
            shape="folder"
         ;;

         config)
            color="goldenrod"
            shape="folder"
         ;;

         folder)
            color="magenta"
            shape="folder"
         ;;

         file)
            color="dodgerblue"
            shape="note"
         ;;

         missing)
            color="maroon"
            shape="folder"  # nicer default than node or invis
         ;;

         *)
            internal_fail "state is empty"
         ;;
      esac
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

   r_basename "${address}"
   exekutor echo "   ${identifier} [ shape=\"${shape}\", \
penwidth=\"${penwidth}\", \
color=\"${color}\", \
style=\"${style}\" \
label=\"${RVAL}\"]"
}


walk_dotdump()
{
   log_entry "walk_dotdump" "$@"

   local url="${NODE_URL}"
   local address="${NODE_ADDRESS}"
   local branch="${NODE_BRANCH}"
   local tag="${NODE_TAG}"
   local nodetype="${NODE_TYPE}"
   local uuid="${NODE_UUID}"
   local marks="${NODE_MARKS}"
   local fetchoptions="${NODE_FETCHOPTIONS}"
   local userinfo="${NODE_USERINFO}"
   local destination="${WALK_VIRTUAL_ADDRESS}"
   local filename="${NODE_FILENAME}"
   local virtual="${WALK_VIRTUAL}"

   local identifier
   local previdentifier
   local relative
   local component
   local isshared

   log_debug "address:     ${address}"
   log_debug "destination: ${destination}"
   log_debug "virtual:     ${virtual}"

   if [ "${OPTION_OUTPUT_EVAL}" = 'YES' ]
   then
      url="`eval "echo \"${url}\""`"
      branch="`eval "printf \"%s\\\\\\\\n\" \"${branch}\""`"
      tag="`eval "printf \"%s\\\\\\\\n\" \"${tag}\""`"
      fetchoptions="`eval "printf \"%s\\\\\\\\n\" \"${fetchoptions}\""`"
   fi

   relative=""
   isshared='NO'
   isglobalshared='NO'

   #
   # replace a known path with a variable
   #
   if [ ! -z "${MULLE_SOURCETREE_STASH_DIR}" ]
   then
      if string_has_prefix "${destination}" "${MULLE_SOURCETREE_STASH_DIR}"
      then
         isshared='YES'

         local tmp

         if is_absolutepath "${MULLE_SOURCETREE_STASH_DIR}"
         then
            isglobalshared='YES'
            tmp="${destination#${MULLE_SOURCETREE_STASH_DIR}}"
            destination="`filepath_concat '${MULLE_SOURCETREE_STASH_DIR}' "${tmp}"`"
         fi
      fi
   fi

   log_debug "destination: ${destination}"

   set -o noglob; IFS="/"
   for component in ${destination}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      if [ -z "${component}" ]
      then
         component="/"
      fi
      label="`html_escape "${component}"`" # yeah...

      r_filepath_concat "${relative}" "${component}"
      relative="${RVAL}"
      identifier="\"${relative}\""

      log_debug "identifier: ${identifier}"

      local style
      local label

      style=""
      label=""
      if [ "${OPTION_OUTPUT_STATE}" = 'YES' ]
      then
         if [ -L "${relative}" ]
         then
            style="dotted"
            label="  symlink"
         fi
      fi

      # this if makes no sense but fixes a bug
      if [ "${previdentifier}" != "${identifier}" ]
      then
         local relidentifier

         relidentifier=
         if [ -z "${previdentifier}" ]
         then
            if [ "${isglobalshared}" = 'NO' ]
            then
               relidentifier="${ROOT_IDENTIFIER} -> ${identifier}"
            fi
         else
            relidentifier="${previdentifier} -> ${identifier}"
         fi

         if [ ! -z "${relidentifier}" ]
         then
            if ! find_line "${ALL_RELATIONSHIPS}" "${relidentifier}"
            then
               exekutor echo "   ${relidentifier} [ style=\"${style}\", label=\"${label}\" ]"
               ALL_RELATIONSHIPS="`add_line "${ALL_RELATIONSHIPS}" "${relidentifier}"`"
            fi
         fi
      fi

      log_debug "[i] ALL_DIRECTORIES='${ALL_DIRECTORIES}'"

      if ! find_line "${ALL_DIRECTORIES}" "${identifier}"
      then
         r_add_line "${ALL_DIRECTORIES}" "${identifier}"
         ALL_DIRECTORIES="${RVAL}"
         log_debug "[+] ALL_DIRECTORIES='${ALL_DIRECTORIES}'"

         if ! find_line "${TOEMIT_DIRECTORIES}" "${identifier}"
         then
            r_add_line "${TOEMIT_DIRECTORIES}" "${identifier}"
            TOEMIT_DIRECTORIES="${RVAL}"
            log_debug "[+] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"
         fi
      fi

      previdentifier="${identifier}"
   done
   IFS="${DEFAULT_IFS}"; set +o noglob

   # remove destinatipn from toemit, as we are emitting it now
   identifier="\"${destination}\""
   TOEMIT_DIRECTORIES="`fgrep -v -s -x -e "${identifier}" <<< "${TOEMIT_DIRECTORIES}"`"
   log_debug "[-] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   if [ "${OPTION_OUTPUT_HTML}" = 'YES' ]
   then
      html_print_node "${identifier}" \
                      "${isshared}"   \
                         "${url}" \
                         "${address}" \
                         "${branch}" \
                         "${tag}" \
                         "${nodetype}" \
                         "${marks}" \
                         "${fetchoptions}" \
                         "${userinfo}" \
                         "${uuid}"
   else
      print_node "default" \
                 "${destination}" \
                 "${identifier}" \
                 "${address}" \
                 "${isshared}"
   fi

   IFS="${DEFAULT_IFS}"

   log_entry "walk_dotdump done"

   :
}


walk_dotdump_finished()
{
   log_debug "[†] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"
   emit_remaining_directories "${TOEMIT_DIRECTORIES}"
}


emit_root()
{
   log_entry "emit_root" "$@"

   local name

   if [ "${OPTION_OUTPUT_HTML}" = 'YES' ]
   then
      html_print_node "${ROOT_IDENTIFIER}" \
                      'NO' \
                           "${url}" \
                           "${PWD}" \
                           "" \
                           "" \
                           "root"
   else
      r_basename "${PWD}"
      print_node "root" \
                 "." \
                 "${ROOT_IDENTIFIER}" \
                 "${RVAL}" \
                 'NO'
   fi
}


emit_remaining_directories()
{
   log_entry "emit_remaining_directories" "$@"

   local directories="$1"

   local identifier
   local name

   set -o noglob ; IFS=$'\n'
   for identifier in ${directories}
   do
      IFS="${DEFAULT_IFS}"; set +o noglob

      name="$(sed 's/^.\(.*\).$/\1/' <<< "${identifier}")"

      print_node "other" \
                 "${name}" \
                 "${identifier}"  \
                 "${name}" \
                 'NO'
   done
   IFS="${DEFAULT_IFS}"; set +o noglob
}


sourcetree_dotdump_body()
{
   log_entry "sourcetree_dotdump_body" "$@"

   local mode="$1"

   #
   # ugly hacks to avoid drawing multiple lines
   #
   local ALL_RELATIONSHIPS=
   local ALL_DIRECTORIES=
   local TOEMIT_DIRECTORIES=
   local ROOT_IDENTIFIER="\"`basename -- "${PWD}"`\""

   log_debug "[*] ALL_DIRECTORIES='${ALL_DIRECTORIES}'"
   log_debug "[*] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   case ",${mode}," in
      *,walkdb,*)
         DID_WALK_CALLBACK=walk_dotdump_finished \
            walk_db_uuids "ALL" \
                          "" \
                          "" \
                          "" \
                          "${mode}" \
                          "walk_dotdump"
      ;;

      *)
         DID_WALK_CALLBACK=walk_dotdump_finished \
            walk_config_uuids "ALL" \
                              "" \
                              "" \
                              "" \
                              "${mode}" \
                              "walk_dotdump"
      ;;
   esac || return 1


   emit_root
}


sourcetree_dotdump()
{
   log_entry "sourcetree_dotdump" "$@"

   local output

   output="`sourcetree_dotdump_body "$@"`" || return 1

   cat <<EOF
digraph sourcetree
{
EOF

   if [ "${OPTION_OUTPUT_HTML}" = 'YES' ]
   then
      echo "   rankdir=LR;"
   fi

   cat <<EOF
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
   local OPTION_NODETYPES=""
   local OPTION_WALK_DB="DEFAULT"
   local OPTION_OUTPUT_HTML='NO'
   local OPTION_OUTPUT_EVAL='NO'
   local OPTION_OUTPUT_STATE='NO'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_dotdump_usage
         ;;

         --walk-db|--walk-db-dir)
            OPTION_WALK_DB='YES'
         ;;

         --walk-config|--walk-config-file)
            OPTION_WALK_DB='NO'
         ;;

         --output-eval)
            OPTION_OUTPUT_EVAL='YES'
         ;;

         --no-output-eval)
            OPTION_OUTPUT_EVAL='NO'
         ;;

         --output-state)
            OPTION_OUTPUT_STATE='YES'
         ;;

         --no-output-state)
            OPTION_OUTPUT_STATE='NO'
         ;;

         --output-html)
            OPTION_OUTPUT_HTML='YES'
         ;;

         --no-output-html)
            OPTION_OUTPUT_HTML='NO'
         ;;
         #
         # more common flags
         #
         -m|--marks)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_MARKS="$1"
         ;;

         -n|--nodetypes)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
            shift

            OPTION_NODETYPES="$1"
         ;;

         -p|--permissions)
            [ $# -eq 1 ] && fail "Missing argument to \"$1\""
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

   local mode

   mode="${SOURCETREE_MODE}"
   if [ "${SOURCETREE_MODE}" != "flat" ]
   then
      r_comma_concat "${mode}" "post-order"
      mode="${RVAL}"
   fi

   if [ "${OPTION_WALK_DB}" = 'YES' ]
   then
      if ! db_dir_exists "${SOURCETREE_START}"
      then
         log_info "There is no ${SOURCETREE_DB_FILENAME} here"
      fi

      r_comma_concat "${mode}" "walkdb"
      mode="${RVAL}"
   else
      if ! cfg_exists "${SOURCETREE_START}"
      then
         log_info "There is no ${SOURCETREE_CONFIG_FILENAME} here"
      fi
   fi

   if ! db_is_ready "${SOURCETREE_START}"
   then
      log_warning "Update has not run yet (mode=${SOURCETREE_MODE})"
   fi

   sourcetree_dotdump "${mode}"
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
