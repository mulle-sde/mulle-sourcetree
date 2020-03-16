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

   eval printf -v evaledurl "%s" "${url}"
   if [ -z "${evaledurl}" ]
   then
      RVAL=
      return 1
   fi

   local evalednodetype

   eval printf -v evalednodetype "%s" "${nodetype}"
   if [ "${evalednodetype}" = "none" ]
   then
      RVAL="${url}"
      return 0
   fi

   RVAL="`${MULLE_FETCH:-mulle-fetch} \
               ${MULLE_TECHNICAL_FLAGS} \
            nameguess \
               -s "${evalednodetype}" \
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

   eval printf -v evaledurl "%s" "${url}"
   if [ -z "${evaledurl}" ]
   then
      RVAL=
      return 1
   fi

   RVAL="`${MULLE_FETCH:-mulle-fetch} \
                  ${MULLE_TECHNICAL_FLAGS} \
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

   [ -z "${address}" ] && fail "Address is empty"
   [ -z "${url}" ] && fail "URL is empty"

   local rval
   local evaledurl
   local evaledbranch
   local evaledtag
   local evaledfetchoptions
   local original_nodetype
   local original_tag
   local original_branch

   #
   # we use evaluated values
   #
   eval printf -v evalednodetype "%s" "${nodetype}"
   eval printf -v evaledtag      "%s" "${tag}"
   eval printf -v evaledbranch   "%s" "${branch}"


   # we check how the values would be, if there are no variables
   # replaced. to get the default value.

   # original_nodetype="`eval env -i printf "%s" "${nodetype}"`"
   original_tag="`env -i sh -c "eval printf \"%s\" \"${tag}\"" `"
   original_branch="`env -i sh -c "eval printf \"%s\" \"${branch}\"" `"

   # branch "suddenly" set ? then ignore tag
   if [ -z "${original_branch}" -a ! -z "${evaledbranch}" ]
   then
      evaledtag=""
   fi

   # tag "suddenly" set ? then ignore branch
   if [ -z "${original_tag}" -a ! -z "${evaledtag}" ]
   then
      evaledbranch=""
   fi

   #
   # if the nodetype changes, we check that branch/tag are still useful
   # archives prefer tag, git prefers branch/tag combination
   #
   case "${evalednodetype}" in
      "")
         fail "Nodetype \"${nodetype}\" evaluates to empty"
      ;;
   esac

   MULLE_BRANCH="${evaledbranch}" \
   MULLE_TAG="${evaledtag}"\
   MULLE_TAG_OR_BRANCH="${evaledtag:-${evaledbranch}}" \
      eval printf -v evaledurl "%s" "${url}"

   [ -z "${evaledurl}" ] && fail "URL \"${url}\" evaluates to empty"

   #
   # If a tag is specified, we can - for some hosts - do filtering
   # like >= 1.0.5. This is done by mulle-fetch though. We also use
   # it to "compose" the url from the tag
   #
   if [ ! -z "${evaledtag}" ]
   then
      evaledurl="`exekutor "${MULLE_FETCH:-mulle-fetch}" \
                          ${MULLE_TECHNICAL_FLAGS} \
                    "filter" \
                        --scm "${evalednodetype}" \
                        "${evaledtag}" \
                        "${evaledurl}" `" || exit 1

      [ -z "${evaledurl}" ] && internal_fail "URL \"${url}\" returned as empty"

      #
      # hackish, used for git scm really
      #
      case "${evaledurl}" in
         *'##'*)
            evaledtag="${evaledurl#*##}"
            evaledurl="${evaledurl%##*}"
         ;;
      esac
   fi

   MULLE_BRANCH="${evaledbranch}" \
   MULLE_TAG="${evaledtag}" \
   MULLE_TAG_OR_BRANCH="${evaledtag:-${evaledbranch}}" \
   MULLE_URL="${evaledurl}" \
      eval  printf -v evaledfetchoptions "%s" "${fetchoptions}"

   local cmdoptions

   if [ ! -z "${evaledtag}" ]
   then
      r_concat "${cmdoptions}" "--tag '${evaledtag}'"
      cmdoptions="${RVAL}"
   fi
   if [ ! -z "${evaledbranch}" ]
   then
      r_concat "${cmdoptions}" "--branch '${evaledbranch}'"
      cmdoptions="${RVAL}"
   fi
   if [ ! -z "${evaledfetchoptions}" ]
   then
      r_concat "${cmdoptions}" "--cmdoptions '${evaledfetchoptions}'"
      cmdoptions="${RVAL}"
   fi

   case "${evalednodetype}" in
      file)
         # does not implement local search
      ;;

      *)
         log_fluff "Looking for local copy of \
${C_RESET_BOLD}${evaledurl}${C_INFO}"

         local localurl
         local localnodetype
         local cmd2options

         cmd2options="${cmdoptions}"
         if [ ! -z "${evaledurl}" ]
         then
            r_concat "${cmdoptions}" "--url '${evaledurl}'"
            cmd2options="${RVAL}"
         fi

         localurl="$( eval_exekutor "'${MULLE_FETCH:-mulle-fetch}'" \
                                          "${MULLE_TECHNICAL_FLAGS}" \
                                       "search-local" \
                                          "${cmd2options}" \
                                          "'${address}'" )"
         if [ ! -z "${localurl}" ]
         then
            evaledurl="${localurl}"
            log_verbose "Local URL found \"${localurl}\""

            r_sourcetree_guess_nodetype "${localurl}"
            localnodetype="${RVAL}"

            if [ ! -z "${localnodetype}" -a "${localnodetype}" != "local" ]
            then
               log_fluff "Local URL found ($localnodetype)"
               # this doesn't work anymore
               # evalednodetype="${localnodetype}"
               :
            fi
         else
            log_fluff "No local URL found"
         fi
      ;;
   esac

   #
   # evaledurl may have changed due to local lookup
   #
   if [ ! -z "${evaledurl}" ]
   then
      r_concat "${cmdoptions}" "--url '${evaledurl}'"
      cmdoptions="${RVAL}"
   fi

   #
   # evalednodetype may have changed due to local lookup
   #
   if [ ! -z "${evalednodetype}" ]
   then
      r_concat "--source '${evalednodetype}'" "${cmdoptions}"
      cmdoptions="${RVAL}"
   fi

   eval_exekutor ${MULLE_FETCH:-mulle-fetch} \
                       "${MULLE_TECHNICAL_FLAGS}" \
                    "${opname}" \
                       "${cmdoptions}" \
                       "${options}" \
                       "'${address}'"
}


r_sourcetree_list_operations()
{
   log_entry "r_sourcetree_list_operations" "$@"

   local nodetype="$1"

   local cachekey

   r_uppercase "${nodetype}"
   cachekey="_SOURCETREE_OPERATIONS_${RVAL}"

   if [ -z "${!cachekey}" ]
   then
      if ! value="`${MULLE_FETCH:-mulle-fetch} \
                  ${MULLE_TECHNICAL_FLAGS} \
                  -s \
               operation -s "${nodetype}" list`"
      then
         value="ERROR"
      fi
      if [ -z "${value}" ]
      then
         value="EMPTY"
      fi
      printf -v "${cachekey}" "%s" "${value}"
   fi

   RVAL=${!cachekey}
   case "${value}" in
      ERROR)
         RVAL=""
         return 1
      ;;

      EMPTY)
         RVAL=""
      ;;
   esac

   return 0
}



sourcetree_fetch_initialize()
{
   log_entry "sourcetree_fetch_initialize" "$@"

   if [ -z "${MULLE_SOURCETREE_NODELINE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodeline.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodeline.sh" || exit 1
   fi
}


sourcetree_fetch_initialize

:
