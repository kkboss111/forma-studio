import 'package:flutter/material.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../controllers/editor_controller.dart';

/// Shows a dialog allowing manual entry of exact zoom percentage and presets.
Future<void> showManualZoomDialog(
  BuildContext context,
  EditorController controller,
  double currentZoom,
  bool extendedLimit,
) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final initialPct = (currentZoom * 100.0).round();
  final minPct = extendedLimit ? 1 : 10;
  final maxPct = extendedLimit ? 5000 : 800;

  final controllerText = TextEditingController(text: '$initialPct');

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            const Icon(Icons.zoom_in_rounded, size: 22, color: FormaColors.primaryBlue),
            const SizedBox(width: 8),
            Text(
              'Canvas Zoom Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? FormaColors.darkTextMain : FormaColors.lightTextMain,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter exact zoom percentage ($minPct% – $maxPct%):',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllerText,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? FormaColors.darkTextMain : FormaColors.lightTextMain,
                    ),
                    decoration: InputDecoration(
                      suffixText: '%',
                      suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: FormaColors.primaryBlue, width: 2),
                      ),
                    ),
                    onSubmitted: (val) {
                      final parsed = double.tryParse(val.replaceAll('%', '').trim());
                      if (parsed != null) {
                        final clamped = parsed.clamp(minPct.toDouble(), maxPct.toDouble());
                        controller.setZoom(clamped / 100.0, extendedLimit: extendedLimit);
                        Navigator.of(dialogCtx).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'QUICK PRESETS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (extendedLimit) 1,
                25,
                50,
                100,
                200,
                400,
                if (extendedLimit) 1000,
                if (extendedLimit) 5000,
              ].map((pct) {
                final isCurrent = initialPct == pct;
                return ActionChip(
                  label: Text('$pct%'),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? FormaColors.primaryBlue : null,
                  ),
                  backgroundColor: isCurrent
                      ? FormaColors.primaryBlue.withValues(alpha: 0.15)
                      : (isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg),
                  side: BorderSide(
                    color: isCurrent
                        ? FormaColors.primaryBlue
                        : (isDark ? FormaColors.darkBorder : FormaColors.lightBorder),
                  ),
                  onPressed: () {
                    controller.setZoom(pct / 100.0, extendedLimit: extendedLimit);
                    Navigator.of(dialogCtx).pop();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final parsed = double.tryParse(controllerText.text.replaceAll('%', '').trim());
              if (parsed != null) {
                final clamped = parsed.clamp(minPct.toDouble(), maxPct.toDouble());
                controller.setZoom(clamped / 100.0, extendedLimit: extendedLimit);
              }
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      );
    },
  );
}
