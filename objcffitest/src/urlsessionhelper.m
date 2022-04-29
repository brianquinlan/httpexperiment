#import "urlsessionhelper.h"

/** cc -dynamiclib /Users/bquinlan/./dart/dart-sdk1/sdk/runtime/include/dart_api_dl.c -I./src/dart-sdk/include/  src/urlsessionhelper.m -framework AppKit -lobjc -o urlsessionhelper.dynlib **/

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

/*
FFI_PLUGIN_EXPORT void sum(Dart_Port dart_port, const char* uri) {
  NSURL *url = [NSURL URLWithString:[[NSString alloc] initWithUTF8String:uri]];

  NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
        dataTaskWithURL:url
      completionHandler:^(NSData *data, NSURLResponse *response,
                          NSError *error) {
        NSHTTPURLResponse *httpResponse = nil;
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
          printf("NSHTTPURLResponse has the wrong type.");
        }
        httpResponse = (NSHTTPURLResponse *)response;
        NSDictionary *headers = httpResponse.allHeaderFields;

        Dart_CObject data_cobj;
        data_cobj.type = Dart_CObject_kTypedData;
        data_cobj.value.as_typed_data.type = Dart_TypedData_kUint8;
        data_cobj.value.as_typed_data.length = data.length;
        data_cobj.value.as_typed_data.values = (uint8_t *)data.bytes;

        NSInteger count = [headers count];
        id __unsafe_unretained objects[count];
        id __unsafe_unretained keys[count];
        [headers getObjects:objects andKeys:keys count:count];
        Dart_CObject* headers_carray[count*2];

        for (int i = 0; i < count; i += 2) {
           Memory leak! 
          headers_carray[i] = malloc(sizeof(Dart_CObject));
          headers_carray[i]->type = Dart_CObject_kString;
          headers_carray[i]->value.as_string = ((NSString *) keys[i]).UTF8String;
          headers_carray[i+1] = malloc(sizeof(Dart_CObject));
          headers_carray[i+1]->type = Dart_CObject_kString;
          headers_carray[i+1]->value.as_string = ((NSString *) objects[i]).UTF8String;
        }

        Dart_CObject headers_cobj;
        headers_cobj.type = Dart_CObject_kArray;
        headers_cobj.value.as_array.length = headers.count;
        headers_cobj.value.as_array.values = &headers_carray;

        Dart_CObject message_cobj;
        Dart_CObject* message_carray[] = {&data_cobj, &headers_cobj};
        message_cobj.type = Dart_CObject_kArray;
        message_cobj.value.as_array.length = 2;
        message_cobj.value.as_array.values = &message_carray;

        const bool success = Dart_PostCObject_DL(dart_port, &message_cobj);
        if (!success) {
          printf("%s\n", "Dart_PostCObject_DL failed.");
        }
      }];
  [downloadTask resume];
}
*
//FFI_PLUGIN_EXPORT intptr_t InitDartApiDL(void* data) {
//  return Dart_InitializeApiDL(data);
// }


// #import <AppKit/AppKit.h>
// #include <stdio.h>
// #include "dart_api_dl.h"

// // cc -dynamiclib /Users/bquinlan/./dart/dart-sdk1/sdk/runtime/include/dart_api_dl.c -I/Users/bquinlan/./flutter/bin/cache/dart-sdk/include/  cocoahttp.m -framework AppKit -lobjc -o cocoahttp.dynlib


// void load_url(Dart_Port dart_port, char *uri) {
//   NSURL *url = [NSURL URLWithString:[[NSString alloc] initWithUTF8String:uri]];

//   NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
//         dataTaskWithURL:url
//       completionHandler:^(NSData *data, NSURLResponse *response,
//                           NSError *error) {
//         NSHTTPURLResponse *httpResponse = nil;
//         if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
//           printf("NSHTTPURLResponse has the wrong type.");
//         }
//         httpResponse = (NSHTTPURLResponse *)response;
//         NSDictionary *headers = httpResponse.allHeaderFields;

//         /* Extract response data. */
//         Dart_CObject data_cobj;
//         data_cobj.type = Dart_CObject_kTypedData;
//         data_cobj.value.as_typed_data.type = Dart_TypedData_kUint8;
//         data_cobj.value.as_typed_data.length = data.length;
//         data_cobj.value.as_typed_data.values = (uint8_t *)data.bytes;

//         /* Extract response headers. */
//         NSInteger count = [headers count];
//         id __unsafe_unretained objects[count];
//         id __unsafe_unretained keys[count];
//         [headers getObjects:objects andKeys:keys count:count];
//         Dart_CObject* headers_carray[count*2];

//         for (int i = 0; i < count; i += 2) {
//           /* Memory leak! */
//           headers_carray[i] = malloc(sizeof(Dart_CObject));
//           headers_carray[i]->type = Dart_CObject_kString;
//           headers_carray[i]->value.as_string = ((NSString *) keys[i]).UTF8String;
//           headers_carray[i+1] = malloc(sizeof(Dart_CObject));
//           headers_carray[i+1]->type = Dart_CObject_kString;
//           headers_carray[i+1]->value.as_string = ((NSString *) objects[i]).UTF8String;
//         }

//         Dart_CObject headers_cobj;
//         headers_cobj.type = Dart_CObject_kArray;
//         headers_cobj.value.as_array.length = headers.count;
//         headers_cobj.value.as_array.values = &headers_carray;

//         Dart_CObject message_cobj;
//         Dart_CObject* message_carray[] = {&data_cobj, &headers_cobj};
//         message_cobj.type = Dart_CObject_kArray;
//         message_cobj.value.as_array.length = 2;
//         message_cobj.value.as_array.values = &message_carray;

//         const bool success = Dart_PostCObject_DL(dart_port, &message_cobj);
//         if (!success) {
//           printf("%s\n", "Dart_PostCObject_DL failed.");
//         }
//       }];
//   [downloadTask resume];
// }
