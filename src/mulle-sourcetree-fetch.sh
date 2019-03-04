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
MULLE_SOURCETREE_FETCH_SH="included"


r_sourcetree_guess_address()
{
   log_entry "r_sourcetree_guess_address" "$@"

   local url="$1"
   local nodetype="${2:-local}"

   [ -z "${url}" ] && fail "URL is empty"

   local evaledurl

   evaledurl="`eval echo "${url}"`"
   if [ -z "${evaledurl}" ]
   then
      RVAL=
      return 1
   fi

   RVAL="`${MULLE_FETCH:-mulle-fetch} \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_FETCH_FLAGS} \
            nameguess \
               -s "${nodetype}" \
               "${evaledurl}"`"

   log_fluff "${MULLE_FETCH:-mulle-fetch} returned \"${RVAL}\" as \
default address for url ($url)"
}


r_sourcetree_guess_nodetype()
{
   log_entry "r_sourcetree_guess_nodetype" "$@"

   local url="$1"

   [ -z "${url}" ] && fail "URL is empty"

   local evaledurl

   evaledurl="`eval echo "${url}"`"
   if [ -z "${evaledurl}" ]
   then
      RVAL=
      return 1
   fi

   RVAL="`${MULLE_FETCH:-mulle-fetch} \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_FETCH_FLAGS} \
               typeguess \
                  "${evaledurl}"`" || return 1

   log_fluff "${MULLE_FETCH:-mulle-fetch} determined \"${RVAL}\" as \
nodetype from url ($evaledurl)"
   return 0
}


sourcetree_sync_operation()
{
   log_entry "sourcetree_sync_operation" "$@"

   local opname="$1"
   local options="$2"

   [ -z "${opname}" ] && internal_fail "opname is empty"

   local url="$3"
   local address="$4"
   local branch="$5"
   local tag="$6"
   local nodetype="$7"
   local fetchoptions="$8"

   [ -z "${url}" ] && fail "URL is empty"

   local rval
   local evaledurl
   local evaledbranch
   local evaledtag
   local evaledfetchoptions

   # we use evaluated values to then pass as "environment" into the
   # echo, this allows us to specify a URL as
   #
   evaledtag="`eval echo "${tag}"`"
   evaledbranch="`eval echo "${branch}"`"
   evaledurl="`MULLE_BRANCH="${evaledbranch}" MULLE_TAG="${evaledtag}" eval echo "${url}"`"
   evaledfetchoptions="`MULLE_URL="${evaledurl}" MULLE_BRANCH="${evaledbranch}" MULLE_TAG="${evaledtag}" eval echo "${_fetchoptions}"`"

   [ -z "${evaledurl}" ] && fail "URL \"${url}\" evaluates to empty"

   case "${nodetype}" in
      file)
         # does not implement local search
      ;;

      *)
         log_fluff "Looking for local copy of \
${C_RESET_BOLD}${evaledurl}${C_INFO}"

         local localurl
         local localnodetype

         localurl="$( eval_exekutor ${MULLE_FETCH:-mulle-fetch} \
                                          "${MULLE_TECHNICAL_FLAGS}" \
                                          "${MULLE_FETCH_FLAGS}" \
                                       "search-local" \
                                          --scm "'${nodetype}'" \
                                          --tag "'${evaledtag}'" \
                                          --branch "'${evaledbranch}'" \
                                          --options "'${evaledfetchoptions}'" \
                                          --url "'${evaledurl}'" \
                                          "'${address}'" )"
         if [ ! -z "${localurl}" ]
         then
            evaledurl="${localurl}"
            log_verbose "Local URL found \"${localurl}\""

            r_sourcetree_guess_nodetype "${localurl}"
            localnodetype="${RVAL}"

            if [ ! -z "${localnodetype}" -a "${localnodetype}" != "local" ]
            then
               nodetype="${localnodetype}"
            fi
         else
            log_fluff "No local URL found"
         fi
      ;;
   esac

   eval_exekutor ${MULLE_FETCH:-mulle-fetch} \
                       "${MULLE_TECHNICAL_FLAGS}" \
                       "${MULLE_FETCH_FLAGS}" \
                    "${opname}" \
                       --scm "'${nodetype}'" \
                       --tag "'${evaledtag}'" \
                       --branch "'${evaledbranch}'" \
                       --options "'${evaledfetchoptions}'" \
                       --url "'${evaledurl}'" \
                       ${options} \
                       "'${address}'"
}


sourcetree_list_operations()
{
   log_entry "sourcetree_list_operations" "$@"

   local nodetype="$1"

   ${MULLE_FETCH:-mulle-fetch} \
         ${MULLE_TECHNICAL_FLAGS} \
         ${MULLE_FETCH_FLAGS} -s \
      operation -s "${nodetype}" list
}



sourcetree_sync_initialize()
{
   log_entry "sourcetree_sync_initialize" "$@"

   if [ -z "${MULLE_SOURCETREE_NODELINE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodeline.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodeline.sh" || exit 1
   fi
}


sourcetree_sync_initialize

:
