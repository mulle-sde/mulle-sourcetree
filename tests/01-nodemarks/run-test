#! /usr/bin/env bash

[ "${TRACE}" = "YES" ] && set -x


main()
{
   _options_mini_main "$@"

   local marks

   nodemarks_contain_build     "${marks}" || fail "Did expect build as default"
   nodemarks_contain_recurse   "${marks}" || fail "Did expect recurse as default"
   nodemarks_contain_delete    "${marks}" || fail "Did expect delete as default"
   nodemarks_contain_require   "${marks}" || fail "Did expect require as default"
   nodemarks_contain_update    "${marks}" || fail "Did expect update as default"

   log_verbose "----- #1 PASSED -----"

   nodemarks_contain_nobuild    "${marks}" && fail "Did not expect nobuild as default"
   nodemarks_contain_nodelete   "${marks}" && fail "Did not expect nodelete as default"
   nodemarks_contain_norecurse  "${marks}" && fail "Did not expect norecurse as default"
   nodemarks_contain_norequire  "${marks}" && fail "Did not expect norequire as default"
   nodemarks_contain_noupdate   "${marks}" && fail "Did not expect noupdate as default"

   log_verbose "----- #2 PASSED -----"

   marks="`nodemarks_add_nobuild "${marks}"`"

   nodemarks_contain_nobuild    "${marks}" || fail "Did expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" && fail "Did not expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" && fail "Did not expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" && fail "Did not expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" && fail "Did not expect noupdate ($marks)"

   log_verbose "----- #3 PASSED -----"

   marks="`nodemarks_add_nodelete "${marks}"`"

   nodemarks_contain_nobuild    "${marks}" || fail "Did expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" || fail "Did expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" && fail "Did not expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" && fail "Did not expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" && fail "Did not expect noupdate ($marks)"

   log_verbose "----- #4 PASSED -----"

   marks="`nodemarks_add_norecurse "${marks}"`"

   nodemarks_contain_nobuild    "${marks}" || fail "Did expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" || fail "Did expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" || fail "Did expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" && fail "Did not expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" && fail "Did not expect noupdate ($marks)"

   log_verbose "----- #5 PASSED -----"

   marks="`nodemarks_add_norequire "${marks}"`"

   nodemarks_contain_nobuild    "${marks}" || fail "Did expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" || fail "Did expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" || fail "Did expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" || fail "Did expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" && fail "Did not expect noupdate ($marks)"

   log_verbose "----- #6 PASSED -----"

   marks="`nodemarks_add_noupdate "${marks}"`"

   nodemarks_contain_nobuild    "${marks}" || fail "Did expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" || fail "Did expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" || fail "Did expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" || fail "Did expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" || fail "Did expect noupdate ($marks)"

   log_verbose "----- #7 PASSED -----"

# remove stuff

   marks="`nodemarks_add_build "${marks}"`"

   nodemarks_contain_nobuild    "${marks}" && fail "Did not expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" || fail "Did expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" || fail "Did expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" || fail "Did expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" || fail "Did expect noupdate ($marks)"

   log_verbose "----- #8 PASSED -----"

   marks="`nodemarks_remove "${marks}" "nodelete"`"

   nodemarks_contain_nobuild    "${marks}" && fail "Did not expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" && fail "Did not expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" || fail "Did expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" || fail "Did expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" || fail "Did expect noupdate ($marks)"

   log_verbose "----- #9 PASSED -----"

   marks="`nodemarks_remove_norecurse "${marks}"`"

   nodemarks_contain_nobuild    "${marks}" && fail "Did not expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" && fail "Did not expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" && fail "Did not expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" || fail "Did expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" || fail "Did expect noupdate ($marks)"

   log_verbose "----- #10 PASSED -----"

   marks="`nodemarks_add_require "${marks}"`"

   nodemarks_contain_nobuild    "${marks}" && fail "Did not expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" && fail "Did not expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" && fail "Did not expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" && fail "Did not expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" || fail "Did expect noupdate ($marks)"

   log_verbose "----- #11 PASSED -----"

   marks="`nodemarks_add_update "${marks}"`"

   nodemarks_contain_nobuild    "${marks}" && fail "Did not expect nobuild ($marks)"
   nodemarks_contain_nodelete   "${marks}" && fail "Did not expect nodelete ($marks)"
   nodemarks_contain_norecurse  "${marks}" && fail "Did not expect norecurse ($marks)"
   nodemarks_contain_norequire  "${marks}" && fail "Did not expect norequire ($marks)"
   nodemarks_contain_noupdate   "${marks}" && fail "Did not expect noupdate ($marks)"

   log_verbose "----- #12 PASSED -----"

   local other

   marks="`nodemarks_add_noupdate "${marks}"`"
   other="`nodemarks_add_nodelete "${marks}"`"

   nodemarks_intersect "${marks}" "${other}" || fail "intersect \"${marks}\" \"${other}\""

   log_verbose "----- #13 PASSED -----"

   other="`nodemarks_add_nodelete ""`"

   nodemarks_intersect "${marks}" "${other}" && fail "! intersect \"${marks}\" \"${other}\""

   log_verbose "----- #14 PASSED -----"

   log_info "----- ALL PASSED -----"
}



init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path`" || exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1

   MULLE_SOURCETREE="${MULLE_SOURCETREE:-${PWD}/../../mulle-sourcetree}"
   MULLE_SOURCETREE_LIBEXEC_DIR="`${MULLE_SOURCETREE} library-path`" || exit 1

   . "${MULLE_SOURCETREE_LIBEXEC_DIR}/mulle-sourcetree-node.sh" || exit 1
}


init "$@"
main "$@"
