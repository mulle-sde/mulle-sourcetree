# shellcheck shell=bash
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
MULLE_SOURCETREE_ENVIRONMENT_SH='included'


sourcetree::environment::config()
{
   log_entry "sourcetree::environment::config" "$@"

   local config_dir="$1"
   local config_names="$2"
   local use_fallback="$3"
   local mode="$4"

   [ -z "${MULLE_SOURCETREE_ETC_DIR}" ]     && _internal_fail "MULLE_SOURCETREE_ETC_DIR is empty"
   [ -z "${MULLE_SOURCETREE_SHARE_DIR}" ]   && _internal_fail "MULLE_SOURCETREE_SHARE_DIR is empty"
   [ -z "${MULLE_SOURCETREE_PROJECT_DIR}" ] && _internal_fail "MULLE_SOURCETREE_PROJECT_DIR is empty"

   SOURCETREE_CONFIG_NAME="${config_names:-config}"

   if [ ! -z "${config_dir}" ]
   then
      SOURCETREE_CONFIG_DIR="${config_dir#"${MULLE_SOURCETREE_PROJECT_DIR}/"}"
      SOURCETREE_FALLBACK_CONFIG_DIR=""
   else
      SOURCETREE_CONFIG_DIR="${MULLE_SOURCETREE_ETC_DIR#"${MULLE_SOURCETREE_PROJECT_DIR}/"}"
      SOURCETREE_FALLBACK_CONFIG_DIR="${MULLE_SOURCETREE_SHARE_DIR#"${MULLE_SOURCETREE_PROJECT_DIR}/"}"
   fi

   if [ "${use_fallback}" = 'YES' ]
   then
      SOURCETREE_CONFIG_DIR="${config_dir#"${MULLE_SOURCETREE_PROJECT_DIR}/"}"
      SOURCETREE_CONFIG_DIR="${SOURCETREE_CONFIG_DIR:-${SOURCETREE_FALLBACK_CONFIG_DIR}}"
      SOURCETREE_FALLBACK_CONFIG_DIR=""
   fi

   SOURCETREE_MODE="${mode}" # maybe empty for now

   is_absolutepath "${SOURCETREE_CONFIG_DIR}" \
   && _internal_fail "SOURCETREE_CONFIG_DIR \"${SOURCETREE_CONFIG_DIR}\" must be relative"
   is_absolutepath "${SOURCETREE_FALLBACK_CONFIG_DIR}" \
   && _internal_fail "SOURCETREE_FALLBACK_CONFIG_DIR \"${SOURCETREE_FALLBACK_CONFIG_DIR}\" must be relative"

   if [ -z "${SOURCETREE_FIX_FILENAME}" ]
   then
      case "${MULLE_UNAME}" in
         windows)
            SOURCETREE_FIX_FILENAME=".mulle/var/${MULLE_HOSTNAME}/${MULLE_USERNAME}.fix"
         ;;

         *)
            SOURCETREE_FIX_FILENAME="${MULLE_SOURCETREE_VAR_DIR#"${MULLE_SOURCETREE_PROJECT_DIR}/"}fix"
         ;;
      esac
   fi
}


sourcetree::environment::minimal()
{
   log_entry "sourcetree::environment::minimal" "$@"

   local directory="$1"

   if [ -z "${directory}" -a ! -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      directory="${MULLE_VIRTUAL_ROOT}"
      log_fluff "Sourcetree uses MULLE_VIRTUAL_ROOT ($MULLE_VIRTUAL_ROOT)"
   fi

   if [ -z "${directory}" ]
   then
      directory="${PWD}"
      log_debug "Sourcetree uses PWD ($directory)"
   fi

   [ -z "${MULLE_PATH_SH}" ] && . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-path.sh"

   r_absolutepath "${directory}"
   r_physicalpath "${RVAL}"

   MULLE_SOURCETREE_PROJECT_DIR="${RVAL}"

   if [ -z "${MULLE_VIRTUAL_ROOT}" ]
   then
      MULLE_VIRTUAL_ROOT="${MULLE_SOURCETREE_PROJECT_DIR}"
      log_fluff "Sourcetree sets MULLE_VIRTUAL_ROOT to \"${MULLE_VIRTUAL_ROOT}\""
   fi

   MULLE_HOSTNAME="${MULLE_HOSTNAME:-`hostname`}" # -s doesn't work on solaris
}


sourcetree::environment::basic()
{
   log_entry "sourcetree::environment::basic" "$@"

   local directory="$1"
   local config_dir="$2"
   local config_names="$3"
   local use_fallback="$4"
   local mode="$5"

   sourcetree::environment::minimal "${directory}"

   # no share in sourcetree operation
   # MULLE_SOURCETREE_SHARE_DIR="${MULLE_SOURCETREE_PROJECT_DIR}/.mulle/share/sourcetree"

   #
   # we don't want to "climb out" of MULLE_SOURCETREE_PROJECT_DIR so
   # use --search-here
   #
   eval `"${MULLE_ENV:-mulle-env}" \
               ${MULLE_TECHNICAL_FLAGS} \
               -d "${MULLE_SOURCETREE_PROJECT_DIR}" \
               --search-here \
               mulle-tool-env sourcetree` || exit 1

   sourcetree::environment::config "${config_dir}" \
                                   "${config_names}" \
                                   "${use_fallback}" \
                                   "${mode}"


   log_setting "MULLE_SOURCETREE_PROJECT_DIR   : ${MULLE_SOURCETREE_PROJECT_DIR}"
   log_setting "SOURCETREE_CONFIG_NAME         : ${SOURCETREE_CONFIG_NAME}"
   log_setting "SOURCETREE_CONFIG_DIR          : ${SOURCETREE_CONFIG_DIR}"
   log_setting "SOURCETREE_FALLBACK_CONFIG_DIR : ${SOURCETREE_FALLBACK_CONFIG_DIR}"
   log_setting "MULLE_SOURCETREE_ETC_DIR       : ${MULLE_SOURCETREE_ETC_DIR}"
   log_setting "MULLE_SOURCETREE_VAR_DIR       : ${MULLE_SOURCETREE_VAR_DIR}"
   log_setting "MULLE_SOURCETREE_SHARE_DIR     : ${MULLE_SOURCETREE_SHARE_DIR}"
}


sourcetree::environment::default()
{
   log_entry "sourcetree::environment::default" "$@"

   local option_sharedir="$1"
   local option_configdir="$2"
   local option_confignames="$3"
   local option_use_fallback="$4"
   local defer="$5"
   local mode="$6"

   # MULLE_USER_PWD can be somewhere else, but for relative paths we 
   # must assume the current PWD is the onw
   
   SOURCETREE_USER_PWD="${PWD}"

   sourcetree::environment::basic "" \
                                  "${option_configdir}" \
                                  "${option_confignames}" \
                                  "${option_use_fallback}" \
                                  "${mode}"

   if [ "${defer}" = "VIRTUAL" ]
   then
      [ -z "${MULLE_VIRTUAL_ROOT}" ] && fail "MULLE_VIRTUAL_ROOT not set"

      cd "${MULLE_VIRTUAL_ROOT}" || fail "failed to cd to \"${MULLE_VIRTUAL_ROOT}\""

      sourcetree::environment::_set_sourcetree_global "${MULLE_SOURCETREE_PROJECT_DIR}"
   else
      sourcetree::environment::_set_sourcetree_global "${MULLE_SOURCETREE_PROJECT_DIR}"

      #
      # Todo: the defer thing is probably old junk
      #
      if ! sourcetree::cfg::defer_if_needed "${defer:-NEAREST}"
      then
         # could be an add, so can't really quit here
         if [ "${defer}" = "PARENT" ]
         then
            exit 1
         fi
      fi
   fi

   #
   # the setting of the share directory is somewhat arcane, the general idea
   # was probably to have a common stash directory for multiple projects.
   # TODO: get rid of this ?
   #
   sourcetree::environment::set_share_dir "${option_sharedir}"
}


sourcetree::environment::_set_sourcetree_global()
{
   log_entry "sourcetree::environment::_set_sourcetree_global" "$@"

   local physicalpwd="$1"

   #
   # SOURCETREE_START is /, if we are in MULLE_VIRTUAL_ROOT
   # otherwise calculate the relative path and append /
   #
   if [ "${MULLE_VIRTUAL_ROOT}" != "${physicalpwd}" ]
   then
      SOURCETREE_START="${physicalpwd#${MULLE_VIRTUAL_ROOT}}"
      if [ "${SOURCETREE_START}" = "${physicalpwd}" ]
      then
         fail "\"${physicalpwd}\" lies outside of MULLE_VIRTUAL_ROOT (${MULLE_VIRTUAL_ROOT}). \
Use -e if this is desired."
      fi
   fi
   SOURCETREE_START="${SOURCETREE_START%%/}/"

   #
   # our db is specific to a host
   #
   [ -z "${MULLE_HOSTNAME}" ] && _internal_fail "MULLE_HOSTNAME is empty"
   [ -z "${MULLE_USERNAME}" ] && _internal_fail "MULLE_USERNAME is empty"

   # for testing let it be overrideable
   if [ -z "${SOURCETREE_DB_FILENAME}" ]
   then
      SOURCETREE_DB_FILENAME=".mulle/var/${MULLE_HOSTNAME}/${MULLE_USERNAME}/sourcetree/db"
      SOURCETREE_DB_FILENAME_RELATIVE="../../../../../.."
   fi
}


sourcetree::environment::set_share_dir()
{
   log_entry "sourcetree::environment::set_share_dir" "$@"

   local usershare_dir="$1"

   [ -z "${MULLE_VIRTUAL_ROOT}" ] && _internal_fail "MULLE_VIRTUAL_ROOT must be defined by now"
   [ -z "${SOURCETREE_START}" ]   && _internal_fail "SOURCETREE_START must be defined by now"

   if [ -z "${usershare_dir}" ]
   then
      #
      # make stash the default, this is less painful when running
      # mulle-sourcetree outside of the environment in most cases
      #
      MULLE_SOURCETREE_STASH_DIRNAME="${MULLE_SOURCETREE_STASH_DIRNAME:-stash}"
      #
      # try to recover old user choice for shared directory
      # this will override the ENVIRONMENT for consistency
      # but only if the .db is not some trash w/o a config
      #
      if sourcetree::cfg::is_config_present "${SOURCETREE_START}"
      then
         local share_dir

         if share_dir="`sourcetree::db::get_shareddir "${SOURCETREE_START}"`"
         then
            if [ -d "${share_dir}" ]
            then
               r_physicalpath "${share_dir}"
               MULLE_SOURCETREE_STASH_DIR="${RVAL}"
               log_debug "Using database share directory \"${share_dir}\""

               r_basename "${MULLE_SOURCETREE_STASH_DIR}"
               MULLE_SOURCETREE_STASH_DIRNAME="${RVAL}"
            fi
         fi
      fi
   else
      if is_absolutepath "${usershare_dir}"
      then
         MULLE_SOURCETREE_STASH_DIR="${usershare_dir}"
         log_debug "Using user supplied shared directory \"${MULLE_SOURCETREE_STASH_DIR}\""
      else
         MULLE_SOURCETREE_STASH_DIRNAME="${usershare_dir}"
         log_debug "Using user supplied shared directory named \"${MULLE_SOURCETREE_STASH_DIRNAME}\""
      fi
   fi

   case "${MULLE_SOURCETREE_STASH_DIR}" in
      "")
         r_filepath_concat "${MULLE_VIRTUAL_ROOT}" "${MULLE_SOURCETREE_STASH_DIRNAME}"
         MULLE_SOURCETREE_STASH_DIR="${RVAL}"
         log_debug "Default shared directory is \"${MULLE_SOURCETREE_STASH_DIR}\""
      ;;

      "/"*)
         # MULLE_SOURCETREE_STASH_DIR="${MULLE_SOURCETREE_STASH_DIR}"
         log_debug "Environment directory is \"${MULLE_SOURCETREE_STASH_DIR}\""
      ;;

      *)
         fail "MULLE_SOURCETREE_STASH_DIR must be an absolute path. (use MULLE_SOURCETREE_STASH_DIRNAME instead)"
      ;;
   esac
}


sourcetree::environment::check_sane_stash_dir()
{
   log_entry "sourcetree::environment::check_sane_stash_dir" "$@"

   local physical

   r_physicalpath "${MULLE_SOURCETREE_STASH_DIR}"
   physical="${RVAL}"

   # if it doesn't exist then we can't say much about it
   if [ ! -z "${physical}" ]
   then
      if [ "${physical}" != "${MULLE_SOURCETREE_STASH_DIR}" ]
      then
         log_warning "MULLE_SOURCETREE_STASH_DIR (${MULLE_SOURCETREE_STASH_DIR}) is traversing symlinks. Will use \"${physical}\""
         MULLE_SOURCETREE_STASH_DIR="${physical}"
      fi
   fi

   #
   # check that an absolute MULLE_SOURCETREE_STASH_DIR does not go outside
   # MULLE_VIRTUAL_ROOT.
   # MEMO: I think this is actually a cool feature.
   #
   # Ensure that stash dir is at least three levels deep, /tmp/xxx/stash is
   # OK
   #
   case "${MULLE_SOURCETREE_STASH_DIR}" in
      *".."*)
        fail "MULLE_SOURCETREE_STASH_DIR contains .."
      ;;

      /*)
#          local relative
#
#          relative="`symlink_relpath "${MULLE_SOURCETREE_STASH_DIR}" "${MULLE_VIRTUAL_ROOT}" `"
#          case "${relative}" in
#             *..*)
#                case "${MULLE_SHELL_MODE}" in
#                   SUBSHELL*)
#                   ;;
#
#                   *)
#                      _log_warning "MULLE_SOURCETREE_STASH_DIR \
# (${MULLE_SOURCETREE_STASH_DIR}) lies outside of MULLE_VIRTUAL_ROOT \
# ($MULLE_VIRTUAL_ROOT)."
#                      log_fluff "Hint: MULLE_SOURCETREE_STASH_DIR must not contain symlinks."
#                   ;;
#                esac
#             ;;
#          esac
      ;;

      "")
         _internal_fail "MULLE_SOURCETREE_STASH_DIR (${MULLE_SOURCETREE_STASH_DIR}) is empty"
      ;;

      *"/")
         _internal_fail "MULLE_SOURCETREE_STASH_DIR (${MULLE_SOURCETREE_STASH_DIR}) ends with /"
      ;;

      *)
         _internal_fail "MULLE_SOURCETREE_STASH_DIR (${MULLE_SOURCETREE_STASH_DIR}) is not absolute"
      ;;
   esac

   r_path_depth "${MULLE_SOURCETREE_STASH_DIR}"
   case ${RVAL} in
      0|1|2)
         _internal_fail "MULLE_SOURCETREE_STASH_DIR (${MULLE_SOURCETREE_STASH_DIR}) is too close to root"
      ;;
   esac
}



# sets external variables!!
sourcetree::environment::set_default_db_mode()
{
   log_entry "sourcetree::environment::set_default_db_mode" "$@"

   local database="$1"
   local usertype="$2"

   local actualdbtype

   actualdbtype="`sourcetree::db::get_dbtype "${database}"`"

   local _rootdir

   # que ??
   if [ ! -z "${actualdbtype}"  ]
   then
      sourcetree::db::__common__rootdir "${database}"
   fi

   local dbtype

   dbtype="${usertype}"
   if [ -z "${dbtype}" ]
   then
      dbtype="${actualdbtype}"
      if [ -z "${dbtype}" ]
      then
         dbtype="share"       # the default
      else
         r_simplified_absolutepath "${_rootdir}"
         log_fluff "Database: ${C_RESET_BOLD}${RVAL} ${C_MAGENTA}${C_BOLD}${actualdbtype}${C_INFO}"
      fi
   fi

   case "${dbtype}" in
      share|recurse|flat)
         SOURCETREE_MODE="${dbtype}"
      ;;

      partial)
         # partial means it's created by a parent share
         # but itself is not shared, but inherently partially recurse
         SOURCETREE_MODE="recurse"
      ;;

      no-share)
         SOURCETREE_MODE="recurse"
      ;;

      *)
         _internal_fail "unknown dbtype \"${dbtype}\""
      ;;
   esac

   if [ ! -z "${SOURCETREE_MODE}" ]
   then
      log_debug "Mode: ${C_MAGENTA}${C_BOLD}${SOURCETREE_MODE}${C_INFO}"
      if [ "${SOURCETREE_MODE}" = "share" ]
      then
         [ -z "${MULLE_SOURCETREE_STASH_DIR}" ] && _internal_fail "MULLE_SOURCETREE_STASH_DIR is empty"
         log_debug "Stash directory: ${C_RESET_BOLD}${MULLE_SOURCETREE_STASH_DIR}${C_INFO}"
      fi
   fi
}


sourcetree::environment::setup()
{
   log_entry "sourcetree::environment::setup" "$@"

   local option_sharedir="${1:-}"
   local option_dirname="${2:-}"
   local option_mode="${3:-}"

   sourcetree::environment::default "" \
                                    "${option_dirname}" \
                                    "" \
                                    "" \
                                    "" \
                                    "" \
                                    "${option_mode}"
   sourcetree::environment::set_share_dir "${option_sharedir}"
   sourcetree::environment::check_sane_stash_dir
   sourcetree::environment::set_default_db_mode "/"
}


sourcetree::environment::initialize()
{
   include "sourcetree::cfg"
   include "sourcetree::db"
   include "sourcetree::node"
   include "sourcetree::nodeline"
   include "sourcetree::marks"
}

sourcetree::environment::initialize

:
