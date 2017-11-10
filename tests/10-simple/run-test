#! /usr/bin/env bash

[ "${TRACE}" = "YES" ] && set -x


run_mulle_sourcetree()
{
   log_fluff "####################################"
   log_fluff ${MULLE_SOURCETREE} ${MULLE_SOURCETREE_FLAGS} "$@"
   log_fluff "####################################"

   exekutor ${MULLE_SOURCETREE} ${MULLE_SOURCETREE_FLAGS} "$@"
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


test_bad_paths()
{
   if run_mulle_sourcetree add "${repos}/a" "/tmp/foo"
   then
      fail "failed to complain about absolute path"
   fi
   [ -e ".mulle-sourcetree" ]    && fail "a: .mulle-sourcetree should not exist"
   [ -e ".mulle-sourcetree.db" ] && fail "a: .mulle-sourcetree.db should not exist"

   if run_mulle_sourcetree add "${repos}/a" "../foo"
   then
      fail "failed to complain about escape path"
   fi
   [ -e ".mulle-sourcetree" ]    && fail "b: .mulle-sourcetree should not exist"
   [ -e ".mulle-sourcetree.db" ] && fail "b: .mulle-sourcetree.db should not exist"

   if run_mulle_sourcetree add "${repos}/a" "a/../.."
   then
      fail "failed to complain about escape path"
   fi
   [ -e ".mulle-sourcetree" ]    && fail "c: .mulle-sourcetree should not exist"
   [ -e ".mulle-sourcetree.db" ] && fail "c: .mulle-sourcetree.db should not exist"

   if run_mulle_sourcetree add "${repos}/a" "~foo"
   then
      fail "failed to complain about absolute path"
   fi
   [ -e ".mulle-sourcetree" ]    && fail "d: .mulle-sourcetree should not exist"
   [ -e ".mulle-sourcetree.db" ] && fail "d: .mulle-sourcetree.db should not exist"

   if run_mulle_sourcetree add "${repos}/a" "~/foo"
   then
      fail "failed to complain about absolute path"
   fi
   [ -e ".mulle-sourcetree" ]    && fail "e: .mulle-sourcetree should not exist"
   [ -e ".mulle-sourcetree.db" ] && fail "e: .mulle-sourcetree.db should not exist"

   :
}


test_simple_add_remove()
{
   if ! run_mulle_sourcetree add --branch release "${repos}/a" "foo"
   then
      fail "failed unexpectedly"
   fi
   [ -f ".mulle-sourcetree" ]    || fail "a: .mulle-sourcetree should exist now"
   [ -e ".mulle-sourcetree.db" ] && fail "a: .mulle-sourcetree.db should not exist"

   # same url should not work
   if run_mulle_sourcetree add "${repos}/a" "foo"
   then
      fail "succeeded unexpectedly"
   fi
   [ -f ".mulle-sourcetree" ]    || fail "a: .mulle-sourcetree should exist now"
   [ -e ".mulle-sourcetree.db" ] && fail "a: .mulle-sourcetree.db should not exist"

   if ! run_mulle_sourcetree remove "${repos}/a"
   then
      fail "failed unexpectedly"
   fi
   [ -e ".mulle-sourcetree" ]    && fail "b: .mulle-sourcetree should not exist anymore"
   [ -e ".mulle-sourcetree.db" ] && fail "b: .mulle-sourcetree.db should not exist"

   :
}


test_update1()
{
   [ -e ".mulle-sourcetree" ]    && fail "a: .mulle-sourcetree should not exist anymore"
   [ -e ".mulle-sourcetree.db" ] && fail "a: .mulle-sourcetree.db should not exist"
   [ -e "foo" ]                  && fail "a: foo should not exist"

   if ! run_mulle_sourcetree add --branch release "${repos}/a" "foo"
   then
      fail "add failed unexpectedly"
   fi

   [ -e ".mulle-sourcetree" ]    || fail "b: .mulle-sourcetree should now exist"
   [ -e ".mulle-sourcetree.db" ] && fail "b: .mulle-sourcetree.db should not exist"
   [ -e "foo" ]                  && fail "b: foo should not exist"

   if ! run_mulle_sourcetree update
   then
      fail "update failed unexpectedly"
   fi

   [ -e ".mulle-sourcetree" ]    || fail "c: .mulle-sourcetree should exist"
   [ -e ".mulle-sourcetree.db" ] || fail "c: .mulle-sourcetree.db should exist"
   [ -f "foo/VERSION" ]  || fail "c: foo/VERSION should exist"

   if ! run_mulle_sourcetree remove "${repos}/a"
   then
      fail "remove failed unexpectedly"
   fi

   [ -e ".mulle-sourcetree" ]    && fail "d: .mulle-sourcetree should not exist anymore"
   [ -e ".mulle-sourcetree.db" ] || fail "d: .mulle-sourcetree.db should exist"
   [ -f "foo/VERSION" ]  || fail "d: foo/VERSION should exist"

   if ! run_mulle_sourcetree update
   then
      fail "update failed unexpectedly"
   fi

   [ -e ".mulle-sourcetree" ]               && fail "e: .mulle-sourcetree should not exist anymore"
   [ -e "foo" ]                             && fail "e: foo should not exist"
   [ -e ".mulle-sourcetree.db" ]            || fail "e: .mulle-sourcetree.db should exist"
   [ -e ".mulle-sourcetree.db/.graveyard" ] || fail "e: .mulle-sourcetree.db/.graveyard should exist"

   :
}


test_update2()
{
   rm -rf foo 2> /dev/null
   rm -rf .mulle-sourcetree.db 2> /dev/null
   rm -f .mulle-sourcetree 2> /dev/null

   [ -e ".mulle-sourcetree" ]    && fail "a: .mulle-sourcetree should not exist anymore"
   [ -e ".mulle-sourcetree.db" ] && fail "a: .mulle-sourcetree.db should not exist"
   [ -e "foo" ]                  && fail "a: foo should not exist"

   if ! run_mulle_sourcetree add --branch release "${repos}/a" "foo"
   then
      fail "add failed unexpectedly"
   fi

   [ -e ".mulle-sourcetree" ]    || fail "b: .mulle-sourcetree should now exist"
   [ -e ".mulle-sourcetree.db" ] && fail "b: .mulle-sourcetree.db should not exist"
   [ -e "foo" ]                  && fail "b: foo should not exist"

   if ! run_mulle_sourcetree update
   then
      fail "update failed unexpectedly"
   fi

   [ -e ".mulle-sourcetree" ]    || fail "c: .mulle-sourcetree should exist"
   [ -e ".mulle-sourcetree.db" ] || fail "c: .mulle-sourcetree.db should exist"
   [ -f "foo/VERSION" ]  || fail "c: foo/VERSION should exist"

   if ! run_mulle_sourcetree set --destination "bar" "${repos}/a"
   then
      fail "remove failed unexpectedly"
   fi

   [ -e ".mulle-sourcetree" ]    || fail "d: .mulle-sourcetree should exist"
   [ -e ".mulle-sourcetree.db" ] || fail "d: .mulle-sourcetree.db should exist"
   [ -f "foo/VERSION" ]  || fail "d: foo/VERSION should exist"
   [ -f "bar/VERSION" ]  && fail "d: bar/VERSION should not exist"

   if ! run_mulle_sourcetree update
   then
      fail "update failed unexpectedly"
   fi

   [ -e ".mulle-sourcetree" ]    || fail "e: .mulle-sourcetree should exist"
   [ -e ".mulle-sourcetree.db" ] || fail "e: .mulle-sourcetree.db should exist"
   [ -f "foo/VERSION" ]  && fail "e: foo/VERSION should exist"
   [ -f "bar/VERSION" ]  || fail "e: bar/VERSION should exist"

   :
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
      cd "${project}"

      test_bad_paths &&
      log_verbose "----- #1 PASSED -----"
   ) || exit 1

   (
      cd "${project}"

      test_simple_add_remove &&
      log_verbose "----- #2 PASSED -----"
   ) || exit 1

   (
      cd "${project}"

      test_update1 &&
      log_verbose "----- #3 PASSED -----"
   ) || exit 1

   (
      cd "${project}"

      test_update2 &&
      log_verbose "----- #4 PASSED -----"
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

