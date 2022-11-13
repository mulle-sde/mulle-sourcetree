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
MULLE_SOURCETREE_DOTDUMP_SH="included"


sourcetree::dotdump::usage()
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


sourcetree::dotdump::html_escape()
{
   tr '[&<>]' '.' <<< "$*"
}


sourcetree::dotdump::html_print_title()
{
   log_entry "sourcetree::dotdump::html_print_title" "$@"

   local title="$1"
   local fontcolor="$2"
   local bgcolor="$3"

   title="`sourcetree::dotdump::html_escape "${title}"`"
   fontcolor="`sourcetree::dotdump::html_escape "${fontcolor}"`"
   bgcolor="`sourcetree::dotdump::html_escape "${bgcolor}"`"

   echo "<TR><TD BGCOLOR=\"${bgcolor}\" COLSPAN=\"2\"><FONT COLOR=\"${fontcolor}\">${title:-&nbsp;}</FONT></TD></TR>"
}


sourcetree::dotdump::html_print_row()
{
   log_entry "sourcetree::dotdump::html_print_row" "$@"

   local key="$1"
   local value="$2"
   local defaultvalue="$3"

   key="`sourcetree::dotdump::html_escape "${key}"`"
   value="`sourcetree::dotdump::html_escape "${value}"`"
   if [ "${value}" != "${defaultvalue}" ]
   then
      echo "<TR><TD>${key}</TD><TD>${value}</TD></TR>"
   fi
}


sourcetree::dotdump::html_print_node()
{
   log_entry "sourcetree::dotdump::html_print_node" "$@"

   local identifier="$1"; shift
   local isshared="$1"; shift
   local title="$1"; shift

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
         _internal_fail "identifier \"${identifier}\" must be quoted"
      ;;
   esac

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


   RVAL="<TABLE>"
   r_concat "${RVAL}" "`sourcetree::dotdump::html_print_title "${title}" "${fontcolor}" "${bgcolor}"`"
   r_concat "${RVAL}" "`sourcetree::dotdump::html_print_row "address" "${address}"`"
   r_concat "${RVAL}" "`sourcetree::dotdump::html_print_row "nodetype" "${nodetype}"`"
   r_concat "${RVAL}" "`sourcetree::dotdump::html_print_row "userinfo" "${userinfo}"`"
   r_concat "${RVAL}" "`sourcetree::dotdump::html_print_row "marks" "${marks}"`"
   r_concat "${RVAL}" "`sourcetree::dotdump::html_print_row "url" "${url}"`"
   r_concat "${RVAL}" "`sourcetree::dotdump::html_print_row "branch" "${branch}"`"
   r_concat "${RVAL}" "`sourcetree::dotdump::html_print_row "tag" "${tag}"`"
   #      html="$(add_line "${html}" "`sourcetree::dotdump::html_print_row "uuid" "${uuid}"`"")"
   r_concat "${RVAL}" "`sourcetree::dotdump::html_print_row "fetchoptions" "${fetchoptions}"`"
   if [ ! -z "${MULLE_ORIGINATOR}" ]
   then
      r_concat "${RVAL}" "`sourcetree::dotdump::html_print_row "original" "${MULLE_ORIGINATOR}"`"
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
sourcetree::dotdump::r_get_fs_status()
{
   log_entry "sourcetree::dotdump::r_get_fs_status" "$@"

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

   if ! sourcetree::cfg::is_config_present "${datasource}"
   then
      log_debug "${destination} has no cfg (is a folder)"
      RVAL="folder"
      return
   fi

   if ! sourcetree::db::dir_exists "${datasource}"
   then
      log_debug "${datasource} has no db (but is a sourcetree)"
      RVAL="config"
      return
   fi

   sourcetree::db::is_ready "${datasource}"
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


sourcetree::dotdump::print_node()
{
   log_entry "sourcetree::dotdump::print_node" "$@"

   local foldertype="$1"
   local destination="$2"
   local identifier="$3"
   local address="$4"
   local isshared="$5"

   case "${identifier}" in
      "")
         [ -z "${destination}" ] && \
            _internal_fail "destination and identifer are empty for \"${WALK_NODE}\""

         identifier="\"${destination}\""
      ;;

      \"*\")
      ;;

      *)
         _internal_fail "identifier \"${identifier}\" must be quoted"
      ;;
   esac

   local shape
   local color
   local state

   sourcetree::dotdump::r_get_fs_status "${destination}"
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
            _internal_fail "state is empty"
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
            _internal_fail "state is empty"
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


sourcetree::dotdump::walk()
{
   log_entry "sourcetree::dotdump::walk" "$@"

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
      r_expanded_string "${url}"
      url="${RVAL}"
      r_expanded_string "${branch}"
      branch="${RVAL}"
      r_expanded_string "${tag}"
      tag="${RVAL}"
      r_expanded_string "${fetchoptions}"
      fetchoptions="${RVAL}"
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
            r_filepath_concat '${MULLE_SOURCETREE_STASH_DIR}' "${tmp}"
            destination="${RVAL}"
         fi
      fi
   fi

   log_debug "destination: ${destination}"

   local style
   local label
   local relidentifier

   shell_disable_glob; IFS="/"
   for component in ${destination}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      if [ -z "${component}" ]
      then
         component="/"
      fi
      label="`sourcetree::dotdump::html_escape "${component}"`" # yeah...

      r_filepath_concat "${relative}" "${component}"
      relative="${RVAL}"
      identifier="\"${relative}\""

      log_debug "identifier: ${identifier}"

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

      # this seems to make no sense but fixes a bug
      if [ "${previdentifier}" != "${identifier}" ]
      then
         relidentifier=
         if [ -z "${previdentifier}" ]
         then
            # if [ "${isglobalshared}" = 'NO' ]
            # then
               relidentifier="${ROOT_IDENTIFIER} -> ${identifier}"
            #fi
         else
            relidentifier="${previdentifier} -> ${identifier}"
         fi

         if [ ! -z "${relidentifier}" ]
         then
            if ! find_line "${ALL_RELATIONSHIPS}" "${relidentifier}"
            then
               exekutor echo "   ${relidentifier} [ style=\"${style}\", label=\"${label}\" ]"
               r_add_line "${ALL_RELATIONSHIPS}" "${relidentifier}"
               ALL_RELATIONSHIPS="${RVAL}"
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
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   # remove destinatipn from toemit, as we are emitting it now
   identifier="\"${destination}\""
   TOEMIT_DIRECTORIES="`fgrep -v -s -x -e "${identifier}" <<< "${TOEMIT_DIRECTORIES}"`"
   log_debug "[-] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   if [ "${OPTION_OUTPUT_HTML}" = 'YES' ]
   then
      r_basename "${destination}"
      title="${RVAL}"

      sourcetree::dotdump::html_print_node "${identifier}" \
                      "${isshared}"   \
                      "${title}" \
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
      sourcetree::dotdump::print_node "default" \
                 "${destination}" \
                 "${identifier}" \
                 "${address}" \
                 "${isshared}"
   fi

   IFS="${DEFAULT_IFS}"

   log_entry "sourcetree::dotdump::walk done"

   :
}


sourcetree::dotdump::walk_finished()
{
   log_debug "[†] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"
   sourcetree::dotdump::emit_remaining_directories "${TOEMIT_DIRECTORIES}"
}


sourcetree::dotdump::emit_root()
{
   log_entry "sourcetree::dotdump::emit_root" "$@"

   local title

   if [ "${OPTION_OUTPUT_HTML}" = 'YES' ]
   then
      title="${ROOT_IDENTIFIER#\"}"
      title="${title%\"}"
      sourcetree::dotdump::html_print_node "${ROOT_IDENTIFIER}" \
                      'NO' \
                      "${title}" \
                      "${url}" \
                      "${PWD}" \
                      "" \
                      "" \
                      "root"
   else
      r_basename "${PWD}"
      sourcetree::dotdump::print_node "root" \
                 "." \
                 "${ROOT_IDENTIFIER}" \
                 "${RVAL}" \
                 'NO'
   fi
}


sourcetree::dotdump::emit_remaining_directories()
{
   log_entry "sourcetree::dotdump::emit_remaining_directories" "$@"

   local directories="$1"

   local identifier
   local name

   shell_disable_glob; IFS=$'\n'
   for identifier in ${directories}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      name="$(sed 's/^.\(.*\).$/\1/' <<< "${identifier}")"

      sourcetree::dotdump::print_node "other" \
                 "${name}" \
                 "${identifier}"  \
                 "${name}" \
                 'NO'
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob
}


sourcetree::dotdump::do_body()
{
   log_entry "sourcetree::dotdump::do_body" "$@"

   local mode="$1"

   #
   # ugly hacks to avoid drawing multiple lines
   #
   local ALL_RELATIONSHIPS=
   local ALL_DIRECTORIES=
   local TOEMIT_DIRECTORIES=
   local ROOT_IDENTIFIER

   r_basename "${PWD}"
   ROOT_IDENTIFIER="\"${RVAL}\""

   log_debug "[*] ROOT_IDENTIFIER='${ROOT_IDENTIFIER}'"
   log_debug "[*] ALL_DIRECTORIES='${ALL_DIRECTORIES}'"
   log_debug "[*] TOEMIT_DIRECTORIES='${TOEMIT_DIRECTORIES}'"

   case ",${mode}," in
      *,walkdb,*)
         DID_WALK_CALLBACK=sourcetree::dotdump::walk_finished \
            sourcetree::walk::walk_db_uuids "ALL" \
                          "" \
                          "" \
                          "" \
                          "${mode}" \
                          "sourcetree::dotdump::walk"
      ;;

      *)
         DID_WALK_CALLBACK=sourcetree::dotdump::walk_finished \
            sourcetree::walk::walk_config_uuids "ALL" \
                              "" \
                              "" \
                              "" \
                              "${mode}" \
                              "sourcetree::dotdump::walk"
      ;;
   esac || return 1


   sourcetree::dotdump::emit_root
}


sourcetree::dotdump::do()
{
   log_entry "sourcetree::dotdump::do" "$@"

   local output

   output="`sourcetree::dotdump::do_body "$@"`" || return 1

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



sourcetree::dotdump::main()
{
   log_entry "sourcetree::dotdump::main" "$@"

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
            sourcetree::dotdump::usage
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
            sourcetree::dotdump::usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree::dotdump::usage

   local mode

   mode="${SOURCETREE_MODE}"
   if [ "${SOURCETREE_MODE}" != "flat" ]
   then
      r_comma_concat "${mode}" "post-order"
      mode="${RVAL}"
   fi

   if [ "${OPTION_WALK_DB}" = 'YES' ]
   then
      if ! sourcetree::db::dir_exists "${SOURCETREE_START}"
      then
         log_info "There is no ${SOURCETREE_DB_FILENAME} here"
      fi

      r_comma_concat "${mode}" "walkdb"
      mode="${RVAL}"
   else
      if ! sourcetree::cfg::is_config_present "${SOURCETREE_START}"
      then
         log_info "There is no sourcetree here (\"${SOURCETREE_CONFIG_DIR}\")"
      fi
   fi

   if ! sourcetree::db::is_ready "${SOURCETREE_START}"
   then
      log_warning "Sync has not run yet (mode=${SOURCETREE_MODE})"
   fi

   sourcetree::dotdump::do "${mode}"
}


sourcetree::dotdump::initialize()
{
   log_entry "sourcetree::dotdump::initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && _internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-walk.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   fi
}


sourcetree::dotdump::initialize

:
