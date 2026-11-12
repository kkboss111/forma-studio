import 'dart:async';
import 'collab_transport.dart';

/// Fallback in-memory / no-network stub transport for unsupported targets or tests.
class StubCollabTransport implements CollabTransport {
  final StreamController<Map<String, dynamic>> _tabController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  bool get supportsBroadcastChannel => false;

  @override
  Stream<Map<String, dynamic>> get localTabMessages => _tabController.stream;

  @override
  void postLocalTabMessage(Map<String, dynamic> message) {
    // No-op on stub target.
  }

  @override
  Future<CollabHttpResponse> request({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
  }) async {
    throw UnsupportedError(
      'HTTP transport is not supported on this platform stub ($method $uri).',
    );
  }

  @override
  void dispose() {
    _tabController.close();
  }
}

CollabTransport createCollabTransport() => StubCollabTransport();
