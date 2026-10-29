import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/node_model.dart';
import '../models/node_types.dart';
import '../models/paint_styles.dart';
import '../models/text_data.dart';

class NodeRenderService {
  NodeRenderService._();

  static final Map<String, ui.Image> _imageCache = {};

  /// Renders a single node and its visual properties onto a canvas.
  static void renderNode(
    Canvas canvas,
    DesignNode node,
    Map<String, DesignNode> allNodes,
  ) {
    if (!node.isVisible) return;

    canvas.save();

    // Transform: rotation around center
    if (node.rotation != 0) {
      final center = Offset(node.x + node.width / 2, node.y + node.height / 2);
      canvas.translate(center.dx, center.dy);
      canvas.rotate(node.rotation * math.pi / 180.0);
      canvas.translate(-center.dx, -center.dy);
    }

    final rect = node.rect;

    // Apply Opacity
    if (node.opacity < 1.0) {
      canvas.saveLayer(
        rect.inflate(20),
        Paint()..color = Colors.black.withValues(alpha: node.opacity),
      );
    }

    // 1. Background Blur (Frosted Backdrop)
    for (final eff in node.effects) {
      if (!eff.isVisible) continue;
      if (eff.type == DesignEffectType.backgroundBlur && eff.blurRadius > 0) {
        final path = getNodePath(node, rect);
        canvas.save();
        canvas.clipPath(path);
        canvas.saveLayer(
          rect.inflate(eff.blurRadius),
          Paint()..imageFilter = ui.ImageFilter.blur(
            sigmaX: eff.blurRadius,
            sigmaY: eff.blurRadius,
          ),
        );
        canvas.restore();
        canvas.restore();
      }
    }

    // 2. Drop Shadows & Outer Glow
    for (final eff in node.effects) {
      if (!eff.isVisible) continue;
      if (eff.type == DesignEffectType.dropShadow) {
        final shadowPaint = Paint()
          ..color = eff.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, eff.blurRadius);
        final shadowRect = rect
            .shift(Offset(eff.offsetX, eff.offsetY))
            .inflate(eff.spreadRadius);
        _drawShapeGeometry(canvas, node, shadowRect, shadowPaint);
      } else if (eff.type == DesignEffectType.outerGlow) {
        final glowPaint = Paint()
          ..color = eff.color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, eff.blurRadius);
        final glowRect = rect.inflate(eff.spreadRadius + 2.0);
        _drawShapeGeometry(canvas, node, glowRect, glowPaint);
      }
    }

    // 3. Layer Blur & Color Filter Effects (Gaussian blur, bloom, grayscale, sepia, invert)
    int effectSaves = 0;
    for (final eff in node.effects) {
      if (!eff.isVisible) continue;
      if (eff.type == DesignEffectType.blur && eff.blurRadius > 0) {
        final blurPaint = Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: eff.blurRadius,
            sigmaY: eff.blurRadius,
          );
        canvas.saveLayer(rect.inflate(eff.blurRadius * 3), blurPaint);
        effectSaves++;
      } else if (eff.type == DesignEffectType.bloom && eff.blurRadius > 0) {
        final bloomPaint = Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: eff.blurRadius,
            sigmaY: eff.blurRadius,
          )
          ..blendMode = BlendMode.screen;
        canvas.saveLayer(rect.inflate(eff.blurRadius * 2), bloomPaint);
        effectSaves++;
      } else if (eff.type == DesignEffectType.grayscale) {
        const matrix = <double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ];
        canvas.saveLayer(rect, Paint()..colorFilter = const ColorFilter.matrix(matrix));
        effectSaves++;
      } else if (eff.type == DesignEffectType.sepia) {
        const matrix = <double>[
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
        ];
        canvas.saveLayer(rect, Paint()..colorFilter = const ColorFilter.matrix(matrix));
        effectSaves++;
      } else if (eff.type == DesignEffectType.invertColors) {
        const matrix = <double>[
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1, 0,
        ];
        canvas.saveLayer(rect, Paint()..colorFilter = const ColorFilter.matrix(matrix));
        effectSaves++;
      }
    }

    // Render Fills (Solid, Linear, Radial, Angular, Image)
    for (final fill in node.fills) {
      if (!fill.isVisible) continue;

      if (fill.type == DesignFillType.image) {
        _renderImageFill(canvas, node, rect, fill);
      } else {
        final fillPaint = Paint()..style = PaintingStyle.fill;

        if (fill.type == DesignFillType.solid) {
          fillPaint.color = fill.color.withValues(
            alpha: fill.color.a * fill.opacity,
          );
        } else if (fill.type == DesignFillType.linearGradient &&
            fill.gradientColors != null &&
            fill.gradientColors!.length >= 2) {
          final rad = fill.gradientAngle * math.pi / 180.0;
          final begin = Alignment(-math.cos(rad), -math.sin(rad));
          final end = Alignment(math.cos(rad), math.sin(rad));
          fillPaint.shader = LinearGradient(
            colors: fill.gradientColors!,
            stops: fill.gradientStops,
            begin: begin,
            end: end,
          ).createShader(rect);
        } else if (fill.type == DesignFillType.radialGradient &&
            fill.gradientColors != null &&
            fill.gradientColors!.length >= 2) {
          fillPaint.shader = RadialGradient(
            colors: fill.gradientColors!,
            stops: fill.gradientStops,
            center: Alignment.center,
            radius: 0.5,
          ).createShader(rect);
        } else if (fill.type == DesignFillType.angularGradient &&
            fill.gradientColors != null &&
            fill.gradientColors!.length >= 2) {
          fillPaint.shader = SweepGradient(
            colors: fill.gradientColors!,
            stops: fill.gradientStops,
            center: Alignment.center,
          ).createShader(rect);
        }

        _drawShapeGeometry(canvas, node, rect, fillPaint);
      }
    }

    // If node itself is an Image node
    if (node.type == NodeType.image) {
      _renderStandaloneImageNode(canvas, node, rect);
    }

    // Render Inner Shadows & Inner Glow
    for (final eff in node.effects) {
      if (!eff.isVisible) continue;
      if (eff.type == DesignEffectType.innerShadow) {
        _renderInnerShadow(canvas, node, rect, eff);
      } else if (eff.type == DesignEffectType.innerGlow) {
        _renderInnerGlow(canvas, node, rect, eff);
      } else if (eff.type == DesignEffectType.colorTint) {
        _renderColorTint(canvas, node, rect, eff);
      } else if (eff.type == DesignEffectType.vignette) {
        _renderVignette(canvas, node, rect, eff);
      }
    }

    // Render Strokes (Solid & Gradient)
    for (final stroke in node.strokes) {
      if (!stroke.isVisible || stroke.width <= 0) continue;
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = stroke.cap
        ..strokeJoin = stroke.join;

      if (stroke.hasGradient) {
        final rad = stroke.gradientAngle * math.pi / 180.0;
        final begin = Alignment(-math.cos(rad), -math.sin(rad));
        final end = Alignment(math.cos(rad), math.sin(rad));
        strokePaint.shader = LinearGradient(
          colors: stroke.gradientColors!,
          stops: stroke.gradientStops,
          begin: begin,
          end: end,
        ).createShader(rect);
      }

      _drawShapeGeometry(canvas, node, rect, strokePaint);
    }

    // Render Text content if this is a Text node
    if (node.type == NodeType.text && node.textData != null) {
      _renderTextNode(canvas, node, rect);
    }

    // Clip content for frames if enabled
    if (node.clipContent) {
      final clipPath = Path()
        ..addRRect(node.cornerRadii.toBorderRadius().toRRect(rect));
      canvas.clipPath(clipPath);
    }

    // Render Children
    for (final childId in node.childrenIds) {
      final childNode = allNodes[childId];
      if (childNode != null) {
        renderNode(canvas, childNode, allNodes);
      }
    }

    // Restore any layer blur or color filter effects
    while (effectSaves > 0) {
      canvas.restore();
      effectSaves--;
    }

    if (node.opacity < 1.0) {
      canvas.restore();
    }

    canvas.restore();
  }

  static Path getNodePath(DesignNode node, Rect rect) {
    switch (node.type) {
      case NodeType.rectangle:
      case NodeType.frame:
      case NodeType.annotationSection:
      case NodeType.image:
        if (node.cornerRadii.uniformValue > 0 || !node.cornerRadii.isUniform) {
          return Path()..addRRect(node.cornerRadii.toBorderRadius().toRRect(rect));
        } else {
          return Path()..addRect(rect);
        }
      case NodeType.roundedRectangle:
        final r = node.cornerRadii.uniformValue > 0
            ? node.cornerRadii.uniformValue
            : 16.0;
        return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
      case NodeType.ellipse:
        return Path()..addOval(rect);
      case NodeType.polygon:
        return _getPolygonPath(rect, node.polygonSides, cornerRadius: node.cornerRadii.uniformValue);
      case NodeType.star:
        return _getStarPath(rect, node.starPoints, node.starInnerRadiusRatio);
      case NodeType.vectorPath:
      case NodeType.freehandPath:
        if (node.vectorData != null && node.vectorData!.anchors.isNotEmpty) {
          return node.vectorData!.toPath(offset: rect.topLeft);
        }
        return Path()..addRect(rect);
      default:
        return Path()..addRect(rect);
    }
  }

  static void _renderImageFill(
    Canvas canvas,
    DesignNode node,
    Rect rect,
    DesignFill fill,
  ) {
    canvas.save();
    canvas.clipPath(getNodePath(node, rect));

    if (fill.imageBase64 != null && fill.imageBase64!.isNotEmpty) {
      final key = fill.imageBase64!;
      if (_imageCache.containsKey(key)) {
        final img = _imageCache[key]!;
        final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
        final paint = Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Colors.white.withValues(alpha: fill.opacity);
        canvas.drawImageRect(img, src, rect, paint);
      } else {
        // Asynchronously decode and cache for subsequent frames
        _decodeAndCacheImage(key);
        _drawPlaceholderImage(canvas, rect, fill.color);
      }
    } else {
      _drawPlaceholderImage(canvas, rect, fill.color);
    }

    canvas.restore();
  }

  static void _renderStandaloneImageNode(
    Canvas canvas,
    DesignNode node,
    Rect rect,
  ) {
    if (node.fills.any((f) => f.type == DesignFillType.image)) return;

    canvas.save();
    canvas.clipPath(getNodePath(node, rect));

    if (node.imagePath != null && node.imagePath!.isNotEmpty) {
      final key = node.imagePath!;
      if (_imageCache.containsKey(key)) {
        final img = _imageCache[key]!;
        final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
        canvas.drawImageRect(img, src, rect, Paint()..filterQuality = FilterQuality.medium);
      } else {
        _decodeAndCacheImage(key);
        _drawPlaceholderImage(canvas, rect, const Color(0xFF64748B));
      }
    } else {
      _drawPlaceholderImage(canvas, rect, const Color(0xFF64748B));
    }

    canvas.restore();
  }

  static void _drawPlaceholderImage(Canvas canvas, Rect rect, Color tint) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tint.withValues(alpha: 0.3),
          tint.withValues(alpha: 0.15),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final iconPaint = Paint()
      ..color = tint.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final iconSize = math.min(rect.width, rect.height) * 0.35;
    if (iconSize > 12) {
      final center = rect.center;
      final iconRect = Rect.fromCenter(center: center, width: iconSize, height: iconSize * 0.75);
      canvas.drawRRect(RRect.fromRectAndRadius(iconRect, const Radius.circular(4)), iconPaint);
      // Small mountain / sun inside placeholder
      final sunCenter = Offset(iconRect.right - iconSize * 0.25, iconRect.top + iconSize * 0.22);
      canvas.drawCircle(sunCenter, iconSize * 0.08, iconPaint);
    }
  }

  static void _decodeAndCacheImage(String base64Data) {
    try {
      final cleanBase64 = base64Data.contains(',')
          ? base64Data.split(',').last
          : base64Data;
      final bytes = base64Decode(cleanBase64);
      ui.decodeImageFromList(bytes, (img) {
        _imageCache[base64Data] = img;
      });
    } catch (_) {
      // Invalid base64 or unsupported image format
    }
  }

  static void _renderInnerShadow(
    Canvas canvas,
    DesignNode node,
    Rect rect,
    DesignEffect eff,
  ) {
    canvas.save();
    final path = getNodePath(node, rect);
    canvas.clipPath(path);

    final shadowPaint = Paint()
      ..color = eff.color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, eff.blurRadius);

    // Draw inverted outer boundary to cast shadow inward
    final outer = Path()
      ..addRect(rect.inflate(eff.blurRadius * 3))
      ..addPath(path.shift(Offset(eff.offsetX, eff.offsetY)), Offset.zero)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(outer, shadowPaint);
    canvas.restore();
  }

  static void _renderInnerGlow(
    Canvas canvas,
    DesignNode node,
    Rect rect,
    DesignEffect eff,
  ) {
    canvas.save();
    final path = getNodePath(node, rect);
    canvas.clipPath(path);

    final glowPaint = Paint()
      ..color = eff.color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, eff.blurRadius);

    final outer = Path()
      ..addRect(rect.inflate(eff.blurRadius * 3))
      ..addPath(path, Offset.zero)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(outer, glowPaint);
    canvas.restore();
  }

  static void _renderColorTint(
    Canvas canvas,
    DesignNode node,
    Rect rect,
    DesignEffect eff,
  ) {
    canvas.save();
    canvas.clipPath(getNodePath(node, rect));
    final tintPaint = Paint()
      ..color = eff.color
      ..blendMode = BlendMode.color;
    canvas.drawRect(rect, tintPaint);
    canvas.restore();
  }

  static void _renderVignette(
    Canvas canvas,
    DesignNode node,
    Rect rect,
    DesignEffect eff,
  ) {
    canvas.save();
    canvas.clipPath(getNodePath(node, rect));
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          eff.color.withValues(alpha: 0.65),
        ],
        stops: const [0.55, 1.0],
        center: Alignment.center,
        radius: 0.85,
      ).createShader(rect);
    canvas.drawRect(rect, vignettePaint);
    canvas.restore();
  }

  static void _drawShapeGeometry(
    Canvas canvas,
    DesignNode node,
    Rect rect,
    Paint paint,
  ) {
    switch (node.type) {
      case NodeType.rectangle:
      case NodeType.frame:
      case NodeType.annotationSection:
      case NodeType.image:
        if (node.cornerRadii.uniformValue > 0 || !node.cornerRadii.isUniform) {
          canvas.drawRRect(
            node.cornerRadii.toBorderRadius().toRRect(rect),
            paint,
          );
        } else {
          canvas.drawRect(rect, paint);
        }
        break;

      case NodeType.roundedRectangle:
        final r = node.cornerRadii.uniformValue > 0
            ? node.cornerRadii.uniformValue
            : 16.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(r)),
          paint,
        );
        break;

      case NodeType.ellipse:
        canvas.drawOval(rect, paint);
        break;

      case NodeType.line:
        canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
        break;

      case NodeType.arrow:
        canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
        _drawArrowhead(canvas, rect.topLeft, rect.bottomRight, paint);
        break;

      case NodeType.polygon:
        final r = node.cornerRadii.uniformValue;
        final path = _getPolygonPath(rect, node.polygonSides, cornerRadius: r);
        canvas.drawPath(path, paint);
        break;

      case NodeType.star:
        final path = _getStarPath(
          rect,
          node.starPoints,
          node.starInnerRadiusRatio,
        );
        canvas.drawPath(path, paint);
        break;

      case NodeType.vectorPath:
      case NodeType.freehandPath:
        if (node.vectorData != null && node.vectorData!.anchors.isNotEmpty) {
          final path = node.vectorData!.toPath(offset: rect.topLeft);
          canvas.drawPath(path, paint);
        }
        break;

      case NodeType.text:
      case NodeType.group:
      case NodeType.componentInstance:
      case NodeType.svg:
        break;
    }
  }

  static TextStyle resolveTextStyle({
    required String fontFamily,
    required double fontSize,
    required FontWeight fontWeight,
    required FontStyle fontStyle,
    required TextDecoration decoration,
    Color? color,
    Paint? foreground,
    List<Shadow>? shadows,
    required double letterSpacing,
    double wordSpacing = 0.0,
    required double height,
  }) {
    try {
      if (foreground != null) {
        return GoogleFonts.getFont(
          fontFamily.trim(),
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          decoration: decoration,
          foreground: foreground,
          shadows: shadows,
          letterSpacing: letterSpacing,
          wordSpacing: wordSpacing,
          height: height,
        );
      }
      return GoogleFonts.getFont(
        fontFamily.trim(),
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        decoration: decoration,
        color: color ?? const Color(0xFF2B3445),
        shadows: shadows,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        decoration: decoration,
        color: foreground == null ? (color ?? const Color(0xFF2B3445)) : null,
        foreground: foreground,
        shadows: shadows,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        height: height,
      );
    }
  }

  /// Accurately measures text dimensions given text data and an optional max width constraint.
  static Size measureText(TextNodeData t, {double maxWidth = double.infinity}) {
    final style = resolveTextStyle(
      fontFamily: t.fontFamily,
      fontSize: t.fontSize,
      fontWeight: t.resolvedFontWeight,
      fontStyle: t.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: t.resolvedDecoration,
      color: Colors.black,
      letterSpacing: t.letterSpacing,
      wordSpacing: t.wordSpacing,
      height: t.lineHeight,
    );

    final textSpan = TextSpan(
      text: t.displayedText.isEmpty ? ' ' : t.displayedText,
      style: style,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: t.textAlign,
    );

    textPainter.layout(maxWidth: maxWidth);
    return Size(
      math.max(24.0, textPainter.width.ceilToDouble()),
      math.max(18.0, textPainter.height.ceilToDouble()),
    );
  }

  static void _renderTextNode(Canvas canvas, DesignNode node, Rect rect) {
    final t = node.textData!;
    final textToRender = t.displayedText;
    if (textToRender.isEmpty) return;

    // 1. Build text shadows from node effects (drop shadow, outer glow)
    final shadows = <Shadow>[];
    for (final eff in node.effects) {
      if (!eff.isVisible) continue;
      if (eff.type == DesignEffectType.dropShadow) {
        shadows.add(Shadow(
          color: eff.color,
          offset: Offset(eff.offsetX, eff.offsetY),
          blurRadius: eff.blurRadius,
        ));
      } else if (eff.type == DesignEffectType.outerGlow) {
        shadows.add(Shadow(
          color: eff.color,
          offset: Offset.zero,
          blurRadius: eff.blurRadius + eff.spreadRadius,
        ));
      }
    }

    final layoutWidth = math.max(10.0, rect.width);

    // 2. Render Text Stroke (if any visible stroke is configured)
    for (final stroke in node.strokes) {
      if (!stroke.isVisible || stroke.width <= 0) continue;

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width * 2 // Outer stroke expansion
        ..strokeCap = stroke.cap
        ..strokeJoin = stroke.join
        ..color = stroke.color;

      if (stroke.hasGradient &&
          stroke.gradientColors != null &&
          stroke.gradientColors!.length >= 2) {
        final rad = stroke.gradientAngle * math.pi / 180.0;
        strokePaint.shader = LinearGradient(
          colors: stroke.gradientColors!,
          stops: stroke.gradientStops,
          begin: Alignment(-math.cos(rad), -math.sin(rad)),
          end: Alignment(math.cos(rad), math.sin(rad)),
        ).createShader(rect);
      }

      final strokeStyle = resolveTextStyle(
        fontFamily: t.fontFamily,
        fontSize: t.fontSize,
        fontWeight: t.resolvedFontWeight,
        fontStyle: t.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: t.resolvedDecoration,
        foreground: strokePaint,
        shadows: shadows.isNotEmpty ? shadows : null,
        letterSpacing: t.letterSpacing,
        wordSpacing: t.wordSpacing,
        height: t.lineHeight,
      );

      final strokePainter = TextPainter(
        text: TextSpan(text: textToRender, style: strokeStyle),
        textDirection: TextDirection.ltr,
        textAlign: t.textAlign,
      );
      strokePainter.layout(minWidth: rect.width, maxWidth: layoutWidth);
      strokePainter.paint(canvas, rect.topLeft);
    }

    // 3. Render Text Fill (Solid or Gradient)
    Paint? fillForeground;
    Color? fillColor;

    if (node.fills.isNotEmpty) {
      final fill = node.fills.firstWhere(
        (f) => f.isVisible,
        orElse: () => node.fills.first,
      );
      if (fill.type == DesignFillType.linearGradient &&
          fill.gradientColors != null &&
          fill.gradientColors!.length >= 2) {
        final rad = fill.gradientAngle * math.pi / 180.0;
        fillForeground = Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            colors: fill.gradientColors!,
            stops: fill.gradientStops,
            begin: Alignment(-math.cos(rad), -math.sin(rad)),
            end: Alignment(math.cos(rad), math.sin(rad)),
          ).createShader(rect);
      } else {
        fillColor = fill.color.withValues(alpha: fill.color.a * fill.opacity);
      }
    } else {
      fillColor = const Color(0xFF2B3445);
    }

    final fillStyle = resolveTextStyle(
      fontFamily: t.fontFamily,
      fontSize: t.fontSize,
      fontWeight: t.resolvedFontWeight,
      fontStyle: t.isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: t.resolvedDecoration,
      color: fillForeground == null ? fillColor : null,
      foreground: fillForeground,
      shadows: (node.strokes.isEmpty && shadows.isNotEmpty) ? shadows : null,
      letterSpacing: t.letterSpacing,
      wordSpacing: t.wordSpacing,
      height: t.lineHeight,
    );

    final fillPainter = TextPainter(
      text: TextSpan(text: textToRender, style: fillStyle),
      textDirection: TextDirection.ltr,
      textAlign: t.textAlign,
    );
    fillPainter.layout(minWidth: rect.width, maxWidth: layoutWidth);
    fillPainter.paint(canvas, rect.topLeft);
  }

  static Path _getPolygonPath(Rect rect, int sides, {double cornerRadius = 0}) {
    final path = Path();
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final rx = rect.width / 2;
    final ry = rect.height / 2;

    final vertices = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i) / sides;
      final px = cx + rx * math.cos(angle);
      final py = cy + ry * math.sin(angle);
      vertices.add(Offset(px, py));
    }

    if (cornerRadius <= 0 || vertices.length < 3) {
      for (int i = 0; i < vertices.length; i++) {
        if (i == 0) {
          path.moveTo(vertices[i].dx, vertices[i].dy);
        } else {
          path.lineTo(vertices[i].dx, vertices[i].dy);
        }
      }
      path.close();
      return path;
    }

    // Fillet each corner with quadratic bezier curves
    for (int i = 0; i < vertices.length; i++) {
      final prev = vertices[(i - 1 + vertices.length) % vertices.length];
      final curr = vertices[i];
      final next = vertices[(i + 1) % vertices.length];

      final vPrev = prev - curr;
      final vNext = next - curr;
      final dPrev = vPrev.distance;
      final dNext = vNext.distance;

      final maxR = math.min(dPrev, dNext) / 2.0;
      final r = math.min(cornerRadius, maxR);

      final pStart = curr + (vPrev / (dPrev == 0 ? 1 : dPrev)) * r;
      final pEnd = curr + (vNext / (dNext == 0 ? 1 : dNext)) * r;

      if (i == 0) {
        path.moveTo(pStart.dx, pStart.dy);
      } else {
        path.lineTo(pStart.dx, pStart.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, pEnd.dx, pEnd.dy);
    }
    path.close();
    return path;
  }

  static Path _getStarPath(Rect rect, int points, double innerRatio) {
    final path = Path();
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final rx = rect.width / 2;
    final ry = rect.height / 2;
    final total = points * 2;

    for (int i = 0; i < total; i++) {
      final angle = -math.pi / 2 + (math.pi * i) / points;
      final radiusX = (i % 2 == 0) ? rx : rx * innerRatio;
      final radiusY = (i % 2 == 0) ? ry : ry * innerRatio;
      final px = cx + radiusX * math.cos(angle);
      final py = cy + radiusY * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    return path;
  }

  static void _drawArrowhead(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const headLength = 12.0;
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    final arrowPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(p2.dx, p2.dy);
    path.lineTo(
      p2.dx - headLength * math.cos(angle - math.pi / 6),
      p2.dy - headLength * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      p2.dx - headLength * math.cos(angle + math.pi / 6),
      p2.dy - headLength * math.sin(angle + math.pi / 6),
    );
    path.close();
    canvas.drawPath(path, arrowPaint);
  }
}
