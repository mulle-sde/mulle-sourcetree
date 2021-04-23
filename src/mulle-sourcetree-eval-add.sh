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
MULLE_SOURCETREE_EVAL_ADD_SH="included"


sourcetree_eval_add_usage()
{
   [ "$#" -ne 0 ] && log_error "$1"

    cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} eval-add <commands>

   Process a list of mulle-sourcetree -N add ... commands like a command-line
   shell would. Commands are given as a single string, separated by linefeeds.

   This is used by other mulle-sde tools that process "sourcetree" files.

EOF
  exit 1
}


sourcetree_append_add_command()
{
   log_entry "sourcetree_append_add_command" "$@"

   local arguments_list="$1"
   local arguments="$2"

   case "${arguments}" in
      "")
         RVAL="${arguments_list}"
         return
      ;;

      mulle-sourcetree*add*)
         arguments="${arguments#*add}"
      ;;
   esac

   r_add_line "${arguments_list}" "${arguments}"
}


# like mulle_sde_init add_to_sourcetree but no templating
sourcetree_eval_add_commands()
{
   log_entry "sourcetree_eval_add_commands" "$@"

   local lines="$1"
   local filename="$2"

   local line
   local arguments
   local arguments_list

   (
      shopt -s extglob

      set -o noglob; IFS=$'\n'
      for line in ${lines}
      do
         # https://stackoverflow.com/questions/50259869/how-to-replace-multiple-spaces-with-a-single-space-using-bash
         line="${line//+([[:blank:]])/ }"
         case "${line}" in
            "")
               if [ -z "${arguments}" ]
               then
                  continue
               fi
            ;;

            *\$\(*|*\`*)
               fail "${filename} contains suspicious code"
            ;;

            *\\)
               arguments="${arguments}${line%\\}"
               continue
            ;;
         esac

         sourcetree_append_add_command "${arguments_list}" "${arguments}${line}"
         arguments_list="${RVAL}"
         arguments=
      done

      sourcetree_append_add_command "${arguments_list}" "${arguments}"
      arguments_list="${RVAL}"

      for arguments in ${arguments_list}
      do
         # This is somewhat dangerous as we
         # are evaluating possibly hostile code here, but only as arguments
         # to sourcetree_add_main and the executable bits $( and ` should have
         # been taken care of.  We use a subshell for slightly improved peace
         # of mind
         #
         (
            eval_exekutor sourcetree_add_main "${arguments}"
         ) || fail "\"${filename}\" has malformed contents: ${arguments}"
      done
   ) || exit 1
}




sourcetree_eval_add_main()
{
   log_entry "sourcetree_eval_add_main" "$@"

   local OPTION_FILENAME

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree_eval_add_usage
         ;;

         --filename)
            [ $# -eq 1 ] \
               && sourcetree_eval_add_usage "Missing argument to \"$1\""
            shift

            OPTION_FILENAME="$1"
         ;;

         --)
            shift
            break;
         ;;

         -*)
            sourcetree_eval_add_usage "Unknown option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ "$#" -eq 0  ] && sourcetree_eval_add_usage "Missing command line text"
   [ "$#" -gt 1  ] && shift && sourcetree_eval_add_usage "Superflous input \"$*\""

   sourcetree_eval_add_commands "$1" \
                                "${OPTION_FILENAME:-<input>}"
}


sourcetree_eval_add_initialize()
{
   log_entry "sourcetree_eval_add_initialize"

   if [ -z "${MULLE_BASHFUNCTIONS_SH}" ]
   then
      [ -z "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}" ] && internal_fail "MULLE_BASHFUNCTIONS_LIBEXEC_DIR is empty"

      # shellcheck source=../../mulle-bashfunctions/src/mulle-bashfunctions.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_WALK_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-config.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-config.sh" || exit 1
   fi
}


sourcetree_eval_add_initialize

: