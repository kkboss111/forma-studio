import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/forma_colors.dart';
import '../../features/settings/models/app_settings.dart';

/// Semantic token bundle defining visual attributes for each of Forma's 4 core themes.
class FormaThemeTokens extends ThemeExtension<FormaThemeTokens> {
  final FormaThemeMode mode;
  final bool isDark;
  final bool isGlass;
  final Color scaffoldBg;
  final Color surface;
  final Color wellBg;
  final Color border;
  final Color borderSubtle;
  final Color textMain;
  final Color textMuted;
  final Color accent;
  final double cardBlur;
  final Color specularRim;
  final List<BoxShadow> cardShadow;
  final Color activeGlow;

  const FormaThemeTokens({
    required this.mode,
    required this.isDark,
    required this.isGlass,
    required this.scaffoldBg,
    required this.surface,
    required this.wellBg,
    required this.border,
    required this.borderSubtle,
    required this.textMain,
    required this.textMuted,
    required this.accent,
    required this.cardBlur,
    required this.specularRim,
    required this.cardShadow,
    required this.activeGlow,
  });

  @override
  FormaThemeTokens copyWith({
    FormaThemeMode? mode,
    bool? isDark,
    bool? isGlass,
    Color? scaffoldBg,
    Color? surface,
    Color? wellBg,
    Color? border,
    Color? borderSubtle,
    Color? textMain,
    Color? textMuted,
    Color? accent,
    double? cardBlur,
    Color? specularRim,
    List<BoxShadow>? cardShadow,
    Color? activeGlow,
  }) {
    return FormaThemeTokens(
      mode: mode ?? this.mode,
      isDark: isDark ?? this.isDark,
      isGlass: isGlass ?? this.isGlass,
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      surface: surface ?? this.surface,
      wellBg: wellBg ?? this.wellBg,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textMain: textMain ?? this.textMain,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      cardBlur: cardBlur ?? this.cardBlur,
      specularRim: specularRim ?? this.specularRim,
      cardShadow: cardShadow ?? this.cardShadow,
      activeGlow: activeGlow ?? this.activeGlow,
    );
  }

  @override
  ThemeExtension<FormaThemeTokens> lerp(
    covariant ThemeExtension<FormaThemeTokens>? other,
    double t,
  ) {
    if (other is! FormaThemeTokens) return this;
    return FormaThemeTokens(
      mode: t < 0.5 ? mode : other.mode,
      isDark: t < 0.5 ? isDark : other.isDark,
      isGlass: t < 0.5 ? isGlass : other.isGlass,
      scaffoldBg: Color.lerp(scaffoldBg, other.scaffoldBg, t) ?? scaffoldBg,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      wellBg: Color.lerp(wellBg, other.wellBg, t) ?? wellBg,
      border: Color.lerp(border, other.border, t) ?? border,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      textMain: Color.lerp(textMain, other.textMain, t) ?? textMain,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      cardBlur: ui.lerpDouble(cardBlur, other.cardBlur, t) ?? cardBlur,
      specularRim: Color.lerp(specularRim, other.specularRim, t) ?? specularRim,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      activeGlow: Color.lerp(activeGlow, other.activeGlow, t) ?? activeGlow,
    );
  }
}

class FormaTheme {
  FormaTheme._();

  static const lightTokens = FormaThemeTokens(
    mode: FormaThemeMode.light,
    isDark: false,
    isGlass: false,
    scaffoldBg: FormaColors.lightBg,
    surface: FormaColors.lightSurface,
    wellBg: FormaColors.lightWellBg,
    border: FormaColors.lightBorder,
    borderSubtle: FormaColors.lightBorderSubtle,
    textMain: FormaColors.lightTextMain,
    textMuted: FormaColors.lightTextMuted,
    accent: FormaColors.lightAccent,
    cardBlur: 0.0,
    specularRim: Colors.transparent,
    cardShadow: [
      BoxShadow(color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 3),
      BoxShadow(color: Color(0x080F172A), offset: Offset(0, 6), blurRadius: 16, spreadRadius: -2),
    ],
    activeGlow: Color(0x302563EB),
  );

  static const darkTokens = FormaThemeTokens(
    mode: FormaThemeMode.dark,
    isDark: true,
    isGlass: false,
    scaffoldBg: FormaColors.darkBg,
    surface: FormaColors.darkSurface,
    wellBg: FormaColors.darkWellBg,
    border: FormaColors.darkBorder,
    borderSubtle: FormaColors.darkBorderSubtle,
    textMain: FormaColors.darkTextMain,
    textMuted: FormaColors.darkTextMuted,
    accent: FormaColors.darkAccent,
    cardBlur: 0.0,
    specularRim: Color(0x0FFFFFFF),
    cardShadow: [
      BoxShadow(color: Color(0x0FFFFFFF), offset: Offset(0, 1), blurRadius: 0),
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 8), blurRadius: 24, spreadRadius: -2),
    ],
    activeGlow: Color(0x4038BDF8),
  );

  static const liquidGlassTokens = FormaThemeTokens(
    mode: FormaThemeMode.liquidGlass,
    isDark: false,
    isGlass: true,
    scaffoldBg: Color(0xFFE0F2FE),
    surface: Color(0xD9FFFFFF), // 85% frosted liquid white
    wellBg: Color(0x8AFFFFFF), // 54% frosted well
    border: Color(0xE6FFFFFF), // 90% specular white border
    borderSubtle: Color(0x80FFFFFF),
    textMain: Color(0xFF0F172A),
    textMuted: Color(0xFF475569),
    accent: Color(0xFF0284C7),
    cardBlur: 24.0,
    specularRim: Color(0xFFFFFFFF),
    cardShadow: [
      BoxShadow(color: Color(0x1A0284C7), offset: Offset(0, 8), blurRadius: 32, spreadRadius: -4),
      BoxShadow(color: Color(0x4DFFFFFF), offset: Offset(0, 1), blurRadius: 1),
    ],
    activeGlow: Color(0x500284C7),
  );

  static const glassmorphismTokens = FormaThemeTokens(
    mode: FormaThemeMode.glassmorphism,
    isDark: true,
    isGlass: true,
    scaffoldBg: Color(0xFF080D1A),
    surface: Color(0x1AFFFFFF), // 10% starlight frosted glass
    wellBg: Color(0x1F000000), // 12% deep black space well
    border: Color(0x2EFFFFFF), // 18% starlight edge
    borderSubtle: Color(0x1AFFFFFF),
    textMain: Color(0xFFF8FAFC),
    textMuted: Color(0xB3E2E8F0),
    accent: Color(0xFF818CF8),
    cardBlur: 18.0,
    specularRim: Color(0x40FFFFFF),
    cardShadow: [
      BoxShadow(color: Color(0x66000000), offset: Offset(0, 16), blurRadius: 36),
      BoxShadow(color: Color(0x20FFFFFF), offset: Offset(0, 1), blurRadius: 1),
    ],
    activeGlow: Color(0x55818CF8),
  );

  /// Resolves the exact tokens for a given FormaThemeMode, respecting system brightness.
  static FormaThemeTokens tokensForMode(FormaThemeMode mode, {bool isSystemDark = false}) {
    switch (mode) {
      case FormaThemeMode.light:
        return lightTokens;
      case FormaThemeMode.dark:
        return darkTokens;
      case FormaThemeMode.liquidGlass:
        return liquidGlassTokens;
      case FormaThemeMode.glassmorphism:
        return glassmorphismTokens;
      case FormaThemeMode.system:
        return isSystemDark ? darkTokens : lightTokens;
    }
  }

  /// Safe accessor to retrieve tokens from BuildContext, falling back cleanly.
  static FormaThemeTokens tokensOf(BuildContext context, [FormaThemeMode? explicitMode]) {
    if (explicitMode != null) {
      final isSysDark = Theme.of(context).brightness == Brightness.dark;
      return tokensForMode(explicitMode, isSystemDark: isSysDark);
    }
    final theme = Theme.of(context);
    final ext = theme.extension<FormaThemeTokens>();
    if (ext != null) return ext;
    return theme.brightness == Brightness.dark ? darkTokens : lightTokens;
  }

  /// 1. Modern Studio Light Theme (Pure White on Slate-50)
  static ThemeData light() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: FormaColors.lightBg,
      extensions: const [lightTokens],
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
      ),
    );
  }

  /// 2. Obsidian Studio Dark Theme (Deep Void Black on Slate-900)
  static ThemeData dark() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: FormaColors.darkBg,
      extensions: const [darkTokens],
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: FormaColors.darkBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
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
      ),
    );
  }

  /// 3. Liquid Glass Theme (macOS Sonoma / visionOS Translucency)
  static ThemeData liquidGlass() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      extensions: const [liquidGlassTokens],
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
      extensions: const [glassmorphismTokens],
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

  /// Ambient Cosmic Radial Gradient accurately reproducing the CSS showcase:
  /// radial-gradient(circle at 15% 20%, #431d77 0%, transparent 45%),
  /// radial-gradient(circle at 85% 15%, #b12a6f 0%, transparent 40%),
  /// radial-gradient(circle at 50% 90%, #0c7585 0%, #07192f 55%, #050b14 100%)
  static const BoxDecoration glassmorphismCosmicGradient = BoxDecoration(
    color: Color(0xFF080D1A),
    gradient: RadialGradient(
      center: Alignment(0.0, -0.4),
      radius: 1.4,
      colors: [
        Color(0xFF431D77), // Deep nebula violet
        Color(0xFF1E1035), // Cosmic purple
        Color(0xFF080D1A), // Space void
      ],
      stops: [0.0, 0.45, 1.0],
    ),
  );
}
