add_library(workc_lib STATIC
        private/num.c
        private/mem.c
)

target_include_directories(workc_lib PRIVATE public)

add_executable(workc_lib_test test.c)

target_link_libraries(workc_lib_test PRIVATE workc_lib)