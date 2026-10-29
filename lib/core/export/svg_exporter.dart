import 'dart:convert';
import 'dart:math' as math;
import '../../domain/models/project_model.dart';
import '../../domain/models/node_model.dart';
import '../../domain/models/node_types.dart';
import '../../domain/models/paint_styles.dart';

class SvgExporter {
  SvgExporter._();

  static String exportPage(
    ProjectModel project,
    String pageId, {
    String? frameId,
  }) {
    final page = project.getPage(pageId);
    if (page == null) {
      return '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"></svg>';
    }

    final List<DesignNode> nodesToExport;
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
      nodesToExport = [frame];
    } else {
      nodesToExport = page.rootNodeIds
          .map((id) => project.nodes[id])
          .whereType<DesignNode>()
          .toList();

      if (nodesToExport.isNotEmpty) {
        minX = nodesToExport.map((n) => n.x).reduce(math.min);
        minY = nodesToExport.map((n) => n.y).reduce(math.min);
        final maxX = nodesToExport.map((n) => n.x + n.width).reduce(math.max);
        final maxY = nodesToExport.map((n) => n.y + n.height).reduce(math.max);
        width = math.max(100, maxX - minX + 40);
        height = math.max(100, maxY - minY + 40);
        minX -= 20;
        minY -= 20;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$minX $minY $width $height" width="$width" height="$height">',
    );

    // Defs
    buffer.writeln('  <defs>');
    _writeDefs(buffer, project);
    buffer.writeln('  </defs>');

    // Background rect
    final bgHex = _colorToHex(page.backgroundColor);
    buffer.writeln(
      '  <rect x="$minX" y="$minY" width="$width" height="$height" fill="$bgHex" />',
    );

    // Nodes
    for (final node in nodesToExport) {
      _writeNode(buffer, node, project);
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  static void _writeDefs(StringBuffer buffer, ProjectModel project) {
    // Generate linear & radial gradient and shadow filter definitions
    for (final node in project.nodes.values) {
      for (int i = 0; i < node.fills.length; i++) {
        final fill = node.fills[i];
        if (fill.type == DesignFillType.linearGradient &&
            fill.gradientColors != null &&
            fill.gradientColors!.isNotEmpty) {
          final gradId = 'grad_${node.id}_$i';
          buffer.writeln(
            '    <linearGradient id="$gradId" x1="0%" y1="0%" x2="100%" y2="100%">',
          );
          final colors = fill.gradientColors!;
          for (int c = 0; c < colors.length; c++) {
            final offset = (c / (colors.length - 1) * 100).toStringAsFixed(0);
            buffer.writeln(
              '      <stop offset="$offset%" stop-color="${_colorToHex(colors[c])}" />',
            );
          }
          buffer.writeln('    </linearGradient>');
        } else if (fill.type == DesignFillType.radialGradient &&
            fill.gradientColors != null &&
            fill.gradientColors!.isNotEmpty) {
          final gradId = 'radial_grad_${node.id}_$i';
          buffer.writeln(
            '    <radialGradient id="$gradId" cx="50%" cy="50%" r="50%" fx="50%" fy="50%">',
          );
          final colors = fill.gradientColors!;
          for (int c = 0; c < colors.length; c++) {
            final offset = (c / (colors.length - 1) * 100).toStringAsFixed(0);
            buffer.writeln(
              '      <stop offset="$offset%" stop-color="${_colorToHex(colors[c])}" />',
            );
          }
          buffer.writeln('    </radialGradient>');
        }
      }

      for (int i = 0; i < node.effects.length; i++) {
        final eff = node.effects[i];
        if (eff.isVisible && eff.type == DesignEffectType.dropShadow) {
          final filterId = 'shadow_${node.id}_$i';
          buffer.writeln('    <filter id="$filterId" x="-25%" y="-25%" width="150%" height="150%">');
          buffer.writeln('      <feDropShadow dx="${eff.offsetX}" dy="${eff.offsetY}" stdDeviation="${eff.blurRadius / 2}" flood-color="${_colorToHex(eff.color)}" flood-opacity="${eff.color.a}" />');
          buffer.writeln('    </filter>');
        }
      }
    }
  }

  static void _writeNode(
    StringBuffer buffer,
    DesignNode node,
    ProjectModel project,
  ) {
    if (!node.isVisible) return;

    final transformStr = node.rotation != 0
        ? ' transform="rotate(${node.rotation} ${node.x + node.width / 2} ${node.y + node.height / 2})"'
        : '';
    final opacityStr = node.opacity < 1.0 ? ' opacity="${node.opacity}"' : '';

    String filterStr = '';
    final dropShadowIdx = node.effects.indexWhere(
      (e) => e.isVisible && e.type == DesignEffectType.dropShadow,
    );
    if (dropShadowIdx >= 0) {
      filterStr = ' filter="url(#shadow_${node.id}_$dropShadowIdx)"';
    }

    String fillStr = 'none';
    if (node.fills.isNotEmpty && node.fills.first.isVisible) {
      final f = node.fills.first;
      if (f.type == DesignFillType.solid) {
        fillStr = _colorToHex(f.color);
      } else if (f.type == DesignFillType.linearGradient) {
        fillStr = 'url(#grad_${node.id}_0)';
      } else if (f.type == DesignFillType.radialGradient) {
        fillStr = 'url(#radial_grad_${node.id}_0)';
      }
    }

    String strokeStr = '';
    if (node.strokes.isNotEmpty && node.strokes.first.isVisible) {
      final s = node.strokes.first;
      strokeStr = ' stroke="${_colorToHex(s.color)}" stroke-width="${s.width}"';
    }

    switch (node.type) {
      case NodeType.frame:
        final rxStr = node.cornerRadii.uniformValue > 0
            ? ' rx="${node.cornerRadii.uniformValue}" ry="${node.cornerRadii.uniformValue}"'
            : '';
        buffer.writeln(
          '  <rect x="${node.x}" y="${node.y}" width="${node.width}" height="${node.height}" fill="$fillStr"$strokeStr$rxStr$transformStr$opacityStr$filterStr />',
        );
        for (final childId in node.childrenIds) {
          final child = project.nodes[childId];
          if (child != null) {
            _writeNode(buffer, child, project);
          }
        }
        return;

      case NodeType.group:
        buffer.writeln('  <g id="${node.id}"$transformStr$opacityStr>');
        for (final childId in node.childrenIds) {
          final child = project.nodes[childId];
          if (child != null) {
            _writeNode(buffer, child, project);
          }
        }
        buffer.writeln('  </g>');
        return;

      case NodeType.rectangle:
      case NodeType.annotationSection:
        final rxStr = node.cornerRadii.uniformValue > 0
            ? ' rx="${node.cornerRadii.uniformValue}" ry="${node.cornerRadii.uniformValue}"'
            : '';
        buffer.writeln(
          '  <rect x="${node.x}" y="${node.y}" width="${node.width}" height="${node.height}" fill="$fillStr"$strokeStr$rxStr$transformStr$opacityStr$filterStr />',
        );
        break;

      case NodeType.image:
        final b64 = node.imagePath ??
            (node.fills.where((f) => f.type == DesignFillType.image).firstOrNull?.imageBase64);
        if (b64 != null && b64.isNotEmpty) {
          final prefix = b64.startsWith('data:') ? '' : 'data:image/png;base64,';
          buffer.writeln(
            '  <image x="${node.x}" y="${node.y}" width="${node.width}" height="${node.height}" href="$prefix$b64"$transformStr$opacityStr$filterStr preserveAspectRatio="none" />',
          );
        } else {
          buffer.writeln(
            '  <rect x="${node.x}" y="${node.y}" width="${node.width}" height="${node.height}" fill="$fillStr"$strokeStr$transformStr$opacityStr$filterStr />',
          );
        }
        break;

      case NodeType.roundedRectangle:
        final r = node.cornerRadii.uniformValue > 0
            ? node.cornerRadii.uniformValue
            : 16.0;
        buffer.writeln(
          '  <rect x="${node.x}" y="${node.y}" width="${node.width}" height="${node.height}" rx="$r" ry="$r" fill="$fillStr"$strokeStr$transformStr$opacityStr />',
        );
        break;

      case NodeType.ellipse:
        final cx = node.x + node.width / 2;
        final cy = node.y + node.height / 2;
        final rx = node.width / 2;
        final ry = node.height / 2;
        buffer.writeln(
          '  <ellipse cx="$cx" cy="$cy" rx="$rx" ry="$ry" fill="$fillStr"$strokeStr$transformStr$opacityStr />',
        );
        break;

      case NodeType.line:
      case NodeType.arrow:
        final x1 = node.x;
        final y1 = node.y;
        final x2 = node.x + node.width;
        final y2 = node.y + node.height;
        buffer.writeln(
          '  <line x1="$x1" y1="$y1" x2="$x2" y2="$y2"$strokeStr$transformStr$opacityStr />',
        );
        break;

      case NodeType.polygon:
        final points = _generatePolygonPoints(
          node.x,
          node.y,
          node.width,
          node.height,
          node.polygonSides,
        );
        buffer.writeln(
          '  <polygon points="$points" fill="$fillStr"$strokeStr$transformStr$opacityStr />',
        );
        break;

      case NodeType.star:
        final points = _generateStarPoints(
          node.x,
          node.y,
          node.width,
          node.height,
          node.starPoints,
          node.starInnerRadiusRatio,
        );
        buffer.writeln(
          '  <polygon points="$points" fill="$fillStr"$strokeStr$transformStr$opacityStr />',
        );
        break;

      case NodeType.text:
        if (node.textData != null) {
          final t = node.textData!;
          final escaped = const HtmlEscape().convert(t.text);
          final textY = node.y + t.fontSize;
          buffer.writeln(
            '  <text x="${node.x}" y="$textY" font-family="${t.fontFamily}" font-size="${t.fontSize}" font-weight="${t.fontWeight}" fill="$fillStr"$strokeStr$transformStr$opacityStr>$escaped</text>',
          );
        }
        break;

      case NodeType.vectorPath:
      case NodeType.freehandPath:
        if (node.vectorData != null && node.vectorData!.anchors.isNotEmpty) {
          final d = _vectorDataToSvgPath(
            node.vectorData!,
            node.x,
            node.y,
            node.width,
            node.height,
          );
          buffer.writeln(
            '  <path d="$d" fill="$fillStr"$strokeStr$transformStr$opacityStr />',
          );
        }
        break;

      default:
        buffer.writeln(
          '  <rect x="${node.x}" y="${node.y}" width="${node.width}" height="${node.height}" fill="$fillStr"$strokeStr$transformStr$opacityStr />',
        );
        break;
    }

    // Children
    for (final childId in node.childrenIds) {
      final child = project.nodes[childId];
      if (child != null) {
        _writeNode(buffer, child, project);
      }
    }
  }

  static String _generatePolygonPoints(
    double x,
    double y,
    double w,
    double h,
    int sides,
  ) {
    final cx = x + w / 2;
    final cy = y + h / 2;
    final rx = w / 2;
    final ry = h / 2;
    final points = <String>[];
    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i) / sides;
      final px = cx + rx * math.cos(angle);
      final py = cy + ry * math.sin(angle);
      points.add('${px.toStringAsFixed(1)},${py.toStringAsFixed(1)}');
    }
    return points.join(' ');
  }

  static String _generateStarPoints(
    double x,
    double y,
    double w,
    double h,
    int numPoints,
    double innerRatio,
  ) {
    final cx = x + w / 2;
    final cy = y + h / 2;
    final rx = w / 2;
    final ry = h / 2;
    final points = <String>[];
    final total = numPoints * 2;
    for (int i = 0; i < total; i++) {
      final angle = -math.pi / 2 + (math.pi * i) / numPoints;
      final radiusX = (i % 2 == 0) ? rx : rx * innerRatio;
      final radiusY = (i % 2 == 0) ? ry : ry * innerRatio;
      final px = cx + radiusX * math.cos(angle);
      final py = cy + radiusY * math.sin(angle);
      points.add('${px.toStringAsFixed(1)},${py.toStringAsFixed(1)}');
    }
    return points.join(' ');
  }

  static String _vectorDataToSvgPath(
    dynamic vectorData,
    double x,
    double y,
    double w,
    double h,
  ) {
    final anchors = vectorData.anchors;
    if (anchors.isEmpty) return '';
    final buffer = StringBuffer();
    final first = anchors.first;
    buffer.write('M ${x + first.point.dx} ${y + first.point.dy} ');
    for (int i = 1; i < anchors.length; i++) {
      final curr = anchors[i];
      buffer.write('L ${x + curr.point.dx} ${y + curr.point.dy} ');
    }
    if (vectorData.isClosed) {
      buffer.write('Z');
    }
    return buffer.toString();
  }

  static String _colorToHex(dynamic color) {
    final c = color as dynamic;
    final r = ((c.r as num) * 255).round().toRadixString(16).padLeft(2, '0');
    final g = ((c.g as num) * 255).round().toRadixString(16).padLeft(2, '0');
    final b = ((c.b as num) * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }
}
