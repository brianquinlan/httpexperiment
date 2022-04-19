import 'dart:io';

main() async {
  final client = HttpClient();
  client.getUrl(Uri.parse("https://www.example.com")).then((request) => {
        request.close().then((response) {
          print(response.statusCode);
        })
      });
}
