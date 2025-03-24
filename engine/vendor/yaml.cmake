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

if (NOT EXISTS ${YAML_DIRECTORY})
    add_custom_target(yaml_clone
            COMMAND git clone https://github.com/zopnote/libyaml.git ${YAML_DIRECTORY} || true
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/_deps
            COMMENT "Cloning libyaml repository"
    )

    add_custom_command(
            OUTPUT ${YAML_SOURCE_FILES}
            COMMENT "Preparing YAML sources"
            DEPENDS yaml_clone
    )
endif ()

add_library(yaml SHARED ${YAML_SOURCE_FILES})

if (NOT EXISTS ${YAML_DIRECTORY})
    add_dependencies(yaml yaml_clone)
endif ()

target_compile_definitions(yaml
        PRIVATE HAVE_CONFIG_H
        PUBLIC
        $<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:YAML_DECLARE_STATIC>
        $<$<BOOL:${MSVC}>:_CRT_SECURE_NO_WARNINGS>
)

set_target_properties(yaml
        PROPERTIES DEFINE_SYMBOL YAML_DECLARE_EXPORT
)

target_include_directories(yaml PUBLIC ${YAML_DIRECTORY}/include)

install(TARGETS yaml
        COMPONENT DESTINATION ${OUT_BINARY_DIRECTORY}
        RUNTIME DESTINATION ${OUT_BINARY_DIRECTORY}
        ARCHIVE DESTINATION ${OUT_LIBRARY_DIRECTORY}
)

