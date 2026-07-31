cmake_minimum_required(VERSION 4.2)
project(MyProject LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ==================================
# CMake modules
# ==================================
include(cmake/CompilerWarnings.cmake)
include(cmake/Sanitizers.cmake)
include(cmake/CppCheck.cmake)
include(cmake/Coverage.cmake)
include(cmake/Doxygen.cmake)
include(cmake/catch2.cmake)

add_subdirectory(src/utility)


# ==================================
# Main executable
# ==================================
add_executable(myapp src/main.cpp)
target_include_directories(myapp PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(myapp PRIVATE Utility)
set_compiler_warnings(myapp)
apply_sanitizers(myapp)
apply_coverage(myapp)

# ==================================
# Unit Tests
# ==================================
add_executable(testMain test/unittest.cpp)
target_include_directories(testMain PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(testMain PRIVATE Catch2::Catch2WithMain Utility)
disable_cppcheck(testMain)
apply_sanitizers(testMain)
apply_coverage(testMain)

enable_testing()
include(CTest)
include(Catch)
catch_discover_tests(testMain)

add_coverage_target(testMain)


# ==================================
# Documentation
# ==================================
add_docs_target()


# ==================================
# Fuzzer
# ==================================
option(ENABLE_FUZZING "Build fuzz targets with libFuzzer (Clang)" OFF)

if(ENABLE_FUZZING)
    add_executable(fuzzer fuzzer/fuzzer.cpp)
    target_link_libraries(fuzzer PRIVATE Utility)
    target_compile_options(fuzzer PRIVATE -fsanitize=fuzzer)
    target_link_options(fuzzer PRIVATE -fsanitize=fuzzer)
endif()