import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart';

class VolleyClient extends BaseClient {
  static const MethodChannel _channel = MethodChannel('volleyhttp');

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    final stream = request.finalize();
    final bytes = await stream.toBytes();

    final Map<String, Object> response =
        await _channel.invokeMethod('request', {
      'method': request.method,
      'url': request.url.toString(),
      'headers': request.headers
    });

    final body = Stream.value(response['body'] as Uint8List);
    return StreamedResponse(body, response['status_code'] as int);
  }
}
