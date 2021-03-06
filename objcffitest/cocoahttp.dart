import 'dart:async';

import 'package:ffi/ffi.dart' as pffi;
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

class _Object<T extends ns.NSObject> {
  final T _nsObject;

  _Object(this._nsObject);
}

class URLSessionConfiguration extends _Object<ns.NSURLSessionConfiguration> {
  URLSessionConfiguration._(ns.NSURLSessionConfiguration c) : super(c) {}
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

  bool get allowsCellularAccess => _nsObject.allowsCellularAccess;
  bool get allowsConstrainedNetworkAccess =>
      _nsObject.allowsConstrainedNetworkAccess;
  bool get allowsExpensiveNetworkAccess =>
      _nsObject.allowsExpensiveNetworkAccess;
  bool get discretionary => _nsObject.discretionary;
  // TODO: Use an enum for httpCookieAcceptPolicy.
  HTTPCookieAcceptPolicy get httpCookieAcceptPolicy =>
      HTTPCookieAcceptPolicy.values[_nsObject.HTTPCookieAcceptPolicy];
  bool get httpShouldSetCookies => _nsObject.HTTPShouldSetCookies;
  bool get httpShouldUsePipelining => _nsObject.HTTPShouldUsePipelining;
  bool get sessionSendsLaunchEvents => _nsObject.sessionSendsLaunchEvents;
  bool get shouldUseExtendedBackgroundIdleMode =>
      _nsObject.shouldUseExtendedBackgroundIdleMode;
  Duration get timeoutIntervalForRequest {
    return Duration(
        microseconds: (_nsObject.timeoutIntervalForRequest *
                Duration.microsecondsPerSecond)
            .round());
  }

  set timeoutIntervalForRequest(Duration interval) {
    _nsObject.timeoutIntervalForRequest =
        interval.inMicroseconds.toDouble() * Duration.microsecondsPerSecond;
  }

  bool get waitsForConnectivity => _nsObject.waitsForConnectivity;

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

  String? get httpMethod {
    return _toString(_nsUrlRequest.HTTPMethod);
  }

  Data? get httpBody {
    final body = _nsUrlRequest.HTTPBody;
    if (body == null) {
      return null;
    }
    return Data._(ns.NSData.castFrom(body));
  }

  Map<String, String> get allHttpHeaderFields {
    final headers =
        ns.NSDictionary.castFrom(_nsUrlRequest.allHTTPHeaderFields!);
    return (_foo(headers));
  }

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

  @override
  String get httpMethod {
    return _toString(nsMutableURLRequest.HTTPMethod)!;
  }

  set httpMethod(String method) {
    nsMutableURLRequest.HTTPMethod =
        ns.NSObject.castFrom(method.toNSString(_lib));
  }

  @override
  Data get httpBody {
    return Data._(ns.NSData.castFrom(nsMutableURLRequest.HTTPBody!));
  }

  void setValueForHttpHeaderField(String value, String field) {
    nsMutableURLRequest.setValue_forHTTPHeaderField(
        ns.NSObject.castFrom(field.toNSString(_lib)),
        ns.NSObject.castFrom(value.toNSString(_lib)));
  }

  set httpBody(Data data) {
    print('This is some data: $data');
    nsMutableURLRequest.HTTPBody = data._nsData;
  }

  factory MutableURLRequest.fromUrl(Uri uri) {
    final url = ns.NSURL.URLWithString(
        _lib, ns.NSObject.castFrom(uri.toString().toNSString(_lib)));
    return MutableURLRequest._(
        ns.NSMutableURLRequest.requestWithURL(_lib, url));
  }

  @override
  String toString() {
    return "[MutableURLRequest " +
        "httpMethod=$httpMethod " +
        "allHttpHeaderFields=$allHttpHeaderFields " +
        "httpBody=$httpBody " +
        "]";
  }
}

Map<String, String> _foo(ns.NSDictionary d) {
  final m = Map<String, String>();

  final keys = ns.NSArray.castFrom(d.allKeys!);
  for (var i = 0; i < keys.count; ++i) {
    final key = _toString(keys.objectAtIndex(i))!;
    final value = _toString(d.objectForKey(keys.objectAtIndex(i)))!;
    m[key] = value;
  }

  return m;
}

class HTTPURLResponse {
  final ns.NSHTTPURLResponse _nsHttpUrlResponse;

  HTTPURLResponse._(this._nsHttpUrlResponse) {}

  int get statusCode => _nsHttpUrlResponse.statusCode;
  int get expectedContentLength => _nsHttpUrlResponse.expectedContentLength;
  String? get mimeType => _toString(_nsHttpUrlResponse.MIMEType);
  Map<String, String> get allHeaderFields {
    final headers =
        ns.NSDictionary.castFrom(_nsHttpUrlResponse.allHeaderFields!);
    return (_foo(headers));
  }

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

  factory Data.fromUint8List(Uint8List l) {
    final f = pffi.calloc<ffi.Uint8>(l.length);
    try {
      f.asTypedList(l.length).setAll(0, l);

      final data = ns.NSData.dataWithBytes_length(_lib, f.cast(), l.length);
      return Data._(data);
    } finally {
      pffi.calloc.free(f);
    }
  }

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
    return "[Data " + "length=$length " + "bytes=0x$b..." + "]";
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
        ns.NSURLSession.sessionWithConfiguration(_lib, config._nsObject));
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

    final bytes = await stream.toBytes();
    print("bytes: $bytes");
    final d = Data.fromUint8List(bytes);

    print("string: ${String.fromCharCodes(bytes)}");

    MutableURLRequest urlRequest = MutableURLRequest.fromUrl(request.url)
      ..httpMethod = request.method
      ..httpBody = d;

    // This will preserve Apple default headers - is that what we want?
    request.headers.forEach(
        (key, value) => urlRequest.setValueForHttpHeaderField(key, value));
    final callbackComplete = Completer<_A>();
    print(urlRequest);
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
      headers: result.response!.allHeaderFields,
    );
  }
}

late Client client; // from pkg:http

Future<void> useClient() async {
  final r = await client.get(Uri.parse("http://www.sweetapp.com"));
  print(r.body.substring(0, 70));
  print(r.statusCode);
  print(r.contentLength);
  print(r.headers);

  final p = await client.post(
      Uri.parse("https://ptsv2.com/t/5e7uf-1651618013/post"),
      headers: {"Content-type": "text/plain"},
      body: "This is a test".codeUnits);
  print(p.statusCode);
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
