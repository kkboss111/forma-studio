import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/project_model.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../app/theme/forma_theme.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/editor_state.dart';

class LayersPanel extends ConsumerStatefulWidget {
  final ProjectModel project;
  final double? width;

  const LayersPanel({super.key, required this.project, this.width = 260});

  @override
  ConsumerState<LayersPanel> createState() => _LayersPanelState();
}

class _LayersPanelState extends ConsumerState<LayersPanel> {
  final Set<String> _collapsedFolderIds = {};
  String _searchQuery = '';
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRenameDialog(String nodeId, String currentName) {
    final textController = TextEditingController(text: currentName);
    final tokens = FormaTheme.tokensOf(context);

    showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: tokens.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Rename Layer',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: tokens.textMain,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(fontSize: 13, color: tokens.textMain),
          decoration: InputDecoration(
            filled: true,
            fillColor: tokens.wellBg,
            hintText: 'Enter layer name...',
            hintStyle: TextStyle(fontSize: 12, color: tokens.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.accent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onSubmitted: (val) {
            Navigator.pop(ctx, val);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tokens.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, textController.text),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((newName) {
      if (newName != null && newName.trim().isNotEmpty) {
        ref.read(editorControllerProvider(widget.project).notifier).renameNode(nodeId, newName.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider(widget.project));
    final controller = ref.read(editorControllerProvider(widget.project).notifier);
    final page = state.project.getPage(state.activePageId);

    if (page == null) return const SizedBox.shrink();

    final tokens = FormaTheme.tokensOf(context);
    final isDark = tokens.isDark;

    // Filter root nodes based on search query
    final filteredRootIds = page.rootNodeIds.where((id) {
      if (_searchQuery.isEmpty) return true;
      final node = state.project.nodes[id];
      if (node == null) return false;
      return _matchesSearch(node, state.project);
    }).toList();

    Widget panel = Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          right: BorderSide(
            color: tokens.border,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title, Count badge, and Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: tokens.borderSubtle, width: 1.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.layers_rounded,
                      size: 14,
                      color: tokens.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LAYERS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: tokens.textMain,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: tokens.accent.withValues(alpha: isDark ? 0.20 : 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: tokens.accent.withValues(alpha: isDark ? 0.35 : 0.20),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        '${state.project.nodes.length}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: tokens.accent,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Search toggle
                    _buildHeaderIconButton(
                      icon: _isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded,
                      tooltip: _isSearchVisible ? 'Close Search' : 'Filter Layers',
                      isActive: _isSearchVisible,
                      tokens: tokens,
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchQuery = '';
                            _searchController.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 1),
                    // New Folder Button
                    _buildHeaderIconButton(
                      icon: Icons.create_new_folder_outlined,
                      tooltip: 'New Folder Group',
                      tokens: tokens,
                      onPressed: () {
                        controller.groupSelectedNodes(
                          folderName: state.selectedNodeIds.isNotEmpty
                              ? 'Folder (${state.selectedNodeIds.length} items)'
                              : 'New Folder',
                        );
                      },
                    ),
                    const SizedBox(width: 1),
                    // Add Layer / Node Popup Menu
                    _buildAddMenuButton(controller, state, tokens),
                    const SizedBox(width: 1),
                    // Delete Selected Button
                    _buildHeaderIconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete Selected Layer(s)',
                      iconColor: state.selectedNodeIds.isNotEmpty ? const Color(0xFFEF4444) : null,
                      tokens: tokens,
                      onPressed: state.selectedNodeIds.isNotEmpty
                          ? controller.deleteSelectedNodes
                          : null,
                    ),
                  ],
                ),
                // Search Input Field (when toggled on)
                if (_isSearchVisible) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: tokens.wellBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tokens.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Icon(Icons.search_rounded, size: 14, color: tokens.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: TextStyle(fontSize: 11, color: tokens.textMain),
                            decoration: InputDecoration(
                              hintText: 'Filter layer names...',
                              hintStyle: TextStyle(fontSize: 11, color: tokens.textMuted),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim().toLowerCase();
                              });
                            },
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.close_rounded, size: 14, color: tokens.textMuted),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Layer Tree Hierarchy View
          Expanded(
            child: page.rootNodeIds.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: tokens.accent.withValues(alpha: isDark ? 0.15 : 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.layers_clear_outlined,
                              size: 22,
                              color: tokens.accent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No layers on this canvas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tokens.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a shape tool below or press R to create your first element',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: tokens.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredRootIds.isEmpty
                    ? Center(
                        child: Text(
                          'No layers matching "$_searchQuery"',
                          style: TextStyle(fontSize: 11, color: tokens.textMuted),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        buildDefaultDragHandles: false,
                        itemCount: filteredRootIds.length,
                        onReorder: (oldIdx, newIdx) {
                          // Handle reorder in reverse visual index (top of list is highest z-index)
                          final oldNodeId = filteredRootIds[oldIdx];
                          final realOld = page.rootNodeIds.indexOf(oldNodeId);

                          int targetVisualIndex = newIdx > oldIdx ? newIdx - 1 : newIdx;
                          targetVisualIndex = targetVisualIndex.clamp(0, filteredRootIds.length - 1);
                          final targetNodeId = filteredRootIds[targetVisualIndex];
                          final realNew = page.rootNodeIds.indexOf(targetNodeId);

                          if (realOld != -1 && realNew != -1 && realOld != realNew) {
                            controller.reorderRootNodes(realOld, realNew);
                          }
                        },
                        itemBuilder: (context, index) {
                          final nodeId = filteredRootIds[index];
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
                              tokens: tokens,
                              isDark: isDark,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );

    if (tokens.isGlass && tokens.cardBlur > 0) {
      return ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: tokens.cardBlur, sigmaY: tokens.cardBlur),
          child: panel,
        ),
      );
    }

    return panel;
  }

  bool _matchesSearch(DesignNode node, ProjectModel project) {
    if (node.name.toLowerCase().contains(_searchQuery)) return true;
    for (final childId in node.childrenIds) {
      final child = project.nodes[childId];
      if (child != null && _matchesSearch(child, project)) return true;
    }
    return false;
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    Color? iconColor,
    bool isActive = false,
    required FormaThemeTokens tokens,
    required VoidCallback? onPressed,
  }) {
    final color = iconColor ?? (isActive ? tokens.accent : tokens.textMuted);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? tokens.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 14,
              color: onPressed == null ? tokens.textMuted.withValues(alpha: 0.3) : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddMenuButton(
    EditorController controller,
    dynamic state,
    FormaThemeTokens tokens,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add_box_outlined, size: 14, color: tokens.textMuted),
      tooltip: 'Insert Layer / Node',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      splashRadius: 12,
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      onSelected: (choice) => _insertNodeFromMenu(choice, controller, state),
      itemBuilder: (ctx) => [
        _buildPopupItem('rect', Icons.crop_square_rounded, 'Rectangle', const Color(0xFF3B82F6), tokens),
        _buildPopupItem('roundedRect', Icons.rectangle_rounded, 'Rounded Rect', const Color(0xFF6366F1), tokens),
        _buildPopupItem('ellipse', Icons.circle_outlined, 'Oval / Circle', const Color(0xFFEC4899), tokens),
        _buildPopupItem('triangle', Icons.change_history_rounded, 'Triangle', const Color(0xFFF97316), tokens),
        _buildPopupItem('polygon', Icons.hexagon_outlined, 'Polygon (5-corner)', const Color(0xFFEAB308), tokens),
        _buildPopupItem('star', Icons.star_border_rounded, 'Star', const Color(0xFFF59E0B), tokens),
        _buildPopupItem('text', Icons.title_rounded, 'Text Node', const Color(0xFF10B981), tokens),
        _buildPopupItem('pen', Icons.polyline_rounded, 'Vector Pen Path', const Color(0xFF06B6D4), tokens),
        _buildPopupItem('frame', Icons.crop_free_rounded, 'Frame / Artboard', const Color(0xFF8B5CF6), tokens),
        _buildPopupItem('group', Icons.folder_outlined, 'Folder Group', const Color(0xFFF59E0B), tokens),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(
    String value,
    IconData icon,
    String label,
    Color badgeColor,
    FormaThemeTokens tokens,
  ) {
    return PopupMenuItem<String>(
      value: value,
      height: 36,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: badgeColor),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tokens.textMain,
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
    required FormaThemeTokens tokens,
    required bool isDark,
  }) {
    final isSelected = state.selectedNodeIds.contains(node.id);
    final isFolder = node.type == NodeType.group ||
        node.type == NodeType.frame ||
        node.childrenIds.isNotEmpty;
    final isCollapsed = _collapsedFolderIds.contains(node.id);

    final badgeColor = _getNodeBadgeColor(node.type);
    final iconData = isFolder
        ? (isCollapsed ? Icons.folder_rounded : Icons.folder_open_rounded)
        : _getNodeIcon(node.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DragTarget to allow dropping any layer directly into this folder
        DragTarget<String>(
          onWillAcceptWithDetails: (details) => isFolder && details.data != node.id,
          onAcceptWithDetails: (details) {
            controller.moveNodeIntoFolder(nodeId: details.data, folderId: node.id);
          },
          builder: (context, candidateData, rejectedData) {
            final isTargeted = candidateData.isNotEmpty;

            return InkWell(
              onTap: () => controller.selectNode(node.id),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                padding: EdgeInsets.only(
                  left: 6.0 + (depth * 14.0),
                  right: 4.0,
                ),
                decoration: BoxDecoration(
                  // Active layer selection pill with subtle glow and 1px hairline border
                  color: isTargeted
                      ? tokens.accent.withValues(alpha: isDark ? 0.28 : 0.16)
                      : isSelected
                          ? tokens.accent.withValues(alpha: isDark ? 0.20 : 0.10)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTargeted
                        ? tokens.accent
                        : isSelected
                            ? tokens.accent.withValues(alpha: isDark ? 0.65 : 0.40)
                            : Colors.transparent,
                    width: isTargeted ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: tokens.accent.withValues(alpha: isDark ? 0.22 : 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Active selection vertical indicator bar
                    if (isSelected) ...[
                      Container(
                        width: 3.0,
                        height: 16,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: tokens.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 4),
                    ],

                    // Tree hierarchy connector guideline for child layers
                    if (depth > 0) ...[
                      Container(
                        width: 1.0,
                        height: 20,
                        margin: const EdgeInsets.only(right: 6),
                        color: tokens.borderSubtle,
                      ),
                    ],

                    // Expand / Collapse Chevron for Folders & Frames
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
                          child: AnimatedRotation(
                            turns: isCollapsed ? 0 : 0.25,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              Icons.arrow_right_rounded,
                              size: 16,
                              color: tokens.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ] else ...[
                      const SizedBox(width: 14),
                    ],

                    // Layer type icon badge with soft tinted background
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: isDark ? 0.35 : 0.20),
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          size: 12.5,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Layer Number Pill (Optional compact reference)
                    if (layerNumber != null && depth == 0) ...[
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'L$layerNumber',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: tokens.textMuted,
                          ),
                        ),
                      ),
                    ],

                    // Layer Name with high-clarity typography
                    Expanded(
                      child: Text(
                        node.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? tokens.textMain
                              : (node.isVisible
                                  ? tokens.textMain
                                  : tokens.textMuted.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),

                    // Inline Edit Name Icon
                    Tooltip(
                      message: 'Rename Layer',
                      child: InkWell(
                        onTap: () => _showRenameDialog(node.id, node.name),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: tokens.textMuted.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),

                    // Lock Toggle Button with micro-interaction
                    Tooltip(
                      message: node.isLocked ? 'Unlock Layer' : 'Lock Layer',
                      child: InkWell(
                        onTap: () => controller.toggleLock(node.id),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: node.isLocked
                                ? tokens.accent.withValues(alpha: 0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Icon(
                              node.isLocked
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              size: 13,
                              color: node.isLocked
                                  ? tokens.accent
                                  : tokens.textMuted.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),

                    // Visibility Toggle Button with eye icon
                    Tooltip(
                      message: node.isVisible ? 'Hide Layer' : 'Show Layer',
                      child: InkWell(
                        onTap: () => controller.toggleVisibility(node.id),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: !node.isVisible
                                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Icon(
                              node.isVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 13,
                              color: node.isVisible
                                  ? tokens.textMuted.withValues(alpha: 0.6)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),

                    // Draggable Handle with visual cue
                    if (reorderIndex != null)
                      Draggable<String>(
                        data: node.id,
                        feedback: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2430) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: tokens.accent, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: tokens.accent.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(iconData, size: 11, color: badgeColor),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  node.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: ReorderableDragStartListener(
                          index: reorderIndex,
                          child: Tooltip(
                            message: 'Drag to reorder',
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.drag_indicator_rounded,
                                size: 14,
                                color: tokens.textMuted.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        // Recursive tree rendering for folder & frame children
        if (!isCollapsed) ...[
          for (final childId in node.childrenIds) ...[
            if (state.project.nodes[childId] != null)
              _buildLayerItem(
                context: context,
                node: state.project.nodes[childId]!,
                depth: depth + 1,
                state: state,
                controller: controller,
                tokens: tokens,
                isDark: isDark,
              ),
          ],
        ],
      ],
    );
  }

  Color _getNodeBadgeColor(NodeType type) {
    switch (type) {
      case NodeType.frame:
        return const Color(0xFF8B5CF6); // Purple
      case NodeType.group:
        return const Color(0xFFF59E0B); // Amber
      case NodeType.rectangle:
        return const Color(0xFF3B82F6); // Blue
      case NodeType.roundedRectangle:
        return const Color(0xFF6366F1); // Indigo
      case NodeType.ellipse:
        return const Color(0xFFEC4899); // Pink
      case NodeType.line:
      case NodeType.arrow:
        return const Color(0xFF14B8A6); // Teal
      case NodeType.polygon:
        return const Color(0xFFF97316); // Orange
      case NodeType.star:
        return const Color(0xFFEAB308); // Yellow
      case NodeType.text:
        return const Color(0xFF10B981); // Emerald Green
      case NodeType.image:
        return const Color(0xFF7C3AED); // Violet
      case NodeType.vectorPath:
      case NodeType.freehandPath:
        return const Color(0xFF06B6D4); // Cyan
      case NodeType.componentInstance:
        return const Color(0xFFD946EF); // Fuchsia
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getNodeIcon(NodeType type) {
    switch (type) {
      case NodeType.frame:
        return Icons.crop_free_rounded;
      case NodeType.group:
        return Icons.folder_outlined;
      case NodeType.rectangle:
        return Icons.crop_square_rounded;
      case NodeType.roundedRectangle:
        return Icons.rectangle_rounded;
      case NodeType.ellipse:
        return Icons.circle_outlined;
      case NodeType.line:
        return Icons.horizontal_rule_rounded;
      case NodeType.arrow:
        return Icons.arrow_right_alt_rounded;
      case NodeType.polygon:
        return Icons.hexagon_outlined;
      case NodeType.star:
        return Icons.star_border_rounded;
      case NodeType.text:
        return Icons.title_rounded;
      case NodeType.image:
        return Icons.image_outlined;
      case NodeType.vectorPath:
        return Icons.polyline_rounded;
      case NodeType.freehandPath:
        return Icons.edit_outlined;
      case NodeType.componentInstance:
        return Icons.widgets_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
