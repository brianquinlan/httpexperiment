#import "urlsessionhelper.h"

#import <Foundation/Foundation.h>

@implementation URLSessionHelper

static Dart_CObject from(void *n) {
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = (int64_t) n;
  return cobj;
}

static Dart_CObject foo(MessageType messageType) {
  Dart_CObject cobj;
  cobj.type = Dart_CObject_kInt64;
  cobj.value.as_int64 = messageType;
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

@implementation TaskConfiguration

- (id) initWithPort:(Dart_Port)sendPort maxRedirects:(uint32_t)redirects {
  self = [super init];
  if (self != nil) {
    self->_sendPort = sendPort;
    self->_maxRedirects = redirects;
  }
  return self;
}

@end

@implementation HttpClientDelegate {
  NSMapTable<NSURLSessionTask *, TaskConfiguration *> *taskConfigurations;
  NSMapTable<NSURLSessionTask *, NSNumber *> *numRedirectsForTask;
}

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    taskConfigurations = [NSMapTable weakToStrongObjectsMapTable];
    numRedirectsForTask = [NSMapTable weakToStrongObjectsMapTable];
  }
  return self;
}

- (void)dealloc {
  [taskConfigurations release];
  [numRedirectsForTask release];
  [super dealloc];
}

- (void)registerTask:(NSURLSessionTask *) task withConfiguration:(TaskConfiguration *)config {
  [taskConfigurations setObject:config forKey:task];
}

- (uint32_t) getNumRedirectsForTask: (NSURLSessionTask *) task {
  NSNumber *redirects = [numRedirectsForTask objectForKey: task];
  if (redirects == nil) {
    return 0;
  } else {
    return [redirects intValue];
  }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
  TaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config != nil) {
    [response retain];

    Dart_CObject ctype = foo(ResponseMessage);
    Dart_CObject cresponse = from(response);
    Dart_CObject* message_carray[] = { &ctype, &cresponse};

    Dart_CObject message_cobj;
    message_cobj.type = Dart_CObject_kArray;
    message_cobj.value.as_array.length = 2;
    message_cobj.value.as_array.values = message_carray;

    const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
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
  TaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
    completionHandler(request);
  }

  uint32_t redirects = [self getNumRedirectsForTask: task] + 1;
  [numRedirectsForTask setObject:@(redirects) forKey:task];

  if ((config.maxRedirects < redirects)) {
    completionHandler(nil);
  } else {
    completionHandler(request);
  }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task
    didReceiveData:(NSData *)data {
  TaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
    return;
  }

  [data retain]; // XXX Leak!!!
  [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {

    Dart_CObject ctype = foo(DataMessage);

    Dart_CObject cdata;
    cdata.type = Dart_CObject_kTypedData;
    cdata.value.as_typed_data.type = Dart_TypedData_kUint8;
    cdata.value.as_typed_data.length = byteRange.length;
    cdata.value.as_typed_data.values = (uint8_t *) bytes;

    Dart_CObject* message_carray[] = { &ctype, &cdata};

    Dart_CObject message_cobj;
    message_cobj.type = Dart_CObject_kArray;
    message_cobj.value.as_array.length = 2;
    message_cobj.value.as_array.values = message_carray;

    const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
    if (!success) {
      printf("%s\n", "Dart_PostCObject_DL failed.");
    }
  }];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
  TaskConfiguration *config = [taskConfigurations objectForKey:task];
  if (config == nil) {
    return;
  }
  
  Dart_CObject ctype = foo(CompletedMessage);
  Dart_CObject cerror;
  if (error != nil) {
    [error retain];
    cerror.type = Dart_CObject_kInt64;
    cerror.value.as_int64 = (int64_t) error;
  } else {
    cerror.type = Dart_CObject_kNull;
  }

  Dart_CObject* message_carray[] = { &ctype, &cerror};

  Dart_CObject message_cobj;
  message_cobj.type = Dart_CObject_kArray;
  message_cobj.value.as_array.length = 2;
  message_cobj.value.as_array.values = message_carray;

  const bool success = Dart_PostCObject_DL(config.sendPort, &message_cobj);
  if (!success) {
    printf("%s\n", "Dart_PostCObject_DL failed.");
  }
}

@end
