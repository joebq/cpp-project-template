# Create a Repeatable CMAKE

> https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html
> https://martin-fieber.de/blog/cmake-presets/
> https://doc.qt.io/qtcreator/creator-build-settings-cmake-presets.html
> 

## CMAKE with SAN Sanitizers

When using CMake with Ninja, the goal is to keep your `CMakeLists.txt` clean and leverage CMake's built-in "Build Type" awareness. Since Ninja is a single-config generator (unlike Visual Studio or Xcode), it expects the configuration to be set at the time of the initial "generate" step.

Here is the best-practice approach to organizing flags and sanitizers.

---

## 1. Handling Debug vs. Release

Instead of hardcoding flags like `-O3` or `-g`, you should use **Generator Expressions**. These allow CMake to switch flags automatically based on the `CMAKE_BUILD_TYPE`.

```cmake
target_compile_options(my_project PRIVATE
    $<$<CONFIG:Debug>:-O0 -g>
    $<$<CONFIG:Release>:-O3 -DNDEBUG>
)

```

To switch between them when using Ninja, you run:

* **For Debug:** `cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug`
* **For Release:** `cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release`

---

## 2. Integrating Sanitizers (ASan and UBSan)

Sanitizers significantly slow down execution and increase memory usage, so you typically want them enabled **only in Debug mode** or a specific **Sanitizer profile**.

The best way to do this is to create an interface library. This keeps your main target logic clean and allows you to "link" the sanitizers to any executable or library in your project.

### Example Setup

```cmake
# Create a 'developer_options' interface
add_library(project_warnings INTERFACE)

# Apply Sanitizers only in Debug mode
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(project_warnings INTERFACE 
        -fsanitize=address 
        -fsanitize=undefined 
        -fno-omit-frame-pointer
    )
    target_link_options(project_warnings INTERFACE 
        -fsanitize=address 
        -fsanitize=undefined
    )
endif()

# Apply to your target
add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE project_warnings)

```

---

## 3. Recommended Project Structure

For a professional C++ project, avoid putting everything in the root. Use a dedicated `cmake/` folder for compiler settings.

| File | Purpose |
| --- | --- |
| `CMakeLists.txt` | General project definition and targets. |
| `cmake/CompilerFlags.cmake` | Logic for `-Wall`, `-Wextra`, and optimization levels. |
| `cmake/Sanitizers.cmake` | Logic for ASan, TSan, or MSan. |

**In your main `CMakeLists.txt`:**

```cmake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(CompilerFlags)
include(Sanitizers)

```

---

## 4. Pro-Tip: Use `ccache` with Ninja

Since you are using Ninja for speed, you should ensure `ccache` is enabled to prevent recompiling files that haven't changed across build type swaps.

```cmake
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

```

---

## Summary Checklist

1. **Use `target_compile_options**` instead of global `add_definitions`.
2. **Use Generator Expressions** `$<$<CONFIG:Debug>:...>` for build-specific flags.
3. **Link Sanitizers** as both compile and link options (they require library support at runtime).
4. **Set `CMAKE_BUILD_TYPE**` explicitly when calling CMake from the command line.


--- 

## CMAKE With Presets

Actually, **`CMakePresets.json`** is the modern, industry-standard way to manage exactly what you are trying to do. It doesn't replace the logic in your `CMakeLists.txt`; rather, it acts as a "driver" that saves you from typing long command-line arguments.

If the `CMakeLists.txt` defines *what* can be built, `CMakePresets.json` defines *how* it is built on your specific machine or CI environment.

---

## 1. Why Presets are "Better"

When using Ninja, you usually have to remember to pass `-DCMAKE_BUILD_TYPE=Debug` and `-G Ninja` every time you clear your cache. Presets solve several problems:

* **Consistency:** Everyone on your team uses the exact same flags.
* **IDE Integration:** VS Code, CLion, and Visual Studio automatically read this file and give you a dropdown menu to switch between "Debug-ASan" and "Release."
* **Separation of Concerns:** You keep the messy environment-specific paths (like where your compiler is) out of your logic-heavy `CMakeLists.txt`.

---

## 2. Recommended Setup (Presets + CMake)

The most robust way to handle this is to combine both. Use your `CMakeLists.txt` to define the **options**, and use `CMakePresets.json` to **toggle** them.

### Step A: The `CMakeLists.txt` (The Logic)

```cmake
option(ENABLE_SANITIZER_ADDRESS "Enable Address Sanitizer" OFF)

if(ENABLE_SANITIZER_ADDRESS)
    add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
    add_link_options(-fsanitize=address)
endif()

```

### Step B: The `CMakePresets.json` (The Execution)

This file lives in your root directory. It tells Ninja exactly which variables to turn on for which "mode."

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/out/build/${presetName}",
      "cacheVariables": {
        "CMAKE_EXPORT_COMPILE_COMMANDS": "YES"
      }
    },
    {
      "name": "debug-asan",
      "displayName": "Debug + Address Sanitizer",
      "inherits": "base",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "ENABLE_SANITIZER_ADDRESS": "ON"
      }
    },
    {
      "name": "release",
      "displayName": "Release Optimization",
      "inherits": "base",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    }
  ]
}

```

---

## 3. How to use it with Ninja

Once you have this file, your command line becomes much simpler:

* **To configure:** `cmake --preset debug-asan`
* **To build:** `cmake --build --preset debug-asan` (This automatically calls Ninja)

---

## 4. When to use which?

| Feature | Use `CMakeLists.txt` when... | Use `CMakePresets.json` when... |
| --- | --- | --- |
| **Flags** | Defining *which* flags are compatible with your code. | Choosing *which* set of flags to use right now. |
| **Sanitizers** | Adding the logic to link `-fsanitize=address`. | Creating a specific "Sanitizer" build configuration. |
| **Optimization** | Setting defaults for Debug/Release. | Switching between Ninja and another generator. |

---

## Summary

You should definitely use **`CMakePresets.json`**. It is the "glue" that connects your compiler flags and sanitizers to your Ninja build system without requiring you to write shell scripts or long manual commands.


## CMAKE Presets & Commandline

Short answer:

*   **`CMakePresets.json` is for *driving* CMake** (configuring, building, testing, packaging) via named presets. It doesn’t replace your project’s build logic; it centralizes commonly used command-line options and cache values. [\[cmake.org\]](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html), [\[learn.microsoft.com\]](https://learn.microsoft.com/en-us/cpp/build/cmake-presets-vs?view=msvc-170)
*   **Put the sanitizer/fuzzer logic in `CMakeLists.txt`** (target options, feature toggles), then **use presets to turn those options on/off** for specific workflows (e.g., “asan-debug”, “fuzz-libfuzzer”). This keeps project semantics in CMake, while presets give devs and CI one-click configurations. [\[cmake.org\]](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)

***

## What each file is for

*   **`CMakeLists.txt`**: Where you define targets, options, and how those options affect compilation/linking (e.g., `target_compile_options`, `target_link_options`, `option(ENABLE_ASAN ...)`).
*   **`CMakePresets.json` / `CMakeUserPresets.json`**: Where you define **configure/build/test presets** that set generators, build directories, cache variables, environments, and inherit across platforms/tools. Presets allow `cmake --preset <name>` and `cmake --build --preset <name>`. [\[cmake.org\]](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html), [\[github.com\]](https://github.com/microsoft/vscode-cmake-tools/blob/main/docs/cmake-presets.md)

> The manual explicitly describes configure, build, test, package, workflow presets and notes that `CMakePresets.json` is project-wide while `CMakeUserPresets.json` is for per-developer local customizations. [\[cmake.org\]](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html), [\[learn.microsoft.com\]](https://learn.microsoft.com/en-us/cpp/build/cmake-presets-json-reference?view=msvc-170)

***

## Best‑practice layout for sanitizers & fuzzers

### 1) Define portable toggles in `CMakeLists.txt`

Create **options** that map cleanly to compiler/linker flags. Prefer **per-target** flags over global `CMAKE_*_FLAGS`, and remember sanitizers typically need **both compile and link** flags.

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(myproj LANGUAGES C CXX)

option(ENABLE_ASAN "Enable AddressSanitizer for supported compilers" OFF)
option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer" OFF)
option(ENABLE_FUZZING "Build fuzz targets with libFuzzer (Clang)" OFF)

add_library(core src/core.cpp)
add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE core)

function(apply_sanitizers tgt)
  if (ENABLE_ASAN)
    target_compile_options(${tgt} PRIVATE -fsanitize=address -fno-omit-frame-pointer -g)
    target_link_options(${tgt} PRIVATE -fsanitize=address)
  endif()
  if (ENABLE_UBSAN)
    target_compile_options(${tgt} PRIVATE -fsanitize=undefined -g)
    target_link_options(${tgt} PRIVATE -fsanitize=undefined)
  endif()
endfunction()

apply_sanitizers(core)
apply_sanitizers(app)

# Example fuzz target (libFuzzer requires Clang and a fuzz entrypoint)
add_executable(fuzz_core tests/fuzz_core.cpp)
target_link_libraries(fuzz_core PRIVATE core)
if (ENABLE_FUZZING)
  target_compile_options(fuzz_core PRIVATE -fsanitize=fuzzer,address -g)
  target_link_options(fuzz_core PRIVATE -fsanitize=fuzzer,address)
endif()
```

*   Using **`target_compile_options` / `target_link_options`** for `-fsanitize=address` is the recommended way, and it ensures both compile and link phases get the flags. [\[stackoverflow.com\]](https://stackoverflow.com/questions/44320465/whats-the-proper-way-to-enable-addresssanitizer-in-cmake-that-works-in-xcode)
*   LibFuzzer on Clang is enabled via `-fsanitize=fuzzer` (often combined with ASan). It must be present **at link time** too; forgetting link flags leads to errors. [\[releases.llvm.org\]](https://releases.llvm.org/21.1.0/docs/LibFuzzer.html), [\[stackoverflow.com\]](https://stackoverflow.com/questions/55452391/how-to-create-minimal-libfuzzer-cmake-example)

### 2) Drive those toggles via presets

Add presets that set cache variables (your options) and any environment/toolchain differences.

```json
// CMakePresets.json
{
  "version": 5,
  "configurePresets": [
    {
      "name": "dev-ninja",
      "displayName": "Dev (Ninja)",
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/build/dev",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    },
    {
      "name": "asan-debug",
      "displayName": "ASan (Debug)",
      "inherits": "dev-ninja",
      "cacheVariables": {
        "ENABLE_ASAN": true,
        "CMAKE_BUILD_TYPE": "Debug"
      }
    },
    {
      "name": "fuzz-libfuzzer",
      "displayName": "LibFuzzer (Clang, ASan)",
      "inherits": "dev-ninja",
      "cacheVariables": {
        "ENABLE_FUZZING": true,
        "ENABLE_ASAN": true,
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_C_COMPILER": "clang",
        "CMAKE_CXX_COMPILER": "clang++"
      }
    }
  ],
  "buildPresets": [
    { "name": "build-asan", "configurePreset": "asan-debug" },
    { "name": "build-fuzz", "configurePreset": "fuzz-libfuzzer" }
  ],
  "testPresets": [
    { "name": "ctest-asan", "configurePreset": "asan-debug" }
  ]
}
```

Now you can:

```bash
cmake --preset asan-debug
cmake --build --preset build-asan

cmake --preset fuzz-libfuzzer
cmake --build --preset build-fuzz
./build/dev/fuzz_core  # run the fuzzer
```

*   Presets **encapsulate configure/build/test settings** and can inherit to avoid duplication. [\[cmake.org\]](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)
*   VS/VS Code integrate with presets, making these selectable in the UI and CI. [\[learn.microsoft.com\]](https://learn.microsoft.com/en-us/cpp/build/cmake-presets-vs?view=msvc-170), [\[github.com\]](https://github.com/microsoft/vscode-cmake-tools/blob/main/docs/cmake-presets.md)

***

## Why not put flags only in presets?

You *can* inject flags through `cacheVariables` (e.g., `CMAKE_CXX_FLAGS`), but it is brittle:

*   Global flags can break toolchains, IDEs, and configuration checks (e.g., `-fsanitize=fuzzer` during compiler detection may fail because the test program has a normal `main` conflicting with libFuzzer’s `main`). [\[discourse.cmake.org\]](https://discourse.cmake.org/t/passing-fsanitize-fuzzer-via-the-command-line-or-from-a-cmakepresets-file/7902)
*   Per‑target options are clearer and avoid over‑instrumenting unrelated targets (tests, tools, third‑party deps). The community guidelines and answers recommend `target_*` options for ASan. [\[stackoverflow.com\]](https://stackoverflow.com/questions/44320465/whats-the-proper-way-to-enable-addresssanitizer-in-cmake-that-works-in-xcode)

***

## Notes for libFuzzer & sanitizers

*   **LibFuzzer**: Build fuzz targets with Clang and `-fsanitize=fuzzer`. Often combine with `-fsanitize=address` and `-g`. Your fuzz target must implement `LLVMFuzzerTestOneInput` and is linked as an **executable** that you run; the engine provides its own `main`. [\[releases.llvm.org\]](https://releases.llvm.org/21.1.0/docs/LibFuzzer.html), [\[github.com\]](https://github.com/google/fuzzing/blob/master/tutorial/libFuzzerTutorial.md)
*   **Sanitizers need link flags** too (not only compile). Forgetting `target_link_options(... -fsanitize=address)` is a common source of “no errors detected” or link failures. [\[stackoverflow.com\]](https://stackoverflow.com/questions/44320465/whats-the-proper-way-to-enable-addresssanitizer-in-cmake-that-works-in-xcode), [\[stackoverflow.com\]](https://stackoverflow.com/questions/55452391/how-to-create-minimal-libfuzzer-cmake-example)
*   **Toolchain/IDE quirks**: If you’re on Xcode or Windows/MSVC, prefer `target_*` properties (or Xcode attributes) rather than raw `CMAKE_*_FLAGS`. [\[stackoverflow.com\]](https://stackoverflow.com/questions/44320465/whats-the-proper-way-to-enable-addresssanitizer-in-cmake-that-works-in-xcode)

***

## Practical rule of thumb

*   **Put project behavior in `CMakeLists.txt`** (options and how they affect targets).
*   **Use `CMakePresets.json`** to **select** those behaviors for dev machines/CI (set `-D ENABLE_*` options, compilers, generators, dirs).  
    This separation matches the intent of presets and scales well across teams and CI. [\[cmake.org\]](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)

***

If you share a snippet of your current `CMakeLists.txt`/`CMakePresets.json`, I can tailor the exact options/presets for your compiler and OS matrix (Clang/GCC/MSVC, Linux/macOS/Windows), including leak detection tweaks and fuzzer runtime settings.

--- 

## CMake Cache Variables

In CMake, cache variables are persistent values stored in the `CMakeCache.txt` file in your build directory. When you use the `-D` flag (e.g., `cmake -D CMAKE_BUILD_TYPE=Release ..`), you are creating or updating these entries.

While any project-specific variable can be a cache variable, there are several standard CMake variables that are frequently passed during the configuration step.

### 1. Build & System Configuration

These variables control the core behavior of the generation process, such as where files go and how they are compiled.

| Variable | Description | Typical Values |
| --- | --- | --- |
| **`CMAKE_BUILD_TYPE`** | Sets the optimization and debug levels (for single-config generators like Ninja/Make). | `Debug`, `Release`, `RelWithDebInfo`, `MinSizeRel` |
| **`CMAKE_INSTALL_PREFIX`** | The "install" root directory (where `cmake --install` puts files). | `/usr/local`, `C:/Program Files/Project` |
| **`BUILD_SHARED_LIBS`** | Global toggle to build libraries as shared (`.so`/`.dll`) instead of static. | `ON`, `OFF` |
| **`CMAKE_EXPORT_COMPILE_COMMANDS`** | Generates `compile_commands.json` for Clang-based LSP/tools. | `ON`, `OFF` |

### 2. Dependency & Path Management

Used to help CMake find libraries, headers, or external packages that aren't in standard system paths.

* **`CMAKE_PREFIX_PATH`**: A semicolon-separated list of directories to search for `find_package()`, `find_library()`, etc.
* **`CMAKE_MODULE_PATH`**: Where to look for custom `.cmake` modules/scripts.
* **`<PackageName>_ROOT`**: (CMake 3.12+) Specific search root for a package (e.g., `-DOpenSSL_ROOT=/opt/openssl`).

### 3. Compiler & Toolchain Settings

These are usually set once during the initial configuration and define the environment.

* **`CMAKE_C_COMPILER`** / **`CMAKE_CXX_COMPILER`**: Force a specific compiler (e.g., `clang++` or `gcc-12`).
* **`CMAKE_CXX_STANDARD`**: Sets the C++ standard version (e.g., `11`, `14`, `17`, `20`).
* **`CMAKE_TOOLCHAIN_FILE`**: Path to a script for cross-compiling (e.g., for Android, iOS, or embedded).
* **`CMAKE_GENERATOR`**: Though usually set via `-G`, this can also be influenced by cache settings in specific scenarios.

### 4. Project-Specific Options

Most professional projects define their own "switches" using the `option()` command or `set(... CACHE ...)`. These are almost always passed via `-D`.

* Example: `-DBUILD_TESTING=OFF` (A standard used by many projects).
* Example: `-DWITH_CUDA=ON` or `-DUSE_MY_LIBRARY=OFF`.

---

### Pro-Tip: How to see what's available

If you are working with a new project and want to see which variables you *can* pass with `-D`, use these commands:

* **List all cached variables:**
```bash
cmake -L ..

```


* **List variables with their help descriptions:**
```bash
cmake -LH ..

```


* **Include "Advanced" variables (those usually hidden):**
```bash
cmake -LAH ..

```



Would you like me to help you create a `CMakePresets.json` file so you don't have to type these `-D` flags every time?




--- 

# Configure ASAN Flags & Compiler Flags

```bash
    cmake -D CMAKE_C_COMPILER="/opt/homebrew/opt/llvm/bin/clang" \
      -D CMAKE_CXX_COMPILER="/opt/homebrew/opt/llvm/bin/clang++" ..

      ASAN_OPTIONS=detect_leaks=1 ./myapp 

      # using leaks for macos
      export MallocStackLogging=1
      leaks -atExit -- ./myapp
```


---

