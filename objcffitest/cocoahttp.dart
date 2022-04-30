import 'dart:async';

import 'nsurlsession_bindings.dart' as ns;
import 'dart:ffi' as ffi;
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math';

import 'package:http/http.dart';

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

enum HTTPCookieAcceptPolicy {
  HTTPCookieAcceptPolicyAlways,
  HTTPCookieAcceptPolicyNever,
  HTTPCookieAcceptPolicyOnlyFromMainDocumentDomain,
}

class URLSessionConfiguration {
  final ns.NSURLSessionConfiguration _configuration;

  URLSessionConfiguration._(this._configuration) {}

  factory URLSessionConfiguration.backgroundSession(String identifier) {
    return URLSessionConfiguration._(ns.NSURLSessionConfiguration.castFrom(
        ns.NSURLSessionConfiguration
            .backgroundSessionConfigurationWithIdentifier(
                _lib, ns.NSObject.castFrom(identifier.toNSString(_lib)))));
  }
  factory URLSessionConfiguration.defaultSessionConfiguration() {
    return URLSessionConfiguration._(ns.NSURLSessionConfiguration.castFrom(
        ns.NSURLSessionConfiguration.getDefaultSessionConfiguration(_lib)!));
  }

  factory URLSessionConfiguration.ephemeralSessionConfiguration() {
    return URLSessionConfiguration._(ns.NSURLSessionConfiguration.castFrom(
        ns.NSURLSessionConfiguration.getEphemeralSessionConfiguration(_lib)!));
  }

  bool get allowsCellularAccess => _configuration.allowsCellularAccess;
  bool get allowsConstrainedNetworkAccess =>
      _configuration.allowsConstrainedNetworkAccess;
  bool get allowsExpensiveNetworkAccess =>
      _configuration.allowsExpensiveNetworkAccess;
  bool get discretionary => _configuration.discretionary;
  // TODO: Use an enum for httpCookieAcceptPolicy.
  HTTPCookieAcceptPolicy get httpCookieAcceptPolicy =>
      HTTPCookieAcceptPolicy.values[_configuration.HTTPCookieAcceptPolicy];
  bool get httpShouldSetCookies => _configuration.HTTPShouldSetCookies;
  bool get httpShouldUsePipelining => _configuration.HTTPShouldUsePipelining;
  bool get sessionSendsLaunchEvents => _configuration.sessionSendsLaunchEvents;
  bool get shouldUseExtendedBackgroundIdleMode =>
      _configuration.shouldUseExtendedBackgroundIdleMode;
  Duration get timeoutIntervalForRequest {
    return Duration(
        microseconds: (_configuration.timeoutIntervalForRequest *
                Duration.microsecondsPerSecond)
            .round());
  }

  set timeoutIntervalForRequest(Duration interval) {
    _configuration.timeoutIntervalForRequest =
        interval.inMicroseconds.toDouble() * Duration.microsecondsPerSecond;
  }

  bool get waitsForConnectivity => _configuration.waitsForConnectivity;

  @override
  String toString() {
    return "[URLSessionConfiguration " +
        "allowsCellularAccess=$allowsCellularAccess " +
        "allowsConstrainedNetworkAccess=$allowsConstrainedNetworkAccess " +
        "allowsExpensiveNetworkAccess=$allowsExpensiveNetworkAccess " +
        "discretionary=$discretionary " +
        "httpCookieAcceptPolicy=$httpCookieAcceptPolicy " +
        "httpShouldSetCookies=$httpShouldSetCookies " +
        "httpShouldUsePipelining=$httpShouldUsePipelining " +
        "sessionSendsLaunchEvents=$sessionSendsLaunchEvents " +
        "shouldUseExtendedBackgroundIdleMode=$shouldUseExtendedBackgroundIdleMode " +
        "timeoutIntervalForRequest=$timeoutIntervalForRequest " +
        "waitsForConnectivity=$waitsForConnectivity" +
        "]";
  }
}

enum URLSessionTaskState {
  URLSessionTaskStateRunning,
  URLSessionTaskStateSuspended,
  URLSessionTaskStateCanceling,
  URLSessionTaskStateCompleted,
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

  URLSessionTaskState get state =>
      URLSessionTaskState.values[_nsUrlSessionTask.state];

  int get countOfBytesReceived => _nsUrlSessionTask.countOfBytesReceived;
  int get countOfBytesExpectedToReceive =>
      _nsUrlSessionTask.countOfBytesExpectedToReceive;

  @override
  String toString() {
    return "[URLSessionTask " +
        "countOfBytesExpectedToReceive=$countOfBytesExpectedToReceive " +
        "countOfBytesReceived=$countOfBytesReceived " +
        "state=$state"
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

class MutableURLRequest extends URLRequest {
  final ns.NSMutableURLRequest nsMutableURLRequest;

  MutableURLRequest._(this.nsMutableURLRequest)
      : super._(nsMutableURLRequest) {}

  factory MutableURLRequest.fromUrl(Uri uri) {
    final url = ns.NSURL.URLWithString(
        _lib, ns.NSObject.castFrom(uri.toString().toNSString(_lib)));
    return MutableURLRequest._(
        ns.NSMutableURLRequest.requestWithURL(_lib, url));
  }
}

class HTTPURLResponse {
  final ns.NSHTTPURLResponse _nsHttpUrlResponse;

  HTTPURLResponse._(this._nsHttpUrlResponse) {}

  int get statusCode => _nsHttpUrlResponse.statusCode;
  int get expectedContentLength => _nsHttpUrlResponse.expectedContentLength;

  String? get mimeType => _toString(_nsHttpUrlResponse.MIMEType);

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

  int get length => _nsData.length;
  Uint8List get bytes {
    final bytes = _nsData.bytes;
    if (bytes.address == 0) {
      return Uint8List(0);
    } else {
      // This is unsafe! It is only a view into the underlying NSData!
      return bytes.cast<ffi.Uint8>().asTypedList(length);
    }
  }

  @override
  String toString() {
    final subrange =
        length == 0 ? Uint8List(0) : bytes.sublist(0, min(length - 1, 20));
    final b = subrange.map((e) => e.toRadixString(16)).join();
    return "[Data " + "length=$length " + "bytes=$b..." + "]";
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
        "localizedDescription=$localizedDescription " +
        "localizedFailureReason=$localizedFailureReason " +
        "localizedRecoverySuggestion=$localizedRecoverySuggestion " +
        "]";
  }
}

class URLSession {
  final ns.NSURLSession _nsUrlSession;

  URLSession._(this._nsUrlSession) {}

  URLSessionConfiguration get configuration {
    return URLSessionConfiguration._(
        ns.NSURLSessionConfiguration.castFrom(_nsUrlSession.configuration!));
  }

  factory URLSession.sessionWithConfiguration(URLSessionConfiguration config) {
    return URLSession._(
        ns.NSURLSession.sessionWithConfiguration(_lib, config._configuration));
  }

  factory URLSession.sharedSession() {
    return URLSession._(
        ns.NSURLSession.castFrom(ns.NSURLSession.getSharedSession(_lib)!));
  }

  URLSessionTask dataTask(
      URLRequest request,
      void Function(Data? data, HTTPURLResponse? response, Error? error)
          completion) {
    final port = ReceivePort();
    port.listen((message) {
      final dp = ffi.Pointer<ns.ObjCObject>.fromAddress(message[0]);
      final rp = ffi.Pointer<ns.ObjCObject>.fromAddress(message[1]);
      final ep = ffi.Pointer<ns.ObjCObject>.fromAddress(message[2]);

      Data? data = null;
      HTTPURLResponse? response = null;
      Error? error = null;

      if (dp.address != 0) {
        data = Data._(ns.NSData.castFromPointer(_lib, dp));
      }
      if (rp.address != 0) {
        response =
            HTTPURLResponse._(ns.NSHTTPURLResponse.castFromPointer(_lib, rp));
      }
      if (ep.address != 0) {
        error = Error._(ns.NSError.castFromPointer(_lib, ep));
      }

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

class _A {
  final Data? data;
  final HTTPURLResponse? response;
  final Error? error;

  _A(this.data, this.response, this.error);
}

class CocoaClient extends BaseClient {
  late URLSession _urlSession = URLSession.sharedSession();

  URLSession get urlSession => _urlSession;

  CocoaClient._(this._urlSession);

  factory CocoaClient.sharedUrlSession() {
    return CocoaClient._(URLSession.sharedSession());
  }

  factory CocoaClient.fromUrlSession(URLSession urlSession) {
    return CocoaClient._(urlSession);
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final stream = request.finalize();

    MutableURLRequest urlRequest = MutableURLRequest.fromUrl(request.url);
    final callbackComplete = Completer<_A>();

    final task = urlSession.dataTask(urlRequest, (data, response, error) {
      callbackComplete.complete(_A(data, response, error));
    });
    task.resume();

    final result = await callbackComplete.future;

    result.data!.bytes.toList();
    return StreamedResponse(
      Stream.fromIterable([result.data!.bytes.toList()]),
      result.response!.statusCode,
      contentLength: result.response!.expectedContentLength,
    );
  }
}

late Client client;

Future<void> useClient() async {
  final r = await client.get(Uri.parse("http://www.google.com"));
  print(r.body.substring(0, 70));
  print(r.statusCode);
  print(r.contentLength);
}

Future<void> useSession() async {
  final session = (client as CocoaClient).urlSession;
  final complete = Completer();
  print(session.configuration);
  final task = session.dataTask(
      URLRequest.fromUrl(Uri.parse(
          "https://upload.wikimedia.org/wikipedia/commons/3/3d/LARGE_elevation.jpg")),
      (data, response, error) {
    if (error == null) {
      print(response);
      print(data);
    } else {
      print(error);
    }
    complete.complete();
  });
  print(task);
  task.resume();
  while (task.state == URLSessionTaskState.URLSessionTaskStateRunning) {
    print(task);
    sleep(Duration(milliseconds: 200));
  }
  print(task);
  await complete.future;
}

void main() async {
  URLSessionConfiguration config =
      URLSessionConfiguration.defaultSessionConfiguration();
  URLSession session = URLSession.sessionWithConfiguration(config);
  client = CocoaClient.fromUrlSession(session);

  await useClient();
  await useSession();
}
