#! /usr/bin/env bash
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

MULLE_SOURCETREE_NODELINE_SH="included"


# first field no -s
_nodeline_get_address()
{
   cut '-d;' -f 1
}


nodeline_get_address()
{
  cut '-d;' -f 1 <<< "$*"
}

nodeline_get_nodetype()
{
   cut -s '-d;' -f 2 <<< "$*"
}


nodeline_get_marks()
{
   cut '-d;' -f 3 <<< "$*"
}


_nodeline_get_uuid()
{
   cut -s '-d;' -f 4
}


nodeline_get_uuid()
{
   cut '-d;' -f 4 <<< "$*"
}


_nodeline_get_url()
{
   cut -s '-d;' -f 5
}

nodeline_get_url()
{
   cut '-d;' -f 5 <<< "$*"
}


nodeline_get_branch()
{
   cut -s '-d;' -f 6 <<< "$*"
}


nodeline_get_tag()
{
   cut -s '-d;' -f 7 <<< "$*"
}


nodeline_get_fetchoptions()
{
   cut '-d;' -f 8 <<< "$*"
}


# if userinfo was last it could contain unquoted ;
# but who cares ?
nodeline_get_userinfo()
{
   cut '-d;' -f 9 <<< "$*"
}



#
# This function sets values of variables that should be declared
# in the caller!
#
#   # nodeline_parse
#
#   local branch
#   local address
#   local fetchoptions
#   local nodetype
#   local marks
#   local tag
#   local url
#   local uuid
#   local userinfo
#
nodeline_parse()
{
   log_entry "nodeline_parse" "$@"

   local nodeline="$1"

   [ -z "${nodeline}" ] && internal_fail "nodeline_parse: nodeline is empty"

   IFS=";" \
      read -r address nodetype marks uuid \
              url branch tag fetchoptions \
              userinfo  <<< "${nodeline}"

   [ -z "${address}" ]   && internal_fail "address is empty"
   [ -z "${nodetype}" ]  && internal_fail "nodetype is empty"
   [ -z "${uuid}" ]      && internal_fail "uuid is empty"

   case "${userinfo}" in
      base64:*)
         local decoded

         userinfo="`base64 --decode <<< "${userinfo:7}"`"
         if [ "$?" -ne 0 ]
         then
            internal_fail "userinfo could not be base64 decoded."
         fi
      ;;
   esac


   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" ]
   then
      log_trace2 "ADDRESS:      \"${address}\""
      log_trace2 "NODETYPE:     \"${nodetype}\""
      log_trace2 "MARKS:        \"${marks}\""
      log_trace2 "UUID:         \"${uuid}\""
      log_trace2 "URL:          \"${url}\""
      log_trace2 "BRANCH:       \"${branch}\""
      log_trace2 "TAG:          \"${tag}\""
      log_trace2 "FETCHOPTIONS: \"${fetchoptions}\""
      log_trace2 "USERINFO:     \"${userinfo}\""
   fi

   :
}


#
#
#
nodeline_remove()
{
   log_entry "nodeline_remove" "$@"

   local nodelines="$1"
   local addresstoremove="$2"

   IFS="
"
   local nodeline
   local url

   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"
      case "${nodeline}" in
         ^#*)
            echo "${nodeline}"
            continue
         ;;
      esac

      url="`nodeline_get_address "${nodeline}"`" || internal_fail "nodeline_get_address \"${nodeline}\""
      if [ "${address}" != "${addresstoremove}" ]
      then
         echo "${nodeline}"
      fi
   done
}


nodeline_find()
{
   log_entry "nodeline_find" "$@"

   local nodelines="$1"
   local address="$2"

   [ -z "${address}" ] && internal_fail "address is empty"

   local nodeline
   local other

   IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"

      other="`nodeline_get_address "${nodeline}"`"
      if [ "${address}" = "${other}" ]
      then
         log_debug "Found \"${nodeline}\""
         echo "${nodeline}"
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}"

   return 1
}



nodeline_has_duplicate()
{
   log_entry "nodeline_has_duplicate" "$@"

   local nodelines="$1"
   local address="$2"
   local uuid="$3"

   IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"
      if [ "${address}" = "`nodeline_get_address "${nodeline}"`" ]
      then
         if [ -z "${uuid}" ] || [ "${uuid}" = "`nodeline_get_uuid "${nodeline}"`" ]
         then
            return 0
         fi
      fi
   done
   IFS="${DEFAULT_IFS}"

   return 1
}


nodeline_read_file()
{
   log_entry "nodeline_read_file" "$@"

   local filename="$1"

   [ -z "${filename}" ] && internal_fail "file is empty"

   egrep -s -v '^#' "${filename}"
}



nodeline_print_header()
{
   log_entry "nodeline_print_header" "$@"

   local mode="$1"

   case "${mode}" in
      *output_header*)
      ;;

      *)
         return
      ;;
   esac

   sep=";"
   case "${mode}" in
      *output_column*)
         sep="|"
      ;;
   esac

   printf "%s" "address${sep}nodetype${sep}marks${sep}userinfo${sep}url"

   case "${mode}" in
      *output_full*)
         printf "%s" "${sep}branch${sep}tag${sep}fetchoptions"
      ;;
   esac
   case "${mode}" in
      *output_uuid*)
         printf "%s" "${sep}uuid"
      ;;
   esac
   printf "\n"

   case "${mode}" in
      *output_separator*)
         printf "%s" "-------${sep}--------${sep}-----${sep}--------${sep}---"
         case "${mode}" in
            *output_full*)
               printf "%s" "${sep}------${sep}---${sep}------------"
            ;;
         esac
         case "${mode}" in
            *output_uuid*)
               printf "%s" "${sep}----"
            ;;
         esac
         printf "\n"
      ;;
   esac
}


nodeline_print()
{
   log_entry "nodeline_print" "$@"

   local nodeline=$1
   local mode="$2"

   local branch
   local address
   local fetchoptions
   local marks
   local nodetype
   local tag
   local url
   local userinfo
   local uuid


   nodeline_parse "${nodeline}"

   case "${mode}" in
      *output_eval*)
         url="`eval echo "${url}"`"
         branch="`eval echo "${branch}"`"
         tag="`eval echo "${tag}"`"
         fetchoptions="`eval echo "${fetchoptions}"`"
      ;;
   esac

   local sep

   sep=";"
   case "${mode}" in
      *output_column*)
         sep="|"
      ;;
   esac

   case "${mode}" in
      *output_cmd*)
         local line

         line="${MULLE_EXECUTABLE_NAME} -N add"

         local guess

         guess="`node_guess_nodetype "${url}"`"

         if [ "${nodetype}" != "git" -o "${guess}" != "git" ]
         then
            line="`concat "${line}" "--nodetype '${nodetype}'"`"
         fi
         if [ ! -z "${url}" ]
         then
            line="`concat "${line}" "--url '${url}'"`"
         fi
         if [ ! -z "${marks}" ]
         then
            line="`concat "${line}" "--marks '${marks}'"`"
         fi

         if [ ! -z "${branch}" -a "${branch}" != "master" ]
         then
            line="`concat "${line}" "--branch '${branch}'"`"
         fi
         if [ ! -z "${fetchoptions}" ]
         then
            line="`concat "${line}" "--fetchoptions '${fetchoptions}'"`"
         fi
         if [ ! -z "${tag}" ]
         then
            line="`concat "${line}" "--tag '${tag}'"`"
         fi
         if [ ! -z "${userinfo}" ]
         then
            line="`concat "${line}" "--userinfo '${userinfo}'"`"
         fi

         line="`concat "${line}" "'${address}'"`"

         echo "${line}"
      ;;

      *output_column*)
         # need space for column if empty
         printf "%s" "${address:-" "}${sep}${nodetype:- }\
${sep}${marks:- }${sep}${userinfo:- }${sep}${url:-  }"
         case "${mode}" in
            *output_full*)
               printf "%s" "${sep}${branch:- }\
${sep}${tag:- }${sep}${fetchoptions:- }"
            ;;
         esac
         case "${mode}" in
            *output_uuid*)
               printf "%s" "${sep}${uuid:-" "}"
            ;;
         esac
         printf "\n"
      ;;


      *)
         printf "%s" "${address}${sep}${nodetype}${sep}${marks}${sep}${userinfo}${sep}${url}"
         case "${mode}" in
            *output_full*)
               printf "%s" "${sep}${branch}${sep}${tag}${sep}${fetchoptions}"

            ;;
         esac
         case "${mode}" in
            *output_uuid*)
               printf "%s" "${sep}${uuid}"
            ;;
         esac
         printf "\n"
      ;;
   esac
}

