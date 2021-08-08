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
MULLE_SOURCETREE_ENVIRONMENT_SH="included"


sourcetree_config_environment()
{
   log_entry "sourcetree_config_environment" "$@"

   local config_dir="$1"
   local use_fallback="$2"
   local scope="$3"
   local mode="$4"

   if [ ! -z "${config_dir}" ]
   then
      SOURCETREE_CONFIG_FILENAME="${config_dir#${MULLE_SOURCETREE_PROJECT_DIR}/}/config"
      SOURCETREE_FALLBACK_CONFIG_FILENAME=""
   else
      SOURCETREE_CONFIG_FILENAME="${MULLE_SOURCETREE_ETC_DIR#${MULLE_SOURCETREE_PROJECT_DIR}/}/config"
      SOURCETREE_FALLBACK_CONFIG_FILENAME="${MULLE_SOURCETREE_SHARE_DIR#${MULLE_SOURCETREE_PROJECT_DIR}/}/config"
   fi

   if [ "${use_fallback}" = 'YES' ]
   then
      SOURCETREE_CONFIG_FILENAME="${SOURCETREE_FALLBACK_CONFIG_FILENAME}"
      SOURCETREE_FALLBACK_CONFIG_FILENAME=""
   fi

   SOURCETREE_SCOPE="${scope:-default}"
   SOURCETREE_MODE="${mode}" # maybe empty for now

   is_absolutepath "${SOURCETREE_CONFIG_FILENAME}" \
   && internal_fail "SOURCETREE_CONFIG_FILENAME \"${SOURCETREE_CONFIG_FILENAME}\" must be relative"

   if [ -z "${SOURCETREE_FIX_FILENAME}" ]
   then
      case "${MULLE_UNAME}" in
         windows)
            SOURCETREE_FIX_FILENAME=".mulle/var/${MULLE_HOSTNAME}.fix"
         ;;

         *)
            SOURCETREE_FIX_FILENAME="${MULLE_SOURCETREE_VAR_DIR#${MULLE_SOURCETREE_PROJECT_DIR}/}fix"
         ;;
      esac
   fi
}


sourcetree_minimal_environment()
{
   log_entry "sourcetree_minimal_environment" "$@"

   local directory="$1"
   local config_dir="$2"
   local use_fallback="$3"

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

   MULLE_HOSTNAME="${MULLE_HOSTNAME:-`hostname -s`}"
}


sourcetree_basic_environment()
{
   log_entry "sourcetree_basic_environment" "$@"

   local directory="$1"
   local config_dir="$2"
   local use_fallback="$3"
   local scope="$4"
   local mode="$5"

   sourcetree_minimal_environment "${directory}" "${config_dir}" "${use_fallback}"

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

   sourcetree_config_environment "${config_dir}" \
                                 "${use_fallback}" \
                                 "${scope}" \
                                 "${mode}"


   if [ "${MULLE_FLAG_LOG_SETTINGS}" = 'YES' ]
   then
      log_trace2 "MULLE_SOURCETREE_PROJECT_DIR:        ${MULLE_SOURCETREE_PROJECT_DIR}"
      log_trace2 "SOURCETREE_CONFIG_FILENAME:          ${SOURCETREE_CONFIG_FILENAME}"
      log_trace2 "SOURCETREE_FALLBACK_CONFIG_FILENAME: ${SOURCETREE_CONFIG_FILENAME}"
      log_trace2 "MULLE_SOURCETREE_ETC_DIR:            ${MULLE_SOURCETREE_ETC_DIR}"
      log_trace2 "MULLE_SOURCETREE_VAR_DIR:            ${MULLE_SOURCETREE_VAR_DIR}"
      log_trace2 "MULLE_SOURCETREE_SHARE_DIR:          ${MULLE_SOURCETREE_SHARE_DIR}"
   fi
}


sourcetree_environment()
{
   log_entry "sourcetree_environment" "$@"

   local option_scope="$1"
   local option_sharedir="$2"
   local option_configdir="$3"
   local option_use_fallback="$4"
   local defer="$5"
   local mode="$6"

   sourcetree_basic_environment "" \
                                "${option_configdir}" \
                                "${option_use_fallback}" \
                                "${option_scope}" \
                                "${mode}"

   if [ "${defer}" = "VIRTUAL" ]
   then
      [ -z "${MULLE_VIRTUAL_ROOT}" ] && fail "MULLE_VIRTUAL_ROOT not set"

      cd "${MULLE_VIRTUAL_ROOT}" || fail "failed to cd to \"${MULLE_VIRTUAL_ROOT}\""

      _set_sourcetree_global "${MULLE_SOURCETREE_PROJECT_DIR}"
   else
      _set_sourcetree_global "${MULLE_SOURCETREE_PROJECT_DIR}"

      #
      # Todo: the defer thing is probably old junk
      #
      if ! cfg_defer_if_needed "${defer:-NEAREST}"
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
   _set_share_dir "${option_sharedir}"
   set +x
}


_set_sourcetree_global()
{
   log_entry "_set_sourcetree_global" "$@"

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
   SOURCETREE_START="${SOURCETREE_START}/"

   #
   # our db is specific to a host
   #
   [ -z "${MULLE_SOURCETREE_PROJECT_DIR}" ] && internal_fail "MULLE_SOURCETREE_PROJECT_DIR is empty"

   # for testing let it be overrideable
   if [ -z "${SOURCETREE_DB_FILENAME}" ]
   then
      SOURCETREE_DB_FILENAME=".mulle/var/${MULLE_HOSTNAME}/sourcetree/db"
      SOURCETREE_DB_FILENAME_RELATIVE="../../../../.."
   fi
}


_set_share_dir()
{
   log_entry "_set_share_dir" "$@"

   local usershare_dir="$1"

   [ -z "${MULLE_VIRTUAL_ROOT}" ] && internal_fail "MULLE_VIRTUAL_ROOT must be defined by now"
   [ -z "${SOURCETREE_START}" ]   && internal_fail "SOURCETREE_START must be defined by now"

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
      if r_cfg_exists "${SOURCETREE_START}"
      then
         local share_dir

         if share_dir="`db_get_shareddir "${SOURCETREE_START}"`"
         then
            if [ -d "${share_dir}" ]
            then
               MULLE_SOURCETREE_STASH_DIR="`physicalpath "${share_dir}" `"
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



sourcetree_initialize()
{
   if [ -z "${MULLE_SOURCETREE_DB_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-db.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_NODEMARKS_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodemarks.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodemarks.sh"|| exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_NODE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-node.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-node.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_NODELINE_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-nodeline.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodeline.sh" || exit 1
   fi

   if [ -z "${MULLE_SOURCETREE_CFG_SH}" ]
   then
      # shellcheck source=mulle-sourcetree-cfg.sh
      . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-cfg.sh" || exit 1
   fi

   :
}

sourcetree_initialize
