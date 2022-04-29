import 'nsurlsession_bindings.dart' as ns;
import 'dart:ffi' as ffi;
import 'dart:core';
import 'dart:io';
import 'dart:isolate';

late ns.NativeLibrary _lib = loadLibrary();
late ns.NativeLibrary _helperLib = loadHelperLibrary();

ns.NativeLibrary loadLibrary() {
  final lib = ffi.DynamicLibrary.open(
      "/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit");
  return ns.NativeLibrary(lib);
}

ns.NativeLibrary loadHelperLibrary() {
  final lib = ffi.DynamicLibrary.open(
      "/Users/bquinlan/dart/httpexperiment/objcffitest/urlsessionhelper.dynlib");

  final int Function(ffi.Pointer<ffi.Void>) initializeApi = lib.lookupFunction<
      ffi.IntPtr Function(ffi.Pointer<ffi.Void>),
      int Function(ffi.Pointer<ffi.Void>)>("Dart_InitializeApiDL");
  final int initializeResult = initializeApi(ffi.NativeApi.initializeApiDLData);
  if (initializeResult != 0) {
    throw 'failed to init API.';
  }

  return ns.NativeLibrary(lib);
}

class URLSessionConfiguration {
  final ns.NSURLSessionConfiguration _configuration;

  URLSessionConfiguration._(this._configuration) {}

  factory URLSessionConfiguration.defaultSessionConfiguration() {
    return URLSessionConfiguration._(ns.NSURLSessionConfiguration.castFrom(
        ns.NSURLSessionConfiguration.getDefaultSessionConfiguration(_lib)));
  }

  factory URLSessionConfiguration.ephemeralSessionConfiguration() {
    return URLSessionConfiguration._(ns.NSURLSessionConfiguration.castFrom(
        ns.NSURLSessionConfiguration.getEphemeralSessionConfiguration(_lib)));
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
  final ns.NSURLSessionTask _nsUrlSessionTask;

  URLSessionTask._(this._nsUrlSessionTask) {}

  void resume() {
    this._nsUrlSessionTask.resume();
  }

  void suspend() {
    this._nsUrlSessionTask.suspend();
  }

  int get countOfBytesReceived => _nsUrlSessionTask.countOfBytesReceived;

  @override
  String toString() {
    return "[URLSessionTask " +
        "countOfBytesReceived=$countOfBytesReceived" +
        "]";
  }
}

class URLRequest {
  final ns.NSURLRequest _nsUrlRequest;

  URLRequest._(this._nsUrlRequest) {}

  factory URLRequest.fromUrl(Uri uri) {
    final url = ns.NSURL.URLWithString(
        _lib, ns.NSObject.castFrom(uri.toString().toNSString(_lib)));
    return URLRequest._(ns.NSURLRequest.requestWithURL(_lib, url));
  }
}

class HTTPURLResponse {
  final ns.NSHTTPURLResponse _nsHttpUrlResponse;

  HTTPURLResponse._(this._nsHttpUrlResponse) {}

  int get statusCode => _nsHttpUrlResponse.statusCode;
  int get expectedContentLength => _nsHttpUrlResponse.expectedContentLength;

  String get mimeType =>
      ns.NSString.castFrom(_nsHttpUrlResponse.MIMEType).toString();

  @override
  String toString() {
    return "[HTTPURLResponse " +
        "statusCode=$statusCode " +
        "mimeType=$mimeType " +
        "expectedContentLength=$expectedContentLength" +
        "]";
  }
}

class Data {
  final ns.NSData _nsData;

  Data._(this._nsData) {}

  @override
  String toString() {
    return "[Data]";
  }
}

String? _toString(ns.NSObject? o) {
  if (o == null) {
    return null;
  }

  return ns.NSString.castFrom(o).toString();
}

class Error {
  final ns.NSError _nsError;

  Error._(this._nsError) {}

  int get code => this._nsError.code;
  String? get localizedDescription => _toString(_nsError.localizedDescription);
  String? get localizedFailureReason =>
      _toString(_nsError.localizedFailureReason);
  String? get localizedRecoverySuggestion =>
      _toString(_nsError.localizedRecoverySuggestion);

  @override
  String toString() {
    return "[Error " +
        "code=$code " +
//        "localizedDescription=$localizedDescription " +
//        "localizedFailureReason=$localizedFailureReason " +
//        "localizedRecoverySuggestion=$localizedRecoverySuggestion " +
        "]";
  }
}

class URLSession {
  final ns.NSURLSession _nsUrlSession;

  URLSession._(this._nsUrlSession) {}

  URLSessionConfiguration get configuration {
    return URLSessionConfiguration._(
        ns.NSURLSessionConfiguration.castFrom(_nsUrlSession.configuration));
  }

  factory URLSession.sessionWithConfiguration(URLSessionConfiguration config) {
    return URLSession._(
        ns.NSURLSession.sessionWithConfiguration(_lib, config._configuration));
  }

  factory URLSession.sharedSession() {
    return URLSession._(
        ns.NSURLSession.castFrom(ns.NSURLSession.getSharedSession(_lib)));
  }

  URLSessionTask dataTask(
      URLRequest request,
      void Function(Data data, HTTPURLResponse response, Error? error)
          completion) {
    final port = ReceivePort();
    port.listen((message) {
      final dp = ffi.Pointer<ns.ObjCObject>.fromAddress(message[0]);
      final rp = ffi.Pointer<ns.ObjCObject>.fromAddress(message[1]);

      Error? error = null;
      if (message[2] != 0) {
        final ep = ffi.Pointer<ns.ObjCObject>.fromAddress(message[2]);
        error = Error._(ns.NSError.castFromPointer(_lib, ep));
      }

      final data = Data._(ns.NSData.castFromPointer(_lib, dp));
      final response =
          HTTPURLResponse._(ns.NSHTTPURLResponse.castFromPointer(_lib, rp));

      try {
        completion(data, response, error);
      } finally {
        port.close();
      }
//      final response = ns.NSError.castFromPointer(ep, _lib);
    });
    final sendPort = port.sendPort.nativePort;
    final task = ns.URLSessionHelper.dataTaskForSession_withRequest_toPort(
        _helperLib, _nsUrlSession, request._nsUrlRequest, sendPort);
    return URLSessionTask._(task);
  }
}

void main() {
  final session = URLSession.sharedSession();
  print(session.configuration);
  final task = session.dataTask(
      URLRequest.fromUrl(Uri.parse(
          "https://upload.wikimedia.org/wikipedia/commons/3/3d/LARGE_elevation.jpg")),
      (data, response, error) {
    if (error == null) {
      print(response);
    } else {
      print(error);
    }
  });
  print(task);
  task.resume();
  for (var i = 0; i < 10; ++i) {
    print(task);
    sleep(Duration(milliseconds: 100));
  }
}
