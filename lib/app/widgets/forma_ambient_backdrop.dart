import 'package:flutter/material.dart';
import '../theme/forma_theme.dart';

/// Immersive ambient backdrop that paints rich nebula gradients and glowing orbs
/// behind frosted glass surfaces (Liquid Glass & Cosmic Glassmorphism).
class FormaAmbientBackdrop extends StatelessWidget {
  final Widget child;
  final FormaThemeTokens? explicitTokens;

  const FormaAmbientBackdrop({
    super.key,
    required this.child,
    this.explicitTokens,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = explicitTokens ?? FormaTheme.tokensOf(context);

    if (tokens.isGlass && tokens.isDark) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Base cosmic void with deep radial nebula
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF080D1A),
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.5),
                radius: 1.2,
                colors: [
                  Color(0xFF431D77), // Deep purple nebula
                  Color(0xFF1E1035), // Interstellar violet
                  Color(0xFF080D1A), // Space void
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Secondary magenta cosmic dust in top right
          Positioned(
            top: -60,
            right: -60,
            width: 380,
            height: 380,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x38B12A6F), // Glowing magenta
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tertiary oceanic cyan abyss in bottom center
          Positioned(
            bottom: -100,
            left: 0,
            right: 0,
            height: 350,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, 0.9),
                    radius: 1.1,
                    colors: [
                      Color(0x350C7585), // Deep radiant cyan
                      Color(0x2007192F),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Foreground app content
          child,
        ],
      );
    }

    if (tokens.isGlass && !tokens.isDark) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Base macOS Sonoma fluid sky mesh
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE0F2FE), // Sky-100
                  Color(0xFFBAE6FD), // Sky-200
                  Color(0xFF7DD3FC), // Sky-300
                  Color(0xFF38BDF8), // Sky-400
                ],
                stops: [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),

          // Ambient luminous cyan orb in top left
          Positioned(
            top: -40,
            left: -40,
            width: 320,
            height: 320,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x400284C7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Ambient aqua sheen in bottom right
          Positioned(
            bottom: -50,
            right: -50,
            width: 340,
            height: 340,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x3538BDF8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Foreground app content
          child,
        ],
      );
    }

    // Standard Solid Themes (Light / Dark)
    return Container(
      color: tokens.scaffoldBg,
      child: child,
    );
  }
}
