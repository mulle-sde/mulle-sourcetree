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
   run_mulle_sourcetree mark "file:///${reporoot}/b" "nobuild"
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

   if ! run_mulle_sourcetree update --recursive
   then
      fail "update failed unexpectedly"
   fi

   local results
   local expected

   expected="a
a/b
a/b/c
a/c"

   results="`run_mulle_sourcetree walk --walk-db "echo" '${MULLE_DSTFILE}'`"
   if [ $? -ne 0 ]
   then
      fail "db walk #1 failed unexpectedly"
   fi

   #
   # order is random pretty much due to uuids
   #
   results="$(sort <<< "${results}")"
   if [ "${results}" != "${expected}" ]
   then
      fail "db walk #1 returned \"${results}\". Expected was \"${expected}\""
   fi

   results="`run_mulle_sourcetree walk --walk-config "echo" '${MULLE_DSTFILE}'`"
   if [ $? -ne 0 ]
   then
      fail "config walk #1 failed unexpectedly"
   fi

   #
   # depth first is consistent
   #
   expected="a
a/b
a/b/c
a/c"

   if [ "${results}" != "${expected}" ]
   then
      fail "config walk #1 returned \"${results}\". Expected was \"${expected}\""
   fi

   #
   # example how to get the repositories in build order
   #
   results="`run_mulle_sourcetree walk --depth-first \
                                       --marks build \
                                       --walk-config \
                                       "echo" '${MULLE_DSTFILE}'`"
   if [ $? -ne 0 ]
   then
      fail "config walk #2 failed unexpectedly"
   fi

   expected="a/c
a"

   if [ "${results}" != "${expected}" ]
   then
      fail "config walk #2 returned \"${results}\". Expected was \"${expected}\""
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

   setup_demo_repos "${repos}" > /dev/null 2>&1 || exit 1

   (
      rmdir_safer "${project}" &&
      mkdir_if_missing "${project}" &&
      cd "${project}" &&
      run_test1
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
}


init "$@"
main "$@"
