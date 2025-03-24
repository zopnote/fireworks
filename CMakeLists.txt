cmake_minimum_required(VERSION 3.13)


# -----------------------------------------------------------------------------
project(
        fireworks
        DESCRIPTION "Modern cross-platform graphics engine framework."
        VERSION 0.1
        LANGUAGES C CXX
)
# -----------------------------------------------------------------------------



# Language related
# -----------------------------------------------------------------------------
set(CMAKE_C_STANDARD 23)
set(CMAKE_CXX_STANDARD 23)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()
if (CMAKE_BUILD_TYPE STREQUAL Debug)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra -Wpedantic -Wformat -Wformat-security -Wstack-protector -fstack-protector-strong -Wno-missing-braces -Wno-unused-parameter")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -Wformat -Wformat-security -Wstack-protector -fstack-protector-strong -Wno-missing-braces -Wno-unused-parameter")
else ()
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-stack-protector")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-stack-protector")
endif ()

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

if(CMAKE_SYSTEM_NAME STREQUAL Windows)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-microsoft -Wno-deprecated-declarations")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-microsoft -Wno-deprecated-declarations")
endif()
# -----------------------------------------------------------------------------



# Global config
# -----------------------------------------------------------------------------
string(TOLOWER
        "${CMAKE_SYSTEM_NAME}_${CMAKE_SYSTEM_PROCESSOR}-${CMAKE_BUILD_TYPE}"
        LOWER_CMAKE_BUILD_NAME
)
set(CMAKE_INSTALL_PREFIX
        "${CMAKE_SOURCE_DIR}/cmake-out/${LOWER_CMAKE_BUILD_NAME}/${PROJECT_NAME}"
)
# -----------------------------------------------------------------------------



# Variables which defines the structure of the output, installed, binaries.
# -----------------------------------------------------------------------------

# The binary and internal paths are hard coded in the program
if(CMAKE_BUILD_TYPE STREQUAL Debug)
    set(OUT_BINARY_DIRECTORY .)
else()
    set(OUT_BINARY_DIRECTORY bin)
endif()

set(OUT_INTERNAL_DIRECTORY ${OUT_BINARY_DIRECTORY}/internal)
set(OUT_CACHE_DIRECTORY ${OUT_BINARY_DIRECTORY}/cache)

set(OUT_DOCUMENTATION_DIRECTORY docs)
set(OUT_LIBRARY_DIRECTORY lib)
set(OUT_INCLUDE_DIRECTORY include)

set(OUT_RUNTIME_DIRECTORY engine/runtime)
set(OUT_UNIT_RUNTIME_DIRECTORY ${OUT_RUNTIME_DIRECTORY}/unit)
set(OUT_CONFIG_DIRECTORY ${OUT_RUNTIME_DIRECTORY}/config)
set(OUT_SCRIPTS_DIRECTORY ${OUT_RUNTIME_DIRECTORY}/scripts)
set(OUT_RESOURCE_DIRECTORY ${OUT_RUNTIME_DIRECTORY}/resources)
set(OUT_TEMPLATES_DIRECTORY ${OUT_RUNTIME_DIRECTORY}/templates)

# -----------------------------------------------------------------------------

add_subdirectory(engine)