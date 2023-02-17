# shellcheck shell=bash
#
#   Copyright (c) 2021 Nat! - Mulle kybernetiK
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
MULLE_SOURCETREE_FILTER_SH='included'



sourcetree::filter::usage()
{
   if [ "$#" -ne 0 ]
   then
      log_error "$*"
   fi

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} filter [options] <marks> <qualifier>

   Apply qualifier on marks, and report if it matches or not.


Example:
   ${MULLE_USAGE_NAME} filter no-foo 'ENABLES foo'
   ${MULLE_USAGE_NAME} filter version-max-darwin-10.99.0 \\
                              'VERSION version-max-darwin >= 11.0.0'

Options:
   -h   : this help
EOF
   exit 1
}


sourcetree::filter::main()
{
   log_entry "sourcetree::filter::main" "$@"

   while :
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::filter::usage
         ;;

         -*)
            sourcetree::filter::usage "Unknown option \"$1\""
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 2 ] || sourcetree::filter::usage

   # shellcheck source=src/mulle-sourcetree-fix.sh
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodemarks.sh"

   if sourcetree::nodemarks::filter_with_qualifier "$@"
   then
      echo 'YES'
   else
      echo 'NO'
   fi
}

