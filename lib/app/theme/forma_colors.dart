import 'package:flutter/material.dart';

/// Design tokens and semantic color constants for Forma Studio.
/// Adheres to modern craft principles (/impeccable & /design-taste-frontend):
/// - High contrast typography (WCAG AAA >= 7:1)
/// - Crisp hairline borders (1px Slate 200/800)
/// - Subtle multi-layer ambient elevation (zero muddy halos)
/// - Unified 4-theme system: Light, Dark, Liquid Glass, Cosmic Glassmorphism
class FormaColors {
  FormaColors._();

  // --- Modern Studio Light Palette (Crisp White on Slate-50) ---
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightWellBg = Color(0xFFF1F5F9);
  static const Color lightShadowLight = Color(0xFFFFFFFF);
  static const Color lightShadowDark = Color(0x0F0F172A); // 6% diffuse ambient
  static const Color lightTextMain = Color(0xFF0F172A); // Slate 900
  static const Color lightTextMuted = Color(0xFF64748B); // Slate 500
  static const Color lightAccent = Color(0xFF2563EB); // Royal Blue
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);
  static const Color lightDashed = Color(0xFFCBD5E1);

  // --- Obsidian Studio Dark Palette (Deep Void on Slate-900) ---
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkWellBg = Color(0xFF0B0F19);
  static const Color darkShadowLight = Color(0x0FFFFFFF); // 6% specular rim
  static const Color darkShadowDark = Color(0x66000000); // 40% deep ambient
  static const Color darkTextMain = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextMuted = Color(0xFF94A3B8); // Slate 400
  static const Color darkAccent = Color(0xFF38BDF8); // Electric Sky
  static const Color darkBorder = Color(0xFF1E293B); // Slate 800
  static const Color darkBorderSubtle = Color(0xFF141C2C);
  static const Color darkDashed = Color(0xFF334155);

  // --- Liquid Glass Palette (macOS / visionOS Translucency) ---
  static const Color liquidGlassCyan = Color(0xFF0284C7);
  static const Color liquidGlassSky = Color(0xFF38BDF8);
  static const Color liquidGlassTeal = Color(0xFF0D9488);
  static const Color liquidGlassCard = Color(0xD0FFFFFF); // 82% frosted white
  static const Color liquidGlassBorder = Color(0xB0FFFFFF); // Luminous specular
  static const Color liquidGlassGlow = Color(0x4038BDF8);

  // --- Cosmic Glassmorphism Palette (Deep Indigo / Starlight Gold) ---
  static const Color cosmicBg = Color(0xFF060913);
  static const Color cosmicCard = Color(0x18FFFFFF); // 9.5% frosted glass
  static const Color cosmicBorder = Color(0x35FFFFFF); // 21% specular edge
  static const Color cosmicIndigo = Color(0xFF6366F1); // Radiant Violet
  static const Color cosmicGold = Color(0xFFFACC15); // Nebula Gold
  static const Color cosmicCyan = Color(0xFF0EA5E9);

  // --- Studio Canvas Accents & Semantic Indicators ---
  static const Color primaryBlue = Color(0xFF2563EB); // Vibrant Electric Indigo/Blue
  static const Color hoverBlue = Color(0xFF3B82F6);
  static const Color selectionWire = Color(0xFF2563EB);
  static const Color componentPurple = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color guidePink = Color(0xFFEC4899);

  // --- Viewport Canvas Defaults ---
  static const Color canvasDefaultBg = Color(0xFFF1F5F9);
  static const Color canvasDarkBg = Color(0xFF080C14);
  static const Color canvasGridLight = Color(0xFFE2E8F0);
  static const Color canvasGridDark = Color(0xFF1B2332);
}
