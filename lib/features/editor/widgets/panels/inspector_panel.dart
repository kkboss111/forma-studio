import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/project_model.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../core/export/code_exporter.dart';
import '../../controllers/editor_controller.dart';

class InspectorPanel extends ConsumerWidget {
  final ProjectModel project;

  const InspectorPanel({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorControllerProvider(project));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedId = state.primarySelectedId;
    final node = selectedId != null ? state.project.nodes[selectedId] : null;

    if (node == null) {
      return Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        child: Center(
          child: Text(
            'Select any layer to inspect CSS and Flutter widget code snippets',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? FormaColors.darkTextMuted
                  : FormaColors.lightTextMuted,
            ),
          ),
        ),
      );
    }

    final cssCode = CodeExporter.generateCss(node);
    final flutterCode = CodeExporter.generateFlutterWidget(node);

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        border: Border(
          left: BorderSide(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEV INSPECTOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark
                      ? FormaColors.darkTextMuted
                      : FormaColors.lightTextMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: FormaColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  node.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: FormaColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Flutter Code Snippet
          _buildCodeBlock(
            context: context,
            title: 'FLUTTER WIDGET',
            code: flutterCode,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // CSS Code Snippet
          _buildCodeBlock(
            context: context,
            title: 'CSS PROPERTIES',
            code: cssCode,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock({
    required BuildContext context,
    required String title,
    required String code,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark
                    ? FormaColors.darkTextMuted
                    : FormaColors.lightTextMuted,
              ),
            ),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title copied to clipboard!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: const Row(
                children: [
                  Icon(
                    Icons.copy_rounded,
                    size: 12,
                    color: FormaColors.primaryBlue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Copy',
                    style: TextStyle(
                      fontSize: 11,
                      color: FormaColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13171F) : const Color(0xFF1E2532),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFFE2E8F0),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
