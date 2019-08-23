#! /usr/bin/env bash
#
#   Copyright (c) 2018 Nat! - Mulle kybernetiK
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
MULLE_SOURCETREE_WRAP_SH="included"


sourcetree_wrap_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} wrap [options]

   Wrap tar and git nodetypes in environment variable.
   Wrap branches in environment variable.

EOF
  exit 1
}


sourcetree_wrap_config()
{
   local config="$1"

   local nodelines

   nodelines="`cfg_read "${config}"`"

   local nodeline
#
   local _branch
   local _address
   local _fetchoptions
   local _nodetype
   local _marks
   local _raw_userinfo
   local _userinfo
   local _tag
   local _url
   local _uuid
#

   local rewritten_nodelines
   local branch_identifier
   local nodetype_identifier
   local url_identifier

   set -o noglob ; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}" ; set +o noglob

      if [ -z "${nodeline}" ]
      then
         continue
      fi

      nodeline_parse "${nodeline}"

      r_de_camel_case_upcase_identifier "${_address}"
      identifier="${RVAL}"

      nodetype_identifier="${identifier}_NODETYPE"
      case "${_nodetype}" in
         tar|git|zip|svn)
            _nodetype="\${${nodetype_identifier}:-${_nodetype}}"
            log_debug "Changed nodetype to \"${_nodetype}\""
         ;;
      esac

      branch_identifier="${identifier}_BRANCH"
      case "${_branch}" in
         "")
            case "${_url}" in
               *${branch_identifier}:-*)
                  _branch="`sed -n -e "s/^.*\\\${${branch_identifier}:-\\([^}]*\\)}.*/\\1/p" <<< "${_url}"`"
               ;;
            esac
         ;;
      esac

      case "${_branch}" in
         "")
            _url="${_url//${branch_identifier}/MULLE_BRANCH}"

            _branch="\${${branch_identifier}}"
            # rewrite url if needed
            log_debug "Changed branch to \"${_branch}\""
         ;;

         [A-Za-z0-9]*)
            _url="${_url//${branch_identifier}:-${_branch}/MULLE_BRANCH}"
            _branch="\${${branch_identifier}:-${_branch}}"
            # rewrite url if needed
            log_debug "Changed branch to \"${_branch}\""
         ;;
      esac

      url_identifier="${identifier}_URL"
      case "${_url}" in
         http*|ftp*:|file*:|/*)
            _url="\${${url_identifier}:-${_url}}"
         ;;
      esac

      r_node_to_nodeline

      r_add_line "${rewritten_nodelines}" "${RVAL}"
      rewritten_nodelines="${RVAL}"
   done

   IFS="${DEFAULT_IFS}" ; set +o noglob

   if [ "${rewritten_nodelines}" = "${nodelines}" ]
   then
      log_fluff "No changes"
      return
   fi

   cfg_write "${config}" "${rewritten_nodelines}"
   log_verbose "Wrote changed sourcetree config"
}


sourcetree_wrap_main()
{
   log_entry "sourcetree_wrap_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_wrap_usage
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown wrap option $1"
            sourcetree_wrap_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree_wrap_usage

   log_info "Create new environment wraps for sourcetree"
   sourcetree_wrap_config "/" || exit 1
}


sourcetree_wrap_initialize()
{
   log_entry "sourcetree_wrap_initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_CASE_SH}" ]
   then
      # shellcheck source=mulle-case.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-case.sh"      || return 1
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

}


sourcetree_wrap_initialize

:

