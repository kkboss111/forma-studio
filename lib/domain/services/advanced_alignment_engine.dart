import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/node_model.dart';

/// Exhaustive, deterministic alignment & geometric distribution engine for Forma Studio.
/// Encapsulates multi-rule edge constraints, center snaps, relative bounds,
/// and equalized dimension scaling (match widths/heights/min/max).
class AdvancedAlignmentEngine {
  AdvancedAlignmentEngine._();

  /// Align nodes along a specific spatial edge or center axis.
  /// If [selectedNodes] has 1 element, aligns relative to [parentBounds].
  /// If > 1 element, aligns relative to collective bounding box or primary anchor.
  static Map<String, Offset> calculateAlignedOffsets({
    required List<DesignNode> selectedNodes,
    required Rect referenceBounds,
    required String alignmentType,
  }) {
    if (selectedNodes.isEmpty) return {};

    final Map<String, Offset> targetPositions = {};

    for (final node in selectedNodes) {
      double targetX = node.x;
      double targetY = node.y;

      switch (alignmentType) {
        case 'left':
          targetX = referenceBounds.left;
          break;
        case 'centerHorizontal':
          targetX = referenceBounds.left + (referenceBounds.width - node.width) / 2.0;
          break;
        case 'right':
          targetX = referenceBounds.right - node.width;
          break;
        case 'top':
          targetY = referenceBounds.top;
          break;
        case 'centerVertical':
          targetY = referenceBounds.top + (referenceBounds.height - node.height) / 2.0;
          break;
        case 'bottom':
          targetY = referenceBounds.bottom - node.height;
          break;
      }

      targetPositions[node.id] = Offset(targetX, targetY);
    }

    return targetPositions;
  }

  /// Distribute 3+ nodes with exact equal spacing along horizontal or vertical axes.
  static Map<String, Offset> calculateDistributedOffsets({
    required List<DesignNode> selectedNodes,
    required String axis, // 'horizontal' or 'vertical'
  }) {
    if (selectedNodes.length < 3) return {};

    final sorted = List<DesignNode>.from(selectedNodes);
    final Map<String, Offset> targetPositions = {};

    if (axis == 'horizontal') {
      sorted.sort((a, b) => a.x.compareTo(b.x));
      final totalWidth = sorted.map((n) => n.width).reduce((a, b) => a + b);
      final span = (sorted.last.x + sorted.last.width) - sorted.first.x;
      final gap = (span - totalWidth) / (sorted.length - 1);

      double curX = sorted.first.x;
      for (final node in sorted) {
        targetPositions[node.id] = Offset(curX, node.y);
        curX += node.width + gap;
      }
    } else {
      sorted.sort((a, b) => a.y.compareTo(b.y));
      final totalHeight = sorted.map((n) => n.height).reduce((a, b) => a + b);
      final span = (sorted.last.y + sorted.last.height) - sorted.first.y;
      final gap = (span - totalHeight) / (sorted.length - 1);

      double curY = sorted.first.y;
      for (final node in sorted) {
        targetPositions[node.id] = Offset(node.x, curY);
        curY += node.height + gap;
      }
    }

    return targetPositions;
  }

  /// Equalizes dimensions (Same Width, Same Height, Max Width, Min Width, Square Aspect)
  static Map<String, Size> calculateDimensionMatches({
    required List<DesignNode> selectedNodes,
    required String matchType, // 'sameWidth', 'sameHeight', 'sameBoth', 'makeSquare'
  }) {
    if (selectedNodes.length < 2 && matchType != 'makeSquare') return {};

    final Map<String, Size> targetSizes = {};

    // First node or max node acts as reference
    final refWidth = selectedNodes.first.width;
    final refHeight = selectedNodes.first.height;
    final maxWidth = selectedNodes.map((n) => n.width).reduce(math.max);
    final maxHeight = selectedNodes.map((n) => n.height).reduce(math.max);

    for (final node in selectedNodes) {
      double w = node.width;
      double h = node.height;

      switch (matchType) {
        case 'sameWidth':
          w = refWidth;
          break;
        case 'sameHeight':
          h = refHeight;
          break;
        case 'maxWidth':
          w = maxWidth;
          break;
        case 'maxHeight':
          h = maxHeight;
          break;
        case 'sameBoth':
          w = refWidth;
          h = refHeight;
          break;
        case 'makeSquare':
          final side = math.max(w, h);
          w = side;
          h = side;
          break;
      }

      targetSizes[node.id] = Size(math.max(1.0, w), math.max(1.0, h));
    }

    return targetSizes;
  }
}
