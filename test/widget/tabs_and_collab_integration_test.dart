import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/features/editor/screens/editor_screen.dart';
import 'package:forma_studio/features/editor/widgets/tabs/editor_tab_bar.dart';
import 'package:forma_studio/features/editor/widgets/canvas/canvas_viewport.dart';
import 'package:forma_studio/features/editor/widgets/canvas/icon_canvas_viewport.dart';
import 'package:forma_studio/features/editor/widgets/dialogs/collab_dialog.dart';
import 'package:forma_studio/features/editor/widgets/panels/room_operator_menu.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'EditorScreen integrates Collab Share button, EditorTabBar, and IconCanvasViewport switching',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final project = ProjectModel(
        id: 'proj-tab-collab-test',
        name: 'Icon Studio & Collab Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: const [
          PageModel(id: 'page-1', name: 'App Design', rootNodeIds: ['node-rect-1']),
        ],
        nodes: const {
          'node-rect-1': DesignNode(
            id: 'node-rect-1',
            type: NodeType.rectangle,
            name: 'Hero Rect',
            x: 50,
            y: 50,
            width: 200,
            height: 100,
          ),
        },
      );

      tester.view.physicalSize = const Size(1280, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: EditorScreen(project: project)),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Top Bar contains project title and Collab/Share button
      expect(find.text('Icon Studio & Collab Test'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);

      // 2. Tap Share button and verify CollabDialog opens
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(find.byType(CollabDialog), findsOneWidget);
      expect(find.text('Start Live Room Now'), findsOneWidget);
      expect(find.text('Join'), findsOneWidget);

      // Dismiss CollabDialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(CollabDialog), findsNothing);

      // 3. Verify EditorTabBar is rendered with main canvas tab
      expect(find.byType(EditorTabBar), findsOneWidget);
      expect(find.byType(CanvasViewport), findsOneWidget);
      expect(find.byType(IconCanvasViewport), findsNothing);

      // 4. Tap 'New Icon Canvas' button in EditorTabBar
      final newIconTabFinder = find.text('New Icon Canvas');
      expect(newIconTabFinder, findsOneWidget);
      await tester.tap(newIconTabFinder);
      await tester.pumpAndSettle();

      // Tap preset '24 x 24 px' from dropdown menu
      final presetFinder = find.text('24 x 24 px');
      expect(presetFinder, findsOneWidget);
      await tester.tap(presetFinder);
      await tester.pumpAndSettle();

      // 5. Verify IconCanvasViewport is now active and rendered
      expect(find.byType(IconCanvasViewport), findsOneWidget);
      expect(find.byType(CanvasViewport), findsNothing);

      // 6. Verify tab for the new icon canvas is visible and active
      expect(find.text('24px'), findsWidgets);

      // 7. Switch back to the main canvas tab
      final mainTabFinder = find.descendant(
        of: find.byType(EditorTabBar),
        matching: find.text('App Design'),
      );
      expect(mainTabFinder, findsOneWidget);
      await tester.tap(mainTabFinder);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify CanvasViewport is restored
      expect(find.byType(CanvasViewport), findsOneWidget);
      expect(find.byType(IconCanvasViewport), findsNothing);
    },
  );

  testWidgets(
    'RoomOperatorMenu renders modal and handles dismissal cleanly',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showRoomOperatorMenu(context),
                    child: const Text('Open Operator Menu'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open operator menu
      await tester.tap(find.text('Open Operator Menu'));
      await tester.pumpAndSettle();

      // Verify RoomOperatorMenu appears with disconnected/idle state
      expect(find.byType(RoomOperatorMenu), findsOneWidget);
      expect(find.text('No Active Collaborative Room'), findsOneWidget);

      // Dismiss menu via Close button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(RoomOperatorMenu), findsNothing);
    },
  );
}
