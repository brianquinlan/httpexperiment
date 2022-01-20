import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platformhttp/platformhttp.dart';

void main() {
  const MethodChannel channel = MethodChannel('platformhttp');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
//    channel.setMockMethodCallHandler((MethodCall methodCall) async {
    //     return '42';
    //   });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(
        await Platformhttp.getUrl(Uri.parse("https://www.google.com/")), '42');
  });
}
