import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'collab_transport.dart';

/// Native (`dart:io`) HTTP transport for Windows, macOS, Linux, Android, and iOS.
class IoCollabTransport implements CollabTransport {
  final HttpClient _client;
  final StreamController<Map<String, dynamic>> _tabController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _disposed = false;

  IoCollabTransport({HttpClient? client})
      : _client = client ?? (HttpClient()..connectionTimeout = const Duration(seconds: 10));

  @override
  bool get supportsBroadcastChannel => false;

  @override
  Stream<Map<String, dynamic>> get localTabMessages => _tabController.stream;

  @override
  void postLocalTabMessage(Map<String, dynamic> message) {
    // Native desktop/mobile apps use single-process memory or Firebase RTDB.
  }

  @override
  Future<CollabHttpResponse> request({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
  }) async {
    if (_disposed) {
      throw StateError('IoCollabTransport has been disposed.');
    }

    final req = await _client.openUrl(method.toUpperCase(), uri);
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (headers != null) {
      headers.forEach((key, value) {
        req.headers.set(key, value);
      });
    }

    final encoding = Encoding.getByName('utf-8');
    if (body != null && body.isNotEmpty) {
      req.add(encoding != null ? encoding.encode(body) : body.codeUnits);
    }

    final res = await req.close().timeout(const Duration(seconds: 12));
    final responseBody = encoding != null
        ? await res.transform(encoding.decoder).join()
        : await res.transform(systemEncoding.decoder).join();
    return CollabHttpResponse(
      statusCode: res.statusCode,
      body: responseBody,
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _client.close(force: true);
    _tabController.close();
  }
}

CollabTransport createCollabTransport() => IoCollabTransport();
