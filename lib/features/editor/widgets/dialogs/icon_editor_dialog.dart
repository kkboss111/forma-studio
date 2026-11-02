import 'package:flutter/material.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../domain/models/paint_styles.dart';
import '../../../../domain/models/vector_data.dart';
import '../../controllers/editor_controller.dart';

/// Focused, limited-area 24x24 / 48x48 icon crafting studio dialog.
/// Allows designing pixel-perfect vector icons on a strict grid with direct path editing.
class IconEditorDialog extends StatefulWidget {
  final DesignNode? existingNode;
  final EditorController controller;
  final bool isDark;

  const IconEditorDialog({
    super.key,
    this.existingNode,
    required this.controller,
    required this.isDark,
  });

  static Future<void> show(
    BuildContext context, {
    DesignNode? existingNode,
    required EditorController controller,
    required bool isDark,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IconEditorDialog(
        existingNode: existingNode,
        controller: controller,
        isDark: isDark,
      ),
    );
  }

  @override
  State<IconEditorDialog> createState() => _IconEditorDialogState();
}

class _IconEditorDialogState extends State<IconEditorDialog> {
  int _iconGridSize = 24; // 24x24 or 48x48
  Color _strokeColor = const Color(0xFF0F172A);
  final double _strokeWidth = 2.0;
  final List<List<Offset>> _paths = [];
  List<Offset>? _currentDrawingPath;

  @override
  void initState() {
    super.initState();
    if (widget.isDark) {
      _strokeColor = const Color(0xFFF8FAFC);
    }
  }

  void _saveIconToCanvas() {
    if (_paths.isEmpty && (_currentDrawingPath == null || _currentDrawingPath!.isEmpty)) {
      Navigator.pop(context);
      return;
    }

    final allPaths = List<List<Offset>>.from(_paths);
    if (_currentDrawingPath != null && _currentDrawingPath!.isNotEmpty) {
      allPaths.add(_currentDrawingPath!);
    }

    // Convert icon grid paths to vector anchors
    final anchors = <VectorAnchor>[];
    for (final pList in allPaths) {
      for (final pt in pList) {
        anchors.add(VectorAnchor(
          point: pt * (64.0 / _iconGridSize), // scale up to 64px on main canvas
          isSmooth: true,
          handleIn: const Offset(-2, 0),
          handleOut: const Offset(2, 0),
        ));
      }
    }

    final iconNode = DesignNode(
      id: 'icon_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Custom Icon',
      type: NodeType.vectorPath,
      x: 150.0,
      y: 150.0,
      width: 64.0,
      height: 64.0,
      vectorData: VectorPathData(anchors: anchors, isClosed: false),
      strokes: [
        DesignStroke(
          color: _strokeColor,
          width: _strokeWidth,
          cap: StrokeCap.round,
          join: StrokeJoin.round,
        ),
      ],
      fills: const [],
    );

    widget.controller.updateNode(iconNode);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: FormaColors.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.star_border_purple500_rounded, color: FormaColors.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Icon Studio (Limited Grid)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : FormaColors.lightTextMain,
                            ),
                          ),
                          Text(
                            'Strict 24x24 / 48x48 icon crafting arena',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Mode & Grid Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('24x24 Grid', style: TextStyle(fontSize: 11)),
                        selected: _iconGridSize == 24,
                        onSelected: (val) {
                          if (val) setState(() => _iconGridSize = 24);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('48x48 Grid', style: TextStyle(fontSize: 11)),
                        selected: _iconGridSize == 48,
                        onSelected: (val) {
                          if (val) setState(() => _iconGridSize = 48);
                        },
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() {
                      _paths.clear();
                      _currentDrawingPath = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // The Limited Area Canvas
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: FormaColors.primaryBlue.withValues(alpha: 0.4),
                          width: 2.0,
                        ),
                      ),
                      child: GestureDetector(
                        onPanStart: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final local = box.globalToLocal(details.globalPosition);
                          setState(() {
                            _currentDrawingPath = [local];
                          });
                        },
                        onPanUpdate: (details) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final local = box.globalToLocal(details.globalPosition);
                          setState(() {
                            _currentDrawingPath?.add(local);
                          });
                        },
                        onPanEnd: (_) {
                          setState(() {
                            if (_currentDrawingPath != null && _currentDrawingPath!.isNotEmpty) {
                              _paths.add(_currentDrawingPath!);
                              _currentDrawingPath = null;
                            }
                          });
                        },
                        child: CustomPaint(
                          painter: _IconCanvasPainter(
                            gridSize: _iconGridSize,
                            paths: _paths,
                            activePath: _currentDrawingPath,
                            strokeColor: _strokeColor,
                            strokeWidth: _strokeWidth,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FormaColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Insert Icon to Canvas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: _saveIconToCanvas,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconCanvasPainter extends CustomPainter {
  final int gridSize;
  final List<List<Offset>> paths;
  final List<Offset>? activePath;
  final Color strokeColor;
  final double strokeWidth;
  final bool isDark;

  _IconCanvasPainter({
    required this.gridSize,
    required this.paths,
    required this.activePath,
    required this.strokeColor,
    required this.strokeWidth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw subtle pixel grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    final step = size.width / gridSize;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 2. Draw outer safe margin ring
    final circlePaint = Paint()
      ..color = FormaColors.primaryBlue.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.42, circlePaint);

    // 3. Draw existing paths
    final drawPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final pList in paths) {
      if (pList.length < 2) continue;
      final path = Path();
      path.moveTo(pList.first.dx, pList.first.dy);
      for (int i = 1; i < pList.length; i++) {
        path.lineTo(pList[i].dx, pList[i].dy);
      }
      canvas.drawPath(path, drawPaint);
    }

    if (activePath != null && activePath!.length >= 2) {
      final path = Path();
      path.moveTo(activePath!.first.dx, activePath!.first.dy);
      for (int i = 1; i < activePath!.length; i++) {
        path.lineTo(activePath![i].dx, activePath![i].dy);
      }
      canvas.drawPath(path, drawPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IconCanvasPainter old) => true;
}
