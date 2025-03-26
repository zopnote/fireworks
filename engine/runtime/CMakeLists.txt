
set(RUNTIME_DIR ${PROJECT_SOURCE_DIR}/engine/runtime)


set(PCH ${CMAKE_CURRENT_SOURCE_DIR}/global/stdpch.h)
set(RUNTIME_MODULES_DIR ${RUNTIME_DIR}/modules)

set(RT_SOURCES)
set(RT_INCLUDE_DIRS)

macro(runtime_add_module NAME)
    file(GLOB_RECURSE MODULE_SOURCES ${RUNTIME_MODULES_DIR}/${NAME}/private/**.c)
    set(RT_SOURCES ${RT_SOURCES} ${MODULE_SOURCES})
    set(RT_INCLUDE_DIRS ${RT_INCLUDE_DIRS} ${RUNTIME_MODULES_DIR}/${NAME}/public)
endmacro()

include(vendor/libyaml.cmake)
include(modules/core/core.cmake)

add_library(runtime SHARED ${RT_SOURCES})
target_precompile_headers(runtime PRIVATE global/stdpch.h)
target_include_directories(runtime PUBLIC ${RT_INCLUDE_DIRS})
target_link_libraries(runtime PUBLIC libyaml)
install(TARGETS runtime DESTINATION ${OUT_ENGINE_RT_DIR})


if(PLATFORM_IOS)
    if(CMAKE_SYSTEM_NAME NOT STREQUAL "Darwin")
        message(FATAL_ERROR "Building the engine runtime is only supported on macOS.")
    endif ()
endif()

add_subdirectory(tests)