add_library(Utility utility.cpp utility.hpp)
set_compiler_warnings(Utility)
apply_sanitizers(Utility)
apply_coverage(Utility)


# Optional C++20 module flavour of the same library. It wraps utility.hpp so
# there is a single source of truth; header consumers keep using `Utility`.
if(ENABLE_CXX_MODULES)
    add_library(UtilityModule)
    target_sources(UtilityModule
        PUBLIC
            FILE_SET CXX_MODULES FILES utility.cppm
    )
    target_link_libraries(UtilityModule PUBLIC Utility)
    target_include_directories(UtilityModule PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    set_compiler_warnings(UtilityModule)
    apply_sanitizers(UtilityModule)
    apply_coverage(UtilityModule)
endif()
