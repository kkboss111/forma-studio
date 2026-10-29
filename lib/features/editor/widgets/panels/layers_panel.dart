import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/project_model.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/editor_state.dart';

class LayersPanel extends ConsumerStatefulWidget {
  final ProjectModel project;
  final double? width;

  const LayersPanel({super.key, required this.project, this.width = 250});

  @override
  ConsumerState<LayersPanel> createState() => _LayersPanelState();
}

class _LayersPanelState extends ConsumerState<LayersPanel> {
  final Set<String> _collapsedFolderIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider(widget.project));
    final controller = ref.read(editorControllerProvider(widget.project).notifier);
    final page = state.project.getPage(state.activePageId);

    if (page == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.width,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                // New Folder Button
                IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined, size: 14),
                  tooltip: 'New Folder',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  splashRadius: 12,
                  onPressed: () {
                    controller.createNode(
                      type: NodeType.group,
                      rect: const Rect.fromLTWH(100, 100, 240, 240),
                      name: 'New Folder ${state.project.nodes.length + 1}',
                    );
                  },
                ),
                // Add Layer / Node Popup Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add_box_outlined, size: 14),
                  tooltip: 'Insert Node / Layer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  splashRadius: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (choice) => _insertNodeFromMenu(choice, controller, state),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'rect',
                      child: Row(
                        children: [
                          Icon(Icons.crop_square_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Rectangle', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'roundedRect',
                      child: Row(
                        children: [
                          Icon(Icons.rectangle_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Rounded Rect', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'triangle',
                      child: Row(
                        children: [
                          Icon(Icons.change_history_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Triangle (3 Corners)', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'ellipse',
                      child: Row(
                        children: [
                          Icon(Icons.circle_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Oval / Circle', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'polygon',
                      child: Row(
                        children: [
                          Icon(Icons.hexagon_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Polygon (Multi-corner)', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'star',
                      child: Row(
                        children: [
                          Icon(Icons.star_border_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Star', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'text',
                      child: Row(
                        children: [
                          Icon(Icons.title_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Text Node', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pen',
                      child: Row(
                        children: [
                          Icon(Icons.polyline_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Vector Pen Path', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'frame',
                      child: Row(
                        children: [
                          Icon(Icons.crop_free_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Frame / Artboard', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'group',
                      child: Row(
                        children: [
                          Icon(Icons.folder_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Folder Group', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                // Delete Selected Button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 14,
                    color: state.selectedNodeIds.isNotEmpty
                        ? FormaColors.dangerRed
                        : null,
                  ),
                  tooltip: 'Delete Selected',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  splashRadius: 12,
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
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    buildDefaultDragHandles: false,
                    itemCount: page.rootNodeIds.length,
                    onReorder: (oldIdx, newIdx) {
                      final len = page.rootNodeIds.length;
                      final realOld = len - 1 - oldIdx;
                      final realNew = len - 1 - (newIdx > oldIdx ? newIdx - 1 : newIdx);
                      controller.reorderRootNodes(realOld, realNew);
                    },
                    itemBuilder: (context, index) {
                      final nodeId =
                          page.rootNodeIds[page.rootNodeIds.length - 1 - index];
                      final node = state.project.nodes[nodeId];
                      if (node == null) return SizedBox.shrink(key: ValueKey(nodeId));

                      final layerNumber = page.rootNodeIds.indexOf(nodeId) + 1;

                      return Container(
                        key: ValueKey(node.id),
                        child: _buildLayerItem(
                          context: context,
                          node: node,
                          depth: 0,
                          layerNumber: layerNumber,
                          reorderIndex: index,
                          state: state,
                          controller: controller,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _insertNodeFromMenu(String choice, EditorController controller, dynamic state) {
    switch (choice) {
      case 'rect':
        controller.createNode(type: NodeType.rectangle, rect: const Rect.fromLTWH(100, 100, 180, 120));
        break;
      case 'roundedRect':
        controller.createNode(type: NodeType.roundedRectangle, rect: const Rect.fromLTWH(100, 100, 180, 120));
        break;
      case 'triangle':
        controller.createNode(type: NodeType.polygon, rect: const Rect.fromLTWH(100, 100, 160, 140), polygonSides: 3, name: 'Triangle ${state.project.nodes.length + 1}');
        break;
      case 'ellipse':
        controller.createNode(type: NodeType.ellipse, rect: const Rect.fromLTWH(100, 100, 140, 140));
        break;
      case 'polygon':
        controller.createNode(type: NodeType.polygon, rect: const Rect.fromLTWH(100, 100, 150, 150), polygonSides: 5);
        break;
      case 'star':
        controller.createNode(type: NodeType.star, rect: const Rect.fromLTWH(100, 100, 150, 150));
        break;
      case 'text':
        controller.createNode(type: NodeType.text, rect: const Rect.fromLTWH(100, 100, 200, 40));
        break;
      case 'pen':
        controller.setTool(EditorTool.vectorPen);
        break;
      case 'frame':
        controller.createNode(type: NodeType.frame, rect: const Rect.fromLTWH(100, 100, 360, 260), name: 'Frame ${state.project.nodes.length + 1}');
        break;
      case 'group':
        if (state.selectedNodeIds.length > 1) {
          controller.groupSelectedNodes();
        } else {
          controller.createNode(type: NodeType.group, rect: const Rect.fromLTWH(100, 100, 200, 200), name: 'Group ${state.project.nodes.length + 1}');
        }
        break;
    }
  }

  Widget _buildLayerItem({
    required BuildContext context,
    required DesignNode node,
    required int depth,
    int? layerNumber,
    int? reorderIndex,
    required dynamic state,
    required EditorController controller,
    required bool isDark,
  }) {
    final isSelected = state.selectedNodeIds.contains(node.id);
    final isFolder = node.type == NodeType.group ||
        node.type == NodeType.frame ||
        node.childrenIds.isNotEmpty;
    final isCollapsed = _collapsedFolderIds.contains(node.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => controller.selectNode(node.id),
          child: Container(
            height: 36,
            padding: EdgeInsets.only(left: 8.0 + (depth * 14.0), right: 6.0),
            color: isSelected
                ? FormaColors.primaryBlue.withValues(
                    alpha: isDark ? 0.25 : 0.12,
                  )
                : Colors.transparent,
            child: Row(
              children: [
                if (isFolder) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isCollapsed) {
                          _collapsedFolderIds.remove(node.id);
                        } else {
                          _collapsedFolderIds.add(node.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        isCollapsed
                            ? Icons.keyboard_arrow_right_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: isDark
                            ? FormaColors.darkTextMuted
                            : FormaColors.lightTextMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                ] else ...[
                  const SizedBox(width: 17),
                ],
                if (layerNumber != null) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'L$layerNumber',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
                      ),
                    ),
                  ),
                ],
                Icon(
                  isFolder
                      ? (isCollapsed ? Icons.folder_rounded : Icons.folder_open_rounded)
                      : _getNodeIcon(node.type),
                  size: 15,
                  color: isFolder
                      ? const Color(0xFFF59E0B)
                      : (isSelected
                          ? FormaColors.primaryBlue
                          : (isDark
                              ? FormaColors.darkTextMuted
                              : FormaColors.lightTextMuted)),
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
                    minWidth: 22,
                    minHeight: 22,
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
                    minWidth: 22,
                    minHeight: 22,
                  ),
                  onPressed: () => controller.toggleVisibility(node.id),
                ),
                const SizedBox(width: 2),
                if (reorderIndex != null)
                  ReorderableDragStartListener(
                    index: reorderIndex,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 15,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Render child layers recursively if not collapsed (Windows style)
        if (!isCollapsed) ...[
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
