import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/features/settings/screens/settings_screen.dart';
import 'package:forma_studio/features/settings/models/app_settings.dart';
import 'package:forma_studio/features/editor/screens/editor_screen.dart';
import 'package:forma_studio/features/editor/controllers/editor_controller.dart';

void main() {
  group('Settings Mobile & Performance Fixes', () {
    testWidgets('Vertical mobile screen renders Settings forms without text squishing', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(initialTabIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Appearance Tab renders cleanly
      expect(find.text('Theme & Visual Identity'), findsOneWidget);

      final sideTitle = find.text('Sidebar & Tool Dock Position');
      await tester.scrollUntilVisible(sideTitle, 200, scrollable: find.byType(Scrollable).last);
      expect(sideTitle, findsOneWidget);

      final cardSizing = find.text('Recent & Template Card Sizing');
      await tester.scrollUntilVisible(cardSizing, 200, scrollable: find.byType(Scrollable).last);
      expect(cardSizing, findsOneWidget);

      // Verify SegmentedButtons are rendered properly
      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
      expect(find.text('Compact'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Spacious'), findsOneWidget);
    });

    testWidgets('Toggling 120Hz option in Performance tab stays false without auto-reverting', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Initially highRefreshRate is true
      expect(container.read(settingsProvider).highRefreshRate, isTrue);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(initialTabIndex: 2), // Performance Tab
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('High Refresh Rate (120Hz ProMotion)'), findsOneWidget);

      // Tap the switch to toggle it off
      final switchFinder = find.widgetWithText(SwitchListTile, 'High Refresh Rate (120Hz ProMotion)');
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify it turned off and STAYS off
      expect(container.read(settingsProvider).highRefreshRate, isFalse);

      // Pump multiple frames to simulate async delay
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).highRefreshRate, isFalse);
    });
  });

  group('Mobile Text Tool Flow', () {
    testWidgets('Tapping Text button on mobile opens typography sheet and inserts text', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final project = ProjectModel(
        id: 'test-p1',
        name: 'Test Mobile Text Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: const [PageModel(id: 'page-1', name: 'Page 1')],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: EditorScreen(project: project),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the mobile Text button in the bottom dock
      final textBtn = find.byTooltip('Text & Typography');
      expect(textBtn, findsOneWidget);

      await tester.tap(textBtn);
      await tester.pumpAndSettle();

      // Typography sheet should open
      expect(find.text('ADD TYPOGRAPHY & TEXT'), findsOneWidget);
      expect(find.text('Add a Heading'), findsOneWidget);
      expect(find.text('Add a Subheading'), findsOneWidget);
      expect(find.text('Add Body Text'), findsOneWidget);

      // Tap "Add a Heading"
      await tester.tap(find.text('Add a Heading'));
      await tester.pumpAndSettle();

      // Drain the autosave debounce timer
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      // Check that a text node was created in the project!
      final editorState = container.read(editorControllerProvider(project));
      final hasTextNode = editorState.project.nodes.values.any((n) => n.type == NodeType.text);
      expect(hasTextNode, isTrue);
    });
  });
}
