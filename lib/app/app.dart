import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/forma_theme.dart';
import '../features/home/screens/splash_screen.dart';
import '../features/settings/models/app_settings.dart';

class FormaApp extends ConsumerWidget {
  const FormaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    ThemeMode mode;
    switch (settings.themeMode) {
      case FormaThemeMode.system:
        mode = ThemeMode.system;
        break;
      case FormaThemeMode.light:
        mode = ThemeMode.light;
        break;
      case FormaThemeMode.dark:
        mode = ThemeMode.dark;
        break;
      case FormaThemeMode.liquidGlass:
      case FormaThemeMode.glassmorphism:
        mode = ThemeMode.light;
        break;
      case FormaThemeMode.cyberpunk:
        mode = ThemeMode.dark;
        break;
    }

    final isSystemDark = View.of(context).platformDispatcher.platformBrightness == Brightness.dark;
    final isDark = settings.themeMode == FormaThemeMode.dark ||
        settings.themeMode == FormaThemeMode.cyberpunk ||
        (settings.themeMode == FormaThemeMode.system && isSystemDark);

    return MaterialApp(
      title: 'Forma Studio v0.1 (Beta Testing)',
      debugShowCheckedModeBanner: false,
      theme: FormaTheme.light(),
      darkTheme: FormaTheme.dark(),
      themeMode: mode,
      home: SplashScreen(
        onToggleTheme: () {
          final cur = ref.read(settingsProvider);
          final curSystemDark = View.of(context).platformDispatcher.platformBrightness ==
              Brightness.dark;
          final isCurrentlyDark = cur.themeMode == FormaThemeMode.dark ||
              (cur.themeMode == FormaThemeMode.system && curSystemDark);
          notifier.setThemeMode(
            isCurrentlyDark ? FormaThemeMode.light : FormaThemeMode.dark,
          );
        },
        isDarkMode: isDark,
      ),
    );
  }
}
