import 'dart:async';

import 'package:flutter/services.dart';

class Platformhttp {
  static const MethodChannel _channel = MethodChannel('platformhttp');

  static Future<String?> getUrl(Uri uri) async {
    final url = uri.toString();
    const method = 'GET';
    final headers = {};

    final String? version = await _channel.invokeMethod(
        'request', {'method': method, 'url': url, 'headers': headers});
    return version;
  }
}
