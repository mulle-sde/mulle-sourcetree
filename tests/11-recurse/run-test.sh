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
   exekutor git add VERSION
   exekutor git commit -m "a: inital version 1.0.0 (tagged)"
   exekutor git tag "1.0.0"

   redirect_exekutor VERSION echo "2.0.0"
   run_mulle_sourcetree add "file:///${reporoot}/b"
   exekutor git add VERSION .mulle-sourcetree
   exekutor git commit -m "a: version 2.0.0 (tagged)"
   exekutor git tag "2.0.0"
}


_setup_demo_repo_b()
{
   local reporoot="$1"

   exekutor git init

   redirect_exekutor VERSION echo "1.0.0"
   exekutor git add VERSION
   exekutor git commit -m "b: inital version"
}


setup_demo_repos()
{
   (
      set -e
      mkdir_if_missing "$1/a" &&
      exekutor cd "$1/a" && _setup_demo_repo_a "$1"
      mkdir_if_missing "$1/b" &&
      exekutor cd "$1/b" && _setup_demo_repo_b "$1"
      set +e
   )
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

   mkdir_if_missing "${project}"

   local number=1

   (
      cd "${project}"

      local a

      for a in 1.0.0 2.0.0 1.0.0
      do
         if ! run_mulle_sourcetree add --tag "${a}" "file://${repos}/a"
         then
           fail "add failed unexpectedly"
         fi

         if ! run_mulle_sourcetree update --recursive
         then
            fail "update failed unexpectedly"
         fi

         case "${a}" in
            1.0.0)
               [ -d "a" ]   || fail "a should exist"
               [ -d "a/b" ] && fail "b should not exist"
            ;;

            2.0.0)
               [ -d "a" ]   || fail "a should exist"
               [ -d "a/b" ] || fail "b should exist"
            ;;
         esac

         run_mulle_sourcetree remove "file://${repos}/a"

         log_info "----- #${number} PASSED -----"
         number="$(expr $number + 1)"
      done
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
