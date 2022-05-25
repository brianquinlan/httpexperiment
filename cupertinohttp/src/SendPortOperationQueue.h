//
//  SendPortOperationQueue.h
//  cupertinohttp
//
//  Created by Brian Quinlan on 5/20/22.
//

#import <Foundation/NSOperation.h>

#include "dart-sdk/include/dart_api_dl.h"

NS_ASSUME_NONNULL_BEGIN

void Callback(NSObject* obj1, NSObject* obj2, NSObject* obj3) {

}

@interface SendPortOperationQueue : NSOperationQueue
- (instancetype)initWithPort:(Dart_Port)sendPort;
@end

NS_ASSUME_NONNULL_END
