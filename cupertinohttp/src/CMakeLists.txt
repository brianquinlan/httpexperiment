cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

set(CMAKE_OSX_DEPLOYMENT_TARGET "10.11" CACHE STRING "Minimum OS X deployment version")

# Set RUNPATH for mylib_dylib so it knows where to dynamically load its dependency.
if(UNIX AND NOT APPLE)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    set(CMAKE_INSTALL_RPATH "$ORIGIN/")
endif()

project(mylib_dylib_library VERSION 0.0.1 LANGUAGES C)

add_library(
    mylib_dylib_dependency
    SHARED
    mylib_dylib_dependency.c
)

set_target_properties(mylib_dylib_dependency PROPERTIES
    PUBLIC_HEADER mylib_dylib_dependency.h
    OUTPUT_NAME "mylib_dylib_dependency"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "no"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
    # Set the install name of the dylib to the path of where it will be in the app bundle.
    XCODE_ATTRIBUTE_LD_DYLIB_INSTALL_NAME "@executable_path/Frameworks/libmylib_dylib_dependency.dylib"
)

add_library(
    mylib_dylib
    SHARED
    mylib_dylib.c
    dart-sdk/include/dart_api_dl.c
)

set_target_properties(mylib_dylib PROPERTIES
    PUBLIC_HEADER mylib_dylib.h
    OUTPUT_NAME "mylib_dylib"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED  "no"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
    # Set the install name of the dylib to the path of where it will be in the app bundle.
    XCODE_ATTRIBUTE_LD_DYLIB_INSTALL_NAME "@executable_path/Frameworks/libmylib_dylib.dylib"
)

target_compile_definitions(mylib_dylib PUBLIC DART_SHARED_LIB)
