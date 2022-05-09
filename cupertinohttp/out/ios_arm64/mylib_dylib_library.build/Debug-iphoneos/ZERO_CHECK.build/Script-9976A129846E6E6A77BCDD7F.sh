#!/bin/sh
set -e
if test "$CONFIGURATION" = "Debug"; then :
  cd /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm64
  make -f /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm64/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "Release"; then :
  cd /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm64
  make -f /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm64/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "MinSizeRel"; then :
  cd /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm64
  make -f /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm64/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "RelWithDebInfo"; then :
  cd /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm64
  make -f /Users/bquinlan/dart/httpexperiment/cupertinohttp/out/ios_arm64/CMakeScripts/ReRunCMake.make
fi

