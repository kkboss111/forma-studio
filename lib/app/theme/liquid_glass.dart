import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'forma_theme.dart';

/// Styling parameters and design tokens for the Liquid Glass theme
/// modeled after macOS translucent glass design specs.
class LiquidGlassTheme {
  LiquidGlassTheme._();

  static const Color accentBlue = Color(0xFF007AFF);
  static const Color textDark = Color(0xFF1C3249);
  static const Color textMuted = Color(0xFF5A738C);
  static const Color textLight = Color(0xFFFFFFFF);

  // Background Gradient matching reference: macOS Sonoma fluid sky mesh
  static const LinearGradient liquidMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE0F2FE), // Sky-100
      Color(0xFFBAE6FD), // Sky-200
      Color(0xFF7DD3FC), // Sky-300
      Color(0xFF38BDF8), // Sky-400
    ],
    stops: [0.0, 0.35, 0.70, 1.0],
  );

  static const LinearGradient liquidDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F2027),
      Color(0xFF203A43),
      Color(0xFF2C5364),
    ],
  );
}

/// A frosted glass box with adjustable blur, luminous specular border, and sheen.
class LiquidGlassBox extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final double opacity;
  final bool hasBorder;
  final bool hasSpecular;
  final bool hasSheen;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? tintColor;

  const LiquidGlassBox({
    super.key,
    required this.child,
    this.radius = 20,
    this.blur = 24.0,
    this.opacity = 0.45,
    this.hasBorder = true,
    this.hasSpecular = true,
    this.hasSheen = false,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = FormaTheme.tokensOf(context);
    final isDarkGlass = tokens.isDark;
    final baseColor = tintColor ??
        (isDarkGlass
            ? const Color(0x1AFFFFFF)
            : Colors.white.withValues(alpha: opacity > 0.6 ? opacity : 0.82));

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isDarkGlass
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(0, 16),
                  blurRadius: 36,
                  spreadRadius: -4,
                ),
                if (hasSpecular)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.14),
                  offset: const Offset(0, 12),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
                if (hasSpecular)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.6),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(radius),
              border: hasBorder
                  ? Border.all(
                      color: isDarkGlass
                          ? const Color(0x2EFFFFFF)
                          : Colors.white.withValues(alpha: 0.85),
                      width: 1.0,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (hasSheen)
                  Positioned(
                    top: -40,
                    left: -20,
                    right: 40,
                    height: 90,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: isDarkGlass ? 0.15 : 0.35),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A floating glass capsule pill for toolbars and indicators.
class LiquidGlassCapsule extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool isSelected;

  const LiquidGlassCapsule({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isSelected
                  ? LiquidGlassTheme.accentBlue
                  : Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? LiquidGlassTheme.accentBlue.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// An iOS-styled switch button matching the reference design.
class LiquidGlassSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const LiquidGlassSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 34,
        height: 18,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value
              ? LiquidGlassTheme.accentBlue
              : Colors.black.withValues(alpha: 0.18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact glass slider for values and percentages.
class LiquidGlassSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? label;

  const LiquidGlassSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    final ratio = (max > min) ? (clamped - min) / (max - min) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 60.0;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final localX = details.localPosition.dx.clamp(0.0, totalWidth);
            final newRatio = localX / totalWidth;
            final newVal = min + newRatio * (max - min);
            onChanged(newVal);
          },
          onTapDown: (details) {
            final localX = details.localPosition.dx.clamp(0.0, totalWidth);
            final newRatio = localX / totalWidth;
            final newVal = min + newRatio * (max - min);
            onChanged(newVal);
          },
          child: Container(
            width: totalWidth,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: LiquidGlassTheme.accentBlue.withValues(alpha: 0.85),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: (ratio * (totalWidth - 12)).clamp(1.0, totalWidth - 12.0),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A numeric value box pill matching .val-box in the reference design.
class LiquidGlassValueBox extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const LiquidGlassValueBox({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: LiquidGlassTheme.textDark,
          ),
        ),
      ),
    );
  }
}
