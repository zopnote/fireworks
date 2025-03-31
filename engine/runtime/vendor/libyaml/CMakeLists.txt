set(LIBYAML_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
set(YAML_SOURCE_FILES
        ${LIBYAML_DIRECTORY}/src/api.c
        ${LIBYAML_DIRECTORY}/src/dumper.c
        ${LIBYAML_DIRECTORY}/src/emitter.c
        ${LIBYAML_DIRECTORY}/src/loader.c
        ${LIBYAML_DIRECTORY}/src/parser.c
        ${LIBYAML_DIRECTORY}/src/reader.c
        ${LIBYAML_DIRECTORY}/src/scanner.c
        ${LIBYAML_DIRECTORY}/src/writer.c
)

if(${CMAKE_SYSTEM_NAME} STREQUAL "Emscripten")
        add_library(yaml STATIC ${YAML_SOURCE_FILES})
else ()
        add_library(yaml SHARED ${YAML_SOURCE_FILES})
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

target_include_directories(yaml PUBLIC ${LIBYAML_DIRECTORY}/include)

