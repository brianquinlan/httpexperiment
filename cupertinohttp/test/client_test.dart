import 'dart:io';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:cupertinohttp/cupertinohttp.dart';

testClientHeaders(http.Client client) async {
  group('client headers', () {
    test('single header', () async {
      late HttpHeaders requestHeaders;
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          requestHeaders = request.headers;
          unawaited(request.response.close());
        });
      await client.get(Uri.parse('http://localhost:${server!.port}'),
          headers: {'foo': 'bar'});
      expect(requestHeaders['foo'], ['bar']);
    });

    test('differently cased header', () async {
      // RFC 2616 14.44 states that header field names are case-insensive.
      late HttpHeaders requestHeaders;
      final server = (await HttpServer.bind('localhost', 0))
        ..listen((request) async {
          request.drain();
          requestHeaders = request.headers;
          unawaited(request.response.close());
        });
      await client.get(Uri.parse('http://localhost:${server!.port}'),
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
      await client.get(Uri.parse('http://localhost:${server!.port}'),
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
      // The `http.Client` API does not offer a way of sending the name field
      // more than once.
      await client.get(Uri.parse('http://localhost:${server!.port}'),
          headers: {'list': 'apple, orange'});

      expect(requestHeaders['list'], ['apple, orange']);
    });
  });
}

testServerHeaders(http.Client client) async {
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
          await client.get(Uri.parse('http://localhost:${server!.port}'));
      expect(response.headers['foo'], 'bar');
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
          await client.get(Uri.parse('http://localhost:${server!.port}'));
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
          await client.get(Uri.parse('http://localhost:${server!.port}'));
      expect(response.headers['list'], 'apple, orange, banana');
    });
  });
}

void main() {
  testServerHeaders(CocoaClient.sharedUrlSession());
  testClientHeaders(CocoaClient.sharedUrlSession());

//  testServerHeaders(http.Client());
//  testClientHeaders(http.Client());
}
