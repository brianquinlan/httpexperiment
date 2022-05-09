#include <stdint.h>
#include <stdlib.h>

#if _WIN32
#define MYLIB_EXPORT __declspec(dllexport)
#else
#define MYLIB_EXPORT
#endif

MYLIB_EXPORT intptr_t sum_dylib_dependency(intptr_t a, intptr_t b);
