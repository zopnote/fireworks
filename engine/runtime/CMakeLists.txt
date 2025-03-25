set(ENGINE_RUNTIME_DIR ${PROJECT_SOURCE_DIR}/engine/runtime)
set(ENGINE_RUNTIME_MODULES
        src/core
)
set(stdpch_header include/stdpch.h)
add_library(runtime_stdpch STATIC ${stdpch_header})
set_target_properties(runtime_stdpch PROPERTIES LINKER_LANGUAGE C)
set(ENGINE_RUNTIME_SOURCES)
set(ENGINE_RUNTIME_INCLUDE_DIRS)
foreach (MODULE IN LISTS ENGINE_RUNTIME_MODULES)
    file(GLOB_RECURSE MODULE_SOURCES "${ENGINE_RUNTIME_DIR}/${MODULE}/private/*.c")
    set(ENGINE_RUNTIME_SOURCES ${ENGINE_RUNTIME_SOURCES} ${MODULE_SOURCES})
    set(ENGINE_RUNTIME_INCLUDE_DIRS ${ENGINE_RUNTIME_INCLUDE_DIRS} ${ENGINE_RUNTIME_DIR}/${MODULE}/public)
    add_library(runtime_fireworks_${MODULE} STATIC ${MODULE_SOURCES})
    target_include_directories(runtime_fireworks_${MODULE} PUBLIC ${ENGINE_RUNTIME_DIR}/${MODULE}/public)
    target_precompile_headers(runtime_fireworks_${MODULE} PRIVATE ${stdpch_header})
endforeach ()

add_library(runtime_fireworks SHARED ${ENGINE_RUNTIME_SOURCES})
target_include_directories(runtime_fireworks PUBLIC ${ENGINE_RUNTIME_INCLUDE_DIRS})
target_precompile_headers(runtime_fireworks PRIVATE ${stdpch_header})

add_subdirectory(src/tests)
