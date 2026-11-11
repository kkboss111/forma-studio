import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/models/node_model.dart';

/// Vibrant Figma-grade color palette curated for high visibility and contrast
/// on both dark voids (Obsidian Dark, Cosmic Glass) and warm paper surfaces (Light Mode).
class CollaboratorColorPalette {
  CollaboratorColorPalette._();

  static const List<Color> vibrantColors = [
    Color(0xFF9333EA), // Royal Figma Purple
    Color(0xFF0284C7), // Electric Ocean Blue
    Color(0xFF059669), // Emerald Mint Green
    Color(0xFFEA580C), // Tangy Sunset Orange
    Color(0xFFE11D48), // Radiant Rose Pink
    Color(0xFFD97706), // Cyber Golden Amber
    Color(0xFF0891B2), // Hyper Cyan
    Color(0xFF4F46E5), // Electric Indigo
    Color(0xFF65A30D), // Vivid Lime
    Color(0xFFDB2777), // Deep Magenta
  ];

  /// Returns a deterministically assigned vibrant color for a given index.
  static Color getColor(int index) {
    return vibrantColors[index.abs() % vibrantColors.length];
  }

  /// Returns a deterministically hashed color for a unique user ID.
  static Color getColorForId(String id) {
    final hash = id.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    return getColor(hash);
  }
}

/// Represents an active peer collaborator in a real-time collaborative design room.
class Collaborator {
  final String id;
  final String name;
  final String? avatarUrl;
  final Color color;
  final Offset? cursorPosition;
  final Set<String> activeNodeIds;
  final DateTime lastActive;
  final bool isHost;
  final String? activeCanvasTabId;
  final String? statusMessage;

  const Collaborator({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.color,
    this.cursorPosition,
    this.activeNodeIds = const {},
    required this.lastActive,
    this.isHost = false,
    this.activeCanvasTabId,
    this.statusMessage,
  });

  /// 1-2 character initials for avatar fallback (e.g. "Sarah Chen" -> "SC").
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Whether collaborator sent a heartbeat/action within the last 45 seconds.
  bool get isRecent {
    final diff = DateTime.now().difference(lastActive);
    return diff.inSeconds < 45;
  }

  Collaborator copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    Color? color,
    Offset? cursorPosition,
    bool clearCursor = false,
    Set<String>? activeNodeIds,
    DateTime? lastActive,
    bool? isHost,
    String? activeCanvasTabId,
    String? statusMessage,
  }) {
    return Collaborator(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      color: color ?? this.color,
      cursorPosition: clearCursor ? null : (cursorPosition ?? this.cursorPosition),
      activeNodeIds: activeNodeIds ?? this.activeNodeIds,
      lastActive: lastActive ?? this.lastActive,
      isHost: isHost ?? this.isHost,
      activeCanvasTabId: activeCanvasTabId ?? this.activeCanvasTabId,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    'color': color.toARGB32(),
    if (cursorPosition != null)
      'cursorPosition': {
        'dx': cursorPosition!.dx,
        'dy': cursorPosition!.dy,
      },
    'activeNodeIds': activeNodeIds.toList(),
    'lastActive': lastActive.toIso8601String(),
    'isHost': isHost,
    if (activeCanvasTabId != null) 'activeCanvasTabId': activeCanvasTabId,
    if (statusMessage != null) 'statusMessage': statusMessage,
  };

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    Offset? cursor;
    if (json['cursorPosition'] != null) {
      final cp = json['cursorPosition'] as Map<String, dynamic>;
      cursor = Offset(
        (cp['dx'] as num).toDouble(),
        (cp['dy'] as num).toDouble(),
      );
    }

    final rawNodeIds = json['activeNodeIds'] as List<dynamic>? ?? [];
    final activeNodeIds = rawNodeIds.map((e) => e.toString()).toSet();

    return Collaborator(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Anonymous Designer',
      avatarUrl: json['avatarUrl'] as String?,
      color: json['color'] != null
          ? Color(json['color'] as int)
          : CollaboratorColorPalette.getColorForId(json['id'] as String),
      cursorPosition: cursor,
      activeNodeIds: activeNodeIds,
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'] as String) ?? DateTime.now()
          : DateTime.now(),
      isHost: json['isHost'] as bool? ?? false,
      activeCanvasTabId: json['activeCanvasTabId'] as String?,
      statusMessage: json['statusMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Collaborator &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          cursorPosition == other.cursorPosition &&
          isHost == other.isHost;

  @override
  int get hashCode => Object.hash(id, name, cursorPosition, isHost);
}

/// Metadata and active state of a shared real-time design room session.
class CollabSession {
  final String roomId;
  final String roomName;
  final String hostId;
  final List<Collaborator> participants;
  final bool isConnected;
  final DateTime? lastSyncedAt;
  final String? currentUserId;
  final Map<String, dynamic> customMetadata;

  const CollabSession({
    required this.roomId,
    required this.roomName,
    required this.hostId,
    this.participants = const [],
    this.isConnected = true,
    this.lastSyncedAt,
    this.currentUserId,
    this.customMetadata = const {},
  });

  /// The local user's collaborator model if present in this session.
  Collaborator? get localUser {
    if (currentUserId == null) return null;
    try {
      return participants.firstWhere((p) => p.id == currentUserId);
    } catch (_) {
      return null;
    }
  }

  /// List of remote peer collaborators (excluding the local user).
  List<Collaborator> get remoteCollaborators {
    if (currentUserId == null) return participants;
    return participants.where((p) => p.id != currentUserId).toList();
  }

  /// Whether current active local user is the room creator / host.
  bool get isHost => currentUserId != null && currentUserId == hostId;

  /// Total count of designers connected in the session.
  int get participantCount => participants.length;

  /// Returns the room host collaborator.
  Collaborator? get host {
    try {
      return participants.firstWhere((p) => p.id == hostId);
    } catch (_) {
      return null;
    }
  }

  CollabSession copyWith({
    String? roomId,
    String? roomName,
    String? hostId,
    List<Collaborator>? participants,
    bool? isConnected,
    DateTime? lastSyncedAt,
    String? currentUserId,
    Map<String, dynamic>? customMetadata,
  }) {
    return CollabSession(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      hostId: hostId ?? this.hostId,
      participants: participants ?? this.participants,
      isConnected: isConnected ?? this.isConnected,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      currentUserId: currentUserId ?? this.currentUserId,
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'roomName': roomName,
    'hostId': hostId,
    'participants': participants.map((p) => p.toJson()).toList(),
    'isConnected': isConnected,
    if (lastSyncedAt != null) 'lastSyncedAt': lastSyncedAt!.toIso8601String(),
    if (currentUserId != null) 'currentUserId': currentUserId,
    'customMetadata': customMetadata,
  };

  factory CollabSession.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'] as List<dynamic>? ?? [];
    final participants = rawParticipants
        .map((p) => Collaborator.fromJson(p as Map<String, dynamic>))
        .toList();

    return CollabSession(
      roomId: json['roomId'] as String? ?? 'FORMA-0000',
      roomName: json['roomName'] as String? ?? 'Untitled Session',
      hostId: json['hostId'] as String? ?? '',
      participants: participants,
      isConnected: json['isConnected'] as bool? ?? true,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      currentUserId: json['currentUserId'] as String?,
      customMetadata: json['customMetadata'] as Map<String, dynamic>? ?? const {},
    );
  }
}

/// Types of atomic deltas transmitted across the real-time engine.
enum CollabDeltaType {
  nodeAdded,
  nodeUpdated,
  nodesDeleted,
  cursorMoved,
  selectionChanged,
  projectSnapshot,
}

/// An atomic operational delta representing real-time changes to the canvas,
/// live cursor streams, or selection updates.
class CollabDelta {
  final String id;
  final String senderId;
  final String senderName;
  final CollabDeltaType type;
  final DateTime timestamp;

  // Single node payloads (additions / edits)
  final DesignNode? node;

  // Multi-node payloads (snapshots / batch operations)
  final List<DesignNode>? nodes;

  // Identification payloads (node deletions)
  final List<String>? nodeIds;

  // Live cursor broadcasting
  final Offset? cursorPosition;

  // Node selection focus
  final Set<String>? selectedNodeIds;

  // Extra generic payload data
  final Map<String, dynamic>? payload;

  const CollabDelta({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.timestamp,
    this.node,
    this.nodes,
    this.nodeIds,
    this.cursorPosition,
    this.selectedNodeIds,
    this.payload,
  });

  /// Factory for high-frequency cursor position broadcasting.
  factory CollabDelta.cursorMoved({
    required String senderId,
    required String senderName,
    required Offset position,
  }) {
    return CollabDelta(
      id: 'cur_${DateTime.now().microsecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      type: CollabDeltaType.cursorMoved,
      timestamp: DateTime.now(),
      cursorPosition: position,
    );
  }

  /// Factory when a designer creates a new node on the canvas.
  factory CollabDelta.nodeAdded({
    required String senderId,
    required String senderName,
    required DesignNode node,
  }) {
    return CollabDelta(
      id: 'add_${node.id}_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      type: CollabDeltaType.nodeAdded,
      timestamp: DateTime.now(),
      node: node,
    );
  }

  /// Factory when a designer modifies an existing node's geometry or paint styles.
  factory CollabDelta.nodeUpdated({
    required String senderId,
    required String senderName,
    required DesignNode node,
  }) {
    return CollabDelta(
      id: 'upd_${node.id}_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      type: CollabDeltaType.nodeUpdated,
      timestamp: DateTime.now(),
      node: node,
    );
  }

  /// Factory when one or more nodes are deleted.
  factory CollabDelta.nodesDeleted({
    required String senderId,
    required String senderName,
    required List<String> nodeIds,
  }) {
    return CollabDelta(
      id: 'del_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      type: CollabDeltaType.nodesDeleted,
      timestamp: DateTime.now(),
      nodeIds: nodeIds,
    );
  }

  /// Factory when a collaborator shifts their active selection bounding box.
  factory CollabDelta.selectionChanged({
    required String senderId,
    required String senderName,
    required Set<String> selectedIds,
  }) {
    return CollabDelta(
      id: 'sel_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      type: CollabDeltaType.selectionChanged,
      timestamp: DateTime.now(),
      selectedNodeIds: selectedIds,
    );
  }

  /// Factory when sending full room state snapshot upon initial handshake.
  factory CollabDelta.projectSnapshot({
    required String senderId,
    required String senderName,
    required List<DesignNode> nodes,
  }) {
    return CollabDelta(
      id: 'snap_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      type: CollabDeltaType.projectSnapshot,
      timestamp: DateTime.now(),
      nodes: nodes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    if (node != null) 'node': node!.toJson(),
    if (nodes != null) 'nodes': nodes!.map((n) => n.toJson()).toList(),
    if (nodeIds != null) 'nodeIds': nodeIds,
    if (cursorPosition != null)
      'cursorPosition': {
        'dx': cursorPosition!.dx,
        'dy': cursorPosition!.dy,
      },
    if (selectedNodeIds != null) 'selectedNodeIds': selectedNodeIds!.toList(),
    if (payload != null) 'payload': payload,
  };

  factory CollabDelta.fromJson(Map<String, dynamic> json) {
    Offset? cursor;
    if (json['cursorPosition'] != null) {
      final cp = json['cursorPosition'] as Map<String, dynamic>;
      cursor = Offset(
        (cp['dx'] as num).toDouble(),
        (cp['dy'] as num).toDouble(),
      );
    }

    final typeName = json['type'] as String? ?? 'nodeUpdated';
    final type = CollabDeltaType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => CollabDeltaType.nodeUpdated,
    );

    DesignNode? singleNode;
    if (json['node'] != null) {
      singleNode = DesignNode.fromJson(json['node'] as Map<String, dynamic>);
    }

    List<DesignNode>? multiNodes;
    if (json['nodes'] != null) {
      multiNodes = (json['nodes'] as List<dynamic>)
          .map((n) => DesignNode.fromJson(n as Map<String, dynamic>))
          .toList();
    }

    List<String>? nodeIds;
    if (json['nodeIds'] != null) {
      nodeIds = (json['nodeIds'] as List<dynamic>).map((e) => e.toString()).toList();
    }

    Set<String>? selectedNodeIds;
    if (json['selectedNodeIds'] != null) {
      selectedNodeIds = (json['selectedNodeIds'] as List<dynamic>).map((e) => e.toString()).toSet();
    }

    return CollabDelta(
      id: json['id'] as String? ?? 'delta_${DateTime.now().microsecondsSinceEpoch}',
      senderId: json['senderId'] as String? ?? 'anonymous',
      senderName: json['senderName'] as String? ?? 'Anonymous',
      type: type,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      node: singleNode,
      nodes: multiNodes,
      nodeIds: nodeIds,
      cursorPosition: cursor,
      selectedNodeIds: selectedNodeIds,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}
