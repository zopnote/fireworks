
add_subdirectory(vendor/JoltPhysics/Build)

add_subdirectory(vendor/libyaml)
if (CMAKE_SYSTEM_NAME STREQUAL Linux)
    find_package(X11 REQUIRED)
endif ()
option(BGFX_BUILD_EXAMPLES OFF)
option(BGFX_BUILD_TESTS OFF)
add_subdirectory(vendor/bgfx.cmake)

add_subdirectory(vendor/Nuklear)

add_subdirectory(vendor/SDL)