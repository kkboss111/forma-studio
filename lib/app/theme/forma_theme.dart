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

  static ThemeData glassmorphism() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE2EAF8),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF0284C7),
        onPrimary: Colors.white,
        secondary: Color(0xFF38BDF8),
        onSecondary: Colors.white,
        surface: Color(0xEEFFFFFF),
        onSurface: Color(0xFF0F172A),
        error: FormaColors.dangerRed,
        onError: Colors.white,
      ),
      dividerColor: const Color(0x4094A3B8),
      cardColor: const Color(0xCCFFFFFF),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: const Color(0xFF0284C7),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF334155),
          fontWeight: FontWeight.w400,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xEE0284C7),
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

  static ThemeData cyberpunk() {
    final baseTextTheme = GoogleFonts.orbitronTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0014),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF00FFF0),
        onPrimary: Colors.black,
        secondary: Color(0xFFFF007F),
        onSecondary: Colors.white,
        surface: Color(0xFF15042A),
        onSurface: Color(0xFF00FFF0),
        error: Color(0xFFFF0055),
        onError: Colors.black,
      ),
      dividerColor: const Color(0xFF3B0764),
      cardColor: const Color(0xFF190733),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: const Color(0xFF00FFF0),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: const Color(0xFFFF007F),
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: const Color(0xFF00FFF0),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFFF1F5F9),
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFFE2E8F0),
          fontWeight: FontWeight.w400,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: const Color(0xFFA855F7),
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF15042A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00FFF0), width: 1.5),
        ),
        textStyle: const TextStyle(
          color: Color(0xFF00FFF0),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        waitDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
