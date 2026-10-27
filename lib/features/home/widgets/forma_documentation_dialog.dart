import 'package:flutter/material.dart';
import '../../../app/theme/forma_colors.dart';
import '../../../app/theme/neumorphic.dart';
import '../../../app/widgets/forma_logo.dart';

class FormaDocumentationDialog extends StatelessWidget {
  const FormaDocumentationDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const FormaDocumentationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 760,
        height: 640,
        decoration: BoxDecoration(
          color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  const FormaLogo(size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forma Studio User Documentation & Guide',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? FormaColors.darkTextMain
                              : FormaColors.lightTextMain,
                        ),
                      ),
                      const Text(
                        'v0.1 (Beta Testing) • Mobile-First Vector Design Suite',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FormaColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    tooltip: 'Close Guide',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                children: [
                  _buildSection(
                    title: '1. Getting Started & Mobile Canvas Gestures',
                    icon: Icons.touch_app_rounded,
                    isDark: isDark,
                    content:
                        '• Tap on any object on the canvas to select it.\n'
                        '• Drag on the selection outline handles to resize, or drag outside corner handles to rotate.\n'
                        '• Pinch with two fingers to zoom smoothly (from 10% to 500%).\n'
                        '• Drag with two fingers or select the Hand tool (H) to pan across the infinite canvas.\n'
                        '• Double-tap on any Text object to directly edit its text in-place.\n'
                        '• Tap the Home icon in the top bar to return to your Recent Projects anytime.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: '2. Shapes, Frames & Layout Hierarchy',
                    icon: Icons.layers_rounded,
                    isDark: isDark,
                    content:
                        '• Create Frames (F), Rectangles (R), Rounded Rects, Ellipses (O), Polygons, Stars, and Lines.\n'
                        '• Use the Layers Panel on the left to reorder z-index, lock layers, hide/show, group (Ctrl+G), and rename.\n'
                        '• Lock your screen layout to mobile, tablet, or desktop presets inside Settings > Advanced.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: '3. Fills, Gradients & 10+ Design Effects',
                    icon: Icons.palette_rounded,
                    isDark: isDark,
                    content:
                        '• Set Solid fills, or rich Linear, Radial, and Angular gradients with custom angle and stops.\n'
                        '• Pick any gradient stop color using the integrated Color Wheel or swatches.\n'
                        '• Apply gradients directly to object Strokes as well as fills.\n'
                        '• Apply 12 distinct visual effects: Drop Shadow, Inner Shadow, Layer Blur, Background Frosted Blur, Outer Glow, Inner Glow, Color Tint, Vignette, Bloom, Grayscale, Sepia, and Invert Colors.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: '4. Motion Curves & Interactive Graph Editor',
                    icon: Icons.animation_rounded,
                    isDark: isDark,
                    content:
                        '• Open the Timeline panel from the top bar to play, pause, loop, and animate properties.\n'
                        '• Unified position tracking animates objects smoothly across the screen.\n'
                        '• Open the Graph Editor to inspect motion curves. Tap anywhere on the graph to add control points, and drag them to customize bezier transitions in real-time.',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: '5. Universal Import & Export (13 Formats)',
                    icon: Icons.import_export_rounded,
                    isDark: isDark,
                    content:
                        '• Import from industry formats including .fig, .sketch, .xd, .svg, .eps, .dxf, .json, and .forma.\n'
                        '• Export at 1x, 2x, 3x, 4x, or custom custom resolutions and scales.\n'
                        '• Share documents directly from the 3-dots project menu as .forma bundles or raster images.\n'
                        '• 100% offline: All work stays on your device with local storage and full archive backup support.',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Forma Studio • 100% Free & Open Vector Suite',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? FormaColors.darkTextMuted
                          : FormaColors.lightTextMuted,
                    ),
                  ),
                  NeuButton(
                    isActive: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Got it, thanks!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? FormaColors.darkWellBg.withValues(alpha: 0.5)
            : FormaColors.lightWellBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: FormaColors.primaryBlue),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? FormaColors.darkTextMain
                      : FormaColors.lightTextMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.6,
              color: isDark ? Colors.white70 : FormaColors.lightTextMain,
            ),
          ),
        ],
      ),
    );
  }
}
