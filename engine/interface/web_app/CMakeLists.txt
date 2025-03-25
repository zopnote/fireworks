

# General interface app setup
# -----------------------------------------------------------------------------
set(BIN_INTERFACE_APP_DIR ${CMAKE_BINARY_DIR}/engine/interface/web_app)

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/bin DESTINATION ${BIN_INTERFACE_APP_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/lib DESTINATION ${BIN_INTERFACE_APP_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/web DESTINATION ${BIN_INTERFACE_APP_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/test DESTINATION ${BIN_INTERFACE_APP_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/pubspec.yaml DESTINATION ${BIN_INTERFACE_APP_DIR})
# -----------------------------------------------------------------------------



# Flutter web app as front end for the editor
# -----------------------------------------------------------------------------
find_program(FLUTTER_EXE flutter)

if(NOT FLUTTER_EXE)
    message(FATAL_ERROR "Flutter executable not found in path.")
endif ()

set(FLUTTER_APP_OUTPUT_BINARIES ${BIN_INTERFACE_APP_DIR}/build/web)
set(FLUTTER_APP_ENTRY_POINT ${BIN_INTERFACE_APP_DIR}/lib/main.dart)

add_custom_command(
        OUTPUT ${FLUTTER_APP_OUTPUT_BINARIES}
        COMMAND ${FLUTTER_EXE} build web
        WORKING_DIRECTORY ${BIN_INTERFACE_APP_DIR}
        COMMENT "Compile interface Flutter web app ${FLUTTER_APP_ENTRY_POINT}."
        VERBATIM
)
add_custom_target(interface_web_app
        DEPENDS ${FLUTTER_APP_OUTPUT_BINARIES}
        SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/lib/main.dart
)
install(DIRECTORY ${FLUTTER_APP_OUTPUT_BINARIES} DESTINATION ${OUT_ENGINE_UI_DIR})
# -----------------------------------------------------------------------------




# Dart entry points to start the server and manage the web app at runtime
# -----------------------------------------------------------------------------

set(APP_RUNTIME_STANDALONE_ENTRY_POINTS
        start_server
)


find_program(DART_EXE dart)
if(NOT DART_EXE)
    message(FATAL_ERROR "Dart executable not found in path.")
endif ()
set(APP_RUNTIME_STANDALONE_BINARIES ${CMAKE_CURRENT_SOURCE_DIR}/bin)


if(CMAKE_SYSTEM_NAME STREQUAL Windows)
    set(EXECUTABLE_ENDING .exe)
else ()
    set(EXECUTABLE_ENDING)
endif ()
set(ENTRY_POINT_BINARIES)
foreach(ENTRY_POINT IN LISTS APP_RUNTIME_STANDALONE_ENTRY_POINTS)
    set(ENTRY_POINT_DART_OUTPUT ${BIN_INTERFACE_APP_DIR}/${ENTRY_POINT}${EXECUTABLE_ENDING})
    set(ENTRY_POINT_DART_INPUT ${BIN_INTERFACE_APP_DIR}/bin/${ENTRY_POINT}.dart)
    set(ENTRY_POINT_BINARIES ${ENTRY_POINT_BINARIES} ${ENTRY_POINT_DART_OUTPUT})
    add_custom_command(
            OUTPUT ${ENTRY_POINT_DART_OUTPUT}
            COMMAND ${DART_EXE} compile exe ${ENTRY_POINT_DART_INPUT} -o ${ENTRY_POINT_DART_OUTPUT}
            WORKING_DIRECTORY ${BIN_INTERFACE_APP_DIR}
            COMMENT "Compile interface dart script ${ENTRY_POINT}."
            VERBATIM
    )
    add_custom_target(interface_web_tools_${ENTRY_POINT}
        DEPENDS ${ENTRY_POINT_DART_OUTPUT}
        SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/bin/${ENTRY_POINT}.dart
    )
    install(FILES ${ENTRY_POINT_DART_OUTPUT} DESTINATION ${OUT_ENGINE_UI_DIR})
endforeach ()
# -----------------------------------------------------------------------------

add_custom_target(interface_web_tools
        DEPENDS ${ENTRY_POINT_BINARIES}
)
add_custom_target(interface_web
        DEPENDS ${ENTRY_POINT_BINARIES} ${FLUTTER_APP_OUTPUT_BINARIES}
)