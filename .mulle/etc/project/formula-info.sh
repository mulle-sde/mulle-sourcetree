# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="mulle-sourcetree"      # your project/repository uuid
DESC="🌲 Project composition and maintenance with build support"
LANGUAGE="bash"                # c,cpp, objc, bash ...
# NAME="${PROJECT}"        # formula filename without .rb extension

DEPENDENCIES='${MULLE_SDE_TAP}mulle-fetch
${MULLE_SDE_TAP}mulle-domain
${MULLE_SDE_TAP}mulle-semver'

#
# bsdmainutils are for "column"
#
DEBIAN_DEPENDENCIES="mulle-fetch, mulle-domain, mulle-semver"
DEBIAN_RECOMMENDATIONS="bsdmainutils"
