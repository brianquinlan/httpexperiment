#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "dart-sdk/include/dart_api_dl.h"

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

FFI_PLUGIN_EXPORT void sum(Dart_Port dart_port, const char* uri);
// FFI_PLUGIN_EXPORT intptr_t InitDartApiDL(void* data);
