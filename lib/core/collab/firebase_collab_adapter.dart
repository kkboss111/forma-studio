import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'collab_models.dart';
import 'collab_transport.dart';

/// Contract for real-time collaboration backends (Firebase RTDB, Web BroadcastChannel, LAN).
abstract class CollabBackendAdapter {
  bool get isConnected;
  String get adapterName;
  bool get isCloudSyncActive;
  bool get supportsBrowserTabSync;

  /// Creates a new room session and establishes host presence.
  Future<CollabSession> createRoom({
    required String roomName,
    required Collaborator host,
  });

  /// Joins an existing room session by its room code (e.g. 'FORMA-8392').
  Future<CollabSession> joinRoom({
    required String roomId,
    required Collaborator user,
  });

  /// Leaves the current room session and cleans up presence state.
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  });

  /// Broadcasts high-frequency live cursor coordinates.
  Future<void> broadcastCursor({
    required String roomId,
    required String userId,
    required Offset position,
  });

  /// Broadcasts structural canvas changes (node added, edited, deleted).
  Future<void> broadcastNodeDelta({
    required String roomId,
    required CollabDelta delta,
  });

  /// Broadcasts collaborator's active node selection IDs.
  Future<void> updateActiveNodes({
    required String roomId,
    required String userId,
    required Set<String> activeNodeIds,
  });

  /// Real-time stream of all connected participants in the room.
  Stream<List<Collaborator>> streamCollaborators(String roomId);

  /// Real-time stream of incoming remote node edits and deltas.
  Stream<CollabDelta> streamNodeDeltas(String roomId);

  /// Releases resources, timers, and active stream controllers.
  void dispose();
}

/// Cross-platform Firebase Realtime Database REST sync adapter with seamless
/// fallback to Web `BroadcastChannel` + Local/LAN Engine when no Firebase URL is set.
class FirebaseCollabAdapter implements CollabBackendAdapter {
  final String? firebaseProjectId;
  String? _realtimeDbUrl;
  String? _apiKey;
  final CollabTransport _transport;
  final bool _ownsTransport;
  final MockLanCollabAdapter _fallbackLanAdapter;

  bool _isRealtimeDbActive = false;
  String? _activeRoomId;
  String? _activeUserId;
  Timer? _pollTimer;
  bool _isPollingInFlight = false;
  final Set<String> _seenDeltaIds = {};
  String? _lastParticipantsFingerprint;
  bool? _lastRoomLocked;
  int _lastPingMs = 14;

  final StreamController<List<Collaborator>> _collaboratorsController =
      StreamController<List<Collaborator>>.broadcast();
  final StreamController<CollabDelta> _deltasController =
      StreamController<CollabDelta>.broadcast();

  FirebaseCollabAdapter({
    this.firebaseProjectId,
    String? realtimeDbUrl,
    String? apiKey,
    CollabTransport? transport,
    MockLanCollabAdapter? fallbackLanAdapter,
  })  : _realtimeDbUrl = _normalizeNullableUrl(realtimeDbUrl),
        _apiKey = apiKey?.trim().isEmpty == true ? null : apiKey?.trim(),
        _transport = transport ?? createPlatformCollabTransport(),
        _ownsTransport = transport == null,
        _fallbackLanAdapter = fallbackLanAdapter ??
            MockLanCollabAdapter(
              transport: transport,
            ) {
    // Share the platform transport with the fallback LAN adapter when we own it
    // unless a dedicated fallback was provided.
    if (fallbackLanAdapter == null && transport == null) {
      _fallbackLanAdapter._attachExternalTransport(_transport);
    }
    _initializeFirebaseConfig(logChange: false);
  }

  static String? _normalizeNullableUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Normalizes a Firebase Realtime Database URL by trimming whitespace and trailing slashes.
  static String normalizeDbUrl(String raw) {
    return raw.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Validates a Firebase Realtime Database URL (`firebaseio.com`, `firebasedatabase.app`,
  /// or any valid HTTP/HTTPS RTDB endpoint).
  static bool isValidRealtimeDbUrl(String? raw) {
    if (raw == null) return false;
    final normalized = normalizeDbUrl(raw);
    if (normalized.isEmpty) return false;
    final uri = Uri.tryParse(normalized);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  String? get realtimeDbUrl => _realtimeDbUrl;
  String? get apiKey => _apiKey;
  bool get isRealtimeDbActive => _isRealtimeDbActive;
  int get pingMs => _lastPingMs;

  @override
  bool get isCloudSyncActive => _isRealtimeDbActive;

  @override
  bool get supportsBrowserTabSync => _transport.supportsBroadcastChannel;

  @override
  String get adapterName => _isRealtimeDbActive
      ? 'Firebase Cloud RTDB'
      : _fallbackLanAdapter.adapterName;

  @override
  bool get isConnected =>
      (_isRealtimeDbActive && _activeRoomId != null) ||
      _fallbackLanAdapter.isConnected;

  /// Updates Firebase configuration at runtime and switches backend cleanly.
  void configure({String? realtimeDbUrl, String? apiKey}) {
    final normalized = _normalizeNullableUrl(realtimeDbUrl);
    final normalizedKey = apiKey?.trim().isEmpty == true ? null : apiKey?.trim();
    final changed = normalized != _realtimeDbUrl || normalizedKey != _apiKey;
    _realtimeDbUrl = normalized;
    _apiKey = normalizedKey;
    _initializeFirebaseConfig(logChange: changed);
  }

  void _initializeFirebaseConfig({required bool logChange}) {
    if (isValidRealtimeDbUrl(_realtimeDbUrl)) {
      _isRealtimeDbActive = true;
      if (logChange) {
        debugPrint(
          '[Collab] Switched backend to Firebase Cloud RTDB ($_realtimeDbUrl).',
        );
      }
    } else {
      _isRealtimeDbActive = false;
      _stopPolling();
      if (logChange) {
        debugPrint(
          '[Collab] Switched backend to ${_fallbackLanAdapter.adapterName}.',
        );
      }
    }
  }

  Uri _roomUri(String roomId, [String subPath = '']) {
    final cleanId = roomId.trim().toUpperCase();
    final suffix = subPath.isEmpty ? '' : '/$subPath';
    return Uri.parse('$_realtimeDbUrl/forma_rooms/$cleanId$suffix.json');
  }

  void _startPolling(String roomId) {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      _pollRoom(roomId);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPollingInFlight = false;
  }

  Future<void> _pollRoom(String roomId) async {
    if (!_isRealtimeDbActive || _activeRoomId != roomId || _isPollingInFlight) {
      return;
    }
    _isPollingInFlight = true;
    final sw = Stopwatch()..start();
    try {
      final res = await _transport.request(
        method: 'GET',
        uri: _roomUri(roomId),
      );
      sw.stop();
      _lastPingMs = sw.elapsedMilliseconds.clamp(1, 9999);
      if (!res.isOk) return;

      final body = res.body.trim();
      if (body.isEmpty || body == 'null') return;
      final decoded = jsonDecode(body);
      if (decoded is! Map) return;
      final roomMap = Map<String, dynamic>.from(decoded);

      // 1. Sync participants list
      final participants = _parseParticipants(roomMap['participants']);
      final fp = _fingerprintParticipants(participants);
      if (fp != _lastParticipantsFingerprint) {
        _lastParticipantsFingerprint = fp;
        if (!_collaboratorsController.isClosed) {
          _collaboratorsController.add(participants);
        }
      }

      // 2. Sync unseen deltas chronologically
      final newDeltas = _parseUnseenDeltas(roomMap['deltas']);
      bool sawRoomLockDelta = false;
      for (final d in newDeltas) {
        _seenDeltaIds.add(d.id);
        if (d.type == CollabDeltaType.roomLocked) {
          sawRoomLockDelta = true;
          _lastRoomLocked = d.payload?['isLocked'] as bool? ?? false;
        }
        if (!_deltasController.isClosed) {
          _deltasController.add(d);
        }
      }

      // 3. Reconcile lock state if modified externally without an explicit delta
      final locked = roomMap['isLocked'] as bool? ?? false;
      if (!sawRoomLockDelta && _lastRoomLocked != null && locked != _lastRoomLocked) {
        _lastRoomLocked = locked;
        final syntheticLock = CollabDelta.roomLocked(
          senderId: roomMap['hostId'] as String? ?? 'host',
          senderName: 'Host',
          isLocked: locked,
        );
        _seenDeltaIds.add(syntheticLock.id);
        if (!_deltasController.isClosed) {
          _deltasController.add(syntheticLock);
        }
      }
    } catch (_) {
      // Remain resilient across transient network drops while polling.
    } finally {
      _isPollingInFlight = false;
    }
  }

  List<Collaborator> _parseParticipants(dynamic rawParticipants) {
    final result = <Collaborator>[];
    if (rawParticipants is Map) {
      for (final entry in rawParticipants.entries) {
        if (entry.value is Map) {
          try {
            result.add(
              Collaborator.fromJson(Map<String, dynamic>.from(entry.value as Map)),
            );
          } catch (_) {}
        }
      }
    } else if (rawParticipants is List) {
      for (final item in rawParticipants) {
        if (item is Map) {
          try {
            result.add(Collaborator.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }
    return result;
  }

  List<CollabDelta> _parseUnseenDeltas(dynamic rawDeltas) {
    final result = <CollabDelta>[];
    if (rawDeltas is Map) {
      for (final entry in rawDeltas.entries) {
        if (entry.value is Map) {
          try {
            final map = Map<String, dynamic>.from(entry.value as Map);
            map['id'] ??= entry.key.toString();
            final delta = CollabDelta.fromJson(map);
            if (!_seenDeltaIds.contains(delta.id)) {
              result.add(delta);
            }
          } catch (_) {}
        }
      }
    } else if (rawDeltas is List) {
      for (final item in rawDeltas) {
        if (item is Map) {
          try {
            final delta = CollabDelta.fromJson(Map<String, dynamic>.from(item));
            if (!_seenDeltaIds.contains(delta.id)) {
              result.add(delta);
            }
          } catch (_) {}
        }
      }
    }
    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  void _markHistoricalKicksSeen(dynamic rawDeltas) {
    if (rawDeltas is Map) {
      for (final entry in rawDeltas.entries) {
        if (entry.value is Map) {
          final map = Map<String, dynamic>.from(entry.value as Map);
          final id = (map['id'] as String?) ?? entry.key.toString();
          if (map['type'] == CollabDeltaType.userKicked.name) {
            _seenDeltaIds.add(id);
          }
        }
      }
    }
  }

  String _fingerprintParticipants(List<Collaborator> list) {
    final sorted = List<Collaborator>.from(list)
      ..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .map(
          (c) =>
              '${c.id}:${c.name}:${c.role.name}:${c.isHost}:${c.cursorPosition?.dx},${c.cursorPosition?.dy}:${c.activeNodeIds.join(",")}',
        )
        .join('|');
  }

  @override
  Future<CollabSession> createRoom({
    required String roomName,
    required Collaborator host,
  }) async {
    if (!_isRealtimeDbActive) {
      return _fallbackLanAdapter.createRoom(roomName: roomName, host: host);
    }

    final roomId = _fallbackLanAdapter.generateRoomCode();
    final updatedHost = host.copyWith(
      isHost: true,
      role: CollaboratorRole.host,
      lastActive: DateTime.now(),
    );
    final now = DateTime.now();
    final resolvedRoomName =
        roomName.trim().isEmpty ? 'Forma Studio Session' : roomName.trim();

    final roomPayload = <String, dynamic>{
      'roomId': roomId,
      'roomName': resolvedRoomName,
      'hostId': updatedHost.id,
      'isConnected': true,
      'isLocked': false,
      'lastSyncedAt': now.toIso8601String(),
      'participants': <String, dynamic>{
        updatedHost.id: updatedHost.toJson(),
      },
    };

    final response = await _transport.request(
      method: 'PUT',
      uri: _roomUri(roomId),
      body: jsonEncode(roomPayload),
    );
    if (!response.isOk) {
      throw Exception(
        'Firebase RTDB createRoom failed (${response.statusCode}): ${response.body}',
      );
    }

    _activeRoomId = roomId;
    _activeUserId = updatedHost.id;
    _seenDeltaIds.clear();
    _lastRoomLocked = false;
    _lastParticipantsFingerprint = _fingerprintParticipants([updatedHost]);

    final session = CollabSession(
      roomId: roomId,
      roomName: resolvedRoomName,
      hostId: updatedHost.id,
      participants: [updatedHost],
      isConnected: true,
      isLocked: false,
      lastSyncedAt: now,
      currentUserId: updatedHost.id,
      customMetadata: {
        'provider': 'firebase',
        'rtdbUrl': _realtimeDbUrl,
        if (firebaseProjectId != null)
          'firestoreDoc': 'projects/$firebaseProjectId/rooms/$roomId',
      },
    );

    if (!_collaboratorsController.isClosed) {
      _collaboratorsController.add([updatedHost]);
    }
    _startPolling(roomId);
    return session;
  }

  @override
  Future<CollabSession> joinRoom({
    required String roomId,
    required Collaborator user,
  }) async {
    if (!_isRealtimeDbActive) {
      return _fallbackLanAdapter.joinRoom(roomId: roomId, user: user);
    }

    final cleanRoomId = roomId.trim().toUpperCase();
    final getRes = await _transport.request(
      method: 'GET',
      uri: _roomUri(cleanRoomId),
    );
    if (!getRes.isOk) {
      throw Exception(
        'Firebase RTDB joinRoom failed (${getRes.statusCode}): ${getRes.body}',
      );
    }

    final trimmedBody = getRes.body.trim();
    if (trimmedBody.isEmpty || trimmedBody == 'null') {
      throw Exception('Room $cleanRoomId was not found on Firebase.');
    }

    final decoded = jsonDecode(trimmedBody);
    if (decoded is! Map) {
      throw Exception('Invalid room data returned by Firebase for $cleanRoomId.');
    }

    final roomMap = Map<String, dynamic>.from(decoded);
    final isLocked = roomMap['isLocked'] as bool? ?? false;
    if (isLocked) {
      throw Exception('Room $cleanRoomId is locked by the host.');
    }

    final hostId = roomMap['hostId'] as String? ?? '';
    final roomName =
        roomMap['roomName'] as String? ?? 'Collaborative Room ($cleanRoomId)';
    final isJoiningHost = user.id == hostId;
    final updatedUser = user.copyWith(
      isHost: isJoiningHost,
      role: isJoiningHost ? CollaboratorRole.host : CollaboratorRole.editor,
      lastActive: DateTime.now(),
    );

    final patchRes = await _transport.request(
      method: 'PATCH',
      uri: _roomUri(cleanRoomId, 'participants/${updatedUser.id}'),
      body: jsonEncode(updatedUser.toJson()),
    );
    if (!patchRes.isOk) {
      throw Exception(
        'Firebase RTDB failed to register participant (${patchRes.statusCode}): ${patchRes.body}',
      );
    }

    final participants = _parseParticipants(roomMap['participants']);
    final existingIdx = participants.indexWhere((p) => p.id == updatedUser.id);
    if (existingIdx >= 0) {
      participants[existingIdx] = updatedUser;
    } else {
      participants.add(updatedUser);
    }

    _activeRoomId = cleanRoomId;
    _activeUserId = updatedUser.id;
    _seenDeltaIds.clear();
    _markHistoricalKicksSeen(roomMap['deltas']);
    _lastRoomLocked = false;
    _lastParticipantsFingerprint = _fingerprintParticipants(participants);

    final session = CollabSession(
      roomId: cleanRoomId,
      roomName: roomName,
      hostId: hostId,
      participants: participants,
      isConnected: true,
      isLocked: false,
      lastSyncedAt: DateTime.now(),
      currentUserId: updatedUser.id,
      customMetadata: {
        'provider': 'firebase',
        'rtdbUrl': _realtimeDbUrl,
      },
    );

    if (!_collaboratorsController.isClosed) {
      _collaboratorsController.add(participants);
    }
    _startPolling(cleanRoomId);
    return session;
  }

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    if (!_isRealtimeDbActive) {
      return _fallbackLanAdapter.leaveRoom(roomId: roomId, userId: userId);
    }

    final cleanRoomId = roomId.trim().toUpperCase();
    _stopPolling();
    try {
      await _transport.request(
        method: 'DELETE',
        uri: _roomUri(cleanRoomId, 'participants/$userId'),
      );
    } catch (_) {
      // Always finish local cleanup even when offline.
    }
    if (_activeRoomId == cleanRoomId) {
      _activeRoomId = null;
      _activeUserId = null;
    }
    _lastParticipantsFingerprint = null;
  }

  @override
  Future<void> broadcastCursor({
    required String roomId,
    required String userId,
    required Offset position,
  }) async {
    if (!_isRealtimeDbActive) {
      return _fallbackLanAdapter.broadcastCursor(
        roomId: roomId,
        userId: userId,
        position: position,
      );
    }

    try {
      await _transport.request(
        method: 'PATCH',
        uri: _roomUri(roomId, 'participants/$userId'),
        body: jsonEncode({
          'cursorPosition': {
            'dx': position.dx,
            'dy': position.dy,
          },
          'lastActive': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  @override
  Future<void> broadcastNodeDelta({
    required String roomId,
    required CollabDelta delta,
  }) async {
    if (!_isRealtimeDbActive) {
      return _fallbackLanAdapter.broadcastNodeDelta(
        roomId: roomId,
        delta: delta,
      );
    }

    _seenDeltaIds.add(delta.id);
    if (!_deltasController.isClosed) {
      _deltasController.add(delta);
    }

    await _transport.request(
      method: 'POST',
      uri: _roomUri(roomId, 'deltas'),
      body: jsonEncode(delta.toJson()),
    );

    // Sync authoritative RTDB room metadata for operator controls
    if (delta.type == CollabDeltaType.roomLocked) {
      final locked = delta.payload?['isLocked'] as bool? ?? false;
      _lastRoomLocked = locked;
      await _transport.request(
        method: 'PATCH',
        uri: _roomUri(roomId),
        body: jsonEncode({'isLocked': locked}),
      );
    } else if (delta.type == CollabDeltaType.roleChanged) {
      final targetId = delta.payload?['targetUserId'] as String?;
      final newRole = delta.payload?['newRole'] as String?;
      if (targetId != null && newRole != null) {
        await _transport.request(
          method: 'PATCH',
          uri: _roomUri(roomId, 'participants/$targetId'),
          body: jsonEncode({'role': newRole}),
        );
      }
    } else if (delta.type == CollabDeltaType.userKicked) {
      final targetId = delta.payload?['targetUserId'] as String?;
      if (targetId != null) {
        await _transport.request(
          method: 'DELETE',
          uri: _roomUri(roomId, 'participants/$targetId'),
        );
      }
    }
  }

  @override
  Future<void> updateActiveNodes({
    required String roomId,
    required String userId,
    required Set<String> activeNodeIds,
  }) async {
    if (!_isRealtimeDbActive) {
      return _fallbackLanAdapter.updateActiveNodes(
        roomId: roomId,
        userId: userId,
        activeNodeIds: activeNodeIds,
      );
    }

    try {
      await _transport.request(
        method: 'PATCH',
        uri: _roomUri(roomId, 'participants/$userId'),
        body: jsonEncode({
          'activeNodeIds': activeNodeIds.toList(),
          'lastActive': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  @override
  Stream<List<Collaborator>> streamCollaborators(String roomId) {
    if (!_isRealtimeDbActive) {
      return _fallbackLanAdapter.streamCollaborators(roomId);
    }
    return _collaboratorsController.stream;
  }

  @override
  Stream<CollabDelta> streamNodeDeltas(String roomId) {
    if (!_isRealtimeDbActive) {
      return _fallbackLanAdapter.streamNodeDeltas(roomId);
    }
    return _deltasController.stream;
  }

  String? get activeRoomId => _activeRoomId;
  String? get activeUserId => _activeUserId;

  @override
  void dispose() {
    _stopPolling();
    _collaboratorsController.close();
    _deltasController.close();
    _fallbackLanAdapter.dispose();
    if (_ownsTransport) {
      _transport.dispose();
    }
  }
}

/// Fallback offline / local LAN + Web `BroadcastChannel` room provider.
/// Holds only real connected human designers (zero fake bot users).
class MockLanCollabAdapter implements CollabBackendAdapter {
  static final Map<String, CollabSession> _lanSessions = {};
  static final Map<String, StreamController<List<Collaborator>>>
      _collaboratorControllers = {};
  static final Map<String, StreamController<CollabDelta>> _deltaControllers = {};
  static int _instanceCounter = 0;

  final math.Random _random = math.Random();
  late final String _instanceId;
  CollabTransport _transport;
  bool _ownsTransport;
  StreamSubscription<Map<String, dynamic>>? _tabSub;
  final Map<String, Completer<CollabSession?>> _discoverCompleters = {};

  bool _connected = false;
  String? _activeRoomId;
  String? _activeUserId;

  MockLanCollabAdapter({CollabTransport? transport})
      : _transport = transport ?? createPlatformCollabTransport(),
        _ownsTransport = transport == null {
    _instanceCounter++;
    _instanceId = 'tab_${_instanceCounter}_${_random.nextInt(999999)}';
    _subscribeToTabMessages();
  }

  void _attachExternalTransport(CollabTransport externalTransport) {
    if (_ownsTransport) {
      _tabSub?.cancel();
      _transport.dispose();
    }
    _transport = externalTransport;
    _ownsTransport = false;
    _subscribeToTabMessages();
  }

  void _subscribeToTabMessages() {
    _tabSub?.cancel();
    _tabSub = _transport.localTabMessages.listen(_handleTabMessage);
  }

  @override
  String get adapterName => _transport.supportsBroadcastChannel
      ? 'Web Browser Tab Sync (BroadcastChannel)'
      : 'Forma Local / LAN Engine';

  @override
  bool get isConnected => _connected;

  @override
  bool get isCloudSyncActive => false;

  @override
  bool get supportsBrowserTabSync => _transport.supportsBroadcastChannel;

  String? get activeRoomId => _activeRoomId;
  String? get activeUserId => _activeUserId;

  /// Generates a crisp 6-character room code (e.g. 'FORMA-8392').
  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(4, (_) => chars[_random.nextInt(chars.length)]).join();
    return 'FORMA-$code';
  }

  StreamController<List<Collaborator>> _getCollaboratorsController(String roomId) {
    final cleanId = roomId.trim().toUpperCase();
    final existing = _collaboratorControllers[cleanId];
    if (existing != null && !existing.isClosed) {
      return existing;
    }
    final created = StreamController<List<Collaborator>>.broadcast();
    _collaboratorControllers[cleanId] = created;
    return created;
  }

  StreamController<CollabDelta> _getDeltasController(String roomId) {
    final cleanId = roomId.trim().toUpperCase();
    final existing = _deltaControllers[cleanId];
    if (existing != null && !existing.isClosed) {
      return existing;
    }
    final created = StreamController<CollabDelta>.broadcast();
    _deltaControllers[cleanId] = created;
    return created;
  }

  void _handleTabMessage(Map<String, dynamic> msg) {
    if (msg['senderTabId'] == _instanceId) return;
    final event = msg['event'] as String?;
    final rawRoomId = msg['roomId'] as String?;
    if (event == null || rawRoomId == null) return;
    final roomId = rawRoomId.trim().toUpperCase();

    switch (event) {
      case 'room_created':
      case 'room_state':
        final rawSession = msg['session'];
        if (rawSession is Map) {
          try {
            final session = CollabSession.fromJson(
              Map<String, dynamic>.from(rawSession),
            );
            _lanSessions[roomId] = session;
            _getCollaboratorsController(roomId).add(session.participants);
            final completer = _discoverCompleters.remove(roomId);
            if (completer != null && !completer.isCompleted) {
              completer.complete(session);
            }
          } catch (_) {}
        }
        break;

      case 'room_discover':
        final session = _lanSessions[roomId];
        if (session != null && (_activeRoomId == roomId || session.participants.isNotEmpty)) {
          _transport.postLocalTabMessage({
            'event': 'room_state',
            'senderTabId': _instanceId,
            'roomId': roomId,
            'session': session.toJson(),
          });
        }
        break;

      case 'participant_joined':
        final session = _lanSessions[roomId];
        final rawUser = msg['user'];
        if (session != null && rawUser is Map) {
          try {
            final user = Collaborator.fromJson(Map<String, dynamic>.from(rawUser));
            final idx = session.participants.indexWhere((p) => p.id == user.id);
            final updated = List<Collaborator>.from(session.participants);
            if (idx >= 0) {
              updated[idx] = user;
            } else {
              updated.add(user);
            }
            _lanSessions[roomId] = session.copyWith(
              participants: updated,
              lastSyncedAt: DateTime.now(),
            );
            _getCollaboratorsController(roomId).add(updated);
          } catch (_) {}
        }
        break;

      case 'participant_left':
        final session = _lanSessions[roomId];
        final userId = msg['userId'] as String?;
        if (session != null && userId != null) {
          final updated =
              session.participants.where((p) => p.id != userId).toList();
          _lanSessions[roomId] = session.copyWith(participants: updated);
          _getCollaboratorsController(roomId).add(updated);
        }
        break;

      case 'cursor_moved':
        final session = _lanSessions[roomId];
        final userId = msg['userId'] as String?;
        final dx = (msg['dx'] as num?)?.toDouble();
        final dy = (msg['dy'] as num?)?.toDouble();
        if (session != null && userId != null && dx != null && dy != null) {
          final updated = session.participants.map((p) {
            if (p.id == userId) {
              return p.copyWith(
                cursorPosition: Offset(dx, dy),
                lastActive: DateTime.now(),
              );
            }
            return p;
          }).toList();
          _lanSessions[roomId] = session.copyWith(participants: updated);
          _getCollaboratorsController(roomId).add(updated);
        }
        break;

      case 'active_nodes':
        final session = _lanSessions[roomId];
        final userId = msg['userId'] as String?;
        final rawIds = msg['activeNodeIds'] as List<dynamic>?;
        if (session != null && userId != null && rawIds != null) {
          final nodeIds = rawIds.map((e) => e.toString()).toSet();
          final updated = session.participants.map((p) {
            if (p.id == userId) {
              return p.copyWith(
                activeNodeIds: nodeIds,
                lastActive: DateTime.now(),
              );
            }
            return p;
          }).toList();
          _lanSessions[roomId] = session.copyWith(participants: updated);
          _getCollaboratorsController(roomId).add(updated);
        }
        break;

      case 'delta':
        final rawDelta = msg['delta'];
        if (rawDelta is Map) {
          try {
            final delta = CollabDelta.fromJson(
              Map<String, dynamic>.from(rawDelta),
            );
            _applyOperatorDeltaLocally(roomId, delta);
            _getDeltasController(roomId).add(delta);
          } catch (_) {}
        }
        break;
    }
  }

  void _applyOperatorDeltaLocally(String roomId, CollabDelta delta) {
    final session = _lanSessions[roomId];
    if (session == null) return;
    if (delta.type == CollabDeltaType.roomLocked) {
      final isLocked = delta.payload?['isLocked'] as bool? ?? false;
      _lanSessions[roomId] = session.copyWith(isLocked: isLocked);
    } else if (delta.type == CollabDeltaType.roleChanged) {
      final targetId = delta.payload?['targetUserId'] as String?;
      final roleName = delta.payload?['newRole'] as String?;
      if (targetId != null && roleName != null) {
        final newRole = CollaboratorRole.values.firstWhere(
          (r) => r.name == roleName,
          orElse: () => CollaboratorRole.editor,
        );
        final updated = session.participants
            .map((p) => p.id == targetId ? p.copyWith(role: newRole) : p)
            .toList();
        _lanSessions[roomId] = session.copyWith(participants: updated);
        _getCollaboratorsController(roomId).add(updated);
      }
    } else if (delta.type == CollabDeltaType.userKicked) {
      final targetId = delta.payload?['targetUserId'] as String?;
      if (targetId != null) {
        final updated =
            session.participants.where((p) => p.id != targetId).toList();
        _lanSessions[roomId] = session.copyWith(participants: updated);
        _getCollaboratorsController(roomId).add(updated);
      }
    }
  }

  @override
  Future<CollabSession> createRoom({
    required String roomName,
    required Collaborator host,
  }) async {
    final roomId = generateRoomCode();
    final updatedHost = host.copyWith(isHost: true, role: CollaboratorRole.host);

    // Contains ONLY the real hosting designer (no fake bots)
    final initialParticipants = [updatedHost];

    final session = CollabSession(
      roomId: roomId,
      roomName: roomName.trim().isEmpty ? 'Forma Shared Workspace' : roomName.trim(),
      hostId: updatedHost.id,
      participants: initialParticipants,
      isConnected: true,
      lastSyncedAt: DateTime.now(),
      currentUserId: updatedHost.id,
      customMetadata: {
        'engine': _transport.supportsBroadcastChannel ? 'broadcast_channel' : 'mock_lan',
        'created': DateTime.now().toIso8601String(),
      },
    );

    _lanSessions[roomId] = session;
    _connected = true;
    _activeRoomId = roomId;
    _activeUserId = updatedHost.id;

    _getCollaboratorsController(roomId).add(initialParticipants);
    _transport.postLocalTabMessage({
      'event': 'room_created',
      'senderTabId': _instanceId,
      'roomId': roomId,
      'session': session.toJson(),
    });

    return session;
  }

  @override
  Future<CollabSession> joinRoom({
    required String roomId,
    required Collaborator user,
  }) async {
    final cleanRoomId = roomId.trim().toUpperCase();
    var session = _lanSessions[cleanRoomId];

    // On Web (or BroadcastChannel-enabled transport), discover room from sibling tabs
    if (session == null && _transport.supportsBroadcastChannel) {
      final completer = Completer<CollabSession?>();
      _discoverCompleters[cleanRoomId] = completer;
      _transport.postLocalTabMessage({
        'event': 'room_discover',
        'senderTabId': _instanceId,
        'roomId': cleanRoomId,
      });
      try {
        session = await completer.future.timeout(
          const Duration(milliseconds: 180),
          onTimeout: () => null,
        );
      } finally {
        _discoverCompleters.remove(cleanRoomId);
      }
    }

    if (session == null) {
      // If room was not yet hosted locally, initialize clean session with this user as host
      final updatedUser = user.copyWith(isHost: true, role: CollaboratorRole.host);
      session = CollabSession(
        roomId: cleanRoomId,
        roomName: 'Collaborative Room ($cleanRoomId)',
        hostId: updatedUser.id,
        participants: [updatedUser],
        isConnected: true,
        lastSyncedAt: DateTime.now(),
        currentUserId: updatedUser.id,
      );
      _lanSessions[cleanRoomId] = session;
      _transport.postLocalTabMessage({
        'event': 'room_created',
        'senderTabId': _instanceId,
        'roomId': cleanRoomId,
        'session': session.toJson(),
      });
    } else {
      if (session.isLocked) {
        return session;
      }

      // Real peer joins the existing room session
      final updatedUser = user.copyWith(
        isHost: user.id == session.hostId,
        role: user.id == session.hostId ? CollaboratorRole.host : CollaboratorRole.editor,
      );

      final existingIndex =
          session.participants.indexWhere((p) => p.id == updatedUser.id);
      List<Collaborator> updatedParticipants;
      if (existingIndex >= 0) {
        updatedParticipants = List.from(session.participants)..[existingIndex] = updatedUser;
      } else {
        updatedParticipants = [...session.participants, updatedUser];
      }

      session = session.copyWith(
        participants: updatedParticipants,
        isConnected: true,
        currentUserId: updatedUser.id,
        lastSyncedAt: DateTime.now(),
      );
      _lanSessions[cleanRoomId] = session;

      _transport.postLocalTabMessage({
        'event': 'participant_joined',
        'senderTabId': _instanceId,
        'roomId': cleanRoomId,
        'user': updatedUser.toJson(),
      });
    }

    _connected = true;
    _activeRoomId = cleanRoomId;
    _activeUserId = user.id;

    _getCollaboratorsController(cleanRoomId).add(session.participants);

    return session;
  }

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    final cleanRoomId = roomId.trim().toUpperCase();
    final session = _lanSessions[cleanRoomId];
    if (session != null) {
      final updatedParticipants =
          session.participants.where((p) => p.id != userId).toList();
      final updatedSession = session.copyWith(
        participants: updatedParticipants,
        isConnected: false,
      );
      _lanSessions[cleanRoomId] = updatedSession;
      _getCollaboratorsController(cleanRoomId).add(updatedParticipants);
      _transport.postLocalTabMessage({
        'event': 'participant_left',
        'senderTabId': _instanceId,
        'roomId': cleanRoomId,
        'userId': userId,
      });
    }
    _connected = false;
    _activeRoomId = null;
    _activeUserId = null;
  }

  @override
  Future<void> broadcastCursor({
    required String roomId,
    required String userId,
    required Offset position,
  }) async {
    final cleanRoomId = roomId.trim().toUpperCase();
    final session = _lanSessions[cleanRoomId];
    if (session == null) return;

    final updatedParticipants = session.participants.map((p) {
      if (p.id == userId) {
        return p.copyWith(cursorPosition: position, lastActive: DateTime.now());
      }
      return p;
    }).toList();

    final updatedSession = session.copyWith(participants: updatedParticipants);
    _lanSessions[cleanRoomId] = updatedSession;
    _getCollaboratorsController(cleanRoomId).add(updatedParticipants);
    _transport.postLocalTabMessage({
      'event': 'cursor_moved',
      'senderTabId': _instanceId,
      'roomId': cleanRoomId,
      'userId': userId,
      'dx': position.dx,
      'dy': position.dy,
    });
  }

  @override
  Future<void> broadcastNodeDelta({
    required String roomId,
    required CollabDelta delta,
  }) async {
    final cleanRoomId = roomId.trim().toUpperCase();
    _applyOperatorDeltaLocally(cleanRoomId, delta);
    _getDeltasController(cleanRoomId).add(delta);
    _transport.postLocalTabMessage({
      'event': 'delta',
      'senderTabId': _instanceId,
      'roomId': cleanRoomId,
      'delta': delta.toJson(),
    });
  }

  @override
  Future<void> updateActiveNodes({
    required String roomId,
    required String userId,
    required Set<String> activeNodeIds,
  }) async {
    final cleanRoomId = roomId.trim().toUpperCase();
    final session = _lanSessions[cleanRoomId];
    if (session == null) return;

    final updatedParticipants = session.participants.map((p) {
      if (p.id == userId) {
        return p.copyWith(
          activeNodeIds: activeNodeIds,
          lastActive: DateTime.now(),
        );
      }
      return p;
    }).toList();

    _lanSessions[cleanRoomId] = session.copyWith(participants: updatedParticipants);
    _getCollaboratorsController(cleanRoomId).add(updatedParticipants);
    _transport.postLocalTabMessage({
      'event': 'active_nodes',
      'senderTabId': _instanceId,
      'roomId': cleanRoomId,
      'userId': userId,
      'activeNodeIds': activeNodeIds.toList(),
    });
  }

  @override
  Stream<List<Collaborator>> streamCollaborators(String roomId) {
    final cleanRoomId = roomId.trim().toUpperCase();
    return _getCollaboratorsController(cleanRoomId).stream;
  }

  @override
  Stream<CollabDelta> streamNodeDeltas(String roomId) {
    final cleanRoomId = roomId.trim().toUpperCase();
    return _getDeltasController(cleanRoomId).stream;
  }

  @override
  void dispose() {
    _tabSub?.cancel();
    _tabSub = null;
    if (_ownsTransport) {
      _transport.dispose();
    }
    // Keep static room controllers alive only if shared across active instances;
    // when single instance disposes, close active room controllers only if needed.
    // Note: in multi-instance unit tests, closing static controllers when one
    // instance disposes could break a sibling instance until re-created, and
    // _getCollaboratorsController recreates closed controllers on demand.
    for (final ctrl in _collaboratorControllers.values) {
      ctrl.close();
    }
    _collaboratorControllers.clear();
    for (final ctrl in _deltaControllers.values) {
      ctrl.close();
    }
    _deltaControllers.clear();
  }
}
