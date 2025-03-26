
set(BIN_APP_DIR ${CMAKE_BINARY_DIR}/engine/interface/host)

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/src DESTINATION ${BIN_APP_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/pubspec.yaml DESTINATION ${BIN_APP_DIR})

# Dart entry points to start the server and manage the web app at runtime
# -----------------------------------------------------------------------------


find_program(DART_EXE dart)

if(NOT DART_EXE)
    message(FATAL_ERROR "Dart executable not found in path.")
endif ()

if(CMAKE_SYSTEM_NAME STREQUAL Windows)
    set(EXECUTABLE_ENDING .exe)
else ()
    set(EXECUTABLE_ENDING)
endif ()

set(OUTPUT_BINARY ${BIN_APP_DIR}/fireworks_web_host${EXECUTABLE_ENDING})
set(ENTRY_POINT ${BIN_APP_DIR}/src/main.dart)

add_custom_command(
        OUTPUT ${OUTPUT_BINARY}
        COMMAND ${DART_EXE} compile exe ${ENTRY_POINT} -o ${OUTPUT_BINARY}
        WORKING_DIRECTORY ${BIN_APP_DIR}
        COMMENT "Compile interface dart script ${ENTRY_POINT}."
        VERBATIM
)

file(GLOB_RECURSE SOURCE_FILES ${CMAKE_CURRENT_SOURCE_DIR}/src/*)
add_custom_target(interface_web_host
        DEPENDS ${OUTPUT_BINARY}
        SOURCES ${SOURCE_FILES}
)

install(FILES ${OUTPUT_BINARY} DESTINATION ${OUT_BINARY_DIRECTORY})
# -----------------------------------------------------------------------------
