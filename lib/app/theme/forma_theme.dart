import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forma_colors.dart';

class FormaTheme {
  FormaTheme._();

  /// 1. Modern Studio Light Theme (Pure White on Slate-50)
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
        surfaceContainerHighest: FormaColors.lightWellBg,
        error: FormaColors.dangerRed,
        onError: Colors.white,
      ),
      dividerColor: FormaColors.lightBorder,
      cardColor: FormaColors.lightSurface,
      cardTheme: CardThemeData(
        color: FormaColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FormaColors.lightBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: FormaColors.lightTextMain),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FormaColors.lightWellBg,
        side: const BorderSide(color: FormaColors.lightBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FormaColors.lightTextMain),
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: FormaColors.lightTextMain,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: FormaColors.lightTextMuted,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: FormaColors.lightTextMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: FormaColors.lightTextMain.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        waitDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  /// 2. Deep Obsidian Studio Dark Theme (High Contrast Void on Slate-900)
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
        onPrimary: FormaColors.darkBg,
        secondary: FormaColors.primaryBlue,
        onSecondary: Colors.white,
        surface: FormaColors.darkSurface,
        onSurface: FormaColors.darkTextMain,
        surfaceContainerHighest: FormaColors.darkWellBg,
        error: FormaColors.dangerRed,
        onError: Colors.white,
      ),
      dividerColor: FormaColors.darkBorder,
      cardColor: FormaColors.darkSurface,
      cardTheme: CardThemeData(
        color: FormaColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FormaColors.darkBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: FormaColors.darkTextMain),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FormaColors.darkWellBg,
        side: const BorderSide(color: FormaColors.darkBorder, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: FormaColors.darkTextMain),
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: FormaColors.darkTextMain,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: FormaColors.darkTextMuted,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: FormaColors.darkTextMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FormaColors.darkBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        waitDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  /// 3. Liquid Glass Theme (macOS / visionOS Fluid Aquatic Translucency)
  static ThemeData liquidGlass() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE0F2FE),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: FormaColors.liquidGlassCyan,
        onPrimary: Colors.white,
        secondary: FormaColors.liquidGlassSky,
        onSecondary: Colors.white,
        surface: FormaColors.liquidGlassCard,
        onSurface: Color(0xFF0F172A),
        surfaceContainerHighest: Color(0x60FFFFFF),
        error: FormaColors.dangerRed,
        onError: Colors.white,
      ),
      dividerColor: const Color(0x350284C7),
      cardColor: FormaColors.liquidGlassCard,
      cardTheme: CardThemeData(
        color: FormaColors.liquidGlassCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: FormaColors.liquidGlassBorder, width: 1.2),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: const Color(0xFF0369A1),
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFF0F172A),
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF1E293B),
          fontWeight: FontWeight.w400,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: const Color(0xFF475569),
          fontWeight: FontWeight.w600,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xD90C4A6E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 4. Cosmic Glassmorphism Theme (Dark Nebula Violet & Starlight Gold)
  static ThemeData glassmorphism() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FormaColors.cosmicBg,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: FormaColors.cosmicIndigo,
        onPrimary: Colors.white,
        secondary: FormaColors.cosmicGold,
        onSecondary: FormaColors.cosmicBg,
        tertiary: FormaColors.cosmicCyan,
        onTertiary: Colors.white,
        surface: FormaColors.cosmicCard,
        onSurface: Color(0xFFF8FAFC),
        surfaceContainerHighest: Color(0x20FFFFFF),
        error: FormaColors.dangerRed,
        onError: Colors.white,
      ),
      dividerColor: const Color(0x30FFFFFF),
      cardColor: FormaColors.cosmicCard,
      cardTheme: CardThemeData(
        color: FormaColors.cosmicCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: FormaColors.cosmicBorder, width: 1.2),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w800,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: const Color(0xFFF8FAFC),
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: FormaColors.cosmicGold,
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
          color: const Color(0xCCCBD5E1),
          fontWeight: FontWeight.w500,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xF00A0D1B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x40818CF8)),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Ambient Cosmic Radial Gradient from CSS showcase
  static const BoxDecoration glassmorphismCosmicGradient = BoxDecoration(
    color: Color(0xFF060913),
    gradient: RadialGradient(
      center: Alignment(0.0, -0.35),
      radius: 1.35,
      colors: [
        Color(0xFF2E1065), // Deep cosmic purple
        Color(0xFF170C36), // Deep violet
        Color(0xFF060913), // Midnight space void
      ],
      stops: [0.0, 0.45, 1.0],
    ),
  );
}
