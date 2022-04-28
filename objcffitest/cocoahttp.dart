import 'nsurlsession_bindings.dart';
import 'dart:ffi';
import 'dart:core';
import 'dart:io';

late NativeLibrary _lib = loadLibrary();

NativeLibrary loadLibrary() {
  final lib = DynamicLibrary.open(
      "/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit");
  return NativeLibrary(lib);
}

class URLSessionConfiguration {
  final NSURLSessionConfiguration _configuration;

  URLSessionConfiguration._(this._configuration) {}

  factory URLSessionConfiguration.defaultSessionConfiguration() {
    return URLSessionConfiguration._(NSURLSessionConfiguration.castFrom(
        NSURLSessionConfiguration.getDefaultSessionConfiguration(_lib)));
  }

  factory URLSessionConfiguration.ephemeralSessionConfiguration() {
    return URLSessionConfiguration._(NSURLSessionConfiguration.castFrom(
        NSURLSessionConfiguration.getEphemeralSessionConfiguration(_lib)));
  }

  bool get allowsCellularAccess => _configuration.allowsCellularAccess;
  bool get waitsForConnectivity => _configuration.waitsForConnectivity;
  Duration get timeoutIntervalForRequest {
    _configuration.timeoutIntervalForRequest;
    return Duration(
        microseconds: (_configuration.timeoutIntervalForRequest *
                Duration.microsecondsPerSecond)
            .round());
  }

  set timeoutIntervalForRequest(Duration interval) {
    _configuration.timeoutIntervalForRequest =
        interval.inMicroseconds.toDouble() * Duration.microsecondsPerSecond;
  }

  @override
  String toString() {
    return "[URLSessionConfiguration " +
        "allowsCellularAccess=$allowsCellularAccess " +
        "waitsForConnectivity=$waitsForConnectivity " +
        "timeoutIntervalForRequest=$timeoutIntervalForRequest" +
        "]";
  }
}

class URLSessionTask {
  final NSURLSessionTask _nsUrlSessionTask;

  URLSessionTask._(this._nsUrlSessionTask) {}

  void resume() {
    this._nsUrlSessionTask.resume();
  }

  void suspend() {
    this._nsUrlSessionTask.suspend();
  }
}

class URLRequest {
  final NSURLRequest _nsUrlRequest;

  URLRequest._(this._nsUrlRequest) {}

  factory URLRequest.fromUrl(Uri uri) {
    NSURL url = NSURL.URLWithString(
        _lib, NSObject.castFrom(uri.toString().toNSString(_lib)));
    return URLRequest._(NSURLRequest.requestWithURL(_lib, url));
  }
}

class URLSession {
  final NSURLSession _nsUrlSession;

  URLSession._(this._nsUrlSession) {}

  URLSessionConfiguration get configuration {
    return URLSessionConfiguration._(
        NSURLSessionConfiguration.castFrom(_nsUrlSession.configuration));
  }

  factory URLSession.sessionWithConfiguration(URLSessionConfiguration config) {
    return URLSession._(
        NSURLSession.sessionWithConfiguration(_lib, config._configuration));
  }

  factory URLSession.sharedSession() {
    return URLSession._(
        NSURLSession.castFrom(NSURLSession.getSharedSession(_lib)));
  }

  URLSessionTask dataTask(URLRequest request) {
    request._nsUrlRequest;
  }
}
