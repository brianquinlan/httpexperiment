import 'dart:core';
import 'dart:ffi';
import 'dart:io';
import 'nsurlsession_bindings.dart';
import 'dart:developer';

main() {
  var start = DateTime.now();

  Timeline.startSync("Load library");
  final lib = DynamicLibrary.open(
      "/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit");
  final app = NativeLibrary(lib);
  Timeline.finishSync();
  print('${DateTime.now().difference(start).inMilliseconds}ms');

  Timeline.startSync("getSharedSession");
  final session = NSURLSession.castFrom(NSURLSession.getSharedSession(app));
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
