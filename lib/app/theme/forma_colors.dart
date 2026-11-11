import 'package:flutter/material.dart';

/// Design tokens and semantic color constants for Forma Studio.
/// Adheres to modern craft principles (/impeccable & /design-taste-frontend):
/// - High contrast typography (WCAG AAA >= 7:1)
/// - Crisp hairline borders (1px Slate 200/800 & warm stone)
/// - Subtle multi-layer ambient elevation (zero muddy halos)
/// - Unified 4-theme system:
///   1. Light: Editorial craft, warm paper background, rich slate typography, delicate 1px borders, crisp contrasting accent colors.
///   2. Obsidian Dark: True OLED deep graphite/black background, multi-tiered dark surfaces, luminous electric accents, pristine typography.
///   3. Liquid Glass: Hyper-realistic Apple iOS 18/visionOS glassmorphism. Multi-layered blur, specular top-edge highlights, frosted semi-transparency with ImageFilter.blur, iridescent subtle border gradients, and high-clarity readability.
///   4. Cosmic Glassmorphism: Deep space/midnight backdrop with ethereal violet and cyan ambient glow, starlight luminescence, glowing boundary lines, and high-contrast text.
class FormaColors {
  FormaColors._();

  // ===========================================================================
  // 1. MODERN STUDIO LIGHT PALETTE (Editorial Craft & Warm Paper)
  // ===========================================================================
  /// Warm alabaster/paper canvas backdrop with editorial warmth.
  static const Color lightBg = Color(0xFFFAF9F6);

  /// Crisp pure white surface layered over warm paper.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Multi-tiered elevated surface for popovers, dropdowns, and active cards.
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  /// Warm sunken tactile well for input fields, chips, and nested containers.
  static const Color lightWellBg = Color(0xFFF2EFE9);

  /// Crisp specular bounce for elevation highlights.
  static const Color lightShadowLight = Color(0xFFFFFFFF);

  /// Delicate diffuse ambient shadow (zero muddy halo).
  static const Color lightShadowDark = Color(0x0C1C1917);

  /// Rich Slate 900 ink typography (17.5:1 contrast against lightBg - WCAG AAA).
  static const Color lightTextMain = Color(0xFF0F172A);

  /// Slate 600 secondary typography (7.3:1 contrast against lightBg - WCAG AAA).
  static const Color lightTextMuted = Color(0xFF475569);

  /// Crisp Royal Editorial Blue accent color.
  static const Color lightAccent = Color(0xFF2563EB);

  /// Delicate 1px warm hairline border.
  static const Color lightBorder = Color(0xFFE4E2DC);

  /// Subtle hairline divider for internal sections.
  static const Color lightBorderSubtle = Color(0xFFECEAE4);

  /// Dashed guideline and placeholder wireframes.
  static const Color lightDashed = Color(0xFFCBD5E1);

  // ===========================================================================
  // 2. OBSIDIAN STUDIO DARK PALETTE (True OLED Pitch Void & Multi-Tiered Surfaces)
  // ===========================================================================
  /// True OLED pitch graphite/black background.
  static const Color darkBg = Color(0xFF05070B);

  /// Tier 1 deep obsidian dark surface for panels, toolbars, and cards.
  static const Color darkSurface = Color(0xFF0F1420);

  /// Tier 2 elevated surface for dialogs, flyouts, and active modals.
  static const Color darkSurfaceElevated = Color(0xFF171E2E);

  /// Sunken well for inputs and nested trays (darker than tier 1 surface).
  static const Color darkWellBg = Color(0xFF090D15);

  /// Specular rim highlight on top edges (8% white rim).
  static const Color darkShadowLight = Color(0x14FFFFFF);

  /// Deep true pitch ambient drop shadow.
  static const Color darkShadowDark = Color(0x80000000);

  /// Pristine Slate 50 typography (18.2:1 contrast against darkBg - WCAG AAA).
  static const Color darkTextMain = Color(0xFFF8FAFC);

  /// Slate 400 secondary typography (7.3:1 contrast against darkSurface - WCAG AAA).
  static const Color darkTextMuted = Color(0xFF94A3B8);

  /// Luminous electric sky accent.
  static const Color darkAccent = Color(0xFF38BDF8);

  /// Crisp 1px Slate 800 hairline border.
  static const Color darkBorder = Color(0xFF1E283A);

  /// Subtle hairline divider for internal dark sections.
  static const Color darkBorderSubtle = Color(0xFF131926);

  /// Dashed dark guideline and placeholder wireframes.
  static const Color darkDashed = Color(0xFF2D3B4F);

  // ===========================================================================
  // 3. LIQUID GLASS PALETTE (Apple iOS 18 / visionOS Fluid Glassmorphism)
  // ===========================================================================
  /// Luminous Apple Ocean Blue.
  static const Color liquidGlassCyan = Color(0xFF0284C7);

  /// Electric Sky Blue for secondary highlights.
  static const Color liquidGlassSky = Color(0xFF38BDF8);

  /// Fluid Teal accent.
  static const Color liquidGlassTeal = Color(0xFF0D9488);

  /// Frosted liquid glass card body (84% frosted white for pristine legibility).
  static const Color liquidGlassCard = Color(0xD6FFFFFF);

  /// Multi-tier elevated frosted glass card (91% frosted white).
  static const Color liquidGlassCardElevated = Color(0xE8FFFFFF);

  /// Frosted sunken well (46% semi-translucent white).
  static const Color liquidGlassWell = Color(0x75FFFFFF);

  /// Specular top edge highlight border (91% luminous white).
  static const Color liquidGlassBorder = Color(0xE8FFFFFF);

  /// Diffuse subtle border edge (38% frosted white).
  static const Color liquidGlassBorderSubtle = Color(0x60FFFFFF);

  /// Luminous cyan fluid refraction glow.
  static const Color liquidGlassGlow = Color(0x400284C7);

  /// High-clarity ink text on liquid glass (WCAG AAA >= 7:1).
  static const Color liquidGlassTextMain = Color(0xFF0F172A);

  /// High-clarity muted text on liquid glass (Slate 700, WCAG AAA).
  static const Color liquidGlassTextMuted = Color(0xFF334155);

  // ===========================================================================
  // 4. COSMIC GLASSMORPHISM PALETTE (Deep Space Midnight, Radial Nebula & Starlight)
  // ===========================================================================
  /// Deep space midnight backdrop.
  static const Color cosmicBg = Color(0xFF060913);

  /// Frosted dark starlight glass (12% frosted starlight white).
  static const Color cosmicCard = Color(0x1EFFFFFF);

  /// Multi-tier elevated frosted cosmic card (16.5% frosted glass).
  static const Color cosmicCardElevated = Color(0x2AFFFFFF);

  /// Sunken deep space well (16% black cosmic void).
  static const Color cosmicWell = Color(0x28000000);

  /// Specular starlight rim border (22% white highlight).
  static const Color cosmicBorder = Color(0x38FFFFFF);

  /// Subtle starlight hairline border (10% white).
  static const Color cosmicBorderSubtle = Color(0x1AFFFFFF);

  /// Luminous ethereal violet boundary glow.
  static const Color cosmicBorderGlow = Color(0x60818CF8);

  /// Ethereal Radiant Violet / Periwinkle primary accent.
  static const Color cosmicIndigo = Color(0xFF818CF8);

  /// Starlight Nebula Gold secondary accent.
  static const Color cosmicGold = Color(0xFFFACC15);

  /// Nebula Electric Cyan tertiary accent.
  static const Color cosmicCyan = Color(0xFF38BDF8);

  /// Pure starlight white typography (>18:1 contrast - WCAG AAA).
  static const Color cosmicTextMain = Color(0xFFFFFFFF);

  /// Slate 300 starlight muted text (8.5:1 contrast against cosmic card - WCAG AAA).
  static const Color cosmicTextMuted = Color(0xFFCBD5E1);

  /// Ethereal violet-cyan ambient aura.
  static const Color cosmicGlow = Color(0x60818CF8);

  // ===========================================================================
  // STUDIO CANVAS ACCENTS & SEMANTIC INDICATORS
  // ===========================================================================
  static const Color primaryBlue = Color(0xFF2563EB); // Vibrant Electric Indigo/Blue
  static const Color hoverBlue = Color(0xFF3B82F6);
  static const Color selectionWire = Color(0xFF2563EB);
  static const Color componentPurple = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color guidePink = Color(0xFFEC4899);

  // ===========================================================================
  // VIEWPORT CANVAS DEFAULTS
  // ===========================================================================
  static const Color canvasDefaultBg = Color(0xFFF2EFE9);
  static const Color canvasDarkBg = Color(0xFF070A10);
  static const Color canvasGridLight = Color(0xFFE4E2DC);
  static const Color canvasGridDark = Color(0xFF1A2232);
}
