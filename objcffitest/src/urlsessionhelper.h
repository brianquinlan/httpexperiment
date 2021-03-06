#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "dart-sdk/include/dart_api_dl.h"

// #import <Foundation/Foundation.h>
#import <Foundation/NSURLSession.h>

@interface URLSessionHelper : NSObject

+ (NSURLSessionDataTask *)dataTaskForSession:(NSURLSession *)session
    withRequest:(NSURLRequest *)request
    toPort: (Dart_Port) dart_port;

@end;
