cmake_minimum_required(VERSION 3.28)

if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
    message(FATAL_ERROR "In-source builds are not allowed.")
endif()

project(test_cmake LANGUAGES CXX)
enable_language(CXX)
enable_testing()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)

if(${CMAKE_CXX_COMPILER_ID} STREQUAL GNU OR ${CMAKE_CXX_COMPILER_ID} STREQUAL Clang)
    add_compile_options(-Wall -Wextra -Wconversion -Wsign-conversion)
    add_compile_options(-march=native $<$<CONFIG:Release,MinSizeRel>:-fomit-frame-pointer>)
    add_link_options($<$<CONFIG:Release,MinSizeRel>:-s>)  # Strip executable
elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL MSVC)
    add_compile_options(/W4)
endif()

add_library(dancing_links STATIC linked_matrix.cpp dancing_links.cpp)
link_libraries(dancing_links)
add_subdirectory(tests)
