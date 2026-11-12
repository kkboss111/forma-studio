import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/core/collab/collab_models.dart';
import 'package:forma_studio/core/collab/collab_service.dart';
import 'package:forma_studio/core/collab/firebase_collab_adapter.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';

void main() {
  group('End-to-End Real-Time Multi-User Collaboration Tests', () {
    test('Hosting a room contains ONLY the real host with zero fake bots', () async {
      final hostService = CollabService(adapter: MockLanCollabAdapter());
      final session = await hostService.quickHostRoom(
        roomName: 'Design Review',
        userName: 'Alice',
      );

      expect(session.isConnected, isTrue);
      expect(session.participants.length, 1);
      expect(session.participants.first.name, 'Alice');
      expect(session.participants.first.isHost, isTrue);
      expect(session.participants.first.role, CollaboratorRole.host);

      // Verify NO fake bots exist (Alex Rivera, Sarah Chen, Jordan)
      final names = session.participants.map((p) => p.name).toList();
      final ids = session.participants.map((p) => p.id).toList();
      expect(names, isNot(contains('Alex Rivera')));
      expect(names, isNot(contains('Sarah Chen')));
      expect(names.any((n) => n.contains('Jordan')), isFalse);
      expect(ids, isNot(contains('peer_alex_99')));
      expect(ids, isNot(contains('peer_sarah_88')));

      // Wait to confirm no simulated peer timers inject bots or cursor drift
      await Future.delayed(const Duration(milliseconds: 150));
      expect(hostService.activeCollaborators.length, 1);
      expect(hostService.remoteCollaborators, isEmpty);

      await hostService.leaveRoom();
      hostService.dispose();
    });

    test('Joining a room adds ONLY real peers and syncs cursors without wandering timers', () async {
      final hostService = CollabService(adapter: MockLanCollabAdapter());
      final guestService = CollabService(adapter: MockLanCollabAdapter());

      final hostSession = await hostService.quickHostRoom(
        roomName: 'Pair Sprint',
        userName: 'Alice',
      );
      final roomCode = hostSession.roomId;

      final guestSession = await guestService.joinRoom(roomCode, 'Bob');
      expect(guestSession.roomId, roomCode);
      expect(guestSession.participants.length, 2);

      await Future.delayed(const Duration(milliseconds: 50));

      // Verify both participants see strictly each other
      expect(hostService.activeCollaborators.length, 2);
      expect(hostService.remoteCollaborators.length, 1);
      expect(hostService.remoteCollaborators.first.name, 'Bob');

      expect(guestService.activeCollaborators.length, 2);
      expect(guestService.remoteCollaborators.length, 1);
      expect(guestService.remoteCollaborators.first.name, 'Alice');

      // Broadcast cursor from Bob
      const targetPos = Offset(412.0, 288.5);
      guestService.broadcastCursor(targetPos);

      // Wait for 32ms throttle + delivery
      await Future.delayed(const Duration(milliseconds: 80));

      expect(hostService.remoteCollaborators.first.cursorPosition, targetPos);

      // Wait 200ms and confirm Bob's cursor stays stationary (no simulated wandering)
      await Future.delayed(const Duration(milliseconds: 200));
      expect(hostService.remoteCollaborators.first.cursorPosition, targetPos);

      await guestService.leaveRoom();
      await hostService.leaveRoom();
      hostService.dispose();
      guestService.dispose();
    });

    test('Multi-user node delta sync broadcasts nodeAdded, nodeUpdated, and nodesDeleted', () async {
      final hostService = CollabService(adapter: MockLanCollabAdapter());
      final guestService = CollabService(adapter: MockLanCollabAdapter());

      final hostSession = await hostService.quickHostRoom(userName: 'Alice');
      await guestService.joinRoom(hostSession.roomId, 'Bob');

      final guestDeltas = <CollabDelta>[];
      final sub = guestService.incomingDeltaStream.listen(guestDeltas.add);

      const node = DesignNode(
        id: 'node-collab-1',
        type: NodeType.rectangle,
        name: 'Shared Button',
        x: 50,
        y: 60,
        width: 140,
        height: 48,
      );

      // 1. Add
      hostService.broadcastNodeDelta(
        CollabDelta.nodeAdded(
          senderId: hostService.localUser!.id,
          senderName: hostService.localUser!.name,
          node: node,
        ),
      );

      // 2. Update
      hostService.broadcastNodeDelta(
        CollabDelta.nodeUpdated(
          senderId: hostService.localUser!.id,
          senderName: hostService.localUser!.name,
          node: node.copyWith(x: 180, y: 220),
        ),
      );

      // 3. Delete
      hostService.broadcastNodeDelta(
        CollabDelta.nodesDeleted(
          senderId: hostService.localUser!.id,
          senderName: hostService.localUser!.name,
          nodeIds: const ['node-collab-1'],
        ),
      );

      await Future.delayed(const Duration(milliseconds: 60));

      expect(guestDeltas.length, 3);
      expect(guestDeltas[0].type, CollabDeltaType.nodeAdded);
      expect(guestDeltas[0].node?.id, 'node-collab-1');
      expect(guestDeltas[1].type, CollabDeltaType.nodeUpdated);
      expect(guestDeltas[1].node?.x, 180);
      expect(guestDeltas[2].type, CollabDeltaType.nodesDeleted);
      expect(guestDeltas[2].nodeIds, ['node-collab-1']);

      await sub.cancel();
      await guestService.leaveRoom();
      await hostService.leaveRoom();
      hostService.dispose();
      guestService.dispose();
    });

    test('Room Operator controls: setRoomLocked, updateCollaboratorRole, forceSyncCanvas, kickCollaborator, endSessionForAll', () async {
      final hostService = CollabService(adapter: MockLanCollabAdapter());
      final guestService = CollabService(adapter: MockLanCollabAdapter());
      final guest2Service = CollabService(adapter: MockLanCollabAdapter());

      final hostSession = await hostService.quickHostRoom(userName: 'Host');
      await guestService.joinRoom(hostSession.roomId, 'GuestOne');
      await guest2Service.joinRoom(hostSession.roomId, 'GuestTwo');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(hostService.activeCollaborators.length, 3);

      // 1. setRoomLocked
      hostService.setRoomLocked(true);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(hostService.isRoomLocked, isTrue);
      expect(guestService.isRoomLocked, isTrue);

      // 2. updateCollaboratorRole (demote GuestOne to viewer)
      final guestOneId = guestService.localUser!.id;
      hostService.updateCollaboratorRole(guestOneId, CollaboratorRole.viewer);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(guestService.localUser!.role, CollaboratorRole.viewer);
      expect(guestService.canEdit, isFalse);

      // 3. forceSyncCanvas
      final guestDeltas = <CollabDelta>[];
      final sub = guestService.incomingDeltaStream.listen(guestDeltas.add);
      const syncNode = DesignNode(
        id: 'sync-node-99',
        type: NodeType.ellipse,
        name: 'Force Synced Circle',
        x: 10,
        y: 20,
        width: 80,
        height: 80,
      );
      hostService.forceSyncCanvas([syncNode]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(guestDeltas.any((d) => d.type == CollabDeltaType.forceSync && d.nodes?.first.id == 'sync-node-99'), isTrue);
      await sub.cancel();

      // 4. kickCollaborator (kick GuestOne)
      hostService.kickCollaborator(guestOneId);
      await Future.delayed(const Duration(milliseconds: 80));
      expect(guestService.isConnected, isFalse);
      expect(hostService.activeCollaborators.any((c) => c.id == guestOneId), isFalse);

      // 5. endSessionForAll (disconnects GuestTwo and Host)
      await hostService.endSessionForAll();
      await Future.delayed(const Duration(milliseconds: 80));
      expect(hostService.isConnected, isFalse);
      expect(guest2Service.isConnected, isFalse);

      hostService.dispose();
      guestService.dispose();
      guest2Service.dispose();
    });
  });
}
