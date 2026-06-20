add_library(Utility utility.cpp utility.hpp)
set_compiler_warnings(Utility)
apply_sanitizers(Utility)
apply_coverage(Utility)
