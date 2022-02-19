import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import "dart:typed_data";
import "package:ffi/ffi.dart";
import 'package:native_library/native_library.dart';
import 'package:simplehttpclient/simplehttpclient.dart';
import 'dart:convert';

import 'cocoahttp_bindings_generated.dart';

/// A very short-lived native function.
///
/// For very short-lived functions, it is fine to call them on the main isolate.
/// They will block the Dart execution while running the native function, so
/// only do this for native functions which are guaranteed to be short-lived.
void _fetch(SendPort port, String uri) =>
    _bindings.sum(port.nativePort, uri.toNativeUtf8().cast<Int8>());

const String _libName = 'cocoahttp';
const String _packageName = '_libName';

/// The dynamic library in which the symbols for [CocoahttpBindings] can be found.
final DynamicLibrary _dylib = () {
  DynamicLibrary? _jit() {
    if (Platform.isMacOS) {
      final Uri dylibPath = sharedLibrariesLocationBuilt(_packageName)
          .resolve('lib$_libName.dylib');
      final File file = File.fromUri(dylibPath);
      if (!file.existsSync()) {
        throw "Dynamic library '${dylibPath.toFilePath()}' does not exist.";
      }
      return DynamicLibrary.open(dylibPath.path);
    } else if (Platform.isLinux) {
      final Uri dylibPath =
          sharedLibrariesLocationBuilt(_packageName).resolve('lib$_libName.so');
      final File file = File.fromUri(dylibPath);
      if (!file.existsSync()) {
        throw "Dynamic library '${dylibPath.toFilePath()}' does not exist.";
      }
      return DynamicLibrary.open(dylibPath.path);
    } else if (Platform.isWindows) {
      final Uri dylibPath =
          sharedLibrariesLocationBuilt(_packageName).resolve('$_libName.dll');
      final File file = File.fromUri(dylibPath);
      if (!file.existsSync()) {
        throw "Dynamic library '${dylibPath.toFilePath()}' does not exist.";
      }
      return DynamicLibrary.open(dylibPath.toFilePath());
    }
    return null;
  }

  switch (Embedders.current) {
    case Embedder.flutter:
      switch (FlutterRuntimeModes.current) {
        case FlutterRuntimeMode.app:
          if (Platform.isMacOS || Platform.isIOS) {
            return DynamicLibrary.open('$_libName.framework/$_libName');
          }
          if (Platform.isAndroid || Platform.isLinux) {
            return DynamicLibrary.open('lib$_libName.so');
          }
          if (Platform.isWindows) {
            return DynamicLibrary.open('$_libName.dll');
          }
          break;
        case FlutterRuntimeMode.test:
          final DynamicLibrary? result = _jit();
          if (result != null) {
            return result;
          }
          break;
      }
      break;
    case Embedder.standalone:
      switch (StandaloneRuntimeModes.current) {
        case StandaloneRuntimeMode.jit:
          final DynamicLibrary? result = _jit();
          if (result != null) {
            return result;
          }
          break;
        case StandaloneRuntimeMode.executable:
          // When running from executable, we expect the person assembling the
          // final executable to locate the dynamic library next to the
          // executable.
          if (Platform.isMacOS) {
            return DynamicLibrary.open('lib$_libName.dylib');
          } else if (Platform.isLinux) {
            return DynamicLibrary.open('lib$_libName.so');
          } else if (Platform.isWindows) {
            return DynamicLibrary.open('$_libName.dll');
          }
          break;
      }
  }
  throw UnsupportedError('Unimplemented!');
}();

/// The bindings to the native functions in [_dylib].
final CocoahttpBindings _bindings = CocoahttpBindings(_dylib);

class Response {
  Map<String, String> headers;
  Uint8List body;

  Response(this.headers, this.body);
}

class CocoaHttpResponse implements SimpleHttpResponse {
  Map<String, String> _headers;
  Uint8List _bodyBytes;

  int get contentLength => this._bodyBytes.length;
  String get body => "cat";
  Uint8List get bodyBytes => _bodyBytes;
  int get statusCode => 200;
  String get reasonPhrase => 'OK';
  Map<String, String> get headers => _headers;

  CocoaHttpResponse(this._headers, this._bodyBytes);
}

class CocoaHttp implements SimpleHttpClient {
  static var _initialized = false;

  static initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final int Function(Pointer<Void>) initializeApi = _dylib.lookupFunction<
        IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)>("Dart_InitializeApiDL");
    final int initializeResult = initializeApi(NativeApi.initializeApiDLData);
    if (initializeResult != 0) {
      throw 'failed to init API.';
    }
  }

  CocaHttp() {}

  Future<CocoaHttpResponse> get(Uri url, {Map<String, String>? headers}) {
    final c = Completer<CocoaHttpResponse>();

    late ReceivePort httpResponsePort;
    httpResponsePort = ReceivePort()
      ..listen((dynamic message) {
        Map<String, String> headers = {};
        for (var i = 0; i < message[1].length - 1; i += 2) {
          // -1?!
          headers[message[1][i]] = message[1][i + 1];
        }
        c.complete(CocoaHttpResponse(headers, message[0]));
        httpResponsePort.close();
      });

//    httpResponsePort.sendPort.send("This is a test");
    initialize();
    _fetch(httpResponsePort.sendPort, url.toString());
    return c.future;
  }

  Future<SimpleHttpResponse> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return Future.value(CocoaHttpResponse({}, Uint8List(5)));
  }
}
