cmake_minimum_required(VERSION 3.22.1)
project(turbolink_engine C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── Compiler flags ────────────────────────────────────────────────────
# Aggressive optimizations for release, sanitizers for debug.
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG -flto")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG -flto")
set(CMAKE_C_FLAGS_DEBUG "-O0 -g -fsanitize=address")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g -fsanitize=address")

# ── FetchContent: pull third-party libraries at configure time ────────
include(FetchContent)

# Zstandard compression library (Facebook)
FetchContent_Declare(
    zstd
    GIT_REPOSITORY https://github.com/facebook/zstd.git
    GIT_TAG        v1.5.6
    SOURCE_SUBDIR  build/cmake
)

# libRaptorQ — RFC 6330 RaptorQ fountain codes
FetchContent_Declare(
    libRaptorQ
    GIT_REPOSITORY https://github.com/LucaFulworking/libRaptorQ.git
    GIT_TAG        master
)

# Make zstd only build the static library, no programs/tests.
set(ZSTD_BUILD_PROGRAMS OFF CACHE BOOL "" FORCE)
set(ZSTD_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(ZSTD_BUILD_SHARED OFF CACHE BOOL "" FORCE)
set(ZSTD_BUILD_STATIC ON CACHE BOOL "" FORCE)

# Try to fetch zstd. If it fails (no internet), we compile without it.
FetchContent_MakeAvailable(zstd)

# ── Engine shared library ─────────────────────────────────────────────
add_library(turbolink_engine SHARED
    turbolink_engine.cpp
)

target_include_directories(turbolink_engine PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${zstd_SOURCE_DIR}/lib    # zstd headers
)

target_link_libraries(turbolink_engine PRIVATE
    libzstd_static    # zstd static library
    log               # Android __android_log_print
)

# Ensure symbols are visible for Dart FFI.
target_compile_definitions(turbolink_engine PRIVATE
    TL_USE_ZSTD=1
)

# Strip debug info in release for smaller .so.
set_target_properties(turbolink_engine PROPERTIES
    LINK_FLAGS_RELEASE "-Wl,--strip-all"
)
