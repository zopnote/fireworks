find_package(Python3 REQUIRED)
find_program(PYINSTALLER pyinstaller)

if (NOT PYINSTALLER)
    message(STATUS "Python package pyinstaller not found.")
    execute_process(
            COMMAND ${CMAKE_COMMAND} -E echo "Installing pyinstaller..."
            COMMAND pip install pyinstaller
            RESULT_VARIABLE INSTALL_RESULT
            OUTPUT_QUIET
            ERROR_QUIET
    )

    if (INSTALL_RESULT EQUAL 0)
        message(STATUS "PyInstaller was successfully installed.")
    else()
        message(FATAL_ERROR "Error occurred while installing pyinstaller!")
    endif()

    find_program(PYINSTALLER pyinstaller)
endif()

if (NOT PYINSTALLER)
    message(FATAL_ERROR "Pyinstaller still cannot be found.")
endif()

set(OUTPUT_DIRECTORY_PATH ${CMAKE_BINARY_DIR}/dev/gen_docs)
set(OUTPUT_BINARY_NAME gen_docs)
if (CMAKE_SYSTEM_NAME STREQUAL Windows)
    set(EXE_ENDING .exe)
endif ()
add_custom_command(
        COMMAND ${CMAKE_COMMAND} -E echo "Installing gen_docs"
        COMMAND ${PYINSTALLER}
        --onefile
        --name=${OUTPUT_BINARY_NAME}
        --add-data="${CMAKE_CURRENT_SOURCE_DIR}/assets/*:assets"
        --workpath=${OUTPUT_DIRECTORY_PATH}
        --specpath=${OUTPUT_DIRECTORY_PATH}
        --distpath=${OUTPUT_DIRECTORY_PATH}
        ${CMAKE_CURRENT_SOURCE_DIR}/src/main.py
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT ${OUTPUT_DIRECTORY_PATH}/${OUTPUT_BINARY_NAME}${EXE_ENDING}
)
add_custom_target(gen_docs
    DEPENDS ${OUTPUT_DIRECTORY_PATH}/${OUTPUT_BINARY_NAME}${EXE_ENDING}
)
install(FILES ${OUTPUT_DIRECTORY_PATH}/${OUTPUT_BINARY_NAME}${EXE_ENDING} DESTINATION ${OUT_BINARY_DIRECTORY})