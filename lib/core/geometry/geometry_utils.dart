import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/node_model.dart';
import 'transform2d.dart';

enum ResizeHandleType {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
  rotation,
}

class HandleInfo {
  final ResizeHandleType type;
  final Offset position;
  final Rect touchRect;

  const HandleInfo({
    required this.type,
    required this.position,
    required this.touchRect,
  });
}

class SnapGuide {
  final bool isVertical;
  final double position;
  final double start;
  final double end;

  const SnapGuide({
    required this.isVertical,
    required this.position,
    required this.start,
    required this.end,
  });
}

class GeometryUtils {
  GeometryUtils._();

  /// Returns 8 bounding handles plus rotation handle for a given document Rect.
  static List<HandleInfo> getSelectionHandles(
    Rect rect, {
    double handleSize = 10.0,
    double rotationOffset = 24.0,
  }) {
    Offset getHandlePos(ResizeHandleType type) {
      switch (type) {
        case ResizeHandleType.topLeft:
          return rect.topLeft;
        case ResizeHandleType.topCenter:
          return Offset(rect.center.dx, rect.top);
        case ResizeHandleType.topRight:
          return rect.topRight;
        case ResizeHandleType.centerLeft:
          return Offset(rect.left, rect.center.dy);
        case ResizeHandleType.centerRight:
          return Offset(rect.right, rect.center.dy);
        case ResizeHandleType.bottomLeft:
          return rect.bottomLeft;
        case ResizeHandleType.bottomCenter:
          return Offset(rect.center.dx, rect.bottom);
        case ResizeHandleType.bottomRight:
          return rect.bottomRight;
        case ResizeHandleType.rotation:
          return Offset(rect.center.dx, rect.top - rotationOffset);
      }
    }

    return ResizeHandleType.values.map((type) {
      final pos = getHandlePos(type);
      return HandleInfo(
        type: type,
        position: pos,
        touchRect: Rect.fromCenter(
          center: pos,
          width: handleSize * 2,
          height: handleSize * 2,
        ),
      );
    }).toList();
  }

  /// Calculates the union bounding box of a list of nodes.
  static Rect? getCollectiveBoundingBox(Iterable<DesignNode> nodes) {
    if (nodes.isEmpty) return null;
    Rect? bounds;
    for (final node in nodes) {
      final nodeAABB = GeometryMath.getRotatedAABB(node.rect, node.rotation);
      bounds = bounds == null ? nodeAABB : bounds.expandToInclude(nodeAABB);
    }
    return bounds;
  }

  /// Hit-tests a document point against a node.
  static bool hitTestNode(Offset point, DesignNode node) {
    if (!node.isVisible) return false;

    // Invert rotation to test against unrotated local rect
    final localPoint = GeometryMath.rotatePoint(
      point,
      node.rect.center,
      -node.rotation,
    );
    return node.rect.contains(localPoint);
  }

  /// Finds top-most hit node from a list of nodes (drawn back to front).
  static DesignNode? hitTestNodes(Offset docPoint, List<DesignNode> nodes) {
    // Reverse to test topmost (drawn last) first
    for (final node in nodes.reversed) {
      if (hitTestNode(docPoint, node)) {
        return node;
      }
    }
    return null;
  }

  /// Snapping logic: Snaps an active rectangle against static reference bounds or grid.
  static Offset snapDelta({
    required Rect activeRect,
    required Offset rawDelta,
    required List<Rect> staticRects,
    double snapThreshold = 6.0,
    bool snapToGrid = false,
    double gridSize = 8.0,
    required List<SnapGuide> outGuides,
  }) {
    outGuides.clear();
    double dx = rawDelta.dx;
    double dy = rawDelta.dy;

    final testRect = activeRect.shift(rawDelta);

    if (snapToGrid && gridSize > 1.0) {
      final nearestX = (testRect.left / gridSize).round() * gridSize;
      final nearestY = (testRect.top / gridSize).round() * gridSize;

      if ((testRect.left - nearestX).abs() < snapThreshold) {
        dx = nearestX - activeRect.left;
        outGuides.add(
          SnapGuide(
            isVertical: true,
            position: nearestX,
            start: testRect.top - 20,
            end: testRect.bottom + 20,
          ),
        );
      }
      if ((testRect.top - nearestY).abs() < snapThreshold) {
        dy = nearestY - activeRect.top;
        outGuides.add(
          SnapGuide(
            isVertical: false,
            position: nearestY,
            start: testRect.left - 20,
            end: testRect.right + 20,
          ),
        );
      }
      return Offset(dx, dy);
    }

    // Snapping against static rects (edges & centers)
    double minDiffX = snapThreshold;
    double minDiffY = snapThreshold;
    double? snappedDx;
    double? snappedDy;

    for (final target in staticRects) {
      // X edges: left-left, left-right, center-center, right-left, right-right
      final xTests = [
        (
          testRect.left - target.left,
          target.left,
          target.left - activeRect.left,
        ),
        (
          testRect.left - target.right,
          target.right,
          target.right - activeRect.left,
        ),
        (
          testRect.center.dx - target.center.dx,
          target.center.dx,
          target.center.dx - activeRect.center.dx,
        ),
        (
          testRect.right - target.left,
          target.left,
          target.left - activeRect.right,
        ),
        (
          testRect.right - target.right,
          target.right,
          target.right - activeRect.right,
        ),
      ];

      for (final test in xTests) {
        if (test.$1.abs() < minDiffX) {
          minDiffX = test.$1.abs();
          snappedDx = test.$3;
          outGuides.add(
            SnapGuide(
              isVertical: true,
              position: test.$2,
              start: math.min(testRect.top, target.top) - 10,
              end: math.max(testRect.bottom, target.bottom) + 10,
            ),
          );
        }
      }

      // Y edges: top-top, top-bottom, center-center, bottom-top, bottom-bottom
      final yTests = [
        (testRect.top - target.top, target.top, target.top - activeRect.top),
        (
          testRect.top - target.bottom,
          target.bottom,
          target.bottom - activeRect.top,
        ),
        (
          testRect.center.dy - target.center.dy,
          target.center.dy,
          target.center.dy - activeRect.center.dy,
        ),
        (
          testRect.bottom - target.top,
          target.top,
          target.top - activeRect.bottom,
        ),
        (
          testRect.bottom - target.bottom,
          target.bottom,
          target.bottom - activeRect.bottom,
        ),
      ];

      for (final test in yTests) {
        if (test.$1.abs() < minDiffY) {
          minDiffY = test.$1.abs();
          snappedDy = test.$3;
          outGuides.add(
            SnapGuide(
              isVertical: false,
              position: test.$2,
              start: math.min(testRect.left, target.left) - 10,
              end: math.max(testRect.right, target.right) + 10,
            ),
          );
        }
      }
    }

    return Offset(snappedDx ?? dx, snappedDy ?? dy);
  }
}
