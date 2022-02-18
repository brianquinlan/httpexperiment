# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(cocoahttp_library VERSION 0.0.1 LANGUAGES C)

add_library(cocoahttp SHARED
  "cocoahttp.m"
  "${CMAKE_CURRENT_LIST_DIR}/dart-sdk/include/dart_api_dl.c"
)

set_target_properties(cocoahttp PROPERTIES
  PUBLIC_HEADER cocoahttp.h
  OUTPUT_NAME "cocoahttp"
)

target_compile_definitions(cocoahttp PUBLIC DART_SHARED_LIB)

find_library(APPKIT_LIB AppKit)
target_link_libraries(foo PRIVATE ${APPKIT_LIB})
