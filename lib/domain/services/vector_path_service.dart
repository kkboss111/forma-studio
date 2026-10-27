import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/vector_data.dart';

enum VectorHandleTarget {
  none,
  anchorPoint,
  handleIn,
  handleOut,
}

class VectorPathService {
  VectorPathService._();

  /// Updates an anchor point position. If `moveHandles` is true,
  /// offsets both handleIn and handleOut by the same delta.
  static VectorPathData updateAnchorPoint({
    required VectorPathData pathData,
    required int index,
    required Offset newPoint,
    bool moveHandles = true,
  }) {
    if (index < 0 || index >= pathData.anchors.length) return pathData;

    final oldAnchor = pathData.anchors[index];
    final delta = newPoint - oldAnchor.point;

    final updated = oldAnchor.copyWith(
      point: newPoint,
      handleIn: (oldAnchor.handleIn != null && moveHandles)
          ? oldAnchor.handleIn! + delta
          : oldAnchor.handleIn,
      handleOut: (oldAnchor.handleOut != null && moveHandles)
          ? oldAnchor.handleOut! + delta
          : oldAnchor.handleOut,
    );

    final newAnchors = List<VectorAnchor>.from(pathData.anchors);
    newAnchors[index] = updated;

    return VectorPathData(
      anchors: newAnchors,
      isClosed: pathData.isClosed,
    );
  }

  /// Updates incoming handle. If `isSmooth` is true, mirror-updates handleOut.
  static VectorPathData updateHandleIn({
    required VectorPathData pathData,
    required int index,
    required Offset? newHandleIn,
  }) {
    if (index < 0 || index >= pathData.anchors.length) return pathData;

    final anchor = pathData.anchors[index];
    Offset? mirrorOut = anchor.handleOut;

    if (anchor.isSmooth && newHandleIn != null) {
      final delta = newHandleIn - anchor.point;
      mirrorOut = anchor.point - delta;
    }

    final updated = anchor.copyWith(
      handleIn: newHandleIn,
      handleOut: mirrorOut,
    );

    final newAnchors = List<VectorAnchor>.from(pathData.anchors);
    newAnchors[index] = updated;

    return VectorPathData(
      anchors: newAnchors,
      isClosed: pathData.isClosed,
    );
  }

  /// Updates outgoing handle. If `isSmooth` is true, mirror-updates handleIn.
  static VectorPathData updateHandleOut({
    required VectorPathData pathData,
    required int index,
    required Offset? newHandleOut,
  }) {
    if (index < 0 || index >= pathData.anchors.length) return pathData;

    final anchor = pathData.anchors[index];
    Offset? mirrorIn = anchor.handleIn;

    if (anchor.isSmooth && newHandleOut != null) {
      final delta = newHandleOut - anchor.point;
      mirrorIn = anchor.point - delta;
    }

    final updated = anchor.copyWith(
      handleOut: newHandleOut,
      handleIn: mirrorIn,
    );

    final newAnchors = List<VectorAnchor>.from(pathData.anchors);
    newAnchors[index] = updated;

    return VectorPathData(
      anchors: newAnchors,
      isClosed: pathData.isClosed,
    );
  }

  /// Toggles between Corner (sharp, no handles) and Smooth (mirrored bezier handles).
  static VectorPathData toggleAnchorSmoothness({
    required VectorPathData pathData,
    required int index,
  }) {
    if (index < 0 || index >= pathData.anchors.length) return pathData;

    final anchor = pathData.anchors[index];
    final newSmooth = !anchor.isSmooth;

    Offset? newIn;
    Offset? newOut;

    if (newSmooth) {
      // Calculate tangent using previous and next points
      final prevIndex = (index - 1 + pathData.anchors.length) % pathData.anchors.length;
      final nextIndex = (index + 1) % pathData.anchors.length;
      final prev = pathData.anchors[prevIndex].point;
      final next = pathData.anchors[nextIndex].point;

      final tangent = (next - prev);
      final len = tangent.distance;
      if (len > 0.001) {
        final unitTangent = tangent / len;
        final handleDist = math.min(30.0, len * 0.25);
        newIn = anchor.point - unitTangent * handleDist;
        newOut = anchor.point + unitTangent * handleDist;
      }
    }

    final updated = VectorAnchor(
      point: anchor.point,
      handleIn: newIn,
      handleOut: newOut,
      isSmooth: newSmooth,
    );

    final newAnchors = List<VectorAnchor>.from(pathData.anchors);
    newAnchors[index] = updated;

    return VectorPathData(
      anchors: newAnchors,
      isClosed: pathData.isClosed,
    );
  }

  /// Adds a new anchor point at the end or inserts at closest segment.
  static VectorPathData addAnchor(VectorPathData pathData, Offset point) {
    final newAnchors = List<VectorAnchor>.from(pathData.anchors);
    newAnchors.add(VectorAnchor(point: point));
    return VectorPathData(anchors: newAnchors, isClosed: pathData.isClosed);
  }

  /// Deletes an anchor point at index.
  static VectorPathData deleteAnchor(VectorPathData pathData, int index) {
    if (index < 0 || index >= pathData.anchors.length || pathData.anchors.length <= 2) {
      return pathData;
    }
    final newAnchors = List<VectorAnchor>.from(pathData.anchors)..removeAt(index);
    return VectorPathData(anchors: newAnchors, isClosed: pathData.isClosed);
  }

  /// Toggles path closed / open status.
  static VectorPathData toggleClosed(VectorPathData pathData) {
    return VectorPathData(
      anchors: pathData.anchors,
      isClosed: !pathData.isClosed,
    );
  }

  /// Performs boolean operation (Union, Difference/Subtract, Intersect, Xor)
  /// between two paths using Flutter's native Path.combine engine.
  static Path combinePaths(Path path1, Path path2, PathOperation operation) {
    return Path.combine(operation, path1, path2);
  }
}
