#! /usr/bin/env bash

[ "${TRACE}" = "YES" ] && set -x


run_mulle_sourcetree()
{
   log_fluff "####################################"
   log_fluff ${MULLE_SOURCETREE} ${MULLE_SOURCETREE_FLAGS} "$@"
   log_fluff "####################################"

   exekutor ${MULLE_SOURCETREE} ${MULLE_SOURCETREE_FLAGS} "$@"
}


_setup_demo_archive_a()
{
   local archives="$1"

   redirect_exekutor VERSION echo "1.0.0"
   run_mulle_sourcetree add "file:///${archives}/b.tar.gz"
   run_mulle_sourcetree add "file:///${archives}/d.tar.gz" "c/d"

   ( cd .. ; tar cfz "${archives}/a.tar.gz" a)
}


_setup_demo_archive_b()
{
   local archives="$1"

   redirect_exekutor VERSION echo "1.1.0"
   run_mulle_sourcetree add "file:///${archives}/d.tar.gz"

   ( cd .. ; tar cfz "${archives}/b.tar.gz" b)
}


_setup_demo_archive_d()
{
   local archives="$1"

   redirect_exekutor VERSION echo "1.0.0"

   ( cd .. ; tar cfz "${archives}/d.tar.gz" d)
}

_setup_demo_archive_e()
{
   local archives="$1"

   redirect_exekutor VERSION echo "1.0.0"

   ( cd .. ; tar cfz "${archives}/e.tar.gz" e)
}




setup_demo_archives()
{
   (
      set -e
      mkdir_if_missing "$1/a" &&
      exekutor cd "$1/a" && _setup_demo_archive_a "$1"
      mkdir_if_missing "$1/b" &&
      exekutor cd "$1/b" && _setup_demo_archive_b "$1"
      mkdir_if_missing "$1/d" &&
      exekutor cd "$1/d" && _setup_demo_archive_d "$1"
      mkdir_if_missing "$1/e" &&
      exekutor cd "$1/e" && _setup_demo_archive_e "$1"
      set +e
   ) || exit 1
}


run_test1()
{
   local archives="$1"

   if ! run_mulle_sourcetree add -s tar "file://${archives}/a.tar.gz" "root/a"
   then
      fail "add failed unexpectedly"
   fi

   local result
   local expected

   result="`run_mulle_sourcetree status --recursive --output-raw --no-output-header`"
   if [ $? -ne 0 ] # > /dev/null 2>&1
   then
      fail "status failed unexpectedly"
   fi

   expected=".;update
root/a;update"

   if [ "${result}" != "${expected}" ]
   then
      fail "status produced \"${result}\", expected \"${expected}\""
   fi

   if run_mulle_sourcetree status --is-uptodate
   then
      fail "--is-uptodate #1 says OK unexpectedly"
   fi

   if ! run_mulle_sourcetree update --recursive
   then
      fail "update #1 failed unexpectedly"
   fi

   if ! run_mulle_sourcetree status --is-uptodate
   then
      fail "--is-uptodate #2 says not ok unexpectedly"
   fi

   (
      cd "root/a/b" &&
      if ! run_mulle_sourcetree add "file://${archives}/e.tar.gz" "src/e"
      then
         fail "add failed unexpectedly"
      fi
   ) || exit 1

   if run_mulle_sourcetree status --is-uptodate
   then
      fail "--is-uptodate #3 says ok unexpectedly"
   fi

   if ! run_mulle_sourcetree update --recursive
   then
      fail "update #2 failed unexpectedly"
   fi

   if ! run_mulle_sourcetree status --is-uptodate
   then
      fail "--is-uptodate #4 says not ok unexpectedly"
   fi
}



main()
{
   MULLE_SOURCETREE_FLAGS="$@"

   _options_mini_main "$@"

   local directory

   directory="`make_tmp_directory`" || exit 1

   local project
   local archives

   project="${directory}/project"
   archives="${directory}/archives"

   setup_demo_archives "${archives}" > /dev/null 2>&1 || exit 1

   (
      rmdir_safer "${project}" &&
      mkdir_if_missing "${project}" &&
      cd "${project}" &&
      run_test1 "${archives}"
   ) || exit 1
   log_verbose "----- #1 PASSED -----"

   log_info "----- ALL PASSED -----"

   rmdir_safer "${directory}"
}


init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path`" || exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1

   MULLE_SOURCETREE="${MULLE_SOURCETREE:-${PWD}/../../mulle-sourcetree}"
   MULLE_SOURCETREE_LIBEXEC_DIR="`${MULLE_SOURCETREE} library-path`" || exit 1

   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-node.sh" || exit 1
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodeline.sh" || exit 1
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh" || exit 1
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-walk.sh" || exit 1
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-dotdump.sh" || exit 1
}


init "$@"
main "$@"

