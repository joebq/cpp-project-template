# cmake/Coverage.cmake
# Code coverage support using gcov + lcov

option(ENABLE_COVERAGE "Build with code coverage instrumentation (gcov/lcov)" OFF)

if(ENABLE_COVERAGE)
    if(MSVC)
        message(FATAL_ERROR "Code coverage is not supported with MSVC. Use GCC or Clang.")
    endif()

    if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
        message(WARNING "Code coverage results are best with Debug builds (CMAKE_BUILD_TYPE=Debug).")
    endif()

    find_program(LCOV_PATH lcov)
    find_program(GENHTML_PATH genhtml)

    if(NOT LCOV_PATH)
        message(WARNING "lcov not found — coverage targets will not be available. Install with: brew install lcov")
    endif()
endif()

function(apply_coverage target_name)
    if(NOT ENABLE_COVERAGE)
        return()
    endif()

    target_compile_options(${target_name} PRIVATE --coverage -fprofile-arcs -ftest-coverage)
    target_link_options(${target_name} PRIVATE --coverage)
endfunction()

# Adds a 'coverage' custom target that runs tests and generates an HTML report
function(add_coverage_target test_target)
    if(NOT ENABLE_COVERAGE)
        return()
    endif()

    if(NOT LCOV_PATH OR NOT GENHTML_PATH)
        message(STATUS "Skipping coverage target — lcov/genhtml not found.")
        return()
    endif()

    add_custom_target(coverage
        COMMENT "Running tests and generating coverage report..."

        # Reset counters
        COMMAND ${LCOV_PATH} --directory ${CMAKE_BINARY_DIR} --zerocounters

        # Run tests
        COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure

        # Capture coverage data
        COMMAND ${LCOV_PATH} --directory ${CMAKE_BINARY_DIR} --capture --output-file coverage.info
            --ignore-errors unsupported,unsupported
            --ignore-errors format,format

        # Remove system headers and test files from report
        COMMAND ${LCOV_PATH} --remove coverage.info
            "/usr/*"
            "${CMAKE_SOURCE_DIR}/test/*"
            "${CMAKE_SOURCE_DIR}/third_party/*"
            "*/catch2/*"
            --output-file coverage.info
            --ignore-errors unsupported,unsupported
            --ignore-errors empty,empty
            --ignore-errors unused,unused

        # Generate HTML report
        COMMAND ${GENHTML_PATH} coverage.info --output-directory coverage_report
            --ignore-errors empty,empty

        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        DEPENDS ${test_target}
        VERBATIM
    )

    message(STATUS "Coverage target enabled — run 'cmake --build <build-dir> --target coverage' to generate report")
endfunction()
