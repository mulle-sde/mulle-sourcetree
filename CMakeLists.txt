cmake_minimum_required (VERSION 3.0)

project( mulle-sourcetree NONE)

#
# Primarily used for packaging on Linux
#
# Debian:
#
# ```
# mkdir package
# cd package
# cmake ..
# cpack -G DEB
# ```
#

execute_process( COMMAND ./mulle-sourcetree version
                 WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
                 OUTPUT_VARIABLE MULLE_SOURCETREE_VERSION
                 OUTPUT_STRIP_TRAILING_WHITESPACE)
message( STATUS "MULLE_SOURCETREE_VERSION is ${MULLE_SOURCETREE_VERSION} according to mulle-sourcetree")


set( PROJECT_VERSION "${MULLE_SOURCETREE_VERSION}")


set( SCRIPTS
mulle-sourcetree
mulle-sourcetree-to-c
mulle-sourcetree-to-cmake
mulle-sourcetree-graph
)


file( GLOB LIBRARY_SCRIPTS
   "src/*.sh"
)


INSTALL( FILES ${SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "bin")

#
# future: install into libexec/mulle-sourcetree/${MULLE_SOURCETREE_VERSION}
#         allows multiple versions to co-exist (does it really ?)
#
INSTALL( FILES ${LIBRARY_SCRIPTS}
PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
            GROUP_EXECUTE GROUP_READ
            WORLD_EXECUTE WORLD_READ
DESTINATION "libexec/mulle-sourcetree")


######
#
# must be after CPACK_PACKAGE_VERSION
include( CMakePackage.cmake)
include( CPack)

