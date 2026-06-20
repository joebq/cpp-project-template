# cmake/CompilerWarnings.cmake
# CLion-style compiler warnings for GCC, Clang, AppleClang, and MSVC

function(set_compiler_warnings target_name)
    set(GCC_CLANG_WARNINGS
        -Wall
        -Wextra
        -Wpedantic
        -Werror

        # Conversion and narrowing
        -Wconversion
        -Wsign-conversion
        -Wnarrowing
        -Wdouble-promotion
        -Wfloat-conversion

        # Dangling and lifetime
        -Wdangling-reference
        -Wreturn-local-addr
        -Winit-self

        # Safety
        -Wshadow
        -Wcast-align
        -Wcast-qual
        -Wformat=2
        -Wformat-overflow=2
        -Wformat-truncation=2
        -Wformat-security
        -Wnull-dereference
        -Wstack-protector
        -Wimplicit-fallthrough=5
        -Wstringop-overflow=4
        -Warray-bounds=2

        # Unused code
        -Wunused
        -Wunused-parameter
        -Wunused-result
        -Wuninitialized

        # Class / OOP
        -Wnon-virtual-dtor
        -Woverloaded-virtual
        -Wold-style-cast
        -Wmisleading-indentation

        # Misc
        -Wduplicated-cond
        -Wduplicated-branches
        -Wlogical-op
        -Wredundant-decls
        -Wundef
        -Wswitch-enum
        -Wextra-semi
    )

    set(CLANG_WARNINGS
        -Wall
        -Wextra
        -Wpedantic
        -Werror

        # Conversion and narrowing
        -Wconversion
        -Wsign-conversion
        -Wnarrowing
        -Wdouble-promotion
        -Wfloat-conversion
        -Wshorten-64-to-32
        -Wimplicit-int-conversion
        -Wimplicit-float-conversion

        # Dangling and lifetime
        -Wdangling
        -Wreturn-stack-address
        -Wdangling-gsl

        # Safety
        -Wshadow
        -Wcast-align
        -Wcast-qual
        -Wformat=2
        -Wformat-security
        -Wnull-dereference
        -Wimplicit-fallthrough

        # Unused code
        -Wunused
        -Wunused-parameter
        -Wunused-result
        -Wuninitialized
        -Wconditional-uninitialized

        # Class / OOP
        -Wnon-virtual-dtor
        -Woverloaded-virtual
        -Wold-style-cast
        -Wmisleading-indentation

        # Misc
        -Wredundant-decls
        -Wundef
        -Wswitch-enum
        -Wextra-semi
        -Wheader-hygiene
        -Wnewline-eof
        -Wundefined-func-template
    )

    set(MSVC_WARNINGS
        /W4
        /WX

        # Narrowing / conversion
        /w14242   # conversion from 'type1' to 'type2', possible loss of data
        /w14254   # operator: conversion from 'type1:field_bits' to 'type2:field_bits'
        /w14263   # member function does not override any base class virtual member function
        /w14265   # class has virtual functions but destructor is not virtual
        /w14287   # unsigned/negative constant mismatch
        /w14296   # expression is always true/false
        /w14311   # pointer truncation from 'type1' to 'type2'
        /w14545   # expression before comma evaluates to a function
        /w14546   # function call before comma missing argument list
        /w14547   # operator before comma has no effect
        /w14549   # operator before comma has no effect; did you intend 'operator'?
        /w14555   # expression has no effect; expected expression with side-effect
        /w14619   # pragma warning: warning number does not exist
        /w14640   # thread-unsafe static member initialization
        /w14826   # conversion is sign-extended
        /w14905   # wide string literal cast to 'LPSTR'
        /w14906   # string literal cast to 'LPWSTR'
        /w14928   # illegal copy-initialization
        /permissive-
        /volatile:iso
        /Zc:__cplusplus
        /Zc:preprocessor
        /Zc:enumTypes
        /Zc:inline
        /Zc:throwingNew
        /EHsc
    )

    target_compile_options(${target_name} PRIVATE
        $<$<CXX_COMPILER_ID:GNU>:${GCC_CLANG_WARNINGS}>
        $<$<CXX_COMPILER_ID:Clang,AppleClang>:${CLANG_WARNINGS}>
        $<$<CXX_COMPILER_ID:MSVC>:${MSVC_WARNINGS}>
    )
endfunction()
