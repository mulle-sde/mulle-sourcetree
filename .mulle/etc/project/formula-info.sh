# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="mulle-sourcetree"      # your project/repository uuid
DESC="🌲 Project composition and maintenance with build support"
LANGUAGE="bash"                # c,cpp, objc, bash ...
# NAME="${PROJECT}"        # formula filename without .rb extension

DEPENDENCIES='${MULLE_SDE_TAP}mulle-fetch'

#
# bsdmainutils are for "column"
#
DEBIAN_DEPENDENCIES="mulle-fetch"
DEBIAN_RECOMMENDATIONS="bsdmainutils"
