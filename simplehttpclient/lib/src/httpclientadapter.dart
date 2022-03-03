class _HttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  // TODO: implement certificate
  X509Certificate? get certificate => throw UnimplementedError();

  @override
  // TODO: implement compressionState
  HttpClientResponseCompressionState get compressionState =>
      throw UnimplementedError();

  @override
  // TODO: implement connectionInfo
  HttpConnectionInfo? get connectionInfo => throw UnimplementedError();

  @override
  // TODO: implement contentLength
  int get contentLength => throw UnimplementedError();

  @override
  // TODO: implement cookies
  List<Cookie> get cookies => throw UnimplementedError();

  @override
  Future<Socket> detachSocket() {
    // TODO: implement detachSocket
    throw UnimplementedError();
  }

  @override
  // TODO: implement headers
  HttpHeaders get headers => throw UnimplementedError();

  @override
  // TODO: implement isRedirect
  bool get isRedirect => throw UnimplementedError();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    // TODO: implement listen
    throw UnimplementedError();
  }

  @override
  // TODO: implement persistentConnection
  bool get persistentConnection => throw UnimplementedError();

  @override
  // TODO: implement reasonPhrase
  String get reasonPhrase => throw UnimplementedError();

  @override
  Future<HttpClientResponse> redirect(
      [String? method, Uri? url, bool? followLoops]) {
    // TODO: implement redirect
    throw UnimplementedError();
  }

  @override
  // TODO: implement redirects
  List<RedirectInfo> get redirects => throw UnimplementedError();

  @override
  // TODO: implement statusCode
  int get statusCode => throw UnimplementedError();
}

class _HttpClientRequest
    implements HttpClientRequest, StreamConsumer<List<int>> {
  SimpleHttpClient _httpClient;
  late IOSink _sink;
  List<int> _body = [];
  Uri _uri;

  @override
  bool bufferOutput;

  @override
  int contentLength;

  @override
  Encoding get encoding => _sink.encoding;

  @override
  set encoding(Encoding e) => _sink.encoding = e;

  @override
  bool followRedirects;

  @override
  int maxRedirects;

  @override
  bool persistentConnection;

  _HttpClientRequest(this._httpClient, this._uri) {
    _sink = IOSink(this);
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    // TODO: implement abort
  }

  @override
  void add(List<int> data) {
    _body.addAll(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // TODO: implement addError
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    stream.forEach((element) => _body.addAll(element));
    return Future.value();
  }

  @override
  Future<HttpClientResponse> close() {
    this._httpClient.get(uri).then((resp) {});
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  // TODO: implement connectionInfo
  HttpConnectionInfo? get connectionInfo => throw UnimplementedError();

  @override
  // TODO: implement cookies
  List<Cookie> get cookies => throw UnimplementedError();

  @override
  // TODO: implement done
  Future<HttpClientResponse> get done => throw UnimplementedError();

  @override
  Future flush() {
    // TODO: implement flush
    throw UnimplementedError();
  }

  @override
  // TODO: implement headers
  HttpHeaders get headers => throw UnimplementedError();

  @override
  // TODO: implement method
  String get method => throw UnimplementedError();

  @override
  Uri get uri => _uri;

  @override
  void write(Object? object) {
    _sink.write(object);
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    _sink.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) {
    _sink.writeCharCode(charCode);
  }

  @override
  void writeln([Object? object = ""]) {
    _sink.writeln(object);
  }
}

class _HttpClientAdapter implements HttpClient {
  noSuchMethod(Invocation invocation) {
    super.noSuchMethod(invocation);
  }

  @override
  void close({bool force = false}) {
    // TODO: implement close
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    // TODO: implement getUrl
    throw UnimplementedError();
  }
}
