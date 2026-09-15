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
MULLE_SOURCETREE_DBLIST_SH='included'


sourcetree::dblist::usage()
{
   [ "$#" -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} dblist [options]

   List the contents of the database. In contrast to \`list\`, which reads
   the sourcetree config files, this reads the database that is created
   during \`sync\`. It therefore also knows the filename each node is
   placed at and which sourcetree owns it.

   Use \`${MULLE_USAGE_NAME} dbstatus\` to query the state of the database.

Options:
   -F                   : append the filename of each node
   -m                   : append the marks of each node
   -o                   : append the owner of each node
   -u                   : append the (evaluated) URL of each node
   -_                   : prepend the UUID of each node
   --format <format>    : supply a custom format (see Format below)
   --force-format <fmt> : like --format but unmodifiable by -F, -m etc.
   --output-format <v>  : one of default (fmt), nodeline, raw
   --output-eval        : show evaluated values
   --output-header      : print a header (default)
   --output-no-header   : suppress the header
   --output-column      : columnize the output (default)
   --output-no-column   : don't columnize the output

   With \`--output-format nodeline\` each database node is printed as
   \`<uuid>;<nodeline>\`. With \`--output-format raw\` the complete stored
   database entry (nodeline, owner, filename, index and evaledurl) is
   printed.

Format:
EOF
   sourcetree::node::printf_format_help >&2

   cat <<EOF >&2
   F        : filename from the database (db only)
   o        : owner from the database (db only)

EOF
   exit 1
}


sourcetree::dblist::r_append_format_char()
{
   case ";$1;" in
      *\;$2\;*)
         RVAL="$1"
         return
      ;;
   esac

   RVAL="$1;$2"
}


sourcetree::dblist::r_prepend_format_char()
{
   case ";$1;" in
      *\;$2\;*)
         RVAL="$1"
         return
      ;;
   esac

   RVAL="$2;$1"
}


#
# returns newline separated "index;uuid" in proper order
#
sourcetree::dblist::r_uuids_in_order()
{
   log_entry "sourcetree::dblist::r_uuids_in_order" "$@"

   local databasedir="$1"

   local list
   local dbfile
   local uuid
   local index

   list=
   shell_enable_nullglob
   for dbfile in "${databasedir}"/????????-????-????-????-????????????
   do
      uuid="`basename "${dbfile}"`"
      index="`head -1 "${dbfile}" | sed -e 's/^\([^;]*\);.*/\1/'`"
      r_add_line "${list}" "${index};${uuid}"
      list="${RVAL}"
   done
   shell_disable_nullglob

   if [ ! -z "${list}" ]
   then
      list="`printf "%s\n" "${list}" | sort -d -t';' -k 1,1`"
   fi

   RVAL="${list}"
}


sourcetree::dblist::_list_formatted()
{
   log_entry "sourcetree::dblist::_list_formatted" "$@"

   local databasedir="$1"
   local format="$2"
   local mode="$3"

   local line
   local uuid
   local entry
   local first
   local _nodeline
   local _owner
   local _filename
   local _index
   local _evaledurl

   sourcetree::nodeline::printf_header "${mode}" "${format}"

   sourcetree::dblist::r_uuids_in_order "${databasedir}"
   .foreachline line in ${RVAL}
   .do
      uuid="${line#*;}"

      if ! entry="`sourcetree::db::recall "${SOURCETREE_START}" "${uuid}"`"
      then
         log_warning "Database entry \"${uuid}\" vanished"
         .continue
      fi

      {
         IFS= read -r first
         IFS= read -r _owner
         IFS= read -r _filename
         IFS= read -r _index
         IFS= read -r _evaledurl
      } <<< "${entry}"

      _nodeline="${first#*;}"
      _index="${first%%;*}"

      sourcetree::nodeline::parse "${_nodeline}"

      sourcetree::node::printf "${mode}" "${format}" "${OPTION_OUTPUT_CMDLINE}" ""
   .done
}


sourcetree::dblist::_list_nodelines()
{
   log_entry "sourcetree::dblist::_list_nodelines" "$@"

   local databasedir="$1"

   local line
   local uuid
   local nodeline

   sourcetree::dblist::r_uuids_in_order "${databasedir}"
   .foreachline line in ${RVAL}
   .do
      uuid="${line#*;}"

      nodeline="`sourcetree::db::fetch_nodeline_for_uuid "${SOURCETREE_START}" "${uuid}"`"
      printf "%s;%s\n" "${uuid}" "${nodeline}"
   .done
}


sourcetree::dblist::_list_raw()
{
   log_entry "sourcetree::dblist::_list_raw" "$@"

   local databasedir="$1"

   local line
   local uuid

   sourcetree::dblist::r_uuids_in_order "${databasedir}"
   .foreachline line in ${RVAL}
   .do
      uuid="${line#*;}"
      printf "# %s\n" "${uuid}"
      sourcetree::db::recall "${SOURCETREE_START}" "${uuid}"
      echo
   .done
}


sourcetree::dblist::main()
{
   log_entry "sourcetree::dblist::main" "$@"

   local OPTION_FORMAT='DEFAULT'
   local OPTION_FORCE_FORMAT
   local OPTION_OUTPUT_FORMAT='FMT'
   local OPTION_OUTPUT_HEADER='DEFAULT'
   local OPTION_OUTPUT_COLUMN='DEFAULT'
   local OPTION_OUTPUT_EVAL='NO'
   local OPTION_OUTPUT_URL='NO'
   local OPTION_OUTPUT_MARKS='NO'
   local OPTION_OUTPUT_FILENAME='NO'
   local OPTION_OUTPUT_OWNER='NO'
   local OPTION_OUTPUT_UUID='NO'
   local OPTION_OUTPUT_CMDLINE

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::dblist::usage
         ;;

         --format)
            [ $# -eq 1 ] && sourcetree::dblist::usage "Missing argument to \"$1\""
            shift

            OPTION_FORMAT="$1"
         ;;

         --force-format)
            [ $# -eq 1 ] && sourcetree::dblist::usage "Missing argument to \"$1\""
            shift

            OPTION_FORCE_FORMAT="$1"
         ;;

         --output-format)
            [ $# -eq 1 ] && sourcetree::dblist::usage "Missing argument to \"$1\""
            shift

            case "$1" in
               default|fmt|formatted)
                  OPTION_OUTPUT_FORMAT='FMT'
               ;;

               nodeline)
                  OPTION_OUTPUT_FORMAT='NODELINE'
               ;;

               raw)
                  OPTION_OUTPUT_FORMAT='RAW'
               ;;

               *)
                  sourcetree::dblist::usage "Unknown output format \"$1\""
               ;;
            esac
         ;;

         -_|--output-uuid)
            OPTION_OUTPUT_UUID='YES'
         ;;

         -u|--output-url)
            OPTION_OUTPUT_URL='YES'
         ;;

         -m|--output-marks)
            OPTION_OUTPUT_MARKS='YES'
         ;;

         -F|--output-filename)
            OPTION_OUTPUT_FILENAME='YES'
         ;;

         -o|--output-owner)
            OPTION_OUTPUT_OWNER='YES'
         ;;

         --output-eval)
            OPTION_OUTPUT_EVAL='YES'
         ;;

         --output-header)
            OPTION_OUTPUT_HEADER='YES'
         ;;

         --no-output-header|--output-no-header)
            OPTION_OUTPUT_HEADER='NO'
         ;;

         --output-column)
            OPTION_OUTPUT_COLUMN='YES'
         ;;

         --no-output-column|--output-no-column)
            OPTION_OUTPUT_COLUMN='NO'
         ;;

         -*)
            sourcetree::dblist::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 0 ] && sourcetree::dblist::usage "superfluous arguments \"$*\""

   include "sourcetree::db"
   include "sourcetree::nodeline"

   local _database
   local _databasedir

   sourcetree::db::__common_databasedir "${SOURCETREE_START}"

   if [ ! -d "${_databasedir}" ]
   then
      log_warning "No database here"
      return 1
   fi

   case "${OPTION_OUTPUT_FORMAT}" in
      NODELINE)
         sourcetree::dblist::_list_nodelines "${_databasedir}"
         return $?
      ;;

      RAW)
         sourcetree::dblist::_list_raw "${_databasedir}"
         return $?
      ;;
   esac

   #
   # build format from options unless force format was given
   #
   local format
   local mode

   format="${OPTION_FORMAT}"
   if [ "${format}" = 'DEFAULT' ]
   then
      format="%a"
   fi

   if [ "${OPTION_OUTPUT_UUID}" = 'YES' ]
   then
      sourcetree::dblist::r_prepend_format_char "${format}" '%_'
      format="${RVAL}"
   fi
   if [ "${OPTION_OUTPUT_FILENAME}" = 'YES' ]
   then
      sourcetree::dblist::r_append_format_char "${format}" '%F'
      format="${RVAL}"
   fi
   if [ "${OPTION_OUTPUT_OWNER}" = 'YES' ]
   then
      sourcetree::dblist::r_append_format_char "${format}" '%o'
      format="${RVAL}"
   fi
   if [ "${OPTION_OUTPUT_URL}" = 'YES' ]
   then
      sourcetree::dblist::r_append_format_char "${format}" '%u!'
      format="${RVAL}"
   fi
   if [ "${OPTION_OUTPUT_MARKS}" = 'YES' ]
   then
      sourcetree::dblist::r_append_format_char "${format}" '%m'
      format="${RVAL}"
   fi

   mode='flat'

   if [ "${OPTION_OUTPUT_HEADER}" != 'NO' ]
   then
      r_comma_concat "${mode}" "output_header"
      mode="${RVAL}"
      r_comma_concat "${mode}" "output_separator"
      mode="${RVAL}"
   fi

   if [ "${OPTION_OUTPUT_EVAL}" = 'YES' ]
   then
      r_comma_concat "${mode}" "output_eval"
      mode="${RVAL}"
   fi

   r_comma_concat "${mode}" 'comment'
   mode="${RVAL}"

   if [ ! -z "${OPTION_FORCE_FORMAT}" ]
   then
      format="${OPTION_FORCE_FORMAT}"
   else
      format="${format}\\n"
   fi

   if [ "${OPTION_OUTPUT_COLUMN}" != 'NO' ]
   then
      r_comma_concat "${mode}" "output_column"
      mode="${RVAL}"

      ( sourcetree::dblist::_list_formatted "${_databasedir}" \
                                             "${format}" \
                                             "${mode}" ; echo ) \
      | rexecute_column_table_or_cat ';'
   else
      sourcetree::dblist::_list_formatted "${_databasedir}" \
                                          "${format}" \
                                          "${mode}"
   fi
}
