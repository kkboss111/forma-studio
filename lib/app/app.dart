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
    ThemeData activeLightTheme = FormaTheme.light();
    ThemeData activeDarkTheme = FormaTheme.dark();

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
    }

    final isSystemDark = View.of(context).platformDispatcher.platformBrightness == Brightness.dark;
    final isDark = settings.themeMode == FormaThemeMode.dark ||
        (settings.themeMode == FormaThemeMode.system && isSystemDark);

    return MaterialApp(
      title: 'Forma Studio',
      debugShowCheckedModeBanner: false,
      theme: activeLightTheme,
      darkTheme: activeDarkTheme,
      themeMode: mode,
      home: SplashScreen(
        onToggleTheme: () {
          final cur = ref.read(settingsProvider);
          final nextMode = switch (cur.themeMode) {
            FormaThemeMode.light => FormaThemeMode.dark,
            FormaThemeMode.dark => FormaThemeMode.light,
            FormaThemeMode.system => isSystemDark ? FormaThemeMode.light : FormaThemeMode.dark,
          };
          notifier.setThemeMode(nextMode);
        },
        isDarkMode: isDark,
      ),
    );
  }
}
