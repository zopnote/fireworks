add_library(cmatic STATIC
        private/mem.c
)

target_include_directories(cmatic PRIVATE public)

add_executable(cmatic_test test/test.c)

target_link_libraries(cmatic_test PRIVATE cmatic)