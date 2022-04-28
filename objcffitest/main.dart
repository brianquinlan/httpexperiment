import 'dart:core';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'nsurlsession_bindings.dart';
import 'dart:developer';
/*
+ (NSURLSession *)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration delegate:(nullable id <NSURLSessionDelegate>)delegate delegateQueue:(nullable NSOperationQueue *)queue;

NSObject getSafeNSOperationQueue(NativeLibrary _lib) {
  final receivePort = ReceivePort();
  receivePort.listen((message) {
    print(message);
    NSOperation.cast(message, _lib).start();
  });

  final queue = _ObjCWrapper._(
      ffi.Pointer<ObjCObject>.fromAddress(ffi.portRunner(receivePort.sendPort)),
      _lib);
}
*/
/*
  static NSURLSession sessionWithConfiguration_delegate_delegateQueue(
      NativeLibrary _lib,
      NSObject configuration,
      NSObject? delegate,
      NSObject? queue) {
    _class ??= _getClass(_lib, "NSURLSession");
    _sel_sessionWithConfiguration_delegate_delegateQueue ??=
        _registerName(_lib, "sessionWithConfiguration:delegate:delegateQueue:");
    final _ret = _lib._objc_msgSend_116(
        _class!,
        _sel_sessionWithConfiguration_delegate_delegateQueue!,
        configuration._id,
        delegate?._id ?? ffi.nullptr,
        queue?._id ?? ffi.nullptr);
    return NSURLSession._(_ret, _lib);
  }
*/

main() {
//  print(portRunner(receivePort.sendPort));
  var start = DateTime.now();

  Timeline.startSync("Load library");
  final lib = DynamicLibrary.open(
      "/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit");
  final app = NativeLibrary(lib);
  Timeline.finishSync();
  print('${DateTime.now().difference(start).inMilliseconds}ms');
/*
  final receivePort = ReceivePort();
  receivePort.listen((message) {
    print(message);
    NSOperation.cast(message, app).start();
  });
*/
  Timeline.startSync("getSharedSession");
  final configuration = NSURLSessionConfiguration.castFrom(
      NSURLSessionConfiguration.getDefaultSessionConfiguration(app));

  final session = NSURLSession.sessionWithConfiguration_delegate_delegateQueue(
      app, configuration, null, getSafeNSOperationQueue(app));
  Timeline.finishSync();

  start = DateTime.now();
  Timeline.startSync("Start a data task");
  final url = NSURL.URLWithString(
      app, NSObject.castFrom(NSString(app, "http://www.example.com")));

  final task = session.dataTaskWithURL(url);
  task.resume();
  Timeline.finishSync();
  print('${DateTime.now().difference(start).inMilliseconds}ms');

  print(NSString.castFrom(
      NSURL.castFrom(NSURLRequest.castFrom(task.originalRequest).URL).host));

  sleep(Duration(seconds: 2));
  print(NSHTTPURLResponse.castFrom(task.response).statusCode);

//  NSURLResponse.castF task.response
//  print(app.NSFoundationVersionNumber);

  /*
  final progress = NSProgress.castFrom(task.progress);

  while (!progress.finished) {
    print(progress.fractionCompleted);
    print(task.countOfBytesClientExpectsToReceive);
    print(task.countOfBytesReceived);
    print(task.response);
  }
  */
}

class URLSessionConfiguration {
  URLSessionConfiguration() {}

  factory URLSessionConfiguration.defaultSessionConfiguration() {
    return URLSessionConfiguration();
  }

  factory URLSessionConfiguration.ephemeralSessionConfiguration() {
    return URLSessionConfiguration();
  }
}

class URLSession {
  URLSession() {}

  factory URLSession.fromConfiguration(URLSessionConfiguration config) {
    return URLSession();
  }

  factory URLSession.sharedSession() {
    return URLSession();
  }
}
