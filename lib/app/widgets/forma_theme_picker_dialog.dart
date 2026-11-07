import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/forma_colors.dart';
import '../theme/forma_theme.dart';
import '../theme/neumorphic.dart';
import '../../features/settings/models/app_settings.dart';

/// Modal dialog allowing instant visual switching between all 4 Forma Studio themes:
/// Modern Light, Obsidian Dark, Liquid Glass, and Cosmic Glassmorphism.
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
                            'STUDIO THEMES',
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

              // Theme Cards List
              _buildThemeCard(
                context: context,
                ref: ref,
                currentMode: settings.themeMode,
                mode: FormaThemeMode.light,
                title: 'Modern Studio Light',
                subtitle: 'Figma-style crisp white on Slate-50 with 1px hairline borders.',
                icon: Icons.light_mode_rounded,
                iconColor: const Color(0xFF2563EB),
                swatchColors: const [Color(0xFFF8FAFC), Color(0xFFFFFFFF), Color(0xFF2563EB)],
                badgeText: 'Crisp & Daytime',
              ),
              const SizedBox(height: 10),

              _buildThemeCard(
                context: context,
                ref: ref,
                currentMode: settings.themeMode,
                mode: FormaThemeMode.dark,
                title: 'Obsidian Studio Dark',
                subtitle: 'Raycast-style deep void black on Slate-900 with specular rim.',
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF38BDF8),
                swatchColors: const [Color(0xFF090D16), Color(0xFF111827), Color(0xFF38BDF8)],
                badgeText: 'Nighttime Studio',
              ),
              const SizedBox(height: 10),

              _buildThemeCard(
                context: context,
                ref: ref,
                currentMode: settings.themeMode,
                mode: FormaThemeMode.liquidGlass,
                title: 'Liquid Glass (macOS Sonoma)',
                subtitle: 'Apple translucent fluid glass with 24px blur and specular top sheen.',
                icon: Icons.blur_on_rounded,
                iconColor: const Color(0xFF0284C7),
                swatchColors: const [Color(0xFFBAE6FD), Color(0xCCFFFFFF), Color(0xFF0284C7)],
                badgeText: 'Translucent Fluid',
                requiresPin: true,
              ),
              const SizedBox(height: 10),

              _buildThemeCard(
                context: context,
                ref: ref,
                currentMode: settings.themeMode,
                mode: FormaThemeMode.glassmorphism,
                title: 'Cosmic Glassmorphism',
                subtitle: 'Bespoke CSS Glassmorphism with deep space radial nebula.',
                icon: Icons.auto_awesome_rounded,
                iconColor: const Color(0xFFFACC15),
                swatchColors: const [Color(0xFF080D1A), Color(0x24FFFFFF), Color(0xFF818CF8)],
                badgeText: 'Deep Space Nebula',
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
    bool requiresPin = false,
  }) {
    final isSelected = currentMode == mode;
    final tokens = FormaTheme.tokensOf(context);

    return InkWell(
      onTap: () async {
        if (requiresPin && mode == FormaThemeMode.liquidGlass) {
          final pin = await _showPasscodeDialog(context);
          if (pin == '1111') {
            ref.read(settingsProvider.notifier).setThemeMode(mode);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Activated Liquid Glass Theme 💧'),
                  backgroundColor: FormaColors.liquidGlassCyan,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else if (pin != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect PIN. Valid PIN is 1111.'),
                backgroundColor: FormaColors.dangerRed,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
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

  Future<String?> _showPasscodeDialog(BuildContext context) {
    final controller = TextEditingController(text: '1111');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unlock Liquid Glass Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the experimental PIN code to unlock visionOS translucent liquid glass:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'PIN (Default: 1111)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Confirm (1111)'),
          ),
        ],
      ),
    );
  }
}
