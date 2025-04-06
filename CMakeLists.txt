cmake_minimum_required(VERSION 3.20)



# -----------------------------------------------------------------------------
project(fireworks
        DESCRIPTION "Modern cross-platform graphics engine framework."
        VERSION 0.1
        LANGUAGES C CXX
)
# -----------------------------------------------------------------------------




# Language related
# -----------------------------------------------------------------------------

set(CMAKE_C_STANDARD 23)
set(CMAKE_CXX_STANDARD 23)
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug)
endif()

set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)


# -----------------------------------------------------------------------------





# Centralized structure configuration. Note that this will be hard coded in the output binaries.
# -----------------------------------------------------------------------------
set(FIREWORKS_INSTALL_BINARIES ${CMAKE_INSTALL_PREFIX}/bin)
set(FIREWORKS_INSTALL_WEB_VIEW ${CMAKE_INSTALL_PREFIX}/editor)
set(FIREWORKS_INSTALL_PACKAGES ${CMAKE_INSTALL_PREFIX}/packages)
set(FIREWORKS_INSTALL_RUNTIME_HEADER ${CMAKE_INSTALL_PREFIX}/include)

string(TOLOWER ${CMAKE_SYSTEM_NAME} CMAKE_SYSTEM_NAME_LOWER)
set(FIREWORKS_INSTALL_RUNTIME_LIBS
        ${CMAKE_INSTALL_PREFIX}/lib/${CMAKE_SYSTEM_NAME_LOWER}-${CMAKE_SYSTEM_PROCESSOR}
)

install(FILES license.md DESTINATION .)
install(FILES readme.md DESTINATION .)
# -----------------------------------------------------------------------------




add_subdirectory(runner)
add_subdirectory(editor)
add_subdirectory(engine)