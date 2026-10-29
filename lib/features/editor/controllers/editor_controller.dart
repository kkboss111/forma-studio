import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/project_model.dart';
import '../../../domain/models/page_model.dart';
import '../../../domain/models/node_model.dart';
import '../../../domain/models/node_types.dart';
import '../../../domain/models/paint_styles.dart';
import '../../../domain/models/text_data.dart';
import '../../../domain/models/comment_model.dart';
import '../../../domain/models/vector_data.dart';
import '../../../domain/models/animation_model.dart';
import '../../../domain/services/vector_path_service.dart';
import '../../../domain/services/node_render_service.dart';
import '../../../core/export/svg_importer.dart';
import '../../../core/history/command.dart';
import '../../../core/history/history_manager.dart';
import '../../../core/persistence/project_repository.dart';
import '../../../core/geometry/geometry_utils.dart';
import 'editor_state.dart';

final editorControllerProvider = StateNotifierProvider.autoDispose
    .family<EditorController, EditorState, ProjectModel>(
      (ref, initialProject) => EditorController(initialProject),
    );

class EditorController extends StateNotifier<EditorState> {
  final HistoryManager _history = HistoryManager();
  final ProjectRepository _repository = ProjectRepository();
  final Uuid _uuid = const Uuid();

  static List<DesignNode> globalClipboardNodes = [];

  EditorController(ProjectModel initialProject)
    : super(
        EditorState(
          project: initialProject,
          activePageId: initialProject.pages.isNotEmpty
              ? initialProject.pages.first.id
              : 'page-1',
        ),
      );

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  void setTool(EditorTool tool) {
    state = state.copyWith(activeTool: tool);
  }

  void setDragMode(DragMode mode, {ResizeHandleType? handle, Rect? marquee}) {
    state = state.copyWith(
      dragMode: mode,
      activeHandle: handle,
      clearHandle: handle == null,
      marqueeRect: marquee,
      clearMarquee: marquee == null,
    );
  }

  void setSnapGuides(List<SnapGuide> guides) {
    state = state.copyWith(activeSnapGuides: guides);
  }

  void selectNode(String id, {bool multiSelect = false}) {
    if (multiSelect) {
      final updated = Set<String>.from(state.selectedNodeIds);
      if (updated.contains(id)) {
        updated.remove(id);
      } else {
        updated.add(id);
      }
      state = state.copyWith(selectedNodeIds: updated);
    } else {
      state = state.copyWith(selectedNodeIds: {id});
    }
  }

  void selectNodes(Iterable<String> ids) {
    state = state.copyWith(selectedNodeIds: ids.toSet());
  }

  void clearSelection() {
    state = state.copyWith(selectedNodeIds: {});
  }

  void selectAll() {
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    state = state.copyWith(selectedNodeIds: page.rootNodeIds.toSet());
  }

  void setHovered(String? id) {
    state = state.copyWith(hoveredNodeId: id, clearHovered: id == null);
  }

  void updateLiveNodes(
    Map<String, DesignNode> nodes, {
    List<SnapGuide>? snapGuides,
  }) {
    state = state.copyWith(
      project: state.project.copyWith(nodes: nodes),
      activeSnapGuides: snapGuides,
    );
  }

  void updateSingleNodeLive(DesignNode node) {
    var nodeToStore = node;
    if (node.type == NodeType.text && node.textData != null) {
      final measured = NodeRenderService.measureText(node.textData!);
      nodeToStore = node.copyWith(
        width: math.max(node.width, measured.width + 8.0),
        height: math.max(node.height, measured.height + 4.0),
      );
    }
    final updated = Map<String, DesignNode>.from(state.project.nodes)
      ..[nodeToStore.id] = nodeToStore;
    state = state.copyWith(project: state.project.copyWith(nodes: updated));
  }

  void updatePages(List<PageModel> pages) {
    state = state.copyWith(project: state.project.copyWith(pages: pages));
    _repository.scheduleAutosave(state.project);
  }

  void setPageBackgroundColor(Color color) {
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    final updated = page.copyWith(backgroundColor: color);
    final updatedPages = state.project.pages
        .map((p) => p.id == page.id ? updated : p)
        .toList();
    state = state.copyWith(project: state.project.copyWith(pages: updatedPages));
    _repository.scheduleAutosave(state.project);
  }

  Future<void> saveNow() async {
    await _repository.saveProject(state.project);
  }

  void setPageShowGrid(bool val) {
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    final updated = page.copyWith(showGrid: val);
    updatePages(state.project.pages.map((p) => p.id == page.id ? updated : p).toList());
  }

  void setPageSnapToGrid(bool val) {
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    final updated = page.copyWith(snapToGrid: val);
    updatePages(state.project.pages.map((p) => p.id == page.id ? updated : p).toList());
  }

  // --- Transformations & Moving ---

  void moveNodes(
    Map<String, Offset> originalPositions,
    Map<String, Offset> newPositions,
  ) {
    final cmd = MoveNodesCommand(
      originalPositions: originalPositions,
      newPositions: newPositions,
    );
    final updatedProj = _history.executeCommand(cmd, state.project);
    state = state.copyWith(project: updatedProj);
    _repository.scheduleAutosave(updatedProj);
  }

  void nudgeSelection(Offset delta) {
    if (state.selectedNodeIds.isEmpty) return;
    final orig = <String, Offset>{};
    final next = <String, Offset>{};

    for (final id in state.selectedNodeIds) {
      final n = state.project.nodes[id];
      if (n != null && !n.isLocked) {
        orig[id] = Offset(n.x, n.y);
        next[id] = Offset(n.x + delta.dx, n.y + delta.dy);
      }
    }

    if (orig.isNotEmpty) {
      moveNodes(orig, next);
    }
  }

  // --- Node Creation ---

  /// Public getter to safely access current editor state from UI components.
  EditorState get currentState => state;

  String createNode({
    required NodeType type,
    required Rect rect,
    String? parentId,
    String? name,
    List<DesignFill>? fills,
    List<DesignStroke>? strokes,
    List<DesignEffect>? effects,
    CornerRadii? cornerRadii,
    TextNodeData? textData,
    int? polygonSides,
    int? starPoints,
  }) {
    final id = 'node-${_uuid.v4().substring(0, 8)}';
    final resolvedName =
        name ?? '${type.displayName} ${state.project.nodes.length + 1}';

    final defaultFills =
        fills ??
        (type == NodeType.text
            ? [const DesignFill.solid(Color(0xFF2B3445))]
            : type == NodeType.line || type == NodeType.arrow
            ? const []
            : [const DesignFill.solid(Color(0xFFE6ECF5))]);

    final defaultStrokes =
        strokes ??
        (type == NodeType.line || type == NodeType.arrow
            ? [const DesignStroke(color: Color(0xFF2B3445), width: 2.0)]
            : const []);

    final resolvedTextData =
        textData ?? (type == NodeType.text ? const TextNodeData() : null);

    double nodeWidth = math.max(10.0, rect.width);
    double nodeHeight = math.max(10.0, rect.height);
    if (type == NodeType.text && resolvedTextData != null) {
      final measured = NodeRenderService.measureText(resolvedTextData);
      nodeWidth = math.max(nodeWidth, measured.width + 8.0);
      nodeHeight = math.max(nodeHeight, measured.height + 4.0);
    }

    final newNode = DesignNode(
      id: id,
      type: type,
      name: resolvedName,
      parentId: parentId,
      x: rect.left,
      y: rect.top,
      width: nodeWidth,
      height: nodeHeight,
      fills: defaultFills,
      strokes: defaultStrokes,
      effects: effects ?? const [],
      cornerRadii:
          cornerRadii ??
          (type == NodeType.roundedRectangle
              ? const CornerRadii.all(16.0)
              : const CornerRadii()),
      textData: resolvedTextData,
      polygonSides: polygonSides ?? 5,
      starPoints: starPoints ?? 5,
    );

    final cmd = AddNodeCommand(pageId: state.activePageId, node: newNode);
    final updatedProj = _history.executeCommand(cmd, state.project);

    state = state.copyWith(
      project: updatedProj,
      selectedNodeIds: {id},
      activeTool: EditorTool.select,
    );

    _repository.scheduleAutosave(updatedProj);
    return id;
  }

  String insertImageNode({
    required String base64Image,
    double width = 300,
    double height = 200,
    String? name,
  }) {
    final id = 'node-${DateTime.now().millisecondsSinceEpoch}';
    final centerOffset = state.panOffset;
    final rect = Rect.fromLTWH(
      (-centerOffset.dx + 160) / state.zoom,
      (-centerOffset.dy + 160) / state.zoom,
      width,
      height,
    );

    final newNode = DesignNode(
      id: id,
      type: NodeType.image,
      name: name ?? 'Image ${state.project.nodes.length + 1}',
      x: math.max(0.0, rect.left),
      y: math.max(0.0, rect.top),
      width: width,
      height: height,
      imagePath: base64Image,
      fills: [
        DesignFill.image(imageBase64: base64Image),
      ],
      strokes: const [],
    );

    final cmd = AddNodeCommand(pageId: state.activePageId, node: newNode);
    final updatedProj = _history.executeCommand(cmd, state.project);

    state = state.copyWith(
      project: updatedProj,
      selectedNodeIds: {id},
      activeTool: EditorTool.select,
    );

    _repository.scheduleAutosave(updatedProj);
    return id;
  }

  void setImageFillForSelected({required String base64Image}) {
    if (state.selectedNodeIds.isEmpty) return;
    final selectedId = state.primarySelectedId;
    if (selectedId == null) return;
    final node = state.project.nodes[selectedId];
    if (node == null) return;

    final updatedFills = [
      DesignFill.image(imageBase64: base64Image),
    ];
    updateNode(node.copyWith(fills: updatedFills));
  }

  void addDropShadowToSelected() {
    for (final id in state.selectedNodeIds) {
      final node = state.project.nodes[id];
      if (node != null) {
        final eff = const DesignEffect(
          type: DesignEffectType.dropShadow,
          color: Color(0x33000000),
          offsetY: 6,
          blurRadius: 16,
          spreadRadius: 2,
        );
        updateNode(node.copyWith(effects: [...node.effects, eff]));
      }
    }
  }

  void addOuterGlowToSelected() {
    for (final id in state.selectedNodeIds) {
      final node = state.project.nodes[id];
      if (node != null) {
        final eff = const DesignEffect(
          type: DesignEffectType.outerGlow,
          color: Color(0x8800FFF0),
          blurRadius: 20,
          spreadRadius: 4,
        );
        updateNode(node.copyWith(effects: [...node.effects, eff]));
      }
    }
  }

  void addBlurToSelected() {
    for (final id in state.selectedNodeIds) {
      final node = state.project.nodes[id];
      if (node != null) {
        final eff = const DesignEffect(
          type: DesignEffectType.blur,
          blurRadius: 14,
        );
        updateNode(node.copyWith(effects: [...node.effects, eff]));
      }
    }
  }

  void addBackdropBlurToSelected() {
    for (final id in state.selectedNodeIds) {
      final node = state.project.nodes[id];
      if (node != null) {
        final eff = const DesignEffect(
          type: DesignEffectType.backgroundBlur,
          blurRadius: 20,
        );
        updateNode(node.copyWith(effects: [...node.effects, eff]));
      }
    }
  }

  // --- Deletion, Duplicate, Grouping ---

  void deleteSelectedNodes() {
    if (state.selectedNodeIds.isEmpty) return;

    final toDelete = state.selectedNodeIds
        .map((id) => state.project.nodes[id])
        .whereType<DesignNode>()
        .where((n) => !n.isLocked)
        .toList();

    if (toDelete.isEmpty) return;

    final cmd = DeleteNodesCommand(
      pageId: state.activePageId,
      nodesToDelete: toDelete,
    );
    final updatedProj = _history.executeCommand(cmd, state.project);

    state = state.copyWith(project: updatedProj, selectedNodeIds: {});
    _repository.scheduleAutosave(updatedProj);
  }

  void duplicateSelectedNodes() {
    if (state.selectedNodeIds.isEmpty) return;
    final newSelected = <String>{};
    ProjectModel current = state.project;

    for (final id in state.selectedNodeIds) {
      final original = state.project.nodes[id];
      if (original != null) {
        final newId = 'node-${_uuid.v4().substring(0, 8)}';
        final clone = original.copyWith(
          id: newId,
          name: '${original.name} Copy',
          x: original.x + 20,
          y: original.y + 20,
        );

        final cmd = AddNodeCommand(pageId: state.activePageId, node: clone);
        current = _history.executeCommand(cmd, current);
        newSelected.add(newId);
      }
    }

    state = state.copyWith(project: current, selectedNodeIds: newSelected);
    _repository.scheduleAutosave(current);
  }

  void groupSelectedNodes() {
    if (state.selectedNodeIds.length < 2) return;

    final selected = state.selectedNodeIds
        .map((id) => state.project.nodes[id])
        .whereType<DesignNode>()
        .toList();

    final bounds = GeometryUtils.getCollectiveBoundingBox(selected);
    if (bounds == null) return;

    final groupId = 'group-${_uuid.v4().substring(0, 8)}';
    final groupNode = DesignNode(
      id: groupId,
      type: NodeType.group,
      name: 'Group ${state.project.nodes.length + 1}',
      x: bounds.left,
      y: bounds.top,
      width: bounds.width,
      height: bounds.height,
      childrenIds: selected.map((n) => n.id).toList(),
    );

    // Update children parentId and local offset
    final updatedNodes = Map<String, DesignNode>.from(state.project.nodes);
    updatedNodes[groupId] = groupNode;

    for (final child in selected) {
      updatedNodes[child.id] = child.copyWith(parentId: groupId);
    }

    final page = state.project.getPage(state.activePageId);
    if (page == null) return;

    final updatedRoots =
        page.rootNodeIds
            .where((id) => !state.selectedNodeIds.contains(id))
            .toList()
          ..add(groupId);

    final updatedPages = state.project.pages.map((p) {
      if (p.id == state.activePageId) {
        return p.copyWith(rootNodeIds: updatedRoots);
      }
      return p;
    }).toList();

    final updatedProj = state.project.copyWith(
      nodes: updatedNodes,
      pages: updatedPages,
    );
    state = state.copyWith(project: updatedProj, selectedNodeIds: {groupId});
    _repository.scheduleAutosave(updatedProj);
  }

  void ungroupSelectedNodes() {
    if (state.selectedNodeIds.isEmpty) return;

    final updatedNodes = Map<String, DesignNode>.from(state.project.nodes);
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    final updatedRoots = List<String>.from(page.rootNodeIds);
    final newSelected = <String>{};

    for (final id in state.selectedNodeIds) {
      final node = updatedNodes[id];
      if (node != null && node.type == NodeType.group) {
        updatedRoots.remove(id);
        for (final childId in node.childrenIds) {
          final child = updatedNodes[childId];
          if (child != null) {
            updatedNodes[childId] = child.copyWith(clearParent: true);
            updatedRoots.add(childId);
            newSelected.add(childId);
          }
        }
        updatedNodes.remove(id);
      }
    }

    final updatedPages = state.project.pages.map((p) {
      if (p.id == state.activePageId) {
        return p.copyWith(rootNodeIds: updatedRoots);
      }
      return p;
    }).toList();

    final updatedProj = state.project.copyWith(
      nodes: updatedNodes,
      pages: updatedPages,
    );
    state = state.copyWith(project: updatedProj, selectedNodeIds: newSelected);
    _repository.scheduleAutosave(updatedProj);
  }

  // --- Layer Stacking Order ---

  void bringForward() {
    if (state.selectedNodeIds.isEmpty) return;
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    final roots = List<String>.from(page.rootNodeIds);
    for (final id in state.selectedNodeIds) {
      final idx = roots.indexOf(id);
      if (idx >= 0 && idx < roots.length - 1) {
        roots.removeAt(idx);
        roots.insert(idx + 1, id);
      }
    }
    final updatedPages = state.project.pages
        .map((p) => p.id == page.id ? p.copyWith(rootNodeIds: roots) : p)
        .toList();
    updatePages(updatedPages);
  }

  void bringToFront() {
    if (state.selectedNodeIds.isEmpty) return;
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    final roots = List<String>.from(page.rootNodeIds);
    for (final id in state.selectedNodeIds) {
      if (roots.remove(id)) {
        roots.add(id);
      }
    }
    final updatedPages = state.project.pages
        .map((p) => p.id == page.id ? p.copyWith(rootNodeIds: roots) : p)
        .toList();
    updatePages(updatedPages);
  }

  void sendBackward() {
    if (state.selectedNodeIds.isEmpty) return;
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    final roots = List<String>.from(page.rootNodeIds);
    for (final id in state.selectedNodeIds) {
      final idx = roots.indexOf(id);
      if (idx > 0) {
        roots.removeAt(idx);
        roots.insert(idx - 1, id);
      }
    }
    final updatedPages = state.project.pages
        .map((p) => p.id == page.id ? p.copyWith(rootNodeIds: roots) : p)
        .toList();
    updatePages(updatedPages);
  }

  void sendToBack() {
    if (state.selectedNodeIds.isEmpty) return;
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    final roots = List<String>.from(page.rootNodeIds);
    for (final id in state.selectedNodeIds.toList().reversed) {
      if (roots.remove(id)) {
        roots.insert(0, id);
      }
    }
    final updatedPages = state.project.pages
        .map((p) => p.id == page.id ? p.copyWith(rootNodeIds: roots) : p)
        .toList();
    updatePages(updatedPages);
  }

  void reorderRootNodes(int oldIndex, int newIndex) {
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;
    final roots = List<String>.from(page.rootNodeIds);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex >= 0 && oldIndex < roots.length && newIndex >= 0 && newIndex <= roots.length) {
      final item = roots.removeAt(oldIndex);
      roots.insert(newIndex, item);
      final updatedPages = state.project.pages
          .map((p) => p.id == page.id ? p.copyWith(rootNodeIds: roots) : p)
          .toList();
      updatePages(updatedPages);
    }
  }

  // --- Alignment & Distribution ---

  void alignSelection(String alignment) {
    if (state.selectedNodeIds.isEmpty) return;
    final selected = state.selectedNodeIds
        .map((id) => state.project.nodes[id])
        .whereType<DesignNode>()
        .toList();
    if (selected.isEmpty) return;

    Rect? bounds;
    if (selected.length == 1) {
      final node = selected.first;
      if (node.parentId != null && state.project.nodes.containsKey(node.parentId)) {
        final parent = state.project.nodes[node.parentId]!;
        bounds = Rect.fromLTWH(0, 0, parent.width, parent.height);
      } else {
        // Page canvas bounds
        bounds = const Rect.fromLTWH(0, 0, 1200, 800);
      }
    } else {
      bounds = GeometryUtils.getCollectiveBoundingBox(selected);
    }
    if (bounds == null) return;

    final orig = <String, Offset>{};
    final next = <String, Offset>{};

    for (final node in selected) {
      orig[node.id] = Offset(node.x, node.y);
      double nx = node.x;
      double ny = node.y;

      switch (alignment) {
        case 'left':
          nx = bounds.left;
          break;
        case 'centerHorizontal':
          nx = bounds.center.dx - node.width / 2;
          break;
        case 'right':
          nx = bounds.right - node.width;
          break;
        case 'top':
          ny = bounds.top;
          break;
        case 'centerVertical':
          ny = bounds.center.dy - node.height / 2;
          break;
        case 'bottom':
          ny = bounds.bottom - node.height;
          break;
      }
      next[node.id] = Offset(nx, ny);
    }

    moveNodes(orig, next);
  }

  void distributeSelection(String axis) {
    if (state.selectedNodeIds.length < 3) return;
    final selected = state.selectedNodeIds
        .map((id) => state.project.nodes[id])
        .whereType<DesignNode>()
        .toList();

    final orig = <String, Offset>{};
    final next = <String, Offset>{};

    if (axis == 'horizontal') {
      selected.sort((a, b) => a.x.compareTo(b.x));
      final totalWidth = selected.map((n) => n.width).reduce((a, b) => a + b);
      final span = (selected.last.x + selected.last.width) - selected.first.x;
      final gap = (span - totalWidth) / (selected.length - 1);

      double curX = selected.first.x;
      for (final node in selected) {
        orig[node.id] = Offset(node.x, node.y);
        next[node.id] = Offset(curX, node.y);
        curX += node.width + gap;
      }
    } else {
      selected.sort((a, b) => a.y.compareTo(b.y));
      final totalHeight = selected.map((n) => n.height).reduce((a, b) => a + b);
      final span = (selected.last.y + selected.last.height) - selected.first.y;
      final gap = (span - totalHeight) / (selected.length - 1);

      double curY = selected.first.y;
      for (final node in selected) {
        orig[node.id] = Offset(node.x, node.y);
        next[node.id] = Offset(node.x, curY);
        curY += node.height + gap;
      }
    }

    moveNodes(orig, next);
  }

  // --- Property Updates ---

  void updateNode(DesignNode updated) {
    final original = state.project.nodes[updated.id];
    if (original == null) return;

    var nodeToSave = updated;
    if (updated.type == NodeType.text && updated.textData != null) {
      final measured = NodeRenderService.measureText(updated.textData!);
      nodeToSave = updated.copyWith(
        width: math.max(updated.width, measured.width + 8.0),
        height: math.max(updated.height, measured.height + 4.0),
      );
    }

    final cmd = UpdateNodeCommand(previousNode: original, updatedNode: nodeToSave);
    final updatedProj = _history.executeCommand(cmd, state.project);
    state = state.copyWith(project: updatedProj);
    _repository.scheduleAutosave(updatedProj);
  }

  void updateSelectedProperties({
    List<DesignFill>? fills,
    List<DesignStroke>? strokes,
    List<DesignEffect>? effects,
    CornerRadii? cornerRadii,
    double? opacity,
    TextNodeData? textData,
    double? rotation,
  }) {
    if (state.selectedNodeIds.isEmpty) return;
    final updatedNodes = Map<String, DesignNode>.from(state.project.nodes);

    for (final id in state.selectedNodeIds) {
      final node = updatedNodes[id];
      if (node != null) {
        final newTextData = textData ?? node.textData;
        double newW = node.width;
        double newH = node.height;
        if (node.type == NodeType.text && newTextData != null) {
          final measured = NodeRenderService.measureText(newTextData);
          newW = math.max(node.width, measured.width + 8.0);
          newH = math.max(node.height, measured.height + 4.0);
        }

        updatedNodes[id] = node.copyWith(
          fills: fills ?? node.fills,
          strokes: strokes ?? node.strokes,
          effects: effects ?? node.effects,
          cornerRadii: cornerRadii ?? node.cornerRadii,
          opacity: opacity ?? node.opacity,
          textData: newTextData,
          rotation: rotation ?? node.rotation,
          width: newW,
          height: newH,
        );
      }
    }

    final updatedProj = state.project.copyWith(nodes: updatedNodes);
    state = state.copyWith(project: updatedProj);
    _repository.scheduleAutosave(updatedProj);
  }

  void toggleLock(String id) {
    final node = state.project.nodes[id];
    if (node != null) {
      updateNode(node.copyWith(isLocked: !node.isLocked));
    }
  }

  void toggleVisibility(String id) {
    final node = state.project.nodes[id];
    if (node != null) {
      updateNode(node.copyWith(isVisible: !node.isVisible));
    }
  }

  void renameNode(String id, String newName) {
    final node = state.project.nodes[id];
    if (node != null && newName.trim().isNotEmpty) {
      updateNode(node.copyWith(name: newName.trim()));
    }
  }

  // --- Pages Management ---

  void addPage(String name) {
    final newId = 'page-${_uuid.v4().substring(0, 6)}';
    final newPage = PageModel(id: newId, name: name);
    final updatedPages = [...state.project.pages, newPage];
    final updatedProj = state.project.copyWith(pages: updatedPages);

    state = state.copyWith(
      project: updatedProj,
      activePageId: newId,
      selectedNodeIds: {},
    );
    _repository.scheduleAutosave(updatedProj);
  }

  void switchPage(String pageId) {
    if (state.project.getPage(pageId) != null) {
      state = state.copyWith(activePageId: pageId, selectedNodeIds: {});
    }
  }

  void renamePage(String pageId, String newName) {
    final updatedPages = state.project.pages.map((p) {
      if (p.id == pageId) return p.copyWith(name: newName);
      return p;
    }).toList();
    final updatedProj = state.project.copyWith(pages: updatedPages);
    state = state.copyWith(project: updatedProj);
    _repository.scheduleAutosave(updatedProj);
  }

  void deletePage(String pageId) {
    if (state.project.pages.length <= 1) return; // Keep at least 1 page
    final updatedPages = state.project.pages
        .where((p) => p.id != pageId)
        .toList();
    final nextActive = updatedPages.first.id;
    final updatedProj = state.project.copyWith(pages: updatedPages);

    state = state.copyWith(
      project: updatedProj,
      activePageId: nextActive,
      selectedNodeIds: {},
    );
    _repository.scheduleAutosave(updatedProj);
  }

  // --- Viewport, Zoom, Pan ---

  void setPanOffset(Offset offset) {
    state = state.copyWith(panOffset: offset);
  }

  void panDelta(Offset delta) {
    state = state.copyWith(panOffset: state.panOffset + delta);
  }

  void setZoom(double zoom, {bool extendedLimit = false}) {
    final minZ = extendedLimit ? 0.01 : 0.1;
    final maxZ = extendedLimit ? 50.0 : 8.0;
    final clamped = zoom.clamp(minZ, maxZ);
    state = state.copyWith(zoom: clamped);
  }

  /// Zooms in or out while preserving the document point under [screenFocalPoint].
  void zoomAroundPoint(double newZoom, Offset screenFocalPoint, {bool extendedLimit = false}) {
    final oldZoom = state.zoom;
    final minZ = extendedLimit ? 0.01 : 0.1;
    final maxZ = extendedLimit ? 50.0 : 8.0;
    final clamped = newZoom.clamp(minZ, maxZ);
    if ((oldZoom - clamped).abs() < 0.0001) return;

    final docFocal = (screenFocalPoint - state.panOffset) / oldZoom;
    final newPan = screenFocalPoint - (docFocal * clamped);

    state = state.copyWith(zoom: clamped, panOffset: newPan);
  }

  void zoomIn([Offset? screenCenter]) {
    if (screenCenter != null) {
      zoomAroundPoint(state.zoom * 1.25, screenCenter);
    } else {
      setZoom(state.zoom * 1.25);
    }
  }

  void zoomOut([Offset? screenCenter]) {
    if (screenCenter != null) {
      zoomAroundPoint(state.zoom / 1.25, screenCenter);
    } else {
      setZoom(state.zoom / 1.25);
    }
  }

  void zoom100([Offset? screenCenter]) {
    if (screenCenter != null) {
      zoomAroundPoint(1.0, screenCenter);
    } else {
      setZoom(1.0);
    }
  }

  void flipHorizontalSelected() {
    if (state.selectedNodeIds.isEmpty) return;
    for (final id in state.selectedNodeIds) {
      final node = state.project.nodes[id];
      if (node != null) {
        final updatedRotation = (180.0 - node.rotation) % 360.0;
        updateSelectedProperties(rotation: updatedRotation);
      }
    }
  }

  void flipVerticalSelected() {
    if (state.selectedNodeIds.isEmpty) return;
    for (final id in state.selectedNodeIds) {
      final node = state.project.nodes[id];
      if (node != null) {
        final updatedRotation = (360.0 - node.rotation) % 360.0;
        updateSelectedProperties(rotation: updatedRotation);
      }
    }
  }

  void zoomToFit() {
    final page = state.project.getPage(state.activePageId);
    if (page == null || page.rootNodeIds.isEmpty) {
      state = state.copyWith(zoom: 1.0, panOffset: const Offset(60, 60));
      return;
    }

    final rootNodes = page.rootNodeIds
        .map((id) => state.project.nodes[id])
        .whereType<DesignNode>();
    final bounds = GeometryUtils.getCollectiveBoundingBox(rootNodes);
    if (bounds != null) {
      state = state.copyWith(
        zoom: 0.8,
        panOffset: Offset(60 - bounds.left * 0.8, 60 - bounds.top * 0.8),
      );
    }
  }

  // --- Undo / Redo ---

  void undo() {
    if (_history.canUndo) {
      final updatedProj = _history.undo(state.project);
      state = state.copyWith(project: updatedProj);
      _repository.scheduleAutosave(updatedProj);
    }
  }

  void redo() {
    if (_history.canRedo) {
      final updatedProj = _history.redo(state.project);
      state = state.copyWith(project: updatedProj);
      _repository.scheduleAutosave(updatedProj);
    }
  }

  // --- Clipboard ---

  void copySelection() async {
    final nodes = state.selectedNodeIds
        .map((id) => state.project.nodes[id])
        .whereType<DesignNode>()
        .toList();
    if (nodes.isEmpty) return;
    globalClipboardNodes = List<DesignNode>.from(nodes);
    try {
      final jsonPayload = jsonEncode({
        'forma_type': 'nodes',
        'data': nodes.map((n) => n.toJson()).toList(),
      });
      await Clipboard.setData(ClipboardData(text: jsonPayload));
    } catch (_) {}
  }

  void cutSelection() {
    copySelection();
    deleteSelectedNodes();
  }

  void paste() async {
    List<DesignNode> toPaste = List<DesignNode>.from(globalClipboardNodes);

    if (toPaste.isEmpty) {
      try {
        final clipData = await Clipboard.getData(Clipboard.kTextPlain);
        if (clipData?.text != null && clipData!.text!.contains('forma_type')) {
          final decoded = jsonDecode(clipData.text!) as Map<String, dynamic>;
          if (decoded['forma_type'] == 'nodes') {
            final rawList = decoded['data'] as List;
            toPaste = rawList
                .map((j) => DesignNode.fromJson(j as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (_) {}
    }

    if (toPaste.isEmpty) return;
    final newSelected = <String>{};
    ProjectModel current = state.project;

    for (final original in toPaste) {
      final newId = 'node-${_uuid.v4().substring(0, 8)}';
      final clone = original.copyWith(
        id: newId,
        name: '${original.name} Copy',
        x: original.x + 30,
        y: original.y + 30,
      );

      final cmd = AddNodeCommand(pageId: state.activePageId, node: clone);
      current = _history.executeCommand(cmd, current);
      newSelected.add(newId);
    }

    state = state.copyWith(project: current, selectedNodeIds: newSelected);
    _repository.scheduleAutosave(current);
  }

  // --- Inspection & Prototype Modes ---

  void toggleDevInspectMode() {
    state = state.copyWith(isDevInspectMode: !state.isDevInspectMode);
  }

  void togglePrototypePlay() {
    state = state.copyWith(isPlayingPrototype: !state.isPlayingPrototype);
  }

  // --- Comments ---

  void addComment(Offset position, String author, String message) {
    final comment = DesignComment(
      id: 'comment-${_uuid.v4().substring(0, 8)}',
      pageId: state.activePageId,
      x: position.dx,
      y: position.dy,
      author: author,
      message: message,
      timestamp: DateTime.now(),
    );

    final updatedComments = [...state.project.comments, comment];
    final updatedProj = state.project.copyWith(comments: updatedComments);
    state = state.copyWith(project: updatedProj);
    _repository.scheduleAutosave(updatedProj);
  }

  void resolveComment(String commentId) {
    final updatedComments = state.project.comments.map((c) {
      if (c.id == commentId) return c.copyWith(isResolved: true);
      return c;
    }).toList();
    final updatedProj = state.project.copyWith(comments: updatedComments);
    state = state.copyWith(project: updatedProj);
    _repository.scheduleAutosave(updatedProj);
  }

  // --- Manual Save ---

  Future<void> saveProject() async {
    state = state.copyWith(isAutosaving: true);
    await _repository.saveProject(state.project);
    state = state.copyWith(
      isAutosaving: false,
      statusMessage: 'Project saved locally',
    );
  }

  // --- Real Vector Path Editing Engine ---

  String startNewVectorDraft(Offset docPos) {
    final page = state.project.getPage(state.activePageId);
    bool hasDrawnLayer = false;
    if (page != null) {
      for (final id in page.rootNodeIds) {
        final n = state.project.nodes[id];
        if (n != null && n.name.contains('Drawn Layer')) {
          hasDrawnLayer = true;
          break;
        }
      }
    }

    final nodeId = 'vec_${DateTime.now().millisecondsSinceEpoch}';
    const initialAnchor = VectorAnchor(
      point: Offset.zero,
      isSmooth: true,
      handleIn: Offset(-24, 0),
      handleOut: Offset(24, 0),
    );
    final newNode = DesignNode(
      id: nodeId,
      name: hasDrawnLayer ? 'Drawn Layer (Stroke ${state.project.nodes.length + 1})' : 'Drawn Layer',
      type: NodeType.vectorPath,
      x: docPos.dx,
      y: docPos.dy,
      width: 1.0,
      height: 1.0,
      vectorData: const VectorPathData(
        anchors: [initialAnchor],
        isClosed: false,
      ),
      strokes: const [
        DesignStroke(
          color: Color(0xFF2563EB),
          width: 3.0,
          cap: StrokeCap.round,
          join: StrokeJoin.round,
        ),
      ],
      fills: const [],
    );

    final cmd = AddNodeCommand(pageId: state.activePageId, node: newNode);
    final updatedProj = _history.executeCommand(cmd, state.project);

    state = state.copyWith(
      project: updatedProj,
      selectedNodeIds: {nodeId},
      editingVectorNodeId: nodeId,
      selectedAnchorIndex: 0,
      selectedHandleTarget: VectorHandleTarget.handleOut,
    );
    _repository.scheduleAutosave(updatedProj);
    return nodeId;
  }

  void closeVectorPath() {
    final nodeId = state.editingVectorNodeId;
    if (nodeId == null) return;
    final node = state.project.nodes[nodeId];
    if (node == null || node.vectorData == null) return;

    final updatedData = node.vectorData!.copyWith(isClosed: true);
    final updated = node.copyWith(vectorData: updatedData);
    final updatedNodes = Map<String, DesignNode>.from(state.project.nodes);
    updatedNodes[nodeId] = updated;

    state = state.copyWith(
      project: state.project.copyWith(nodes: updatedNodes),
      clearEditingVector: true,
      clearAnchorIndex: true,
      clearHandleTarget: true,
      activeTool: EditorTool.select,
    );
    _repository.scheduleAutosave(state.project);
  }

  void toggleVectorClosed() {
    closeVectorPath();
  }

  void renameProject(String newName) {
    if (newName.trim().isEmpty) return;
    final updated = state.project.copyWith(
      name: newName.trim(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(project: updated);
    _repository.saveProject(updated);
  }

  void enterVectorEditMode(String nodeId) {
    final node = state.project.nodes[nodeId];
    if (node == null) return;

    if (node.vectorData == null || node.vectorData!.anchors.isEmpty) {
      final List<VectorAnchor> defaultAnchors = [
        const VectorAnchor(point: Offset.zero),
        VectorAnchor(point: Offset(node.width, 0)),
        VectorAnchor(point: Offset(node.width, node.height)),
        VectorAnchor(point: Offset(0, node.height)),
      ];
      final convertedNode = node.copyWith(
        type: NodeType.vectorPath,
        vectorData: VectorPathData(anchors: defaultAnchors, isClosed: true),
      );
      final updatedNodes = Map<String, DesignNode>.from(state.project.nodes);
      updatedNodes[nodeId] = convertedNode;
      state = state.copyWith(
        project: state.project.copyWith(nodes: updatedNodes),
        editingVectorNodeId: nodeId,
        selectedAnchorIndex: 0,
        selectedNodeIds: {nodeId},
      );
    } else {
      state = state.copyWith(
        editingVectorNodeId: nodeId,
        selectedAnchorIndex: 0,
        selectedNodeIds: {nodeId},
      );
    }
  }

  void exitVectorEditMode() {
    state = state.copyWith(
      clearEditingVector: true,
      clearAnchorIndex: true,
      clearHandleTarget: true,
      activeTool: state.activeTool == EditorTool.vectorPen ? EditorTool.select : state.activeTool,
    );
  }

  void selectAnchor(int index) {
    state = state.copyWith(selectedAnchorIndex: index);
  }

  void updateVectorAnchor(int index, Offset newPoint) {
    final nodeId = state.editingVectorNodeId;
    if (nodeId == null) return;
    final node = state.project.nodes[nodeId];
    if (node == null || node.vectorData == null) return;

    final updatedPath = VectorPathService.updateAnchorPoint(
      pathData: node.vectorData!,
      index: index,
      newPoint: newPoint,
    );

    final updatedNode = node.copyWith(vectorData: updatedPath);
    final updatedMap = Map<String, DesignNode>.from(state.project.nodes);
    updatedMap[nodeId] = updatedNode;

    state = state.copyWith(project: state.project.copyWith(nodes: updatedMap));
    _repository.scheduleAutosave(state.project);
  }

  void updateVectorHandle(int index, VectorHandleTarget target, Offset handlePos) {
    final nodeId = state.editingVectorNodeId;
    if (nodeId == null) return;
    final node = state.project.nodes[nodeId];
    if (node == null || node.vectorData == null) return;

    VectorPathData updatedPath;
    if (target == VectorHandleTarget.handleIn) {
      updatedPath = VectorPathService.updateHandleIn(
        pathData: node.vectorData!,
        index: index,
        newHandleIn: handlePos,
      );
    } else if (target == VectorHandleTarget.handleOut) {
      updatedPath = VectorPathService.updateHandleOut(
        pathData: node.vectorData!,
        index: index,
        newHandleOut: handlePos,
      );
    } else {
      return;
    }

    final updatedNode = node.copyWith(vectorData: updatedPath);
    final updatedMap = Map<String, DesignNode>.from(state.project.nodes);
    updatedMap[nodeId] = updatedNode;

    state = state.copyWith(project: state.project.copyWith(nodes: updatedMap));
    _repository.scheduleAutosave(state.project);
  }

  void toggleVectorAnchorSmooth(int index) {
    final nodeId = state.editingVectorNodeId;
    if (nodeId == null) return;
    final node = state.project.nodes[nodeId];
    if (node == null || node.vectorData == null) return;

    final updatedPath = VectorPathService.toggleAnchorSmoothness(
      pathData: node.vectorData!,
      index: index,
    );

    final updatedNode = node.copyWith(vectorData: updatedPath);
    final updatedMap = Map<String, DesignNode>.from(state.project.nodes);
    updatedMap[nodeId] = updatedNode;

    state = state.copyWith(project: state.project.copyWith(nodes: updatedMap));
    _repository.scheduleAutosave(state.project);
  }

  void addVectorAnchor(Offset point) {
    final nodeId = state.editingVectorNodeId;
    if (nodeId == null) return;
    final node = state.project.nodes[nodeId];
    if (node == null || node.vectorData == null) return;

    final updatedPath = VectorPathService.addAnchor(node.vectorData!, point);
    final updatedNode = node.copyWith(vectorData: updatedPath);
    final updatedMap = Map<String, DesignNode>.from(state.project.nodes);
    updatedMap[nodeId] = updatedNode;

    state = state.copyWith(
      project: state.project.copyWith(nodes: updatedMap),
      selectedAnchorIndex: updatedPath.anchors.length - 1,
    );
    _repository.scheduleAutosave(state.project);
  }

  void deleteSelectedVectorAnchor() {
    final nodeId = state.editingVectorNodeId;
    final idx = state.selectedAnchorIndex;
    if (nodeId == null || idx == null) return;
    final node = state.project.nodes[nodeId];
    if (node == null || node.vectorData == null) return;

    final updatedPath = VectorPathService.deleteAnchor(node.vectorData!, idx);
    final updatedNode = node.copyWith(vectorData: updatedPath);
    final updatedMap = Map<String, DesignNode>.from(state.project.nodes);
    updatedMap[nodeId] = updatedNode;

    state = state.copyWith(
      project: state.project.copyWith(nodes: updatedMap),
      selectedAnchorIndex: (idx - 1).clamp(0, updatedPath.anchors.length - 1),
    );
    _repository.scheduleAutosave(state.project);
  }

  // --- Animation & Timeline System ---

  Timer? _animTimer;

  void toggleTimelinePanel() {
    state = state.copyWith(showTimelinePanel: !state.showTimelinePanel);
  }

  void togglePlayAnimation() {
    if (state.isPlayingTimeline) {
      _animTimer?.cancel();
      state = state.copyWith(isPlayingTimeline: false);
    } else {
      state = state.copyWith(isPlayingTimeline: true);
      final intervalMs = (1000 / state.timeline.fps).round();
      _animTimer?.cancel();
      _animTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
        if (!state.isPlayingTimeline) {
          timer.cancel();
          return;
        }

        var nextMs = state.currentTimelineMs + intervalMs;
        if (nextMs >= state.timeline.durationMs) {
          if (state.timeline.isLooping) {
            nextMs = 0;
          } else {
            nextMs = state.timeline.durationMs;
            timer.cancel();
            state = state.copyWith(isPlayingTimeline: false);
          }
        }
        setTimelineScrub(nextMs);
      });
    }
  }

  void setTimelineScrub(double timeMs) {
    final updatedNodes = Map<String, DesignNode>.from(state.project.nodes);
    bool changed = false;

    for (final track in state.timeline.tracks) {
      final node = updatedNodes[track.nodeId];
      if (node == null) continue;

      double defaultVal;
      switch (track.property) {
        case AnimProperty.x:
          defaultVal = node.x;
          break;
        case AnimProperty.y:
          defaultVal = node.y;
          break;
        case AnimProperty.width:
          defaultVal = node.width;
          break;
        case AnimProperty.height:
          defaultVal = node.height;
          break;
        case AnimProperty.rotation:
          defaultVal = node.rotation;
          break;
        case AnimProperty.opacity:
          defaultVal = node.opacity;
          break;
        case AnimProperty.scaleX:
        case AnimProperty.scaleY:
          defaultVal = 1.0;
          break;
        case AnimProperty.pivotX:
          defaultVal = node.width / 2;
          break;
        case AnimProperty.pivotY:
          defaultVal = node.height / 2;
          break;
        case AnimProperty.orbitAngle:
          defaultVal = 0.0;
          break;
        case AnimProperty.orbitRadius:
          defaultVal = 140.0;
          break;
        case AnimProperty.cornerRadius:
          defaultVal = node.cornerRadii.uniformValue;
          break;
        case AnimProperty.strokeWidth:
          defaultVal = node.strokes.isNotEmpty ? node.strokes.first.width : 1.0;
          break;
      }

      final evalVal = track.evaluate(timeMs, defaultVal);

      switch (track.property) {
        case AnimProperty.x:
          updatedNodes[track.nodeId] = node.copyWith(x: evalVal);
          changed = true;
          break;
        case AnimProperty.y:
          updatedNodes[track.nodeId] = node.copyWith(y: evalVal);
          changed = true;
          break;
        case AnimProperty.width:
          updatedNodes[track.nodeId] = node.copyWith(width: evalVal);
          changed = true;
          break;
        case AnimProperty.height:
          updatedNodes[track.nodeId] = node.copyWith(height: evalVal);
          changed = true;
          break;
        case AnimProperty.rotation:
          updatedNodes[track.nodeId] = node.copyWith(rotation: evalVal);
          changed = true;
          break;
        case AnimProperty.opacity:
          updatedNodes[track.nodeId] = node.copyWith(opacity: evalVal.clamp(0.0, 1.0));
          changed = true;
          break;
        case AnimProperty.scaleX:
        case AnimProperty.scaleY:
          break;
        case AnimProperty.pivotX:
        case AnimProperty.pivotY:
        case AnimProperty.orbitRadius:
          break;
        case AnimProperty.orbitAngle:
          final rad = evalVal * math.pi / 180.0;
          const originX = 400.0;
          const originY = 300.0;
          const radius = 140.0;
          updatedNodes[track.nodeId] = node.copyWith(
            x: originX + radius * math.cos(rad) - node.width / 2,
            y: originY + radius * math.sin(rad) - node.height / 2,
            rotation: evalVal,
          );
          changed = true;
          break;
        case AnimProperty.cornerRadius:
          updatedNodes[track.nodeId] = node.copyWith(cornerRadii: CornerRadii.all(evalVal));
          changed = true;
          break;
        case AnimProperty.strokeWidth:
          if (node.strokes.isNotEmpty) {
            final st = List<DesignStroke>.from(node.strokes);
            st[0] = st[0].copyWith(width: evalVal);
            updatedNodes[track.nodeId] = node.copyWith(strokes: st);
            changed = true;
          }
          break;
      }
    }

    state = state.copyWith(
      currentTimelineMs: timeMs,
      project: changed ? state.project.copyWith(nodes: updatedNodes) : state.project,
    );
  }

  void addKeyframeForSelectedNode({AnimProperty property = AnimProperty.x}) {
    final nodeId = state.primarySelectedId;
    if (nodeId == null) return;
    final node = state.project.nodes[nodeId];
    if (node == null) return;

    double value;
    switch (property) {
      case AnimProperty.x: value = node.x; break;
      case AnimProperty.y: value = node.y; break;
      case AnimProperty.width: value = node.width; break;
      case AnimProperty.height: value = node.height; break;
      case AnimProperty.rotation: value = node.rotation; break;
      case AnimProperty.opacity: value = node.opacity; break;
      case AnimProperty.scaleX:
      case AnimProperty.scaleY: value = 1.0; break;
      case AnimProperty.pivotX: value = node.width / 2; break;
      case AnimProperty.pivotY: value = node.height / 2; break;
      case AnimProperty.orbitAngle: value = node.rotation; break;
      case AnimProperty.orbitRadius: value = 140.0; break;
      case AnimProperty.cornerRadius: value = node.cornerRadii.uniformValue; break;
      case AnimProperty.strokeWidth: value = node.strokes.isNotEmpty ? node.strokes.first.width : 1.0; break;
    }

    final newKf = FloatKeyframe(timeMs: state.currentTimelineMs, value: value);
    final tracks = List<NodeAnimationTrack>.from(state.timeline.tracks);
    final existingTrackIdx = tracks.indexWhere((t) => t.nodeId == nodeId && t.property == property);

    if (existingTrackIdx >= 0) {
      final oldTrack = tracks[existingTrackIdx];
      final filteredKfs = oldTrack.keyframes.where((k) => (k.timeMs - state.currentTimelineMs).abs() > 10).toList();
      filteredKfs.add(newKf);
      filteredKfs.sort((a, b) => a.timeMs.compareTo(b.timeMs));
      tracks[existingTrackIdx] = oldTrack.copyWith(keyframes: filteredKfs);
    } else {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: property,
        keyframes: [newKf],
      ));
    }

    state = state.copyWith(timeline: state.timeline.copyWith(tracks: tracks));
  }

  void deleteKeyframeAtPlayhead() {
    final nodeId = state.primarySelectedId;
    if (nodeId == null) return;

    final tracks = List<NodeAnimationTrack>.from(state.timeline.tracks);
    for (int i = 0; i < tracks.length; i++) {
      if (tracks[i].nodeId == nodeId) {
        final filtered = tracks[i].keyframes.where((k) => (k.timeMs - state.currentTimelineMs).abs() > 50).toList();
        tracks[i] = tracks[i].copyWith(keyframes: filtered);
      }
    }
    state = state.copyWith(timeline: state.timeline.copyWith(tracks: tracks));
  }

  void toggleTimelineLoop() {
    state = state.copyWith(timeline: state.timeline.copyWith(isLooping: !state.timeline.isLooping));
  }

  void setTimelineFps(int fps) {
    state = state.copyWith(timeline: state.timeline.copyWith(fps: fps));
  }

  void snapToPrevKeyframe() {
    final prev = state.timeline.getPreviousKeyframeTime(state.currentTimelineMs);
    if (prev != null) {
      setTimelineScrub(prev);
    } else {
      setTimelineScrub(0.0);
    }
  }

  void snapToNextKeyframe() {
    final next = state.timeline.getNextKeyframeTime(state.currentTimelineMs);
    if (next != null) {
      setTimelineScrub(next);
    } else {
      setTimelineScrub(state.timeline.durationMs);
    }
  }

  void updateKeyframe(String nodeId, AnimProperty property, int index, FloatKeyframe updated) {
    final tracks = List<NodeAnimationTrack>.from(state.timeline.tracks);
    final idx = tracks.indexWhere((t) => t.nodeId == nodeId && t.property == property);
    if (idx >= 0) {
      final kfs = List<FloatKeyframe>.from(tracks[idx].keyframes);
      if (index >= 0 && index < kfs.length) {
        kfs[index] = updated;
        kfs.sort((a, b) => a.timeMs.compareTo(b.timeMs));
        tracks[idx] = tracks[idx].copyWith(keyframes: kfs);
        state = state.copyWith(timeline: state.timeline.copyWith(tracks: tracks));
      }
    }
  }

  void addQuickMotionPreset(String type) {
    final nodeId = state.primarySelectedId;
    if (nodeId == null) return;
    final node = state.project.nodes[nodeId];
    if (node == null) return;

    final tracks = List<NodeAnimationTrack>.from(state.timeline.tracks);
    tracks.removeWhere((t) => t.nodeId == nodeId);

    if (type == 'spin') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.rotation,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 0.0),
          FloatKeyframe(timeMs: 2000, value: 360.0),
        ],
      ));
    } else if (type == 'moveRight') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.x,
        keyframes: [
          FloatKeyframe(timeMs: 0, value: node.x),
          FloatKeyframe(timeMs: 1500, value: node.x + 160.0),
        ],
      ));
    } else if (type == 'fade') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.opacity,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 0.2),
          FloatKeyframe(timeMs: 1000, value: 1.0),
          FloatKeyframe(timeMs: 2000, value: 0.2),
        ],
      ));
    } else if (type == 'orbit') {
      final centerX = node.x + 120.0;
      final centerY = node.y;
      const radius = 120.0;
      final xKeys = <FloatKeyframe>[];
      final yKeys = <FloatKeyframe>[];
      const int steps = 8;
      for (int s = 0; s <= steps; s++) {
        final t = (3000.0 / steps) * s;
        final angle = (2.0 * math.pi / steps) * s;
        final xPos = centerX + radius * math.cos(angle) - node.width / 2;
        final yPos = centerY + radius * math.sin(angle) - node.height / 2;
        xKeys.add(FloatKeyframe(timeMs: t, value: xPos, interpolation: InterpolationType.easeInOut));
        yKeys.add(FloatKeyframe(timeMs: t, value: yPos, interpolation: InterpolationType.easeInOut));
      }
      tracks.add(NodeAnimationTrack(nodeId: nodeId, property: AnimProperty.x, keyframes: xKeys));
      tracks.add(NodeAnimationTrack(nodeId: nodeId, property: AnimProperty.y, keyframes: yKeys));
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.rotation,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 0.0, interpolation: InterpolationType.linear),
          FloatKeyframe(timeMs: 3000, value: 360.0, interpolation: InterpolationType.linear),
        ],
      ));
    } else if (type == 'bounce') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.y,
        keyframes: [
          FloatKeyframe(timeMs: 0, value: node.y - 120.0, interpolation: InterpolationType.easeIn),
          FloatKeyframe(timeMs: 800, value: node.y, interpolation: InterpolationType.bounce),
          FloatKeyframe(timeMs: 1400, value: node.y - 40.0, interpolation: InterpolationType.easeInOut),
          FloatKeyframe(timeMs: 2000, value: node.y, interpolation: InterpolationType.bounce),
        ],
      ));
    } else if (type == 'slideUp') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.y,
        keyframes: [
          FloatKeyframe(timeMs: 0, value: node.y + 140.0, interpolation: InterpolationType.easeOut),
          FloatKeyframe(timeMs: 1000, value: node.y, interpolation: InterpolationType.easeInOut),
        ],
      ));
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.opacity,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 0.0),
          FloatKeyframe(timeMs: 800, value: 1.0),
        ],
      ));
    } else if (type == 'slideDown') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.y,
        keyframes: [
          FloatKeyframe(timeMs: 0, value: node.y - 140.0, interpolation: InterpolationType.easeOut),
          FloatKeyframe(timeMs: 1000, value: node.y, interpolation: InterpolationType.easeInOut),
        ],
      ));
    } else if (type == 'pop') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.scaleX,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 0.2, interpolation: InterpolationType.spring),
          FloatKeyframe(timeMs: 600, value: 1.15, interpolation: InterpolationType.easeInOut),
          FloatKeyframe(timeMs: 1000, value: 1.0, interpolation: InterpolationType.spring),
        ],
      ));
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.scaleY,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 0.2, interpolation: InterpolationType.spring),
          FloatKeyframe(timeMs: 600, value: 1.15, interpolation: InterpolationType.easeInOut),
          FloatKeyframe(timeMs: 1000, value: 1.0, interpolation: InterpolationType.spring),
        ],
      ));
    } else if (type == 'pulse') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.scaleX,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 1.0),
          FloatKeyframe(timeMs: 500, value: 1.2, interpolation: InterpolationType.easeInOut),
          FloatKeyframe(timeMs: 1000, value: 1.0),
        ],
      ));
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.scaleY,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 1.0),
          FloatKeyframe(timeMs: 500, value: 1.2, interpolation: InterpolationType.easeInOut),
          FloatKeyframe(timeMs: 1000, value: 1.0),
        ],
      ));
    } else if (type == 'wobble') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.rotation,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 0.0),
          FloatKeyframe(timeMs: 250, value: -14.0),
          FloatKeyframe(timeMs: 500, value: 14.0),
          FloatKeyframe(timeMs: 750, value: -8.0),
          FloatKeyframe(timeMs: 1000, value: 8.0),
          FloatKeyframe(timeMs: 1250, value: 0.0),
        ],
      ));
    } else if (type == 'float') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.y,
        keyframes: [
          FloatKeyframe(timeMs: 0, value: node.y, interpolation: InterpolationType.easeInOut),
          FloatKeyframe(timeMs: 1000, value: node.y - 25.0, interpolation: InterpolationType.easeInOut),
          FloatKeyframe(timeMs: 2000, value: node.y, interpolation: InterpolationType.easeInOut),
        ],
      ));
    } else if (type == 'strobe') {
      tracks.add(NodeAnimationTrack(
        nodeId: nodeId,
        property: AnimProperty.opacity,
        keyframes: const [
          FloatKeyframe(timeMs: 0, value: 1.0, interpolation: InterpolationType.hold),
          FloatKeyframe(timeMs: 200, value: 0.1, interpolation: InterpolationType.hold),
          FloatKeyframe(timeMs: 400, value: 1.0, interpolation: InterpolationType.hold),
          FloatKeyframe(timeMs: 600, value: 0.1, interpolation: InterpolationType.hold),
          FloatKeyframe(timeMs: 800, value: 1.0, interpolation: InterpolationType.hold),
        ],
      ));
    }

    state = state.copyWith(
      timeline: state.timeline.copyWith(tracks: tracks, isLooping: true),
    );
  }

  void applyMotionPreset(String type) => addQuickMotionPreset(type);

  // --- SVG Import ---

  void importSvg(String svgXml) {
    try {
      final result = SvgImporter.parseSvg(svgXml);
      var current = state.project;

      for (final child in result.childNodes) {
        final cmd = AddNodeCommand(pageId: state.activePageId, node: child);
        current = _history.executeCommand(cmd, current);
      }

      final rootCmd = AddNodeCommand(pageId: state.activePageId, node: result.rootFrame);
      current = _history.executeCommand(rootCmd, current);

      state = state.copyWith(
        project: current,
        selectedNodeIds: {result.rootFrame.id},
        statusMessage: 'Imported SVG successfully',
      );
      _repository.scheduleAutosave(current);
    } catch (e) {
      state = state.copyWith(statusMessage: 'SVG import failed: $e');
    }
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
