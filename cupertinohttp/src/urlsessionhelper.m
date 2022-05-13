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
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    maxRedirectsForTask = [NSMapTable weakToStrongObjectsMapTable];
    redirectsForTask = [NSMapTable weakToStrongObjectsMapTable];
  }
  return self;
}

- (void)dealloc {
  [maxRedirectsForTask release];
  [redirectsForTask release];
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

@end
