import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Handles 2D coordinate space transformation between Screen Viewport and Document Space.
class CanvasTransform {
  final double zoom;
  final Offset panOffset;

  const CanvasTransform({this.zoom = 1.0, this.panOffset = Offset.zero});

  /// Converts a screen/viewport point to document/canvas coordinates.
  Offset screenToDoc(Offset screenPoint) {
    return (screenPoint - panOffset) / zoom;
  }

  /// Converts a document/canvas point to screen/viewport coordinates.
  Offset docToScreen(Offset docPoint) {
    return (docPoint * zoom) + panOffset;
  }

  /// Converts a screen delta (e.g. drag distance) to document delta.
  Offset screenDeltaToDoc(Offset screenDelta) {
    return screenDelta / zoom;
  }

  /// Converts a document Rect to screen Rect.
  Rect docToScreenRect(Rect docRect) {
    final topLeft = docToScreen(docRect.topLeft);
    return Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      docRect.width * zoom,
      docRect.height * zoom,
    );
  }

  /// Converts a screen Rect (such as a marquee drag box) to document Rect.
  Rect screenToDocRect(Rect screenRect) {
    final topLeft = screenToDoc(screenRect.topLeft);
    return Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      screenRect.width / zoom,
      screenRect.height / zoom,
    );
  }

  CanvasTransform copyWith({double? zoom, Offset? panOffset}) {
    return CanvasTransform(
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
    );
  }
}

/// Utility for rotational and 2D bounding math.
class GeometryMath {
  GeometryMath._();

  static const double degToRad = math.pi / 180.0;
  static const double radToDeg = 180.0 / math.pi;

  /// Rotates a point around a pivot point by given angle in degrees.
  static Offset rotatePoint(Offset point, Offset pivot, double degrees) {
    if (degrees == 0.0) return point;
    final rad = degrees * degToRad;
    final cosA = math.cos(rad);
    final sinA = math.sin(rad);

    final dx = point.dx - pivot.dx;
    final dy = point.dy - pivot.dy;

    return Offset(
      pivot.dx + (dx * cosA - dy * sinA),
      pivot.dy + (dx * sinA + dy * cosA),
    );
  }

  /// Calculates the AABB (Axis-Aligned Bounding Box) for a rotated rectangle.
  static Rect getRotatedAABB(Rect rect, double degrees) {
    if (degrees == 0.0) return rect;
    final center = rect.center;

    final tl = rotatePoint(rect.topLeft, center, degrees);
    final tr = rotatePoint(rect.topRight, center, degrees);
    final br = rotatePoint(rect.bottomRight, center, degrees);
    final bl = rotatePoint(rect.bottomLeft, center, degrees);

    final minX = math.min(math.min(tl.dx, tr.dx), math.min(br.dx, bl.dx));
    final maxX = math.max(math.max(tl.dx, tr.dx), math.max(br.dx, bl.dx));
    final minY = math.min(math.min(tl.dy, tr.dy), math.min(br.dy, bl.dy));
    final maxY = math.max(math.max(tl.dy, tr.dy), math.max(br.dy, bl.dy));

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
