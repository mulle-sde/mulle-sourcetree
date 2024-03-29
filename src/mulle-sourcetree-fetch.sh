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
MULLE_SOURCETREE_FETCH_SH='included'


sourcetree::fetch::r_guess_address()
{
   log_entry "sourcetree::fetch::r_guess_address" "$@"

   local evaledurl="$1"
   local evalednodetype="${2:-local}"

   [ -z "${evaledurl}" ] && fail "URL is empty"

   if [ "${evalednodetype}" = "none" ]
   then
      RVAL="${evaledurl}"
      return 0
   fi

   local rval

   RVAL="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
               ${MULLE_TECHNICAL_FLAGS} \
               ${MULLE_DOMAIN_FLAGS} \
            nameguess \
               -s "${evalednodetype}" \
               "${evaledurl}"`"
   rval=$?
   [ $rval -eq 127 ] \
   && fail "mulle-domain not found (you may need to run mulle-sde upgrade)"

   _log_fluff "${MULLE_DOMAIN:-mulle-domain} returned \"${RVAL}\" as \
default address for url ($evaledurl)"
   return $rval
}


#
# returns "local" if the URL is found on the local filesystem
# this doesn't distinguish then between
sourcetree::fetch::r_guess_nodetype()
{
   log_entry "sourcetree::fetch::r_guess_nodetype" "$@"

   local url="$1"

   [ -z "${url}" ] && fail "URL is empty"

   local evaledurl

   r_expanded_string "${url}"
   evaledurl="${RVAL}"

   case "${evaledurl}" in
      "")
         RVAL=
         return 1
      ;;

      *:*)
         # URL guess
      ;;

      # local filesystem guesses
      /*|~/*|\.\./*|\./*)
         if [ -e "${evaledurl}" ]
         then
            log_fluff "\"${url}\" looks like a local nodetype url (${evaledurl})"
            RVAL="local"
            return
         fi
      ;;
   esac

   local rval

   RVAL="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
                  ${MULLE_TECHNICAL_FLAGS} \
                  ${MULLE_DOMAIN_FLAGS} \
               typeguess \
                  "${evaledurl}"`" || return 1
   rval=$?
   [ $rval -eq 127 ] \
   && fail "mulle-domain not found (you may need to run mulle-sde upgrade)"

   _log_fluff "${MULLE_DOMAIN:-mulle-domain} determined \"${RVAL}\" as \
nodetype from url ($evaledurl)"
   return $rval
}


#
# resolves the url actually
#
sourcetree::fetch::r_resolve_url_with_tag()
{
   log_entry "sourcetree::fetch::r_resolve_url_with_tag" "$@"

   local url="$1"
   local tag="$2"
   local scm="$3"

   [ "${scm}" = 'comment' ] \
      && _internal_fail "comment should have been ignored previously"

   local type 
   local rval

   type="`rexekutor "${MULLE_SEMVER:-mulle-semver}" \
                         ${MULLE_TECHNICAL_FLAGS} \
                      "qualifier-type" \
                         "${tag}" `"
   rval=$?
   
   [ $rval -eq 127 ] \
      && fail "mulle-semver not found (you may need to run mulle-sde upgrade)"

   case "${type}" in
      NO|EMPTY|SEMVER)
         RVAL="${url}"
         return 0
      ;;
   esac   

   RVAL="`rexekutor "${MULLE_DOMAIN:-mulle-domain}" \
                         ${MULLE_TECHNICAL_FLAGS} \
                      "resolve" \
                         --scm "${scm}" \
                         --latest \
                         "${url}" \
                         "${tag}" `"
   rval=$?
   [ $rval -eq 127 ] \
      && fail "mulle-domain not found (you may need to run mulle-sde upgrade)"

   return $rval
}


sourcetree::fetch::sync_operation()
{
   log_entry "sourcetree::fetch::sync_operation" "$@"

   local opname="$1"
   local options="$2"

   [ -z "${opname}" ] && _internal_fail "opname is empty"

   local _url="$3"
   local _address="$4"
   local _branch="$5"
   local _tag="$6"
   local _nodetype="$7"
   local _fetchoptions="$8"

   [ -z "${_address}" ] && fail "Address is empty"
   [ -z "${_url}" ] && fail "URL is empty"

   local original_nodetype
   local original_tag
   local original_branch

   local _evaledurl
   local _evalednodetype
   local _evaledbranch
   local _evaledtag
   local _evaledfetchoptions

   sourcetree::node::__evaluate_values

   # we check how the values would be, if there are no variables
   # replaced. to get the default value.

   # original_nodetype="`eval env -i printf "%s" "${_nodetype}"`"

   # branch "suddenly" set ? then ignore tag
   r_expanded_string "${_branch}" 'NO' # get default value
   original_branch="${RVAL}"

   if [ -z "${original_branch}" -a ! -z "${_evaledbranch}" ]
   then
      _evaledtag=""
   fi

   # tag "suddenly" set ? then ignore branch
   r_expanded_string "${_tag}" 'NO'  # get default value
   original_tag="${RVAL}"

   if [ -z "${original_tag}" -a ! -z "${_evaledtag}" ]
   then
      _evaledbranch=""
   fi

   #
   # if the nodetype changes, we check that branch/tag are still useful
   # archives prefer tag, git prefers branch/tag combination
   #
   case "${_evalednodetype}" in
      "")
         fail "Nodetype \"${_nodetype}\" evaluates to empty"
      ;;
   esac

   MULLE_BRANCH="${_evaledbranch}" \
   MULLE_TAG="${_evaledtag}" \
   MULLE_TAG_OR_BRANCH="${_evaledtag:-${_evaledbranch}}" \
      r_expanded_string "${_url}"
      _evaledurl="${RVAL}"

   #
   # If a tag is specified, we can - for some hosts - do filtering
   # like >=1.0.5. This is done by mulle-fetch though. We also use
   # it to "compose" the url from the tag. We also treat latest
   # in a special way. This can "hammer" github though, so we have
   # a way to turn it off
   #
   if [ ! -z "${_evaledtag}" ]
   then
      if [ "${MULLE_SOURCETREE_RESOLVE_TAG}" = 'YES' ]
      then
         if sourcetree::fetch::r_resolve_url_with_tag "${_evaledurl}" \
                                                      "${_evaledtag}" \
                                                      "${_evalednodetype}"
         then
            _evaledurl="${RVAL}"
         else
            case "${_evaledurl}" in
               *"${_evaledtag}"*)
               ;;

               *)
                  _log_warning "Don't know how to modify URL \"${_evaledurl}\" \
for tag \"${_evaledtag}\". Hope for symlink."
               ;;
            esac
         fi
      else
         _log_fluff "Not resolving tag \"${_evaledtag}\" as \
MULLE_SOURCETREE_RESOLVE_TAG is NO"
      fi
   fi

   #
   # hackish, used for git scm really
   #
   case "${_evaledurl}" in
      *'##'*)
         _evaledtag="${_evaledurl#*##}"
         _evaledurl="${_evaledurl%##*}"
      ;;
   esac

   [ -z "${_evaledurl}" ] && _internal_fail "URL \"${_url}\" returned as empty"

   MULLE_BRANCH="${_evaledbranch}" \
   MULLE_TAG="${_evaledtag}" \
   MULLE_TAG_OR_BRANCH="${_evaledtag:-${_evaledbranch}}" \
   MULLE_URL="${_evaledurl}" \
      r_expanded_string "${_fetchoptions}"
   _evaledfetchoptions="${RVAL}"

   local cmdoptions

   if [ ! -z "${_evaledtag}" ]
   then
      r_concat "${cmdoptions}" "--tag '${_evaledtag}'"
      cmdoptions="${RVAL}"
   fi
   if [ ! -z "${_evaledbranch}" ]
   then
      r_concat "${cmdoptions}" "--branch '${_evaledbranch}'"
      cmdoptions="${RVAL}"
   fi
   if [ ! -z "${_evaledfetchoptions}" ]
   then
      r_concat "${cmdoptions}" "--options '${_evaledfetchoptions}'"
      cmdoptions="${RVAL}"
   fi

#   local rval
#   local localurl
#   local localnodetype
#   local cmd2options
#
#   case "${_evalednodetype}" in
#      file)
#         # does not implement local search
#      ;;
#
#      comment)
#         _internal_fail "comment should have been ignored previously"
#      ;;
#
#      *)
#         _log_fluff "Looking for local copy of \
#${C_RESET_BOLD}${_evaledurl}${C_INFO}"
#
#         cmd2options="${cmdoptions}"
#         if [ ! -z "${_evaledurl}" ]
#         then
#            r_concat "${cmdoptions}" "--url '${_evaledurl}'"
#            cmd2options="${RVAL}"
#         fi
#
#         localurl="$( eval_exekutor "'${MULLE_FETCH:-mulle-fetch}'" \
#                                          "${MULLE_TECHNICAL_FLAGS}" \
#                                       "search-local" \
#                                          "${cmd2options}" \
#                                          "'${_address}'" )"
#         rval=$?
#         [ $rval -eq 127 ] && fail "mulle-fetch not found"
#
#         if [ ! -z "${localurl}" ]
#         then
#            _evaledurl="${localurl}"
#
#            sourcetree::fetch::r_guess_nodetype "${localurl}"
#            localnodetype="${RVAL}"
#
#            log_fluff "A ${localnodetype} matched at \"${localurl}\""
#            if [ ! -z "${localnodetype}" -a "${localnodetype}" != "local" ]
#            then
#               case "${options}" in
#                  *--symlink*)
#                     _evalednodetype="${localnodetype}"
#                  ;;
#               esac
#               # this is needed for a local match of a tar url to git url
#               # BUT it was commented out at some point
#            fi
#         else
#            log_fluff "No local URL found"
#         fi
#      ;;
#   esac

   #
   # _evaledurl may have changed due to local lookup
   #
   if [ ! -z "${_evaledurl}" ]
   then
      r_concat "${cmdoptions}" "--url '${_evaledurl}'"
      cmdoptions="${RVAL}"
   fi

   #
   # evalednodetype may have changed due to local lookup
   #
   if [ ! -z "${_evalednodetype}" ]
   then
      r_concat "--source '${_evalednodetype}'" "${cmdoptions}"
      cmdoptions="${RVAL}"
   fi

   eval_exekutor ${MULLE_FETCH:-mulle-fetch} \
                       "${MULLE_TECHNICAL_FLAGS}" \
                    "${opname}" \
                       "${cmdoptions}" \
                       "${options}" \
                       "'${_address}'"
   rval=$?
   [ $rval -eq 127 ] && fail "mulle-fetch not found"

   return $rval
}


sourcetree::fetch::r_list_operations()
{
   log_entry "sourcetree::fetch::r_list_operations" "$@"

   local nodetype="$1"

   [ "${nodetype}" = 'comment' ] \
      && _internal_fail "comment should have been ignored previously"

   local cachekey
   local cachekey_value

   include "case"

   r_smart_upcase_identifier "${nodetype}"
   cachekey="_SOURCETREE_OPERATIONS_${RVAL}"

   r_shell_indirect_expand "${cachekey}"
   cachekey_value="${RVAL}"

   if [ -z "${cachekey_value}" ]
   then
      if ! value="`"${MULLE_FETCH:-mulle-fetch}" \
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

      cachekey_value="${value}"
   fi

   RVAL="${cachekey_value}"
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



sourcetree::fetch::initialize()
{
   log_entry "sourcetree::fetch::initialize" "$@"

   include "sourcetree::node"

   include "sourcetree::nodeline"
}


sourcetree::fetch::initialize

:
