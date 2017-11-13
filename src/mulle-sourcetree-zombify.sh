#! /usr/bin/env bash
#
#   Copyright (c) 2015 Nat! - Mulle kybernetiK
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
# it must have been ascertained that address is not in use my other nodes
#
_zombie_bury()
{
   log_entry "bury_node" "$@"

   local address="$1"
   local uuid="$2"

   [ $# -eq 2 ] || internal_fail "api error"

   [ -z "${uuid}" ] && internal_fail "uuid is empty"
   [ -z "${address}" ] && internal_fail "address is empty"

   [ -z "${SOURCETREE_DB_DIR}" ] && internal_fail "SOURCETREE_DB_DIR"

   local gravepath

   gravepath="${SOURCETREE_DB_DIR}/.graveyard/${uuid}"

   if [ -L "${address}" ]
   then
      log_verbose "Removing old symlink \"${address}\""
      exekutor rm -f "${address}" >&2
      return
   fi

   if [ -e "${gravepath}" ]
   then
      log_fluff "Repurposing old grave \"${gravepath}\""
      exekutor rm -rf "${gravepath}" >&2
   else
      mkdir_if_missing "${SOURCETREE_DB_DIR}/.graveyard"
   fi

   log_info "Burying \"${address}\" in grave \"${gravepath}\""
   exekutor mv ${OPTION_COPYMOVEFLAGS} "${address}" "${gravepath}" >&2
}


zombie_bury_node()
{
   log_entry "zombie_bury_node" "$@"

   local address="$1"
   local uuid="$2"

   [ -z "${uuid}" ]    && internal_fail "uuid is empty"
   [ -z "${address}" ] && internal_fail "address is empty"

   # forget it now, so it doesn't come up in db_get_all_addresss
   db_forget "${uuid}"

   local inuse

   inuse="`db_get_all_addresss`"
   if fgrep -q -s -x "${address}" <<< "${inuse}"
   then
      log_fluff "Another node is using \"${address}\" now"
   else
      if [ -L "${address}"  ]
      then
         log_info "Removing unused symlink ${C_MAGENTA}${C_BOLD}${address}${C_INFO}"
         exekutor rm "${address}" >&2
      else
         _zombie_bury "${address}" "${uuid}"
      fi
   fi
}


zombie_bury_nodeline()
{
   log_entry "zombie_bury_nodeline" "$@"

   local nodeline="$1"

   local branch
   local address
   local fetchoptions
   local nodetype
   local marks
   local tag
   local url
   local userinfo
   local uuid

   nodeline_parse "${nodeline}"


   if [ -e "${address}" ]
   then
      if nodemarks_contain_nodelete "${marks}"
      then
         log_fluff "${url} is marked as nodelete so not burying"
      else
         zombie_bury_node "${address}" "${uuid}"
      fi
   else
      db_forget "${uuid}"
      log_fluff "\"${address}\" vanished or never existed ($PWD)"
   fi
}


zombie_bury_zombie()
{
   log_entry "zombie_bury_zombie" "$@"

   local zombie="$1"

   [ -z "${zombie}" ] && internal_fail "zombie is empty"

   local uuid
   local address
   local gravepath
   local nodeline

   nodeline="`db_get_nodeline_of_zombie "${zombie}"`"

   zombie_bury_nodeline "${nodeline}"

   remove_file_if_present "${zombie}"
}


zombie_bury_zombies()
{
   log_entry "zombie_bury_zombies" "$@"

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
            zombie_bury_zombie "${zombie}"
         fi
      done
   fi

   if [ -d "${zombiepath}" ]
   then
      exekutor rm -rf ${OPTION_COPYMOVEFLAGS} "${zombiepath}" >&2
   fi
}



zombie_clean_usage()
{
    cat <<EOF >&2
Usage:
   ${MULLE_EXECUTABLE_NAME} clean

   Remove sources placed into the projecttree by mulle-sourcetree.

   This command only reads the local database.
EOF
  exit 1
}


zombie_clean_all_nodes()
{
   if ! db_exists
   then
      log_info "Nothing to clean, since no update has run yet"
      return
   fi

   # shellcheck source=mulle-sourcetree-nodeline.sh
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-zombify.sh" || exit 1

   local nodeline
   local parent

   IFS="
"
   for nodeline in `db_get_all_nodelines`
   do
      IFS="${DEFAULT_IFS}"

      zombie_bury_nodeline "${nodeline}"

      parent="`dirname -- "${address}"`"
      case "${parent}" in
         .|""|..)
         ;;

         *)
            rmdir_if_empty "${parent}"
         ;;
      esac
   done

   IFS="${DEFAULT_IFS}"
}


zombie__clean_main()
{
   log_entry "zombie__clean_main" "$@"

   local OPTION_REMOVE_GRAVEYARD="DEFAULT"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h|-help|--help)
            zombie_clean_usage
         ;;

         -*)
            log_error "${MULLE_EXECUTABLE_FAIL_PREFIX}: Unknown clean option $1"
            zombie_clean_usage
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0 ] || zombie_clean_usage

   zombie_clean_all_nodes
}


