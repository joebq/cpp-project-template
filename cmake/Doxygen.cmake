# cmake/Doxygen.cmake
# Doxygen documentation generation

option(ENABLE_DOCS "Build API documentation with Doxygen" OFF)

function(add_docs_target)
    if(NOT ENABLE_DOCS)
        return()
    endif()

    find_package(Doxygen REQUIRED)

    if(NOT DOXYGEN_FOUND)
        message(WARNING "Doxygen not found — docs target will not be available. Install with: brew install doxygen")
        return()
    endif()

    set(DOXYGEN_IN  ${CMAKE_SOURCE_DIR}/Doxyfile.in)
    set(DOXYGEN_OUT ${CMAKE_BINARY_DIR}/Doxyfile)

    configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)

    add_custom_target(docs
        COMMENT "Generating API documentation with Doxygen..."
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        VERBATIM
    )

    message(STATUS "Docs target enabled — run 'cmake --build <build-dir> --target docs' to generate documentation")
endfunction()
