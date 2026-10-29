import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forma_colors.dart';

class FormaTheme {
  FormaTheme._();

  static ThemeData light() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: FormaColors.lightBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: FormaColors.lightAccent,
        onPrimary: Colors.white,
        secondary: FormaColors.primaryBlue,
        onSecondary: Colors.white,
        surface: FormaColors.lightSurface,
        onSurface: FormaColors.lightTextMain,
        error: FormaColors.dangerRed,
        onError: Colors.white,
      ),
      dividerColor: FormaColors.lightBorder,
      cardColor: FormaColors.lightSurface,
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: FormaColors.lightTextMuted,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: FormaColors.lightTextMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: FormaColors.lightAccent.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  static ThemeData dark() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FormaColors.darkBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: FormaColors.darkAccent,
        onPrimary: Colors.white,
        secondary: FormaColors.primaryBlue,
        onSecondary: Colors.white,
        surface: FormaColors.darkSurface,
        onSurface: FormaColors.darkTextMain,
        error: FormaColors.dangerRed,
        onError: Colors.white,
      ),
      dividerColor: FormaColors.darkBorder,
      cardColor: FormaColors.darkSurface,
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: FormaColors.darkTextMuted,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: FormaColors.darkTextMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1318),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FormaColors.darkBorder),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Showcase Glassmorphism Theme (Dark Cosmic Glass with Glowing Orbs)
  /// Grounded in modern CSS glassmorphism specification (backdrop-filter: blur, alpha surfaces, luminous orbs)
  static ThemeData glassmorphism() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF080D1A),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF6366F1), // Indigo
        onPrimary: Colors.white,
        secondary: Color(0xFFFACC15), // Gold Accent
        onSecondary: Color(0xFF080D1A),
        tertiary: Color(0xFF0EA5E9), // Cyan
        onTertiary: Colors.white,
        surface: Color(0x1AFFFFFF), // rgba(255, 255, 255, 0.10)
        onSurface: Color(0xFFF8FAFC),
        error: Color(0xFFEF4444),
        onError: Colors.white,
      ),
      dividerColor: const Color(0x29FFFFFF), // rgba(255, 255, 255, 0.16)
      cardColor: const Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: const Color(0xFFFACC15),
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFFE2E8F0),
          fontWeight: FontWeight.w400,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: const Color(0xBFE2E8F0), // rgba(226, 232, 240, 0.75)
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1425),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  /// Ambient Cosmic Radial Gradient from CSS showcase
  static const BoxDecoration glassmorphismCosmicGradient = BoxDecoration(
    color: Color(0xFF080D1A),
    gradient: RadialGradient(
      center: Alignment(0.0, -0.4),
      radius: 1.2,
      colors: [
        Color(0xFF241242), // Deep purple glow
        Color(0xFF140D2B),
        Color(0xFF080D1A), // Midnight navy
      ],
      stops: [0.0, 0.45, 1.0],
    ),
  );
}
