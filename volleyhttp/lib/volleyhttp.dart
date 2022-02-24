import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:simplehttpclient/simplehttpclient.dart';

class VolleyHttpResponse implements SimpleHttpResponse {
  final Map<String, String> _headers;
  final Uint8List _bodyBytes;

  @override
  int get contentLength => this._bodyBytes.length;

  @override
  String get body => String.fromCharCodes(_bodyBytes);

  @override
  Uint8List get bodyBytes => _bodyBytes;

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  Map<String, String> get headers => _headers;

  VolleyHttpResponse(this._headers, this._bodyBytes);
}

class Volleyhttp implements SimpleHttpClient {
  static const MethodChannel _channel = MethodChannel('volleyhttp');

  static void registerWith() {
    SimpleHttpClient.global = Volleyhttp();
  }

  Future<String?> getUrl(Uri uri) async {
    final url = uri.toString();
    const method = 'GET';
    final headers = {};

    final String? version = await _channel.invokeMethod(
        'request', {'method': method, 'url': url, 'headers': headers});
    return version;
  }

  @override
  Future<SimpleHttpResponse> get(Uri url,
      {Map<String, String>? headers}) async {
    const method = 'GET';
    final headers = {};

    final String version = await _channel.invokeMethod('request',
        {'method': method, 'url': url.toString(), 'headers': headers ?? {}});

    return Future.value(
        VolleyHttpResponse({}, Uint8List.fromList(version.codeUnits)));
  }

  @override
  Future<SimpleHttpResponse> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    // TODO: implement post
    throw UnimplementedError();
  }
}

SimpleHttpClient getSimpleHttpClient() {
  return Volleyhttp();
}
