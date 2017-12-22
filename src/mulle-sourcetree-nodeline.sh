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


# if _userinfo was last it could contain unquoted ;
# but who cares ?
nodeline_get_userinfo()
{
   cut '-d;' -f 9 <<< "$*"
}



#
# This function sets values of variables that should be declared
# in the caller! That's why they have a _ prefix
#
#   # nodeline_parse
#
#   local _branch
#   local _address
#   local _fetchoptions
#   local _nodetype
#   local _marks
#   local _tag
#   local _url
#   local _uuid
#   local _userinfo
#
nodeline_parse()
{
   log_entry "nodeline_parse" "$@"

   local nodeline="$1"

   [ -z "${nodeline}" ] && internal_fail "nodeline_parse: nodeline is empty"

   IFS=";" \
      read -r _address _nodetype _marks _uuid \
              _url _branch _tag _fetchoptions \
              _userinfo  <<< "${nodeline}"

   [ -z "${_address}" ]   && internal_fail "_address is empty"
   [ -z "${_nodetype}" ]  && internal_fail "_nodetype is empty"
   [ -z "${_uuid}" ]      && internal_fail "_uuid is empty"

   case "${_userinfo}" in
      base64:*)
         _userinfo="`base64 --decode <<< "${_userinfo:7}"`"
         if [ "$?" -ne 0 ]
         then
            internal_fail "_userinfo could not be base64 decoded."
         fi
      ;;
   esac


   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" ]
   then
      log_trace2 "ADDRESS:      \"${_address}\""
      log_trace2 "NODETYPE:     \"${_nodetype}\""
      log_trace2 "MARKS:        \"${_marks}\""
      log_trace2 "UUID:         \"${_uuid}\""
      log_trace2 "URL:          \"${_url}\""
      log_trace2 "BRANCH:       \"${_branch}\""
      log_trace2 "TAG:          \"${_tag}\""
      log_trace2 "FETCHOPTIONS: \"${_fetchoptions}\""
      log_trace2 "USERINFO:     \"${_userinfo}\""
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
   local address

   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"
      case "${nodeline}" in
         ^#*)
            echo "${nodeline}"
            continue
         ;;
      esac

      address="`nodeline_get_address "${nodeline}"`" || internal_fail "nodeline_get_address \"${nodeline}\""
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

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _userinfo
   local _uuid


   nodeline_parse "${nodeline}"

   case "${mode}" in
      *output_eval*)
         _url="`eval echo "${_url}"`"
         _branch="`eval echo "${_branch}"`"
         _tag="`eval echo "${_tag}"`"
         _fetchoptions="`eval echo "${_fetchoptions}"`"
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

         if [ ! -z "${_url}" ]
         then
            guess="`node_guess_nodetype "${_url}"`"
         fi

         if [ "${_nodetype}" != "git" -o "${guess}" != "git" ]
         then
            line="`concat "${line}" "--nodetype '${_nodetype}'"`"
         fi
         if [ ! -z "${_url}" ]
         then
            line="`concat "${line}" "--url '${_url}'"`"
         fi
         if [ ! -z "${_marks}" ]
         then
            line="`concat "${line}" "--marks '${_marks}'"`"
         fi

         if [ ! -z "${_branch}" -a "${_branch}" != "master" ]
         then
            line="`concat "${line}" "--branch '${_branch}'"`"
         fi
         if [ ! -z "${_fetchoptions}" ]
         then
            line="`concat "${line}" "--fetchoptions '${_fetchoptions}'"`"
         fi
         if [ ! -z "${_tag}" ]
         then
            line="`concat "${line}" "--tag '${_tag}'"`"
         fi
         if [ ! -z "${_userinfo}" ]
         then
            line="`concat "${line}" "--userinfo '${_userinfo}'"`"
         fi

         line="`concat "${line}" "'${_address}'"`"

         echo "${line}"
      ;;

      *output_column*)
         # need space for column if empty
         printf "%s" "${_address:-" "}${sep}${_nodetype:- }\
${sep}${_marks:- }${sep}${_userinfo:- }${sep}${_url:-  }"
         case "${mode}" in
            *output_full*)
               printf "%s" "${sep}${_branch:- }\
${sep}${_tag:- }${sep}${_fetchoptions:- }"
            ;;
         esac
         case "${mode}" in
            *output_uuid*)
               printf "%s" "${sep}${_uuid:-" "}"
            ;;
         esac
         printf "\n"
      ;;

      *)
         printf "%s" "${_address}${sep}${_nodetype}${sep}${_marks}${sep}${_userinfo}${sep}${_url}"
         case "${mode}" in
            *output_full*)
               printf "%s" "${sep}${_branch}${sep}${_tag}${sep}${_fetchoptions}"

            ;;
         esac
         case "${mode}" in
            *output_uuid*)
               printf "%s" "${sep}${_uuid}"
            ;;
         esac
         printf "\n"
      ;;
   esac
}


#
# style is known to be "share"
# compute the filename to use
#
nodeline_share_filename()
{
   log_entry "nodeline_share_filename" "$@"

   local database="$1"
   local address="$2"
   local nodetype="$3"
   local marks="$4"

   local filename

   #
   # address gets truncated
   #
   if [ "${address}" != "`basename -- "${address}" `" ]
   then
      fail "Can't share node \"${address}\" as it specified as a subdirectory."
   fi

   #
   # locate minion in root database, which overrides, but not if we are
   # in root
   #
   if [ "${database}" != "/" ]
   then
      local otheruuid

      otheruuid="`db_fetch_uuid_for_address "/" "${address}"`"
      if [ ! -z "${otheruuid}" ]
      then
         log_fluff "There is a minion for \"${address}\" in root. So skip it."
         return 1
      fi

      log_debug "Use root database for share node \"${address}\""
   fi

   if [ "${nodetype}" != "local" ]
   then
      #
      # use shared root database for shared nodes
      #
      filename="`filepath_concat "${MULLE_SOURCETREE_SHARE_DIR}" "${address}"`"
      log_debug "Set filename to share \"${filename}\""
   else
      filename="${address}"
   fi

   echo "${filename}"
}
