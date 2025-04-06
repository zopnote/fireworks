include(vendor/JoltPhysicsConfig.cmake)
add_subdirectory(vendor/JoltPhysics/Build)

include(vendor/libyamlConfig.cmake)
add_subdirectory(vendor/libyaml)

include(vendor/bgfxConfig.cmake)
add_subdirectory(vendor/bgfx)

include(vendor/NuklearConfig.cmake)
add_subdirectory(vendor/Nuklear)

include(vendor/SDLConfig.cmake)
add_subdirectory(vendor/SDL)