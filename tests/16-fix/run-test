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
   run_mulle_sourcetree add "file:///${reporoot}/d" "c/d"
   exekutor git add VERSION .mulle-sourcetree
   exekutor git commit -m "a: inital version"
}

_setup_demo_repo_b()
{
   local reporoot="$1"

   exekutor git init

   redirect_exekutor VERSION echo "1.1.0"
   run_mulle_sourcetree add "file:///${reporoot}/d"
   exekutor git add VERSION .mulle-sourcetree
   exekutor git commit -m "b: inital version"
}


_setup_demo_repo_d()
{
   local reporoot="$1"

   exekutor git init

   redirect_exekutor VERSION echo "1.0.0"
   exekutor git add VERSION
   exekutor git commit -m "d: inital version"
}


setup_demo_repos()
{
   (
      set -e
      mkdir_if_missing "$1/a" &&
      exekutor cd "$1/a" && _setup_demo_repo_a "$1"
      mkdir_if_missing "$1/b" &&
      exekutor cd "$1/b" && _setup_demo_repo_b "$1"
      mkdir_if_missing "$1/d" &&
      exekutor cd "$1/d" && _setup_demo_repo_d "$1"
      set +e
   ) || exit 1
}


run_test1()
{
   local repos="$1"

   if ! run_mulle_sourcetree add "file://${repos}/a" "root/a"
   then
      fail "add failed unexpectedly"
   fi

   if run_mulle_sourcetree fix
   then
      fail "fix worked unexpectedly"
   fi

   if ! run_mulle_sourcetree update --recursive # > /dev/null 2>&1
   then
      fail "update failed unexpectedly"
   fi

   # now move directory b away

   mv root/a/b root/

   local result
   local expected

   if ! result="`run_mulle_sourcetree fix`"
   then
      fail "fix failed unexpectedly"
   fi

   expected="mulle-sourcetree set url root/b"
   case "${result}" in
      *set*root/b*)
      ;;

      *)
         fail "got \"${result}\""
      ;;
   esac

   mkdir -p foo/x
   mv root/b foo/x/

   if ! result="`run_mulle_sourcetree fix`"
   then
      fail "fix failed unexpectedly"
   fi

   case "${result}" in
      *set*foo/x*)
      ;;

      *)
         fail "got \"${result}\""
      ;;
   esac

   rm -rf foo/x/

   if ! result="`run_mulle_sourcetree fix`"
   then
      fail "fix failed unexpectedly"
   fi

   case "${result}" in
      *remove*/b\'*)
      ;;

      *)
         fail "got \"${result}\""
      ;;
   esac
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
      run_test1 "${repos}"
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

