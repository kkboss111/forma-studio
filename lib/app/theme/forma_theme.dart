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
}
