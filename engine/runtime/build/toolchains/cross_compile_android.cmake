
find_program(NDK_EXE ndk-build.cmd)
get_filename_component(ANDROID_NDK ${NDK_EXE} DIRECTORY)

macro(compile_android TARGET API_LEVEL ARCHITECTURE)
    get_target_property(TARGET_SOURCES ${TARGET} SOURCES)
    get_target_property(TARGET_HEADER ${TARGET} INCLUDE_DIRECTORIES)
    get_target_property(TARGET_LIBRARIES ${TARGET} LINK_LIBRARIES)
    if(WIN32)
        set(CROSS_COMPILE_PATH ${ANDROID_NDK}/toolchains/llvm/prebuilt/windows-x86_64)
        set(COMPILE_ENDING .cmd)
    elseif(APPLE)
        set(CROSS_COMPILE_PATH ${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64)
    else()
        set(CROSS_COMPILE_PATH ${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64)
    endif()

    if(${ARCHITECTURE} STREQUAL "armeabi-v7a")
        set(CROSS_COMPILE ${CROSS_COMPILE_PATH}/bin/armv7a-linux-androideabi${API_LEVEL}-clang)
    elseif(${ARCHITECTURE} STREQUAL "arm64-v8a")
        set(CROSS_COMPILE ${CROSS_COMPILE_PATH}/bin/aarch64-linux-android${API_LEVEL}-clang)
    elseif(${ARCHITECTURE} STREQUAL "arm64")
        set(CROSS_COMPILE ${CROSS_COMPILE_PATH}/bin/aarch64-linux-android${API_LEVEL}-clang)
    elseif(${ARCHITECTURE} STREQUAL "x86")
        set(CROSS_COMPILE ${CROSS_COMPILE_PATH}/bin/i686-linux-android${API_LEVEL}-clang)
    elseif(${ARCHITECTURE} STREQUAL "x86_64")
        set(CROSS_COMPILE ${CROSS_COMPILE_PATH}/bin/x86_64-linux-android${API_LEVEL}-clang)
    else()
        message(FATAL_ERROR "Unknown Android ABI: ${ARCHITECTURE}")
    endif()

    set(BUILD_DIR ${CMAKE_BINARY_DIR})
    set(SHARED_LIB_OUTPUT ${BUILD_DIR}/${TARGET}_android${API_LEVEL}_${ARCHITECTURE}.so)

    if(TARGET_LIBRARIES)
        set(LIBRARY_INCLUSION_DIRS)
        foreach (LIBRARY IN LISTS TARGET_LIBRARIES)
            get_target_property(LIBRARY_HEADER ${LIBRARY} INCLUDE_DIRECTORIES)
            set(LIBRARY_INCLUSION_DIRS "${LIBRARY_INCLUSION_DIRS}${LIBRARY_HEADER};")
        endforeach ()
    endif ()
    if(CMAKE_BUILD_TYPE STREQUAL Debug)
        set(OPTIMIZATION "-O0")
        set(DEBUG_SYMBOLS "-g")
    elseif (CMAKE_BUILD_TYPE STREQUAL RelWithDeb)
        set(OPTIMIZATION "-O3")
        set(DEBUG_SYMBOLS "-g")
    else ()
        set(OPTIMIZATION "-O3")
    endif ()
    add_custom_command(
            OUTPUT ${SHARED_LIB_OUTPUT}
            COMMAND ${CROSS_COMPILE}
            -shared
            -o ${SHARED_LIB_OUTPUT}
            -s ${TARGET_SOURCES}
            -include ${PCH}
            -I${LIBRARY_INCLUSION_DIRS}
            -I${TARGET_HEADER}
            -I${CROSS_COMPILE_PATH}/sysroot/usr/include
            -L${CROSS_COMPILE_PATH}/sysroot/usr/lib
            -lc
            -lm
            -ldl
            -llog
            ${DEBUG_SYMBOLS}
            ${OPTIMIZATION}
            DEPENDS ${TARGET_SOURCES}
            WORKING_DIRECTORY ${BUILD_DIR}
            COMMENT "Building shared library for android ${API_LEVEL} ${ARCHITECTURE}"
            VERBATIM
    )

    add_custom_target(${TARGET}_android${API_LEVEL}_${ARCHITECTURE} DEPENDS ${SHARED_LIB_OUTPUT})
    add_dependencies(${TARGET} ${TARGET}_android${API_LEVEL}_${ARCHITECTURE})
    install(FILES ${SHARED_LIB_OUTPUT} DESTINATION ${OUT_BINARY_DIRECTORY})
endmacro()
