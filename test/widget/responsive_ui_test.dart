import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/app/theme/forma_theme.dart';
import 'package:forma_studio/features/home/screens/home_screen.dart';
import 'package:forma_studio/features/editor/screens/editor_screen.dart';
import 'package:forma_studio/features/settings/screens/settings_screen.dart';
import 'package:forma_studio/features/settings/models/app_settings.dart';

ProjectModel _createSampleProject() {
  final now = DateTime.now();
  return ProjectModel(
    id: 'sample-project-id',
    name: 'Forma Responsive Artboard',
    createdAt: now,
    updatedAt: now,
    pages: const [
      PageModel(
        id: 'page-1',
        name: 'Page 1',
        rootNodeIds: ['node-rect-1', 'node-text-1'],
      ),
    ],
    nodes: const {
      'node-rect-1': DesignNode(
        id: 'node-rect-1',
        type: NodeType.roundedRectangle,
        name: 'Card Background',
        x: 40,
        y: 60,
        width: 320,
        height: 180,
      ),
      'node-text-1': DesignNode(
        id: 'node-text-1',
        type: NodeType.rectangle,
        name: 'Header Banner',
        x: 60,
        y: 80,
        width: 220,
        height: 40,
      ),
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Mobile Vertical Phone Layout (375x812)', () {
    testWidgets('HomeScreen renders cleanly without RenderFlex overflow on 375x812', (tester) async {
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

      // 1. Verify 0 RenderFlex or widget overflow errors
      expect(tester.takeException(), isNull);

      // 2. Verify key mobile elements are rendered
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('EditorScreen renders cleanly without RenderFlex overflow on 375x812', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = _createSampleProject();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.dark(),
            home: EditorScreen(project: project),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify 0 overflow errors
      expect(tester.takeException(), isNull);

      // 2. Verify editor UI renders without crashing
      expect(find.byType(EditorScreen), findsOneWidget);
      expect(find.text('Forma Responsive Artboard'), findsWidgets);
    });

    testWidgets('SettingsScreen renders cleanly without RenderFlex overflow on 375x812', (tester) async {
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
            home: const SettingsScreen(initialTabIndex: 0),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final err = tester.takeException();
      if (err != null) {
        if (err is FlutterError) {
          debugPrint('Mobile Editor Diagnostics:\n${err.diagnostics.map((d) => d.toString()).join('\n')}');
        } else {
          debugPrint('Mobile Editor Exception: $err');
        }
      }
      expect(err, isNull);

      // 2. Verify appearance settings elements render
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Theme & Visual Identity'), findsOneWidget);
    });
  });

  group('PC Desktop Layout (1440x900)', () {
    testWidgets('HomeScreen renders cleanly in wide desktop view (1440x900)', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
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

    testWidgets('EditorScreen renders full desktop sidebars on 1440x900', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = _createSampleProject();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: FormaTheme.dark(),
            home: EditorScreen(project: project),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(EditorScreen), findsOneWidget);
      expect(find.text('Forma Responsive Artboard'), findsWidgets);
      // Layers panel is visible on desktop
      expect(find.text('LAYERS'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders multi-column layout on 1440x900', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
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
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Theme & Visual Identity'), findsOneWidget);
    });
  });

  group('Visual Theme Verification (All 4 Core Themes)', () {
    testWidgets('1. Light Theme: Warm paper craft & crisp contrast tokens', (tester) async {
      final tokens = FormaTheme.lightTokens;
      expect(tokens.mode, FormaThemeMode.light);
      expect(tokens.isDark, isFalse);
      expect(tokens.isGlass, isFalse);
      expect(tokens.cardBlur, 0.0);
      expect(tokens.scaffoldBg, isNotNull);
      expect(tokens.surface, isNotNull);
      expect(tokens.textMain, isNotNull);
      expect(tokens.accent, isNotNull);

      // Verify widget rendering with Light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: FormaTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final resolved = FormaTheme.tokensOf(context);
                expect(resolved.isDark, isFalse);
                expect(resolved.mode, FormaThemeMode.light);
                return Container(
                  color: resolved.scaffoldBg,
                  child: Text(
                    'Forma Light Craft',
                    style: TextStyle(color: resolved.textMain),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Forma Light Craft'), findsOneWidget);
    });

    testWidgets('2. Obsidian Dark Theme: True OLED graphite surfaces & electric accents', (tester) async {
      final tokens = FormaTheme.darkTokens;
      expect(tokens.mode, FormaThemeMode.dark);
      expect(tokens.isDark, isTrue);
      expect(tokens.isGlass, isFalse);
      expect(tokens.cardBlur, 0.0);
      expect(tokens.scaffoldBg, isNotNull);
      expect(tokens.surface, isNotNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: FormaTheme.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final resolved = FormaTheme.tokensOf(context);
                expect(resolved.isDark, isTrue);
                expect(resolved.mode, FormaThemeMode.dark);
                return Container(
                  color: resolved.scaffoldBg,
                  child: Text(
                    'Forma Obsidian Dark',
                    style: TextStyle(color: resolved.textMain),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Forma Obsidian Dark'), findsOneWidget);
    });

    testWidgets('3. Liquid Glass Theme: visionOS blur, specular rim & frosted translucency', (tester) async {
      final tokens = FormaTheme.liquidGlassTokens;
      expect(tokens.mode, FormaThemeMode.liquidGlass);
      expect(tokens.isGlass, isTrue);
      expect(tokens.cardBlur, greaterThan(0.0));
      expect(tokens.specularRim, isNotNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: FormaTheme.liquidGlass(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final resolved = FormaTheme.tokensOf(context);
                expect(resolved.isGlass, isTrue);
                expect(resolved.mode, FormaThemeMode.liquidGlass);
                return Container(
                  color: resolved.surface,
                  child: Text(
                    'Forma Liquid Glass',
                    style: TextStyle(color: resolved.textMain),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Forma Liquid Glass'), findsOneWidget);
    });

    testWidgets('4. Cosmic Glassmorphism Theme: Deep nebula space & starlight luminescence', (tester) async {
      final tokens = FormaTheme.glassmorphismTokens;
      expect(tokens.mode, FormaThemeMode.glassmorphism);
      expect(tokens.isDark, isTrue);
      expect(tokens.isGlass, isTrue);
      expect(tokens.cardBlur, greaterThan(0.0));

      await tester.pumpWidget(
        MaterialApp(
          theme: FormaTheme.glassmorphism(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final resolved = FormaTheme.tokensOf(context);
                expect(resolved.isGlass, isTrue);
                expect(resolved.isDark, isTrue);
                expect(resolved.mode, FormaThemeMode.glassmorphism);
                return Container(
                  color: resolved.surface,
                  child: Text(
                    'Forma Cosmic Nebula',
                    style: TextStyle(color: resolved.textMain),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Forma Cosmic Nebula'), findsOneWidget);
    });

    testWidgets('Dynamic theme switching across all 4 modes updates state and UI cleanly', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(settingsProvider);
              final activeTheme = switch (settings.themeMode) {
                FormaThemeMode.light => FormaTheme.light(),
                FormaThemeMode.dark => FormaTheme.dark(),
                FormaThemeMode.liquidGlass => FormaTheme.liquidGlass(),
                FormaThemeMode.glassmorphism => FormaTheme.glassmorphism(),
                FormaThemeMode.system => FormaTheme.light(),
              };

              return MaterialApp(
                theme: activeTheme,
                home: Scaffold(
                  body: Center(
                    child: Text('Current: ${settings.themeMode.name}'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      for (final mode in [
        FormaThemeMode.light,
        FormaThemeMode.dark,
        FormaThemeMode.liquidGlass,
        FormaThemeMode.glassmorphism,
      ]) {
        container.read(settingsProvider.notifier).setThemeMode(mode);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(container.read(settingsProvider).themeMode, mode);
        expect(find.text('Current: ${mode.name}'), findsOneWidget);
      }
    });
  });
}
