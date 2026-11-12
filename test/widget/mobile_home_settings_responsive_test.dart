import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma_studio/app/theme/forma_theme.dart';
import 'package:forma_studio/features/home/screens/home_screen.dart';
import 'package:forma_studio/features/settings/screens/settings_screen.dart';

void main() {
  group('HomeScreen Mobile & Responsive UX', () {
    testWidgets('Renders cleanly on 375x812 iPhone with 1-column grid and filter pills', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.light(),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);

      // Verify search & action bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byTooltip('New Artboard'), findsWidgets);

      // Verify filter pills
      expect(find.textContaining('All'), findsWidgets);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.textContaining('Starred'), findsWidgets);
    });

    testWidgets('Renders cleanly on 390x844 iPhone 14 without RenderFlex overflows', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.dark(),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Renders 2-column grid on 768x1024 tablet', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.light(),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Updates tab renders v0.4.0 changelog without RenderFlex overflow on 375x812', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterErrorDetails? caught;
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        caught = details;
        oldHandler?.call(details);
      };

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.light(),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify v0.4 badge is present on home
      expect(find.text('v0.4 (Studio Edition)'), findsWidgets);

      // Tap 'Updates' tab in bottom nav
      final updatesTab = find.text('Updates');
      expect(updatesTab, findsOneWidget);
      await tester.tap(updatesTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      if (caught != null) {
        for (final info in caught!.informationCollector?.call() ?? <DiagnosticsNode>[]) {
          debugPrint('COLLECTOR: ${info.name}: ${info.toDescription()}');
        }
      }

      final err = tester.takeException();
      expect(err, isNull);
      expect(find.text('v0.4.0 (Latest Release)'), findsOneWidget);
      expect(find.text('Multiplayer & Icon Studio Edition'), findsOneWidget);
      expect(find.text("What's New & Version Changelog"), findsOneWidget);
      expect(find.text('Open 10-Page Manual'), findsOneWidget);
    });
  });

  group('SettingsScreen Mobile Stacked Cards UX', () {
    testWidgets('Appearance tab renders full-width stacked cards on 375x812', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.dark(),
            home: const SettingsScreen(initialTabIndex: 0),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Theme & Visual Identity'), findsOneWidget);

      final sideTitle = find.text('Sidebar & Tool Dock Position');
      await tester.scrollUntilVisible(sideTitle, 200, scrollable: find.byType(Scrollable).last);
      expect(sideTitle, findsOneWidget);

      final cardSizing = find.text('Recent & Template Card Sizing');
      await tester.scrollUntilVisible(cardSizing, 200, scrollable: find.byType(Scrollable).last);
      expect(cardSizing, findsOneWidget);

      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
      expect(find.text('Compact'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Spacious'), findsOneWidget);
    });

    testWidgets('Shortcuts tab renders clean hotkey cards without squishing', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.light(),
            home: const SettingsScreen(initialTabIndex: 5), // Shortcuts tab
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('Figma-Compatible Hotkeys Reference'), findsOneWidget);
      expect(find.text('Selection & Transformation Tool'), findsOneWidget);
      expect(find.text('V'), findsOneWidget);
    });

    testWidgets('About tab renders roadmap cards cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.light(),
            home: const SettingsScreen(initialTabIndex: 6), // About tab
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('About Forma Studio'), findsOneWidget);
      expect(find.text('FORMA STUDIO'), findsOneWidget);
      expect(find.text('v0.4.0 (Studio Release)'), findsOneWidget);
      expect(find.textContaining('SQLite'), findsNothing);

      final roadmapTitle = find.text('Roadmap & Future Releases (Local First)');
      await tester.scrollUntilVisible(roadmapTitle, 200, scrollable: find.byType(Scrollable).last);
      expect(roadmapTitle, findsOneWidget);

      final booleanSyncTitle = find.text('Non-Destructive Boolean Geometry & Figma Live Sync');
      await tester.scrollUntilVisible(booleanSyncTitle, 200, scrollable: find.byType(Scrollable).last);
      expect(booleanSyncTitle, findsOneWidget);
      expect(find.textContaining('SQLite'), findsNothing);
    });
  });

  group('HomeScreen v0.4.0 Changelog Verification', () {
    testWidgets('Updates tab displays v0.4.0 release notes including multiplayer, HTML importer, and removed items', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.light(),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Navigate to Updates / Changelog tab
      await tester.tap(find.text('WHATS NEW & UPDATES'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('v0.4.0 (Latest Release)'), findsOneWidget);
      expect(find.text('Multiplayer & Icon Studio Edition'), findsOneWidget);
      expect(find.textContaining('Multiplayer Collaboration (Firebase + LAN Mesh)'), findsOneWidget);
      expect(find.textContaining('HTML File Importer'), findsOneWidget);
      expect(find.textContaining('Removed — Liquid Glass & Cosmic Glassmorphism Themes'), findsOneWidget);
      expect(find.textContaining('Removed — Simulated Fake Bot Collaborators'), findsOneWidget);
    });
  });
}
