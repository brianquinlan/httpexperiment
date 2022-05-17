#import "urlsessionhelper.h"

#import <Foundation/Foundation.h>

@implementation URLSessionHelper

static Dart_CObject from(void *n) {
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = (int64_t) n;
  return cobj;
}

+ (NSURLSessionDataTask *)dataTaskForSession:(NSURLSession *)session
                                 withRequest:(NSURLRequest *)request
                                      toPort: (Dart_Port) dart_port {
  //    printf("dataTaskForSession\n");

  //    [[URLSessionDelegate new] someMethod];
  NSURLSessionDataTask *downloadTask = [session
                                        dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response,
                                                            NSError *error) {

    [data retain];
    [response retain];
    [error retain];

    Dart_CObject cdata = from(data);
    Dart_CObject cresponse = from(response);
    Dart_CObject cerror = from(error);
    Dart_CObject* message_carray[] = { &cdata, &cresponse, &cerror};

    Dart_CObject message_cobj;
    message_cobj.type = Dart_CObject_kArray;
    message_cobj.value.as_array.length = 3;
    message_cobj.value.as_array.values = message_carray;

    const bool success = Dart_PostCObject_DL(dart_port, &message_cobj);
    if (!success) {
      printf("%s\n", "Dart_PostCObject_DL failed.");
    }
  }];
  return downloadTask;
}

@end

@implementation HttpClientDelegate {
  NSMapTable<NSURLSessionTask *, NSNumber *> *maxRedirectsForTask;
  NSMapTable<NSURLSessionTask *, NSNumber *> *redirectsForTask;
  NSMapTable<NSURLSessionTask *, NSNumber *> *dataPortForTask;
  NSMapTable<NSURLSessionTask *, NSNumber *> *responsePortForTask;
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    maxRedirectsForTask = [NSMapTable weakToStrongObjectsMapTable];
    redirectsForTask = [NSMapTable weakToStrongObjectsMapTable];
    dataPortForTask = [NSMapTable weakToStrongObjectsMapTable];
    responsePortForTask = [NSMapTable weakToStrongObjectsMapTable];
  }
  return self;
}

- (void)dealloc {
  [maxRedirectsForTask release];
  [redirectsForTask release];
  [dataPortForTask release];
  [responsePortForTask release];
  [super dealloc];
}

- (void) setMaxRedirects: (uint32_t)max forTask: (NSURLSessionTask *) task {
  [maxRedirectsForTask setObject:@(max) forKey:task];
}

- (uint32_t) getRedirectsForTask: (NSURLSessionTask *) task {
  NSNumber *redirects = [redirectsForTask objectForKey: task];
  if (redirects == nil) {
    return 0;
  } else {
    return [redirects intValue];
  }
}

- (void)setDataPort:(Dart_Port) dart_port forTask: (NSURLSessionTask *) task {
  [task retain]; // LEAK.
  [dataPortForTask setObject:@(dart_port) forKey:task];
}

- (Dart_Port) getDataPortForTask: (NSURLSessionTask *) task {
  NSNumber *port = [dataPortForTask objectForKey: task];
  if (port == nil) {
    return ILLEGAL_PORT;
  } else {
    return [port longLongValue];
  }
}

- (void)setResponsePort:(Dart_Port) dart_port forTask: (NSURLSessionTask *) task {
  [responsePortForTask setObject:@(dart_port) forKey:task];

}

- (Dart_Port) getResponsePortForTask: (NSURLSessionTask *) task {
  NSNumber *port = [responsePortForTask objectForKey: task];
  if (port == nil) {
    return ILLEGAL_PORT;
  } else {
    return [port longLongValue];
  }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  Dart_Port port = [self getResponsePortForTask:dataTask];
  if (port != ILLEGAL_PORT) {
    [response retain];

    Dart_CObject message_cobj;
    message_cobj.type = Dart_CObject_kInt64;
    message_cobj.value.as_int64 = (int64_t) response;

    const bool success = Dart_PostCObject_DL(port, &message_cobj);
    if (!success) {
      printf("%s\n", "Dart_PostCObject_DL failed.");
    }
  }

  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest *))completionHandler API_AVAILABLE(ios(7.0)) {
  NSNumber *maxRedirects = [maxRedirectsForTask objectForKey: task];
  int32_t redirects = [self getRedirectsForTask: task] + 1;
  [redirectsForTask setObject:@(redirects) forKey:task];

  if ((maxRedirects != nil) && ([maxRedirects intValue] < redirects)) {
    completionHandler(nil);
  } else {
    completionHandler(request);
  }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  Dart_Port port = [self getDataPortForTask:dataTask];
  if (port != ILLEGAL_PORT) {
    [data retain]; // XXX Leak!!!
    [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
      Dart_CObject message_cobj;
      message_cobj.type = Dart_CObject_kTypedData;
      message_cobj.value.as_typed_data.type = Dart_TypedData_kUint8;
      message_cobj.value.as_typed_data.length = byteRange.length;
      message_cobj.value.as_typed_data.values = (uint8_t *) bytes;

      const bool success = Dart_PostCObject_DL(port, &message_cobj);
      if (!success) {
        printf("%s\n", "Dart_PostCObject_DL failed.");
      }
    }];
  }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
  Dart_Port port = [self getDataPortForTask:task];
  if (port != ILLEGAL_PORT) {

    if (error != nil) {
      [error retain];
    }
    Dart_CObject message_cobj;
    message_cobj.type = Dart_CObject_kInt64;
    message_cobj.value.as_int64 = (int64_t) error;

    const bool success = Dart_PostCObject_DL(port, &message_cobj);
    if (!success) {
      printf("%s\n", "Dart_PostCObject_DL failed.");
    }
  }

  if (error == nil) {
  } else {

  }
}

@end
