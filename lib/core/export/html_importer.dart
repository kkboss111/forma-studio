import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../../domain/models/node_model.dart';
import '../../domain/models/node_types.dart';
import '../../domain/models/paint_styles.dart';
import '../../domain/models/text_data.dart';

/// Service parsing HTML documents or snippets into native Forma Studio [DesignNode] hierarchy.
/// Converts containers (div, section, article, header, nav) to Frames, buttons to styled frames,
/// headings & paragraphs to TextNodes, and parses inline CSS styles (colors, dimensions, borders, shadows).
class HtmlImporter {
  HtmlImporter._();

  static const _uuid = Uuid();

  /// Parses an HTML string and returns a parent Frame [DesignNode] with all children.
  static HtmlImportResult parseHtml(
    String htmlString, {
    Offset insertionPoint = const Offset(80, 80),
  }) {
    final cleaned = _sanitizeHtml(htmlString);
    XmlDocument? doc;

    try {
      doc = XmlDocument.parse(cleaned);
    } catch (_) {
      // Fallback: wrap in minimal document
      try {
        doc = XmlDocument.parse('<root>$cleaned</root>');
      } catch (_) {
        // If strict XML parse fails, generate from regex fallback
        return _fallbackRegexParse(htmlString, insertionPoint);
      }
    }

    final frameId = 'html-frame-${_uuid.v4().substring(0, 8)}';
    final List<DesignNode> childNodes = [];
    final List<String> childIds = [];

    double currentY = 24.0;
    const double marginX = 24.0;
    double maxContentWidth = 600.0;

    // Find the body or main container if present
    final bodyElements = doc.findAllElements('body');
    final rootElement = bodyElements.isNotEmpty ? bodyElements.first : doc.rootElement;

    // Parse top-level elements
    for (final child in rootElement.children.whereType<XmlElement>()) {
      if (child.name.local.toLowerCase() == 'script' ||
          child.name.local.toLowerCase() == 'style' ||
          child.name.local.toLowerCase() == 'head') {
        continue;
      }

      final parsed = _parseHtmlElement(
        element: child,
        parentId: frameId,
        x: marginX,
        y: currentY,
      );

      if (parsed != null) {
        childNodes.add(parsed.node);
        childNodes.addAll(parsed.nestedChildren);
        childIds.add(parsed.node.id);

        currentY += parsed.node.height + 16.0;
        maxContentWidth = math.max(maxContentWidth, parsed.node.width + marginX * 2);
      }
    }

    final rootFrameHeight = math.max(400.0, currentY + 24.0);

    final rootFrame = DesignNode(
      id: frameId,
      name: 'HTML Import',
      type: NodeType.frame,
      x: insertionPoint.dx,
      y: insertionPoint.dy,
      width: maxContentWidth,
      height: rootFrameHeight,
      fills: const [DesignFill.solid(Color(0xFFFFFFFF))],
      strokes: const [
        DesignStroke(color: Color(0xFFE2E8F0), width: 1.0),
      ],
      cornerRadii: const CornerRadii.all(12),
      clipContent: true,
      childrenIds: childIds,
    );

    return HtmlImportResult(rootFrame: rootFrame, childNodes: childNodes);
  }

  /// Parses an individual HTML element into a DesignNode.
  static _ParsedElement? _parseHtmlElement({
    required XmlElement element,
    required String parentId,
    required double x,
    required double y,
  }) {
    final tag = element.name.local.toLowerCase();
    final styleMap = _parseInlineStyle(element.getAttribute('style') ?? '');
    final elementId = 'node-html-${_uuid.v4().substring(0, 8)}';

    // 1. Headings (h1 - h6)
    if (tag.startsWith('h') && tag.length == 2 && int.tryParse(tag[1]) != null) {
      final level = int.parse(tag[1]);
      final text = element.innerText.trim();
      if (text.isEmpty) return null;

      final fontSize = _headingFontSize(level);
      final color = styleMap['color'] ?? const Color(0xFF0F172A);

      final node = DesignNode(
        id: elementId,
        name: '${tag.toUpperCase()}: $text',
        type: NodeType.text,
        x: x,
        y: y,
        width: 520,
        height: fontSize * 1.5,
        parentId: parentId,
        fills: [DesignFill.solid(color)],
        textData: TextNodeData(
          text: text,
          fontSize: fontSize,
          fontWeight: 700,
          fontFamily: styleMap['font-family-name'] ?? 'Inter',
        ),
      );
      return _ParsedElement(node: node);
    }

    // 2. Paragraphs & Text (p, span, a, label, b, strong, em)
    if (tag == 'p' || tag == 'span' || tag == 'a' || tag == 'label' || tag == 'b' || tag == 'strong' || tag == 'em') {
      final text = element.innerText.trim();
      if (text.isEmpty) return null;

      final isBold = tag == 'b' || tag == 'strong' || styleMap['is-bold'] == true;
      final isLink = tag == 'a';
      final color = styleMap['color'] ?? (isLink ? const Color(0xFF2563EB) : const Color(0xFF334155));
      final fontSize = (styleMap['font-size'] as double?) ?? (tag == 'p' ? 14.0 : 13.0);

      final node = DesignNode(
        id: elementId,
        name: text.length > 20 ? '${text.substring(0, 20)}...' : text,
        type: NodeType.text,
        x: x,
        y: y,
        width: 500,
        height: fontSize * 1.8,
        parentId: parentId,
        fills: [DesignFill.solid(color)],
        textData: TextNodeData(
          text: text,
          fontSize: fontSize,
          fontWeight: isBold ? 700 : 400,
          fontFamily: styleMap['font-family-name'] ?? 'Inter',
        ),
      );
      return _ParsedElement(node: node);
    }

    // 3. Buttons (button)
    if (tag == 'button') {
      final text = element.innerText.trim();
      final bg = styleMap['background-color'] ?? const Color(0xFF2563EB);
      final fg = styleMap['color'] ?? Colors.white;
      final radius = (styleMap['border-radius'] as double?) ?? 8.0;

      final labelId = '$elementId-label';
      final labelNode = DesignNode(
        id: labelId,
        name: text.isNotEmpty ? text : 'Button Label',
        type: NodeType.text,
        x: 16,
        y: 10,
        width: 140,
        height: 20,
        parentId: elementId,
        fills: [DesignFill.solid(fg)],
        textData: TextNodeData(
          text: text.isNotEmpty ? text : 'Button',
          fontSize: 14,
          fontWeight: 600,
        ),
      );

      final buttonFrame = DesignNode(
        id: elementId,
        name: 'Button: $text',
        type: NodeType.frame,
        x: x,
        y: y,
        width: (styleMap['width'] as double?) ?? 160,
        height: (styleMap['height'] as double?) ?? 42,
        parentId: parentId,
        fills: [DesignFill.solid(bg)],
        cornerRadii: CornerRadii.all(radius),
        childrenIds: [labelId],
      );

      return _ParsedElement(node: buttonFrame, nestedChildren: [labelNode]);
    }

    // 4. Containers (div, section, article, card, header, footer, nav)
    final width = (styleMap['width'] as double?) ?? 540.0;
    final bg = styleMap['background-color'];
    final radius = (styleMap['border-radius'] as double?) ?? 0.0;
    final strokeColor = styleMap['border-color'];
    final strokeWidth = (styleMap['border-width'] as double?) ?? 1.0;

    final childNodes = <DesignNode>[];
    final childIds = <String>[];
    double innerY = 16.0;

    for (final innerChild in element.children.whereType<XmlElement>()) {
      final parsedInner = _parseHtmlElement(
        element: innerChild,
        parentId: elementId,
        x: 16.0,
        y: innerY,
      );
      if (parsedInner != null) {
        childNodes.add(parsedInner.node);
        childNodes.addAll(parsedInner.nestedChildren);
        childIds.add(parsedInner.node.id);
        innerY += parsedInner.node.height + 12.0;
      }
    }

    // If container has plain text without inner tags
    if (childNodes.isEmpty && element.innerText.trim().isNotEmpty) {
      final text = element.innerText.trim();
      final textNode = DesignNode(
        id: '$elementId-txt',
        name: text.length > 20 ? '${text.substring(0, 20)}...' : text,
        type: NodeType.text,
        x: 16.0,
        y: 16.0,
        width: width - 32.0,
        height: 24.0,
        parentId: elementId,
        fills: [DesignFill.solid(styleMap['color'] ?? const Color(0xFF334155))],
        textData: TextNodeData(
          text: text,
          fontSize: 14.0,
        ),
      );
      childNodes.add(textNode);
      childIds.add(textNode.id);
      innerY += 36.0;
    }

    final height = (styleMap['height'] as double?) ?? math.max(60.0, innerY + 16.0);

    final node = DesignNode(
      id: elementId,
      name: '${tag.toUpperCase()} Container',
      type: NodeType.frame,
      x: x,
      y: y,
      width: width,
      height: height,
      parentId: parentId,
      fills: bg != null ? [DesignFill.solid(bg)] : const [],
      strokes: strokeColor != null
          ? [DesignStroke(color: strokeColor, width: strokeWidth)]
          : const [],
      cornerRadii: CornerRadii.all(radius),
      childrenIds: childIds,
    );

    return _ParsedElement(node: node, nestedChildren: childNodes);
  }

  /// Parses inline CSS style declaration into a property map.
  static Map<String, dynamic> _parseInlineStyle(String style) {
    final map = <String, dynamic>{};
    if (style.trim().isEmpty) return map;

    final declarations = style.split(';');
    for (final decl in declarations) {
      final colon = decl.indexOf(':');
      if (colon == -1) continue;
      final key = decl.substring(0, colon).trim().toLowerCase();
      final val = decl.substring(colon + 1).trim();

      switch (key) {
        case 'color':
          final c = _parseColor(val);
          if (c != null) map['color'] = c;
          break;
        case 'background-color':
        case 'background':
          final c = _parseColor(val);
          if (c != null) map['background-color'] = c;
          break;
        case 'width':
          final w = _parsePx(val);
          if (w != null) map['width'] = w;
          break;
        case 'height':
          final h = _parsePx(val);
          if (h != null) map['height'] = h;
          break;
        case 'border-radius':
          final r = _parsePx(val);
          if (r != null) map['border-radius'] = r;
          break;
        case 'border':
          _parseBorderShorthand(val, map);
          break;
        case 'border-color':
          final c = _parseColor(val);
          if (c != null) map['border-color'] = c;
          break;
        case 'border-width':
          final w = _parsePx(val);
          if (w != null) map['border-width'] = w;
          break;
        case 'font-size':
          final fs = _parsePx(val);
          if (fs != null) map['font-size'] = fs;
          break;
        case 'font-weight':
          if (val == 'bold' || val == '700' || val == '800' || val == '900') {
            map['is-bold'] = true;
          }
          break;
        case 'font-family':
          map['font-family-name'] = val.replaceAll(RegExp(r"""['"]"""), '').split(',').first.trim();
          break;
      }
    }
    return map;
  }

  static void _parseBorderShorthand(String border, Map<String, dynamic> map) {
    final parts = border.split(RegExp(r'\s+'));
    for (final p in parts) {
      final px = _parsePx(p);
      if (px != null) {
        map['border-width'] = px;
        continue;
      }
      final c = _parseColor(p);
      if (c != null) {
        map['border-color'] = c;
      }
    }
  }

  static double? _parsePx(String str) {
    final match = RegExp(r'^([\d.]+)(px|rem|em|%)?$').firstMatch(str.trim());
    if (match == null) return null;
    final val = double.tryParse(match.group(1) ?? '');
    if (val == null) return null;
    final unit = match.group(2);
    if (unit == 'rem' || unit == 'em') return val * 16.0;
    return val;
  }

  static Color? _parseColor(String str) {
    final s = str.trim().toLowerCase();
    if (s.startsWith('#')) {
      final hex = s.substring(1);
      if (hex.length == 3) {
        final r = hex[0] * 2;
        final g = hex[1] * 2;
        final b = hex[2] * 2;
        return Color(int.parse('FF$r$g$b', radix: 16));
      } else if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    if (s.startsWith('rgb')) {
      final match = RegExp(r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)').firstMatch(s);
      if (match != null) {
        final r = int.parse(match.group(1)!);
        final g = int.parse(match.group(2)!);
        final b = int.parse(match.group(3)!);
        return Color.fromARGB(255, r, g, b);
      }
    }
    switch (s) {
      case 'white': return Colors.white;
      case 'black': return Colors.black;
      case 'blue': return const Color(0xFF2563EB);
      case 'red': return const Color(0xFFDC2626);
      case 'green': return const Color(0xFF16A34A);
      case 'gray': case 'grey': return const Color(0xFF64748B);
      case 'purple': return const Color(0xFF9333EA);
      case 'transparent': return Colors.transparent;
    }
    return null;
  }

  static double _headingFontSize(int level) {
    switch (level) {
      case 1: return 32.0;
      case 2: return 26.0;
      case 3: return 22.0;
      case 4: return 18.0;
      case 5: return 16.0;
      case 6: default: return 14.0;
    }
  }

  /// Sanitizes HTML to ensure unclosed tags (like img, br, hr, input) are valid XML.
  static String _sanitizeHtml(String raw) {
    var s = raw
        .replaceAll(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<meta[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<link[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<br\s*>', caseSensitive: false), '<br/>')
        .replaceAll(RegExp(r'<hr\s*>', caseSensitive: false), '<hr/>');

    // Make img tags self closing if not already
    s = s.replaceAllMapped(RegExp(r'<img\s+([^>]*[^/])>', caseSensitive: false), (m) => '<img ${m.group(1)}/>');
    return s.trim();
  }

  /// Fallback regex parser for unstructured HTML
  static HtmlImportResult _fallbackRegexParse(String html, Offset insertionPoint) {
    final frameId = 'html-frame-${_uuid.v4().substring(0, 8)}';
    final List<DesignNode> nodes = [];
    final List<String> childIds = [];
    double y = 24.0;

    final tagRegex = RegExp(r'<(\w+)[^>]*>(.*?)</\1>', dotAll: true);
    for (final match in tagRegex.allMatches(html)) {
      final tag = match.group(1)!.toLowerCase();
      final text = match.group(2)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (text.isEmpty) continue;

      final id = 'node-html-${_uuid.v4().substring(0, 8)}';
      final isHeading = tag.startsWith('h');
      final node = DesignNode(
        id: id,
        name: '$tag: $text',
        type: NodeType.text,
        x: 24,
        y: y,
        width: 500,
        height: isHeading ? 36 : 22,
        parentId: frameId,
        fills: const [DesignFill.solid(Color(0xFF0F172A))],
        textData: TextNodeData(
          text: text,
          fontSize: isHeading ? 24 : 14,
          fontWeight: isHeading ? 700 : 400,
        ),
      );
      nodes.add(node);
      childIds.add(id);
      y += node.height + 14.0;
    }

    // Fallback: If no closed tags matched, extract raw text
    if (nodes.isEmpty) {
      final rawText = html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (rawText.isNotEmpty) {
        final id = 'node-html-${_uuid.v4().substring(0, 8)}';
        final node = DesignNode(
          id: id,
          name: 'Text Content',
          type: NodeType.text,
          x: 24,
          y: y,
          width: 500,
          height: 28,
          parentId: frameId,
          fills: const [DesignFill.solid(Color(0xFF0F172A))],
          textData: TextNodeData(
            text: rawText,
            fontSize: 14,
            fontWeight: 400,
          ),
        );
        nodes.add(node);
        childIds.add(id);
      }
    }

    final rootFrame = DesignNode(
      id: frameId,
      name: 'HTML Layout',
      type: NodeType.frame,
      x: insertionPoint.dx,
      y: insertionPoint.dy,
      width: 560,
      height: math.max(300.0, y + 24.0),
      fills: const [DesignFill.solid(Colors.white)],
      strokes: const [DesignStroke(color: Color(0xFFCBD5E1), width: 1.0)],
      cornerRadii: const CornerRadii.all(12),
      clipContent: true,
      childrenIds: childIds,
    );

    return HtmlImportResult(rootFrame: rootFrame, childNodes: nodes);
  }
}

class HtmlImportResult {
  final DesignNode rootFrame;
  final List<DesignNode> childNodes;

  const HtmlImportResult({
    required this.rootFrame,
    required this.childNodes,
  });
}

class _ParsedElement {
  final DesignNode node;
  final List<DesignNode> nestedChildren;

  const _ParsedElement({
    required this.node,
    this.nestedChildren = const [],
  });
}
