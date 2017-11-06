#! /usr/bin/env bash

[ "${TRACE}" = "YES" ] && set -x


run_mulle_sourcetree()
{
   log_fluff "####################################"
   log_fluff ${MULLE_SOURCETREE} ${MULLE_SOURCETREE_FLAGS} "$@"
   log_fluff "####################################"

   exekutor ${MULLE_SOURCETREE} ${MULLE_SOURCETREE_FLAGS} "$@"
}

#
# repository has no .mulle-sourcetree in 1.0.0
# repository has a .mulle-sourcetree in 2.0.0
# repository has no .mulle-sourcetree in 3.0.0
#
_setup_demo_repo_a()
{
   local reporoot="$1"

   exekutor git init

   redirect_exekutor VERSION echo "1.0.0"
   run_mulle_sourcetree add "file:///${reporoot}/b"
   run_mulle_sourcetree add "file:///${reporoot}/c"
   exekutor git add VERSION .mulle-sourcetree
   exekutor git commit -m "a: inital version"
}

_setup_demo_repo_b()
{
   local reporoot="$1"

   exekutor git init

   redirect_exekutor VERSION echo "1.1.0"
   run_mulle_sourcetree add "file:///${reporoot}/c"
   exekutor git add VERSION .mulle-sourcetree
   exekutor git commit -m "b: inital version"
}


_setup_demo_repo_c()
{
   local reporoot="$1"

   exekutor git init

   redirect_exekutor VERSION echo "1.0.0"
   exekutor git add VERSION
   exekutor git commit -m "c: inital version"
}



_change_demo_repo_a()
{
   local reporoot="$1"

   run_mulle_sourcetree mark "file:///${reporoot}/b" noshare
   exekutor git commit -m "a: noshare version" .mulle-sourcetree
}


change_demo_repo_b_to_noshare()
{
   (
      exekutor cd "$1/a" && _change_demo_repo_a "$1"
   ) || exit 1
}

setup_demo_repos()
{
   (
      set -e
      mkdir_if_missing "$1/a" &&
      exekutor cd "$1/a" && _setup_demo_repo_a "$1"
      mkdir_if_missing "$1/b" &&
      exekutor cd "$1/b" && _setup_demo_repo_b "$1"
      mkdir_if_missing "$1/c" &&
      exekutor cd "$1/c" && _setup_demo_repo_c "$1"
      set +e
   ) || exit 1
}


run_test1()
{
   if ! run_mulle_sourcetree add "file://${repos}/a"
   then
      fail "add failed unexpectedly"
   fi
   if ! run_mulle_sourcetree add "file://${repos}/b"
   then
      fail "add failed unexpectedly"
   fi
   if ! run_mulle_sourcetree update --share --recursive --share-prefix shared
   then
      fail "update failed unexpectedly"
   fi

   [ -d "shared/a" ] || fail "a should exist"
   [ -d "shared/b" ] || fail "b should exist"
   [ -d "shared/c" ] || fail "c should exist"
}


run_test2()
{
   if ! run_mulle_sourcetree add "file://${repos}/a"
   then
      fail "add failed unexpectedly"
   fi
   if ! run_mulle_sourcetree update --share --share-prefix shared
   then
      fail "update failed unexpectedly"
   fi

   [ -d "shared/a" ] || fail "a should exist"
   [ -d "shared/b" ] || fail "b should exist"
   [ -d "shared/c" ] || fail "c should exist"
}



run_test3()
{
   local flags="$1"

   if ! run_mulle_sourcetree add "file://${repos}/a"
   then
      fail "add failed unexpectedly"
   fi
   if ! run_mulle_sourcetree ${flags} update --share --share-prefix shared
   then
      fail "update failed unexpectedly"
   fi

   if [ -z ${flags} ]
   then
      [ -d "shared/a" ]   || fail "a should exist"
      [ ! -d "shared/b" ] || fail "b should not exist"
      [ -d "shared/c" ]   || fail "c should exist"

      [ -d "shared/a/b" ]   || fail "a/b should exist"
      [ -d "shared/a/b/c" ] || fail "a/b/c should exist"
   fi
}



main()
{
   MULLE_SOURCETREE_FLAGS="$@"

   _options_mini_main "$@"

   local directory

   directory="`make_tmp_directory`" || exit 1

   local project

   project="${directory}/project"
   repos="${directory}/repositories"

   setup_demo_repos "${repos}"

   (
      rmdir_safer "${project}" &&
      mkdir_if_missing "${project}" &&
      cd "${project}" &&
      run_test1
   ) || exit 1
   log_verbose "----- #1 PASSED -----"

   (
      rmdir_safer "${project}" &&
      mkdir_if_missing "${project}" &&
      cd "${project}" &&
      run_test2
   ) || exit 1
   log_verbose "----- #2 PASSED -----"

   #
   #
   #
   change_demo_repo_b_to_noshare "${repos}"

   (
      rmdir_safer "${project}" &&
      mkdir_if_missing "${project}" &&
      cd "${project}" &&
      run_test3
   ) || exit 1
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

   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-node.sh" || exit 1
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-nodeline.sh" || exit 1
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-db.sh" || exit 1
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-update.sh" || exit 1
   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-zombify.sh" || exit 1
}


init "$@"
main "$@"

