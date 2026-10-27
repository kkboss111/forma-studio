import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../domain/models/project_model.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/page_model.dart';
import '../../../../domain/services/node_render_service.dart';
import '../../../../core/geometry/geometry_utils.dart';
import '../../../../app/theme/forma_colors.dart';

class CanvasPainter extends CustomPainter {
  final ProjectModel project;
  final PageModel page;
  final Set<String> selectedNodeIds;
  final String? hoveredNodeId;
  final double zoom;
  final Offset panOffset;
  final Rect? marqueeRect;
  final List<SnapGuide> snapGuides;
  final bool isDevInspectMode;
  final String? editingVectorNodeId;
  final int? selectedAnchorIndex;

  CanvasPainter({
    required this.project,
    required this.page,
    required this.selectedNodeIds,
    this.hoveredNodeId,
    required this.zoom,
    required this.panOffset,
    this.marqueeRect,
    this.snapGuides = const [],
    this.isDevInspectMode = false,
    this.editingVectorNodeId,
    this.selectedAnchorIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw canvas background
    final bgPaint = Paint()..color = page.backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Transform canvas according to Pan & Zoom
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(zoom, zoom);

    // 3. Draw Grid if enabled
    if (page.showGrid && page.gridSize > 0) {
      _drawGrid(canvas, size);
    }

    // 4. Render Document Nodes (drawn in z-order from back to front with frustum culling)
    final rootNodes = page.rootNodeIds
        .map((id) => project.nodes[id])
        .whereType<DesignNode>()
        .toList();

    // Viewport frustum culling for heavy rendering performance optimization
    final minDocX = -panOffset.dx / zoom - 60.0;
    final maxDocX = (size.width - panOffset.dx) / zoom + 60.0;
    final minDocY = -panOffset.dy / zoom - 60.0;
    final maxDocY = (size.height - panOffset.dy) / zoom + 60.0;
    final viewportDocRect = Rect.fromLTRB(minDocX, minDocY, maxDocX, maxDocY);

    for (final node in rootNodes) {
      if (!viewportDocRect.overlaps(node.rect.inflate(50))) continue;
      NodeRenderService.renderNode(canvas, node, project.nodes);
    }

    // 5. Render Selection Outlines and Handles
    if (editingVectorNodeId != null) {
      _drawVectorEditOverlays(canvas);
    } else {
      _drawSelectionOverlays(canvas);
    }

    // 6. Render Snap Guides
    _drawSnapGuides(canvas);

    // 7. Render Prototype Wires
    _drawPrototypeWires(canvas);

    // 8. Render Comments Markers
    _drawComments(canvas);

    // 9. Render Marquee Drag Box
    if (marqueeRect != null) {
      final marqueeFill = Paint()
        ..color = FormaColors.primaryBlue.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      final marqueeStroke = Paint()
        ..color = FormaColors.primaryBlue
        ..strokeWidth = 1.0 / zoom
        ..style = PaintingStyle.stroke;

      canvas.drawRect(marqueeRect!, marqueeFill);
      canvas.drawRect(marqueeRect!, marqueeStroke);
    }

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = FormaColors.canvasGridLight.withValues(alpha: 0.7)
      ..strokeWidth = 0.5 / zoom;

    // Viewport bounds in doc space
    final minDocX = -panOffset.dx / zoom;
    final maxDocX = (size.width - panOffset.dx) / zoom;
    final minDocY = -panOffset.dy / zoom;
    final maxDocY = (size.height - panOffset.dy) / zoom;

    final startX = (minDocX / page.gridSize).floor() * page.gridSize;
    final endX = (maxDocX / page.gridSize).ceil() * page.gridSize;
    final startY = (minDocY / page.gridSize).floor() * page.gridSize;
    final endY = (maxDocY / page.gridSize).ceil() * page.gridSize;

    // Draw grid points for clean Figma-like dot grid or faint lines
    if (zoom >= 0.5) {
      final dotPaint = Paint()
        ..color = FormaColors.lightTextMuted.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      final dotRadius = 1.0 / zoom;

      for (double x = startX; x <= endX; x += page.gridSize * 4) {
        for (double y = startY; y <= endY; y += page.gridSize * 4) {
          canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
        }
      }
    } else {
      for (double x = startX; x <= endX; x += page.gridSize * 8) {
        canvas.drawLine(Offset(x, minDocY), Offset(x, maxDocY), gridPaint);
      }
      for (double y = startY; y <= endY; y += page.gridSize * 8) {
        canvas.drawLine(Offset(minDocX, y), Offset(maxDocX, y), gridPaint);
      }
    }
  }

  void _drawVectorEditOverlays(Canvas canvas) {
    if (editingVectorNodeId == null) return;
    final node = project.nodes[editingVectorNodeId];
    if (node == null || node.vectorData == null) return;

    final anchors = node.vectorData!.anchors;
    final nodeOffset = Offset(node.x, node.y);

    final linePaint = Paint()
      ..color = FormaColors.primaryBlue.withValues(alpha: 0.7)
      ..strokeWidth = 1.0 / zoom;

    final anchorFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final anchorStroke = Paint()
      ..color = FormaColors.primaryBlue
      ..strokeWidth = 1.5 / zoom
      ..style = PaintingStyle.stroke;

    final selectedFill = Paint()
      ..color = FormaColors.primaryBlue
      ..style = PaintingStyle.fill;

    final handleRadius = 4.5 / zoom;

    for (int i = 0; i < anchors.length; i++) {
      final a = anchors[i];
      final pt = nodeOffset + a.point;
      final isSel = (i == selectedAnchorIndex);

      if (isSel) {
        if (a.handleIn != null) {
          final inPt = nodeOffset + a.handleIn!;
          canvas.drawLine(pt, inPt, linePaint);
          canvas.drawCircle(inPt, 3.5 / zoom, selectedFill);
        }
        if (a.handleOut != null) {
          final outPt = nodeOffset + a.handleOut!;
          canvas.drawLine(pt, outPt, linePaint);
          canvas.drawCircle(outPt, 3.5 / zoom, selectedFill);
        }

        canvas.drawCircle(pt, handleRadius + 1.0 / zoom, selectedFill);
        canvas.drawCircle(pt, handleRadius + 1.0 / zoom, anchorStroke);
      } else {
        canvas.drawCircle(pt, handleRadius, anchorFill);
        canvas.drawCircle(pt, handleRadius, anchorStroke);
      }
    }
  }

  void _drawSelectionOverlays(Canvas canvas) {
    if (selectedNodeIds.isEmpty) return;

    final outlinePaint = Paint()
      ..color = FormaColors.primaryBlue
      ..strokeWidth = 1.5 / zoom
      ..style = PaintingStyle.stroke;

    final handleFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final handleStroke = Paint()
      ..color = FormaColors.primaryBlue
      ..strokeWidth = 1.5 / zoom
      ..style = PaintingStyle.stroke;

    final handleSize = 8.0 / zoom;

    // Single or Multi-Selection
    final selectedNodes = selectedNodeIds
        .map((id) => project.nodes[id])
        .whereType<DesignNode>()
        .toList();

    for (final node in selectedNodes) {
      canvas.save();
      if (node.rotation != 0) {
        final center = Offset(
          node.x + node.width / 2,
          node.y + node.height / 2,
        );
        canvas.translate(center.dx, center.dy);
        canvas.rotate(node.rotation * math.pi / 180.0);
        canvas.translate(-center.dx, -center.dy);
      }

      // Draw outline
      canvas.drawRect(node.rect, outlinePaint);

      // If single selection, draw handles
      if (selectedNodes.length == 1 && !node.isLocked) {
        final handles = GeometryUtils.getSelectionHandles(
          node.rect,
          handleSize: handleSize,
        );
        for (final h in handles) {
          if (h.type == ResizeHandleType.rotation) {
            // Draw connector stem and rotation pill
            final stemPaint = Paint()
              ..color = FormaColors.primaryBlue
              ..strokeWidth = 1.0 / zoom;
            canvas.drawLine(
              Offset(node.rect.center.dx, node.rect.top),
              h.position,
              stemPaint,
            );
            canvas.drawCircle(h.position, handleSize / 1.5, handleFill);
            canvas.drawCircle(h.position, handleSize / 1.5, handleStroke);
          } else {
            // Standard corner / edge handle square
            final handleRect = Rect.fromCenter(
              center: h.position,
              width: handleSize,
              height: handleSize,
            );
            canvas.drawRect(handleRect, handleFill);
            canvas.drawRect(handleRect, handleStroke);
          }
        }

        // Draw dimension badge if inspecting
        if (isDevInspectMode) {
          _drawDimensionBadge(canvas, node.rect);
        }
      }

      canvas.restore();
    }

    // If multi-selection, draw collective bounding box
    if (selectedNodes.length > 1) {
      final bounds = GeometryUtils.getCollectiveBoundingBox(selectedNodes);
      if (bounds != null) {
        final multiOutline = Paint()
          ..color = FormaColors.primaryBlue.withValues(alpha: 0.6)
          ..strokeWidth = 1.0 / zoom
          ..style = PaintingStyle.stroke;
        canvas.drawRect(bounds, multiOutline);
      }
    }
  }

  void _drawDimensionBadge(Canvas canvas, Rect rect) {
    final textSpan = TextSpan(
      text:
          '${rect.width.toStringAsFixed(0)} × ${rect.height.toStringAsFixed(0)}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 10 / zoom,
        fontWeight: FontWeight.w600,
      ),
    );
    final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    tp.layout();

    final badgeOffset = Offset(
      rect.center.dx - tp.width / 2,
      rect.bottom + 6 / zoom,
    );
    final badgeRect = Rect.fromLTWH(
      badgeOffset.dx - 4 / zoom,
      badgeOffset.dy - 2 / zoom,
      tp.width + 8 / zoom,
      tp.height + 4 / zoom,
    );

    final badgePaint = Paint()..color = FormaColors.primaryBlue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, Radius.circular(4 / zoom)),
      badgePaint,
    );
    tp.paint(canvas, badgeOffset);
  }

  void _drawSnapGuides(Canvas canvas) {
    if (snapGuides.isEmpty) return;

    final guidePaint = Paint()
      ..color = FormaColors.guidePink
      ..strokeWidth = 1.0 / zoom;

    for (final guide in snapGuides) {
      if (guide.isVertical) {
        canvas.drawLine(
          Offset(guide.position, guide.start),
          Offset(guide.position, guide.end),
          guidePaint,
        );
      } else {
        canvas.drawLine(
          Offset(guide.start, guide.position),
          Offset(guide.end, guide.position),
          guidePaint,
        );
      }
    }
  }

  void _drawPrototypeWires(Canvas canvas) {
    for (final flow in project.flows) {
      for (final inter in flow.interactions) {
        final src = project.nodes[inter.sourceNodeId];
        final tgt = project.nodes[inter.targetFrameId];
        if (src != null && tgt != null) {
          final p1 = src.rect.centerRight;
          final p2 = tgt.rect.centerLeft;

          final wirePaint = Paint()
            ..color = FormaColors.primaryBlue.withValues(alpha: 0.8)
            ..strokeWidth = 2.0 / zoom
            ..style = PaintingStyle.stroke;

          final path = Path();
          path.moveTo(p1.dx, p1.dy);
          final cp1 = Offset(p1.dx + 40, p1.dy);
          final cp2 = Offset(p2.dx - 40, p2.dy);
          path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);

          canvas.drawPath(path, wirePaint);

          // Wire target circle
          final dotPaint = Paint()..color = FormaColors.primaryBlue;
          canvas.drawCircle(p2, 4.0 / zoom, dotPaint);
        }
      }
    }
  }

  void _drawComments(Canvas canvas) {
    final pageComments = project.comments.where(
      (c) => c.pageId == page.id && !c.isResolved,
    );

    for (final comment in pageComments) {
      final pinCenter = Offset(comment.x, comment.y);
      final pinRadius = 14.0 / zoom;

      // Pin circle
      final pinPaint = Paint()..color = FormaColors.warningAmber;
      final pinShadow = Paint()
        ..color = Colors.black26
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 / zoom);

      canvas.drawCircle(pinCenter + Offset(0, 2 / zoom), pinRadius, pinShadow);
      canvas.drawCircle(pinCenter, pinRadius, pinPaint);

      // Comment icon letter
      final textSpan = TextSpan(
        text: 'C',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12 / zoom,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, pinCenter - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.project != project ||
        oldDelegate.page != page ||
        oldDelegate.selectedNodeIds != selectedNodeIds ||
        oldDelegate.hoveredNodeId != hoveredNodeId ||
        oldDelegate.zoom != zoom ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.marqueeRect != marqueeRect ||
        oldDelegate.snapGuides != snapGuides ||
        oldDelegate.isDevInspectMode != isDevInspectMode ||
        oldDelegate.editingVectorNodeId != editingVectorNodeId ||
        oldDelegate.selectedAnchorIndex != selectedAnchorIndex;
  }
}
