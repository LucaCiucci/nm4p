#[[ BRUCIU_NOTICE_BEGIN
BRUCIU_NOTICE_END ]]

################################################################
#                            INFO
################################################################
#[[

Top level CMake project, see README.md for info

]]

################################################################
#                    basic configurations
################################################################

cmake_minimum_required (VERSION 3.20)

################################################################
#                          PROJECT
################################################################
# main project definition

project("NumMethodsForPhysics" VERSION 0.0
    DESCRIPTION "..."
    LANGUAGES CXX
)

# add_subdirectory("cmake")

################################
#         SUBPROJECTS
################################

# TODO TMP!!!!!!
#find_package(cereal REQUIRED)

add_subdirectory("nm4pLib")
add_subdirectory("course_modules")

