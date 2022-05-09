#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#include "dart-sdk/include/dart_api_dl.h"

#if _WIN32
#define MYLIB_EXPORT __declspec(dllexport)
#else
#define MYLIB_EXPORT
#endif

MYLIB_EXPORT intptr_t sum_dylib(intptr_t a, intptr_t b);

MYLIB_EXPORT void sum_dylib_async(Dart_Port dart_port, intptr_t a, intptr_t b);
