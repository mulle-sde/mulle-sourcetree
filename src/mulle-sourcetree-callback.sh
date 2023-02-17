# shellcheck shell=bash
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
MULLE_SOURCETREE_CALLBACK_SH='included'


#
# "cheat" and read global _ values defined in sourcetree::walk::_visit_node and friends
# w/o passing them explicitly from mulle-sourcetree-walk
#
sourcetree::callback::call()
{
   log_entry "sourcetree::callback::call" "$@"

   local datasource="$1"; shift
   local virtual="$1"; shift
   local mode="$1"; shift
   local callback="$1"; shift

   [ -z "${callback}" ]  && _internal_fail "callback is empty"

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

#   local owner
#
#   r_basename "${datasource#/}"
#   owner="${RVAL:-.}"

   log_setting "NODE_ADDRESS         : \"${_address}\""
   log_setting "NODE_BRANCH          : \"${_branch}\""
   log_setting "NODE_FETCHOPTIONS    : \"${_fetchoptions}\""
   log_setting "NODE_FILENAME        : \"${_filename}\""
   log_setting "NODE_MARKS           : \"${_marks}\""
   log_setting "NODE_RAW_USERINFO    : \"${_raw_userinfo}\""
   log_setting "NODE_TAG             : \"${_tag}\""
   log_setting "NODE_TYPE            : \"${_nodetype}\""
   log_setting "NODE_URL             : \"${_url}\""
   log_setting "NODE_UUID            : \"${_uuid}\""

   log_setting "WALK_DATASOURCE      : \"${datasource}\""
   log_setting "WALK_DESTINATION     : \"${_destination}\""
   log_setting "WALK_MODE            : \"${mode}\""
   log_setting "WALK_NODE            : \"${_nodeline}\""
   log_setting "WALK_PARENT          : \"${WALK_PARENT}\""
   log_setting "WALK_VIRTUAL         : \"${virtual}\""
   log_setting "WALK_VIRTUAL_ADDRESS : \"${_virtual_address}\""

   #
   # "pass" these as globals
   #
   local _mode="${mode}"
   local _datasource="${datasource}"
   local _virtual="${virtual}"

   #
   # WALK_NODE the current nodelines from config or database, unchanged
   #
   # NODE_ADDRESS-NODE_UUID as defined in nodeline, unchanged
   #
   # MULLE_DATASOURCE  : config or database "handle" where nodelines was read
   # MULLE_DESTINATION : either "_address" or in shared case basename of "_address"
   # WALK_VIRTUAL     : either ${MULLE_SOURECTREE_SHARE_DIR} or ${MULLE_VIRTUAL_ROOT}
   #
   #
   log_debug "Calling callback: NODE_ADDRESS=${_address} NODE_FILENAME=${_filename} ${callback} "

   local dependency

   r_basename "${datasource}"
   dependency="${RVAL}"

   #
   # DO NOT WRAP THIS IN A SUBSHELL, BECAUSE THE CALLBACK LOSES STATE!
   # TODO: since callback is evaluated we actually do not not need to pass the
   # extra parameters around anymore
   #
   NODE_ADDRESS="${_address}" \
   NODE_BRANCH="${_branch}" \
   NODE_FETCHOPTIONS="${_fetchoptions}" \
   NODE_FILENAME="${_filename}" \
   NODE_MARKS="${_marks}" \
   NODE_RAW_USERINFO="${_raw_userinfo}" \
   NODE_TAG="${_tag}" \
   NODE_TYPE="${_nodetype}" \
   NODE_URL="${_url}" \
   NODE_UUID="${_uuid}" \
   WALK_DATASOURCE="${datasource}" \
   WALK_DEPENDENCY="${dependency}" \
   WALK_DESTINATION="${_destination}" \
   WALK_MODE="${mode}" \
   WALK_INDENT="${WALK_INDENT}" \
   WALK_INDEX="${WALK_INDEX}" \
   WALK_LEVEL="${WALK_LEVEL}" \
   WALK_NODE="${_nodeline}" \
   WALK_PARENT="${WALK_PARENT}" \
   WALK_VIRTUAL="${virtual}" \
   WALK_VIRTUAL_ADDRESS="${_virtual_address}" \
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
