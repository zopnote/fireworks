include(FetchContent)

FetchContent_Declare(
        nuklear
        GIT_REPOSITORY https://github.com/Immediate-Mode-UI/Nuklear.git
        GIT_TAG 4.12.6
)
FetchContent_MakeAvailable(nuklear)

file(GLOB SOURCES ${nuklear_SOURCE_DIR}/src/**.c)
set(SOURCES ${SOURCES}
        ${nuklear_SOURCE_DIR}/src/nuklear_internal.h
)
add_library(nuklear STATIC)


target_sources(nuklear PRIVATE
        ${SOURCES}
)

target_include_directories(nuklear PUBLIC
        ${nuklear_SOURCE_DIR}/src
)
