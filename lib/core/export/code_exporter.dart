import '../../domain/models/node_model.dart';
import '../../domain/models/node_types.dart';
import '../../domain/models/paint_styles.dart';

class CodeExporter {
  CodeExporter._();

  /// Generates CSS-like styling snippet for a design node.
  static String generateCss(DesignNode node) {
    final buffer = StringBuffer();
    buffer.writeln('/* ${node.name} (${node.type.displayName}) */');
    buffer.writeln('.${_sanitizeClassName(node.name)} {');
    buffer.writeln('  position: absolute;');
    buffer.writeln('  left: ${node.x.toStringAsFixed(1)}px;');
    buffer.writeln('  top: ${node.y.toStringAsFixed(1)}px;');
    buffer.writeln('  width: ${node.width.toStringAsFixed(1)}px;');
    buffer.writeln('  height: ${node.height.toStringAsFixed(1)}px;');

    if (node.rotation != 0) {
      buffer.writeln(
        '  transform: rotate(${node.rotation.toStringAsFixed(1)}deg);',
      );
    }

    if (node.opacity < 1.0) {
      buffer.writeln('  opacity: ${node.opacity.toStringAsFixed(2)};');
    }

    // Fills
    if (node.fills.isNotEmpty) {
      final fill = node.fills.firstWhere(
        (f) => f.isVisible,
        orElse: () => node.fills.first,
      );
      if (fill.type == DesignFillType.solid) {
        buffer.writeln('  background-color: ${_colorToHex(fill.color)};');
      } else if (fill.type == DesignFillType.linearGradient &&
          fill.gradientColors != null) {
        final colors = fill.gradientColors!.map(_colorToHex).join(', ');
        buffer.writeln('  background: linear-gradient(135deg, $colors);');
      }
    }

    // Strokes
    if (node.strokes.isNotEmpty && node.strokes.first.isVisible) {
      final s = node.strokes.first;
      buffer.writeln(
        '  border: ${s.width.toStringAsFixed(1)}px solid ${_colorToHex(s.color)};',
      );
    }

    // Corner Radii
    if (!node.cornerRadii.isUniform) {
      buffer.writeln(
        '  border-radius: ${node.cornerRadii.topLeft}px ${node.cornerRadii.topRight}px ${node.cornerRadii.bottomRight}px ${node.cornerRadii.bottomLeft}px;',
      );
    } else if (node.cornerRadii.uniformValue > 0) {
      buffer.writeln('  border-radius: ${node.cornerRadii.uniformValue}px;');
    }

    // Box Shadows
    for (final eff in node.effects) {
      if (eff.isVisible && eff.type == DesignEffectType.dropShadow) {
        buffer.writeln(
          '  box-shadow: ${eff.offsetX}px ${eff.offsetY}px ${eff.blurRadius}px ${_colorToRgba(eff.color)};',
        );
      }
    }

    // Text properties
    if (node.type == NodeType.text && node.textData != null) {
      final t = node.textData!;
      buffer.writeln("  font-family: '${t.fontFamily}', sans-serif;");
      buffer.writeln('  font-size: ${t.fontSize.toStringAsFixed(1)}px;');
      buffer.writeln('  font-weight: ${t.fontWeight};');
      buffer.writeln('  line-height: ${t.lineHeight};');
      buffer.writeln('  text-align: ${t.textAlign.name};');
      if (t.letterSpacing != 0) {
        buffer.writeln(
          '  letter-spacing: ${t.letterSpacing.toStringAsFixed(1)}px;',
        );
      }
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Generates approximate Flutter widget code for a design node.
  static String generateFlutterWidget(DesignNode node) {
    if (node.type == NodeType.text && node.textData != null) {
      final t = node.textData!;
      final colorHex = node.fills.isNotEmpty
          ? _colorToHex(node.fills.first.color)
          : '#2B3445';
      return '''
Text(
  '${t.text.replaceAll("'", "\\'")}',
  textAlign: TextAlign.${t.textAlign.name},
  style: TextStyle(
    fontFamily: '${t.fontFamily}',
    fontSize: ${t.fontSize},
    fontWeight: FontWeight.w${t.fontWeight},
    color: Color(0x${colorHex.replaceAll('#', 'FF')}),
    letterSpacing: ${t.letterSpacing},
    height: ${t.lineHeight},
  ),
)''';
    }

    final buffer = StringBuffer();
    buffer.writeln('Container(');
    buffer.writeln('  width: ${node.width.toStringAsFixed(1)},');
    buffer.writeln('  height: ${node.height.toStringAsFixed(1)},');

    final hasBorder = node.strokes.isNotEmpty && node.strokes.first.isVisible;
    final hasRadius =
        node.cornerRadii.uniformValue > 0 || !node.cornerRadii.isUniform;
    final hasShadow = node.effects.any(
      (e) => e.isVisible && e.type == DesignEffectType.dropShadow,
    );
    final hasFill = node.fills.isNotEmpty && node.fills.first.isVisible;

    if (hasBorder || hasRadius || hasShadow || hasFill) {
      buffer.writeln('  decoration: BoxDecoration(');
      if (hasFill) {
        final fill = node.fills.first;
        if (fill.type == DesignFillType.solid) {
          buffer.writeln(
            '    color: Color(0x${_colorToHex(fill.color).replaceAll('#', 'FF')}),',
          );
        } else if (fill.type == DesignFillType.linearGradient &&
            fill.gradientColors != null) {
          final colors = fill.gradientColors!
              .map((c) => 'Color(0x${_colorToHex(c).replaceAll('#', 'FF')})')
              .join(', ');
          buffer.writeln('    gradient: LinearGradient(');
          buffer.writeln('      colors: [$colors],');
          buffer.writeln('      begin: Alignment.topLeft,');
          buffer.writeln('      end: Alignment.bottomRight,');
          buffer.writeln('    ),');
        }
      }
      if (hasRadius) {
        if (node.cornerRadii.isUniform) {
          buffer.writeln(
            '    borderRadius: BorderRadius.circular(${node.cornerRadii.uniformValue}),',
          );
        } else {
          buffer.writeln('    borderRadius: BorderRadius.only(');
          buffer.writeln(
            '      topLeft: Radius.circular(${node.cornerRadii.topLeft}),',
          );
          buffer.writeln(
            '      topRight: Radius.circular(${node.cornerRadii.topRight}),',
          );
          buffer.writeln(
            '      bottomRight: Radius.circular(${node.cornerRadii.bottomRight}),',
          );
          buffer.writeln(
            '      bottomLeft: Radius.circular(${node.cornerRadii.bottomLeft}),',
          );
          buffer.writeln('    ),');
        }
      }
      if (hasBorder) {
        final s = node.strokes.first;
        buffer.writeln(
          '    border: Border.all(color: Color(0x${_colorToHex(s.color).replaceAll('#', 'FF')}), width: ${s.width}),',
        );
      }
      if (hasShadow) {
        final eff = node.effects.firstWhere(
          (e) => e.isVisible && e.type == DesignEffectType.dropShadow,
        );
        buffer.writeln('    boxShadow: [');
        buffer.writeln('      BoxShadow(');
        buffer.writeln(
          '        color: Color(0x${_colorToHex(eff.color).replaceAll('#', '33')}),',
        );
        buffer.writeln(
          '        offset: Offset(${eff.offsetX}, ${eff.offsetY}),',
        );
        buffer.writeln('        blurRadius: ${eff.blurRadius},');
        buffer.writeln('      ),');
        buffer.writeln('    ],');
      }
      buffer.writeln('  ),');
    }

    if (node.clipContent) {
      buffer.writeln('  clipBehavior: Clip.antiAlias,');
    }

    buffer.writeln(')');
    return buffer.toString();
  }

  static String _sanitizeClassName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '-');
  }

  static String _colorToHex(dynamic color) {
    final c = color as dynamic;
    final r = ((c.r as num) * 255).round().toRadixString(16).padLeft(2, '0');
    final g = ((c.g as num) * 255).round().toRadixString(16).padLeft(2, '0');
    final b = ((c.b as num) * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  static String _colorToRgba(dynamic color) {
    final c = color as dynamic;
    final r = ((c.r as num) * 255).round();
    final g = ((c.g as num) * 255).round();
    final b = ((c.b as num) * 255).round();
    final a = (c.a as num).toStringAsFixed(2);
    return 'rgba($r, $g, $b, $a)';
  }
}
