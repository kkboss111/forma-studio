import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/features/home/screens/home_screen.dart';
import 'package:forma_studio/features/editor/screens/editor_screen.dart';
import 'package:forma_studio/features/settings/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Mobile dark mode toggle works cleanly without overflow on 360px portrait screen',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      // Set mobile phone screen size (360 x 740, 1.0 dpr)
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Start with explicit light mode
      container.read(settingsProvider.notifier).setThemeMode(FormaThemeMode.light);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify zero RenderFlex overflows occurred
      expect(tester.takeException(), isNull);

      // 2. Locate theme toggle button in mobile header
      final themeToggleFinder = find.byTooltip('Switch to Dark Mode');
      expect(themeToggleFinder, findsOneWidget);

      // 3. Tap theme toggle button
      await tester.tap(themeToggleFinder);
      await tester.pumpAndSettle();

      // Verify theme state updated to dark mode
      expect(container.read(settingsProvider).themeMode, FormaThemeMode.dark);
      expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);

      // 4. Tap again to switch back to light mode
      await tester.tap(find.byTooltip('Switch to Light Mode'));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).themeMode, FormaThemeMode.light);
      expect(find.byTooltip('Switch to Dark Mode'), findsOneWidget);

      // 5. Open mobile drawer and verify drawer theme toggle items
      final menuButton = find.byTooltip('Open Navigation Menu');
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer navigation list has the theme toggle item
      final drawerThemeItem = find.text('SWITCH TO DARK MODE');
      expect(drawerThemeItem, findsOneWidget);

      // Tap drawer theme item
      await tester.tap(drawerThemeItem);
      await tester.pumpAndSettle();

      // Verify theme changed to dark via drawer
      expect(container.read(settingsProvider).themeMode, FormaThemeMode.dark);
    },
  );

  testWidgets(
    'Mobile landscape screen (740x360) and EditorScreen top bar toggle theme cleanly',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      tester.view.physicalSize = const Size(740, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider.notifier).setThemeMode(FormaThemeMode.light);

      final project = ProjectModel(
        id: 'proj-mobile-test',
        name: 'Mobile App Wireframe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: const [PageModel(id: 'p1', name: 'Page 1', rootNodeIds: [])],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: EditorScreen(project: project),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);

      // Find theme toggle button in Editor top bar
      final editorThemeToggle = find.byTooltip('Switch to Dark Mode');
      expect(editorThemeToggle, findsOneWidget);

      // Tap theme toggle in editor
      await tester.tap(editorThemeToggle);
      await tester.pumpAndSettle();

      // State is now dark
      expect(container.read(settingsProvider).themeMode, FormaThemeMode.dark);
      expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);

      // Tap again to switch back to light mode
      await tester.tap(find.byTooltip('Switch to Light Mode'));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).themeMode, FormaThemeMode.light);
    },
  );
}
