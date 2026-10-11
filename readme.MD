# C++ Project Template

A modern C++ project template with CMake presets, Catch2 testing, sanitizers, code coverage, fuzzing support, Doxygen documentation, and static analysis via CppCheck and compiler warnings.

## Project Structure

```
cppTemplate/
├── CMakeLists.txt              # Root build configuration
├── CMakePresets.json            # Configure, build, and test presets
├── Doxyfile.in                  # Doxygen config template (configured by CMake)
├── cmake/
│   ├── CompilerWarnings.cmake   # Strict compiler warning flags
│   ├── Sanitizers.cmake         # ASan, TSan, MSan support
│   ├── Coverage.cmake           # gcov/lcov code coverage
│   ├── CppCheck.cmake           # Static analysis
│   ├── Doxygen.cmake            # Doxygen documentation generation
│   └── catch2.cmake             # Catch2 test framework (FetchContent)
├── include/                     # Public headers
├── src/
│   ├── main.cpp                 # Application entry point (header-based)
│   ├── main_modules.cpp         # Entry point using `import utility;` (ENABLE_CXX_MODULES)
│   └── utility/                 # Utility library
│       ├── CMakeLists.txt
│       ├── utility.cpp
│       ├── utility.hpp
│       └── utility.cppm         # C++20 module interface wrapping utility.hpp
├── test/
│   ├── unittest.cpp             # Catch2 unit tests (headers)
│   └── unittest_modules.cpp     # Catch2 unit tests (modules, ENABLE_CXX_MODULES)
├── fuzzer/
│   └── fuzzer.cpp               # libFuzzer fuzz target
└── third_party/                 # Third-party dependencies
```

## Requirements

- CMake 4.2+
- Ninja build system
- A C++23 compatible compiler (Clang, Apple Clang, GCC, or MSVC)
- `lcov` and `genhtml` (for code coverage reports): `brew install lcov`
- `doxygen` (for documentation): `brew install doxygen`
- `graphviz` (optional, for class/call diagrams in docs): `brew install graphviz`

## Quick Start

```bash
cmake --preset <preset-name>          # Configure
cmake --build --preset <preset-name>  # Build
ctest --preset <preset-name>          # Run tests
```

## Available Presets

### Clang

| Preset           | Description                      |
| ---------------- | -------------------------------- |
| `clang-debug`    | Debug build                      |
| `clang-release`  | Release build                    |
| `clang-asan`     | Debug + AddressSanitizer / UBSan |
| `clang-tsan`     | Debug + ThreadSanitizer          |
| `clang-coverage` | Debug + code coverage            |
| `clang-fuzz`     | Debug + libFuzzer + ASan         |
| `clang-modules`  | Debug + C++20 modules targets    |

### Apple Clang (macOS only)

| Preset           | Description                      |
| ---------------- | -------------------------------- |
| `apple-debug`    | Debug build                      |
| `apple-release`  | Release build                    |
| `apple-asan`     | Debug + AddressSanitizer / UBSan |
| `apple-tsan`     | Debug + ThreadSanitizer          |
| `apple-coverage` | Debug + code coverage            |
| `apple-fuzz`     | Debug + libFuzzer + ASan         |

### GCC

| Preset         | Description                      |
| -------------- | -------------------------------- |
| `gcc-debug`    | Debug build                      |
| `gcc-release`  | Release build                    |
| `gcc-asan`     | Debug + AddressSanitizer / UBSan |
| `gcc-tsan`     | Debug + ThreadSanitizer          |
| `gcc-coverage` | Debug + code coverage            |

### MSVC (Windows only)

| Preset         | Description              |
| -------------- | ------------------------ |
| `msvc-debug`   | Debug build              |
| `msvc-release` | Release build            |
| `msvc-asan`    | Debug + AddressSanitizer |

## Building and Running Tests

Example using Apple Clang on macOS:

```bash
cmake --preset apple-debug
cmake --build --preset apple-debug
ctest --preset apple-debug
```

Build output goes to `build/<preset-name>/`.

## Headers and C++20 Modules

Headers and modules live side by side in the same project. Header targets (`Utility`, `myapp`, `testMain`) are always built. Setting `ENABLE_CXX_MODULES=ON` additionally builds the module targets:

| Target          | Description                                                       |
| --------------- | ----------------------------------------------------------------- |
| `UtilityModule` | Module library (`import utility;`), links the header `Utility`    |
| `myapp_modules` | Example app that uses `import utility;`                           |
| `testModules`   | Catch2 tests that use `import utility;`                           |

```bash
cmake --preset clang-modules
cmake --build --preset clang-modules
ctest --preset clang-modules
```

Or enable it on any other preset: `cmake --preset clang-debug -DENABLE_CXX_MODULES=ON`.

How it works: [`src/utility/utility.cppm`](src/utility/utility.cppm) declares `export module utility;`, includes `utility.hpp` in the global module fragment and re-exports `Point` with `export using ::Point;`. The header stays the single source of truth, so consumers can choose either `#include "utility/utility.hpp"` or `import utility;`. To write a header-free module, put the definitions directly in a `.cppm` file and add it to a `FILE_SET CXX_MODULES` as in `src/utility/CMakeLists.txt`.

Requirements for modules:

- Ninja 1.11+ (or a Visual Studio generator) and CMake 3.28+ (this project already requires 4.2+)
- A compiler with module support and a matching `clang-scan-deps` (for Clang, e.g. Homebrew LLVM: `brew install llvm`). Apple's `/usr/bin/clang` is untested here.

## Code Coverage

Code coverage uses `gcov` + `lcov` to instrument your code and generate an HTML report showing which lines your tests exercise. Works with GCC, Clang, and Apple Clang.

### Running Code Coverage

```bash
# 1. Configure with a coverage preset
cmake --preset apple-coverage

# 2. Build
cmake --build --preset apple-coverage

# 3. Run tests and generate the HTML coverage report
cmake --build build/apple-coverage --target coverage

# 4. Open the report in your browser
open build/apple-coverage/coverage_report/index.html
```

Replace `apple-coverage` with `clang-coverage` or `gcc-coverage` depending on your compiler.

The `--target coverage` step does the following automatically:

1. Resets any previous coverage counters
2. Runs all tests via CTest
3. Captures coverage data with `lcov`
4. Filters out system headers, test files, and third-party code
5. Generates an HTML report in `build/<preset>/coverage_report/`

### If you just want to run the tests (no HTML report)

```bash
ctest --preset apple-coverage
```

## Sanitizers

Sanitizers are enabled via CMake options and are mutually exclusive (you cannot combine ASan with TSan).

| Option        | What it catches                                                      |
| ------------- | -------------------------------------------------------------------- |
| `ENABLE_ASAN` | Memory errors (buffer overflow, use-after-free) + undefined behavior |
| `ENABLE_TSAN` | Data races and threading issues                                      |
| `ENABLE_MSAN` | Uninitialized memory reads (Clang only)                              |

Use the corresponding preset (e.g. `clang-asan`, `gcc-tsan`) or pass the option manually:

```bash
cmake --preset clang-debug -DENABLE_ASAN=ON
```

## Fuzzing

Fuzzing is behind the `ENABLE_FUZZING` option and uses Clang's libFuzzer. The fuzz target is in `fuzzer/fuzzer.cpp`.

```bash
cmake --preset clang-fuzz
cmake --build --preset clang-fuzz
./build/clang-fuzz/fuzzer
```

## Documentation (Doxygen)

Doxygen generates API documentation from your source code comments. It scans `src/` and `include/`, producing an HTML site with class references, file listings, and source browsing.

### Install

```bash
brew install doxygen
brew install graphviz    # optional — enables class/call/collaboration diagrams
```

### Generate Documentation

No special preset is needed — the `docs` target works from any preset. Just pass `-DENABLE_DOCS=ON` when configuring:

```bash
# 1. Configure with docs enabled (use any preset you like)
cmake --preset apple-debug -DENABLE_DOCS=ON

# 2. Build the project (optional — docs don't depend on compiled code)
cmake --build --preset apple-debug

# 3. Generate the documentation
cmake --build build/apple-debug --target docs

# 4. Open in your browser
open build/apple-debug/docs/html/index.html
```

### Enabling Graphviz Diagrams

If you have Graphviz installed, edit `Doxyfile.in` and set:

```
HAVE_DOT = YES
```

This enables class inheritance diagrams, collaboration graphs, call graphs, and caller graphs rendered as interactive SVGs.

### Writing Doxygen Comments

Doxygen extracts documentation from specially formatted comments in your code:

```cpp
/**
 * @brief Calculates the factorial of a number.
 *
 * @param n The input number (must be >= 0).
 * @return The factorial of n.
 * @throws std::invalid_argument if n is negative.
 */
int factorial(int n);

/// @brief A utility class for string operations.
class StringUtils {
public:
    /// Converts a string to uppercase.
    /// @param input The string to convert.
    /// @return The uppercase string.
    std::string toUpper(const std::string& input);
};
```

Common Doxygen tags: `@brief`, `@param`, `@return`, `@throws`, `@note`, `@warning`, `@see`, `@todo`, `@deprecated`.

## CMake Options Reference

| Option            | Default | Description                               |
| ----------------- | ------- | ----------------------------------------- |
| `ENABLE_ASAN`     | `OFF`   | AddressSanitizer + UBSan                  |
| `ENABLE_TSAN`     | `OFF`   | ThreadSanitizer                           |
| `ENABLE_MSAN`     | `OFF`   | MemorySanitizer (Clang only)              |
| `ENABLE_COVERAGE` | `OFF`   | Code coverage instrumentation (gcov/lcov) |
| `ENABLE_FUZZING`  | `OFF`   | Build fuzz targets with libFuzzer         |
| `ENABLE_DOCS`     | `OFF`   | Build API documentation with Doxygen      |
| `ENABLE_CXX_MODULES` | `OFF` | Also build C++20 module targets (headers stay available) |

## References

- [Catch2](https://github.com/catchorg/Catch2)
- [CMake template (cpp-best-practices)](https://github.com/cpp-best-practices/cmake_template)
- [Clang-Tidy docs](https://clang.llvm.org/extra/clang-tidy/)
- [lcov](https://github.com/linux-test-project/lcov)
- [Doxygen](https://www.doxygen.nl/)
- [Graphviz](https://graphviz.org/)

## C++ Package Managers FAQ

### Which C++ package manager to use:

It depends on your priorities, but here's a quick breakdown:

**vcpkg** — best default choice for most people

- Microsoft-backed, huge package catalog
- Integrates cleanly with CMake (manifest mode with `vcpkg.json`)
- Works well cross-platform
- Simple to get started

**Conan** — best for complex/enterprise setups

- More flexible (supports multiple build systems, not just CMake)
- Better for managing private packages and custom configurations
- Steeper learning curve
- Strong versioning and dependency resolution

**CPM (CPM.cmake)** — best for simplicity

- Just a CMake script, no external tool to install
- Fetches dependencies via `FetchContent` under the hood
- Great for small-to-medium projects or header-only/CMake-based libs
- Limited to packages that are CMake-compatible on GitHub/GitLab

**My recommendation:** If you're learning C++ and building personal projects, start with **CPM** — it's the lowest friction (just one `include` in your CMakeLists.txt). If you find yourself needing libraries that aren't easily fetched from Git repos, move to **vcpkg**.

For professional/team work, **vcpkg** is the safest bet. **Conan** is worth it when you need fine-grained control over build configurations or maintain internal package repos.

### Where do package managers install the libraries

**Per project.** Always.

Both vcpkg and Conan support this well:

- **vcpkg**: Use manifest mode — put a `vcpkg.json` in your project root. Dependencies are resolved per project.
- **Conan**: Use a `conanfile.txt` or `conanfile.py` in your project root.

**Why per-project wins:**

- Reproducible builds — anyone cloning your repo gets the same deps
- No version conflicts between projects
- Easy to version-control the dependency list
- CI/CD just works

**The "global install" approach** leads to "works on my machine" problems and version collisions once you have more than one project.

The binaries themselves get cached globally (vcpkg's `~/.vcpkg` cache, Conan's `~/.conan2` cache), so you're not re-downloading/rebuilding everything per project — you just declare what each project needs independently.

### Does that mean the libraries live in each project?

No — the **declarations** live in your project, but the **installed files** go to a shared cache:

- **vcpkg**: `~/.vcpkg/` (binary cache) + a `vcpkg_installed/` folder in your build directory
- **Conan**: `~/.conan2/` (global cache), packages are copied/linked into your build folder at build time

So your project source tree stays clean. You just get:

```
my-project/
├── vcpkg.json          # declaration (commit this)
├── CMakeLists.txt
├── src/
└── build/
    └── vcpkg_installed/ # auto-generated (gitignore this)
```

The global cache means if two projects use the same version of a library, it's only downloaded/built once. Each project just references what it needs from the cache.

**What to commit:** `vcpkg.json` / `conanfile.txt`
**What to gitignore:** the `build/` directory, installed artifacts

### What if I want to update a library with a new version?

**Update the version** in your manifest file, then the old version gets cleaned up naturally:

**vcpkg:**

1. Update the version in `vcpkg.json`
2. Rebuild — `vcpkg_installed/` in your build dir gets updated automatically

**Conan:**

1. Update the version in `conanfile.txt`
2. Run `conan install .` — your build gets the new version

**Clearing the old version from the global cache:**

- **vcpkg**: `vcpkg x-ci-clean` or just delete `~/.vcpkg/downloads/` and `~/.vcpkg/packages/` manually
- **Conan**: `conan cache clean` or `conan remove "libname/old_version*"`

In practice, don't worry too much about cleaning the cache unless you're tight on disk space. The cache is just a build optimization — nothing depends on it at runtime. If it ever gets bloated, you can nuke the entire cache folder and everything rebuilds on next build.
