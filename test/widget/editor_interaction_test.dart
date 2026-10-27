import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/features/editor/screens/editor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'EditorScreen loads project, displays canvas, layers, and properties',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final project = ProjectModel(
        id: 'proj-widget-test',
        name: 'Fan Dashboard Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: const [
          PageModel(id: 'page-1', name: 'Page 1', rootNodeIds: ['node-card-1']),
        ],
        nodes: const {
          'node-card-1': DesignNode(
            id: 'node-card-1',
            type: NodeType.roundedRectangle,
            name: 'Hero Stat Card',
            x: 100,
            y: 100,
            width: 280,
            height: 140,
          ),
        },
      );

      // Set screen size to tablet/desktop
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: EditorScreen(project: project)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify top bar elements
      expect(find.text('Fan Dashboard Test'), findsOneWidget);
      expect(find.text('LAYERS'), findsOneWidget);
      expect(find.text('Hero Stat Card'), findsOneWidget);
      expect(find.text('CANVAS SETTINGS'), findsOneWidget);

      // Tap on the layer item to select it
      await tester.tap(find.text('Hero Stat Card'));
      await tester.pump();

      // Now properties panel should show geometry controls for Hero Stat Card
      expect(find.text('GEOMETRY'), findsOneWidget);
      expect(find.text('CONSTRAINTS'), findsOneWidget);
      expect(find.text('FILLS'), findsOneWidget);
      expect(find.text('STROKES'), findsOneWidget);
    },
  );
}
