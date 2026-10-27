import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../domain/models/project_model.dart';
import '../../domain/models/node_model.dart';
import '../../domain/services/node_render_service.dart';

class PngExporter {
  PngExporter._();

  /// Exports a page or specific frame to PNG bytes.
  static Future<Uint8List?> exportToPng({
    required ProjectModel project,
    required String pageId,
    String? frameId,
    double scale = 1.0,
    bool transparentBg = false,
  }) async {
    final page = project.getPage(pageId);
    if (page == null) return null;

    final List<DesignNode> nodesToRender;
    double minX = 0;
    double minY = 0;
    double width = 800;
    double height = 600;

    if (frameId != null && project.nodes.containsKey(frameId)) {
      final frame = project.nodes[frameId]!;
      minX = frame.x;
      minY = frame.y;
      width = frame.width;
      height = frame.height;
      nodesToRender = [frame];
    } else {
      nodesToRender = page.rootNodeIds
          .map((id) => project.nodes[id])
          .whereType<DesignNode>()
          .toList();

      if (nodesToRender.isNotEmpty) {
        minX = nodesToRender.map((n) => n.x).reduce(math.min);
        minY = nodesToRender.map((n) => n.y).reduce(math.min);
        final maxX = nodesToRender.map((n) => n.x + n.width).reduce(math.max);
        final maxY = nodesToRender.map((n) => n.y + n.height).reduce(math.max);
        width = math.max(100, maxX - minX + 40);
        height = math.max(100, maxY - minY + 40);
        minX -= 20;
        minY -= 20;
      }
    }

    final pixelWidth = (width * scale).ceil();
    final pixelHeight = (height * scale).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Scale canvas
    canvas.scale(scale, scale);
    canvas.translate(-minX, -minY);

    // Draw background if not transparent
    if (!transparentBg) {
      final bgPaint = Paint()..color = page.backgroundColor;
      canvas.drawRect(Rect.fromLTWH(minX, minY, width, height), bgPaint);
    }

    // Render nodes
    for (final node in nodesToRender) {
      NodeRenderService.renderNode(canvas, node, project.nodes);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelWidth, pixelHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }
}
