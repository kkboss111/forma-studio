import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PageModel {
  final String id;
  final String name;
  final Color backgroundColor;
  final bool showGrid;
  final double gridSize;
  final bool snapToGrid;
  final List<String> rootNodeIds;

  const PageModel({
    required this.id,
    required this.name,
    this.backgroundColor = const Color(0xFFF0F4FA),
    this.showGrid = true,
    this.gridSize = 8.0,
    this.snapToGrid = false,
    this.rootNodeIds = const [],
  });

  PageModel copyWith({
    String? id,
    String? name,
    Color? backgroundColor,
    bool? showGrid,
    double? gridSize,
    bool? snapToGrid,
    List<String>? rootNodeIds,
  }) {
    return PageModel(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showGrid: showGrid ?? this.showGrid,
      gridSize: gridSize ?? this.gridSize,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      rootNodeIds: rootNodeIds ?? this.rootNodeIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'backgroundColor': backgroundColor.toARGB32(),
    'showGrid': showGrid,
    'gridSize': gridSize,
    'snapToGrid': snapToGrid,
    'rootNodeIds': rootNodeIds,
  };

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Page 1',
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFFF0F4FA),
      showGrid: json['showGrid'] as bool? ?? true,
      gridSize: (json['gridSize'] as num?)?.toDouble() ?? 8.0,
      snapToGrid: json['snapToGrid'] as bool? ?? false,
      rootNodeIds: (json['rootNodeIds'] as List? ?? []).cast<String>(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          backgroundColor == other.backgroundColor &&
          showGrid == other.showGrid &&
          gridSize == other.gridSize &&
          snapToGrid == other.snapToGrid &&
          listEquals(rootNodeIds, other.rootNodeIds);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        backgroundColor,
        showGrid,
        gridSize,
        snapToGrid,
        Object.hashAll(rootNodeIds),
      );
}
