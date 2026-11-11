import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/forma_theme.dart';
import '../theme/neumorphic.dart';
import '../../features/settings/models/app_settings.dart';

/// Modal dialog allowing instant visual switching between the 3 Forma Studio themes:
/// System Default, Modern Studio Light, and Obsidian Studio Dark.
class FormaThemePickerDialog extends ConsumerWidget {
  const FormaThemePickerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => const FormaThemePickerDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final tokens = FormaTheme.tokensOf(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: NeuCard(
          radius: 24,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tokens.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.palette_outlined,
                          size: 20,
                          color: tokens.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STUDIO THEME',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: tokens.textMain,
                            ),
                          ),
                          Text(
                            'Select your active workspace visual identity',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: tokens.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. System Default
              _buildThemeCard(
                context: context,
                ref: ref,
                currentMode: settings.themeMode,
                mode: FormaThemeMode.system,
                title: 'System Default',
                subtitle: 'Syncs automatically with device OS appearance.',
                icon: Icons.brightness_auto_rounded,
                iconColor: tokens.accent,
                swatchColors: const [Color(0xFFFAF9F6), Color(0xFF05070B), Color(0xFF2563EB)],
                badgeText: 'Auto Match',
              ),
              const SizedBox(height: 10),

              // 2. Modern Studio Light
              _buildThemeCard(
                context: context,
                ref: ref,
                currentMode: settings.themeMode,
                mode: FormaThemeMode.light,
                title: 'Modern Studio Light',
                subtitle: 'Editorial paper craft, warm background & crisp hairline borders.',
                icon: Icons.light_mode_rounded,
                iconColor: const Color(0xFF2563EB),
                swatchColors: const [Color(0xFFFAF9F6), Color(0xFFFFFFFF), Color(0xFF2563EB)],
                badgeText: 'Warm Paper',
              ),
              const SizedBox(height: 10),

              // 3. Obsidian Studio Dark
              _buildThemeCard(
                context: context,
                ref: ref,
                currentMode: settings.themeMode,
                mode: FormaThemeMode.dark,
                title: 'Obsidian Studio Dark',
                subtitle: 'True OLED pitch void, multi-tiered dark surfaces & electric accents.',
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF38BDF8),
                swatchColors: const [Color(0xFF05070B), Color(0xFF0F1420), Color(0xFF38BDF8)],
                badgeText: 'True OLED',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required WidgetRef ref,
    required FormaThemeMode currentMode,
    required FormaThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Color> swatchColors,
    required String badgeText,
  }) {
    final isSelected = currentMode == mode;
    final tokens = FormaTheme.tokensOf(context);

    return InkWell(
      onTap: () {
        ref.read(settingsProvider.notifier).setThemeMode(mode);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Activated $title ✨'),
              backgroundColor: tokens.accent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? tokens.accent
                : (tokens.isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 1.8 : 1.0,
          ),
          color: isSelected
              ? tokens.accent.withValues(alpha: tokens.isDark ? 0.16 : 0.08)
              : (tokens.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.15),
                border: Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: tokens.textMain,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: tokens.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Swatch Dots
            Row(
              mainAxisSize: MainAxisSize.min,
              children: swatchColors.map((c) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 0.8),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 10),

            // Checkmark if selected
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: tokens.accent,
              ),
          ],
        ),
      ),
    );
  }
}
