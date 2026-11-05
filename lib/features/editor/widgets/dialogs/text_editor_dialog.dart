import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/text_data.dart';
import '../../../../domain/services/node_render_service.dart';
import '../../controllers/editor_controller.dart';

class TextEditorDialog {
  TextEditorDialog._();

  static Future<void> show(
    BuildContext context,
    DesignNode node,
    EditorController controller,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCtrl = TextEditingController(text: node.textData?.text ?? '');

    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.title_rounded, color: FormaColors.primaryBlue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit Canvas Text',
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          maxLines: 4,
          minLines: 1,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
            hintText: 'Type text...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, textCtrl.text),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newText != null && newText.trim().isNotEmpty) {
      final t = (node.textData ?? const TextNodeData()).copyWith(text: newText);
      final measured = NodeRenderService.measureText(t);
      controller.updateNode(
        node.copyWith(
          textData: t,
          width: math.max(node.width, measured.width + 8.0),
          height: math.max(node.height, measured.height + 4.0),
        ),
      );
    }
  }
}
