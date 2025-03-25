add_executable(runtime_${PROJECT_NAME}_tests_main main_test.c)
target_link_libraries(runtime_${PROJECT_NAME}_tests_main runtime_${PROJECT_NAME}_core)