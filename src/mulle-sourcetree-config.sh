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
MULLE_SOURCETREE_CONFIG_SH="included"


sourcetree::config::usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config <command>

   Manipulate sourcetree configuration files. A sourcetree configuration is
   usually stored in the
   "${MULLE_SOURCETREE_ETC_DIR#"${MULLE_USER_PWD}/"}/config" file.

   Sometimes you may need a completely different sourcetree configuration.
   For this you can have alternate sourcetree configuration names. When you
   specify these alternate names with the --config-name flag or the
   MULLE_SOURCETREE_CONFIG_NAME environment variable, this name will be
   used instead of "config".

Examples:
   If you desire to sometimes build with the Apple Foundation and sometimes
   with mulle-objc, you could keep the mulle-objc dependencies in the
   sourcetree with the default name "config" and introduce a second
   sourcetree with the name "apple" for Apple Foundation.
   To switch to the Apple Foundation you would set
   MULLE_SOURCETREE_CONFIG_NAME to 'apple'.
   
Commands:
   list
   copy
   remove

EOF
  exit 1
}


sourcetree::config::list_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config list [options]

   List the available sourcetree configuration files. The "config"
   configuration is the default configuration used my ${MULLE_USAGE_NAME},
   unless overridden by a
   MULLE_SOURCETREE_CONFIG_NAME_\${PROJECT_UPCASE_IDENTIFIER} environment
   variable.

Options:
   -n        : list only available names
   -s        : separator to separate names, if -n option is used
   --no-warn : don't print a warning if there is no sourcetree
EOF
   exit 1
}


sourcetree::config::copy_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} [flags] config copy [options] <destination>

   Copy the currently active sourcetree configuration to a different name.
   Use ${MULLE_USAGE_NAME} config switch <destination>, to use the copied
   configuration.

Tip:
   Use the --config-name flag to address a specific config file.

Options:
   -h  : help
EOF
   exit 1
}


sourcetree::config::remove_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} [flags] config remove <name>

   Remove the currently active sourcetree configuration. If the currently
   active configuration resides in "share", an empty configuration of the
   same name will be created in "etc". (Deleted files from "share" will
   reappear on the next project upgrade.)

Tip:
   Use the --config-name flag to address a specific config file.

Options:
   -h  : help
EOF
   exit 1
}


sourcetree::config::r_find()
{
   log_entry "sourcetree::config::r_find" "$@"

   local config_name="$1"
#   local config_scope="$2"

#   local scope
   local filename
   local rval
   local name

   rval=1

   .foreachpath name in ${config_name}
   .do
#      case "${config_scope}" in
#         'default')
#            scope="${MULLE_UNAME}"
#         ;;
#
#         'global')
#            scope=""
#         ;;
#
#         *)
#            scope="${config_scope}"
#         ;;
#      esac
#
#      if [ ! -z "${scope}" ]
#      then
#         filename="${MULLE_SOURCETREE_ETC_DIR}/${name}.${scope}"
#         if [ -f "${MULLE_SOURCETREE_ETC_DIR}/${name}.${scope}" ]
#         then
#            rval=0
#            .break
#         fi
#
#         filename="${MULLE_SOURCETREE_SHARE_DIR}/${name}.${scope}"
#         if [ -f "${MULLE_SOURCETREE_SHARE_DIR}/${name}.${scope}" ]
#         then
#            rval=0
#            .break
#         fi
#      fi
#
#      case "${config_scope}" in
#         default|global)
            filename="${MULLE_SOURCETREE_ETC_DIR}/${name}"
            if [ -f "${MULLE_SOURCETREE_ETC_DIR}/${name}" ]
            then
               rval=0
               .break
            fi

            filename="${MULLE_SOURCETREE_SHARE_DIR}/${name}"
            if [ -f "${MULLE_SOURCETREE_SHARE_DIR}/${name}" ]
            then
               rval=0
               .break
            fi
#         ;;
#      esac

      filename=""
   .done

   RVAL="${filename}"
   return $rval
}


sourcetree::config::list_main()
{
   log_entry "sourcetree::config::list_main" "$@"

   local OPTION_SEPARATOR=" "
   local OPTION_WARN="YES"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::config::list_usage
         ;;

         -n|--name-only)
            OPTION_NAME_ONLY='YES'
         ;;

         -s|--separator)
            [ $# -eq 1 ] && sourcetree::config::list_usage "Missing argument to \"$1\""
            shift

            OPTION_SEPARATOR="$1"
         ;;

         --no-warn)
            OPTION_WARN='NO'
         ;;

         -*)
            sourcetree::config::list_usage "Unknown config list option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 0 ] && sourcetree::config::list_usage "Superflous arguments $*"

   local filename
   local found
   local names

   shell_enable_nullglob

   if [ -d "${MULLE_SOURCETREE_ETC_DIR}" ]
   then
      [ "${OPTION_NAME_ONLY}" != 'YES' ] && log_info "etc"

      for filename in "${MULLE_SOURCETREE_ETC_DIR}"/*
      do
         if [ -f "${filename}" ] # ignore directories
         then
            if [ "${OPTION_NAME_ONLY}" = 'YES' ]
            then
               r_extensionless_basename "${filename}"
               r_add_unique_line "${names}" "${RVAL}"
               names="${RVAL}"
            else
               printf "%s\n" "${filename#"${MULLE_USER_PWD}/"}"
            fi
            found='YES'
         fi
      done
   fi

   if [ -d "${MULLE_SOURCETREE_SHARE_DIR}" ]
   then
      [ "${OPTION_NAME_ONLY}" != 'YES' ] && log_info "share"

      for filename in "${MULLE_SOURCETREE_SHARE_DIR}"/*
      do
         if [ -f "${filename}" ]  # ignore directories
         then
            if [ "${OPTION_NAME_ONLY}" = 'YES' ]
            then
               r_extensionless_basename "${filename}"
               r_add_unique_line "${names}" "${RVAL}"
               names="${RVAL}"
            else
               printf "%s\n" "${filename#"${MULLE_USER_PWD}/"}"
            fi
            found='YES'
         fi
      done
   fi

   shell_disable_nullglob

   if [ "${found}" != 'YES' -a "${OPTION_WARN}" = 'YES' ]
   then
      log_warning "There is no sourcetree here (\"${SOURCETREE_CONFIG_DIR}\")"
      return 0
   fi

   if [ "${OPTION_NAME_ONLY}" = 'YES' ]
   then
      local sep
      local line

      .foreachline line in ${names}
      .do
         printf "%s%s" "${sep}" "${line}"
         sep="${OPTION_SEPARATOR}"
      .done

      printf "\n"
   fi
}


sourcetree::config::copy_main()
{
   log_entry "sourcetree::config::copy_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::config::copy_usage
         ;;

         -a|--all)
            OPTION_ALL='YES'
         ;;

         -*)
            sourcetree::config::copy_usage "Unknown config copy option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -eq 0 ] && sourcetree::config::copy_usage "Missing destination argument"
   [ $# -gt 1 ] && shift && sourcetree::config::copy_usage "Superflous arguments $*"

   local destination="$1"

   local destination_file
#   local name
#   local scope

   if [ -z "${destination}" ]
   then
      fail "destination must not be empty"
   fi

   if [ "${destination//[^a-zA-Z0-9_-]/}" != "${destination}" ]
   then
      fail "\"${destination}\" is not a valid configuration name (identifier[.identifier])"
   fi

#   if [ "${scope//[^a-zA-Z0-9_-]/}" != "${scope}" ]
#   then
#      fail "\"${destination}\" is not a valid configuration name (${name}[.identifier])"
#   fi
#
#   if [ ! -z "${scope}" -a "${name}.${scope}" != "${destination}" ]
#   then
#      fail "\"${destination}\" is not a valid configuration name (identifier.identifier)"
#   fi

   destination_file="${MULLE_SOURCETREE_ETC_DIR}/${destination}"
   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' -a -f "${destination_file}" ]
   then
      fail "\"${destination_file#"${MULLE_USER_PWD}/"}\" already exists"
   fi

   if ! sourcetree::config::r_find "${SOURCETREE_CONFIG_NAME}" # "${SOURCETREE_CONFIG_SCOPES}"
   then
      local text

#      case "${SOURCETREE_CONFIG_SCOPES}" in
#         default|global)
#            text=""
#         ;;
#
#         *)
#            text="${SOURCETREE_CONFIG_SCOPES} "
#         ;;
#      esac
      fail "No ${text}sourcetree with name ${SOURCETREE_CONFIG_NAME} found"
   fi

   log_verbose "${RVAL#"${MULLE_USER_PWD}/"} found"

   remove_file_if_present "${destination_file}"
   exekutor cp -a "${RVAL}" "${destination_file}"
}


sourcetree::config::remove_main()
{
   log_entry "sourcetree::config::remove_main" "$@"

#   local scope
#
#   scope="${SOURCETREE_CONFIG_SCOPES}"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::config::remove_usage
         ;;

#         --scope)
#            [ $# -eq 1 ] && sourcetree::config::remove_usage "Missing argument to \"$1\""
#            shift
#
#            scope="$1"
#         ;;

         -*)
            sourcetree::config::remove_usage "Unknown config copy option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -gt 1 ] && shift && sourcetree::config::remove_usage "Superflous argument $*"

   local names

   names="${SOURCETREE_CONFIG_NAME}"
   if [ $# -eq 1 ]
   then
      names="$1"
   fi

   if ! sourcetree::config::r_find "${names}" # "${scope}"
   then
      local text
#
#      case "${scope}" in
#         default|global)
#            text=""
#         ;;
#
#         *)
#            text="${scope} "
#         ;;
#      esac
      fail "No ${text}sourcetree with name \"${names//:/\" or \"}\" found"
   fi

   log_verbose "${RVAL#"${MULLE_USER_PWD}/"} found"

   #
   # if in share, we gotta create an empty file, to effectively hide it
   #
   local name

   name="${RVAL#${MULLE_SOURCETREE_SHARE_DIR}/}"
   if [ "${name}" != "${RVAL}" ]
   then
      exekutor touch "${MULLE_SOURCETREE_SHARE_DIR}/${name}"
   else
      remove_file_if_present "${RVAL}"
   fi
}


sourcetree::config::main()
{
   log_entry "sourcetree::config::main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::config::usage
         ;;

         -*)
            sourcetree::config::usage "Unknown config option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   if [ -z "${MULLE_PATH_SH}" ]
   then
      # shellcheck source=mulle-path.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh" || return 1
   fi
   if [ -z "${MULLE_FILE_SH}" ]
   then
      # shellcheck source=mulle-file.sh
      . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-file.sh" || return 1
   fi

   local cmd="$1"

   [ $# -gt 0 ] && shift

   cmd="${cmd:-list}"
   case "${cmd}" in
      copy|list|remove)
         sourcetree::config::${cmd}_main "$@"
      ;;

      *)
         sourcetree::config::usage "Unknown command \"${cmd}\""
      ;;
   esac
}

