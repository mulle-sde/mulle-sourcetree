#! /usr/bin/env bash
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in nodetype and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of nodetype code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
#   Neither the uuid of Mulle kybernetiK nor the names of its contributors
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
MULLE_SOURCETREE_ZOMBIFY_SH="included"


#
# used to do this with chmod -h, alas Linux can't do that
# So we create a special directory .zombies
# and create files there
#
#
# ###
#
#
#
#
zombify_nodes()
{
   log_entry "zombify_nodes" "$@"

   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR"

   log_fluff "Marking all nodes as zombies for now ($PWD)"

   local zombiepath

   zombiepath="${SOURCETREE_DB_DIR}/.zombies"
   rmdir_safer "${zombiepath}"

   if dir_has_files "${SOURCETREE_DB_DIR}"
   then
      mkdir_if_missing "${zombiepath}"

      exekutor cp ${OPTION_COPYMOVEFLAGS} "${SOURCETREE_DB_DIR}/"* "${zombiepath}/" >&2
   fi
}


is_node_alive()
{
   log_entry "is_node_alive" "$@"

   local uuid="$1"

   [ -z "${uuid}" ] && internal_fail "uuid is empty"
   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR"

   zombie="${SOURCETREE_DB_DIR}/.zombies/${uuid}"
   [ ! -e "${zombie}" ]
}


diagnose_node_as_alive()
{
   log_entry "diagnose_node_as_alive" "$@"

   local uuid="$1"

   local zombie

   [ -z "${uuid}" ] && internal_fail "uuid is empty"
   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR"

   zombie="${SOURCETREE_DB_DIR}/.zombies/${uuid}"
   if [ -e "${zombie}" ]
   then
      log_fluff "Marking \"${uuid}\" as alive"

      remove_file_if_present "${zombie}" || fail "failed to delete zombie ${zombie}"
   else
      log_fluff "\"${uuid}\" is alive as `absolutepath "${zombie}"` is not present"
   fi
}


#
#
#

bury_node()
{
   log_entry "bury_node" "$@"

   local uuid="$1"
   local destination="$2"

   [ $# -eq 2 ] || internal_fail "api error"

   [ -z "${uuid}" ] && internal_fail "uuid is empty"
   [ -z "${destination}" ] && internal_fail "destination is empty"
   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR"

   local gravepath

   gravepath="${SOURCETREE_DB_DIR}/.graveyard/${uuid}"

   if [ -L "${destination}" ]
   then
      log_verbose "Removing old symlink \"${destination}\""
      exekutor rm -f "${destination}" >&2
      return
   fi

   if [ -e "${gravepath}" ]
   then
      log_fluff "Repurposing old grave \"${gravepath}\""
      exekutor rm -rf "${gravepath}" >&2
   else
      mkdir_if_missing "${SOURCETREE_DB_DIR}/.graveyard"
   fi

   log_info "Burying \"${destination}\" in grave \"${gravepath}\""
   exekutor mv ${OPTION_COPYMOVEFLAGS} "${destination}" "${gravepath}" >&2
}


_bury_zombie()
{
   log_entry "_bury_zombie" "$@"

   local zombie="$1"

   [ -z "${zombie}" ] && internal_fail "zombie is empty"

   local uuid
   local destination
   local gravepath
   local nodeline

   nodeline="`db_get_nodeline_of_zombie "${zombie}"`"

   local branch
   local destination
   local fetchoptions
   local nodetype
   local marks
   local tag
   local url
   local userinfo
   local uuid

   nodeline_parse "${nodeline}"

   local delete

   delete="YES"
   if nodemarks_contain_nodelete "${marks}"
   then
      delete="NO"
      log_fluff "${url} is marked as nodelete so not burying"
   fi

   # forget it now, so it doesn't come up in db_get_all_destinations
   db_forget "${uuid}"

   if [ -e "${destination}" ]
   then
      if [ "${delete}" = "YES" ]
      then
         #
         # need to check, that not another repository now uses the same
         # destination
         #
         local inuse

         inuse="`db_get_all_destinations`"
         if fgrep -q -s -x "${destination}" <<< "${inuse}"
         then
            log_fluff "Another node is using \"${destination}\" now"
         else
            if [ -L "${destination}"  ]
            then
               log_info "Removing unused symlink ${C_MAGENTA}${C_BOLD}${destination}${C_INFO}"
               exekutor rm "${destination}" >&2
            else
               bury_node "${uuid}" "${destination}"
            fi
         fi
      fi
   else
      log_fluff "Zombie \"${destination}\" vanished or never existed ($PWD)"
   fi

   remove_file_if_present "${zombie}"
}


bury_node_zombies()
{
   log_entry "bury_node_zombies" "$@"

   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR"

   log_fluff "Burying zombie nodes ($PWD)"

   local zombie
   local zombiepath

   zombiepath="${SOURCETREE_DB_DIR}/.zombies"

   if dir_has_files "${zombiepath}"
   then
      log_fluff "Moving zombies into graveyard"

      for zombie in `ls -1 "${zombiepath}/"* 2> /dev/null`
      do
         if [ -f "${zombie}" ]
         then
            _bury_zombie "${zombie}"
         fi
      done
   fi

   if [ -d "${zombiepath}" ]
   then
      exekutor rm -rf ${OPTION_COPYMOVEFLAGS} "${zombiepath}" >&2
   fi
}

