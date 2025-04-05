include(FetchContent)

FetchContent_Declare(
        bx
        GIT_REPOSITORY https://github.com/bkaradzic/bx.git
        GIT_TAG master
)
FetchContent_MakeAvailable(bx)

file(GLOB_RECURSE SOURCES ${bx_SOURCE_DIR}/src/**.cpp)
add_library(bx STATIC)

target_sources(bx PRIVATE
        ${SOURCES}
)
target_compile_options(bx PRIVATE
        /Zc:__cplusplus
        /Zc:preprocessor
)

target_compile_definitions(bx PRIVATE BX_CONFIG_DEBUG=0)
target_include_directories(bx PUBLIC
        ${bx_SOURCE_DIR}/include
        ${bx_SOURCE_DIR}/3rdparty
)

FetchContent_Declare(
        bimg
        GIT_REPOSITORY https://github.com/bkaradzic/bimg.git
        GIT_TAG master
)
FetchContent_MakeAvailable(bimg)

file(GLOB_RECURSE SOURCES ${bimg_SOURCE_DIR}/src/**.cpp)
add_library(bimg STATIC)
target_link_libraries(bimg PRIVATE bx)
target_sources(bimg PRIVATE
        ${SOURCES}
)

target_compile_definitions(bimg PRIVATE BX_CONFIG_DEBUG=0)
target_include_directories(bimg PUBLIC
        ${bimg_SOURCE_DIR}/include
        ${bimg_SOURCE_DIR}/3rdparty
        ${bimg_SOURCE_DIR}/3rdparty/astc-encoder/include
        ${bimg_SOURCE_DIR}/3rdparty/iqa/include
        ${bimg_SOURCE_DIR}/3rdparty/tinyexr/deps/miniz
)


FetchContent_Declare(
        bgfx
        GIT_REPOSITORY https://github.com/bkaradzic/bgfx.git
        GIT_TAG master
)
FetchContent_MakeAvailable(bgfx)

file(GLOB_RECURSE SOURCES ${bgfx_SOURCE_DIR}/src/**.cpp)
add_library(bgfx STATIC)
target_link_libraries(bgfx PRIVATE bx bimg)
target_sources(bgfx PRIVATE
        ${SOURCES}
)
target_compile_definitions(bgfx PRIVATE BX_CONFIG_DEBUG=0)
target_include_directories(bgfx PUBLIC
        ${bgfx_SOURCE_DIR}/include
        ${bgfx_SOURCE_DIR}/3rdparty
)