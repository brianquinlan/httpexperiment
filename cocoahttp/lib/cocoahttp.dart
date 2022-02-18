import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import "dart:typed_data";
import "package:ffi/ffi.dart";
import 'package:native_library/native_library.dart';

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

// Some hypothetical abstract base class for a minimal Http client
// implementation.
abstract class Http {
  // This should probably accept "headers" - I need do some some research
  // into what all likely implementations support.
  Future<Response> get(Uri uri);

  // Should have `post`, etc.
}

class CocaHttp implements Http {
  static var _initialized = false;

  static initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    /*
    final initializeResult =
        _bindings.InitDartApiDL(NativeApi.initializeApiDLData);
    if (initializeResult != 0) {
      throw 'failed to init API.';
    }
*/
    final int Function(Pointer<Void>) initializeApi = _dylib.lookupFunction<
        IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)>("Dart_InitializeApiDL");
    final int initializeResult = initializeApi(NativeApi.initializeApiDLData);
    if (initializeResult != 0) {
      throw 'failed to init API.';
    }
  }

  CocaHttp() {}

  Future<Response> get(Uri uri) {
    final c = Completer<Response>();

    late ReceivePort httpResponsePort;
    httpResponsePort = ReceivePort()
      ..listen((dynamic message) {
        Map<String, String> headers = {};
        for (var i = 0; i < message[1].length - 1; i += 2) {
          // -1?!
          headers[message[1][i]] = message[1][i + 1];
        }
        c.complete(Response(headers, message[0]));
        httpResponsePort.close();
      });

//    httpResponsePort.sendPort.send("This is a test");
    initialize();
    _fetch(httpResponsePort.sendPort, uri.toString());
    return c.future;
  }
}
