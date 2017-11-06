#! /usr/bin/env bash


run_test_1()
{
   local nodeline

   nodeline="url;dstfile;branch;tag;nodetype;uuid;marks;fetchoptions;userinfo"

   local branch
   local dstfile
   local fetchoptions
   local name
   local nodetype
   local marks
   local tag
   local url
   local userinfo

   nodeline_parse "${nodeline}"

   [ "${url}"          = "url" ]          || fail "wrong name \"${url}\""
   [ "${dstfile}"      = "dstfile" ]      || fail "wrong dstfile \"${dstfile}\""
   [ "${branch}"       = "branch" ]       || fail "wrong branch \"${branch}\""
   [ "${tag}"          = "tag" ]          || fail "wrong tag \"${tag}\""
   [ "${nodetype}"     = "nodetype" ]     || fail "wrong nodetype \"${nodetype}\""
   [ "${uuid}"         = "uuid" ]         || fail "wrong uuid \"${uuid}\""
   [ "${marks}"        = "marks" ]        || fail "wrong marks \"${marks}\""
   [ "${fetchoptions}" = "fetchoptions" ] || fail "wrong nodetype \"${fetchoptions}\""
   [ "${userinfo}"     = "userinfo" ]     || fail "wrong userinfo \"${userinfo}\""

   local printed

   printed="`node_print_nodeline "${nodeline}"`"

   [ "${nodeline}" = "${printed}" ]     || fail "printed nodeline differs \"${printed}\""
}


run_test_2()
{
   local branch
   local dstfile
   local fetchoptions
   local name
   local nodetype
   local marks
   local tag
   local url
   local userinfo

   nodeline_parse "abc;whatever;;;xyz;"

   [ "${url}"     = "abc" ]      || fail "wrong name \"${url}\""
   [ "${dstfile}" = "whatever" ] || fail "wrong dstfile \"${dstfile}\""
   [ -z "${branch}"       ]      || fail "wrong branch \"${branch}\""
   [ -z "${tag}"          ]      || fail "wrong tag \"${tag}\""
   [ "${nodetype}" = "xyz"  ]    || fail "wrong nodetype \"${nodetype}\""
   [ -z "${uuid}"         ]      || fail "wrong uuid \"${uuid}\""
   [ -z "${marks}"        ]      || fail "wrong marks \"${marks}\""
   [ -z "${fetchoptions}" ]      || fail "wrong nodetype \"${fetchoptions}\""
   [ -z "${userinfo}"     ]      || fail "wrong userinfo \"${userinfo}\""
}



main()
{
   MULLE_SOURCETREE_FLAGS="$@"

   _options_mini_main "$@"

   set -e # for tests

   run_test_1
   log_verbose "----- #1 PASSED -----"

   run_test_2
   log_verbose "----- #2 PASSED -----"

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
}


init "$@"
main "$@"

