include(FetchContent)

FetchContent_Declare(
        nuklear
        GIT_REPOSITORY https://github.com/Immediate-Mode-UI/Nuklear.git
        GIT_TAG 4.12.6
)
FetchContent_MakeAvailable(nuklear)

file(GLOB SOURCES ${nuklear_SOURCE_DIR}/src/**.c)
add_library(nuklear STATIC)
set_property(TARGET nuklear PROPERTY C_STANDARD 90)

target_sources(nuklear PRIVATE
        ${SOURCES}
)

target_compile_definitions(nuklear PUBLIC NK_IMPLEMENTATION)
target_include_directories(nuklear PUBLIC
        ${nuklear_SOURCE_DIR}/src
)
