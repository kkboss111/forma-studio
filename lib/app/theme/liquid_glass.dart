import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'forma_theme.dart';

/// Styling parameters and design tokens for the Liquid Glass theme
/// modeled after Apple iOS 18 & visionOS hyper-realistic glassmorphism:
/// - Multi-layered blur with ui.ImageFilter.blur
/// - Specular top-edge highlights (1px light reflection rim)
/// - Frosted semi-transparency calibrated for WCAG AAA high clarity
/// - Iridescent subtle border gradients simulating chromatic glass refraction
class LiquidGlassTheme {
  LiquidGlassTheme._();

  static const Color accentBlue = Color(0xFF007AFF);
  static const Color accentCyan = Color(0xFF0284C7);
  static const Color accentSky = Color(0xFF38BDF8);
  static const Color textDark = Color(0xFF0F172A); // Rich ink slate (WCAG AAA)
  static const Color textMuted = Color(0xFF334155); // Slate 700 (WCAG AAA)
  static const Color textLight = Color(0xFFFFFFFF); // Pristine white

  /// Apple visionOS fluid sky mesh gradient
  static const LinearGradient liquidMeshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE0F2FE), // Sky 100
      Color(0xFFBAE6FD), // Sky 200
      Color(0xFF7DD3FC), // Sky 300
      Color(0xFF38BDF8), // Sky 400
    ],
    stops: [0.0, 0.35, 0.70, 1.0],
  );

  /// Deep space cosmic fluid mesh gradient
  static const LinearGradient liquidDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A101D),
      Color(0xFF141E30),
      Color(0xFF243B55),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Iridescent subtle border gradient (simulating optical glass prism refraction)
  static const LinearGradient iridescentLightBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xF0FFFFFF), // 94% specular white at top edge
      Color(0x60BAE6FD), // Subtle iridescent sky refraction
      Color(0x50C7D2FE), // Delicate iridescent lavender micro-tone
      Color(0x66FFFFFF), // 40% diffuse white at bottom
    ],
    stops: [0.0, 0.30, 0.70, 1.0],
  );

  /// Iridescent border gradient for dark glassmorphism
  static const LinearGradient iridescentDarkBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x90FFFFFF), // Specular starlight top rim
      Color(0x4038BDF8), // Ambient electric cyan edge
      Color(0x35818CF8), // Ethereal violet edge
      Color(0x25FFFFFF), // Diffuse bottom
    ],
    stops: [0.0, 0.30, 0.70, 1.0],
  );
}

/// Custom painter for rendering crisp, hairline iridescent border gradients
/// with visionOS top-edge specular illumination.
class _LiquidGlassBorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final bool isDark;
  final bool iridescent;
  final Gradient? customGradient;

  const _LiquidGlassBorderPainter({
    required this.radius,
    this.strokeWidth = 1.0,
    required this.isDark,
    this.iridescent = true,
    this.customGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final halfStroke = strokeWidth / 2;
    final insetRect = Rect.fromLTWH(
      halfStroke,
      halfStroke,
      math.max(0.0, size.width - strokeWidth),
      math.max(0.0, size.height - strokeWidth),
    );
    final clampedRadius = Radius.circular(math.max(0.0, radius - halfStroke));
    final rrect = RRect.fromRectAndRadius(insetRect, clampedRadius);

    final gradient = customGradient ??
        (iridescent
            ? (isDark
                ? LiquidGlassTheme.iridescentDarkBorderGradient
                : LiquidGlassTheme.iridescentLightBorderGradient)
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.white.withValues(alpha: 0.50),
                        Colors.white.withValues(alpha: 0.15),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.40),
                      ],
              ));

    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassBorderPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isDark != isDark ||
        oldDelegate.iridescent != iridescent ||
        oldDelegate.customGradient != customGradient;
  }
}

/// A hyper-realistic frosted glass container with multi-layered blur,
/// specular top-edge highlights, frosted semi-transparency with [ui.ImageFilter.blur],
/// iridescent subtle border gradients, and high-clarity readability.
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
  final bool iridescent;
  final Gradient? borderGradient;

  const LiquidGlassBox({
    super.key,
    required this.child,
    this.radius = 20,
    this.blur = 28.0,
    this.opacity = 0.45,
    this.hasBorder = true,
    this.hasSpecular = true,
    this.hasSheen = true,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.tintColor,
    this.iridescent = true,
    this.borderGradient,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = FormaTheme.tokensOf(context);
    final isDarkGlass = tokens.isDark;

    // Calibrated base frosted color ensuring WCAG AAA readability for enclosed text
    final baseColor = tintColor ??
        (isDarkGlass
            ? Color.lerp(
                const Color(0x18FFFFFF),
                const Color(0x280D1322),
                0.5,
              )!
            : Colors.white.withValues(
                alpha: opacity > 0.6 ? opacity : 0.84,
              ));

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: isDarkGlass
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  offset: const Offset(0, 16),
                  blurRadius: 36,
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.15),
                  offset: const Offset(0, 2),
                  blurRadius: 16,
                ),
                if (hasSpecular)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.22),
                    offset: const Offset(0, 1),
                    blurRadius: 0,
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
                    color: Colors.white.withValues(alpha: 0.65),
                    offset: const Offset(0, 1),
                    blurRadius: 0,
                  ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            color: baseColor,
            child: Stack(
              children: [
                // 1. Ambient diagonal sheen reflection wash
                if (hasSheen)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: math.max(64.0, (height ?? 140) * 0.45),
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(radius),
                            topRight: Radius.circular(radius),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(
                                alpha: isDarkGlass ? 0.14 : 0.28,
                              ),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 2. Specular top-edge hairline highlight (catches overhead environmental light)
                if (hasSpecular)
                  Positioned(
                    top: 0,
                    left: math.max(4.0, radius * 0.4),
                    right: math.max(4.0, radius * 0.4),
                    height: 1.2,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(
                                alpha: isDarkGlass ? 0.50 : 0.88,
                              ),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. Child content with user padding
                Container(
                  padding: padding,
                  child: child,
                ),

                // 4. Iridescent & specular hairline border overlay
                if (hasBorder)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _LiquidGlassBorderPainter(
                          radius: radius,
                          strokeWidth: 1.0,
                          isDark: isDarkGlass,
                          iridescent: iridescent,
                          customGradient: borderGradient,
                        ),
                      ),
                    ),
                  ),
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
  final double radius;

  const LiquidGlassCapsule({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.isSelected = false,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = FormaTheme.tokensOf(context);
    final isDarkGlass = tokens.isDark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: padding,
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.accent
                  : (isDarkGlass
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.65)),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.6)
                    : (isDarkGlass
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.85)),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? tokens.accent.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: isDarkGlass ? 0.25 : 0.06),
                  blurRadius: 8,
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

/// An Apple iOS 18-styled smooth fluid switch.
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
    final tokens = FormaTheme.tokensOf(context);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value
              ? tokens.accent
              : (tokens.isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: value
                  ? tokens.accent.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact frosted glass slider for values and percentages.
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
    final tokens = FormaTheme.tokensOf(context);
    final clamped = value.clamp(min, max);
    final ratio = (max > min) ? (clamped - min) / (max - min) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 80.0;

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
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: tokens.isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.08),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Filled active portion
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: tokens.accent,
                    ),
                  ),
                ),
                // Specular Knob
                Positioned(
                  left: (ratio * (totalWidth - 14)).clamp(0.0, totalWidth - 14.0),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
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
    final tokens = FormaTheme.tokensOf(context);
    final isDarkGlass = tokens.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDarkGlass
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDarkGlass
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.85),
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
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: tokens.textMain,
          ),
        ),
      ),
    );
  }
}

/// A convenience card widget wrapped in visionOS frosted liquid glass.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tintColor;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.blur = 28.0,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final glassBox = LiquidGlassBox(
      radius: radius,
      blur: blur,
      padding: padding,
      tintColor: tintColor,
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: glassBox,
      );
    }
    return glassBox;
  }
}
