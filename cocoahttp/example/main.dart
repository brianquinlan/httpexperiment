import 'package:cocoahttp/cocoahttp.dart';

main() async {
  final Http http = CocaHttp();
  final uri = Uri.parse("https://www.apple.com/");

  final stopwatch = Stopwatch()..start();
  final Future<Response> rf = http.get(uri);
  print('http.get() returned a future in ${stopwatch.elapsed}');

  final r = await rf;
  print('Content is ${r.body.length} bytes');
  r.headers.forEach((key, value) {
    print('$key: $value');
  });
}
