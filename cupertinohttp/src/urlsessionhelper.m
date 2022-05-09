#import "urlsessionhelper.h"

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
