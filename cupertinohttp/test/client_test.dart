import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:cupertinohttp/cupertinohttp.dart';

class Plus2Decoder extends Converter<List<int>, String> {
  @override
  String convert(List<int> input) {
    return const Utf8Decoder().convert(input.map((e) => e + 2).toList());
  }
}

class Plus2Encoder extends Converter<String, List<int>> {
  @override
  List<int> convert(String input) {
    return const Utf8Encoder().convert(input).map((e) => e - 2).toList();
  }
}

class Plus2Encoding extends Encoding {
  @override
  Converter<List<int>, String> get decoder => Plus2Decoder();

  @override
  Converter<String, List<int>> get encoder => Plus2Encoder();

  @override
  String get name => "plus2";
}

testRequestBody(http.Client client) {
  group('request body', () {
    test('client.post() with string body', () async {
      late List<String>? serverReceivedContentType;
      late String serverReceivedBody;

      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          serverReceivedContentType =
              request.headers[HttpHeaders.contentTypeHeader];
          serverReceivedBody = await const Utf8Decoder()
              .bind(request)
              .fold("", (p, e) => "$p$e");
          unawaited(request.response.close());
        });
      await client.post(Uri.parse('http://localhost:${server.port}'),
          body: 'Hello World!');

      expect(serverReceivedContentType, ["text/plain; charset=utf-8"]);
      expect(serverReceivedBody, 'Hello World!');
    });

    test('client.post() with string body and custom encoding', () async {
      late List<String>? serverReceivedContentType;
      late String serverReceivedBody;

      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          serverReceivedContentType =
              request.headers[HttpHeaders.contentTypeHeader];
          serverReceivedBody = await const Utf8Decoder()
              .bind(request)
              .fold("", (p, e) => "$p$e");
          unawaited(request.response.close());
        });
      await client.post(Uri.parse('http://localhost:${server.port}'),
          body: 'Hello', encoding: Plus2Encoding());

      expect(serverReceivedContentType, ["text/plain; charset=plus2"]);
      expect(serverReceivedBody, 'Fcjjm');
    });

    test('client.post() with map body', () async {
      late List<String>? serverReceivedContentType;
      late String serverReceivedBody;

      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          serverReceivedContentType =
              request.headers[HttpHeaders.contentTypeHeader];
          serverReceivedBody = await const Utf8Decoder()
              .bind(request)
              .fold("", (p, e) => "$p$e");
          unawaited(request.response.close());
        });
      await client.post(Uri.parse('http://localhost:${server.port}'),
          body: {"key": "value"});
      expect(serverReceivedContentType,
          ['application/x-www-form-urlencoded; charset=utf-8']);
      expect(serverReceivedBody, "key=value");
    });

    test('client.post() with map body and encloding', () async {
      late List<String>? serverReceivedContentType;
      late String serverReceivedBody;

      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          serverReceivedContentType =
              request.headers[HttpHeaders.contentTypeHeader];
          serverReceivedBody = await const Utf8Decoder()
              .bind(request)
              .fold("", (p, e) => "$p$e");
          unawaited(request.response.close());
        });
      await client.post(Uri.parse('http://localhost:${server.port}'),
          body: {"key": "value"}, encoding: Plus2Encoding());
      expect(serverReceivedContentType,
          ['application/x-www-form-urlencoded; charset=plus2']);
      expect(serverReceivedBody, "gau;r]hqa");
    });
  });
}

testResponseBody(http.Client client, {bool canStream = true}) async {
  group('response body', () {
    test('small response with content length', () async {
      const message = "Hello World!";
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          request.response.headers.set('Content-Type', 'text/plain');
          request.response.write(message);
          await request.response.close();
        });
      final response =
          await client.get(Uri.parse('http://localhost:${server.port}'));
      expect(response.body, message);
      expect(response.bodyBytes, message.codeUnits);
      expect(response.contentLength, message.length);
      expect(response.headers['content-type'], 'text/plain');
    });

    test('small response streamed without content length', () async {
      const message = "Hello World!";
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          request.response.headers.set('Content-Type', 'text/plain');
          request.response.write(message);
          await request.response.close();
        });
      final request =
          http.Request('GET', Uri.parse('http://localhost:${server.port}'));
      final response = await client.send(request);
      expect(await response.stream.bytesToString(), message);
      expect(response.contentLength, null);
      expect(response.headers['content-type'], 'text/plain');
    });

    test('large response streamed without content length', () async {
      const count = 10000000;
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          request.response.headers.set('Content-Type', 'text/plain');
          for (var i = 0; i <= count; ++i) {
            request.response.write("$i\n");
          }
          await request.response.close();
        });
      final request =
          http.Request('GET', Uri.parse('http://localhost:${server.port}'));
      final response = await client.send(request);
      int sum = 0;
      await const LineSplitter()
          .bind(const Utf8Decoder().bind(response.stream))
          .forEach((s) {
        sum += int.parse(s.trim());
      });
      expect(response.headers['content-type'], 'text/plain');
      expect(sum, count * (count + 1) / 2);
    }, skip: canStream ? false : 'does not support streamed output');
  });
}

testRequestHeaders(http.Client client) async {
  group('client headers', () {
    test('single header', () async {
      late HttpHeaders requestHeaders;
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          requestHeaders = request.headers;
          unawaited(request.response.close());
        });
      await client.get(Uri.parse('http://localhost:${server.port}'),
          headers: {'foo': 'bar'});
      expect(requestHeaders['foo'], ['bar']);
    });

    test('UPPER case header', () async {
      late HttpHeaders requestHeaders;
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          requestHeaders = request.headers;
          unawaited(request.response.close());
        });
      await client.get(Uri.parse('http://localhost:${server.port}'),
          headers: {'FOO': 'BAR'});
      // RFC 2616 14.44 states that header field names are case-insensive.
      // http.Client canonicalizes field names into lower case.
      expect(requestHeaders['foo'], ['BAR']);
    });

    test('test headers different only in case', () async {
      // RFC 2616 14.44 states that header field names are case-insensive.
      late HttpHeaders requestHeaders;
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          requestHeaders = request.headers;
          unawaited(request.response.close());
        });
      await client.get(Uri.parse('http://localhost:${server.port}'),
          headers: {'foo': 'bar', 'Foo': 'Bar'});
      expect(requestHeaders['foo']!.first, isIn(['bar', 'Bar']));
    });

    test('multiple headers', () async {
      late HttpHeaders requestHeaders;
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          requestHeaders = request.headers;
          unawaited(request.response.close());
        });
      // The `http.Client` API does not offer a way of sending the name field
      // more than once.
      await client.get(Uri.parse('http://localhost:${server.port}'),
          headers: {'list': 'apple, orange'});
      expect(requestHeaders['list'], ['apple, orange']);
    });

    test('multiple values per header', () async {
      late HttpHeaders requestHeaders;
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          requestHeaders = request.headers;
          unawaited(request.response.close());
        });
      // The `http.Client` API does not offer a way of sending the same field
      // more than once.
      await client.get(Uri.parse('http://localhost:${server.port}'),
          headers: {'list': 'apple, orange'});

      expect(requestHeaders['list'], ['apple, orange']);
    });
  });
}

testResponseHeaders(http.Client client) async {
  group('server headers', () {
    test('single header', () async {
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          var response = request.response;
          response.headers.set('foo', 'bar');
          unawaited(response.close());
        });
      final response =
          await client.get(Uri.parse('http://localhost:${server.port}'));
      expect(response.headers['foo'], 'bar');
    });

    test('UPPERCASE header', () async {
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          var response = request.response;
          response.headers.set('FOO', 'BAR', preserveHeaderCase: true);
          unawaited(response.close());
        });
      // RFC 2616 14.44 states that header field names are case-insensive.
      // http.Client canonicalizes field names into lower case.
      final response =
          await client.get(Uri.parse('http://localhost:${server.port}'));
      expect(response.headers['foo'], 'BAR');
    });

    test('multiple headers', () async {
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          var response = request.response;
          response.headers.set('field1', 'value1');
          response.headers.set('field2', 'value2');
          response.headers.set('field3', 'value3');
          unawaited(response.close());
        });
      final response =
          await client.get(Uri.parse('http://localhost:${server.port}'));
      expect(response.headers['field1'], 'value1');
      expect(response.headers['field2'], 'value2');
      expect(response.headers['field3'], 'value3');
    });

    test('multiple values per header', () async {
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          var response = request.response;
          // RFC 2616 14.44 states that header field names are case-insensive.
          response.headers.add("list", "apple");
          response.headers.add("list", "orange");
          response.headers.add("List", "banana");
          unawaited(response.close());
        });
      final response =
          await client.get(Uri.parse('http://localhost:${server.port}'));
      expect(response.headers['list'], 'apple, orange, banana');
    });
  });
}

void main() {
  group('CocoaClient', () {
    testRequestBody(CocoaClient.sharedUrlSession());
    testResponseBody(CocoaClient.sharedUrlSession(), canStream: false);
    testRequestHeaders(CocoaClient.sharedUrlSession());
    testResponseHeaders(CocoaClient.sharedUrlSession());
  });

  group('dart:io', () {
    testRequestBody(http.Client());
    testResponseBody(http.Client());
    testRequestHeaders(http.Client());
    testResponseHeaders(http.Client());
  });
}
