import 'package:flutter/material.dart';

/// Design tokens and color constants for Forma Studio.
/// Visual styling is derived from the neumorphic reference palette:
/// Soft blue-gray (#E6ECF5), dark-slate (#2B3445), muted (#8A99AD),
/// with crisp highlights (#FFFFFF) and soft shadows (#C8D3E2).
class FormaColors {
  FormaColors._();

  // --- Light Neumorphic Palette ---
  static const Color lightBg = Color(0xFFE6ECF5);
  static const Color lightSurface = Color(0xFFE6ECF5);
  static const Color lightWellBg = Color(0xFFDCE4F0);
  static const Color lightShadowLight = Color(0xFFFFFFFF);
  static const Color lightShadowDark = Color(0xFFC8D3E2);
  static const Color lightTextMain = Color(0xFF2B3445);
  static const Color lightTextMuted = Color(0xFF8A99AD);
  static const Color lightAccent = Color(0xFF1E2532);
  static const Color lightBorder = Color(0xFFDFE6F0);
  static const Color lightDashed = Color(0xFFD5DEEA);

  // --- Dark Neumorphic Palette ---
  static const Color darkBg = Color(0xFF181C24);
  static const Color darkSurface = Color(0xFF1E242F);
  static const Color darkWellBg = Color(0xFF141820);
  static const Color darkShadowLight = Color(0xFF27303E);
  static const Color darkShadowDark = Color(0xFF11151B);
  static const Color darkTextMain = Color(0xFFE8EEF5);
  static const Color darkTextMuted = Color(0xFF808F9F);
  static const Color darkAccent = Color(0xFF4C75F2);
  static const Color darkBorder = Color(0xFF283140);
  static const Color darkDashed = Color(0xFF333F52);

  // --- Design Canvas Accents ---
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color hoverBlue = Color(0xFF60A5FA);
  static const Color selectionWire = Color(0xFF2563EB);
  static const Color componentPurple = Color(0xFF8B5CF6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color guidePink = Color(0xFFEC4899);

  // --- Canvas Defaults ---
  static const Color canvasDefaultBg = Color(0xFFF0F4FA);
  static const Color canvasDarkBg = Color(0xFF14181F);
  static const Color canvasGridLight = Color(0xFFDCE4F0);
  static const Color canvasGridDark = Color(0xFF232A36);
}
