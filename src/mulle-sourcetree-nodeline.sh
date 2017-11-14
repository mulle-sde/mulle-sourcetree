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


_nodeline_get_address()
{
   cut -s '-d;' -f 1
}


nodeline_get_address()
{
  cut -s '-d;' -f 1 <<< "$*"
}


_nodeline_get_url()
{
   cut -s '-d;' -f 2
}

nodeline_get_url()
{
   cut '-d;' -f 2 <<< "$*"
}


nodeline_get_branch()
{
   cut -s '-d;' -f 3 <<< "$*"
}


nodeline_get_tag()
{
   cut -s '-d;' -f 4 <<< "$*"
}


nodeline_get_nodetype()
{
   cut -s '-d;' -f 5 <<< "$*"
}


nodeline_get_marks()
{
   cut '-d;' -f 6 <<< "$*"
}


nodeline_get_fetchoptions()
{
   cut '-d;' -f 7 <<< "$*"
}


# if userinfo was last it could contain unquoted ;
# but who cares ?
nodeline_get_userinfo()
{
   cut '-d;' -f 8 <<< "$*"
}

_nodeline_get_uuid()
{
   cut -s '-d;' -f 9
}


nodeline_get_uuid()
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
# Merge two "repositories" files contents. Find duplicates by matching
# against urls(!) not uuids
#
nodeline_merge()
{
   log_entry "nodeline_merge" "$@"

   local contents="$1"
   local additions="$2"

   local nodeline
   local map
   local url
   local uuid

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
   then
      log_trace2 "Merging repositories \"${additions}\" into \"${contents}\""
   fi

   #
   # additions may contain address
   # we replace this with
   #
   # 1. if we are a master, with the name of the url
   # 2. we erase it
   #
   map=""
   IFS="
"
   for nodeline in ${additions}
   do
      IFS="${DEFAULT_IFS}"

      url="`nodeline_get_url "${nodeline}"`" || internal_fail "nodeline_get_url \"${url}\""
      map="`assoc_array_set "${map}" "${url}" "${nodeline}"`"
   done

   IFS="
"
   for nodeline in ${contents}
   do
      IFS="${DEFAULT_IFS}"

      url="`nodeline_get_url "${nodeline}"`" || internal_fail "nodeline_get_url \"${nodeline}\""
      map="`assoc_array_set "${map}" "${url}" "${nodeline}"`"
   done
   IFS="${DEFAULT_IFS}"

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
   then
      log_trace2 "----------------------"
      log_trace2 "merged \"nodelines\":"
      log_trace2 "----------------------"
      log_trace2 "`assoc_array_all_values "${map}"`"
      log_trace2 "----------------------"
   fi
   assoc_array_all_values "${map}"
}


nodeline_read_file()
{
   log_entry "nodeline_read_file" "$@"

   local filename="$1"

   [ -z "${filename}" ] && internal_fail "file is empty"

   egrep -s -v '^#' "${filename}"
}

#
# these can be prefixed for external queries
#

nodeline_config_exists()
{
   log_entry "nodeline_config_exists" "$@"

   local prefix="$1"

   [ -z "${prefix}${SOURCETREE_CONFIG_FILE}" ] && internal_fail "SOURCETREE_CONFIG_FILE is empty"

   if [ -f "${prefix}${SOURCETREE_CONFIG_FILE}" ]
   then
      log_debug "\"${PWD}/${prefix}${SOURCETREE_CONFIG_FILE}\" exists"
      return 0
   fi

   log_debug "\"${PWD}/${prefix}${SOURCETREE_CONFIG_FILE}\" not found"
   return 1
}


nodeline_config_timestamp()
{
   log_entry "nodeline_config_timestamp" "$@"

   local prefix="$1"

   [ -z "${prefix}${SOURCETREE_CONFIG_FILE}" ] && internal_fail "SOURCETREE_CONFIG_FILE is empty"

   if [ -f "${prefix}${SOURCETREE_CONFIG_FILE}" ]
   then
      modification_timestamp "${prefix}${SOURCETREE_CONFIG_FILE}"
   fi
}


#
# can receive a prefix (for walking)
#
nodeline_config_read()
{
   log_entry "nodeline_config_read" "$@"

   [ -z "${SOURCETREE_CONFIG_FILE}" ] && internal_fail "SOURCETREE_CONFIG_FILE is empty"

   local prefix="$1"

   if [ -f "${prefix}${SOURCETREE_CONFIG_FILE}" ]
   then
      egrep -s -v '^#' "${prefix}${SOURCETREE_CONFIG_FILE}"
   else
      log_debug "No config file \"${prefix}${SOURCETREE_CONFIG_FILE}\" found ($PWD)"
   fi
}


#
#
#
nodeline_merge_files()
{
   log_entry "nodeline_merge_files" "$@"

   local srcfile="$1"
   local address="$2"

   [ -z "${srcfile}" ] && internal_fail "srcfile is empty"
   [ -z "${address}" ] && internal_fail "address is empty"

   log_fluff "Merge \"srcfile\" into \"${address}\""

   local contents
   local additions
   local results

   contents="$(nodeline_read_file "${srcfile}")" || exit 1
   additions="$(nodeline_read_file "${address}")" || exit 1

   results="`nodeline_merge "${contents}" "${additions}"`"

   redirect_exekutor "${address}" echo "${results}" || fail "failed to merge"
}


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



#
# take a list of nodelines
# unique them with another list of repositories by url
# output uniqued list
#
# another:  b;b
# input:    b
# output:   b;b
#
nodeline_unique()
{
   log_entry "nodeline_unique" "$@"

   local input="$1"
   local another="$2"

   local nodeline
   local map
   local uuid
   local output

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
   then
      log_trace2 "Uniquing \"${input}\" with \"${another}\""
   fi

   map=""
   IFS="
"
   for nodeline in ${another}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -z "${nodeline}" ]
      then
         url="`nodeline_get_url "${nodeline}"`" || internal_fail "nodeline_get_url \"${nodeline}\""
         map="`assoc_array_set "${map}" "${url}" "${nodeline}"`"
      fi
   done

   output=""
   IFS="
"
   for nodeline in ${input}
   do
      IFS="${DEFAULT_IFS}"

      if [ ! -z "${nodeline}" ]
      then
         url="`nodeline_get_url "${nodeline}"`" || internal_fail "nodeline_get_url \"${nodeline}\""
         uniqued="`assoc_array_get "${map}" "${url}"`"
         output="`add_line "${output}" "${uniqued:-${nodeline}}"`"
      fi
   done
   IFS="${DEFAULT_IFS}"

   if [ "$MULLE_FLAG_LOG_SETTINGS" = "YES" -o "$MULLE_FLAG_LOG_MERGE" = "YES"  ]
   then
      log_trace2 "----------------------"
      log_trace2 "uniqued \"repositories\":"
      log_trace2 "----------------------"
      log_trace2 "${output}"
      log_trace2 "----------------------"
   fi

   echo "${output}"
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


nodeline_config_get_nodeline()
{
   log_entry "nodeline_config_get_nodeline" "$@"

   local address="$1"

   local nodelines

   nodelines="`nodeline_config_read`"
   nodeline_find "${nodelines}" "${address}"
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


nodeline_config_has_duplicate()
{
   log_entry "nodeline_config_has_duplicate" "$@"

   local address="$1"
   local uuid="$2"

   local nodelines

   nodelines="`nodeline_config_read`"
   nodeline_has_duplicate "${nodelines}" "${address}" "${uuid}"
}


nodeline_config_remove_nodeline()
{
   log_entry "nodeline_config_remove_nodeline" "$@"

   local address="$1"

   local escaped

   log_debug "Removing \"${address}\" from  \"${SOURCETREE_CONFIG_FILE}\""
   escaped="`escaped_sed_pattern "${address}"`"
   if ! exekutor sed -i ".bak" "/^${escaped};/d" "${SOURCETREE_CONFIG_FILE}"
   then
      internal_fail "sed address corrupt ?"
   fi
}


nodeline_config_change_nodeline()
{
   log_entry "nodeline_config_change_nodeline" "$@"

   local oldnodeline="$1"
   local newnodeline="$2"

   local oldescaped
   local newescaped

   oldescaped="`escaped_sed_pattern "${oldnodeline}"`"
   newescaped="`escaped_sed_pattern "${newnodeline}"`"

   log_debug "Editing \"${SOURCETREE_CONFIG_FILE}\""
   if ! exekutor sed -i '-bak' -e "s/^${oldescaped}$/${newescaped}/" "${SOURCETREE_CONFIG_FILE}"
   then
      fail "Edit of config file failed unexpectedly"
   fi
}


nodeline_search_config_dir()
{
   log_entry "nodeline_search_config_dir" "$@"

   local directory="${1:-${PWD}}"

   (
      cd "${directory}" &&
      while ! nodeline_config_exists
      do
         case "${PWD}" in
            "/"|"")
               exit 1
            ;;
         esac

         cd ..
      done &&
      echo "${PWD}"
   )
}


nodeline_print_header()
{
   log_entry "nodeline_print_header" "$@"

   local mode="$1"

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
   local nodeline=$1; shift
   local mode="$1"; shift

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
      *output_cmdline*)
         local line
         local guess

         line="${MULLE_EXECUTABLE_NAME} add"

         guess="`node_guess_address "${url}" "${nodetype}"`"
         if [ ! -z "${branch}" -a "${branch}" != "master" ]
         then
            line="`concat "${line}" "--branch '${branch}'"`"
         fi
         if [ ! -z "${tag}" ]
         then
            line="`concat "${line}" "--tag '${tag}'"`"
         fi
         if [ ! -z "${nodetype}" -a "${nodetype}" != "git" ]
         then
            line="`concat "${line}" "--nodetype '${nodetype}'"`"
         fi
         if [ ! -z "${fetchoptions}" ]
         then
            line="`concat "${line}" "--fetchoptions '${fetchoptions}'"`"
         fi
         if [ ! -z "${marks}" ]
         then
            line="`concat "${line}" "--marks '${marks}'"`"
         fi
         if [ ! -z "${userinfo}" ]
         then
            line="`concat "${line}" "--userinfo '${userinfo}'"`"
         fi
         if [ ! -z "${url}" ]
         then
            line="`concat "${line}" "--url '${url}'"`"
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


#
# return the directory, that we should be using for the following defer
# possibilities
#
# NONE:    do not search only pri
# NEAREST: search up until we find a sourcetree
# PARENT:  get the enveloping sourcetree of PWD (even if PWD has a sourcetree)
# ROOT:    get the outermost enveloping sourcetree (can be PWD)
#
nodeline_working_directory()
{
   log_entry "nodeline_working_directory" "$@"

   local preference="${1:-NONE}"

   local directory
   local parent
   local found
   local defer

   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-db.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh"
   fi

   defer="${MULLE_FLAG_DEFER}"
   if [ "${defer}" = "DEFAULT" ]
   then
      defer="${preference}"
   fi

   case "${defer}" in
      NONE)
         if nodeline_config_exists || db_dir_exists
         then
            echo "${PWD}"
            return 0
         fi

         log_debug "No config found or db found"
         return 1
      ;;

      NEAREST)
         directory="`nodeline_search_config_dir`"
         if [ $? -ne 0 ]
         then
            log_debug "No config found or db found"
            return 1
         fi
         echo "${directory}"
         return 0
      ;;

      PARENT)
         directory="`nodeline_search_config_dir`"
         if [ $? -ne 0 ]
         then
            log_debug "No config found or db found"
            return 1
         fi

         if [ "${directory}" != "${PWD}" ]
         then
            echo "${directory}"
            return 0
         fi

         parent="`dirname -- "${directory}"`"
         directory="`nodeline_search_config_dir "${parent}"`"
         if [ $? -eq 0 ]
         then
            echo "${directory}"
            return 0
         fi

         log_debug "No parent found"
         return 1
      ;;

      ROOT)
         directory="`nodeline_search_config_dir`"
         if [ $? -ne 0 ]
         then
            log_debug "No config found"
            return 1
         fi

         while :
         do
            found="${directory}"
            parent="`dirname -- "${directory}"`"
            if [ "${parent}" = "/" ]
            then
               break
            fi

            directory="`nodeline_search_config_dir "${parent}"`"
            if [ $? -ne 0 ]
            then
               break
            fi
         done

         echo "${found}"
         return 0
      ;;
   esac

   return 1
}


nodeline_defer_if_needed()
{
   local preference="${1:-NONE}"

   local directory

   if directory="`nodeline_working_directory "${preference}"`"
   then
      if [ "${directory}" != "${PWD}" ]
      then
         exekutor cd "${directory}"
         log_debug "Changed to master \"${directory}\" ($PWD)"
      fi
   fi

   if [ ! -z "${directory}" -a -z "${MULLE_WALK_SUPRESS}" ]
   then
      if nodeline_config_exists "${directory}/"
      then
         log_info "Sourcetree: ${C_RESET_BOLD}${directory}/${SOURCETREE_CONFIG_FILE}${C_INFO}"
      fi
   fi
}

