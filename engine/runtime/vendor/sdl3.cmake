include(FetchContent)

FetchContent_Declare(
        sdl
        GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
        GIT_TAG release-3.2.10
)
FetchContent_MakeAvailable(sdl)
