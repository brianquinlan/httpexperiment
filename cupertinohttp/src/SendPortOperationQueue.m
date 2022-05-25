//
//  SendPortOperationQueue.m
//  cupertinohttp
//
//  Created by Brian Quinlan on 5/20/22.
//

#import <Foundation/Foundation.h>

#import "SendPortOperationQueue.h"

@implementation SendPortOperationQueue {
  Dart_Port _sendPort;
}

- (instancetype)initWithPort:(Dart_Port)sendPort {
  if (self = [super init]) {
    self->_sendPort = sendPort;
  }
  return self;
}

- (void)addOperation:(NSOperation*)op {
  [op retain];
  Dart_CObject message_cobj;
  //  message_cobj.type = Dart_CObject_kInt64;
  message_cobj.type = Dart_CObject_kNativePointer;
  message_cobj.value.as_native_pointer.ptr = (intptr_t) op;
  message_cobj.value.as_native_pointer.size = 1;
  message_cobj.value.as_native_pointer.callback = NULL;

  const bool success = Dart_PostCObject_DL(self->_sendPort, &message_cobj);
  if (!success) {
//    os_log(OS_LOG_DEFAULT, "failed to send\n");
  }
}

- (void)addOperationWithBlock:(void (^)(void))block {
  [self addOperation:[NSBlockOperation blockOperationWithBlock:block]];
}
@end
