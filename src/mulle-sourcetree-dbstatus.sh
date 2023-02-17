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
MULLE_SOURCETREE_DBSTATUS_SH='included'


sourcetree::dbstatus::usage()
{
   [ $# -ne 0 ] && log_error "$1"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dbstatus

   Tests if a database is up to date.

Returns:
    0 : yes
    1 : error
    2 : no
EOF
  exit 1
}


sourcetree::dbstatus::main()
{
   log_entry "sourcetree::dbstatus::main" "$@"

   [ "$#" -eq 0 ] || sourcetree::status::usage

   include "sourcetree::cfg"
   include "sourcetree::db"

   local configfile

   include "sourcetree::cfg"
   
   sourcetree::cfg::r_configfile_for_read "${SOURCETREE_START}"
   configfile="${RVAL}"

   local _database
   local _databasedir

   sourcetree::db::__common_databasedir "/"

   dbdonefile="${_databasedir}/.db_done"

   if [ ! -e "${configfile}" ]
   then
      log_info "No sourcetree here"
      return 1
   fi

   if rexekutor [ "${configfile}" -nt "${dbdonefile}" ]
   then
      if [ -e "${dbdonefile}" ]
      then
         log_info "Needs sync as sourcetree has edits"
      else
         log_info "Needs sync as database is not complete"
      fi
      return 2
   fi

   if ! sourcetree::db::is_ready "${SOURCETREE_START}"
   then
      log_info "Needs sync as database is not ready"
      return 2
   fi

   if rexekutor [ ! -e "${MULLE_SOURCETREE_STASH_DIR}" ]
   then
      local dependencies

      # only complain if there are dependencies in configfile
      # how does mulle-sourcetree know about this though ?
      dependencies="`sourcetree::cfg::_read "${configfile}" | grep -E -v 'no-dependency' `"
      if [ ! -z "${dependencies}" ]
      then
         log_info "No stash here"
         return 2
      fi
   fi

   log_info "Is up-to-date"
}

