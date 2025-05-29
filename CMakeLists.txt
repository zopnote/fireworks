cmake_minimum_required(VERSION 4.0.0)
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
project(
        fireworks
        DESCRIPTION "Framework for the creation of 3d graphic programs with a modern development cycle."
        VERSION 1.0
        LANGUAGES C CXX
)


add_subdirectory(packages/cmatic)