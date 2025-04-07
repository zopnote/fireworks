# Copyright (c) 2025 Lenny Siebert. All rights reserved.
# Fireworks is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.

# environment.cmake is for setting up the environment related things.
# It will test for applications, dependencies and compilation steps.

# The file gets included in the main CMakeLists.txt to provide all necessary environment variables.

if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug" AND NOT CMAKE_BUILD_TYPE STREQUAL "Release" AND NOT CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    message(FATAL_ERROR "${CMAKE_BUILD_TYPE} is not a valid build configuration. Available: Debug, Release, RelWithDebInfo.")
endif ()
message(STATUS "")
message(STATUS "${CMAKE_PROJECT_NAME} v${CMAKE_PROJECT_VERSION} ${CMAKE_BUILD_TYPE}")
message(STATUS "${CMAKE_PROJECT_DESCRIPTION}")
message(STATUS "")
message(STATUS "Copyright (c) 2025 Lenny Siebert. All rights reserved.")
message(STATUS "Fireworks is licensed under the terms of the GNU General Public License v3.0 (GPLv3) for open-source usage.")
message(STATUS "")
message(STATUS "CMake version: ${CMAKE_VERSION}")
message(STATUS "Host platform: ${CMAKE_HOST_SYSTEM_NAME} ${CMAKE_HOST_SYSTEM_VERSION}, ${CMAKE_HOST_SYSTEM_PROCESSOR}")
message(STATUS "Target platform: ${CMAKE_SYSTEM_NAME}, ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C++ compiler: ${CMAKE_CXX_COMPILER}")
if (CMAKE_TOOLCHAIN_FILE)
    message(STATUS "Toolchain: ${CMAKE_TOOLCHAIN_FILE}.")
endif ()
macro(search_program NAME VARIABLE)
    find_program(${VARIABLE} ${NAME})
    if (${VARIABLE})
        message(STATUS "${VARIABLE}.....FOUND")
    else ()
        message(STATUS "${VARIABLE}.....NOT FOUND")
    endif ()
endmacro()

search_program(flutter FLUTTER)
search_program(go GOLANG)
search_program(git GIT)


macro(ensure_vendor NAME VARIABLE)
    find_program(${VARIABLE} ${NAME})
    if (${VARIABLE})
        message(STATUS "${VARIABLE}.....FOUND")
    else ()
        message(STATUS "${VARIABLE}.....NOT FOUND")
    endif ()
endmacro()