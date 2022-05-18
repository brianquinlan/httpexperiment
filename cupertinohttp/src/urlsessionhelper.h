#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "dart-sdk/include/dart_api_dl.h"

// Normally, we'd "import <Foundation/Foundation.h>"
// but that would mean that ffigen would process every
#import <Foundation/NSURLSession.h>


@interface URLSessionHelper : NSObject

+ (NSURLSessionDataTask *)dataTaskForSession:(NSURLSession *)session
                                 withRequest:(NSURLRequest *)request
                                      toPort: (Dart_Port) dart_port;

@end

typedef NS_ENUM(NSInteger, MessageType) {
  ResponseMessage = 0,
  DataMessage = 1,
  CompletedMessage = 2,
  DeniedRedirectMessage = 3
};

@interface TaskConfiguration : NSObject

- (id) initWithPort:(Dart_Port)sendPort maxRedirects:(uint32_t)redirects;

@property (readonly) Dart_Port sendPort;
@property (readonly) uint32_t maxRedirects;

@end

@interface HttpClientDelegate : NSObject // <NSURLSessionDelegate>

- (void)registerTask:(NSURLSessionTask *) task withConfiguration:(TaskConfiguration *)config;
- (void)unregisterTask:(NSURLSessionTask *) task;
- (uint32_t) getNumRedirectsForTask: (NSURLSessionTask *) task;

@end
