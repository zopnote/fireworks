set(ENGINE_RUNTIME_DIR ${PROJECT_SOURCE_DIR}/engine/runtime)
set(ENGINE_RUNTIME_MODULES
        core
)
set(preworks_header runtime/stdpch.h)
add_library(preworks_target STATIC ${preworks_header})
set_target_properties(preworks_target PROPERTIES LINKER_LANGUAGE C)
set(ENGINE_RUNTIME_SOURCES)
set(ENGINE_RUNTIME_INCLUDE_DIRS)
foreach (MODULE IN LISTS ENGINE_RUNTIME_MODULES)
    file(GLOB_RECURSE MODULE_SOURCES "${ENGINE_RUNTIME_DIR}/${MODULE}/private/*.c")
    set(ENGINE_RUNTIME_SOURCES ${ENGINE_RUNTIME_SOURCES} ${MODULE_SOURCES})
    set(ENGINE_RUNTIME_INCLUDE_DIRS ${ENGINE_RUNTIME_INCLUDE_DIRS} ${ENGINE_RUNTIME_DIR}/${MODULE}/public)
    add_library(${MODULE} STATIC ${MODULE_SOURCES})
    target_include_directories(${MODULE} PUBLIC ${ENGINE_RUNTIME_DIR}/${MODULE}/public)
    target_precompile_headers(${MODULE} PRIVATE ${preworks_header})
endforeach ()

add_library(${PROJECT_NAME} SHARED ${ENGINE_RUNTIME_SOURCES})
target_include_directories(${PROJECT_NAME} PUBLIC ${ENGINE_RUNTIME_INCLUDE_DIRS})
target_precompile_headers(${PROJECT_NAME} PRIVATE ${preworks_header})

add_subdirectory(runtime/tests)