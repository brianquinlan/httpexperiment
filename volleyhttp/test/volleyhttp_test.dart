import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyhttp/volleyhttp.dart';

void main() {
  const MethodChannel channel = MethodChannel('volleyhttp');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Volleyhttp.platformVersion, '42');
  });
}
