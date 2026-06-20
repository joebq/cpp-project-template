include(FetchContent)

FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG v3.11.0
    GIT_SHALLOW TRUE
    SYSTEM
)

# Prevent cppcheck from running on Catch2's sources. Its files live inside
# CMAKE_BINARY_DIR/_deps, which is already in the cppcheck ignore list, so
# cppcheck errors out with "could not find or open any of the paths given".
set(_saved_cppcheck "${CMAKE_CXX_CPPCHECK}")
set(CMAKE_CXX_CPPCHECK "")
FetchContent_MakeAvailable(Catch2)
set(CMAKE_CXX_CPPCHECK "${_saved_cppcheck}")

list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)