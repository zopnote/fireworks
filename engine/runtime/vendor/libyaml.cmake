set(YAML_DIRECTORY ${CMAKE_BINARY_DIR}/_deps/libyaml)

set(YAML_SOURCE_FILES
        ${CMAKE_BINARY_DIR}/_deps/libyaml/src/api.c
        ${CMAKE_BINARY_DIR}/_deps/libyaml/src/dumper.c
        ${CMAKE_BINARY_DIR}/_deps/libyaml/src/emitter.c
        ${CMAKE_BINARY_DIR}/_deps/libyaml/src/loader.c
        ${CMAKE_BINARY_DIR}/_deps/libyaml/src/parser.c
        ${CMAKE_BINARY_DIR}/_deps/libyaml/src/reader.c
        ${CMAKE_BINARY_DIR}/_deps/libyaml/src/scanner.c
        ${CMAKE_BINARY_DIR}/_deps/libyaml/src/writer.c
)
if (NOT EXISTS ${CMAKE_BINARY_DIR}/_deps)
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/_deps)
endif ()

if (NOT EXISTS ${YAML_DIRECTORY})
    add_custom_target(vendor_yaml_clone
            COMMAND git clone https://github.com/zopnote/libyaml.git ${YAML_DIRECTORY} || true
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/_deps
            COMMENT "Cloning libyaml repository"
    )

    add_custom_command(
            OUTPUT ${YAML_SOURCE_FILES}
            COMMENT "Preparing YAML sources"
            DEPENDS vendor_yaml_clone
    )
endif ()

add_library(libyaml SHARED ${YAML_SOURCE_FILES})

if (NOT EXISTS ${YAML_DIRECTORY})
    add_dependencies(libyaml vendor_yaml_clone)
endif ()

target_compile_definitions(libyaml
        PRIVATE HAVE_CONFIG_H
        PUBLIC
        $<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:YAML_DECLARE_STATIC>
        $<$<BOOL:${MSVC}>:_CRT_SECURE_NO_WARNINGS>
)

set_target_properties(libyaml
        PROPERTIES DEFINE_SYMBOL YAML_DECLARE_EXPORT
)

target_include_directories(libyaml PUBLIC ${YAML_DIRECTORY}/include)

install(TARGETS libyaml
        RUNTIME DESTINATION ${OUT_ENGINE_RT_DIR}
)

