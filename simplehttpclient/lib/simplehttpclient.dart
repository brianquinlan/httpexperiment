import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

final _simpleHttpClientToken = Object();

abstract class SimpleHttpResponse {
  int get contentLength;
  String get body;
  Uint8List get bodyBytes;
  int get statusCode;
  String get reasonPhrase;
  Map<String, String> get headers;
}

abstract class SimpleHttpClient {
  static SimpleHttpClient? _global;

  static SimpleHttpClient? get current {
    return Zone.current[_simpleHttpClientToken] ?? _global;
  }

  static set global(SimpleHttpClient? overrides) {
    _global = overrides;
  }

  // Make List for headers?

  Future<SimpleHttpResponse> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding});
}

// 