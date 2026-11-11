import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/forma_colors.dart';
import '../../features/settings/models/app_settings.dart';

/// Semantic token bundle defining visual attributes for each of Forma's 4 core themes:
/// 1. Light: Editorial craft, warm paper background, rich slate typography, delicate 1px borders, crisp contrasting accent colors.
/// 2. Obsidian Dark: True OLED deep graphite/black background, multi-tiered dark surfaces, luminous electric accents, pristine typography.
/// 3. Liquid Glass: Hyper-realistic Apple iOS 18/visionOS glassmorphism. Multi-layered blur, specular top-edge highlights, frosted semi-transparency with ImageFilter.blur, iridescent subtle border gradients, and high-clarity readability.
/// 4. Cosmic Glassmorphism: Deep space/midnight backdrop with ethereal violet and cyan ambient glow, starlight luminescence, glowing boundary lines, and high-contrast text.
class FormaThemeTokens extends ThemeExtension<FormaThemeTokens> {
  final FormaThemeMode mode;
  final bool isDark;
  final bool isGlass;
  final Color scaffoldBg;
  final Color surface;
  final Color surfaceElevated;
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
    this.surfaceElevated = const Color(0xFFFFFFFF),
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

  // ===========================================================================
  // Semantic Aliases & Ergonomic Getters
  // ===========================================================================
  /// Background color alias (scaffoldBg).
  Color get background => scaffoldBg;

  /// Card surface color alias (surface).
  Color get cardBg => surface;

  /// Active glowing border / boundary aura alias (activeGlow).
  Color get borderGlow => activeGlow;

  /// Primary high-contrast typography alias (textMain).
  Color get textPrimary => textMain;

  /// Secondary muted typography alias (textMuted).
  Color get textSecondary => textMuted;

  /// Whether current theme is light mode.
  bool get isLight => !isDark;

  @override
  FormaThemeTokens copyWith({
    FormaThemeMode? mode,
    bool? isDark,
    bool? isGlass,
    Color? scaffoldBg,
    Color? background,
    Color? surface,
    Color? cardBg,
    Color? surfaceElevated,
    Color? wellBg,
    Color? border,
    Color? borderSubtle,
    Color? textMain,
    Color? textPrimary,
    Color? textMuted,
    Color? textSecondary,
    Color? accent,
    double? cardBlur,
    Color? specularRim,
    List<BoxShadow>? cardShadow,
    Color? activeGlow,
    Color? borderGlow,
  }) {
    return FormaThemeTokens(
      mode: mode ?? this.mode,
      isDark: isDark ?? this.isDark,
      isGlass: isGlass ?? this.isGlass,
      scaffoldBg: background ?? scaffoldBg ?? this.scaffoldBg,
      surface: cardBg ?? surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      wellBg: wellBg ?? this.wellBg,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textMain: textPrimary ?? textMain ?? this.textMain,
      textMuted: textSecondary ?? textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      cardBlur: cardBlur ?? this.cardBlur,
      specularRim: specularRim ?? this.specularRim,
      cardShadow: cardShadow ?? this.cardShadow,
      activeGlow: borderGlow ?? activeGlow ?? this.activeGlow,
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
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t) ?? surfaceElevated,
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

  // ===========================================================================
  // 1. MODERN STUDIO LIGHT TOKENS (Editorial Craft & Warm Paper)
  // ===========================================================================
  static const lightTokens = FormaThemeTokens(
    mode: FormaThemeMode.light,
    isDark: false,
    isGlass: false,
    scaffoldBg: FormaColors.lightBg,
    surface: FormaColors.lightSurface,
    surfaceElevated: FormaColors.lightSurfaceElevated,
    wellBg: FormaColors.lightWellBg,
    border: FormaColors.lightBorder,
    borderSubtle: FormaColors.lightBorderSubtle,
    textMain: FormaColors.lightTextMain,
    textMuted: FormaColors.lightTextMuted,
    accent: FormaColors.lightAccent,
    cardBlur: 0.0,
    specularRim: Colors.transparent,
    cardShadow: [
      BoxShadow(color: Color(0x0A1C1917), offset: Offset(0, 1), blurRadius: 3),
      BoxShadow(color: Color(0x061C1917), offset: Offset(0, 6), blurRadius: 16, spreadRadius: -2),
    ],
    activeGlow: Color(0x252563EB),
  );

  // ===========================================================================
  // 2. OBSIDIAN STUDIO DARK TOKENS (True OLED Pitch Void & Multi-Tiered Surfaces)
  // ===========================================================================
  static const darkTokens = FormaThemeTokens(
    mode: FormaThemeMode.dark,
    isDark: true,
    isGlass: false,
    scaffoldBg: FormaColors.darkBg,
    surface: FormaColors.darkSurface,
    surfaceElevated: FormaColors.darkSurfaceElevated,
    wellBg: FormaColors.darkWellBg,
    border: FormaColors.darkBorder,
    borderSubtle: FormaColors.darkBorderSubtle,
    textMain: FormaColors.darkTextMain,
    textMuted: FormaColors.darkTextMuted,
    accent: FormaColors.darkAccent,
    cardBlur: 0.0,
    specularRim: FormaColors.darkShadowLight,
    cardShadow: [
      BoxShadow(color: Color(0x14FFFFFF), offset: Offset(0, 1), blurRadius: 0),
      BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 28, spreadRadius: -3),
    ],
    activeGlow: Color(0x4038BDF8),
  );

  // ===========================================================================
  // 3. LIQUID GLASS TOKENS (Apple iOS 18 / visionOS Fluid Glassmorphism)
  // ===========================================================================
  static const liquidGlassTokens = FormaThemeTokens(
    mode: FormaThemeMode.light,
    isDark: false,
    isGlass: true,
    scaffoldBg: Color(0xFFE0F2FE),
    surface: FormaColors.liquidGlassCard,
    surfaceElevated: FormaColors.liquidGlassCardElevated,
    wellBg: FormaColors.liquidGlassWell,
    border: FormaColors.liquidGlassBorder,
    borderSubtle: FormaColors.liquidGlassBorderSubtle,
    textMain: FormaColors.liquidGlassTextMain,
    textMuted: FormaColors.liquidGlassTextMuted,
    accent: FormaColors.liquidGlassCyan,
    cardBlur: 28.0,
    specularRim: Color(0xFFFFFFFF),
    cardShadow: [
      BoxShadow(color: Color(0x180284C7), offset: Offset(0, 10), blurRadius: 32, spreadRadius: -4),
      BoxShadow(color: Color(0x60FFFFFF), offset: Offset(0, 1), blurRadius: 0),
    ],
    activeGlow: FormaColors.liquidGlassGlow,
  );

  // ===========================================================================
  // 4. COSMIC GLASSMORPHISM TOKENS (Deep Space Midnight & Starlight Luminescence)
  // ===========================================================================
  static const glassmorphismTokens = FormaThemeTokens(
    mode: FormaThemeMode.dark,
    isDark: true,
    isGlass: true,
    scaffoldBg: FormaColors.cosmicBg,
    surface: FormaColors.cosmicCard,
    surfaceElevated: FormaColors.cosmicCardElevated,
    wellBg: FormaColors.cosmicWell,
    border: FormaColors.cosmicBorder,
    borderSubtle: FormaColors.cosmicBorderSubtle,
    textMain: FormaColors.cosmicTextMain,
    textMuted: FormaColors.cosmicTextMuted,
    accent: FormaColors.cosmicIndigo,
    cardBlur: 20.0,
    specularRim: Color(0x40FFFFFF),
    cardShadow: [
      BoxShadow(color: Color(0x80000000), offset: Offset(0, 16), blurRadius: 40, spreadRadius: -2),
      BoxShadow(color: Color(0x25818CF8), offset: Offset(0, 2), blurRadius: 16),
      BoxShadow(color: Color(0x35FFFFFF), offset: Offset(0, 1), blurRadius: 0),
    ],
    activeGlow: FormaColors.cosmicBorderGlow,
  );

  /// Resolves the exact tokens for a given FormaThemeMode, respecting system brightness.
  static FormaThemeTokens tokensForMode(FormaThemeMode mode, {bool isSystemDark = false}) {
    switch (mode) {
      case FormaThemeMode.light:
        return lightTokens;
      case FormaThemeMode.dark:
        return darkTokens;
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

  // ===========================================================================
  // 1. MODERN STUDIO LIGHT THEME BUILDER (Editorial Warm Paper & Slate)
  // ===========================================================================
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
      dividerTheme: const DividerThemeData(
        color: FormaColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      cardColor: FormaColors.lightSurface,
      cardTheme: CardThemeData(
        color: FormaColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FormaColors.lightBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FormaColors.lightSurface,
        elevation: 12,
        shadowColor: const Color(0x181C1917),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FormaColors.lightTextMain,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FormaColors.lightWellBg,
        hoverColor: FormaColors.lightWellBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FormaColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FormaColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FormaColors.lightAccent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: FormaColors.lightAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: FormaColors.lightTextMain,
          side: const BorderSide(color: FormaColors.lightBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
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

  // ===========================================================================
  // 2. OBSIDIAN STUDIO DARK THEME BUILDER (True OLED Pitch & Multi-Tiered Surfaces)
  // ===========================================================================
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
      dividerTheme: const DividerThemeData(
        color: FormaColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      cardColor: FormaColors.darkSurface,
      cardTheme: CardThemeData(
        color: FormaColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: FormaColors.darkBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FormaColors.darkSurfaceElevated,
        elevation: 16,
        shadowColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FormaColors.darkTextMain,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FormaColors.darkWellBg,
        hoverColor: FormaColors.darkWellBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FormaColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FormaColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FormaColors.darkAccent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: FormaColors.darkAccent,
          foregroundColor: FormaColors.darkBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: FormaColors.darkTextMain,
          side: const BorderSide(color: FormaColors.darkBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
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
              color: Colors.black.withValues(alpha: 0.45),
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
      ),
    );
  }

  // ===========================================================================
  // 3. LIQUID GLASS THEME BUILDER (Apple iOS 18 / visionOS Translucency)
  // ===========================================================================
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
        onSurface: FormaColors.liquidGlassTextMain,
        surfaceContainerHighest: FormaColors.liquidGlassWell,
        error: FormaColors.dangerRed,
        onError: Colors.white,
      ),
      dividerColor: const Color(0x350284C7),
      dividerTheme: const DividerThemeData(
        color: Color(0x350284C7),
        thickness: 1,
        space: 1,
      ),
      cardColor: FormaColors.liquidGlassCard,
      cardTheme: CardThemeData(
        color: FormaColors.liquidGlassCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: FormaColors.liquidGlassBorder, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: FormaColors.liquidGlassCardElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: FormaColors.liquidGlassBorder, width: 1.5),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: FormaColors.liquidGlassTextMain,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: FormaColors.liquidGlassTextMain,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: FormaColors.liquidGlassTextMain,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: const Color(0xFF0369A1),
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: FormaColors.liquidGlassTextMain,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFF1E293B),
          fontWeight: FontWeight.w400,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: FormaColors.liquidGlassTextMuted,
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

  // ===========================================================================
  // 4. COSMIC GLASSMORPHISM THEME BUILDER (Midnight Nebula & Starlight Luminescence)
  // ===========================================================================
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
        onSurface: FormaColors.cosmicTextMain,
        surfaceContainerHighest: FormaColors.cosmicWell,
        error: FormaColors.dangerRed,
        onError: Colors.white,
      ),
      dividerColor: const Color(0x30FFFFFF),
      dividerTheme: const DividerThemeData(
        color: Color(0x30FFFFFF),
        thickness: 1,
        space: 1,
      ),
      cardColor: FormaColors.cosmicCard,
      cardTheme: CardThemeData(
        color: FormaColors.cosmicCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: FormaColors.cosmicBorder, width: 1.2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xE60D1224),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: FormaColors.cosmicBorder, width: 1.5),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          color: FormaColors.cosmicTextMain,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: FormaColors.cosmicTextMain,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: FormaColors.cosmicTextMain,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: FormaColors.cosmicGold,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: FormaColors.cosmicTextMain,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: const Color(0xFFE2E8F0),
          fontWeight: FontWeight.w400,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: FormaColors.cosmicTextMuted,
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

  /// Ambient Cosmic Radial Gradient accurately reproducing the deep space nebula showcase:
  /// radial-gradient with deep nebula violet, interstellar purple, and cyan abyss void.
  static const BoxDecoration glassmorphismCosmicGradient = BoxDecoration(
    color: Color(0xFF060913),
    gradient: RadialGradient(
      center: Alignment(-0.3, -0.4),
      radius: 1.5,
      colors: [
        Color(0xFF431D77), // Deep nebula violet
        Color(0xFF1F103A), // Interstellar purple
        Color(0xFF0A0F22), // Deep starlight navy
        Color(0xFF060913), // Space void midnight
      ],
      stops: [0.0, 0.35, 0.70, 1.0],
    ),
  );
}
