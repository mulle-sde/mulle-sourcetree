# shellcheck shell=bash
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
MULLE_SOURCETREE_NODELINE_SH='included'


sourcetree::nodeline::r_get_address()
{
   RVAL="${*%%;*}"
}


sourcetree::nodeline::__get_address_nodetype()
{
   local nodeline="$1"

   _nodetype="${nodeline#*;}"

   _address="${nodeline%%;*}"
   _nodetype="${_nodetype%%;*}"
}


sourcetree::nodeline::__get_address_nodetype_marks()
{
   local nodeline="$1"

   _nodetype="${nodeline#*;}"
   _marks="${_nodetype#*;}"

   _address="${nodeline%%;*}"
   _nodetype="${_nodetype%%;*}"
   _marks="${_marks%%;*}"
}


sourcetree::nodeline::__get_address_nodetype_marks_uuid()
{
   local nodeline="$1"

   _nodetype="${nodeline#*;}"
   _marks="${_nodetype#*;}"
   _uuid="${_marks#*;}"

   _address="${nodeline%%;*}"
   _nodetype="${_nodetype%%;*}"
   _marks="${_marks%%;*}"
   _uuid="${_uuid%%;*}"
}


sourcetree::nodeline::r_get_uuid()
{
   local nodeline="$1"

   local _nodetype
   local _marks
   local _uuid

   _nodetype="${nodeline#*;}"
   _marks="${_nodetype#*;}"
   _uuid="${_marks#*;}"
   RVAL="${_uuid%%;*}"
}


sourcetree::nodeline::r_get_url()
{
   local nodetype
   local marks
   local uuid

   IFS=';' \
      read -r address nodetype marks uuid RVAL <<< "$*"

   # RVAL will contain all the rest of the string, which we don't want
   RVAL="${RVAL%%;*}"
}


# this needs to do proper expansion to evaluate the URL
sourcetree::nodeline::r_get_evaled_url()
{
   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _userinfo
   local _raw_userinfo
   local _uuid

   sourcetree::nodeline::parse "$@"

   # define MULLE_TAG and everything else, so we can propery expand

   local _evaledurl
   local _evalednodetype
   local _evaledbranch
   local _evaledtag
   local _evaledfetchoptions

   sourcetree::node::__evaluate_values

   r_expanded_string "${_url}"
}


#
# This function sets values of variables that should be declared
# in the caller! That's why they have a _ prefix
#
#   # sourcetree::nodeline::parse
#
#   local _branch
#   local _address
#   local _fetchoptions
#   local _nodetype
#   local _marks
#   local _raw_userinfo
#   local _userinfo
#   local _tag
#   local _url
#   local _uuid
#
# #   This is a bit faster but not by much
# #   _address="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _nodetype="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _marks="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _uuid="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _url="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _branch="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _tag="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _fetchoptions="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"
# #
# #   _raw_userinfo="${nodeline%%;*}"
# #   nodeline="${nodeline#*;}"

#
# MEMO: if we change the format from CSV to evaluatable shell script
# _address='';_nodetype='';
#
# We gain expandability and also its 3 times as fast as read -r from
# a string. Minimally would have to guard against unescaped $ and backticks
# i believe.
#
sourcetree::nodeline::parse()
{
   # log_entry "sourcetree::nodeline::parse" "$@"

   local nodeline="$1"

   [ -z "${nodeline}" ] && _internal_fail "sourcetree::nodeline::parse: nodeline is empty"

   # MEMO: if there are stray ';' in the back they will be part of
   # _raw_userinfo (its a bashism)
   #
   IFS=";" \
      read -r _address _nodetype _marks _uuid \
              _url _branch _tag _fetchoptions \
              _raw_userinfo  <<< "${nodeline}"

   # set this to empty, so we know raw is not converted yet

   _userinfo=""

   [ -z "${_address}" ]   && _internal_fail "_address is empty in \"${nodeline}\""
   [ -z "${_nodetype}" ]  && _internal_fail "_nodetype is empty in \"${nodeline}\""
   [ -z "${_uuid}" ]      && _internal_fail "_uuid is empty in \"${nodeline}\""

   # correct some legacy stuff, because i was too lazy to write a script
   # probably only used by MulleObjCOSFoundation
   _marks="${_marks//only-os-/only-platform-}"
   _marks="${_marks//no-os-/no-platform-}"

   # early escape here

   log_setting "ADDRESS      : \"${_address}\""
   log_setting "NODETYPE     : \"${_nodetype}\""
   log_setting "MARKS        : \"${_marks}\""
   log_setting "UUID         : \"${_uuid}\""
   log_setting "URL          : \"${_url}\""
   log_setting "BRANCH       : \"${_branch}\""
   log_setting "TAG          : \"${_tag}\""
   log_setting "FETCHOPTIONS : \"${_fetchoptions}\""
   log_setting "USERINFO     : \"${_raw_userinfo}\""

   return 0
}


#
#
#
sourcetree::nodeline::r_index()
{
   log_entry "sourcetree::nodeline::r_index" "..." "$2"

   local nodelines="$1"
   local value="$2"

   [ $# -ne 2 ] && _internal_fail "API error"

   local nodeline
   local index

   index=0
   .foreachline nodeline in ${nodelines}
   .do
      if [ "${nodeline}" = "${value}" ]
      then
         log_debug "Found \"${nodeline}\" at index ${index} "
         RVAL="${index}"
         return 0
      fi
      index=$(( index + 1 ))
   .done

   RVAL=-1
   return 1
}


sourcetree::nodeline::_r_find()
{
   log_entry "sourcetree::nodeline::_r_find" "..." "$2" "$3" "$4"

   local nodelines="$1"
   local value="$2"
   local lookup="$3"
   local fuzzy="$4"

   [ $# -ne 4 ] && _internal_fail "API error"

   local nodeline
   local other

   if [ "${fuzzy}" = 'YES' ]
   then
      case "${value}" in
         *[\$\|\<\>]*)
            fail "Suspicious value \"${value}\" can't be matched"
         ;;
      esac
   fi

   .foreachline nodeline in ${nodelines}
   .do
      "${lookup}" "${nodeline}"
      other="${RVAL}"

      if [ "${other}" = "${value}" ]
      then
         log_debug "Found \"${nodeline}\""
         RVAL="${nodeline}"
         return 0
      fi

      if [ "${fuzzy}" = 'YES' ]
      then
         case "${other}" in
            ${value})
               log_debug "Found \"${_nodeline}\""
               RVAL="${nodeline}"
               return 0
            ;;
         esac
      fi
   .done

   RVAL=
   return 1
}


sourcetree::nodeline::r_find()
{
   log_entry "sourcetree::nodeline::r_find" ... "$2" "$3"

   local nodelines="$1"
   local address="$2"
   local fuzzy="${3:-NO}"

   [ -z "${address}" ] && _internal_fail "address is empty"

   sourcetree::nodeline::_r_find "${nodelines}" \
                                 "${address}" \
                                 sourcetree::nodeline::r_get_address \
                                 "${fuzzy}"
}

sourcetree::nodeline::r_find_by_url()
{
   log_entry "sourcetree::nodeline::r_find_by_url" "..." "$2"

   local nodelines="$1"
   local url="$2"

   [ -z "${url}" ] && _internal_fail "url is empty"

   sourcetree::nodeline::_r_find "${nodelines}" \
                                 "${url}" \
                                 sourcetree::nodeline::r_get_url \
                                 'NO'
}


sourcetree::nodeline::r_find_by_evaled_url()
{
   log_entry "sourcetree::nodeline::r_find_by_evaled_url" "..." "$2"

   local nodelines="$1"
   local url="$2"

   [ -z "${url}" ] && _internal_fail "url is empty"

   sourcetree::nodeline::_r_find "${nodelines}" \
                                  "${url}" \
                                  sourcetree::nodeline::r_get_evaled_url \
                                  'NO'
}


sourcetree::nodeline::r_find_by_uuid()
{
   log_entry "sourcetree::nodeline::r_find_by_uuid"  "..." "$2"

   local nodelines="$1"
   local uuid="$2"

   [ -z "${uuid}" ] && _internal_fail "uuid is empty"


   sourcetree::nodeline::_r_find "${nodelines}" \
                                 "${uuid}" \
                                 sourcetree::nodeline::r_get_uuid NO
}


sourcetree::nodeline::r_find_by_index()
{
   log_entry "sourcetree::cfg::r_find_by_index" "..." "$2"

   local nodelines="$1"
   local index="$2"

   case ${index} in
      ''|*[!0-9]*)
         log_debug "Need an integer for index"
         return 1
      ;;
   esac

   r_line_at_index "${nodelines}" "${index}"
}


sourcetree::nodeline::r_find_by_address_url_uuid()
{
   log_entry "sourcetree::nodeline::r_find_by_address_url_uuid" "$@"

   local nodelines="$1"
   local address="$2"
   local url="$3"
   local uuid="$4"
   local fuzzy="${5:-NO}"
   local regex="${6:-NO}"

   if [ ! -z "${uuid}" ]
   then
      if sourcetree::nodeline::r_find_by_uuid "${nodelines}" \
                                              "${uuid}"
      then
         return $?
      fi
      if [ "${fuzzy}" = 'NO' ]
      then
         return 1
      fi
      address="${address:-${uuid}}"
   fi

   if [ ! -z "${address}" ]
   then
      if sourcetree::nodeline::r_find_by_index "${nodelines}" \
                                               "${address}"
      then
         return 0
      fi

      if sourcetree::nodeline::r_find "${nodelines}" \
                                      "${address}" \
                                      "${regex}"
      then
         return 0
      fi

      if [ "${fuzzy}" = 'NO' ]
      then
         return 1
      fi
      url="${url:-${address}}"
   fi

   if sourcetree::nodeline::r_find_by_evaled_url "${nodelines}" "${url}"
   then
      return 0
   fi

   sourcetree::nodeline::r_find_by_url "${nodelines}" "${url}"
}


sourcetree::nodeline::has_duplicate()
{
   log_entry "sourcetree::nodeline::has_duplicate"  "..." "$2" "$3"

   local nodelines="$1"
   local address="$2"
   local uuid="$3"

   local _address
   local _nodetype
   local _marks
   local _uuid

   .foreachline nodeline in ${nodelines}
   .do
      sourcetree::nodeline::__get_address_nodetype_marks_uuid "${nodeline}"

      if [ "${address}" = "${_address}" ]
      then
         if [ -z "${uuid}" ] || [ "${uuid}" = "${_uuid}" ]
         then
            return 0
         fi
      fi
   .done

   return 1
}

sourcetree::nodeline::remove()
{
   log_entry "sourcetree::nodeline::remove" "..." "$2"

   local nodelines="$1"
   local addresstoremove="$2"

   local nodeline

   .foreachline nodeline in ${nodelines}
   .do
      case "${nodeline}" in
         ^#*)
            printf "%s\n" "${nodeline}"
            .continue
         ;;
      esac

      sourcetree::nodeline::r_get_address "${nodeline}"
      if [ "${RVAL}" != "${addresstoremove}" ]
      then
         printf "%s\n" "${nodeline}"
      fi
   .done
}

sourcetree::nodeline::r_get_sep()
{
   log_entry "sourcetree::nodeline::r_get_sep" "$@"

   local mode="$1"

   case ",${mode}," in
      *,output_column,*)
         RVAL="; "
      ;;

      *)
         RVAL=";"
      ;;
   esac
}


sourcetree::nodeline::r_get_formatstring()
{
   log_entry "sourcetree::nodeline::r_get_formatstring" "$@"

   local mode="$1"
   local formatstring="$2"
   local sep="$3"

   # this could be much better

   RVAL="${formatstring}"

   if [ -z "${formatstring}" ]
   then
      RVAL="%a${sep}%n${sep}%m${sep}%i"
      case ",${mode}," in
         *,output_url,*)
            RVAL="${RVAL}${sep}%u"
         ;;
      esac

      case ",${mode}," in
         *,output_full,*)
            RVAL="${RVAL}${sep}%b${sep}%t${sep}%f"
         ;;
      esac

      case ",${mode}," in
         *,output_uuid,*)
            RVAL="%_${sep}${RVAL}"
         ;;
      esac
      RVAL="${RVAL}\\n"
   fi

   log_debug "Format: ${RVAL}"
}


sourcetree::nodeline::printf_header()
{
   log_entry "sourcetree::nodeline::printf_header" "$@"

   local mode="$1"
   local formatstring="$2"

   case ",${mode}," in
      *,output_header,*)
      ;;

      *)
         return
      ;;
   esac

   local sep

   sourcetree::nodeline::r_get_sep "${mode}"
   sep="${RVAL}"

   sourcetree::nodeline::r_get_formatstring "${mode}" "${formatstring}" "${sep}"
   formatstring="${RVAL}"

   local h_line
   local s_line

   local name
   local dash
   local tmp
   local _formatstring
   local _key
   local _title
   local _dashes

   while [ ! -z "${formatstring}" ]
   do
      case "${formatstring}" in
         %a*)
            name="address"
            dash="-------"
         ;;

         %b!*)
            name="branch"
            dash="------"
            formatstring="${formatstring:1}"
         ;;

         %b*)
            name="branch"
            dash="------"
         ;;

         %f!*)
            name="fetchoptions"
            dash="------------"
            formatstring="${formatstring:1}"
         ;;

         %f*)
            name="fetchoptions"
            dash="------------"
         ;;

         %v*)
            if [ "${formatstring:2:2}" = "={" ]
            then
               sourcetree::node::_r_get_format_key "${formatstring}"
               formatstring="XX${RVAL}"
               name="${_title:-${_key}}"
               dash="${_dashes:-'--------'}"
            else
               name="variable"
               dash="--------"
            fi
         ;;

         %i*)
            if [ "${formatstring:2:2}" = "={" ]
            then
               sourcetree::node::_r_get_format_key "${formatstring}"
               formatstring="XX${RVAL}"
               name="${_title:-${_key}}"
               dash="${_dashes:-'--------'}"
            else
               name="userinfo"
               dash="--------"
            fi
         ;;

         %m*)
            name="marks"
            dash="-----"
         ;;

         %n!*)
            name="nodetype"
            dash="--------"
            formatstring="${formatstring:1}"
         ;;

         %n*)
            name="nodetype"
            dash="--------"
         ;;

         %s*)
            name="supermarks"
            dash="----------"
         ;;

         %t!*)
            name="tag"
            dash="---"
            formatstring="${formatstring:1}"
         ;;

         %t*)
            name="tag"
            dash="---"
         ;;

         %[uU]!*)
            name="url"
            dash="---"
            formatstring="${formatstring:1}"
         ;;

         %[uU]*)
            name="url"
            dash="---"
         ;;

         %_*)
            name="uuid"
            dash="----"
         ;;

         %*)
            fail "unknown format character \"${formatstring:1:1}\""
         ;;

         \\n)
            case ",${mode}," in
               *,output_cmd,*|*,output_cmd2,*)
                  name=""
                  dash=""
               ;;

               *)
                  name=$'\n'
                  dash=$'\n'
               ;;
            esac
         ;;

         *)
            h_line="${h_line}${formatstring:0:1}"
            s_line="${s_line}${formatstring:0:1}"
            formatstring="${formatstring:1}"
            continue
         ;;
      esac

      h_line="${h_line}${name}"
      s_line="${s_line}${dash}"

      formatstring="${formatstring:2}"
   done

   rexekutor printf "%s" "${h_line}"
   case ",${mode}," in
      *,output_separator,*)
         rexekutor printf "%s" "${s_line}"
      ;;
   esac
}


sourcetree::nodeline::printf()
{
   local nodeline="$1"; shift

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _uuid
   local _raw_userinfo
   local _userinfo

   sourcetree::nodeline::parse "${nodeline}"

   sourcetree::node::printf "$@"
}


sourcetree::nodeline::r_diff()
{
   log_entry "sourcetree::nodeline::r_diff"

   local nodeline1="$1"
   local nodeline2="$2"
   local mode="${3:-diff}"

   local _branch
   local _address
   local _fetchoptions
   local _marks
   local _nodetype
   local _tag
   local _url
   local _uuid
   local _raw_userinfo
   local _userinfo

   sourcetree::nodeline::parse "${nodeline1}"

   local branch="${_branch}"
   local address="${_address}"
   local fetchoptions="${_fetchoptions}"
   local marks="${_marks}"
   local nodetype="${_nodetype}"
   local tag="${_tag}"
   local url="${_url}"
   local uuid="${_uuid}"
   local raw_userinfo="${_raw_userinfo}"
   local userinfo="${_userinfo}"

   sourcetree::nodeline::parse "${nodeline2}"

   local field
   local u_field
   local u_field_value
   local field_value
   local diffed_value
   local memo

   RVAL=
   shell_disable_glob
   for field in address branch fetchoptions marks nodetype tag url userinfo
   do
      u_field="_${field}"

      r_shell_indirect_expand "${field}"
      field_value="${RVAL}"

      r_shell_indirect_expand "${u_field}"
      u_field_value="${RVAL}"

      if [ "${field_value}" = "${u_field_value}" ]
      then
         continue
      fi

      case "${mode}" in
         diff)
            if [ "${field}" = "marks" ]
            then
               memo="${RVAL}"
                  sourcetree::marks::r_diff "${field_value}" "${u_field_value}"
                  diffed_value="${RVAL}"
               RVAL="${memo}"
            else
               diffed_value="${field_value};${u_field_value}"
            fi
            r_add_line "${RVAL}" "${field}:${diffed_value}"
         ;;

         field)
            r_commalist_add "${RVAL}" "${field}"
         ;;
      esac
   done
   shell_enable_glob
}


sourcetree::nodeline::initialize()
{
   log_entry "sourcetree::nodeline::initialize"

   include "sourcetree::node"
   include "sourcetree::marks"
}

sourcetree::nodeline::initialize

:
