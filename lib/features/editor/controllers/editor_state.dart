import 'package:flutter/material.dart';
import '../../../domain/models/project_model.dart';
import '../../../domain/models/animation_model.dart';
import '../../../domain/services/vector_path_service.dart';
import '../../../core/geometry/geometry_utils.dart';

enum EditorTool {
  select,
  hand,
  frame,
  section,
  rectangle,
  roundedRectangle,
  ellipse,
  triangle,
  line,
  arrow,
  polygon,
  star,
  vectorPen,
  freehand,
  text,
  comment,
}

enum DragMode {
  none,
  panningCanvas,
  marqueeSelecting,
  movingNodes,
  resizingNode,
  rotatingNode,
  drawingNode,
  movingAnchor,
  movingHandle,
}

class EditorState {
  final ProjectModel project;
  final String activePageId;
  final Set<String> selectedNodeIds;
  final String? hoveredNodeId;
  final EditorTool activeTool;
  final double zoom;
  final Offset panOffset;
  final DragMode dragMode;
  final ResizeHandleType? activeHandle;
  final Rect? marqueeRect;
  final List<SnapGuide> activeSnapGuides;
  final bool isDevInspectMode;
  final bool isPlayingPrototype;
  final bool isAutosaving;
  final String? statusMessage;

  // Real Vector Path Editing Mode
  final String? editingVectorNodeId;
  final int? selectedAnchorIndex;
  final VectorHandleTarget? selectedHandleTarget;

  // Animation Timeline
  final ProjectTimeline timeline;
  final double currentTimelineMs;
  final bool isPlayingTimeline;
  final bool showTimelinePanel;

  const EditorState({
    required this.project,
    required this.activePageId,
    this.selectedNodeIds = const {},
    this.hoveredNodeId,
    this.activeTool = EditorTool.select,
    this.zoom = 1.0,
    this.panOffset = const Offset(50, 50),
    this.dragMode = DragMode.none,
    this.activeHandle,
    this.marqueeRect,
    this.activeSnapGuides = const [],
    this.isDevInspectMode = false,
    this.isPlayingPrototype = false,
    this.isAutosaving = false,
    this.statusMessage,
    this.editingVectorNodeId,
    this.selectedAnchorIndex,
    this.selectedHandleTarget,
    this.timeline = const ProjectTimeline(),
    this.currentTimelineMs = 0.0,
    this.isPlayingTimeline = false,
    this.showTimelinePanel = false,
  });

  bool get isVectorEditing => editingVectorNodeId != null;

  /// Safe accessor for the primary selected node ID that never throws on sets or web.
  String? get primarySelectedId =>
      selectedNodeIds.isEmpty ? null : selectedNodeIds.first;

  EditorState copyWith({
    ProjectModel? project,
    String? activePageId,
    Set<String>? selectedNodeIds,
    String? hoveredNodeId,
    bool clearHovered = false,
    EditorTool? activeTool,
    double? zoom,
    Offset? panOffset,
    DragMode? dragMode,
    ResizeHandleType? activeHandle,
    bool clearHandle = false,
    Rect? marqueeRect,
    bool clearMarquee = false,
    List<SnapGuide>? activeSnapGuides,
    bool? isDevInspectMode,
    bool? isPlayingPrototype,
    bool? isAutosaving,
    String? statusMessage,
    bool clearStatus = false,
    String? editingVectorNodeId,
    bool clearEditingVector = false,
    int? selectedAnchorIndex,
    bool clearAnchorIndex = false,
    VectorHandleTarget? selectedHandleTarget,
    bool clearHandleTarget = false,
    ProjectTimeline? timeline,
    double? currentTimelineMs,
    bool? isPlayingTimeline,
    bool? showTimelinePanel,
  }) {
    return EditorState(
      project: project ?? this.project,
      activePageId: activePageId ?? this.activePageId,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      hoveredNodeId: clearHovered
          ? null
          : (hoveredNodeId ?? this.hoveredNodeId),
      activeTool: activeTool ?? this.activeTool,
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
      dragMode: dragMode ?? this.dragMode,
      activeHandle: clearHandle ? null : (activeHandle ?? this.activeHandle),
      marqueeRect: clearMarquee ? null : (marqueeRect ?? this.marqueeRect),
      activeSnapGuides: activeSnapGuides ?? this.activeSnapGuides,
      isDevInspectMode: isDevInspectMode ?? this.isDevInspectMode,
      isPlayingPrototype: isPlayingPrototype ?? this.isPlayingPrototype,
      isAutosaving: isAutosaving ?? this.isAutosaving,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      editingVectorNodeId: clearEditingVector
          ? null
          : (editingVectorNodeId ?? this.editingVectorNodeId),
      selectedAnchorIndex: clearAnchorIndex
          ? null
          : (selectedAnchorIndex ?? this.selectedAnchorIndex),
      selectedHandleTarget: clearHandleTarget
          ? null
          : (selectedHandleTarget ?? this.selectedHandleTarget),
      timeline: timeline ?? this.timeline,
      currentTimelineMs: currentTimelineMs ?? this.currentTimelineMs,
      isPlayingTimeline: isPlayingTimeline ?? this.isPlayingTimeline,
      showTimelinePanel: showTimelinePanel ?? this.showTimelinePanel,
    );
  }
}
