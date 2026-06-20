# cmake/Sanitizers.cmake
# Sanitizer support for GCC, Clang, AppleClang, and MSVC

option(ENABLE_ASAN "Enable AddressSanitizer + UndefinedBehaviorSanitizer" OFF)
option(ENABLE_TSAN "Enable ThreadSanitizer" OFF)
option(ENABLE_MSAN "Enable MemorySanitizer (Clang only)" OFF)

# ASAN and TSAN are mutually exclusive
if(ENABLE_ASAN AND ENABLE_TSAN)
    message(FATAL_ERROR "AddressSanitizer and ThreadSanitizer cannot be used together.")
endif()

if(ENABLE_ASAN AND ENABLE_MSAN)
    message(FATAL_ERROR "AddressSanitizer and MemorySanitizer cannot be used together.")
endif()

function(apply_sanitizers target_name)
    if(NOT (ENABLE_ASAN OR ENABLE_TSAN OR ENABLE_MSAN))
        return()
    endif()

    if(MSVC)
        if(ENABLE_ASAN)
            target_compile_options(${target_name} PRIVATE /fsanitize=address)
        endif()
        # MSVC does not support TSAN or MSAN
        return()
    endif()

    set(SANITIZER_FLAGS "")
    set(SANITIZER_LINK_FLAGS "")

    if(ENABLE_ASAN)
        list(APPEND SANITIZER_FLAGS
            -fsanitize=address
            -fsanitize=undefined
            -fno-sanitize-recover=all
            -fno-omit-frame-pointer
            -fno-optimize-sibling-calls
        )
        list(APPEND SANITIZER_LINK_FLAGS
            -fsanitize=address
            -fsanitize=undefined
        )
    endif()

    if(ENABLE_TSAN)
        list(APPEND SANITIZER_FLAGS -fsanitize=thread)
        list(APPEND SANITIZER_LINK_FLAGS -fsanitize=thread)
    endif()

    if(ENABLE_MSAN)
        if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
            message(WARNING "MemorySanitizer is only supported by Clang. Skipping for ${target_name}.")
            return()
        endif()
        list(APPEND SANITIZER_FLAGS
            -fsanitize=memory
            -fno-omit-frame-pointer
            -fsanitize-memory-track-origins=2
        )
        list(APPEND SANITIZER_LINK_FLAGS -fsanitize=memory)
    endif()

    target_compile_options(${target_name} PRIVATE ${SANITIZER_FLAGS})
    target_link_options(${target_name} PRIVATE ${SANITIZER_LINK_FLAGS})
endfunction()
