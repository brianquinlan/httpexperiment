#include "mylib_dylib.h"

#if !_WIN32
#include <dlfcn.h>
#else
#include <windows.h>
#endif
#include <stdio.h>

MYLIB_EXPORT intptr_t sum_dylib(intptr_t a, intptr_t b) {
#if _WIN32
  const LPCWSTR shared_library_path = L"mylib_dylib_dependency.dll";
#elif __APPLE__
  const char *shared_library_path =
      "@loader_path/libmylib_dylib_dependency.dylib";
#else
  const char *shared_library_path = "libmylib_dylib_dependency.so";
#endif
  const char *symbol = "sum_dylib_dependency";

#if !_WIN32
  void *library_handle = dlopen(shared_library_path, RTLD_LAZY);
  if (library_handle == NULL) {
    const char *error = dlerror();
    printf("dlopen of '%s' failed with '%s'.\n", shared_library_path, error);
    return -1;
  }
  const void *symbol_handle = dlsym(library_handle, symbol);
  const char *error = dlerror();
  if (error != NULL) {
    printf("dlsym of '%s' failed with '%s'.\n", symbol, error);
    return -2;
  }

#else
  SetLastError(0); // Clear any errors.
  // TODO(dacoharkes): Opening relative does not seem to work yet.
  HMODULE handle = LoadLibraryW(shared_library_path);
  if (handle == NULL) {
    const int error = GetLastError();
    printf("LoadLibraryW failed with error code %d\n", error);
    return -1;
  }

  void *symbol_handle = (void *)GetProcAddress(handle, symbol);
  if (symbol_handle == NULL) {
    const int error = GetLastError();
    printf("GetProcAddress failed with error code %d.\n", error);
    return -2;
  }
#endif

  intptr_t (*sum_dependency)(intptr_t, intptr_t) = symbol_handle;

  return sum_dependency(a, b);
}

// Below is an async sample using pthreads on unix systems and CreateThread
// on Windows (this is a C program).
//
// When using C++ prefer using platform independent threads
// (e.g. std::thread).
#if _WIN32
#define THREAD_RETURN_TYPE DWORD WINAPI
#define THREAD_RETURN return 0
#define THREAD_CREATE(func, data) CreateThread(NULL, 0, func, data, 0, NULL)
#define SLEEP(milliseconds) Sleep(milliseconds)
#else
#define THREAD_RETURN_TYPE void *
#define THREAD_RETURN                                                          \
  pthread_exit(NULL);                                                          \
  return NULL
#define THREAD_CREATE(func, data)                                              \
  pthread_t pthread;                                                           \
  pthread_create(&pthread, NULL, &func, data);                                 \
  pthread_detach(pthread)
#define SLEEP(milliseconds) usleep(milliseconds * 1000)
#endif

typedef struct {
  Dart_Port dart_port;
  intptr_t a;
  intptr_t b;
} ThreadData;

THREAD_RETURN_TYPE run_async(void *parameter) {
  if (Dart_PostCObject_DL == 0x0) {
    printf("Dart_PostCObject_DL is not initialized! "
           "Call Dart_InitializeApiDL. %p %p\n",
           Dart_PostCObject_DL, &Dart_PostCObject_DL);
    THREAD_RETURN;
  }

  // Simulate work.
  SLEEP(1000);

  ThreadData *data = (ThreadData *)parameter;
  Dart_CObject dart_cobject;
  dart_cobject.type = Dart_CObject_kInt64;
  dart_cobject.value.as_int64 = data->a + data->b;
  const bool success = Dart_PostCObject_DL(data->dart_port, &dart_cobject);
  if (!success) {
    printf("%s\n", "Dart_PostCObject_DL failed.");
  }

  free(data);

  THREAD_RETURN;
}

MYLIB_EXPORT void sum_dylib_async(Dart_Port dart_port, intptr_t a, intptr_t b) {
  ThreadData *data = (ThreadData *)malloc(sizeof(ThreadData));
  data->dart_port = dart_port;
  data->a = a;
  data->b = b;
  THREAD_CREATE(run_async, (void *)data);
}
