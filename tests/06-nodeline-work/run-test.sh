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


_setup_demo_repo_a()
{
   local reporoot="$1"

   exekutor git init

   exekutor git checkout -b release

   redirect_exekutor VERSION echo "1.0.0"
   exekutor git add VERSION
   exekutor git commit -m "a: 1.0.0"
   exekutor git tag "1.0.0"

   redirect_exekutor VERSION echo "2.0.0"
   exekutor git commit -m "a: 2.0.0" VERSION
   exekutor git tag "2.0.0"

   exekutor git branch -d master
}


setup_demo_repos()
{
   (
      set -e
      mkdir_if_missing "$1/a" &&
      exekutor cd "$1/a" && _setup_demo_repo_a "$1"
      set +e
   )
}



run_test()
{
   local uuidgen

   SOURCETREE_UPDATE_CACHE=whatever

   uuid="`uuidgen`"
   (
      update_with_nodeline "normal" "" "${repos}/a;ringo/starr;release;;git;${uuid}"
   ) || fail "failed unexpectedly"

   [ -f "ringo/starr/VERSION" ] || fail "ringo/starr/VERSION not there"
   log_verbose "----- #1 PASSED -----"

   (
      update_with_nodeline "normal" "" "${repos}/a;ringo/star;release;;git;${uuid}"
   ) || fail "failed unexpectedly"

   [ ! -f "ringo/starr/VERSION" ] || fail "ringo/starr/VERSION not gone"
   [ -f "ringo/star/VERSION" ]    || fail "ringo/star/VERSION not there"
   log_verbose "----- #2 PASSED -----"

   (
      update_with_nodeline "normal" "" "${repos}/a;ringo/star;unknown;;git;${uuid}"
   ) && fail "worked unexpectedly"

   [ -f "ringo/star/VERSION" ]    && fail "branch unknown should have wiped ringo/star/VERSION"
   log_verbose "----- #3 PASSED -----"

   (
      update_with_nodeline "normal" "" "${repos}/a;ringo/starr;release;2.0.0;git;${uuid}"
   ) || fail "failed unexpectedly"

   [ `cat ringo/starr/VERSION` = 2.0.0 ] || fail "Wrong checkout"

   log_verbose "----- #4 PASSED -----"

   (
      update_with_nodeline "normal" "" "${repos}/a;ringo/starr;release;1.0.0;git;${uuid}"
   ) || fail "failed unexpectedly"

   [ `cat ringo/starr/VERSION` = 1.0.0 ] || fail "Wrong checkout"

   log_verbose "----- #5 PASSED -----"
}



main()
{
   MULLE_SOURCETREE_FLAGS="$@"

   _options_mini_main "$@"

   local directory

   directory="`make_tmp_directory`" || exit 1

   local project
   local repos

   project="${directory}/project"
   repos="${directory}/repositories"

   setup_demo_repos "${repos}"

   mkdir_if_missing "${project}"

   (
      SOURCETREE_DB_DIR="${project}/db"

      cd "${project}" &&
      run_test
   ) || exit 1

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

