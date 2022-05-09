#!/bin/sh
set -e
if test "$CONFIGURATION" = "Debug"; then :
  cd /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm
  /opt/homebrew/Cellar/cmake/3.23.1/bin/cmake -E cmake_symlink_library /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/Debug${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/Debug${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/Debug${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib
fi
if test "$CONFIGURATION" = "Release"; then :
  cd /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm
  /opt/homebrew/Cellar/cmake/3.23.1/bin/cmake -E cmake_symlink_library /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/Release${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/Release${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/Release${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib
fi
if test "$CONFIGURATION" = "MinSizeRel"; then :
  cd /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm
  /opt/homebrew/Cellar/cmake/3.23.1/bin/cmake -E cmake_symlink_library /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/MinSizeRel${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/MinSizeRel${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/MinSizeRel${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib
fi
if test "$CONFIGURATION" = "RelWithDebInfo"; then :
  cd /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm
  /opt/homebrew/Cellar/cmake/3.23.1/bin/cmake -E cmake_symlink_library /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/RelWithDebInfo${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/RelWithDebInfo${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm/RelWithDebInfo${EFFECTIVE_PLATFORM_NAME}/libmylib_dylib.dylib
fi

