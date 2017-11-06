#! /usr/bin/env bash

expect_actions()
{
   local actions="$1"
   local expected="$2"

   actions="$(sort <<< "${actions}")"

   expected="$(tr ',' '\012' <<< "${expected}")"
   expected="$(sort <<< "${expected}")"

   if [ "${actions}" != "${expected}" ]
   then
      log_error "Unexpected output generated"
      cat <<EOF >&2
----------------
Output:
----------------
${actions}
----------------
Expected:
----------------
${expected}
----------------
EOF
      exit 1
   fi
}



run_git_tests()
{
   local uuidgen
   local old
   local new

   uuid="`node_uuidgen`"

   old="https://github.com/mulle-nat/mulle-c11.git;ringo/starr;release;;git;${uuid}"

   # into empty is simple
   new="https://github.com/mulle-nat/mulle-c11.git;paul/jones;release;;git;${uuid}"
   actions="`update_actions_for_nodelines "normal" "" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "fetch"
   log_verbose "----- #1 PASSED -----"

   # uuid change is bug
   new="https://github.com/mulle-nat/mulle-c11.git;ringo/starr;release;;git;`node_uuidgen`"
   ( update_actions_for_nodelines "${old}" "${new}" ) 2> /dev/null && fail "did not fail unexpectedly"
   log_verbose "----- #2 PASSED -----"

   mkdir_if_missing "ringo"
   exekutor touch "ringo/starr"

   # url change for git is supported
   new="https://github.com/mulle-objc/mulle-c11.git;ringo/starr;release;;git;${uuid}"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "set-url,upgrade"

   log_verbose "----- #3 PASSED -----"

   # branch change for git is supported
   new="https://github.com/mulle-nat/mulle-c11.git;ringo/starr;master;;git;${uuid}"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "checkout"

   log_verbose "----- #4 PASSED -----"

   # tag change needs a checkout
   new="https://github.com/mulle-nat/mulle-c11.git;ringo/starr;release;frobozz;git;${uuid}"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "checkout"

   log_verbose "----- #5 PASSED -----"

   # let it move the dstination around
   new="https://github.com/mulle-nat/mulle-c11.git;paul/jones;release;;git;${uuid}"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "move"

   log_verbose "----- #6 PASSED -----"

   # let it do nothing if we moved
   mkdir_if_missing "paul"
   exekutor touch "paul/jones"
   rmdir_safer "ringo"

   new="https://github.com/mulle-nat/mulle-c11.git;paul/jones;release;;git;${uuid}"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "remember"

   log_verbose "----- #7 PASSED -----"


   old="https://github.com/mulle-nat/mulle-c11.git;paul/jones;release;;git;${uuid}"

   # lets change url and dst at the same time
   new="https://github.com/mulle-objc/mulle-c11.git;tom/petty;release;;git;${uuid}"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "move,upgrade,set-url"

   log_verbose "----- #8 PASSED -----"

   # change of nodetype is heavy url and dst at the same time
   new="https://github.com/mulle-nat/mulle-c11.git;paul/jones;release;;svn;${uuid}"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "fetch,remove"

   log_verbose "----- #9 PASSED -----"

   # change in marks,fetchoptions,userinfo = don't care
   new="https://github.com/mulle-nat/mulle-c11.git;paul/jones;release;;git;${uuid};nobuild;fetch=whatever;userinfo"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" ""

   log_verbose "----- #10 PASSED -----"
}



run_tar_tests()
{
   local uuidgen
   local old
   local new

   uuid="`node_uuidgen`"

   # into empty is simple
   new="https://github.com/mulle-nat/mulle-c11/archive/1.2.5.tar.gz;ringo/starr;;;tar;${uuid}"
   actions="`update_actions_for_nodelines "normal" "" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "fetch"
   log_verbose "----- #11 PASSED -----"

   old="https://github.com/mulle-nat/mulle-c11/archive/1.2.5.tar.gz;ringo/starr;;;tar;${uuid}"

   mkdir_if_missing "ringo"
   exekutor touch "ringo/starr"

   # url change means refetch
   new="https://github.com/mulle-objc/mulle-c11.git;ringo/starr;release;;tar;${uuid}"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "fetch,remove"

   log_verbose "----- #12 PASSED -----"

   # let it move the dstination around
   new="https://github.com/mulle-nat/mulle-c11/archive/1.2.5.tar.gz;paul/jones;;;tar;${uuid}"
   actions="`update_actions_for_nodelines "normal" "${old}" "${new}"`" || fail "failed unexpectedly"
   expect_actions "${actions}" "move"

   log_verbose "----- #13 PASSED -----"
}


main()
{
   MULLE_SOURCETREE_FLAGS="$@"

   _options_mini_main "$@"

   local directory

   set -e

   directory="`make_tmp_directory`" || exit 1
   (
      cd "${directory}" &&
      run_git_tests
   ) || exit 1
   rmdir_safer "${directory}"

   directory="`make_tmp_directory`" || exit 1
   (
      cd "${directory}" &&
      run_tar_tests
   ) || exit 1
   rmdir_safer "${directory}"

   log_info "----- ALL PASSED -----"

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

