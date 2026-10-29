import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/project_model.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/text_data.dart';
import '../../../../domain/services/vector_path_service.dart';
import '../../../../domain/services/node_render_service.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/neumorphic.dart';
import '../../../../core/geometry/transform2d.dart';
import '../../../../core/geometry/geometry_utils.dart';
import '../../controllers/editor_state.dart';
import '../../controllers/editor_controller.dart';
import '../../../settings/models/app_settings.dart';
import '../dialogs/manual_zoom_dialog.dart';
import 'canvas_painter.dart';

class CanvasViewport extends ConsumerStatefulWidget {
  final ProjectModel project;

  const CanvasViewport({super.key, required this.project});

  @override
  ConsumerState<CanvasViewport> createState() => _CanvasViewportState();
}

class _CanvasViewportState extends ConsumerState<CanvasViewport> {
  Offset? _dragStartScreen;
  Offset? _dragStartDoc;
  Map<String, Offset>? _originalNodePositions;
  Rect? _originalNodeBounds;
  double? _originalFontSize;
  ResizeHandleType? _activeHandle;
  Rect? _currentMarquee;
  final List<SnapGuide> _currentSnapGuides = [];
  Offset _cursorPosDoc = Offset.zero;

  int? _activeAnchorIdx;
  VectorHandleTarget? _activeHandleTarget;
  DateTime? _lastTapTime;
  String? _lastTapNodeId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider(widget.project));
    final controller = ref.read(
      editorControllerProvider(widget.project).notifier,
    );
    final page = state.project.getPage(state.activePageId);

    if (page == null) {
      return const Center(child: Text('No active page'));
    }

    final transform = CanvasTransform(
      zoom: state.zoom,
      panOffset: state.panOffset,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Stack(
            children: [
              // 1. Interactive Canvas Gestures Area
              Positioned.fill(
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      // Pan or zoom with mouse wheel towards cursor
                      if (HardwareKeyboard.instance.isControlPressed ||
                          HardwareKeyboard.instance.isMetaPressed) {
                        final zoomFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
                        controller.zoomAroundPoint(
                          state.zoom * zoomFactor,
                          event.localPosition,
                        );
                      } else {
                        controller.panDelta(-event.scrollDelta);
                      }
                    }
                  },
                  onPointerDown: (event) =>
                      _onPointerDown(event, transform, state, controller),
                  onPointerMove: (event) =>
                      _onPointerMove(event, transform, state, controller),
                  onPointerUp: (event) =>
                      _onPointerUp(event, transform, state, controller),
                  child: MouseRegion(
                    cursor: _getCursorForTool(state.activeTool, _activeHandle),
                    onHover: (event) {
                      final docPt = transform.screenToDoc(event.localPosition);
                      setState(() => _cursorPosDoc = docPt);

                      if (state.activeTool == EditorTool.select &&
                          state.dragMode == DragMode.none) {
                        final hit = GeometryUtils.hitTestNodes(
                          docPt,
                          page.rootNodeIds
                              .map((id) => state.project.nodes[id])
                              .whereType<DesignNode>()
                              .toList(),
                        );
                        controller.setHovered(hit?.id);
                      }
                    },
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: CanvasPainter(
                          project: state.project,
                          page: page,
                          selectedNodeIds: state.selectedNodeIds,
                          hoveredNodeId: state.hoveredNodeId,
                          zoom: state.zoom,
                          panOffset: state.panOffset,
                          marqueeRect: _currentMarquee,
                          snapGuides: _currentSnapGuides,
                          isDevInspectMode: state.isDevInspectMode,
                          editingVectorNodeId: state.editingVectorNodeId,
                          selectedAnchorIndex: state.selectedAnchorIndex,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Coordinate Rulers (Top & Left)
              _buildTopRuler(constraints.maxWidth, transform),
              _buildLeftRuler(constraints.maxHeight, transform),

              // 3. Floating Vector Edit Mode Bar
              if (state.isVectorEditing || state.activeTool == EditorTool.vectorPen)
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: NeuCard(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.polyline_rounded,
                            size: 16,
                            color: FormaColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            state.activeTool == EditorTool.vectorPen
                                ? 'Pen Drafting (Drag to curve)'
                                : 'Vector Edit Mode',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          NeuButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            tooltip: 'Close Vector Loop',
                            onPressed: controller.closeVectorPath,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.loop_rounded, size: 14),
                                SizedBox(width: 4),
                                Text('Close Path', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          NeuButton(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            tooltip: 'Toggle Smooth / Corner Point',
                            onPressed: state.selectedAnchorIndex != null
                                ? () => controller.toggleVectorAnchorSmooth(
                                      state.selectedAnchorIndex!,
                                    )
                                : null,
                            child: const Text(
                              'Smooth / Sharp',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 6),
                          NeuIconButton(
                            icon: Icons.delete_outline_rounded,
                            size: 28,
                            iconSize: 15,
                            tooltip: 'Delete Selected Anchor',
                            onPressed: state.selectedAnchorIndex != null
                                ? controller.deleteSelectedVectorAnchor
                                : null,
                          ),
                          const SizedBox(width: 8),
                          NeuButton(
                            isActive: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            tooltip: 'Finish Vector',
                            onPressed: controller.exitVectorEditMode,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, size: 15, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Finish',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Floating Zoom & Viewport Navigation HUD
              Positioned(
                bottom: constraints.maxWidth < 650 ? 76 : 24,
                right: constraints.maxWidth < 650 ? 14 : 20,
                child: NeuCard(
                  radius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Builder(
                    builder: (ctx) {
                      final centerPoint = Offset(
                        constraints.maxWidth / 2,
                        constraints.maxHeight / 2,
                      );
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          NeuIconButton(
                            icon: Icons.remove_rounded,
                            size: 32,
                            iconSize: 16,
                            tooltip: 'Zoom Out (Ctrl -)',
                            onPressed: () => controller.zoomOut(centerPoint),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              final settings = ref.read(settingsProvider);
                              showManualZoomDialog(
                                context,
                                controller,
                                state.zoom,
                                settings.extendedZoomLimit,
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Text(
                                '${(state.zoom * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: FormaColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          NeuIconButton(
                            icon: Icons.add_rounded,
                            size: 32,
                            iconSize: 16,
                            tooltip: 'Zoom In (Ctrl +)',
                            onPressed: () => controller.zoomIn(centerPoint),
                          ),
                          const SizedBox(width: 4),
                          NeuIconButton(
                            icon: Icons.fit_screen_rounded,
                            size: 32,
                            iconSize: 15,
                            tooltip: 'Fit to Viewport',
                            onPressed: () => controller.zoomToFit(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  MouseCursor _getCursorForTool(EditorTool tool, ResizeHandleType? handle) {
    if (handle != null) {
      switch (handle) {
        case ResizeHandleType.topLeft:
        case ResizeHandleType.bottomRight:
          return SystemMouseCursors.resizeUpLeftDownRight;
        case ResizeHandleType.topRight:
        case ResizeHandleType.bottomLeft:
          return SystemMouseCursors.resizeUpRightDownLeft;
        case ResizeHandleType.centerLeft:
        case ResizeHandleType.centerRight:
          return SystemMouseCursors.resizeLeftRight;
        case ResizeHandleType.topCenter:
        case ResizeHandleType.bottomCenter:
          return SystemMouseCursors.resizeUpDown;
        case ResizeHandleType.rotation:
          return SystemMouseCursors.click;
      }
    }

    switch (tool) {
      case EditorTool.hand:
        return SystemMouseCursors.grab;
      case EditorTool.select:
        return SystemMouseCursors.basic;
      case EditorTool.text:
        return SystemMouseCursors.text;
      default:
        return SystemMouseCursors.precise;
    }
  }

  void _onPointerDown(
    PointerDownEvent event,
    CanvasTransform transform,
    EditorState state,
    EditorController controller,
  ) {
    _dragStartScreen = event.localPosition;
    _dragStartDoc = transform.screenToDoc(event.localPosition);
    final page = state.project.getPage(state.activePageId);
    if (page == null) return;

    if (state.activeTool == EditorTool.hand ||
        event.buttons == kMiddleMouseButton) {
      controller.setDragMode(DragMode.panningCanvas);
      return;
    }

    // Vector Pen Tool (drafting or adding anchors with interactive curve bending)
    if (state.activeTool == EditorTool.vectorPen) {
      if (!state.isVectorEditing) {
        controller.startNewVectorDraft(_dragStartDoc!);
        _activeAnchorIdx = 0;
        _activeHandleTarget = VectorHandleTarget.handleOut;
        controller.setDragMode(DragMode.movingHandle);
        return;
      } else {
        final node = state.project.nodes[state.editingVectorNodeId];
        if (node != null && node.vectorData != null) {
          final nodeOffset = Offset(node.x, node.y);
          final touchRadius = 14.0 / state.zoom;
          final docPt = _dragStartDoc!;

          // Snap to first anchor point to close path
          if (node.vectorData!.anchors.length >= 2) {
            final firstPt = nodeOffset + node.vectorData!.anchors.first.point;
            if ((docPt - firstPt).distance <= touchRadius) {
              controller.toggleVectorClosed();
              controller.exitVectorEditMode();
              controller.setTool(EditorTool.select);
              return;
            }
          }

          for (int i = 0; i < node.vectorData!.anchors.length; i++) {
            final a = node.vectorData!.anchors[i];
            final pt = nodeOffset + a.point;
            if ((docPt - pt).distance <= touchRadius) {
              _activeAnchorIdx = i;
              controller.selectAnchor(i);
              _activeHandleTarget = VectorHandleTarget.handleOut;
              controller.setDragMode(DragMode.movingHandle);
              return;
            }
          }

          final localPt = docPt - nodeOffset;
          controller.addVectorAnchor(localPt);
          _activeAnchorIdx = node.vectorData!.anchors.length;
          _activeHandleTarget = VectorHandleTarget.handleOut;
          controller.setDragMode(DragMode.movingHandle);
          return;
        }
      }
    }

    // Vector Edit Mode Interaction
    if (state.isVectorEditing) {
      final node = state.project.nodes[state.editingVectorNodeId];
      if (node != null && node.vectorData != null) {
        final nodeOffset = Offset(node.x, node.y);
        final touchRadius = 10.0 / state.zoom;
        final docPt = _dragStartDoc!;

        final selIdx = state.selectedAnchorIndex;
        if (selIdx != null && selIdx < node.vectorData!.anchors.length) {
          final selAnchor = node.vectorData!.anchors[selIdx];
          if (selAnchor.handleIn != null) {
            final inPt = nodeOffset + selAnchor.handleIn!;
            if ((docPt - inPt).distance <= touchRadius) {
              _activeAnchorIdx = selIdx;
              _activeHandleTarget = VectorHandleTarget.handleIn;
              controller.setDragMode(DragMode.movingHandle);
              return;
            }
          }
          if (selAnchor.handleOut != null) {
            final outPt = nodeOffset + selAnchor.handleOut!;
            if ((docPt - outPt).distance <= touchRadius) {
              _activeAnchorIdx = selIdx;
              _activeHandleTarget = VectorHandleTarget.handleOut;
              controller.setDragMode(DragMode.movingHandle);
              return;
            }
          }
        }

        for (int i = 0; i < node.vectorData!.anchors.length; i++) {
          final a = node.vectorData!.anchors[i];
          final pt = nodeOffset + a.point;
          if ((docPt - pt).distance <= touchRadius) {
            _activeAnchorIdx = i;
            controller.selectAnchor(i);
            controller.setDragMode(DragMode.movingAnchor);
            return;
          }
        }

        if (state.activeTool == EditorTool.vectorPen) {
          controller.addVectorAnchor(docPt - nodeOffset);
          return;
        }
      }
      return;
    }

    if (state.activeTool == EditorTool.select) {
      // 1. Check if clicking on resize/rotate handle of single selected node
      if (state.selectedNodeIds.length == 1) {
        final node = state.project.nodes[state.selectedNodeIds.first];
        if (node != null && !node.isLocked) {
          final handles = GeometryUtils.getSelectionHandles(
            node.rect,
            handleSize: 12.0 / state.zoom,
          );
          for (final h in handles) {
            if (h.touchRect.contains(_dragStartDoc!)) {
              _activeHandle = h.type;
              _originalNodeBounds = node.rect;
              _originalFontSize = node.textData?.fontSize;
              controller.setDragMode(
                h.type == ResizeHandleType.rotation
                    ? DragMode.rotatingNode
                    : DragMode.resizingNode,
                handle: h.type,
              );
              return;
            }
          }
        }
      }

      // 2. Hit-test nodes on canvas
      final rootNodes = page.rootNodeIds
          .map((id) => state.project.nodes[id])
          .whereType<DesignNode>()
          .toList();
      final hitNode = GeometryUtils.hitTestNodes(_dragStartDoc!, rootNodes);

      final isMulti = HardwareKeyboard.instance.isShiftPressed;

      if (hitNode != null) {
        final now = DateTime.now();
        if (_lastTapNodeId == hitNode.id &&
            _lastTapTime != null &&
            now.difference(_lastTapTime!).inMilliseconds < 350) {
          if (hitNode.type == NodeType.text) {
            _showInPlaceTextEditor(context, hitNode, controller);
          }
          _lastTapNodeId = null;
          _lastTapTime = null;
          return;
        }
        _lastTapNodeId = hitNode.id;
        _lastTapTime = now;

        if (!state.selectedNodeIds.contains(hitNode.id) && !isMulti) {
          controller.selectNode(hitNode.id);
        } else if (isMulti) {
          controller.selectNode(hitNode.id, multiSelect: true);
        }

        // Store positions for dragging
        _originalNodePositions = {};
        for (final id
            in state.selectedNodeIds.contains(hitNode.id)
                ? state.selectedNodeIds
                : {hitNode.id}) {
          final n = state.project.nodes[id];
          if (n != null && !n.isLocked) {
            _originalNodePositions![id] = Offset(n.x, n.y);
          }
        }

        controller.setDragMode(DragMode.movingNodes);
      } else {
        // Hit empty space: clear selection & initiate marquee selection
        if (!isMulti) {
          controller.clearSelection();
        }
        controller.setDragMode(DragMode.marqueeSelecting);
      }
    } else {
      // Drawing Tool active
      controller.setDragMode(DragMode.drawingNode);
    }
  }

  void _onPointerMove(
    PointerMoveEvent event,
    CanvasTransform transform,
    EditorState state,
    EditorController controller,
  ) {
    if (_dragStartScreen == null || _dragStartDoc == null) return;
    final currentDoc = transform.screenToDoc(event.localPosition);
    setState(() => _cursorPosDoc = currentDoc);

    final deltaDoc = currentDoc - _dragStartDoc!;

    if (state.dragMode == DragMode.panningCanvas) {
      final screenDelta = event.delta;
      controller.panDelta(screenDelta);
    } else if (state.dragMode == DragMode.movingAnchor &&
        _activeAnchorIdx != null &&
        state.editingVectorNodeId != null) {
      final node = state.project.nodes[state.editingVectorNodeId!];
      if (node != null) {
        final localPt = currentDoc - Offset(node.x, node.y);
        controller.updateVectorAnchor(_activeAnchorIdx!, localPt);
      }
    } else if (state.dragMode == DragMode.movingHandle &&
        _activeAnchorIdx != null &&
        _activeHandleTarget != null &&
        state.editingVectorNodeId != null) {
      final node = state.project.nodes[state.editingVectorNodeId!];
      if (node != null) {
        final localPt = currentDoc - Offset(node.x, node.y);
        controller.updateVectorHandle(
          _activeAnchorIdx!,
          _activeHandleTarget!,
          localPt,
        );
      }
    } else if (state.dragMode == DragMode.movingNodes &&
        _originalNodePositions != null) {
      // Snap calculations
      final page = state.project.getPage(state.activePageId);
      final staticRects =
          page?.rootNodeIds
              .where((id) => !state.selectedNodeIds.contains(id))
              .map((id) => state.project.nodes[id]?.rect)
              .whereType<Rect>()
              .toList() ??
          [];

      final primaryId = state.primarySelectedId;
      final primaryNode = primaryId != null
          ? state.project.nodes[primaryId]
          : null;

      Offset finalDelta = deltaDoc;
      if (primaryNode != null) {
        finalDelta = GeometryUtils.snapDelta(
          activeRect: primaryNode.rect,
          rawDelta: deltaDoc,
          staticRects: staticRects,
          snapToGrid: page?.snapToGrid ?? false,
          gridSize: page?.gridSize ?? 8.0,
          outGuides: _currentSnapGuides,
        );
      }

      // Update node positions temporarily during drag
      final updatedPositions = <String, Offset>{};
      for (final entry in _originalNodePositions!.entries) {
        updatedPositions[entry.key] = entry.value + finalDelta;
      }

      final updatedNodes = Map<String, DesignNode>.from(state.project.nodes);
      for (final entry in updatedPositions.entries) {
        final n = updatedNodes[entry.key];
        if (n != null) {
          updatedNodes[entry.key] = n.copyWith(
            x: entry.value.dx,
            y: entry.value.dy,
          );
        }
      }

      controller.updateLiveNodes(updatedNodes, snapGuides: _currentSnapGuides);
    } else if (state.dragMode == DragMode.resizingNode &&
        _originalNodeBounds != null) {
      // Resizing single node
      final nodeId = state.selectedNodeIds.first;
      final node = state.project.nodes[nodeId];
      if (node != null && _activeHandle != null) {
        Rect newBounds = _calculateResizedRect(
          _originalNodeBounds!,
          _activeHandle!,
          deltaDoc,
        );
        if (HardwareKeyboard.instance.isShiftPressed &&
            (_activeHandle == ResizeHandleType.topLeft ||
                _activeHandle == ResizeHandleType.topRight ||
                _activeHandle == ResizeHandleType.bottomLeft ||
                _activeHandle == ResizeHandleType.bottomRight)) {
          final aspect = _originalNodeBounds!.width /
              (_originalNodeBounds!.height == 0 ? 1 : _originalNodeBounds!.height);
          final maxSide = math.max(newBounds.width, newBounds.height);
          final constrainedW = aspect >= 1.0 ? maxSide : maxSide * aspect;
          final constrainedH = aspect >= 1.0 ? maxSide / aspect : maxSide;
          newBounds = Rect.fromLTWH(
            newBounds.left,
            newBounds.top,
            constrainedW,
            constrainedH,
          );
        }
        DesignNode updated;
        if (node.type == NodeType.text && node.textData != null) {
          final scaleH = newBounds.height / math.max(10.0, _originalNodeBounds!.height);
          final scaleW = newBounds.width / math.max(10.0, _originalNodeBounds!.width);
          final scale = math.max(scaleH, scaleW);
          final baseFs = _originalFontSize ?? node.textData!.fontSize;
          final newFontSize = (baseFs * scale).clamp(6.0, 500.0);
          final updatedTextData = node.textData!.copyWith(fontSize: newFontSize);
          final measured = NodeRenderService.measureText(updatedTextData);
          updated = node.copyWith(
            x: newBounds.left,
            y: newBounds.top,
            width: math.max(newBounds.width, measured.width + 8.0),
            height: math.max(newBounds.height, measured.height + 4.0),
            textData: updatedTextData,
          );
        } else {
          updated = node.copyWith(
            x: newBounds.left,
            y: newBounds.top,
            width: math.max(10.0, newBounds.width),
            height: math.max(10.0, newBounds.height),
          );
        }
        controller.updateSingleNodeLive(updated);
      }
    } else if (state.dragMode == DragMode.rotatingNode) {
      final nodeId = state.selectedNodeIds.first;
      final node = state.project.nodes[nodeId];
      if (node != null) {
        final center = node.rect.center;
        final angleRad =
            math.atan2(currentDoc.dy - center.dy, currentDoc.dx - center.dx) +
            math.pi / 2;
        double angleDeg = (angleRad * 180 / math.pi) % 360;
        if (HardwareKeyboard.instance.isShiftPressed) {
          // Snap to 15 degrees
          angleDeg = (angleDeg / 15).round() * 15;
        }
        controller.updateSingleNodeLive(node.copyWith(rotation: angleDeg));
      }
    } else if (state.dragMode == DragMode.marqueeSelecting) {
      final marquee = Rect.fromPoints(_dragStartDoc!, currentDoc);
      setState(() => _currentMarquee = marquee);

      // Hit-test all intersecting nodes
      final page = state.project.getPage(state.activePageId);
      if (page != null) {
        final selectedIds = <String>{};
        for (final id in page.rootNodeIds) {
          final n = state.project.nodes[id];
          if (n != null && marquee.overlaps(n.rect)) {
            selectedIds.add(n.id);
          }
        }
        controller.selectNodes(selectedIds);
      }
    } else if (state.dragMode == DragMode.drawingNode) {
      Rect drawRect = Rect.fromPoints(_dragStartDoc!, currentDoc);
      if (HardwareKeyboard.instance.isShiftPressed) {
        final w = currentDoc.dx - _dragStartDoc!.dx;
        final h = currentDoc.dy - _dragStartDoc!.dy;
        final side = math.max(w.abs(), h.abs());
        final endX = _dragStartDoc!.dx + side * (w < 0 ? -1 : 1);
        final endY = _dragStartDoc!.dy + side * (h < 0 ? -1 : 1);
        drawRect = Rect.fromPoints(_dragStartDoc!, Offset(endX, endY));
      }
      setState(() => _currentMarquee = drawRect);
    }
  }

  void _onPointerUp(
    PointerUpEvent event,
    CanvasTransform transform,
    EditorState state,
    EditorController controller,
  ) {
    if (_dragStartDoc != null &&
        state.dragMode == DragMode.drawingNode &&
        state.activeTool != EditorTool.vectorPen) {
      final endDoc = transform.screenToDoc(event.localPosition);
      Rect rawRect = Rect.fromPoints(_dragStartDoc!, endDoc);
      if (HardwareKeyboard.instance.isShiftPressed) {
        final w = endDoc.dx - _dragStartDoc!.dx;
        final h = endDoc.dy - _dragStartDoc!.dy;
        final side = math.max(w.abs(), h.abs());
        final endX = _dragStartDoc!.dx + side * (w < 0 ? -1 : 1);
        final endY = _dragStartDoc!.dy + side * (h < 0 ? -1 : 1);
        rawRect = Rect.fromPoints(_dragStartDoc!, Offset(endX, endY));
      }
      final isText = state.activeTool == EditorTool.text;
      Rect finalRect;
      if (isText) {
        final rw = rawRect.width.abs();
        final rh = rawRect.height.abs();
        finalRect = Rect.fromLTWH(
          rawRect.left,
          rawRect.top,
          rw > 40 ? rw : 200.0,
          rh > 24 ? rh : 48.0,
        );
      } else {
        finalRect = Rect.fromLTWH(
          rawRect.left,
          rawRect.top,
          math.max(20.0, rawRect.width),
          math.max(20.0, rawRect.height),
        );
      }

      final nodeType = _nodeTypeForTool(state.activeTool);
      final isTriangle = state.activeTool == EditorTool.triangle;
      final createdId = controller.createNode(
        type: nodeType,
        rect: finalRect,
        polygonSides: isTriangle ? 3 : (nodeType == NodeType.polygon ? 5 : null),
        name: isTriangle
            ? 'Triangle ${state.project.nodes.length + 1}'
            : (isText ? 'Text ${state.project.nodes.length + 1}' : null),
      );

      if (isText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final createdNode = controller.currentState.project.nodes[createdId];
          if (createdNode != null && mounted) {
            _showInPlaceTextEditor(context, createdNode, controller);
          }
        });
      }
    } else if (state.dragMode == DragMode.resizingNode &&
        _originalNodeBounds != null &&
        state.selectedNodeIds.length == 1) {
      final nodeId = state.selectedNodeIds.first;
      final n = state.project.nodes[nodeId];
      if (n != null) {
        controller.updateNode(n);
      }
    } else if (state.dragMode == DragMode.movingNodes &&
        _originalNodePositions != null) {
      // Commit final move positions
      final newPositions = <String, Offset>{};
      for (final id in _originalNodePositions!.keys) {
        final n = state.project.nodes[id];
        if (n != null) {
          newPositions[id] = Offset(n.x, n.y);
        }
      }
      controller.moveNodes(_originalNodePositions!, newPositions);
    }

    setState(() {
      _dragStartScreen = null;
      _dragStartDoc = null;
      _originalNodePositions = null;
      _originalNodeBounds = null;
      _originalFontSize = null;
      _activeHandle = null;
      _currentMarquee = null;
      _currentSnapGuides.clear();
      _activeAnchorIdx = null;
      _activeHandleTarget = null;
    });

    controller.setDragMode(DragMode.none);
  }

  Rect _calculateResizedRect(Rect orig, ResizeHandleType handle, Offset delta) {
    double l = orig.left;
    double t = orig.top;
    double r = orig.right;
    double b = orig.bottom;

    switch (handle) {
      case ResizeHandleType.topLeft:
        l += delta.dx;
        t += delta.dy;
        break;
      case ResizeHandleType.topCenter:
        t += delta.dy;
        break;
      case ResizeHandleType.topRight:
        r += delta.dx;
        t += delta.dy;
        break;
      case ResizeHandleType.centerLeft:
        l += delta.dx;
        break;
      case ResizeHandleType.centerRight:
        r += delta.dx;
        break;
      case ResizeHandleType.bottomLeft:
        l += delta.dx;
        b += delta.dy;
        break;
      case ResizeHandleType.bottomCenter:
        b += delta.dy;
        break;
      case ResizeHandleType.bottomRight:
        r += delta.dx;
        b += delta.dy;
        break;
      case ResizeHandleType.rotation:
        break;
    }

    if (r < l) {
      final tmp = r;
      r = l;
      l = tmp;
    }
    if (b < t) {
      final tmp = b;
      b = t;
      t = tmp;
    }

    return Rect.fromLTRB(l, t, r, b);
  }

  NodeType _nodeTypeForTool(EditorTool tool) {
    switch (tool) {
      case EditorTool.frame:
        return NodeType.frame;
      case EditorTool.section:
        return NodeType.annotationSection;
      case EditorTool.rectangle:
        return NodeType.rectangle;
      case EditorTool.roundedRectangle:
        return NodeType.roundedRectangle;
      case EditorTool.ellipse:
        return NodeType.ellipse;
      case EditorTool.line:
        return NodeType.line;
      case EditorTool.arrow:
        return NodeType.arrow;
      case EditorTool.triangle:
      case EditorTool.polygon:
        return NodeType.polygon;
      case EditorTool.star:
        return NodeType.star;
      case EditorTool.text:
        return NodeType.text;
      case EditorTool.vectorPen:
        return NodeType.vectorPath;
      case EditorTool.freehand:
        return NodeType.freehandPath;
      default:
        return NodeType.rectangle;
    }
  }

  Widget _buildTopRuler(double width, CanvasTransform transform) {
    return Positioned(
      top: 0,
      left: 20,
      right: 0,
      height: 20,
      child: Container(
        color: const Color(0xFFE2E9F3).withValues(alpha: 0.85),
        child: CustomPaint(
          size: Size(width, 20),
          painter: _TopRulerPainter(
            transform: transform,
            cursorX: _cursorPosDoc.dx,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftRuler(double height, CanvasTransform transform) {
    return Positioned(
      top: 20,
      left: 0,
      bottom: 0,
      width: 20,
      child: Container(
        color: const Color(0xFFE2E9F3).withValues(alpha: 0.85),
        child: CustomPaint(
          size: Size(20, height),
          painter: _LeftRulerPainter(
            transform: transform,
            cursorY: _cursorPosDoc.dy,
          ),
        ),
      ),
    );
  }
  Future<void> _showInPlaceTextEditor(
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
            Text('Edit Canvas Text', style: TextStyle(fontSize: 16)),
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

class _TopRulerPainter extends CustomPainter {
  final CanvasTransform transform;
  final double cursorX;

  _TopRulerPainter({required this.transform, required this.cursorX});

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = const Color(0xFF8A99AD)
      ..strokeWidth = 1.0;

    final step = transform.zoom >= 1.0 ? 50.0 : 100.0;
    final minDocX = transform.screenToDoc(Offset.zero).dx;
    final maxDocX = transform.screenToDoc(Offset(size.width, 0)).dx;

    final startX = (minDocX / step).floor() * step;
    final endX = (maxDocX / step).ceil() * step;

    for (double x = startX; x <= endX; x += step) {
      final screenX = transform.docToScreen(Offset(x, 0)).dx;
      canvas.drawLine(Offset(screenX, 12), Offset(screenX, 20), tickPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: x.toInt().toString(),
          style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(screenX + 2, 2));
    }

    // Cursor indicator
    final cursorScreenX = transform.docToScreen(Offset(cursorX, 0)).dx;
    canvas.drawLine(
      Offset(cursorScreenX, 0),
      Offset(cursorScreenX, 20),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _TopRulerPainter oldDelegate) => true;
}

class _LeftRulerPainter extends CustomPainter {
  final CanvasTransform transform;
  final double cursorY;

  _LeftRulerPainter({required this.transform, required this.cursorY});

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = const Color(0xFF8A99AD)
      ..strokeWidth = 1.0;

    final step = transform.zoom >= 1.0 ? 50.0 : 100.0;
    final minDocY = transform.screenToDoc(Offset.zero).dy;
    final maxDocY = transform.screenToDoc(Offset(0, size.height)).dy;

    final startY = (minDocY / step).floor() * step;
    final endY = (maxDocY / step).ceil() * step;

    for (double y = startY; y <= endY; y += step) {
      final screenY = transform.docToScreen(Offset(0, y)).dy;
      canvas.drawLine(Offset(12, screenY), Offset(20, screenY), tickPaint);
    }

    // Cursor indicator
    final cursorScreenY = transform.docToScreen(Offset(0, cursorY)).dy;
    canvas.drawLine(
      Offset(0, cursorScreenY),
      Offset(20, cursorScreenY),
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _LeftRulerPainter oldDelegate) => true;
}
