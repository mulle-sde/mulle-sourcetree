#! /usr/bin/env bash
#
#   Copyright (c) 2017 Nat! - Mulle kybernetiK
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

MULLE_SOURCETREE_NODELINE_SH="included"


_nodeline_get_url()
{
   cut -s '-d;' -f 1
}


nodeline_get_url()
{
   echo "$@" | cut '-d;' -f 1
}


_nodeline_get_dstfile()
{
   cut -s '-d;' -f 2
}


nodeline_get_dstfile()
{
   echo "$@" | cut -s '-d;' -f 2
}


nodeline_get_branch()
{
   echo "$@" | cut -s '-d;' -f 3
}


nodeline_get_tag()
{
   echo "$@" | cut -s '-d;' -f 4
}


nodeline_get_nodetype()
{
   echo "$@" | cut -s '-d;' -f 5
}


nodeline_get_uuid()
{
   echo "$@" | cut '-d;' -f 6
}


nodeline_get_marks()
{
   echo "$@" | cut '-d;' -f 7
}


nodeline_get_fetchoptions()
{
   echo "$@" | cut '-d;' -f 8
}


nodeline_get_userinfo()
{
   echo "$@" | cut '-d;' -f 9
}


#
# This function sets values of variables that should be declared
# in the caller!
#
#   # nodeline_parse
#
#   local branch
#   local dstfile
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
   local nodeline="$1"

   [ -z "${nodeline}" ] && internal_fail "nodeline_parse: nodeline is empty"

   IFS=";" \
      read -r url dstfile branch tag nodetype uuid marks fetchoptions userinfo \
         <<< "${nodeline}"
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
   # additions may contain dstfile
   # we replace this with
   #
   # 1. if we are a master, with the uuid of the url
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

   [ -f "${prefix}${SOURCETREE_CONFIG_FILE}" ]
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
nodeline_read_config()
{
   log_entry "nodeline_read_config" "$@"

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
   local dstfile="$2"

   [ -z "${srcfile}" ] && internal_fail "srcfile is empty"
   [ -z "${dstfile}" ] && internal_fail "dstfile is empty"

   log_fluff "Merge \"srcfile\" into \"${dstfile}\""

   local contents
   local additions
   local results

   contents="$(nodeline_read_file "${srcfile}")" || exit 1
   additions="$(nodeline_read_file "${dstfile}")" || exit 1

   results="`nodeline_merge "${contents}" "${additions}"`"

   redirect_exekutor "${dstfile}" echo "${results}" || fail "failed to merge"
}


nodeline_remove_by_url()
{
   local nodelines="$1"
   local urltoremove="$2"

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

      url="`nodeline_get_url "${nodeline}"`" || internal_fail "nodeline_get_url \"${nodeline}\""
      if [ "${url}" != "${urltoremove}" ]
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


nodeline_find_by_url()
{
   log_entry "nodeline_find_by_url" "$@"

   local nodelines="$1"
   local url="$2"

   [ -z "${url}" ] && internal_fail "url is empty"

   local nodeline
   local other

   IFS="
"
   for nodeline in ${nodelines}
   do
      IFS="${DEFAULT_IFS}"

      other="`nodeline_get_url "${nodeline}"`"
      if [ "${url}" = "${other}" ]
      then
         log_debug "Found \"${nodeline}\""
         echo "${nodeline}"
         return 0
      fi
   done
   IFS="${DEFAULT_IFS}"

   return 1
}
