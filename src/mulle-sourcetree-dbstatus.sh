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
    1 : no sourcetree
    2 : no (not up to date)
    3 : no (stash directory changed, needs fetch and clean)
EOF
  exit 1
}


sourcetree::dbstatus::main()
{
   log_entry "sourcetree::dbstatus::main" "$@"

   [ "$#" -eq 0 ] || sourcetree::dbstatus::usage

   # Save the original MULLE_SOURCETREE_STASH_DIR from environment before it gets overwritten
   local original_stash_dir="${MULLE_SOURCETREE_STASH_DIR}"

   include "sourcetree::cfg"
   include "sourcetree::db"

   local configfile

   sourcetree::cfg::r_configfile_for_read "${SOURCETREE_START}"
   configfile="${RVAL}"

   local _database
   local _databasedir

   sourcetree::db::__common_databasedir "${SOURCETREE_START}"

   dbdonefile="${_databasedir}/.db_done"

   if [ ! -e "${configfile}" ]
   then
      log_warning "No sourcetree here"
      return 1
   fi

   if rexekutor [ "${configfile}" -nt "${dbdonefile}" ]
   then
      if [ -e "${dbdonefile}" ]
      then
         log_warning "Needs sync as sourcetree has edits"
      else
         log_warning "Needs sync as database is not complete"
      fi
      return 2
   fi

   if ! sourcetree::db::is_ready "${SOURCETREE_START}"
   then
      log_warning "Needs sync as database is not ready"
      return 2
   fi

   # Check if the stash directory has changed
   # Get the REAL environment value from mulle-env, not the one loaded from the database
   local env_stash_dir

   env_stash_dir="`\"${MULLE_ENV:-mulle-env}\" -s environment get --output-eval MULLE_SOURCETREE_STASH_DIR 2>/dev/null`"
   if [ ! -z "${env_stash_dir}" ]
   then
      local cached_stashdir

      if cached_stashdir="`sourcetree::db::get_shareddir "${SOURCETREE_START}"`"
      then
         if [ "${cached_stashdir}" != "${env_stash_dir}" ]
         then
            log_warning "Needs sync as stash directory changed from ${C_RESET_BOLD}${cached_stashdir}${C_WARNING} to ${C_RESET_BOLD}${env_stash_dir}"
            return 3
         fi
      fi
   fi

   if rexekutor [ ! -e "${MULLE_SOURCETREE_STASH_DIR}" ]
   then
      if [ "`sourcetree::db::get_dbtype "${SOURCETREE_START}"`" = "share" ]
      then
         local dependencies
         local grep_cmdline
         local only_filtered 
         local line 

         # only complain if there are dependencies in configfile
         # how does mulle-sourcetree know about this though ?
         grep_cmdline="no-share|no-dependency|no-platform-${MULLE_UNAME}|no-fetch-platform-${MULLE_UNAME}"
         dependencies="`sourcetree::cfg::_read "${configfile}" | grep -E -v "${grep_cmdline}" `"
         if [ ! -z "${dependencies}" ]
         then
            .foreachline line in ${dependencies}
            .do
               case "${line}" in 
                  *[,:]only-platform-${MULLE_UNAME}[,:]*|*[,:]only-fetch-platform-${MULLE_UNAME}[,:]*)
                     r_add_line "${only_filtered}" "${line}"
                     only_filtered="${RVAL}"
                  ;;

                  *[,:]only-platform-*[,:]*)
                  ;;

                  *)
                     r_add_line "${only_filtered}" "${line}"
                     only_filtered="${RVAL}"
                  ;;
               esac
            .done

            if [ ! -z "${only_filtered}" ]
            then
               log_warning "No stash found at ${C_RESET_BOLD}${MULLE_SOURCETREE_STASH_DIR#${MULLE_USER_PWD}/}${C_WARNING} but expected one"
               return 2
            fi
         fi
      fi
   fi

   log_info "Is up-to-date"
   return 0
}

