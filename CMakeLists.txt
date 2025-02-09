cmake_minimum_required(VERSION 3.23)

# Conan setup
include(${CMAKE_BINARY_DIR}/conan_toolchain.cmake)

# Project versions
file(READ "include/khaiii/khaiii_api.h" KHAIII_VERSION_HEADER)
string(REGEX MATCH "#define[ \t]+KHAIII_VERSION_MAJOR[ \t]+([0-9]+)" _KHAIII_VERSION_MAJOR "${KHAIII_VERSION_HEADER}")
set(KHAIII_VERSION_MAJOR ${CMAKE_MATCH_1} CACHE STRING "major version" FORCE)
string(REGEX MATCH "#define[ \t]+KHAIII_VERSION_MINOR[ \t]+([0-9]+)" _KHAIII_VERSION_MINOR "${KHAIII_VERSION_HEADER}")
set(KHAIII_VERSION_MINOR ${CMAKE_MATCH_1} CACHE STRING "minor version" FORCE)
set(KHAIII_VERSION ${KHAIII_VERSION_MAJOR}.${KHAIII_VERSION_MINOR} CACHE STRING "version" FORCE)

# Project definition
project(khaiii VERSION ${KHAIII_VERSION} LANGUAGES CXX)

# Project options

# Fused multiply add
option(FMA "Fused Multiply Add" ON)
if(FMA)
    message(STATUS "[khaiii] fused multiplty add option enabled")
    include("cmake/FusedMultiplyAdd.cmake")
endif()

# Profile
option(PROFILER "Profiler" OFF)
if(PROFILER)
    message(STATUS "[khaiii] profiler option enabled")
    include("cmake/FindGperftools.cmake")
    add_definitions(-DPROFILER)
endif()

# Code coverage
option(COVERAGE "Code coverage" OFF)
if(COVERAGE AND CMAKE_COMPILER_IS_GNUCXX)
    message(STATUS "[khaiii] coverage option enabled")
    set(CMAKE_BUILD_TYPE Debug)
    include(cmake/CodeCoverage.cmake)
    APPEND_COVERAGE_COMPILER_FLAGS()
endif()

set(CMAKE_DEBUG_POSTFIX "_debug")

# Extern dependencies
find_package(Boost CONFIG REQUIRED)
find_package(cxxopts CONFIG REQUIRED)
find_package(Eigen3 CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)
find_package(GTest CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(Threads REQUIRED)

# Language requirements
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
add_definitions(-DFMT_HEADER_ONLY)

# Release profile
if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_definitions(-O3)
    add_definitions(-g)
    add_definitions(-funroll-loops)
endif()

# Includes interface
add_library(khaiii_includes INTERFACE)
target_include_directories(khaiii_includes INTERFACE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/src/main/cpp
    ${Boost_INCLUDE_DIRS}
    ${Eigen3_INCLUDE_DIRS}
    ${nlohmann_json_INCLUDE_DIRS}
)

# Project main objects
add_library(obj_khaiii OBJECT
        src/main/cpp/khaiii/Config.cpp
        src/main/cpp/khaiii/Embed.cpp
        src/main/cpp/khaiii/ErrPatch.cpp
        src/main/cpp/khaiii/KhaiiiImpl.cpp
        src/main/cpp/khaiii/Morph.cpp
        src/main/cpp/khaiii/Preanal.cpp
        src/main/cpp/khaiii/Resource.cpp
        src/main/cpp/khaiii/Restore.cpp
        src/main/cpp/khaiii/Sentence.cpp
        src/main/cpp/khaiii/Tagger.cpp
        src/main/cpp/khaiii/Trie.cpp
        src/main/cpp/khaiii/Word.cpp
        src/main/cpp/khaiii/khaiii_api.cpp
        src/main/cpp/khaiii/khaiii_dev.cpp
        src/main/cpp/khaiii/nn/Conv1d.cpp
        src/main/cpp/khaiii/nn/Linear.cpp
        src/main/cpp/khaiii/nn/tensor.cpp)
target_include_directories(obj_khaiii PUBLIC $<TARGET_PROPERTY:khaiii_includes,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_definitions(obj_khaiii PUBLIC -DPREFIX="${CMAKE_INSTALL_PREFIX}")

# Library: libkhaiii.so
add_library(khaiii SHARED $<TARGET_OBJECTS:obj_khaiii>)
set_target_properties(khaiii PROPERTIES
        VERSION ${KHAIII_VERSION}
        SOVERSION ${KHAIII_VERSION_MAJOR}
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
target_link_libraries(khaiii PRIVATE khaiii_includes)

# Executable: bin/khaiii
add_executable(bin_khaiii
        $<TARGET_OBJECTS:obj_khaiii>
        src/main/cpp/main.cpp)
set_target_properties(bin_khaiii PROPERTIES
        OUTPUT_NAME khaiii
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
target_link_libraries(bin_khaiii PRIVATE
        cxxopts::cxxopts
        ${GPERFTOOLS_PROFILER}
        ${CMAKE_THREAD_LIBS_INIT}
        khaiii_includes)

# Test executable: test_khaiii
add_executable(test_khaiii
        $<TARGET_OBJECTS:obj_khaiii>
        src/test/cpp/test_main.cpp
        src/test/cpp/khaiii/ErrPatchTest.cpp
        src/test/cpp/khaiii/KhaiiiApiTest.cpp
        src/test/cpp/khaiii/KhaiiiDevTest.cpp
        src/test/cpp/khaiii/PreanalTest.cpp)
set_target_properties(test_khaiii PROPERTIES
        OUTPUT_NAME khaiii
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/test)
target_include_directories(test_khaiii PRIVATE
        src/test/cpp)
target_link_libraries(test_khaiii PRIVATE
        GTest::gtest
        cxxopts::cxxopts
        ${GPERFTOOLS_PROFILER}
        ${CMAKE_THREAD_LIBS_INIT}
        khaiii_includes)
if(COVERAGE AND CMAKE_COMPILER_IS_GNUCXX)
    target_link_libraries(test_khaiii PRIVATE gcov)
endif()

# Target resource
add_custom_target(resource
        COMMAND make PREFIX=${CMAKE_BINARY_DIR} -C ${CMAKE_SOURCE_DIR}/rsc)
add_custom_target(large_resource
        COMMAND make PREFIX=${CMAKE_BINARY_DIR} MODEL_SIZE=large -C ${CMAKE_SOURCE_DIR}/rsc)

# Target test
enable_testing()
add_test(NAME test_khaiii COMMAND $<TARGET_FILE:test_khaiii> "--rsc-dir=${CMAKE_BINARY_DIR}/share/khaiii")

# Target install
install(TARGETS khaiii bin_khaiii
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/include/khaiii DESTINATION include)
install(DIRECTORY ${CMAKE_BINARY_DIR}/share/khaiii DESTINATION share/khaiii)

# Project package
set(CPACK_GENERATOR TGZ)
set(CPACK_PACKAGE_VENDOR "Kakao Corp.")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Kakao Hangul Analyzer III")
set(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE)
set(CPACK_RESOURCE_FILE_README ${CMAKE_CURRENT_SOURCE_DIR}/README.md)
set(CPACK_SOURCE_GENERATOR ZIP)
set(CPACK_SOURCE_PACKAGE_FILE_NAME ${CMAKE_PROJECT_NAME}-${KHAIII_VERSION})
set(CPACK_SOURCE_IGNORE_FILES
        "/\\\\..*"
        "/.*build.*/"
        "/train/"
        "__pycache__"
        ".*\\\\.pyc"
        ${CPACK_SOURCE_IGNORE_FILES})
include(CPack)

# Python package
set(PKG_PY_DIR ${CMAKE_BINARY_DIR}/package_python)
add_custom_target(package_python
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_SOURCE_DIR}/README.md ${PKG_PY_DIR}/README.md
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_SOURCE_DIR}/LICENSE ${PKG_PY_DIR}/LICENSE
        COMMAND ${CMAKE_COMMAND} -E make_directory ${PKG_PY_DIR}/khaiii
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_SOURCE_DIR}/src/main/python/khaiii/khaiii.py ${PKG_PY_DIR}/khaiii/khaiii.py
        COMMAND ${CMAKE_COMMAND} -E create_symlink ${CMAKE_SOURCE_DIR}/src/test/python/test_khaiii ${PKG_PY_DIR}/khaiii/test_khaiii
        COMMAND make package_source
        COMMAND ${CMAKE_COMMAND} -E rename ${CPACK_SOURCE_PACKAGE_FILE_NAME}.zip ${PKG_PY_DIR}/${CPACK_SOURCE_PACKAGE_FILE_NAME}.zip)
configure_file(${CMAKE_SOURCE_DIR}/src/main/python/setup.py.in ${PKG_PY_DIR}/setup.py @ONLY)
configure_file(${CMAKE_SOURCE_DIR}/src/main/python/MANIFEST.in.in ${PKG_PY_DIR}/MANIFEST.in @ONLY)
configure_file(${CMAKE_SOURCE_DIR}/src/main/python/khaiii/__init__.py.in ${PKG_PY_DIR}/khaiii/__init__.py @ONLY)