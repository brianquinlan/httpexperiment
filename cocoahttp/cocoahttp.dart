import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io' show sleep, Platform, Directory;
import 'package:path/path.dart' as path;
import 'dart:ffi';
import 'dart:isolate';
import "package:ffi/ffi.dart";
import "dart:typed_data";

class Response {
  Map<String, String> headers;
  Uint8List body;

  Response(this.headers, this.body);
}

class Http {
  static late Function(int, Pointer<Utf8>) _fetch;
  static var _initialized = false;

  static initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;

    var libraryPath = path.join(Directory.current.path, 'cocoahttp.dynlib');
    final dylib = ffi.DynamicLibrary.open(libraryPath);
    final initializeApi = dylib.lookupFunction<IntPtr Function(Pointer<Void>),
        int Function(Pointer<Void>)>('Dart_InitializeApiDL');
    final initializeResult = initializeApi(NativeApi.initializeApiDLData);
    if (initializeResult != 0) {
      throw 'failed to init API.';
    }
    _fetch = dylib.lookupFunction<Void Function(Int64 port, Pointer<Utf8> url),
        void Function(int port, Pointer<Utf8> url)>('test');
  }

  Http() {
    initialize();
  }

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

    final cUri = uri.toString().toNativeUtf8();
    _fetch(httpResponsePort.sendPort.nativePort, cUri);
    return c.future;
  }
}

main() async {
  final http = Http();

  Response r = await http.get(Uri.parse("https://www.apple.com/"));
  print(String.fromCharCodes(r.body).substring(0, 200));
  print(r.headers);
}
