import 'package:flutter/material.dart';

import '../../../../app/theme/forma_colors.dart';
import '../../../../domain/models/animation_model.dart';

class GraphEditorDialog extends StatefulWidget {
  final NodeAnimationTrack track;
  final double durationMs;
  final double currentTimeMs;
  final ValueChanged<NodeAnimationTrack> onSaveTrack;
  final VoidCallback onDeleteKeyframeAtPlayhead;

  const GraphEditorDialog({
    super.key,
    required this.track,
    required this.durationMs,
    required this.currentTimeMs,
    required this.onSaveTrack,
    required this.onDeleteKeyframeAtPlayhead,
  });

  static Future<void> show(
    BuildContext context, {
    required NodeAnimationTrack track,
    required double durationMs,
    required double currentTimeMs,
    required ValueChanged<NodeAnimationTrack> onSaveTrack,
    required VoidCallback onDeleteKeyframeAtPlayhead,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => GraphEditorDialog(
        track: track,
        durationMs: durationMs,
        currentTimeMs: currentTimeMs,
        onSaveTrack: onSaveTrack,
        onDeleteKeyframeAtPlayhead: onDeleteKeyframeAtPlayhead,
      ),
    );
  }

  @override
  State<GraphEditorDialog> createState() => _GraphEditorDialogState();
}

class _GraphEditorDialogState extends State<GraphEditorDialog> {
  late List<FloatKeyframe> _keyframes;
  int? _selectedKfIndex;
  InterpolationType _activeInterpolation = InterpolationType.easeInOut;
  double _customHandleOutX = 0.42;
  double _customHandleOutY = 0.0;
  double _customHandleInX = 0.58;
  double _customHandleInY = 1.0;

  @override
  void initState() {
    super.initState();
    _keyframes = List<FloatKeyframe>.from(widget.track.keyframes)
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
    if (_keyframes.isEmpty) {
      // Default initial and end keyframes if empty
      _keyframes = [
        const FloatKeyframe(timeMs: 0, value: 0.0),
        FloatKeyframe(timeMs: widget.durationMs, value: 1.0),
      ];
    }
    _selectedKfIndex = 0;
    _activeInterpolation = _keyframes.first.interpolation;
    _customHandleOutX = _keyframes.first.handleOutX;
    _customHandleOutY = _keyframes.first.handleOutY;
    _customHandleInX = _keyframes.first.handleInX;
    _customHandleInY = _keyframes.first.handleInY;
  }

  void _applyInterpolationToSelected(InterpolationType type) {
    if (_selectedKfIndex == null || _selectedKfIndex! >= _keyframes.length) return;
    setState(() {
      _activeInterpolation = type;
      _keyframes[_selectedKfIndex!] = _keyframes[_selectedKfIndex!].copyWith(
        interpolation: type,
        handleOutX: _customHandleOutX,
        handleOutY: _customHandleOutY,
        handleInX: _customHandleInX,
        handleInY: _customHandleInY,
      );
    });
  }

  void _deleteSelectedKeyframe() {
    if (_selectedKfIndex == null || _selectedKfIndex! >= _keyframes.length) return;
    if (_keyframes.length <= 1) return; // Maintain at least 1 keyframe
    setState(() {
      _keyframes.removeAt(_selectedKfIndex!);
      _selectedKfIndex = _keyframes.isNotEmpty ? 0 : null;
    });
  }

  void _saveAndClose() {
    final updatedTrack = widget.track.copyWith(keyframes: _keyframes);
    widget.onSaveTrack(updatedTrack);
    Navigator.of(context).pop();
  }

  // Coordinate mapping for tap & drag
  (double minVal, double maxVal, double range) _getValueRange() {
    if (_keyframes.isEmpty) return (0.0, 1.0, 1.0);
    double minV = _keyframes.first.value;
    double maxV = _keyframes.first.value;
    for (final k in _keyframes) {
      if (k.value < minV) minV = k.value;
      if (k.value > maxV) maxV = k.value;
    }
    final r = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);
    return (minV, maxV, r);
  }

  Offset _toScreen(double timeMs, double val, Size size) {
    final (minVal, _, range) = _getValueRange();
    final x = (timeMs / widget.durationMs) * size.width;
    final y = size.height - ((val - minVal) / range) * (size.height - 40) - 20;
    return Offset(x.clamp(0.0, size.width), y.clamp(10.0, size.height - 10));
  }

  (double timeMs, double val) _fromScreen(Offset pos, Size size) {
    final (minVal, _, range) = _getValueRange();
    final timeMs = (pos.dx / size.width * widget.durationMs).clamp(0.0, widget.durationMs);
    final normY = ((size.height - 20 - pos.dy) / (size.height - 40)).clamp(0.0, 1.0);
    final val = minVal + normY * range;
    return (timeMs, val);
  }

  void _handleCanvasTap(Offset localPos, Size size) {
    // 1. Check if tap hits an existing keyframe marker
    for (int i = 0; i < _keyframes.length; i++) {
      final pt = _toScreen(_keyframes[i].timeMs, _keyframes[i].value, size);
      if ((localPos - pt).distance <= 20.0) {
        setState(() {
          _selectedKfIndex = i;
          _activeInterpolation = _keyframes[i].interpolation;
        });
        return;
      }
    }

    // 2. Otherwise: create a new keyframe at tapped position
    final (t, v) = _fromScreen(localPos, size);
    final newKf = FloatKeyframe(
      timeMs: t,
      value: v,
      interpolation: _activeInterpolation,
      handleOutX: _customHandleOutX,
      handleOutY: _customHandleOutY,
      handleInX: _customHandleInX,
      handleInY: _customHandleInY,
    );

    setState(() {
      _keyframes.add(newKf);
      _keyframes.sort((a, b) => a.timeMs.compareTo(b.timeMs));
      _selectedKfIndex = _keyframes.indexOf(newKf);
    });
  }

  void _handlePanStart(Offset localPos, Size size) {
    for (int i = 0; i < _keyframes.length; i++) {
      final pt = _toScreen(_keyframes[i].timeMs, _keyframes[i].value, size);
      if ((localPos - pt).distance <= 24.0) {
        setState(() {
          _selectedKfIndex = i;
          _activeInterpolation = _keyframes[i].interpolation;
        });
        return;
      }
    }
  }

  void _handlePanUpdate(Offset localPos, Size size) {
    if (_selectedKfIndex == null || _selectedKfIndex! >= _keyframes.length) return;
    final (t, v) = _fromScreen(localPos, size);
    setState(() {
      final current = _keyframes[_selectedKfIndex!];
      _keyframes[_selectedKfIndex!] = current.copyWith(
        timeMs: t,
        value: v,
      );
    });
  }

  void _handlePanEnd() {
    if (_selectedKfIndex != null && _selectedKfIndex! < _keyframes.length) {
      final activeKf = _keyframes[_selectedKfIndex!];
      setState(() {
        _keyframes.sort((a, b) => a.timeMs.compareTo(b.timeMs));
        _selectedKfIndex = _keyframes.indexOf(activeKf);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 720,
        height: 540,
        decoration: BoxDecoration(
          color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.show_chart_rounded, color: FormaColors.primaryBlue, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Graph Editor — ${widget.track.property.name.toUpperCase()}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: FormaColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tap to add • Drag diamonds to curve',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: FormaColors.primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Interactive Graph Canvas with Tap & Drag Gesture Detector
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    onTapDown: (details) => _handleCanvasTap(details.localPosition, size),
                    onPanStart: (details) => _handlePanStart(details.localPosition, size),
                    onPanUpdate: (details) => _handlePanUpdate(details.localPosition, size),
                    onPanEnd: (_) => _handlePanEnd(),
                    child: Container(
                      color: isDark ? const Color(0xFF0D121D) : const Color(0xFFF1F5F9),
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _GraphInteractivePainter(
                          keyframes: _keyframes,
                          totalDurationMs: widget.durationMs,
                          currentTimeMs: widget.currentTimeMs,
                          selectedKfIndex: _selectedKfIndex,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Easing Presets & Interpolation Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Interpolation Mode:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildInterpChip('Linear', InterpolationType.linear),
                              _buildInterpChip('Ease In', InterpolationType.easeIn),
                              _buildInterpChip('Ease Out', InterpolationType.easeOut),
                              _buildInterpChip('Ease In-Out', InterpolationType.easeInOut),
                              _buildInterpChip('Spring', InterpolationType.spring),
                              _buildInterpChip('Bounce', InterpolationType.bounce),
                              _buildInterpChip('Bezier', InterpolationType.bezier),
                              _buildInterpChip('Hold', InterpolationType.hold),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_selectedKfIndex != null && _keyframes.length > 1)
                        TextButton.icon(
                          onPressed: _deleteSelectedKeyframe,
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: FormaColors.dangerRed),
                          label: const Text('Delete Keyframe', style: TextStyle(color: FormaColors.dangerRed, fontSize: 12)),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FormaColors.primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _saveAndClose,
                        child: const Text('Apply Curves', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterpChip(String label, InterpolationType type) {
    final isSelected = _activeInterpolation == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 10)),
        selected: isSelected,
        onSelected: (_) => _applyInterpolationToSelected(type),
      ),
    );
  }
}

class _GraphInteractivePainter extends CustomPainter {
  final List<FloatKeyframe> keyframes;
  final double totalDurationMs;
  final double currentTimeMs;
  final int? selectedKfIndex;
  final bool isDark;

  _GraphInteractivePainter({
    required this.keyframes,
    required this.totalDurationMs,
    required this.currentTimeMs,
    this.selectedKfIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (keyframes.isEmpty) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 1; i <= 6; i++) {
      final x = size.width * (i / 7);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Min and Max values for scaling
    double minVal = keyframes.first.value;
    double maxVal = keyframes.first.value;
    for (final k in keyframes) {
      if (k.value < minVal) minVal = k.value;
      if (k.value > maxVal) maxVal = k.value;
    }
    final range = (maxVal - minVal).abs() < 0.001 ? 1.0 : (maxVal - minVal);

    Offset toScreen(double timeMs, double val) {
      final x = (timeMs / totalDurationMs) * size.width;
      final y = size.height - ((val - minVal) / range) * (size.height - 40) - 20;
      return Offset(x.clamp(0.0, size.width), y.clamp(10.0, size.height - 10));
    }

    // Continuous Eased Curve
    final curvePath = Path();
    const int samplePoints = 120;
    final dummyTrack = NodeAnimationTrack(nodeId: '', property: AnimProperty.x, keyframes: keyframes);

    for (int i = 0; i <= samplePoints; i++) {
      final t = (totalDurationMs / samplePoints) * i;
      final val = dummyTrack.evaluate(t, minVal);
      final pt = toScreen(t, val);
      if (i == 0) {
        curvePath.moveTo(pt.dx, pt.dy);
      } else {
        curvePath.lineTo(pt.dx, pt.dy);
      }
    }

    final curvePaint = Paint()
      ..color = FormaColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(curvePath, curvePaint);

    // Current Playhead Indicator
    final playheadX = (currentTimeMs / totalDurationMs) * size.width;
    final playheadPaint = Paint()
      ..color = FormaColors.primaryBlue.withValues(alpha: 0.8)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(playheadX, 0), Offset(playheadX, size.height), playheadPaint);

    // Keyframe Markers (Diamonds)
    final kfFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final kfStroke = Paint()
      ..color = FormaColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final selectedKfFill = Paint()
      ..color = FormaColors.primaryBlue
      ..style = PaintingStyle.fill;

    for (int i = 0; i < keyframes.length; i++) {
      final pt = toScreen(keyframes[i].timeMs, keyframes[i].value);
      final isSel = selectedKfIndex == i;

      // Glow halo on selected keyframe
      if (isSel) {
        final glowPaint = Paint()
          ..color = FormaColors.primaryBlue.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(pt, 12, glowPaint);
      }

      final diamond = Path()
        ..moveTo(pt.dx, pt.dy - 8)
        ..lineTo(pt.dx + 8, pt.dy)
        ..lineTo(pt.dx, pt.dy + 8)
        ..lineTo(pt.dx - 8, pt.dy)
        ..close();

      canvas.drawPath(diamond, isSel ? selectedKfFill : kfFill);
      canvas.drawPath(diamond, kfStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphInteractivePainter oldDelegate) => true;
}
