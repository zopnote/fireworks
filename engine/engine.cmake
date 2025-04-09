
# Entry point for building the engine runtime.
if (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    cmake_minimum_required(VERSION 3.20)
    project(fireworks_runtime
            DESCRIPTION "The engine runtime of Fireworks"
            VERSION 0.1
            LANGUAGES C CXX
    )
endif ()

# Engine modules
# ------------------------------------------------------------------------------------------------------------------
include(modules/renderer/module.cmake)
# ------------------------------------------------------------------------------------------------------------------

# Vendor configuration and inclusion
# ------------------------------------------------------------------------------------------------------------------
include(vendor/vulkanConfig.cmake)

include(vendor/JoltPhysicsConfig.cmake)

include(vendor/libyamlConfig.cmake)
add_subdirectory(vendor/libyaml)

include(vendor/NuklearConfig.cmake)
add_subdirectory(vendor/Nuklear)

include(vendor/SDLConfig.cmake)
add_subdirectory(vendor/SDL)
# ------------------------------------------------------------------------------------------------------------------