add_library(firelibc STATIC
        private/num.c
        private/mem.c
)

target_include_directories(firelibc PRIVATE public)

add_executable(firelibc_test test.c)

target_link_libraries(firelibc_test PRIVATE firelibc)