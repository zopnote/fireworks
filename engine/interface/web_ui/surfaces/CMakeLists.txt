
# General interface app setup
# -----------------------------------------------------------------------------
set(BIN_APP_DIR ${CMAKE_BINARY_DIR}/engine/interface/surfaces)

file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/lib DESTINATION ${BIN_APP_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/web DESTINATION ${BIN_APP_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/test DESTINATION ${BIN_APP_DIR})
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/pubspec.yaml DESTINATION ${BIN_APP_DIR})
# -----------------------------------------------------------------------------



# Flutter web app as front end for the editor
# -----------------------------------------------------------------------------
find_program(FLUTTER_EXE flutter)

if(NOT FLUTTER_EXE)
    message(FATAL_ERROR "Flutter executable not found in path.")
endif ()

set(OUTPUT_BINARIES ${BIN_APP_DIR}/build/web)
set(ENTRY_POINT ${BIN_APP_DIR}/lib/main.dart)

add_custom_command(
        OUTPUT ${OUTPUT_BINARIES}
        COMMAND ${FLUTTER_EXE} build web
        WORKING_DIRECTORY ${BIN_APP_DIR}
        COMMENT "Compile interface Flutter web app ${ENTRY_POINT}."
        VERBATIM
)
file(GLOB_RECURSE SOURCE_FILES ${CMAKE_CURRENT_SOURCE_DIR}/lib/*)
add_custom_target(interface_web_ui_surfaces
        DEPENDS ${OUTPUT_BINARIES}
        SOURCES ${SOURCE_FILES}
)

install(DIRECTORY ${OUTPUT_BINARIES} DESTINATION ${OUT_ENGINE_UI_DIR}/surfaces)
# -----------------------------------------------------------------------------