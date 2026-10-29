import 'dart:math' as math;
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
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: math.min(size.width - 24, 760),
        height: math.min(size.height * 0.88, 660),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
              child: Row(
                children: [
                  const FormaLogo(size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forma Studio User Documentation & Guide',
                          style: TextStyle(
                            fontSize: 15,
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
                  ),
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
                  horizontal: 20,
                  vertical: 16,
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
                  const SizedBox(height: 16),
                  _buildSection(
                    title: '2. Vector Pen Tool & Bézier Path Drafting',
                    icon: Icons.polyline_rounded,
                    isDark: isDark,
                    content:
                        '• Select the Pen tool (P) or double-tap any vector object to enter Vector Edit Mode.\n'
                        '• Click or tap on canvas to place anchor points; drag while tapping to shape smooth tangent curve handles.\n'
                        '• Tap the first anchor point or tap "Close Path" on the floating HUD to close the vector loop.\n'
                        '• Toggle individual anchor points between smooth curves and sharp corners with "Smooth / Sharp".\n'
                        '• Delete selected anchors with the delete icon or Delete key, and tap "Finish" to exit vector mode.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: '3. Triangle, Polygons & Shift-Key Constraints',
                    icon: Icons.change_history_rounded,
                    isDark: isDark,
                    content:
                        '• Select Triangle from the tool dock or layer insert menu to draw 3-sided vector geometries.\n'
                        '• In the Properties Panel, customize corner count (3 to 12 sides) and fillet corner radius (0 to 50 px).\n'
                        '• Hold Shift while drawing or resizing any shape to enforce a perfect 1:1 aspect ratio (squares, circles, equilateral polygons).',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: '4. Shapes, Frames & Layer Stacking Order',
                    icon: Icons.layers_rounded,
                    isDark: isDark,
                    content:
                        '• Create Frames (F), Rectangles (R), Rounded Rects, Ellipses (O), Polygons, Stars, and Lines.\n'
                        '• Use the upgraded Layers Panel to reorder layers by dragging and dropping them up or down.\n'
                        '• Inspect layer level indicators (L1, L2, L3) and use Bring to Front, Bring Forward, Send Backward, and Send to Back buttons in the Properties Panel.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: '5. Fills, Gradients & Customizable Effects',
                    icon: Icons.palette_rounded,
                    isDark: isDark,
                    content:
                        '• Set Solid fills, or rich Linear, Radial, and Angular gradients with custom angle and stops.\n'
                        '• Customize Drop Shadows and Outer Glows with custom color pickers, darkness sliders, X & Y offsets, blur, and spread.\n'
                        '• Apply layer filters: Grayscale, Sepia, Invert Colors, Vignette, Bloom, and Frosted Glass Blurs.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: '6. Image Placement & Masking',
                    icon: Icons.image_outlined,
                    isDark: isDark,
                    content:
                        '• Insert standalone PNG/JPG/WebP images onto the canvas or mask them inside any shape.\n'
                        '• Adjust image opacity, corner radii, and use the built-in Crop & Filter studio.\n'
                        '• Quickly replace an image with a single tap using the Replace button.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: '7. Universal Import & Multi-Format Export',
                    icon: Icons.import_export_rounded,
                    isDark: isDark,
                    content:
                        '• Import from industry formats including .fig, .sketch, .xd, .svg, .eps, .dxf, .json, and .forma.\n'
                        '• Export full vector SVG with recursive hierarchy, embedded images, and drop shadow filters.\n'
                        '• Export packaged Figma (.fig), Sketch (.sketch), and Adobe XD (.xd) bundles with embedded vector SVG.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: '8. Themes & Security Passcodes',
                    icon: Icons.security_rounded,
                    isDark: isDark,
                    content:
                        '• Choose from Soft Neumorphic Light, Deep Slate Dark, Liquid Glass, Glassmorphism Frost, and Cyberpunk Neon.\n'
                        '• Unlock premium aesthetic themes using their dedicated 4-digit security PINs in Settings > Appearance.',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Forma Studio • 100% Free & Open Vector Suite',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? FormaColors.darkTextMuted
                          : FormaColors.lightTextMuted,
                    ),
                  ),
                  NeuButton(
                    isActive: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Got it, thanks!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
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
