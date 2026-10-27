import 'package:flutter/material.dart';
import 'node_types.dart';
import 'paint_styles.dart';
import 'constraints.dart';
import 'layout_config.dart';
import 'vector_data.dart';
import 'text_data.dart';
import 'component_model.dart';

class DesignNode {
  final String id;
  final NodeType type;
  final String name;
  final String? parentId;
  final List<String> childrenIds;

  // Geometry
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation; // in degrees
  final double opacity;
  final bool isVisible;
  final bool isLocked;

  // Appearance
  final List<DesignFill> fills;
  final List<DesignStroke> strokes;
  final List<DesignEffect> effects;
  final CornerRadii cornerRadii;
  final bool clipContent;

  // Responsive Layout
  final LayoutConstraints constraints;
  final AutoLayoutConfig layoutConfig;

  // Type Specific Attributes
  final int polygonSides;
  final int starPoints;
  final double starInnerRadiusRatio;
  final VectorPathData? vectorData;
  final TextNodeData? textData;
  final String? imagePath;
  final String? svgContent;
  final ComponentInstanceData? componentData;
  final String? annotationNote;

  const DesignNode({
    required this.id,
    required this.type,
    required this.name,
    this.parentId,
    this.childrenIds = const [],
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.isVisible = true,
    this.isLocked = false,
    this.fills = const [],
    this.strokes = const [],
    this.effects = const [],
    this.cornerRadii = const CornerRadii(),
    this.clipContent = false,
    this.constraints = const LayoutConstraints(),
    this.layoutConfig = const AutoLayoutConfig(),
    this.polygonSides = 5,
    this.starPoints = 5,
    this.starInnerRadiusRatio = 0.382,
    this.vectorData,
    this.textData,
    this.imagePath,
    this.svgContent,
    this.componentData,
    this.annotationNote,
  });

  Rect get rect => Rect.fromLTWH(x, y, width, height);

  DesignNode copyWith({
    String? id,
    NodeType? type,
    String? name,
    String? parentId,
    bool clearParent = false,
    List<String>? childrenIds,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    double? opacity,
    bool? isVisible,
    bool? isLocked,
    List<DesignFill>? fills,
    List<DesignStroke>? strokes,
    List<DesignEffect>? effects,
    CornerRadii? cornerRadii,
    bool? clipContent,
    LayoutConstraints? constraints,
    AutoLayoutConfig? layoutConfig,
    int? polygonSides,
    int? starPoints,
    double? starInnerRadiusRatio,
    VectorPathData? vectorData,
    TextNodeData? textData,
    String? imagePath,
    String? svgContent,
    ComponentInstanceData? componentData,
    String? annotationNote,
  }) {
    return DesignNode(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      childrenIds: childrenIds ?? this.childrenIds,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      fills: fills ?? this.fills,
      strokes: strokes ?? this.strokes,
      effects: effects ?? this.effects,
      cornerRadii: cornerRadii ?? this.cornerRadii,
      clipContent: clipContent ?? this.clipContent,
      constraints: constraints ?? this.constraints,
      layoutConfig: layoutConfig ?? this.layoutConfig,
      polygonSides: polygonSides ?? this.polygonSides,
      starPoints: starPoints ?? this.starPoints,
      starInnerRadiusRatio: starInnerRadiusRatio ?? this.starInnerRadiusRatio,
      vectorData: vectorData ?? this.vectorData,
      textData: textData ?? this.textData,
      imagePath: imagePath ?? this.imagePath,
      svgContent: svgContent ?? this.svgContent,
      componentData: componentData ?? this.componentData,
      annotationNote: annotationNote ?? this.annotationNote,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    if (parentId != null) 'parentId': parentId,
    'childrenIds': childrenIds,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'opacity': opacity,
    'isVisible': isVisible,
    'isLocked': isLocked,
    'fills': fills.map((f) => f.toJson()).toList(),
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'effects': effects.map((e) => e.toJson()).toList(),
    'cornerRadii': cornerRadii.toJson(),
    'clipContent': clipContent,
    'constraints': constraints.toJson(),
    'layoutConfig': layoutConfig.toJson(),
    'polygonSides': polygonSides,
    'starPoints': starPoints,
    'starInnerRadiusRatio': starInnerRadiusRatio,
    if (vectorData != null) 'vectorData': vectorData!.toJson(),
    if (textData != null) 'textData': textData!.toJson(),
    if (imagePath != null) 'imagePath': imagePath,
    if (svgContent != null) 'svgContent': svgContent,
    if (componentData != null) 'componentData': componentData!.toJson(),
    if (annotationNote != null) 'annotationNote': annotationNote,
  };

  factory DesignNode.fromJson(Map<String, dynamic> json) {
    return DesignNode(
      id: json['id'] as String,
      type: NodeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NodeType.rectangle,
      ),
      name: json['name'] as String? ?? 'Layer',
      parentId: json['parentId'] as String?,
      childrenIds: (json['childrenIds'] as List? ?? []).cast<String>(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 100.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      fills: (json['fills'] as List? ?? [])
          .map((f) => DesignFill.fromJson(f as Map<String, dynamic>))
          .toList(),
      strokes: (json['strokes'] as List? ?? [])
          .map((s) => DesignStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      effects: (json['effects'] as List? ?? [])
          .map((e) => DesignEffect.fromJson(e as Map<String, dynamic>))
          .toList(),
      cornerRadii: json['cornerRadii'] != null
          ? CornerRadii.fromJson(json['cornerRadii'] as Map<String, dynamic>)
          : const CornerRadii(),
      clipContent: json['clipContent'] as bool? ?? false,
      constraints: json['constraints'] != null
          ? LayoutConstraints.fromJson(
              json['constraints'] as Map<String, dynamic>,
            )
          : const LayoutConstraints(),
      layoutConfig: json['layoutConfig'] != null
          ? AutoLayoutConfig.fromJson(
              json['layoutConfig'] as Map<String, dynamic>,
            )
          : const AutoLayoutConfig(),
      polygonSides: json['polygonSides'] as int? ?? 5,
      starPoints: json['starPoints'] as int? ?? 5,
      starInnerRadiusRatio:
          (json['starInnerRadiusRatio'] as num?)?.toDouble() ?? 0.382,
      vectorData: json['vectorData'] != null
          ? VectorPathData.fromJson(json['vectorData'] as Map<String, dynamic>)
          : null,
      textData: json['textData'] != null
          ? TextNodeData.fromJson(json['textData'] as Map<String, dynamic>)
          : null,
      imagePath: json['imagePath'] as String?,
      svgContent: json['svgContent'] as String?,
      componentData: json['componentData'] != null
          ? ComponentInstanceData.fromJson(
              json['componentData'] as Map<String, dynamic>,
            )
          : null,
      annotationNote: json['annotationNote'] as String?,
    );
  }
}
