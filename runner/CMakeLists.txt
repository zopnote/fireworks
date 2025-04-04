find_program(GO_EXECUTABLE go)
if (NOT GO_EXECUTABLE)
    message(FATAL_ERROR "The runner requires go for building.")
endif ()

if (CMAKE_SYSTEM_NAME STREQUAL Windows)
    set(EXE_ENDING .exe)
endif ()

set(OUTPUT_BINARY_PATH ${CMAKE_BINARY_DIR}/fireworks${EXE_ENDING})

add_custom_command(
        COMMAND ${CMAKE_COMMAND} -E echo "Building runner..."
        COMMAND ${GO_EXECUTABLE} build -o ${OUTPUT_BINARY_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/main.go
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT ${OUTPUT_BINARY_PATH}
)

add_custom_target(runner
    DEPENDS ${OUTPUT_BINARY_PATH}
)

install(FILES ${OUTPUT_BINARY_PATH} DESTINATION ${FIREWORKS_INSTALL_BINARIES})
add_subdirectory(packages)