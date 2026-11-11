import 'package:flutter/material.dart';
import 'node_model.dart';

/// Represents the type of canvas tab open in the editor.
enum EditorTabType {
  /// Standard infinite freeform design artboard canvas.
  mainCanvas,

  /// Precision bounded icon crafting studio canvas.
  iconCanvas,
}

/// Represents an open tab in the Forma Studio editor.
/// Supports both main multi-page infinite canvas and dedicated bounded icon studio canvases.
@immutable
class EditorTab {
  /// Unique identifier of this tab.
  final String id;

  /// Display title shown on the tab pill.
  final String title;

  /// Type of editor canvas associated with this tab.
  final EditorTabType type;

  /// Target bounded canvas size for icon design (e.g. 16, 24, 32, 48, 64, 128).
  /// Ignored for [EditorTabType.mainCanvas].
  final double iconSize;

  /// Visual nodes and shapes created or edited in this icon canvas.
  final List<DesignNode> nodes;

  /// Whether the user is allowed to close this tab.
  /// Typically false for the primary main canvas artboard.
  final bool isClosable;

  /// Whether changes have been made in this tab that are unsaved or modified.
  final bool isModified;

  /// Whether to render the 1px precision pixel grid when zoomed in.
  final bool showPixelGrid;

  /// Whether to render the 0.5px sub-pixel grid at high zoom.
  final bool showSubpixelGrid;

  /// Whether to render standard Material/Apple icon keyline guides (circle, square, rect, safe zone).
  final bool showKeylines;

  /// Whether to render the central crosshair axes.
  final bool showCenterAxes;

  /// Whether coordinates snap to integer pixels.
  final bool snapToPixel;

  /// Custom background color for the bounded artboard (null = studio theme default).
  final Color? backgroundColor;

  const EditorTab({
    required this.id,
    required this.title,
    required this.type,
    this.iconSize = 24.0,
    this.nodes = const [],
    this.isClosable = true,
    this.isModified = false,
    this.showPixelGrid = true,
    this.showSubpixelGrid = false,
    this.showKeylines = true,
    this.showCenterAxes = true,
    this.snapToPixel = true,
    this.backgroundColor,
  });

  /// Factory constructor for the primary main canvas tab.
  factory EditorTab.mainCanvas({
    String id = 'main-canvas',
    String title = 'Main Artboard',
  }) {
    return EditorTab(
      id: id,
      title: title,
      type: EditorTabType.mainCanvas,
      iconSize: 24.0,
      nodes: const [],
      isClosable: false,
      isModified: false,
      showPixelGrid: false,
      showKeylines: false,
      showCenterAxes: false,
    );
  }

  /// Factory constructor for a dedicated bounded icon studio canvas tab.
  factory EditorTab.iconCanvas({
    String? id,
    String? title,
    double iconSize = 24.0,
    List<DesignNode> nodes = const [],
    bool isClosable = true,
    bool isModified = false,
    bool showPixelGrid = true,
    bool showSubpixelGrid = false,
    bool showKeylines = true,
    bool showCenterAxes = true,
    bool snapToPixel = true,
    Color? backgroundColor,
  }) {
    final effectiveId = id ?? 'icon-tab-${DateTime.now().millisecondsSinceEpoch}';
    final effectiveTitle = title ?? 'Icon ${iconSize.toInt()}x${iconSize.toInt()}';
    return EditorTab(
      id: effectiveId,
      title: effectiveTitle,
      type: EditorTabType.iconCanvas,
      iconSize: iconSize,
      nodes: nodes,
      isClosable: isClosable,
      isModified: isModified,
      showPixelGrid: showPixelGrid,
      showSubpixelGrid: showSubpixelGrid,
      showKeylines: showKeylines,
      showCenterAxes: showCenterAxes,
      snapToPixel: snapToPixel,
      backgroundColor: backgroundColor,
    );
  }

  /// Whether this tab is the primary infinite main canvas.
  bool get isMainCanvas => type == EditorTabType.mainCanvas;

  /// Whether this tab is an icon design studio canvas.
  bool get isIconCanvas => type == EditorTabType.iconCanvas;

  /// Creates a copy of this tab with updated fields.
  EditorTab copyWith({
    String? id,
    String? title,
    EditorTabType? type,
    double? iconSize,
    List<DesignNode>? nodes,
    bool? isClosable,
    bool? isModified,
    bool? showPixelGrid,
    bool? showSubpixelGrid,
    bool? showKeylines,
    bool? showCenterAxes,
    bool? snapToPixel,
    Color? backgroundColor,
    bool clearBackgroundColor = false,
  }) {
    return EditorTab(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      iconSize: iconSize ?? this.iconSize,
      nodes: nodes ?? this.nodes,
      isClosable: isClosable ?? this.isClosable,
      isModified: isModified ?? this.isModified,
      showPixelGrid: showPixelGrid ?? this.showPixelGrid,
      showSubpixelGrid: showSubpixelGrid ?? this.showSubpixelGrid,
      showKeylines: showKeylines ?? this.showKeylines,
      showCenterAxes: showCenterAxes ?? this.showCenterAxes,
      snapToPixel: snapToPixel ?? this.snapToPixel,
      backgroundColor: clearBackgroundColor
          ? null
          : (backgroundColor ?? this.backgroundColor),
    );
  }

  /// Serializes this tab to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'iconSize': iconSize,
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'isClosable': isClosable,
    'isModified': isModified,
    'showPixelGrid': showPixelGrid,
    'showSubpixelGrid': showSubpixelGrid,
    'showKeylines': showKeylines,
    'showCenterAxes': showCenterAxes,
    'snapToPixel': snapToPixel,
    if (backgroundColor != null) 'backgroundColor': backgroundColor!.toARGB32(),
  };

  /// Deserializes a tab from JSON.
  factory EditorTab.fromJson(Map<String, dynamic> json) {
    return EditorTab(
      id: json['id'] as String? ?? 'tab',
      title: json['title'] as String? ?? 'Canvas',
      type: EditorTabType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => EditorTabType.mainCanvas,
      ),
      iconSize: (json['iconSize'] as num?)?.toDouble() ?? 24.0,
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((item) => DesignNode.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      isClosable: json['isClosable'] as bool? ?? true,
      isModified: json['isModified'] as bool? ?? false,
      showPixelGrid: json['showPixelGrid'] as bool? ?? true,
      showSubpixelGrid: json['showSubpixelGrid'] as bool? ?? false,
      showKeylines: json['showKeylines'] as bool? ?? true,
      showCenterAxes: json['showCenterAxes'] as bool? ?? true,
      snapToPixel: json['snapToPixel'] as bool? ?? true,
      backgroundColor: json.containsKey('backgroundColor') && json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorTab &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          type == other.type &&
          iconSize == other.iconSize &&
          isClosable == other.isClosable &&
          isModified == other.isModified &&
          showPixelGrid == other.showPixelGrid &&
          showSubpixelGrid == other.showSubpixelGrid &&
          showKeylines == other.showKeylines &&
          showCenterAxes == other.showCenterAxes &&
          snapToPixel == other.snapToPixel &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        type,
        iconSize,
        isClosable,
        isModified,
        showPixelGrid,
        showSubpixelGrid,
        showKeylines,
        showCenterAxes,
        snapToPixel,
        backgroundColor,
      );
}
