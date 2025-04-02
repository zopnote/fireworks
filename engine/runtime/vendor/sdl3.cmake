include(ExternalProject)

ExternalProject_Add(
        sdl
        GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
        GIT_TAG release-3.2.10
        CMAKE_GENERATOR ${CMAKE_GENERATOR}
        CMAKE_ARGS
        $<$<BOOL:${CMAKE_TOOLCHAIN_FILE}>:-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}>
        $<$<BOOL:${ANDROID_NATIVE_API_LEVEL}>:-DANDROID_NATIVE_API_LEVEL=${ANDROID_NATIVE_API_LEVEL}>
        $<$<BOOL:${ANDROID_ABI}>:-DANDROID_ABI=${ANDROID_ABI}>
)