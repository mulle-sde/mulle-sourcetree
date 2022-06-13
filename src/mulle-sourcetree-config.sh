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
MULLE_SOURCETREE_CONFIG_SH="included"


sourcetree::config::usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} config <command>

   Manipulate sourcetree configuration files. Usually a sourcetree
   configuration is stored in the
   "${MULLE_SOURCETREE_ETC_DIR#${MULLE_USER_PWD}/}/config" file. OS specific
   derivations called "scopes" are stored separately. (For the current
   OS scope that would be "${MULLE_SOURCETREE_ETC_DIR#${MULLE_USER_PWD}/}/config.${MULLE_UNAME}").

   Sometimes you may need two completely different sourcetree configurations.
   For this you can have alternate sourcetree configuration names. When you
   specify these alternate names with the --config-names flag or the
   MULLE_SOURCETREE_CONFIG_NAMES_${PROJECT_UPCASE_IDENTIFIER:-LOCAL} environment
   variable, these names will be searched in the given order of preference.

Examples:
   Two scopes
      You want your library to build with mulle-objc by default, but on Apple
      you always want to use the Apple Foundation. You use the OS "scoping" of
      mulle-sourcetree with a standard "config" for mulle-objc and a
      "config.darwin" for Apple.

   Two names
      If you desire to sometimes build with the Apple Foundation and sometimes
      with mulle-objc, you could keep the mulle-objc dependencies in the
      sourcetree with the default name "config" and introduce a second
      sourcetree with the name "apple" for Apple Foundation.
      To switch to the Apple Foundation you would set
      MULLE_SOURCETREE_CONFIG_NAMES_${PROJECT_UPCASE_IDENTIFIER:-LOCAL} to
      'apple:config', having the default as a fallback.
   
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

   List the currently active sourcetree configuration. You can also see the
   available sourcetree configurations.

Options:
   -a  : list all available sourcetree configurations
EOF
}


sourcetree::config::name_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} [flags] config name [options]

   List the currently active sourcetree configuration name.

Tip:
   Use the --config-names and --config-scope flags to address a specific
   config file.

Options:
   -h  : help
EOF
}



sourcetree::config::copy_usage()
{
   [ $# -ne 0 ] && log_error "$*"

   cat <<EOF >&2
Usage:
   ${MULLE_USAGE_NAME} [flags] config copy [options] <destination>

   Copy the currently active sourcetree configuration to a different name.

Tip:
   Use the --config-names and --config-scope flags to address a specific
   config file.

Options:
   -h  : help
EOF
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
   Use the --config-names and --config-scope flags to address a specific
   config file.

Options:
   -h  : help
EOF
}


sourcetree::config::r_find()
{
   log_entry "sourcetree::config::r_find" "$@"

   local config_names="$1"
   local config_scope="$2"

   local scope
   local filename
   local rval
   local name

   rval=1

   IFS=':'; shell_disable_glob
   for name in ${config_names}
   do
      IFS="${DEFAULT_IFS}"; shell_enable_glob

      case "${config_scope}" in
         'default')
            scope="${MULLE_UNAME}"
         ;;

         'global')
            scope=""
         ;;

         *)
            scope="${config_scope}"
         ;;
      esac

      if [ ! -z "${scope}" ]
      then
         filename="${MULLE_SOURCETREE_ETC_DIR}/${name}.${scope}"
         if [ -f "${MULLE_SOURCETREE_ETC_DIR}/${name}.${scope}" ]
         then
            rval=0
            break
         fi

         filename="${MULLE_SOURCETREE_SHARE_DIR}/${name}.${scope}"
         if [ -f "${MULLE_SOURCETREE_SHARE_DIR}/${name}.${scope}" ]
         then
            rval=0
            break
         fi
      fi

      case "${config_scope}" in
         default|global)
            filename="${MULLE_SOURCETREE_ETC_DIR}/${name}"
            if [ -f "${MULLE_SOURCETREE_ETC_DIR}/${name}" ]
            then
               rval=0
               break
            fi

            filename="${MULLE_SOURCETREE_SHARE_DIR}/${name}"
            if [ -f "${MULLE_SOURCETREE_SHARE_DIR}/${name}" ]
            then
               rval=0
               break
            fi
         ;;
      esac

      filename=""
   done
   shell_disable_glob

   RVAL="${filename}"
   return $rval
}


sourcetree::config::list_main()
{
   log_entry "sourcetree::config::list_main" "$@"

   local OPTION_ALL

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::config::list_usage
         ;;

         -a|--all)
            OPTION_ALL='YES'
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

   if [ "${OPTION_ALL}" = 'YES' ]
   then
      shell_enable_nullglob
      if [ -d "${MULLE_SOURCETREE_ETC_DIR}" ]
      then
         log_info "etc"

         for filename in "${MULLE_SOURCETREE_ETC_DIR}"/*
         do
            if [ -f "${filename}" ] # ignore directories
            then
               printf "%s\n" "${filename#${MULLE_USER_PWD}/}"
               found='YES'
            fi
         done
      fi

      if [ -d "${MULLE_SOURCETREE_SHARE_DIR}" ]
      then
         log_info "share"

         for filename in "${MULLE_SOURCETREE_SHARE_DIR}"/*
         do
            if [ -f "${filename}" ]  # ignore directories
            then
               printf "%s\n" "${filename#${MULLE_USER_PWD}/}"
               found='YES'
            fi
         done
      fi

      shell_disable_nullglob
      return

      if [ "${found}" != 'YES' ]
      then
         log_warning "There is no sourcetree here"
      fi
   fi

   #
   #
   #
   if sourcetree::config::r_find "${SOURCETREE_CONFIG_NAMES}" \
                               "${SOURCETREE_SCOPE}"
   then
      printf "%s\n" "${RVAL#${MULLE_USER_PWD}/}"
   else
      log_warning "There is no sourcetree here"
   fi
}


# scopeless name or names without etc or share
sourcetree::config::name_main()
{
   log_entry "sourcetree::config::name_main" "$@"

   local OPTION_ALL
   local OPTION_SEPARATOR=$'\n'

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::config::name_usage
         ;;

         -a|--all)
            OPTION_ALL='YES'
         ;;

         --separator)
            [ $# -eq 1 ] && sourcetree::config::name_usage "Missing argument to \"$1\""
            shift

            OPTION_SEPARATOR="$1"
         ;;

         -*)
            sourcetree::config::name_usage "Unknown config list option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 0 ] && sourcetree::config::name_usage "Superflous arguments $*"

   local filename
   local found

   if [ "${OPTION_ALL}" = 'YES' ]
   then
      local names 

      shell_enable_nullglob
      if [ -d "${MULLE_SOURCETREE_ETC_DIR}" ]
      then
         for filename in "${MULLE_SOURCETREE_ETC_DIR}"/*
         do
            if [ -f "${filename}" ] # ignore directories
            then
               r_extensionless_basename "${filename}"
               r_add_unique_line "${names}" "${RVAL}"
               names="${RVAL}"
            fi
         done
      fi

      if [ -d "${MULLE_SOURCETREE_SHARE_DIR}" ]
      then
         for filename in "${MULLE_SOURCETREE_SHARE_DIR}"/*
         do
            if [ -f "${filename}" ] # ignore directories
            then
               r_extensionless_basename "${filename}"
               r_add_unique_line "${names}" "${RVAL}"
               names="${RVAL}"
            fi
         done
      fi

      shell_disable_nullglob

      if [ ! -z "${names}" ]
      then
         local sep
         local line

         IFS=$'\n'
         for line in ${names}
         do
            printf "%s%s" "${sep}" "${line}"
            sep="${OPTION_SEPARATOR}"
         done
         IFS="${DEFAULT_IFS}"

         printf "\n"
         return 0
      fi
      return 1
   fi

   if sourcetree::config::r_find "${SOURCETREE_CONFIG_NAMES}" \
                                 "${SOURCETREE_SCOPE}"
   then
      r_extensionless_basename "${RVAL}"
      printf "%s\n" "${RVAL}"
      return 0
   fi

   return 1
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
   local name
   local scope

   if [ -z "${destination}" ]
   then
      fail "destination must not be empty"
   fi

   case "${destination}" in
      *\.*)
         name="${destination%%.*}"
         scope="${destination#*.}"
      ;;

      *)
         name="${destination}"
      ;;
   esac

   if [ "${name//[^a-zA-Z0-9_-]/}" != "${name}" ]
   then
      fail "\"${destination}\" is not a valid configuration name (identifier[.identifier])"
   fi

   if [ "${scope//[^a-zA-Z0-9_-]/}" != "${scope}" ]
   then
      fail "\"${destination}\" is not a valid configuration name (${name}[.identifier])"
   fi

   if [ ! -z "${scope}" -a "${name}.${scope}" != "${destination}" ]
   then
      fail "\"${destination}\" is not a valid configuration name (identifier.identifier)"
   fi

   destination_file="${MULLE_SOURCETREE_ETC_DIR}/${destination}"
   if [ "${MULLE_FLAG_MAGNUM_FORCE}" != 'YES' -a -f "${destination_file}" ]
   then
      fail "\"${destination_file#${MULLE_USER_PWD}/}\" already exists"
   fi

   if ! sourcetree::config::r_find "${SOURCETREE_CONFIG_NAMES}" "${SOURCETREE_SCOPE}"
   then
      local text

      case "${SOURCETREE_SCOPE}" in
         default|global)
            text= ""
         ;;

         *)
            text="${SOURCETREE_SCOPE} "
         ;;
      esac
      fail "No ${text}sourcetree with names ${SOURCETREE_CONFIG_NAMES//:/,} found"
   fi

   log_verbose "${RVAL#${MULLE_USER_PWD}/} found"

   remove_file_if_present "${destination_file}"
   exekutor cp -a "${RVAL}" "${destination_file}"
}


sourcetree::config::remove_main()
{
   log_entry "sourcetree::config::remove_main" "$@"

   while [ $# -ne 0 ]
   do
      case "$1" in
         -h*|--help|help)
            sourcetree::config::remove_usage
         ;;

         -*)
            sourcetree::config::remove_usage "Unknown config copy option $1"
         ;;

         *)
            break
         ;;
      esac

      shift
   done

   [ $# -ne 0 ] && sourcetree::config::remove_usage "Superflous argument $*"

   if ! sourcetree::config::r_find "${SOURCETREE_CONFIG_NAMES}" "${SOURCETREE_SCOPE}"
   then
      local text

      case "${SOURCETREE_SCOPE}" in
         default|global)
            text= ""
         ;;

         *)
            text="${SOURCETREE_SCOPE} "
         ;;
      esac
      fail "No ${text}sourcetree with names ${SOURCETREE_CONFIG_NAMES//:/,} found"
   fi

   log_verbose "${RVAL#${MULLE_USER_PWD}/} found"

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
      name|copy|list|remove)
         sourcetree::config::${cmd}_main "$@"
      ;;

      *)
         sourcetree::config::usage "Unknown command \"${cmd}\""
      ;;
   esac
}

