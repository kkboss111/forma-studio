import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/project_model.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../controllers/editor_controller.dart';

class LayersPanel extends ConsumerWidget {
  final ProjectModel project;
  final double? width;

  const LayersPanel({super.key, required this.project, this.width = 250});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorControllerProvider(project));
    final controller = ref.read(editorControllerProvider(project).notifier);
    final page = state.project.getPage(state.activePageId);

    if (page == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Quick Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Text(
                  'LAYERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? FormaColors.darkTextMuted
                        : FormaColors.lightTextMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${state.project.nodes.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? FormaColors.darkTextMuted
                          : FormaColors.lightTextMuted,
                    ),
                  ),
                ),
                const Spacer(),
                // Group Button
                IconButton(
                  icon: const Icon(Icons.folder_outlined, size: 15),
                  tooltip: 'Group (Ctrl+G)',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  splashRadius: 14,
                  onPressed: state.selectedNodeIds.length > 1
                      ? controller.groupSelectedNodes
                      : null,
                ),
                // Add Frame Button
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, size: 15),
                  tooltip: 'Add Frame',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  splashRadius: 14,
                  onPressed: () {
                    controller.createNode(
                      type: NodeType.frame,
                      rect: const Rect.fromLTWH(100, 100, 320, 240),
                      name: 'Frame ${state.project.nodes.length + 1}',
                    );
                  },
                ),
                // Delete Selected Button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 15,
                    color: state.selectedNodeIds.isNotEmpty
                        ? FormaColors.dangerRed
                        : null,
                  ),
                  tooltip: 'Delete Selected',
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  splashRadius: 14,
                  onPressed: state.selectedNodeIds.isNotEmpty
                      ? controller.deleteSelectedNodes
                      : null,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Layer Tree
          Expanded(
            child: page.rootNodeIds.isEmpty
                ? Center(
                    child: Text(
                      'No layers yet\nDraw a shape to start',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? FormaColors.darkTextMuted
                            : FormaColors.lightTextMuted,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    // Reversed to show topmost on top (like Figma/Photoshop)
                    itemCount: page.rootNodeIds.length,
                    itemBuilder: (context, index) {
                      final nodeId =
                          page.rootNodeIds[page.rootNodeIds.length - 1 - index];
                      final node = state.project.nodes[nodeId];
                      if (node == null) return const SizedBox.shrink();

                      return _buildLayerItem(
                        context: context,
                        node: node,
                        depth: 0,
                        state: state,
                        controller: controller,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerItem({
    required BuildContext context,
    required DesignNode node,
    required int depth,
    required dynamic state,
    required EditorController controller,
    required bool isDark,
  }) {
    final isSelected = state.selectedNodeIds.contains(node.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => controller.selectNode(node.id),
          child: Container(
            height: 36,
            padding: EdgeInsets.only(left: 12.0 + (depth * 14.0), right: 8.0),
            color: isSelected
                ? FormaColors.primaryBlue.withValues(
                    alpha: isDark ? 0.25 : 0.12,
                  )
                : Colors.transparent,
            child: Row(
              children: [
                Icon(
                  _getNodeIcon(node.type),
                  size: 15,
                  color: isSelected
                      ? FormaColors.primaryBlue
                      : (isDark
                            ? FormaColors.darkTextMuted
                            : FormaColors.lightTextMuted),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : FormaColors.lightTextMain)
                          : (isDark
                                ? FormaColors.darkTextMain
                                : FormaColors.lightTextMain),
                    ),
                  ),
                ),
                // Lock toggle
                IconButton(
                  icon: Icon(
                    node.isLocked
                        ? Icons.lock_outline_rounded
                        : Icons.lock_open_rounded,
                    size: 14,
                    color: node.isLocked
                        ? FormaColors.primaryBlue
                        : (isDark
                              ? FormaColors.darkTextMuted
                              : FormaColors.lightTextMuted),
                  ),
                  splashRadius: 12,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: () => controller.toggleLock(node.id),
                ),
                // Visibility toggle
                IconButton(
                  icon: Icon(
                    node.isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 14,
                    color: node.isVisible
                        ? (isDark
                              ? FormaColors.darkTextMuted
                              : FormaColors.lightTextMuted)
                        : Colors.grey,
                  ),
                  splashRadius: 12,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  onPressed: () => controller.toggleVisibility(node.id),
                ),
              ],
            ),
          ),
        ),
        // Render child layers recursively
        for (final childId in node.childrenIds) ...[
          if (state.project.nodes[childId] != null)
            _buildLayerItem(
              context: context,
              node: state.project.nodes[childId]!,
              depth: depth + 1,
              state: state,
              controller: controller,
              isDark: isDark,
            ),
        ],
      ],
    );
  }

  IconData _getNodeIcon(NodeType type) {
    switch (type) {
      case NodeType.frame:
        return Icons.crop_free_rounded;
      case NodeType.group:
        return Icons.folder_outlined;
      case NodeType.rectangle:
      case NodeType.roundedRectangle:
        return Icons.crop_square_rounded;
      case NodeType.ellipse:
        return Icons.circle_outlined;
      case NodeType.line:
      case NodeType.arrow:
        return Icons.horizontal_rule_rounded;
      case NodeType.polygon:
        return Icons.hexagon_outlined;
      case NodeType.star:
        return Icons.star_border_rounded;
      case NodeType.text:
        return Icons.title_rounded;
      case NodeType.image:
        return Icons.image_outlined;
      case NodeType.componentInstance:
        return Icons.widgets_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
