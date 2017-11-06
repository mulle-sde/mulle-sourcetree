#! /bin/sh

[ "${TRACE}" = "YES" ] && set -x


TEST_DIR="`dirname "$0"`"
PROJECT_DIR="$( cd "${TEST_DIR}/.." ; pwd -P)"

PATH="${PROJECT_DIR}:$PATH"
export PATH


main()
{
   _options_mini_main "$@"

   MULLE_SOURCETREE="`which mulle-sourcetree`" || exit 1

   local i

   log_verbose "mulle-sourcetree: `mulle-sourcetree version` (`mulle-sourcetree library-path`)"

   OUTPUT_DEVICE=
   for i in "${TEST_DIR}"/*
   do
      if [ -x "$i/run-test.sh" ]
      then
         case "$i" in
            *.darwin)
               if [ "${UNAME}" != darwin ]
               then
                  continue
               fi
            ;;
         esac

         log_verbose "------------------------------------------"
         log_info    "$i:"
         log_verbose "------------------------------------------"
         if [ "${MULLE_FLAG_LOG_TERSE}" = "YES" ]
         then
            ( cd "$i" && ./run-test.sh "$@" > /dev/null 2>&1 ) || fail "Test \"$i\" failed"
         else
            ( cd "$i" && ./run-test.sh "$@" ) || fail "Test \"$i\" failed"
         fi
      fi
   done
}


init()
{
   MULLE_BASHFUNCTIONS_LIBEXEC_DIR="`mulle-bashfunctions-env library-path`" || exit 1

   . "${MULLE_BASHFUNCTIONS_LIBEXEC_DIR}/mulle-bashfunctions.sh" || exit 1
}


init "$@"
main "$@"

