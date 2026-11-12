import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'collab_transport.dart';

/// Web browser transport using `window.fetch` for Firebase RTDB REST calls
/// and `BroadcastChannel('forma_studio_collab')` for 0ms cross-tab sync.
class WebCollabTransport implements CollabTransport {
  static const String channelName = 'forma_studio_collab';

  final StreamController<Map<String, dynamic>> _tabController =
      StreamController<Map<String, dynamic>>.broadcast();

  web.BroadcastChannel? _channel;
  StreamSubscription<web.MessageEvent>? _channelSub;
  bool _disposed = false;

  WebCollabTransport() {
    _initBroadcastChannel();
  }

  void _initBroadcastChannel() {
    try {
      final channel = web.BroadcastChannel(channelName);
      _channel = channel;
      _channelSub =
          web.EventStreamProviders.messageEvent.forTarget(channel).listen((event) {
        final rawData = event.data;
        if (rawData == null) return;
        try {
          if (rawData.isA<JSString>()) {
            final decoded = jsonDecode((rawData as JSString).toDart);
            if (decoded is Map<String, dynamic>) {
              _tabController.add(decoded);
            } else if (decoded is Map) {
              _tabController.add(Map<String, dynamic>.from(decoded));
            }
          }
        } catch (_) {
          // Ignore malformed broadcast messages from external tabs.
        }
      });
    } catch (_) {
      // BroadcastChannel may be unavailable in restricted contexts.
      _channel = null;
    }
  }

  @override
  bool get supportsBroadcastChannel => _channel != null;

  @override
  Stream<Map<String, dynamic>> get localTabMessages => _tabController.stream;

  @override
  void postLocalTabMessage(Map<String, dynamic> message) {
    if (_disposed || _channel == null) return;
    try {
      _channel!.postMessage(jsonEncode(message).toJS);
    } catch (_) {
      // Ignore transient post errors on closing tabs.
    }
  }

  @override
  Future<CollabHttpResponse> request({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
  }) async {
    if (_disposed) {
      throw StateError('WebCollabTransport has been disposed.');
    }

    final upperMethod = method.toUpperCase();
    final jsHeaders = web.Headers();
    jsHeaders.set('Content-Type', 'application/json; charset=utf-8');
    jsHeaders.set('Accept', 'application/json');
    headers?.forEach((key, value) {
      jsHeaders.set(key, value);
    });

    final hasBody =
        body != null && body.isNotEmpty && upperMethod != 'GET' && upperMethod != 'HEAD';

    final init = hasBody
        ? web.RequestInit(
            method: upperMethod,
            headers: jsHeaders,
            body: body.toJS,
          )
        : web.RequestInit(
            method: upperMethod,
            headers: jsHeaders,
          );

    final response = await web.window.fetch(uri.toString().toJS, init).toDart;
    final text = (await response.text().toDart).toDart;

    return CollabHttpResponse(
      statusCode: response.status,
      body: text,
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _channelSub?.cancel();
    _channelSub = null;
    try {
      _channel?.close();
    } catch (_) {}
    _channel = null;
    _tabController.close();
  }
}

CollabTransport createCollabTransport() => WebCollabTransport();
