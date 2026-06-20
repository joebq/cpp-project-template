# cmake/CppCheck.cmake
# Cppcheck static analysis integration

option(ENABLE_CPPCHECK "Enable cppcheck static analysis" ON)

if(ENABLE_CPPCHECK)
    find_program(CPPCHECK_EXE NAMES cppcheck)

    if(CPPCHECK_EXE)
        message(STATUS "cppcheck found: ${CPPCHECK_EXE}")

        set(CMAKE_CXX_CPPCHECK
            "${CPPCHECK_EXE}"
            "--enable=all"
            "--check-level=exhaustive"
            "--inconclusive"
            "--inline-suppr"
            "--std=c++23"
            "--suppress=missingIncludeSystem"
            "--suppress=unmatchedSuppression"
            "--suppress=checkersReport"
            "--suppressions-list=${CMAKE_SOURCE_DIR}/.cppcheck-suppressions"
            "-i${CMAKE_SOURCE_DIR}/third_party"
            "-i${CMAKE_BINARY_DIR}"
            "--template={file}:{line}: [{severity}] ({id}) {message}"
            CACHE STRING "cppcheck command line" FORCE
        )
    else()
        message(WARNING "cppcheck requested but not found. Install it or set ENABLE_CPPCHECK=OFF.")
    endif()
endif()

# Call this on targets that should NOT be checked (e.g. test targets using Catch2)
function(disable_cppcheck target_name)
    set_target_properties(${target_name} PROPERTIES CXX_CPPCHECK "")
endfunction()
