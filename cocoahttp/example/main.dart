import 'package:cocoahttp/cocoahttp.dart';

main() async {
  final Http http = CocaHttp();

  Response r = await http.get(Uri.parse("https://www.apple.com/"));
  print(String.fromCharCodes(r.body).substring(0, 200));
  r.headers.forEach((key, value) {
    print('$key: $value');
  });
}
