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
MULLE_SOURCETREE_REWRITE_SH="included"


sourcetree::rewrite::usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} rewrite [options]

   If you hand-edited a sourcetree config file, the marks may contain 
   duplicates and might be sorted in the wrong order. With "rewrite" you can
   clean up.

   This will lose all '#' comments.

EOF
  exit 1
}



#
# this cleans up the marks and resorts them
#
sourcetree::rewrite::do()
{
   log_entry "sourcetree::rewrite::do" "$@"

   local config="$1"

   local nodelines
   local nodeline
   local output

   nodelines="`sourcetree::cfg::read "${config}"`" || exit 1

   [ -z "${nodelines}" ] && return 0

   local _branch
   local _address
   local _fetchoptions
   local _nodetype
   local _marks
   local _raw_userinfo
   local _tag
   local _url
   local _uuid
   local _userinfo

   shell_disable_glob; IFS=$'\n'
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      sourcetree::nodeline::parse "${nodeline}"  # memo: :_marks used raw

      sourcetree::node::r_sanitized_marks "${_marks}"
      _marks="${RVAL}"

      if [ "${_marks}" != "${RVAL}" ]
      then
         log_verbose "${_address} marks changed"
      fi
      _marks="${RVAL}"

      sourcetree::node::_r_to_nodeline
      r_add_line "${output}" "${RVAL}"
      output="${RVAL}"
   done
   IFS="${DEFAULT_IFS}"; shell_enable_glob

   sourcetree::cfg::write "${config}" "${output}"
}


sourcetree::rewrite::main()
{
   log_entry "sourcetree::rewrite::main" "$@"

   local OPTION_REMOVE_GRAVEYARD="DEFAULT"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::rewrite::usage
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown rewrite option $1"
            sourcetree::rewrite::usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || sourcetree::rewrite::usage

   log_info "Rewriting marks for sourcetree"
   sourcetree::rewrite::do "/" || exit 1
}


sourcetree::rewrite::initialize()
{
   log_entry "sourcetree::rewrite::initialize"

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
}


sourcetree::rewrite::initialize

:

