import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../../domain/models/node_model.dart';
import '../../domain/models/node_types.dart';
import '../../domain/models/paint_styles.dart';
import '../../domain/models/vector_data.dart';
import '../../domain/models/text_data.dart';

class SvgImporter {
  SvgImporter._();

  static const _uuid = Uuid();

  /// Parses an SVG string and returns a parent Frame `DesignNode`
  /// along with all child `DesignNode`s ready to be added to a project page.
  static SvgImportResult parseSvg(
    String svgXml, {
    Offset insertionPoint = const Offset(100, 100),
  }) {
    final document = XmlDocument.parse(svgXml);
    final svgElements = document.findAllElements('svg');
    final svgRoot = svgElements.isEmpty ? null : svgElements.first;

    if (svgRoot == null) {
      throw const FormatException('Invalid SVG: missing <svg> root element');
    }

    double width = 400;
    double height = 400;

    final viewBoxAttr = svgRoot.getAttribute('viewBox');
    if (viewBoxAttr != null) {
      final parts = viewBoxAttr
          .trim()
          .split(RegExp(r'[\s,]+'))
          .map((s) => double.tryParse(s) ?? 0.0)
          .toList();
      if (parts.length == 4) {
        width = parts[2] > 0 ? parts[2] : width;
        height = parts[3] > 0 ? parts[3] : height;
      }
    } else {
      final w = double.tryParse(svgRoot.getAttribute('width') ?? '');
      final h = double.tryParse(svgRoot.getAttribute('height') ?? '');
      if (w != null && w > 0) width = w;
      if (h != null && h > 0) height = h;
    }

    final frameId = 'frame-svg-${_uuid.v4().substring(0, 8)}';
    final List<DesignNode> nodes = [];
    final List<String> childrenIds = [];

    // Parse elements
    for (final child in svgRoot.descendants.whereType<XmlElement>()) {
      final node = _parseElement(child, parentId: frameId);
      if (node != null) {
        nodes.add(node);
        childrenIds.add(node.id);
      }
    }

    final frameNode = DesignNode(
      id: frameId,
      type: NodeType.frame,
      name: 'Imported SVG',
      x: insertionPoint.dx,
      y: insertionPoint.dy,
      width: width,
      height: height,
      clipContent: true,
      childrenIds: childrenIds,
      fills: const [
        DesignFill(color: Colors.transparent),
      ],
    );

    return SvgImportResult(rootFrame: frameNode, childNodes: nodes);
  }

  static DesignNode? _parseElement(XmlElement el, {required String parentId}) {
    final id = 'node-svg-${_uuid.v4().substring(0, 8)}';

    final fills = _parseFills(el);
    final strokes = _parseStrokes(el);

    switch (el.name.local.toLowerCase()) {
      case 'rect':
        final x = double.tryParse(el.getAttribute('x') ?? '0') ?? 0;
        final y = double.tryParse(el.getAttribute('y') ?? '0') ?? 0;
        final w = double.tryParse(el.getAttribute('width') ?? '100') ?? 100;
        final h = double.tryParse(el.getAttribute('height') ?? '100') ?? 100;
        final rx = double.tryParse(el.getAttribute('rx') ?? '0') ?? 0;

        return DesignNode(
          id: id,
          parentId: parentId,
          type: rx > 0 ? NodeType.roundedRectangle : NodeType.rectangle,
          name: 'Rect',
          x: x,
          y: y,
          width: w,
          height: h,
          cornerRadii: CornerRadii.all(rx),
          fills: fills,
          strokes: strokes,
        );

      case 'circle':
        final cx = double.tryParse(el.getAttribute('cx') ?? '0') ?? 0;
        final cy = double.tryParse(el.getAttribute('cy') ?? '0') ?? 0;
        final r = double.tryParse(el.getAttribute('r') ?? '20') ?? 20;

        return DesignNode(
          id: id,
          parentId: parentId,
          type: NodeType.ellipse,
          name: 'Circle',
          x: cx - r,
          y: cy - r,
          width: r * 2,
          height: r * 2,
          fills: fills,
          strokes: strokes,
        );

      case 'ellipse':
        final cx = double.tryParse(el.getAttribute('cx') ?? '0') ?? 0;
        final cy = double.tryParse(el.getAttribute('cy') ?? '0') ?? 0;
        final rx = double.tryParse(el.getAttribute('rx') ?? '20') ?? 20;
        final ry = double.tryParse(el.getAttribute('ry') ?? '20') ?? 20;

        return DesignNode(
          id: id,
          parentId: parentId,
          type: NodeType.ellipse,
          name: 'Ellipse',
          x: cx - rx,
          y: cy - ry,
          width: rx * 2,
          height: ry * 2,
          fills: fills,
          strokes: strokes,
        );

      case 'line':
        final x1 = double.tryParse(el.getAttribute('x1') ?? '0') ?? 0;
        final y1 = double.tryParse(el.getAttribute('y1') ?? '0') ?? 0;
        final x2 = double.tryParse(el.getAttribute('x2') ?? '100') ?? 100;
        final y2 = double.tryParse(el.getAttribute('y2') ?? '0') ?? 0;

        final minX = math.min(x1, x2);
        final minY = math.min(y1, y2);
        final w = math.max(1.0, (x2 - x1).abs());
        final h = math.max(1.0, (y2 - y1).abs());

        return DesignNode(
          id: id,
          parentId: parentId,
          type: NodeType.line,
          name: 'Line',
          x: minX,
          y: minY,
          width: w,
          height: h,
          strokes: strokes.isNotEmpty
              ? strokes
              : const [DesignStroke(color: Colors.black, width: 1.0)],
        );

      case 'path':
        final d = el.getAttribute('d');
        if (d == null || d.trim().isEmpty) return null;

        final pathData = _parseSvgPathData(d);
        if (pathData.anchors.isEmpty) return null;

        // Calculate bounding box of anchors
        final points = pathData.anchors.map((a) => a.point).toList();
        final minX = points.map((p) => p.dx).reduce(math.min);
        final minY = points.map((p) => p.dy).reduce(math.min);
        final maxX = points.map((p) => p.dx).reduce(math.max);
        final maxY = points.map((p) => p.dy).reduce(math.max);
        final w = math.max(2.0, maxX - minX);
        final h = math.max(2.0, maxY - minY);

        // Normalize anchors relative to (minX, minY)
        final normalizedAnchors = pathData.anchors.map((a) {
          final np = Offset(a.point.dx - minX, a.point.dy - minY);
          final hin = a.handleIn != null
              ? Offset(a.handleIn!.dx - minX, a.handleIn!.dy - minY)
              : null;
          final hout = a.handleOut != null
              ? Offset(a.handleOut!.dx - minX, a.handleOut!.dy - minY)
              : null;
          return a.copyWith(point: np, handleIn: hin, handleOut: hout);
        }).toList();

        return DesignNode(
          id: id,
          parentId: parentId,
          type: NodeType.vectorPath,
          name: 'Path',
          x: minX,
          y: minY,
          width: w,
          height: h,
          fills: fills,
          strokes: strokes,
          vectorData: VectorPathData(
            anchors: normalizedAnchors,
            isClosed: pathData.isClosed,
          ),
        );

      case 'text':
        final x = double.tryParse(el.getAttribute('x') ?? '0') ?? 0;
        final y = double.tryParse(el.getAttribute('y') ?? '0') ?? 0;
        final content = el.innerText.trim();
        final fontSize =
            double.tryParse(el.getAttribute('font-size') ?? '16') ?? 16;

        return DesignNode(
          id: id,
          parentId: parentId,
          type: NodeType.text,
          name: 'Text',
          x: x,
          y: y,
          width: math.max(60, content.length * fontSize * 0.6),
          height: fontSize * 1.5,
          textData: TextNodeData(
            text: content,
            fontSize: fontSize,
          ),
        );

      default:
        return null;
    }
  }

  static List<DesignFill> _parseFills(XmlElement el) {
    final fillAttr = el.getAttribute('fill');
    if (fillAttr == 'none') return [];
    if (fillAttr != null) {
      final color = _parseColor(fillAttr);
      if (color != null) {
        return [DesignFill(color: color)];
      }
    }
    return [const DesignFill(color: Colors.black)];
  }

  static List<DesignStroke> _parseStrokes(XmlElement el) {
    final strokeAttr = el.getAttribute('stroke');
    if (strokeAttr != null && strokeAttr != 'none') {
      final color = _parseColor(strokeAttr);
      if (color != null) {
        final w =
            double.tryParse(el.getAttribute('stroke-width') ?? '1') ?? 1.0;
        return [DesignStroke(color: color, width: w)];
      }
    }
    return [];
  }

  static Color? _parseColor(String raw) {
    var c = raw.trim().toLowerCase();
    if (c == 'none' || c.isEmpty) return null;
    if (c.startsWith('#')) {
      c = c.substring(1);
      if (c.length == 3) {
        c = '${c[0]}${c[0]}${c[1]}${c[1]}${c[2]}${c[2]}';
      }
      if (c.length == 6) {
        final val = int.tryParse('FF$c', radix: 16);
        if (val != null) return Color(val);
      } else if (c.length == 8) {
        final val = int.tryParse(c, radix: 16);
        if (val != null) return Color(val);
      }
    }

    switch (c) {
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'gray':
      case 'grey':
        return Colors.grey;
      default:
        return null;
    }
  }

  static VectorPathData _parseSvgPathData(String d) {
    final anchors = <VectorAnchor>[];
    bool isClosed = false;

    final tokenRegex = RegExp(r'([MmLlHhVvCcSsQqTtZz]|[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)');
    final matches = tokenRegex.allMatches(d).map((m) => m.group(0)!).toList();

    double curX = 0;
    double curY = 0;
    int i = 0;

    while (i < matches.length) {
      final token = matches[i];
      if (RegExp(r'^[MmLlHhVvCcSsQqTtZz]$').hasMatch(token)) {
        final cmd = token;
        i++;

        if (cmd == 'Z' || cmd == 'z') {
          isClosed = true;
          continue;
        }

        if (cmd == 'M' || cmd == 'm') {
          if (i + 1 < matches.length) {
            final x = double.tryParse(matches[i]) ?? 0;
            final y = double.tryParse(matches[i + 1]) ?? 0;
            i += 2;
            curX = cmd == 'M' ? x : curX + x;
            curY = cmd == 'M' ? y : curY + y;
            anchors.add(VectorAnchor(point: Offset(curX, curY)));
          }
        } else if (cmd == 'L' || cmd == 'l') {
          if (i + 1 < matches.length) {
            final x = double.tryParse(matches[i]) ?? 0;
            final y = double.tryParse(matches[i + 1]) ?? 0;
            i += 2;
            curX = cmd == 'L' ? x : curX + x;
            curY = cmd == 'L' ? y : curY + y;
            anchors.add(VectorAnchor(point: Offset(curX, curY)));
          }
        } else if (cmd == 'C' || cmd == 'c') {
          if (i + 5 < matches.length) {
            final cp1x = double.tryParse(matches[i]) ?? 0;
            final cp1y = double.tryParse(matches[i + 1]) ?? 0;
            final cp2x = double.tryParse(matches[i + 2]) ?? 0;
            final cp2y = double.tryParse(matches[i + 3]) ?? 0;
            final x = double.tryParse(matches[i + 4]) ?? 0;
            final y = double.tryParse(matches[i + 5]) ?? 0;
            i += 6;

            final p0 = Offset(curX, curY);
            final p1 = cmd == 'C' ? Offset(cp1x, cp1y) : Offset(curX + cp1x, curY + cp1y);
            final p2 = cmd == 'C' ? Offset(cp2x, cp2y) : Offset(curX + cp2x, curY + cp2y);
            final p3 = cmd == 'C' ? Offset(x, y) : Offset(curX + x, curY + y);

            if (anchors.isNotEmpty) {
              final last = anchors.removeLast();
              anchors.add(last.copyWith(handleOut: p1));
            } else {
              anchors.add(VectorAnchor(point: p0, handleOut: p1));
            }

            curX = p3.dx;
            curY = p3.dy;
            anchors.add(VectorAnchor(point: p3, handleIn: p2, isSmooth: true));
          }
        }
      } else {
        i++;
      }
    }

    return VectorPathData(anchors: anchors, isClosed: isClosed);
  }
}

class SvgImportResult {
  final DesignNode rootFrame;
  final List<DesignNode> childNodes;

  const SvgImportResult({
    required this.rootFrame,
    required this.childNodes,
  });
}
