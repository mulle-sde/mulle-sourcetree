#! /usr/bin/env bash

expect()
{
   local output="$1"
   local expected="$2"

   if [ "${output}" != "${expected}" ]
   then
      exekutor fail "Did expect \"${expected}\" but got \"${output}\""
   fi
}


main()
{
   MULLE_SOURCETREE_FLAGS="$@"

   _options_mini_main "$@"

   set -e

   directory="`make_tmp_directory`" || exit 1

   SOURCETREE_DB_DIR="${directory}"

   local nodeline
   local sourcenodeline

   db_remember 1 "text"
   nodeline="`db_get_nodeline_for_uuid 1`"
   expect "${nodeline}" "text"
   log_verbose "----- #1 PASSED -----"

   db_remember 2 "other"
   nodeline="`db_get_nodeline_for_uuid 1`"
   expect "${nodeline}" "text"
   nodeline="`db_get_nodeline_for_uuid 2`"
   expect "${nodeline}" "other"
   log_verbose "----- #2 PASSED -----"

   nodeline="`db_get_nodeline_for_uuid 3`"
   expect "${nodeline}" ""

   log_verbose "----- #3 PASSED -----"

   log_info "----- ALL PASSED -----"

   rmdir_safer "${directory}"
}


init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path`" || exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1

   MULLE_SOURCETREE="${MULLE_SOURCETREE:-${PWD}/../../mulle-sourcetree}"
   MULLE_SOURCETREE_LIBEXEC_DIR="`${MULLE_SOURCETREE} library-path`" || exit 1

   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh" || exit 1
}


init "$@"
main "$@"

