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
MULLE_SOURCETREE_CALLBACK_SH="included"

#
# convenience for callbacks in shared configuration
# TODO: is this still needed for statzs ? isn't this the same as _filename
# now ?
#
__walk_get_db_filename()
{
   log_entry "__walk_get_db_filename" "$@"

   if ! nodemarks_contain "${MULLE_MARKS}" "fs"
   then
      return
   fi

   local database

   database="${MULLE_DATASOURCE}"
   if nodemarks_contain "${MULLE_MARKS}" "share" && \
      [ "${SOURCETREE_MODE}" = "share" -a ! -z "${MULLE_URL}" ]
   then
      database="/"
      if db_is_ready "${database}"
      then
         local uuid

         uuid="`db_fetch_uuid_for_url "${database}" "${MULLE_URL}" `"
         if [ ! -z "${uuid}" ]
         then
            db_fetch_filename_for_uuid "${database}" "${uuid}"
            return
         fi
         # ok could be an edit
      fi

      r_fast_basename "${MULLE_ADDRESS}"
      filepath_concat "${MULLE_SOURCETREE_STASH_DIR}" "${RVAL}"
      return
   fi

   if db_is_ready "${database}"
   then
      db_fetch_filename_for_uuid "${database}" "${MULLE_UUID}"
   else
      echo "${MULLE_FILENAME}"
   fi
}


#
# "cheat" and read global _ values defined in _visit_node and friends
# w/o passing them explicitly from mulle-sourcetree-walk
#
__call_callback()
{
   log_entry "__call_callback" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift
   local mode="$1"; shift
   local callback="$1"; shift

   [ -z "${callback}" ]  && internal_fail "callback is empty"

   local evaluator

   case ",${mode}," in
      *,no-trace,*)
         evaluator=""
         case ",${mode}," in
            *,eval,*)
               evaluator="eval"
            ;;
         esac
      ;;

      *)
         evaluator="rexekutor"
         case ",${mode}," in
            *,eval,*)
               evaluator="eval_rexekutor"
            ;;
         esac
      ;;
   esac

   if [ "$MULLE_FLAG_LOG_SETTINGS" = 'YES' ]
   then
      log_trace2 "MULLE_ADDRESS:         \"${_address}\""
      log_trace2 "MULLE_BRANCH:          \"${_branch}\""
      log_trace2 "MULLE_DATASOURCE:      \"${datasource}\""
      log_trace2 "MULLE_DESTINATION:     \"${_destination}\""
      log_trace2 "MULLE_FETCHOPTIONS:    \"${_fetchoptions}\""
      log_trace2 "MULLE_FILENAME:        \"${_filename}\""
      log_trace2 "MULLE_MARKS:           \"${_marks}\""
      log_trace2 "MULLE_MODE:            \"${mode}\""
      log_trace2 "MULLE_NODE:            \"${_nodeline}\""
      log_trace2 "MULLE_NODETYPE:        \"${_nodetype}\""
      log_trace2 "MULLE_TAG:             \"${_tag}\""
      log_trace2 "MULLE_URL:             \"${_url}\""
      log_trace2 "MULLE_RAW_USERINFO:    \"${_raw_userinfo}\""
      log_trace2 "MULLE_USERINFO:        \"${_userinfo}\""
      log_trace2 "MULLE_UUID:            \"${_uuid}\""
      log_trace2 "MULLE_VIRTUAL:         \"${virtual}\""
      log_trace2 "MULLE_VIRTUAL_ADDRESS: \"${_virtual_address}\""
   fi

   #
   # "pass" these as globals
   #
   local _mode="${mode}"
   local _datasource="${datasource}"
   local _virtual="${virtual}"

   #
   # MULLE_NODE the current nodelines from config or database, unchanged
   #
   # MULLE_ADDRESS-MULLE_UUID as defined in nodeline, unchanged
   #
   # MULLE_DATASOURCE  : config or database "handle" where nodelines was read
   # MULLE_DESTINATION : either "_address" or in shared case basename of "_address"
   # MULLE_VIRTUAL     : either ${MULLE_SOURECTREE_SHARE_DIR} or ${MULLE_VIRTUAL_ROOT}
   #
   #
   log_fluff "Calling callback: ${callback} $*"

   #
   # DO NOT WRAP THIS IN A SUBSHELL, BECAUSE THE CALLBACK LOSES STATE THEN
   # TODO: since callback is evaluated we actually do not not need to pass the
   # extra parameters around anymore
   #
   MULLE_NODE="${_nodeline}" \
   MULLE_ADDRESS="${_address}" \
   MULLE_BRANCH="${_branch}" \
   MULLE_FETCHOPTIONS="${_fetchoptions}" \
   MULLE_MARKS="${_marks}" \
   MULLE_NODETYPE="${_nodetype}" \
   MULLE_RAW_USERINFO="${_raw_userinfo}" \
   MULLE_URL="${_url}" \
   MULLE_USERINFO="${_userinfo}" \
   MULLE_TAG="${_tag}" \
   MULLE_UUID="${_uuid}" \
   MULLE_DATASOURCE="${datasource}" \
   MULLE_DESTINATION="${_destination}" \
   MULLE_FILENAME="${_filename}" \
   MULLE_MODE="${mode}" \
   MULLE_VIRTUAL="${virtual}" \
   MULLE_VIRTUAL_ADDRESS="${_virtual_address}" \
      ${evaluator} "${callback}" "$@"
   rval="$?"

   if [ ${rval} -eq 0 ]
   then
      return 0
   fi

   log_debug "Command \"${callback}\" returned $rval for node \"${_address}\""

   case ",${mode}," in
      *,lenient,*)
         return 0
      ;;
   esac

   return $rval
}
