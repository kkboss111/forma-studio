import '../../domain/models/node_model.dart';
import '../../domain/models/layout_config.dart';
import '../../domain/models/constraints.dart';

class LayoutEngine {
  LayoutEngine._();

  /// Recalculates child node positions and sizes inside an auto-layout frame.
  static Map<String, DesignNode> computeAutoLayout({
    required DesignNode frame,
    required List<DesignNode> children,
  }) {
    if (!frame.layoutConfig.enabled || children.isEmpty) {
      return {for (var c in children) c.id: c};
    }

    final config = frame.layoutConfig;
    final isHorizontal = config.direction == AutoLayoutDirection.horizontal;
    final updated = <String, DesignNode>{};

    double currentOffset = isHorizontal
        ? config.paddingLeft
        : config.paddingTop;

    // Total content size along main axis
    double totalChildMainSize = 0;
    for (final child in children) {
      totalChildMainSize += isHorizontal ? child.width : child.height;
    }
    final totalGaps = config.gap * (children.length - 1);
    final availableSpace =
        (isHorizontal ? frame.width : frame.height) -
        (isHorizontal
            ? (config.paddingLeft + config.paddingRight)
            : (config.paddingTop + config.paddingBottom));

    double actualGap = config.gap;
    if (config.mainAxisAlignment == AutoLayoutAlignment.spaceBetween &&
        children.length > 1) {
      actualGap = (availableSpace - totalChildMainSize) / (children.length - 1);
    } else if (config.mainAxisAlignment == AutoLayoutAlignment.center) {
      final freeSpace = availableSpace - (totalChildMainSize + totalGaps);
      if (freeSpace > 0) {
        currentOffset += freeSpace / 2;
      }
    } else if (config.mainAxisAlignment == AutoLayoutAlignment.end) {
      final freeSpace = availableSpace - (totalChildMainSize + totalGaps);
      if (freeSpace > 0) {
        currentOffset += freeSpace;
      }
    }

    for (final child in children) {
      double childX = child.x;
      double childY = child.y;
      double childW = child.width;
      double childH = child.height;

      if (isHorizontal) {
        childX = frame.x + currentOffset;
        currentOffset += childW + actualGap;

        // Cross axis alignment (Y)
        final crossAvail =
            frame.height - (config.paddingTop + config.paddingBottom);
        switch (config.crossAxisAlignment) {
          case AutoLayoutCrossAlignment.start:
            childY = frame.y + config.paddingTop;
            break;
          case AutoLayoutCrossAlignment.center:
            childY = frame.y + config.paddingTop + (crossAvail - childH) / 2;
            break;
          case AutoLayoutCrossAlignment.end:
            childY = frame.y + frame.height - config.paddingBottom - childH;
            break;
          case AutoLayoutCrossAlignment.stretch:
            childY = frame.y + config.paddingTop;
            childH = crossAvail;
            break;
        }
      } else {
        // Vertical
        childY = frame.y + currentOffset;
        currentOffset += childH + actualGap;

        // Cross axis alignment (X)
        final crossAvail =
            frame.width - (config.paddingLeft + config.paddingRight);
        switch (config.crossAxisAlignment) {
          case AutoLayoutCrossAlignment.start:
            childX = frame.x + config.paddingLeft;
            break;
          case AutoLayoutCrossAlignment.center:
            childX = frame.x + config.paddingLeft + (crossAvail - childW) / 2;
            break;
          case AutoLayoutCrossAlignment.end:
            childX = frame.x + frame.width - config.paddingRight - childW;
            break;
          case AutoLayoutCrossAlignment.stretch:
            childX = frame.x + config.paddingLeft;
            childW = crossAvail;
            break;
        }
      }

      updated[child.id] = child.copyWith(
        x: childX,
        y: childY,
        width: childW,
        height: childH,
      );
    }

    return updated;
  }

  /// Adjusts child nodes when their parent frame dimensions change, according to constraints.
  static DesignNode applyConstraintsOnParentResize({
    required DesignNode child,
    required double oldParentW,
    required double oldParentH,
    required double newParentW,
    required double newParentH,
  }) {
    final dw = newParentW - oldParentW;
    final dh = newParentH - oldParentH;

    double newX = child.x;
    double newY = child.y;
    double newW = child.width;
    double newH = child.height;

    // Horizontal Constraint
    switch (child.constraints.horizontal) {
      case HorizontalConstraint.left:
        // Stays pinned to left
        break;
      case HorizontalConstraint.right:
        newX += dw;
        break;
      case HorizontalConstraint.center:
        newX += dw / 2;
        break;
      case HorizontalConstraint.stretch:
        newW += dw;
        break;
      case HorizontalConstraint.scale:
        if (oldParentW > 0) {
          final ratioX = newParentW / oldParentW;
          newX = child.x * ratioX;
          newW = child.width * ratioX;
        }
        break;
    }

    // Vertical Constraint
    switch (child.constraints.vertical) {
      case VerticalConstraint.top:
        // Stays pinned to top
        break;
      case VerticalConstraint.bottom:
        newY += dh;
        break;
      case VerticalConstraint.center:
        newY += dh / 2;
        break;
      case VerticalConstraint.stretch:
        newH += dh;
        break;
      case VerticalConstraint.scale:
        if (oldParentH > 0) {
          final ratioY = newParentH / oldParentH;
          newY = child.y * ratioY;
          newH = child.height * ratioY;
        }
        break;
    }

    return child.copyWith(x: newX, y: newY, width: newW, height: newH);
  }
}
