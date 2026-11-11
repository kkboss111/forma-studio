import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/forma_theme.dart';
import '../../../../core/export/file_saver_service.dart';
import '../../../../domain/models/editor_tab_model.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../domain/models/paint_styles.dart';
import '../../../../domain/models/project_model.dart';
import '../../../../domain/models/vector_data.dart';
import '../../../../domain/services/node_render_service.dart';

/// Tools available in the dedicated Icon Studio Canvas.
enum IconStudioTool {
  select,
  pen,
  rectangle,
  roundedRectangle,
  circle,
  line,
  star,
  eraser,
}

/// A dedicated bounded canvas for designing pixel-perfect vector icons.
/// Unlike the infinite canvas, this studio operates within strict bounded presets
/// (16x16, 24x24, 32x32, 48x48, 64x64, 128x128) with precision pixel grids,
/// Material & Apple keyline guides, real-time multi-scale preview dock, and direct SVG/PNG export.
class IconCanvasViewport extends ConsumerStatefulWidget {
  /// The tab model backing this icon canvas.
  final EditorTab tab;

  /// Optional project reference if integrated with parent editor state.
  final ProjectModel? project;

  /// Callback when the tab's nodes or configuration are modified.
  final ValueChanged<EditorTab>? onTabChanged;

  /// Callback to close this icon studio tab.
  final VoidCallback? onClose;

  const IconCanvasViewport({
    super.key,
    required this.tab,
    this.project,
    this.onTabChanged,
    this.onClose,
  });

  @override
  ConsumerState<IconCanvasViewport> createState() => _IconCanvasViewportState();
}

class _IconCanvasViewportState extends ConsumerState<IconCanvasViewport> {
  static const List<double> presetSizes = [16, 24, 32, 48, 64, 128];
  static const Uuid _uuid = Uuid();

  late double _iconSize;
  late List<DesignNode> _nodes;
  String? _selectedNodeId;

  // Viewport navigation
  double _zoom = 18.0;
  Offset _panOffset = Offset.zero;

  // Display toggles
  late bool _showPixelGrid;
  late bool _showSubpixelGrid;
  late bool _showKeylines;
  late bool _showCenterAxes;
  late bool _snapToPixel;
  bool _showPreviewDock = true;
  bool _darkPreviewTile = true;

  // Active Tool & Style State
  IconStudioTool _activeTool = IconStudioTool.select;
  Color _strokeColor = const Color(0xFF0F172A);
  Color? _fillColor;
  double _strokeWidth = 2.0;
  final StrokeCap _strokeCap = StrokeCap.round;
  final StrokeJoin _strokeJoin = StrokeJoin.round;

  // Interactive drawing & manipulation state
  bool _isPanning = false;
  Offset? _panStartScreen;
  Offset? _drawingStart;
  Offset? _drawingCurrent;
  final List<Offset> _activePenPoints = [];
  Offset? _hoveredArtboardPos;
  DesignNode? _transformingNodeOriginal;
  Offset? _nodeMoveStart;

  // Undo / Redo history
  final List<List<DesignNode>> _undoHistory = [];
  final List<List<DesignNode>> _redoHistory = [];

  @override
  void initState() {
    super.initState();
    _iconSize = widget.tab.iconSize;
    _nodes = List<DesignNode>.from(widget.tab.nodes);
    _showPixelGrid = widget.tab.showPixelGrid;
    _showSubpixelGrid = widget.tab.showSubpixelGrid;
    _showKeylines = widget.tab.showKeylines;
    _showCenterAxes = widget.tab.showCenterAxes;
    _snapToPixel = widget.tab.snapToPixel;

    if (_nodes.isEmpty) {
      _loadTemplateGlyph('heart');
    }
  }

  @override
  void didUpdateWidget(covariant IconCanvasViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab.id != widget.tab.id) {
      _iconSize = widget.tab.iconSize;
      _nodes = List<DesignNode>.from(widget.tab.nodes);
      _selectedNodeId = null;
      _undoHistory.clear();
      _redoHistory.clear();
    }
  }

  void _recordHistory() {
    _undoHistory.add(List<DesignNode>.from(_nodes));
    _redoHistory.clear();
    if (_undoHistory.length > 50) {
      _undoHistory.removeAt(0);
    }
  }

  void _undo() {
    if (_undoHistory.isEmpty) return;
    _redoHistory.add(List<DesignNode>.from(_nodes));
    setState(() {
      _nodes = _undoHistory.removeLast();
      _selectedNodeId = null;
    });
    _notifyTabChanged();
  }

  void _redo() {
    if (_redoHistory.isEmpty) return;
    _undoHistory.add(List<DesignNode>.from(_nodes));
    setState(() {
      _nodes = _redoHistory.removeLast();
      _selectedNodeId = null;
    });
    _notifyTabChanged();
  }

  void _notifyTabChanged() {
    widget.onTabChanged?.call(
      widget.tab.copyWith(
        iconSize: _iconSize,
        nodes: _nodes,
        isModified: true,
        showPixelGrid: _showPixelGrid,
        showSubpixelGrid: _showSubpixelGrid,
        showKeylines: _showKeylines,
        showCenterAxes: _showCenterAxes,
        snapToPixel: _snapToPixel,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Geometry & Coordinate Conversion
  // Maps between viewport screen coordinates and centered bounded icon artboard.
  // ---------------------------------------------------------------------------
  Rect _getArtboardRect(Size viewportSize) {
    final center = Offset(viewportSize.width / 2, viewportSize.height / 2) + _panOffset;
    final artboardPixelSize = _iconSize * _zoom;
    return Rect.fromCenter(
      center: center,
      width: artboardPixelSize,
      height: artboardPixelSize,
    );
  }

  Offset _screenToArtboard(
    Offset screenPos,
    Size viewportSize, {
    bool clampToBounds = true,
  }) {
    final artboardRect = _getArtboardRect(viewportSize);
    final relative = screenPos - artboardRect.topLeft;
    double x = relative.dx / _zoom;
    double y = relative.dy / _zoom;

    if (clampToBounds) {
      x = x.clamp(0.0, _iconSize);
      y = y.clamp(0.0, _iconSize);
    }

    if (_snapToPixel) {
      x = x.roundToDouble();
      y = y.roundToDouble();
    }

    return Offset(x, y);
  }

  void _fitToViewport(Size viewportSize) {
    final available = math.min(viewportSize.width - 240, viewportSize.height - 240);
    final targetZoom = (available / _iconSize).clamp(4.0, 48.0);
    setState(() {
      _zoom = targetZoom;
      _panOffset = Offset.zero;
    });
  }

  void _setSizePreset(double newSize) {
    if (_iconSize == newSize) return;
    _recordHistory();
    setState(() {
      final scaleFactor = newSize / _iconSize;
      _nodes = _nodes.map((n) {
        return n.copyWith(
          x: n.x * scaleFactor,
          y: n.y * scaleFactor,
          width: n.width * scaleFactor,
          height: n.height * scaleFactor,
        );
      }).toList();
      _iconSize = newSize;
    });
    _notifyTabChanged();
  }

  // ---------------------------------------------------------------------------
  // Starter Glyph Templates
  // ---------------------------------------------------------------------------
  void _loadTemplateGlyph(String template) {
    _recordHistory();
    final s = _iconSize;
    final color = _strokeColor;
    final w = _strokeWidth;

    List<DesignNode> newNodes = [];

    switch (template) {
      case 'heart':
        final anchors = [
          VectorAnchor(point: Offset(s * 0.5, s * 0.8), handleIn: Offset(-s * 0.1, 0), handleOut: Offset(s * 0.1, 0)),
          VectorAnchor(point: Offset(s * 0.18, s * 0.45), handleIn: Offset(0, s * 0.15), handleOut: Offset(0, -s * 0.15), isSmooth: true),
          VectorAnchor(point: Offset(s * 0.32, s * 0.22), handleIn: Offset(-s * 0.08, 0), handleOut: Offset(s * 0.08, 0), isSmooth: true),
          VectorAnchor(point: Offset(s * 0.5, s * 0.38), handleIn: Offset(-s * 0.05, -s * 0.05), handleOut: Offset(s * 0.05, -s * 0.05)),
          VectorAnchor(point: Offset(s * 0.68, s * 0.22), handleIn: Offset(-s * 0.08, 0), handleOut: Offset(s * 0.08, 0), isSmooth: true),
          VectorAnchor(point: Offset(s * 0.82, s * 0.45), handleIn: Offset(0, -s * 0.15), handleOut: Offset(0, s * 0.15), isSmooth: true),
        ];
        newNodes.add(
          DesignNode(
            id: _uuid.v4(),
            type: NodeType.vectorPath,
            name: 'Heart Path',
            x: 0,
            y: 0,
            width: s,
            height: s,
            vectorData: VectorPathData(anchors: anchors, isClosed: true),
            strokes: [DesignStroke(color: color, width: w, cap: _strokeCap, join: _strokeJoin)],
            fills: _fillColor != null ? [DesignFill(color: _fillColor!)] : const [],
          ),
        );
        break;

      case 'search':
        final r = s * 0.32;
        newNodes.add(
          DesignNode(
            id: _uuid.v4(),
            type: NodeType.ellipse,
            name: 'Lens',
            x: s * 0.15,
            y: s * 0.15,
            width: r * 2,
            height: r * 2,
            strokes: [DesignStroke(color: color, width: w, cap: _strokeCap, join: _strokeJoin)],
            fills: const [],
          ),
        );
        newNodes.add(
          DesignNode(
            id: _uuid.v4(),
            type: NodeType.line,
            name: 'Handle',
            x: s * 0.60,
            y: s * 0.60,
            width: s * 0.25,
            height: s * 0.25,
            strokes: [DesignStroke(color: color, width: w, cap: _strokeCap, join: _strokeJoin)],
            fills: const [],
          ),
        );
        break;

      case 'check':
        final anchors = [
          VectorAnchor(point: Offset(s * 0.2, s * 0.52)),
          VectorAnchor(point: Offset(s * 0.42, s * 0.74)),
          VectorAnchor(point: Offset(s * 0.82, s * 0.28)),
        ];
        newNodes.add(
          DesignNode(
            id: _uuid.v4(),
            type: NodeType.vectorPath,
            name: 'Checkmark',
            x: 0,
            y: 0,
            width: s,
            height: s,
            vectorData: VectorPathData(anchors: anchors, isClosed: false),
            strokes: [DesignStroke(color: color, width: w, cap: _strokeCap, join: _strokeJoin)],
            fills: const [],
          ),
        );
        break;

      case 'plus':
        newNodes.add(
          DesignNode(
            id: _uuid.v4(),
            type: NodeType.line,
            name: 'Horizontal',
            x: s * 0.2,
            y: s * 0.5,
            width: s * 0.6,
            height: 0,
            strokes: [DesignStroke(color: color, width: w, cap: _strokeCap, join: _strokeJoin)],
            fills: const [],
          ),
        );
        newNodes.add(
          DesignNode(
            id: _uuid.v4(),
            type: NodeType.line,
            name: 'Vertical',
            x: s * 0.5,
            y: s * 0.2,
            width: 0,
            height: s * 0.6,
            strokes: [DesignStroke(color: color, width: w, cap: _strokeCap, join: _strokeJoin)],
            fills: const [],
          ),
        );
        break;

      case 'empty':
        break;
    }

    setState(() {
      _nodes = newNodes;
      _selectedNodeId = null;
    });
    _notifyTabChanged();
  }

  // ---------------------------------------------------------------------------
  // Gesture Handling with Accurate Screen-To-Artboard Mapping
  // ---------------------------------------------------------------------------
  void _onPanDown(DragDownDetails details, Size viewportSize) {
    final screenPos = details.localPosition;
    final artboardRect = _getArtboardRect(viewportSize);

    // If spacebar is pressed, middle-click, or touch is outside artboard boundary, pan viewport
    if (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.space) ||
        !artboardRect.inflate(20).contains(screenPos)) {
      _isPanning = true;
      _panStartScreen = screenPos;
      return;
    }

    _isPanning = false;
    final artboardPt = _screenToArtboard(screenPos, viewportSize);

    if (_activeTool == IconStudioTool.select) {
      String? hitId;
      for (int i = _nodes.length - 1; i >= 0; i--) {
        final n = _nodes[i];
        if (n.rect.inflate(2.0).contains(artboardPt)) {
          hitId = n.id;
          break;
        }
      }

      setState(() {
        _selectedNodeId = hitId;
      });

      if (hitId != null) {
        _nodeMoveStart = artboardPt;
        _transformingNodeOriginal = _nodes.firstWhere((n) => n.id == hitId);
        _recordHistory();
      }
    } else if (_activeTool == IconStudioTool.pen) {
      setState(() {
        _activePenPoints.add(artboardPt);
      });
    } else if (_activeTool == IconStudioTool.eraser) {
      for (int i = _nodes.length - 1; i >= 0; i--) {
        if (_nodes[i].rect.inflate(3.0).contains(artboardPt)) {
          _recordHistory();
          setState(() {
            _nodes.removeAt(i);
            _selectedNodeId = null;
          });
          _notifyTabChanged();
          break;
        }
      }
    } else {
      // Shape tool drag initiation
      setState(() {
        _drawingStart = artboardPt;
        _drawingCurrent = artboardPt;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size viewportSize) {
    final screenPos = details.localPosition;

    if (_isPanning) {
      if (_panStartScreen != null) {
        setState(() {
          _panOffset += (screenPos - _panStartScreen!);
          _panStartScreen = screenPos;
        });
      }
      return;
    }

    final artboardPt = _screenToArtboard(screenPos, viewportSize);
    setState(() => _hoveredArtboardPos = artboardPt);

    if (_activeTool == IconStudioTool.select &&
        _selectedNodeId != null &&
        _nodeMoveStart != null &&
        _transformingNodeOriginal != null) {
      final delta = artboardPt - _nodeMoveStart!;
      setState(() {
        final idx = _nodes.indexWhere((n) => n.id == _selectedNodeId);
        if (idx != -1) {
          final orig = _transformingNodeOriginal!;
          _nodes[idx] = orig.copyWith(
            x: (orig.x + delta.dx).clamp(0.0, _iconSize - orig.width),
            y: (orig.y + delta.dy).clamp(0.0, _iconSize - orig.height),
          );
        }
      });
    } else if (_activeTool == IconStudioTool.pen && _activePenPoints.isNotEmpty) {
      if ((_activePenPoints.last - artboardPt).distance > 0.5) {
        setState(() {
          _activePenPoints.add(artboardPt);
        });
      }
    } else if (_drawingStart != null) {
      setState(() {
        _drawingCurrent = artboardPt;
      });
    }
  }

  void _onPanEnd(DragEndDetails details, Size viewportSize) {
    if (_isPanning) {
      _isPanning = false;
      _panStartScreen = null;
      return;
    }

    if (_activeTool == IconStudioTool.select) {
      _nodeMoveStart = null;
      _transformingNodeOriginal = null;
      _notifyTabChanged();
      return;
    }

    if (_drawingStart != null && _drawingCurrent != null && _activeTool != IconStudioTool.pen) {
      final start = _drawingStart!;
      final end = _drawingCurrent!;
      final rect = Rect.fromPoints(start, end);

      if (rect.width >= 0.5 || rect.height >= 0.5) {
        _recordHistory();
        final id = _uuid.v4();
        DesignNode? created;

        final strokes = [
          DesignStroke(
            color: _strokeColor,
            width: _strokeWidth,
            cap: _strokeCap,
            join: _strokeJoin,
          ),
        ];
        final fills = _fillColor != null ? [DesignFill(color: _fillColor!)] : <DesignFill>[];

        switch (_activeTool) {
          case IconStudioTool.rectangle:
            created = DesignNode(
              id: id,
              name: 'Rectangle',
              type: NodeType.rectangle,
              x: rect.left,
              y: rect.top,
              width: math.max(1.0, rect.width),
              height: math.max(1.0, rect.height),
              strokes: strokes,
              fills: fills,
            );
            break;
          case IconStudioTool.roundedRectangle:
            created = DesignNode(
              id: id,
              name: 'Rounded Rect',
              type: NodeType.roundedRectangle,
              x: rect.left,
              y: rect.top,
              width: math.max(1.0, rect.width),
              height: math.max(1.0, rect.height),
              cornerRadii: const CornerRadii.all(3.0),
              strokes: strokes,
              fills: fills,
            );
            break;
          case IconStudioTool.circle:
            created = DesignNode(
              id: id,
              name: 'Circle',
              type: NodeType.ellipse,
              x: rect.left,
              y: rect.top,
              width: math.max(1.0, rect.width),
              height: math.max(1.0, rect.height),
              strokes: strokes,
              fills: fills,
            );
            break;
          case IconStudioTool.line:
            created = DesignNode(
              id: id,
              name: 'Line',
              type: NodeType.line,
              x: start.dx,
              y: start.dy,
              width: end.dx - start.dx,
              height: end.dy - start.dy,
              strokes: strokes,
              fills: const [],
            );
            break;
          case IconStudioTool.star:
            created = DesignNode(
              id: id,
              name: 'Star',
              type: NodeType.star,
              x: rect.left,
              y: rect.top,
              width: math.max(1.0, rect.width),
              height: math.max(1.0, rect.height),
              starPoints: 5,
              starInnerRadiusRatio: 0.4,
              strokes: strokes,
              fills: fills,
            );
            break;
          default:
            break;
        }

        if (created != null) {
          setState(() {
            _nodes.add(created!);
            _selectedNodeId = created.id;
          });
          _notifyTabChanged();
        }
      }

      setState(() {
        _drawingStart = null;
        _drawingCurrent = null;
      });
    }
  }

  void _onTapDown(TapDownDetails details, Size viewportSize) {
    final screenPos = details.localPosition;
    final artboardPt = _screenToArtboard(screenPos, viewportSize);

    if (_activeTool == IconStudioTool.pen) {
      setState(() {
        _activePenPoints.add(artboardPt);
      });
    } else if (_activeTool == IconStudioTool.select) {
      String? hitId;
      for (int i = _nodes.length - 1; i >= 0; i--) {
        final n = _nodes[i];
        if (n.rect.inflate(2.0).contains(artboardPt)) {
          hitId = n.id;
          break;
        }
      }
      setState(() {
        _selectedNodeId = hitId;
      });
    }
  }

  void _finishPenPath(bool closeLoop) {
    if (_activePenPoints.length < 2) {
      setState(() => _activePenPoints.clear());
      return;
    }

    _recordHistory();
    final anchors = _activePenPoints.map((pt) => VectorAnchor(point: pt)).toList();
    final id = _uuid.v4();

    final node = DesignNode(
      id: id,
      name: 'Custom Path',
      type: NodeType.vectorPath,
      x: 0,
      y: 0,
      width: _iconSize,
      height: _iconSize,
      vectorData: VectorPathData(anchors: anchors, isClosed: closeLoop),
      strokes: [
        DesignStroke(
          color: _strokeColor,
          width: _strokeWidth,
          cap: _strokeCap,
          join: _strokeJoin,
        ),
      ],
      fills: (_fillColor != null && closeLoop) ? [DesignFill(color: _fillColor!)] : const [],
    );

    setState(() {
      _nodes.add(node);
      _selectedNodeId = node.id;
      _activePenPoints.clear();
      _activeTool = IconStudioTool.select;
    });
    _notifyTabChanged();
  }

  // ---------------------------------------------------------------------------
  // Export methods (SVG & PNG)
  // ---------------------------------------------------------------------------
  String _buildSvgString() {
    final s = _iconSize.toInt();
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $s $s" width="$s" height="$s" fill="none">');

    for (final node in _nodes) {
      if (!node.isVisible) continue;
      final strokeHex = node.strokes.isNotEmpty
          ? '#${node.strokes.first.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'
          : 'none';
      final strokeW = node.strokes.isNotEmpty ? node.strokes.first.width : 0.0;
      final fillHex = node.fills.isNotEmpty
          ? '#${node.fills.first.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'
          : 'none';

      final cap = node.strokes.isNotEmpty ? node.strokes.first.cap.name : 'round';
      final join = node.strokes.isNotEmpty ? node.strokes.first.join.name : 'round';

      switch (node.type) {
        case NodeType.rectangle:
          buffer.writeln(
            '  <rect x="${node.x}" y="${node.y}" width="${node.width}" height="${node.height}" fill="$fillHex" stroke="$strokeHex" stroke-width="$strokeW" stroke-linecap="$cap" stroke-linejoin="$join" />',
          );
          break;
        case NodeType.roundedRectangle:
          final rx = node.cornerRadii.topLeft;
          buffer.writeln(
            '  <rect x="${node.x}" y="${node.y}" width="${node.width}" height="${node.height}" rx="$rx" fill="$fillHex" stroke="$strokeHex" stroke-width="$strokeW" stroke-linecap="$cap" stroke-linejoin="$join" />',
          );
          break;
        case NodeType.ellipse:
          final cx = node.x + node.width / 2;
          final cy = node.y + node.height / 2;
          final rx = node.width / 2;
          final ry = node.height / 2;
          buffer.writeln(
            '  <ellipse cx="$cx" cy="$cy" rx="$rx" ry="$ry" fill="$fillHex" stroke="$strokeHex" stroke-width="$strokeW" stroke-linecap="$cap" stroke-linejoin="$join" />',
          );
          break;
        case NodeType.line:
          final x2 = node.x + node.width;
          final y2 = node.y + node.height;
          buffer.writeln(
            '  <line x1="${node.x}" y1="${node.y}" x2="$x2" y2="$y2" stroke="$strokeHex" stroke-width="$strokeW" stroke-linecap="$cap" stroke-linejoin="$join" />',
          );
          break;
        case NodeType.vectorPath:
          if (node.vectorData != null && node.vectorData!.anchors.isNotEmpty) {
            final anchors = node.vectorData!.anchors;
            final dBuf = StringBuffer();
            dBuf.write('M ${anchors.first.point.dx} ${anchors.first.point.dy} ');
            for (int i = 1; i < anchors.length; i++) {
              final a = anchors[i];
              dBuf.write('L ${a.point.dx} ${a.point.dy} ');
            }
            if (node.vectorData!.isClosed) {
              dBuf.write('Z');
            }
            buffer.writeln(
              '  <path d="${dBuf.toString().trim()}" fill="$fillHex" stroke="$strokeHex" stroke-width="$strokeW" stroke-linecap="$cap" stroke-linejoin="$join" />',
            );
          }
          break;
        default:
          break;
      }
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  Future<void> _exportSvg() async {
    final svgContent = _buildSvgString();
    final filename = '${widget.tab.title.replaceAll(RegExp(r'\s+'), '_').toLowerCase()}_${_iconSize.toInt()}px.svg';
    final encoder = Encoding.getByName('utf-8')!;
    final bytes = Uint8List.fromList(encoder.encode(svgContent));
    final success = await FileSaverService.saveFile(
      bytes: bytes,
      filename: filename,
      mimeType: 'image/svg+xml',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Exported SVG ($filename)' : 'SVG Download triggered'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copySvgToClipboard() async {
    final svgContent = _buildSvgString();
    await Clipboard.setData(ClipboardData(text: svgContent));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SVG code copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportPng(double scale) async {
    final px = (_iconSize * scale).toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(scale, scale);

    final nodeMap = {for (final n in _nodes) n.id: n};
    for (final node in _nodes) {
      NodeRenderService.renderNode(canvas, node, nodeMap);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(px, px);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final bytes = byteData.buffer.asUint8List();
    final filename = '${widget.tab.title.replaceAll(RegExp(r'\s+'), '_').toLowerCase()}_${_iconSize.toInt()}px@${scale.toInt()}x.png';
    await FileSaverService.saveFile(
      bytes: bytes,
      filename: filename,
      mimeType: 'image/png',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported PNG (${px}x$px)'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = FormaTheme.tokensOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Container(
          color: tokens.isDark ? const Color(0xFF080C14) : const Color(0xFFF1EFEA),
          child: Stack(
            children: [
              // 1. Interactive Canvas Gestures Area (Pan, Draw, Select)
              Positioned.fill(
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      if (HardwareKeyboard.instance.isControlPressed ||
                          HardwareKeyboard.instance.isMetaPressed) {
                        final factor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
                        setState(() {
                          _zoom = (_zoom * factor).clamp(3.0, 64.0);
                        });
                      } else {
                        setState(() {
                          _panOffset -= event.scrollDelta;
                        });
                      }
                    }
                  },
                  child: MouseRegion(
                    cursor: _activeTool == IconStudioTool.select
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.precise,
                    onHover: (e) {
                      final pt = _screenToArtboard(e.localPosition, viewportSize);
                      setState(() => _hoveredArtboardPos = pt);
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (d) => _onPanDown(d, viewportSize),
                      onPanUpdate: (d) => _onPanUpdate(d, viewportSize),
                      onPanEnd: (d) => _onPanEnd(d, viewportSize),
                      onTapDown: (d) => _onTapDown(d, viewportSize),
                      child: CustomPaint(
                        size: viewportSize,
                        painter: _BoundedIconCanvasPainter(
                          iconSize: _iconSize,
                          zoom: _zoom,
                          panOffset: _panOffset,
                          nodes: _nodes,
                          selectedNodeId: _selectedNodeId,
                          showPixelGrid: _showPixelGrid,
                          showSubpixelGrid: _showSubpixelGrid,
                          showKeylines: _showKeylines,
                          showCenterAxes: _showCenterAxes,
                          activePenPoints: _activePenPoints,
                          drawingStart: _drawingStart,
                          drawingCurrent: _drawingCurrent,
                          activeTool: _activeTool,
                          isDarkTheme: tokens.isDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Sleek Floating Top Control HUD
              Positioned(
                top: 12,
                left: 14,
                right: 14,
                child: _buildTopToolbar(context, tokens, viewportSize),
              ),

              // 3. Floating Pen Drafting Assistant Bar
              if (_activeTool == IconStudioTool.pen && _activePenPoints.isNotEmpty)
                Positioned(
                  top: 64,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: tokens.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: tokens.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.polyline_rounded, size: 16, color: FormaColors.primaryBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Vector Drafting: ${_activePenPoints.length} points',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: tokens.textMain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.loop_rounded, size: 14),
                            label: const Text('Close Loop', style: TextStyle(fontSize: 11)),
                            onPressed: () => _finishPenPath(true),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tokens.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 14),
                            label: const Text('Finish Open Path', style: TextStyle(fontSize: 11)),
                            onPressed: () => _finishPenPath(false),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 14),
                            tooltip: 'Cancel Path',
                            onPressed: () => setState(() => _activePenPoints.clear()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Live Multi-Scale Preview Dock (Bottom-Right)
              if (_showPreviewDock)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _buildMultiScalePreviewDock(context, tokens),
                ),

              // 5. Floating Zoom & Viewport Controls (Bottom-Left)
              Positioned(
                bottom: 16,
                left: 16,
                child: _buildZoomAndPresetsHUD(context, tokens, viewportSize),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Top Toolbar HUD
  // ---------------------------------------------------------------------------
  Widget _buildTopToolbar(
    BuildContext context,
    FormaThemeTokens tokens,
    Size viewportSize,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.surface.withValues(alpha: tokens.isDark ? 0.85 : 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: tokens.isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Size preset selector chips
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: tokens.wellBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: presetSizes.map((sz) {
                  final isCurrent = sz == _iconSize;
                  return InkWell(
                    onTap: () => _setSizePreset(sz),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent ? tokens.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '${sz.toInt()}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent ? tokens.accent : tokens.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(width: 8),
            _buildVDivider(tokens),
            const SizedBox(width: 8),

            // Tools selector
            _buildToolButton(IconStudioTool.select, Icons.near_me_rounded, 'Select / Move (V)', tokens),
            _buildToolButton(IconStudioTool.pen, Icons.polyline_rounded, 'Vector Pen (P)', tokens),
            _buildToolButton(IconStudioTool.rectangle, Icons.crop_square_rounded, 'Rectangle (R)', tokens),
            _buildToolButton(IconStudioTool.roundedRectangle, Icons.rectangle_outlined, 'Rounded Rect', tokens),
            _buildToolButton(IconStudioTool.circle, Icons.circle_outlined, 'Circle (O)', tokens),
            _buildToolButton(IconStudioTool.line, Icons.horizontal_rule_rounded, 'Line (L)', tokens),
            _buildToolButton(IconStudioTool.star, Icons.star_border_rounded, 'Star (S)', tokens),
            _buildToolButton(IconStudioTool.eraser, Icons.delete_outline_rounded, 'Eraser (E)', tokens),

            const SizedBox(width: 8),
            _buildVDivider(tokens),
            const SizedBox(width: 8),

            // Stroke Width Selector Dropdown
            PopupMenuButton<double>(
              tooltip: 'Stroke Weight',
              color: tokens.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: tokens.border),
              ),
              onSelected: (val) {
                setState(() => _strokeWidth = val);
                if (_selectedNodeId != null) {
                  final idx = _nodes.indexWhere((n) => n.id == _selectedNodeId);
                  if (idx != -1) {
                    _recordHistory();
                    final node = _nodes[idx];
                    final updatedStrokes = node.strokes.map((s) => s.copyWith(width: val)).toList();
                    setState(() {
                      _nodes[idx] = node.copyWith(strokes: updatedStrokes);
                    });
                    _notifyTabChanged();
                  }
                }
              },
              itemBuilder: (ctx) => [0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0].map((w) {
                return PopupMenuItem<double>(
                  value: w,
                  height: 32,
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: w,
                        color: tokens.textMain,
                      ),
                      const SizedBox(width: 12),
                      Text('${w}px', style: TextStyle(fontSize: 12, color: tokens.textMain)),
                    ],
                  ),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.wellBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.line_weight_rounded, size: 14, color: tokens.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${_strokeWidth}px',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tokens.textMain,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Stroke Color Swatch
            InkWell(
              onTap: () => _showColorPicker(context, true),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.wellBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _strokeColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Stroke', style: TextStyle(fontSize: 11, color: tokens.textMuted)),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),
            _buildVDivider(tokens),
            const SizedBox(width: 8),

            // Precision Grid & Guide Toggles
            _buildToggleIcon(
              icon: Icons.grid_4x4_rounded,
              tooltip: '1px Pixel Grid',
              active: _showPixelGrid,
              onTap: () {
                setState(() => _showPixelGrid = !_showPixelGrid);
                _notifyTabChanged();
              },
              tokens: tokens,
            ),
            _buildToggleIcon(
              icon: Icons.grid_goldenratio_rounded,
              tooltip: '0.5px Sub-pixel Grid',
              active: _showSubpixelGrid,
              onTap: () {
                setState(() => _showSubpixelGrid = !_showSubpixelGrid);
                _notifyTabChanged();
              },
              tokens: tokens,
            ),
            _buildToggleIcon(
              icon: Icons.crop_free_rounded,
              tooltip: 'Material & Apple Keyline Guides',
              active: _showKeylines,
              onTap: () {
                setState(() => _showKeylines = !_showKeylines);
                _notifyTabChanged();
              },
              tokens: tokens,
            ),
            _buildToggleIcon(
              icon: Icons.gps_fixed_rounded,
              tooltip: 'Center Crosshair Axes',
              active: _showCenterAxes,
              onTap: () {
                setState(() => _showCenterAxes = !_showCenterAxes);
                _notifyTabChanged();
              },
              tokens: tokens,
            ),
            _buildToggleIcon(
              icon: Icons.grid_on_rounded,
              tooltip: 'Snap to Pixel Grid',
              active: _snapToPixel,
              onTap: () {
                setState(() => _snapToPixel = !_snapToPixel);
                _notifyTabChanged();
              },
              tokens: tokens,
            ),

            const SizedBox(width: 8),
            _buildVDivider(tokens),
            const SizedBox(width: 8),

            // Undo / Redo
            IconButton(
              icon: const Icon(Icons.undo_rounded, size: 15),
              tooltip: 'Undo (Ctrl+Z)',
              onPressed: _undoHistory.isNotEmpty ? _undo : null,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            IconButton(
              icon: const Icon(Icons.redo_rounded, size: 15),
              tooltip: 'Redo (Ctrl+Y)',
              onPressed: _redoHistory.isNotEmpty ? _redo : null,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),

            const SizedBox(width: 8),
            _buildVDivider(tokens),
            const SizedBox(width: 8),

            // Preset starter icon dropdown
            PopupMenuButton<String>(
              tooltip: 'Starter Templates',
              color: tokens.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: tokens.border),
              ),
              onSelected: _loadTemplateGlyph,
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'heart', child: Text('Heart Glyph')),
                const PopupMenuItem(value: 'search', child: Text('Search Lens')),
                const PopupMenuItem(value: 'check', child: Text('Checkmark')),
                const PopupMenuItem(value: 'plus', child: Text('Plus Cross')),
                const PopupMenuItem(value: 'empty', child: Text('Clear Artboard')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.wellBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: tokens.accent),
                    const SizedBox(width: 4),
                    Text('Glyphs', style: TextStyle(fontSize: 11, color: tokens.textMain)),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),
            _buildVDivider(tokens),
            const SizedBox(width: 8),

            // Export Button Dropdown
            _buildExportMenu(tokens),
          ],
        ),
      ),
    );
  }

  Widget _buildVDivider(FormaThemeTokens tokens) {
    return Container(
      width: 1,
      height: 18,
      color: tokens.borderSubtle,
    );
  }

  Widget _buildToolButton(
    IconStudioTool tool,
    IconData icon,
    String tooltip,
    FormaThemeTokens tokens,
  ) {
    final isActive = _activeTool == tool;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          setState(() {
            _activeTool = tool;
            if (tool != IconStudioTool.pen) {
              _activePenPoints.clear();
            }
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: isActive ? tokens.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isActive ? Colors.white : tokens.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleIcon({
    required IconData icon,
    required String tooltip,
    required bool active,
    required VoidCallback onTap,
    required FormaThemeTokens tokens,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: active ? tokens.accent.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? tokens.accent.withValues(alpha: 0.3) : Colors.transparent,
              width: 0.5,
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: active ? tokens.accent : tokens.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildExportMenu(FormaThemeTokens tokens) {
    return PopupMenuButton<String>(
      tooltip: 'Export Icon',
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.border),
      ),
      onSelected: (val) {
        switch (val) {
          case 'svg':
            _exportSvg();
            break;
          case 'copy_svg':
            _copySvgToClipboard();
            break;
          case 'png1x':
            _exportPng(1.0);
            break;
          case 'png2x':
            _exportPng(2.0);
            break;
          case 'png4x':
            _exportPng(4.0);
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: 'svg',
          child: Row(
            children: [
              Icon(Icons.code_rounded, size: 16, color: tokens.accent),
              const SizedBox(width: 8),
              const Text('Export as SVG'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'copy_svg',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 16, color: tokens.accent),
              const SizedBox(width: 8),
              const Text('Copy SVG Code'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'png1x',
          child: Text('Export PNG (1x)'),
        ),
        const PopupMenuItem<String>(
          value: 'png2x',
          child: Text('Export PNG (2x Retina)'),
        ),
        const PopupMenuItem<String>(
          value: 'png4x',
          child: Text('Export PNG (4x Ultra)'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: tokens.accent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: tokens.accent.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.file_download_rounded, size: 15, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'Export Icon',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, bool isStroke) {
    final colors = [
      const Color(0xFF0F172A),
      const Color(0xFFF8FAFC),
      FormaColors.primaryBlue,
      FormaColors.componentPurple,
      FormaColors.successGreen,
      FormaColors.warningAmber,
      FormaColors.dangerRed,
      const Color(0xFF0D9488),
      const Color(0xFFEC4899),
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        final tokens = FormaTheme.tokensOf(ctx);
        return AlertDialog(
          backgroundColor: tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tokens.border),
          ),
          title: Text(
            isStroke ? 'Stroke Color' : 'Fill Color',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: tokens.textMain),
          ),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((c) {
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isStroke) {
                      _strokeColor = c;
                    } else {
                      _fillColor = c;
                    }
                  });
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.border, width: 2),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Real-time Multi-Scale Preview Dock
  // ---------------------------------------------------------------------------
  Widget _buildMultiScalePreviewDock(BuildContext context, FormaThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha: tokens.isDark ? 0.90 : 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: tokens.isDark ? 0.35 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove_red_eye_rounded, size: 14, color: tokens.accent),
              const SizedBox(width: 6),
              Text(
                'LIVE SCALES PREVIEW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              // Dark / Light Tile Preview Toggle
              InkWell(
                onTap: () => setState(() => _darkPreviewTile = !_darkPreviewTile),
                child: Icon(
                  _darkPreviewTile ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 14,
                  color: tokens.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _showPreviewDock = false),
                child: Icon(Icons.close_rounded, size: 14, color: tokens.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [16, 24, 32, 48].map((targetScale) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: targetScale.toDouble() + 10,
                      height: targetScale.toDouble() + 10,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _darkPreviewTile ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _darkPreviewTile ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: CustomPaint(
                        size: Size(targetScale.toDouble(), targetScale.toDouble()),
                        painter: _LiveScaleIconPainter(
                          nodes: _nodes,
                          nativeSize: _iconSize,
                          targetSize: targetScale.toDouble(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${targetScale}px',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Zoom, Coordinate Display & HUD at Bottom Left
  // ---------------------------------------------------------------------------
  Widget _buildZoomAndPresetsHUD(
    BuildContext context,
    FormaThemeTokens tokens,
    Size viewportSize,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 15),
            tooltip: 'Zoom Out',
            onPressed: () => setState(() => _zoom = (_zoom * 0.85).clamp(3.0, 64.0)),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),
          InkWell(
            onTap: () => setState(() => _zoom = 18.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${(_zoom * 100 / 18).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: tokens.textMain,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 15),
            tooltip: 'Zoom In',
            onPressed: () => setState(() => _zoom = (_zoom * 1.15).clamp(3.0, 64.0)),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: tokens.borderSubtle,
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen_rounded, size: 15),
            tooltip: 'Fit Artboard',
            onPressed: () => _fitToViewport(viewportSize),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),
          if (_hoveredArtboardPos != null) ...[
            Container(
              width: 1,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: tokens.borderSubtle,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${_hoveredArtboardPos!.dx.toInt()}, ${_hoveredArtboardPos!.dy.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: tokens.accent,
                ),
              ),
            ),
          ],
          if (!_showPreviewDock) ...[
            Container(
              width: 1,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: tokens.borderSubtle,
            ),
            IconButton(
              icon: const Icon(Icons.remove_red_eye_rounded, size: 15),
              tooltip: 'Show Scales Preview Dock',
              onPressed: () => setState(() => _showPreviewDock = true),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Live Scale Icon Painter for Preview Dock
// =============================================================================
class _LiveScaleIconPainter extends CustomPainter {
  final List<DesignNode> nodes;
  final double nativeSize;
  final double targetSize;

  _LiveScaleIconPainter({
    required this.nodes,
    required this.nativeSize,
    required this.targetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = targetSize / nativeSize;
    canvas.save();
    canvas.scale(scale, scale);

    final nodeMap = {for (final n in nodes) n.id: n};
    for (final node in nodes) {
      NodeRenderService.renderNode(canvas, node, nodeMap);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiveScaleIconPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.nativeSize != nativeSize ||
        oldDelegate.targetSize != targetSize;
  }
}

// =============================================================================
// Bounded Icon Canvas Painter
// Renders bounded artboard, precision pixel grid, sub-pixel grid, center axes,
// Material & Apple icon keylines, and nodes.
// =============================================================================
class _BoundedIconCanvasPainter extends CustomPainter {
  final double iconSize;
  final double zoom;
  final Offset panOffset;
  final List<DesignNode> nodes;
  final String? selectedNodeId;
  final bool showPixelGrid;
  final bool showSubpixelGrid;
  final bool showKeylines;
  final bool showCenterAxes;
  final List<Offset> activePenPoints;
  final Offset? drawingStart;
  final Offset? drawingCurrent;
  final IconStudioTool activeTool;
  final bool isDarkTheme;

  _BoundedIconCanvasPainter({
    required this.iconSize,
    required this.zoom,
    required this.panOffset,
    required this.nodes,
    required this.selectedNodeId,
    required this.showPixelGrid,
    required this.showSubpixelGrid,
    required this.showKeylines,
    required this.showCenterAxes,
    required this.activePenPoints,
    required this.drawingStart,
    required this.drawingCurrent,
    required this.activeTool,
    required this.isDarkTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + panOffset;
    final artboardPixelSize = iconSize * zoom;
    final artboardRect = Rect.fromCenter(
      center: center,
      width: artboardPixelSize,
      height: artboardPixelSize,
    );

    // 1. Draw artboard shadow & background
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDarkTheme ? 0.45 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawRect(artboardRect, shadowPaint);

    final bgPaint = Paint()
      ..color = isDarkTheme ? const Color(0xFF0F1420) : Colors.white;
    canvas.drawRect(artboardRect, bgPaint);

    // Save for transformed bounded drawing
    canvas.save();
    canvas.translate(artboardRect.left, artboardRect.top);
    canvas.scale(zoom, zoom);

    // 2. Draw Precision Pixel Grid (1px intervals)
    if (showPixelGrid && zoom >= 4.0) {
      final gridPaint = Paint()
        ..color = (isDarkTheme ? Colors.white : Colors.black).withValues(alpha: zoom >= 12.0 ? 0.08 : 0.04)
        ..strokeWidth = 0.5 / zoom
        ..style = PaintingStyle.stroke;

      for (double x = 0; x <= iconSize; x += 1.0) {
        canvas.drawLine(Offset(x, 0), Offset(x, iconSize), gridPaint);
      }
      for (double y = 0; y <= iconSize; y += 1.0) {
        canvas.drawLine(Offset(0, y), Offset(iconSize, y), gridPaint);
      }
    }

    // 3. Draw Sub-pixel Grid (0.5px intervals) at high zoom
    if (showSubpixelGrid && zoom >= 14.0) {
      final subGridPaint = Paint()
        ..color = (isDarkTheme ? Colors.white : Colors.black).withValues(alpha: 0.03)
        ..strokeWidth = 0.25 / zoom
        ..style = PaintingStyle.stroke;

      for (double x = 0.5; x < iconSize; x += 1.0) {
        canvas.drawLine(Offset(x, 0), Offset(x, iconSize), subGridPaint);
      }
      for (double y = 0.5; y < iconSize; y += 1.0) {
        canvas.drawLine(Offset(0, y), Offset(iconSize, y), subGridPaint);
      }
    }

    // 4. Draw Center Crosshair Axes
    if (showCenterAxes) {
      final axisPaint = Paint()
        ..color = FormaColors.primaryBlue.withValues(alpha: 0.4)
        ..strokeWidth = 1.0 / zoom
        ..style = PaintingStyle.stroke;

      final half = iconSize / 2;
      canvas.drawLine(Offset(half, 0), Offset(half, iconSize), axisPaint);
      canvas.drawLine(Offset(0, half), Offset(iconSize, half), axisPaint);
    }

    // 5. Draw Material & Apple Standard Keyline Guides
    if (showKeylines) {
      _drawKeylineGuides(canvas);
    }

    // 6. Render Document Nodes
    final nodeMap = {for (final n in nodes) n.id: n};
    for (final node in nodes) {
      NodeRenderService.renderNode(canvas, node, nodeMap);
    }

    // 7. Render Active Drawing Previews
    _drawActiveDrawing(canvas);

    // 8. Render Selection Outline & Handles
    if (selectedNodeId != null) {
      final selected = nodes.where((n) => n.id == selectedNodeId).firstOrNull;
      if (selected != null) {
        _drawSelectionOutline(canvas, selected);
      }
    }

    canvas.restore();

    // 9. Artboard Boundary Stroke & Corner Crop Marks
    final borderPaint = Paint()
      ..color = (isDarkTheme ? const Color(0xFF38BDF8) : FormaColors.primaryBlue).withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(artboardRect, borderPaint);

    final tickLen = 6.0;
    final tickPaint = Paint()
      ..color = (isDarkTheme ? const Color(0xFF38BDF8) : FormaColors.primaryBlue)
      ..strokeWidth = 2.0;

    // Top-left
    canvas.drawLine(artboardRect.topLeft - Offset(tickLen, 0), artboardRect.topLeft, tickPaint);
    canvas.drawLine(artboardRect.topLeft - Offset(0, tickLen), artboardRect.topLeft, tickPaint);
    // Top-right
    canvas.drawLine(artboardRect.topRight + Offset(tickLen, 0), artboardRect.topRight, tickPaint);
    canvas.drawLine(artboardRect.topRight - Offset(0, tickLen), artboardRect.topRight, tickPaint);
    // Bottom-left
    canvas.drawLine(artboardRect.bottomLeft - Offset(tickLen, 0), artboardRect.bottomLeft, tickPaint);
    canvas.drawLine(artboardRect.bottomLeft + Offset(0, tickLen), artboardRect.bottomLeft, tickPaint);
    // Bottom-right
    canvas.drawLine(artboardRect.bottomRight + Offset(tickLen, 0), artboardRect.bottomRight, tickPaint);
    canvas.drawLine(artboardRect.bottomRight + Offset(0, tickLen), artboardRect.bottomRight, tickPaint);
  }

  void _drawKeylineGuides(Canvas canvas) {
    final guidePaint = Paint()
      ..color = FormaColors.guidePink.withValues(alpha: 0.35)
      ..strokeWidth = 0.8 / zoom
      ..style = PaintingStyle.stroke;

    final s = iconSize;
    final center = Offset(s / 2, s / 2);

    // Safe zone margin (2px inset on 24x24 proportional)
    final margin = s * (2.0 / 24.0);
    final safeRect = Rect.fromLTWH(margin, margin, s - 2 * margin, s - 2 * margin);
    canvas.drawRect(safeRect, guidePaint);

    // Circular keyline (diameter = 20px on 24x24 proportional, radius = 10px)
    final circleRadius = s * (10.0 / 24.0);
    canvas.drawCircle(center, circleRadius, guidePaint);

    // Square keyline (18x18 on 24x24 proportional, corner radius = 3px)
    final squareSide = s * (18.0 / 24.0);
    final squareRadius = s * (3.0 / 24.0);
    final squareRect = Rect.fromCenter(center: center, width: squareSide, height: squareSide);
    canvas.drawRRect(RRect.fromRectAndRadius(squareRect, Radius.circular(squareRadius)), guidePaint);

    // Horizontal rectangle (20x16 on 24x24 proportional)
    final hRectW = s * (20.0 / 24.0);
    final hRectH = s * (16.0 / 24.0);
    final hRect = Rect.fromCenter(center: center, width: hRectW, height: hRectH);
    canvas.drawRRect(RRect.fromRectAndRadius(hRect, Radius.circular(squareRadius)), guidePaint);

    // Vertical rectangle (16x20 on 24x24 proportional)
    final vRect = Rect.fromCenter(center: center, width: hRectH, height: hRectW);
    canvas.drawRRect(RRect.fromRectAndRadius(vRect, Radius.circular(squareRadius)), guidePaint);

    // 45-degree diagonal guides
    final diagPaint = Paint()
      ..color = FormaColors.guidePink.withValues(alpha: 0.18)
      ..strokeWidth = 0.6 / zoom
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(s, s), diagPaint);
    canvas.drawLine(Offset(0, s), Offset(s, 0), diagPaint);
  }

  void _drawActiveDrawing(Canvas canvas) {
    if (activeTool == IconStudioTool.pen && activePenPoints.isNotEmpty) {
      final penPaint = Paint()
        ..color = FormaColors.primaryBlue
        ..strokeWidth = 2.0 / zoom
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(activePenPoints.first.dx, activePenPoints.first.dy);
      for (int i = 1; i < activePenPoints.length; i++) {
        path.lineTo(activePenPoints[i].dx, activePenPoints[i].dy);
      }
      canvas.drawPath(path, penPaint);

      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final pointStroke = Paint()
        ..color = FormaColors.primaryBlue
        ..strokeWidth = 1.0 / zoom
        ..style = PaintingStyle.stroke;

      for (final pt in activePenPoints) {
        canvas.drawCircle(pt, 2.5 / zoom, pointPaint);
        canvas.drawCircle(pt, 2.5 / zoom, pointStroke);
      }
    } else if (drawingStart != null && drawingCurrent != null) {
      final previewPaint = Paint()
        ..color = FormaColors.primaryBlue.withValues(alpha: 0.8)
        ..strokeWidth = 1.5 / zoom
        ..style = PaintingStyle.stroke;

      final rect = Rect.fromPoints(drawingStart!, drawingCurrent!);
      switch (activeTool) {
        case IconStudioTool.rectangle:
          canvas.drawRect(rect, previewPaint);
          break;
        case IconStudioTool.roundedRectangle:
          canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(3.0 / zoom * 2)), previewPaint);
          break;
        case IconStudioTool.circle:
          canvas.drawOval(rect, previewPaint);
          break;
        case IconStudioTool.line:
          canvas.drawLine(drawingStart!, drawingCurrent!, previewPaint);
          break;
        default:
          break;
      }
    }
  }

  void _drawSelectionOutline(Canvas canvas, DesignNode node) {
    final selPaint = Paint()
      ..color = FormaColors.primaryBlue
      ..strokeWidth = 1.0 / zoom
      ..style = PaintingStyle.stroke;

    final r = node.rect;
    canvas.drawRect(r, selPaint);

    final handleFill = Paint()..color = Colors.white;
    final handleStroke = Paint()
      ..color = FormaColors.primaryBlue
      ..strokeWidth = 1.0 / zoom
      ..style = PaintingStyle.stroke;
    final handleRadius = 2.5 / zoom;

    final handles = [
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
      r.topCenter,
      r.bottomCenter,
      r.centerLeft,
      r.centerRight,
    ];

    for (final h in handles) {
      canvas.drawCircle(h, handleRadius, handleFill);
      canvas.drawCircle(h, handleRadius, handleStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _BoundedIconCanvasPainter oldDelegate) {
    return true;
  }
}
