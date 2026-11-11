import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'collab_models.dart';
import 'firebase_collab_adapter.dart';

/// Central real-time multi-user collaboration engine.
/// Coordinates session presence, live cursor synchronization, delta broadcasting,
/// and local vs remote state reconciliation.
class CollabService extends ChangeNotifier {
  final CollabBackendAdapter _adapter;
  final Uuid _uuid = const Uuid();

  CollabSession? _session;
  Collaborator? _localUser;
  List<Collaborator> _activeCollaborators = [];
  bool _showRemoteCursors = true;
  bool _isConnecting = false;
  String? _errorMessage;

  StreamSubscription<List<Collaborator>>? _collabSub;
  StreamSubscription<CollabDelta>? _deltaSub;

  final StreamController<CollabSession?> _sessionController =
      StreamController<CollabSession?>.broadcast();
  final StreamController<CollabDelta> _incomingDeltaController =
      StreamController<CollabDelta>.broadcast();

  // High-frequency cursor throttling (30-40 fps transmission budget)
  Timer? _cursorThrottleTimer;
  Offset? _pendingCursorPosition;

  CollabService({CollabBackendAdapter? adapter})
      : _adapter = adapter ?? FirebaseCollabAdapter() {
    _initDefaultUser();
  }

  // ===========================================================================
  // Getters & Public Properties
  // ===========================================================================
  CollabSession? get session => _session;
  CollabSession? get currentSession => _session;
  Collaborator? get localUser => _localUser;
  bool get isConnected => _session != null && _session!.isConnected;
  bool get isConnecting => _isConnecting;
  bool get showRemoteCursors => _showRemoteCursors;
  String? get errorMessage => _errorMessage;
  String get adapterName => _adapter.adapterName;

  /// Current active collaborators list (including local user if connected).
  List<Collaborator> get activeCollaborators => _activeCollaborators;

  /// Remote collaborators list (excluding the local designer).
  List<Collaborator> get remoteCollaborators {
    if (_localUser == null) return _activeCollaborators;
    return _activeCollaborators.where((c) => c.id != _localUser!.id).toList();
  }

  /// Live streams
  Stream<CollabSession?> get sessionStream => _sessionController.stream;
  Stream<List<Collaborator>> get collaboratorsStream => _adapter.streamCollaborators(_session?.roomId ?? '');
  Stream<CollabDelta> get incomingDeltaStream => _incomingDeltaController.stream;

  void _initDefaultUser() {
    final userId = 'usr_${_uuid.v4().substring(0, 8)}';
    final userColor = CollaboratorColorPalette.getColorForId(userId);
    _localUser = Collaborator(
      id: userId,
      name: 'Designer',
      color: userColor,
      lastActive: DateTime.now(),
    );
  }

  /// Sets or customizes local designer identity profile.
  void setLocalProfile({required String name, Color? color, String? avatarUrl}) {
    if (_localUser == null) {
      _initDefaultUser();
    }
    _localUser = _localUser!.copyWith(
      name: name.trim().isEmpty ? 'Designer' : name.trim(),
      color: color ?? _localUser!.color,
      avatarUrl: avatarUrl ?? _localUser!.avatarUrl,
    );
    notifyListeners();
  }

  /// Toggles remote cursor visibility overlay across canvas viewport.
  void setShowRemoteCursors(bool show) {
    if (_showRemoteCursors != show) {
      _showRemoteCursors = show;
      notifyListeners();
    }
  }

  void toggleRemoteCursors() {
    setShowRemoteCursors(!_showRemoteCursors);
  }

  // ===========================================================================
  // Session Lifecycle
  // ===========================================================================

  /// Creates and hosts a brand new real-time design room.
  Future<CollabSession> createRoom(
    String roomName, {
    String? userName,
    Color? color,
  }) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (userName != null && userName.trim().isNotEmpty) {
        setLocalProfile(name: userName.trim(), color: color);
      }

      final hostUser = _localUser!.copyWith(
        isHost: true,
        lastActive: DateTime.now(),
      );
      _localUser = hostUser;

      final session = await _adapter.createRoom(
        roomName: roomName.trim().isEmpty ? 'Forma Studio Session' : roomName.trim(),
        host: hostUser,
      );

      _session = session;
      _subscribeToRoom(session.roomId);
      _isConnecting = false;
      _sessionController.add(_session);
      notifyListeners();

      return session;
    } catch (e) {
      _isConnecting = false;
      _errorMessage = 'Failed to create collaboration room: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Joins an existing active room session by its room code (e.g. 'FORMA-8392').
  Future<CollabSession> joinRoom(
    String roomId,
    String userName, {
    Color? color,
  }) async {
    _isConnecting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanRoomCode = roomId.trim().toUpperCase();
      if (userName.trim().isNotEmpty) {
        setLocalProfile(name: userName.trim(), color: color);
      }

      final joinUser = _localUser!.copyWith(
        isHost: false,
        lastActive: DateTime.now(),
      );
      _localUser = joinUser;

      final session = await _adapter.joinRoom(
        roomId: cleanRoomCode,
        user: joinUser,
      );

      _session = session;
      _subscribeToRoom(cleanRoomCode);
      _isConnecting = false;
      _sessionController.add(_session);
      notifyListeners();

      return session;
    } catch (e) {
      _isConnecting = false;
      _errorMessage = 'Failed to join collaboration room: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Leaves the current room session and resets live streams.
  Future<void> leaveRoom() async {
    if (_session == null || _localUser == null) return;

    final roomId = _session!.roomId;
    final userId = _localUser!.id;

    try {
      await _adapter.leaveRoom(roomId: roomId, userId: userId);
    } catch (e) {
      debugPrint('[CollabService] Disconnect notice error: $e');
    }

    _cursorThrottleTimer?.cancel();
    _collabSub?.cancel();
    _collabSub = null;
    _deltaSub?.cancel();
    _deltaSub = null;

    _session = null;
    _activeCollaborators = [];
    _sessionController.add(null);
    notifyListeners();
  }

  void _subscribeToRoom(String roomId) {
    _collabSub?.cancel();
    _collabSub = _adapter.streamCollaborators(roomId).listen(
      (participants) {
        _activeCollaborators = participants;
        if (_session != null) {
          _session = _session!.copyWith(
            participants: participants,
            lastSyncedAt: DateTime.now(),
          );
        }
        notifyListeners();
      },
      onError: (err) {
        debugPrint('[CollabService] Collaborators stream error: $err');
      },
    );

    _deltaSub?.cancel();
    _deltaSub = _adapter.streamNodeDeltas(roomId).listen(
      (delta) {
        // Discard local echoes
        if (_localUser != null && delta.senderId == _localUser!.id) {
          return;
        }
        _incomingDeltaController.add(delta);
      },
      onError: (err) {
        debugPrint('[CollabService] Node delta stream error: $err');
      },
    );
  }

  // ===========================================================================
  // Real-time Broadcasting (Cursors, Nodes, Selections)
  // ===========================================================================

  /// Broadcasts mouse cursor movements with smooth 33ms (~30fps) throttling.
  void broadcastCursor(Offset position) {
    if (!isConnected || _session == null || _localUser == null) return;

    _pendingCursorPosition = position;
    if (_cursorThrottleTimer?.isActive ?? false) return;

    _cursorThrottleTimer = Timer(const Duration(milliseconds: 32), () {
      if (_pendingCursorPosition != null && isConnected && _session != null) {
        _adapter.broadcastCursor(
          roomId: _session!.roomId,
          userId: _localUser!.id,
          position: _pendingCursorPosition!,
        );
      }
      _cursorThrottleTimer = null;
    });
  }

  /// Broadcasts node mutations (add, update, delete) to all remote designers.
  void broadcastNodeDelta(CollabDelta delta) {
    if (!isConnected || _session == null) return;
    _adapter.broadcastNodeDelta(
      roomId: _session!.roomId,
      delta: delta,
    );
  }

  /// Broadcasts the set of nodes currently selected by the local designer.
  void broadcastSelection(Set<String> selectedIds) {
    if (!isConnected || _session == null || _localUser == null) return;
    _adapter.updateActiveNodes(
      roomId: _session!.roomId,
      userId: _localUser!.id,
      activeNodeIds: selectedIds,
    );

    final delta = CollabDelta.selectionChanged(
      senderId: _localUser!.id,
      senderName: _localUser!.name,
      selectedIds: selectedIds,
    );
    broadcastNodeDelta(delta);
  }

  @override
  void dispose() {
    _cursorThrottleTimer?.cancel();
    _collabSub?.cancel();
    _deltaSub?.cancel();
    _sessionController.close();
    _incomingDeltaController.close();
    _adapter.dispose();
    super.dispose();
  }
}

// =============================================================================
// Riverpod Providers for Forma Studio Dependency Injection
// =============================================================================

/// Global provider for CollabService singleton.
final collabServiceProvider = ChangeNotifierProvider<CollabService>((ref) {
  return CollabService();
});

/// Current active collaborative session (null if disconnected).
final activeCollabSessionProvider = Provider<CollabSession?>((ref) {
  return ref.watch(collabServiceProvider).session;
});

/// List of all active collaborators in the current room.
final activeCollaboratorsProvider = Provider<List<Collaborator>>((ref) {
  return ref.watch(collabServiceProvider).activeCollaborators;
});

/// List of remote collaborators only (excluding self).
final remoteCollaboratorsProvider = Provider<List<Collaborator>>((ref) {
  return ref.watch(collabServiceProvider).remoteCollaborators;
});

/// Whether remote cursor tracking overlays are toggled on.
final showRemoteCursorsProvider = Provider<bool>((ref) {
  return ref.watch(collabServiceProvider).showRemoteCursors;
});

/// Stream provider for incoming real-time canvas deltas from peers.
final collabDeltaStreamProvider = StreamProvider.autoDispose<CollabDelta>((ref) {
  final service = ref.watch(collabServiceProvider);
  return service.incomingDeltaStream;
});
