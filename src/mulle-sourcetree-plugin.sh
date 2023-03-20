# shellcheck shell=bash
#
#   Copyright (c) 2023 Nat! - Mulle kybernetiK
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
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
MULLE_SOURCETREE_PLUGIN_SH='included'


#
# the main problem is brew, as brew symlinks to the folder
# but we need to get the source of the symlinks folder
#
sourcetree::plugin::r_installdir()
{
#   log_entry "env::plugin::r_installdir"

   local dev="${1:-NO}"

   # dev support
   if [ "${dev}" = 'YES' ]
   then
      case "${MULLE_SOURCETREE_LIBEXEC_DIR}" in
         */src)
            RVAL="/tmp/share/mulle-sourcetree/plugins"
            return
         ;;
      esac
   fi

   r_resolve_symlinks "${MULLE_EXECUTABLE}"
   r_simplified_path "${RVAL}/../../share/mulle-sourcetree/plugins"
#   log_debug "plugin install directory: ${RVAL}"
}


sourcetree::plugin::r_searchpath()
{
   log_entry "sourcetree::plugin::r_searchpath"

   if [ ${_MULLE_SOURCETREE_PLUGIN_PATH+x} ]
   then
      RVAL="${_MULLE_SOURCETREE_PLUGIN_PATH}"
      return
   fi

   local searchpath

   searchpath="${MULLE_SOURCETREE_PLUGIN_PATH:-}"

   #
   # add wherever we are that share directory
   # i.e.  /usr/libexec/mulle-env -> /usr/share/mulle-env
   #
   sourcetree::plugin::r_installdir
   r_colon_concat "${searchpath}" "${RVAL}"
   searchpath="${RVAL}"

#   r_colon_concat "${searchpath}" "${MULLE_SDE_EXTENSION_BASE_PATH:-}"
#   searchpath="${RVAL}"

   r_colon_concat "${searchpath}" "/usr/local/share/mulle-sourcetree/plugins"
   searchpath="${RVAL}"

   r_colon_concat "${searchpath}" "/usr/share/mulle-sourcetree/plugins"
   searchpath="${RVAL}"

   # builtin plugins last
   r_simplified_path "${MULLE_SOURCETREE_LIBEXEC_DIR}/plugins"
   r_colon_concat "${searchpath}" "${RVAL}"
   searchpath="${RVAL}"

   log_debug "plugin searchpath: ${searchpath}"
   RVAL="${searchpath}"
}


sourcetree::plugin::load()
{
   local filename="$1"

   local name

   r_extensionless_basename "${filename}"
   name="${RVAL}"

   if shell_is_function "sourcetree::plugin::${name}::is_sourcetree_plugin"
   then
      log_debug "Plugin \"${name}\" already loaded"
      return 0
   fi

   if [ ! -f "${filename}" ]
   then
      log_warning "No sourcetree plugin \"${name}\" found"
      return 1
   fi

   . "${filename}" || fail "failed to load plugin \"${filename}\""

   log_debug "Sourcetree plugin \"${name}\" loaded"

   return 0
}


sourcetree::plugin::r_load_plugins()
{
   log_entry "sourcetree::plugin::r_load_plugins" "$@"

   local names="$1"

   local name
   local result 

   result=
   .foreachpath name in ${names}
   .do
      if ! sourcetree::plugin::load "${name}"
      then
         .continue
      fi
      r_add_line "${result}" "${name}"
      result="${RVAL}"
   .done

   RVAL="${result}"
}


sourcetree::plugin::r_all_plugin_filenames()
{
   local paths

   sourcetree::plugin::r_searchpath
   paths="${RVAL}"

   local path
   local result
   local files

   .foreachpath path in ${paths}
   .do
      files="`dir_list_files "${path}" "*.sh" 2> /dev/null`"

      log_debug "$path: ${files}"

      r_add_line "${result}" "${files}"
      result="${RVAL}"
   .done

   RVAL="${result}"
}


sourcetree::plugin::load_all()
{
   log_entry "sourcetree::plugin::load_all" "$@"

   local filename
   local filenames

   sourcetree::plugin::r_all_plugin_filenames
   filenames="${RVAL}"

   .foreachline filename in ${filenames}
   .do
      if ! sourcetree::plugin::load "${filename}"
      then
         .continue
      fi
   .done
}


sourcetree::plugin::main()
{
   log_entry "sourcetree::plugin::main"

   log_fluff "Listing sourcetree plugins..."

   local filename
   local pluginname
   local filenames
   local found

   sourcetree::plugin::r_all_plugin_filenames
   filenames="${RVAL}"

   .foreachline filename in ${filenames}
   .do
      r_extensionless_basename "${filename}"
      pluginname="${RVAL}"

      printf "%s\n" "${pluginname}"
      found='YES'
   .done

   if [ "${found}" != 'YES' ]
   then
      log_info "No plugins found"
   fi
}

:
