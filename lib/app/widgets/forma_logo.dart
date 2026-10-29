// ==============================================================================
// FORMA STUDIO — OFFICIAL BRAND LOGO
// ==============================================================================
// Permanent, official 3D glassmorphic brand insignia for Forma Studio.
// Non-editable across all app surfaces and screens.
// High-resolution asset bundled at 'assets/images/forma_logo.png' with
// pure vector fallback painter for offline/headless rendering.
// ==============================================================================

import 'package:flutter/material.dart';

class FormaLogo extends StatelessWidget {
  final double size;
  final bool isAnimated;
  final Color? primaryColor;
  final Color? secondaryColor;

  const FormaLogo({
    super.key,
    this.size = 42.0,
    this.isAnimated = false,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseSize = size.clamp(14.0, 512.0);
    final radius = baseSize * 0.22;

    return Container(
      width: baseSize,
      height: baseSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: (primaryColor ?? const Color(0xFF2563EB)).withValues(alpha: 0.28),
            blurRadius: baseSize * 0.16,
            offset: Offset(0, baseSize * 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/forma_logo.png',
          width: baseSize,
          height: baseSize,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              size: Size(baseSize, baseSize),
              painter: _FormaLogoPainter(
                primaryColor: primaryColor ?? const Color(0xFF2563EB),
                secondaryColor: secondaryColor ?? const Color(0xFF1D4ED8),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FormaLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _FormaLogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = w * 0.22;

    // Base Gradient Surface Container
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bgRect);

    final rrect = RRect.fromRectAndRadius(bgRect, Radius.circular(radius));
    canvas.drawRRect(rrect, bgPaint);

    // Inner Specular Sheen (Top-Left Highlight)
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.center,
      ).createShader(bgRect);
    canvas.drawRRect(rrect, sheenPaint);

    // Geometric "F" Vector Glyph
    final fPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final stemWidth = w * 0.22;
    final stemLeft = w * 0.25;
    final stemTop = h * 0.22;
    final stemHeight = h * 0.56;

    // Vertical Stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(stemLeft, stemTop, stemWidth, stemHeight),
        Radius.circular(stemWidth * 0.45),
      ),
      fPaint,
    );

    // Top Bar
    final topBarWidth = w * 0.50;
    final topBarHeight = h * 0.17;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(stemLeft, stemTop, topBarWidth, topBarHeight),
        Radius.circular(topBarHeight * 0.45),
      ),
      fPaint,
    );

    // Middle Bar
    final midBarWidth = w * 0.36;
    final midBarHeight = h * 0.15;
    final midBarTop = stemTop + h * 0.22;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(stemLeft, midBarTop, midBarWidth, midBarHeight),
        Radius.circular(midBarHeight * 0.45),
      ),
      fPaint,
    );

    // Accent Dot
    final dotRadius = w * 0.08;
    canvas.drawCircle(
      Offset(stemLeft + stemWidth * 0.5, stemTop + stemHeight - dotRadius),
      dotRadius,
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _FormaLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
