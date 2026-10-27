import 'package:flutter/material.dart';
import '../theme/forma_colors.dart';
import 'forma_logo.dart';

enum StudioTransitionType {
  homeToCanvas,
  canvasToHome,
}

class StudioLoadingTransition extends StatelessWidget {
  final StudioTransitionType type;

  const StudioLoadingTransition({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHomeToCanvas = type == StudioTransitionType.homeToCanvas;

    final title = isHomeToCanvas
        ? 'Opening Design Canvas...'
        : 'Saving & Returning to Studio...';

    final subtitle = isHomeToCanvas
        ? 'Mounting vector artboards & shaders'
        : 'Syncing project state to local storage';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: FormaColors.primaryBlue.withValues(alpha: isDark ? 0.28 : 0.20),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const FormaLogo(size: 72),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 110,
                child: LinearProgressIndicator(
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  valueColor: const AlwaysStoppedAnimation<Color>(FormaColors.primaryBlue),
                  minHeight: 2.5,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
