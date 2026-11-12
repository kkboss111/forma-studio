import 'dart:async';

import 'collab_transport_stub.dart'
    if (dart.library.io) 'collab_transport_io.dart'
    if (dart.library.js_interop) 'collab_transport_web.dart' as platform;

/// Lightweight HTTP response wrapper shared across native, web, and mock transports.
class CollabHttpResponse {
  final int statusCode;
  final String body;

  const CollabHttpResponse({
    required this.statusCode,
    required this.body,
  });

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

/// Cross-platform transport interface for Firebase RTDB REST calls and
/// same-origin browser tab synchronization (`BroadcastChannel`).
abstract class CollabTransport {
  /// Executes an HTTP REST request (`GET`, `PUT`, `PATCH`, `POST`, `DELETE`).
  Future<CollabHttpResponse> request({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
  });

  /// Stream of JSON payloads broadcast from other local tabs/isolates.
  Stream<Map<String, dynamic>> get localTabMessages;

  /// Broadcasts a JSON payload to sibling browser tabs on the same origin.
  void postLocalTabMessage(Map<String, dynamic> message);

  /// Whether cross-tab `BroadcastChannel` transport is available on this platform.
  bool get supportsBroadcastChannel;

  /// Releases transport resources and stream controllers.
  void dispose();
}

/// Instantiates the appropriate [CollabTransport] for the current runtime target.
CollabTransport createPlatformCollabTransport() => platform.createCollabTransport();
