import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/core/history/command.dart';
import 'package:forma_studio/core/history/history_manager.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';

void main() {
  group('Command History & Undo/Redo Tests', () {
    late ProjectModel project;

    setUp(() {
      project = ProjectModel(
        id: 'proj-test',
        name: 'Test Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: const [PageModel(id: 'page-1', name: 'Page 1', rootNodeIds: [])],
        nodes: const {},
      );
    });

    test('AddNodeCommand executes and safely undoes', () {
      final history = HistoryManager();
      const node = DesignNode(
        id: 'node-rect',
        type: NodeType.rectangle,
        name: 'New Rect',
        x: 10,
        y: 20,
        width: 100,
        height: 50,
      );

      final cmd = AddNodeCommand(pageId: 'page-1', node: node);
      project = history.executeCommand(cmd, project);

      expect(project.nodes.containsKey('node-rect'), isTrue);
      expect(project.pages.first.rootNodeIds.contains('node-rect'), isTrue);
      expect(history.canUndo, isTrue);

      // Undo
      project = history.undo(project);
      expect(project.nodes.containsKey('node-rect'), isFalse);
      expect(project.pages.first.rootNodeIds.contains('node-rect'), isFalse);
      expect(history.canRedo, isTrue);

      // Redo
      project = history.redo(project);
      expect(project.nodes.containsKey('node-rect'), isTrue);
    });

    test('MoveNodesCommand tracks positions and restores on undo', () {
      final history = HistoryManager();
      const node = DesignNode(
        id: 'node-box',
        type: NodeType.rectangle,
        name: 'Box',
        x: 10,
        y: 10,
        width: 100,
        height: 100,
      );

      project = project.copyWith(
        nodes: {'node-box': node},
        pages: [
          const PageModel(
            id: 'page-1',
            name: 'Page 1',
            rootNodeIds: ['node-box'],
          ),
        ],
      );

      final moveCmd = MoveNodesCommand(
        originalPositions: {'node-box': const Offset(10, 10)},
        newPositions: {'node-box': const Offset(60, 80)},
      );

      project = history.executeCommand(moveCmd, project);
      expect(project.nodes['node-box']!.x, equals(60.0));
      expect(project.nodes['node-box']!.y, equals(80.0));

      // Undo
      project = history.undo(project);
      expect(project.nodes['node-box']!.x, equals(10.0));
      expect(project.nodes['node-box']!.y, equals(10.0));
    });
  });
}
