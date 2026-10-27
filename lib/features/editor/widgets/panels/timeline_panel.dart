import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/neumorphic.dart';
import '../../../../domain/models/animation_model.dart';
import '../dialogs/graph_editor_dialog.dart';

enum TimelineViewMode { dopeSheet, graphEditor }

class TimelinePanel extends StatefulWidget {
  final ProjectTimeline timeline;
  final double currentTimeMs;
  final bool isPlaying;
  final String? selectedNodeId;
  final VoidCallback onTogglePlay;
  final ValueChanged<double> onScrub;
  final void Function(AnimProperty property) onAddKeyframe;
  final void Function(String presetType)? onAddMotionPreset;
  final VoidCallback onDeleteKeyframe;
  final VoidCallback onToggleLoop;
  final ValueChanged<int> onFpsChanged;
  final VoidCallback onClose;
  final VoidCallback onSnapPrev;
  final VoidCallback onSnapNext;
  final void Function(String nodeId, AnimProperty property, int kfIdx, FloatKeyframe updated) onUpdateKeyframe;
  final VoidCallback? onToggleFloating;

  const TimelinePanel({
    super.key,
    required this.timeline,
    required this.currentTimeMs,
    required this.isPlaying,
    this.selectedNodeId,
    required this.onTogglePlay,
    required this.onScrub,
    required this.onAddKeyframe,
    this.onAddMotionPreset,
    required this.onDeleteKeyframe,
    required this.onToggleLoop,
    required this.onFpsChanged,
    required this.onClose,
    required this.onSnapPrev,
    required this.onSnapNext,
    required this.onUpdateKeyframe,
    this.onToggleFloating,
  });

  @override
  State<TimelinePanel> createState() => _TimelinePanelState();
}

class _TimelinePanelState extends State<TimelinePanel> {
  TimelineViewMode _viewMode = TimelineViewMode.dopeSheet;
  int _activeTrackIndex = 0;

  void _openKeyframeInspector(
    BuildContext context,
    NodeAnimationTrack track,
    int kfIdx,
    FloatKeyframe kf,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => _KeyframeInspectorDialog(
        track: track,
        kfIndex: kfIdx,
        keyframe: kf,
        onSave: (updated) {
          widget.onUpdateKeyframe(track.nodeId, track.property, kfIdx, updated);
        },
        onDelete: widget.onDeleteKeyframe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSec = (widget.timeline.durationMs / 1000).toStringAsFixed(1);
    final curSec = (widget.currentTimeMs / 1000).toStringAsFixed(2);
    final isLandscapePhone = MediaQuery.of(context).size.height < 550;

    return Container(
      height: isLandscapePhone ? 140 : 210,
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Controls Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
                  width: 0.5,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Snap to Previous Keyframe (|◄)
                  NeuIconButton(
                    icon: Icons.skip_previous_rounded,
                    size: 32,
                    iconSize: 18,
                    tooltip: 'Previous Keyframe (|◄)',
                    onPressed: widget.onSnapPrev,
                  ),
                  const SizedBox(width: 4),

                  // Play / Pause Button
                  NeuIconButton(
                    icon: widget.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 34,
                    iconSize: 20,
                    iconColor: FormaColors.primaryBlue,
                    onPressed: widget.onTogglePlay,
                    tooltip: widget.isPlaying ? 'Pause' : 'Play Animation',
                  ),
                  const SizedBox(width: 4),

                  // Snap to Next Keyframe (►|)
                  NeuIconButton(
                    icon: Icons.skip_next_rounded,
                    size: 32,
                    iconSize: 18,
                    tooltip: 'Next Keyframe (►|)',
                    onPressed: widget.onSnapNext,
                  ),
                  const SizedBox(width: 8),

                  // Loop Toggle Button
                  NeuIconButton(
                    icon: Icons.repeat_rounded,
                    size: 32,
                    iconSize: 16,
                    isActive: widget.timeline.isLooping,
                    onPressed: widget.onToggleLoop,
                    tooltip: 'Toggle Loop Playback',
                  ),
                  const SizedBox(width: 8),

                  // Add Keyframe with Property Menu
                  PopupMenuButton<AnimProperty>(
                    tooltip: 'Add Keyframe for Property',
                    onSelected: widget.onAddKeyframe,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: FormaColors.primaryBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.diamond_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '+ Key',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                        ],
                      ),
                    ),
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: AnimProperty.x,
                        child: Text('Position (X & Y)'),
                      ),
                      const PopupMenuItem(
                        value: AnimProperty.rotation,
                        child: Text('Rotation (°)'),
                      ),
                      const PopupMenuItem(
                        value: AnimProperty.opacity,
                        child: Text('Opacity'),
                      ),
                      const PopupMenuItem(
                        value: AnimProperty.width,
                        child: Text('Width & Height'),
                      ),
                      const PopupMenuItem(
                        value: AnimProperty.cornerRadius,
                        child: Text('Corner Radius'),
                      ),
                      const PopupMenuItem(
                        value: AnimProperty.strokeWidth,
                        child: Text('Stroke Width'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),

                  // Motion Presets Menu (Quick 1-tap working animation)
                  if (widget.onAddMotionPreset != null)
                    PopupMenuButton<String>(
                      tooltip: 'Quick Motion Presets',
                      onSelected: widget.onAddMotionPreset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        decoration: BoxDecoration(
                          color: FormaColors.primaryBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: FormaColors.primaryBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 14, color: FormaColors.primaryBlue),
                            SizedBox(width: 4),
                            Text(
                              '+ Preset',
                              style: TextStyle(
                                color: FormaColors.primaryBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'spin',
                          child: Text('Spin 360° (2s Loop)'),
                        ),
                        const PopupMenuItem(
                          value: 'moveRight',
                          child: Text('Slide Right (1.5s)'),
                        ),
                        const PopupMenuItem(
                          value: 'fade',
                          child: Text('Fade In & Out (2s)'),
                        ),
                      ],
                    ),
                  const SizedBox(width: 6),

                  // Delete Keyframe
                  NeuIconButton(
                    icon: Icons.remove_circle_outline_rounded,
                    size: 32,
                    iconSize: 16,
                    onPressed: widget.onDeleteKeyframe,
                    tooltip: 'Delete Keyframe at Playhead',
                  ),
                  const SizedBox(width: 10),

                  // View Mode Toggle (Dope Sheet vs Graph Editor)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _viewMode = TimelineViewMode.dopeSheet),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: _viewMode == TimelineViewMode.dopeSheet
                                  ? FormaColors.primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.view_timeline_outlined,
                              size: 15,
                              color: _viewMode == TimelineViewMode.dopeSheet
                                  ? Colors.white
                                  : (isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _viewMode = TimelineViewMode.graphEditor),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: _viewMode == TimelineViewMode.graphEditor
                                  ? FormaColors.primaryBlue
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Icon(
                              Icons.auto_graph_rounded,
                              size: 15,
                              color: _viewMode == TimelineViewMode.graphEditor
                                  ? Colors.white
                                  : (isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Open Centered Graph Editor Window
                  NeuIconButton(
                    icon: Icons.open_in_new_rounded,
                    size: 30,
                    iconSize: 14,
                    tooltip: 'Open Graph Editor Window in Center of Screen',
                    onPressed: () {
                      final track = widget.timeline.tracks.isNotEmpty
                          ? widget.timeline.tracks[_activeTrackIndex.clamp(0, widget.timeline.tracks.length - 1)]
                          : null;
                      if (track != null) {
                        GraphEditorDialog.show(
                          context,
                          track: track,
                          durationMs: widget.timeline.durationMs,
                          currentTimeMs: widget.currentTimeMs,
                          onSaveTrack: (updatedTrack) {
                            for (int k = 0; k < updatedTrack.keyframes.length; k++) {
                              widget.onUpdateKeyframe(
                                updatedTrack.nodeId,
                                updatedTrack.property,
                                k,
                                updatedTrack.keyframes[k],
                              );
                            }
                          },
                          onDeleteKeyframeAtPlayhead: widget.onDeleteKeyframe,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 10),

                  // Timecode Readout
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141820) : const Color(0xFFE2EAF4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${curSec}s / ${totalSec}s',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // FPS selector with autocalculated options
                  PopupMenuButton<int>(
                    initialValue: widget.timeline.fps,
                    onSelected: widget.onFpsChanged,
                    tooltip: 'Framerate (FPS)',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        '${widget.timeline.fps} FPS',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 12, child: Text('12 FPS (Stop-Motion)')),
                      const PopupMenuItem(value: 24, child: Text('24 FPS (Cinematic Film)')),
                      const PopupMenuItem(value: 30, child: Text('30 FPS (NTSC Standard)')),
                      const PopupMenuItem(value: 60, child: Text('60 FPS (Fluid 60Hz)')),
                      const PopupMenuItem(value: 120, child: Text('120 FPS (High-Refresh ProMotion)')),
                    ],
                  ),
                  const SizedBox(width: 8),

                  if (widget.onToggleFloating != null) ...[
                    NeuIconButton(
                      icon: Icons.picture_in_picture_alt_rounded,
                      size: 30,
                      iconSize: 15,
                      tooltip: 'Toggle Floating Window (Draggable & Resizable)',
                      onPressed: widget.onToggleFloating,
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    splashRadius: 16,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          ),

          // Scrubber Bar with Visible Keyframe Markers
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth - 60;
                final allKfTimes = widget.timeline.getAllKeyframeTimes();

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Base line
                    Positioned(
                      left: 30,
                      right: 30,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Keyframe Tick Markers on the Scrubber
                    ...allKfTimes.map((t) {
                      final ratio = (t / widget.timeline.durationMs).clamp(0.0, 1.0);
                      final pos = 30 + (ratio * trackWidth);
                      final isNearPlayhead = (t - widget.currentTimeMs).abs() < 30;
                      return Positioned(
                        left: pos - 3,
                        child: Container(
                          width: 6,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isNearPlayhead
                                ? FormaColors.primaryBlue
                                : const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: (isNearPlayhead
                                        ? FormaColors.primaryBlue
                                        : const Color(0xFFF59E0B))
                                    .withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Interactive Scrub Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        activeTrackColor: FormaColors.primaryBlue,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: FormaColors.primaryBlue,
                      ),
                      child: Slider(
                        value: widget.currentTimeMs.clamp(0.0, widget.timeline.durationMs),
                        min: 0.0,
                        max: widget.timeline.durationMs,
                        onChanged: widget.onScrub,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Main Content View (Dope Sheet vs Graph Editor)
          Expanded(
            child: _viewMode == TimelineViewMode.dopeSheet
                ? _buildDopeSheetView(isDark)
                : _buildGraphEditorView(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDopeSheetView(bool isDark) {
    if (widget.timeline.tracks.isEmpty) {
      return Center(
        child: Text(
          widget.selectedNodeId != null
              ? 'Click "+ Key" to record keyframes for the selected node'
              : 'Select an object on the canvas to animate',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.timeline.tracks.length,
      itemBuilder: (context, trackIdx) {
        final track = widget.timeline.tracks[trackIdx];
        final isSelectedNode = track.nodeId == widget.selectedNodeId;

        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: isSelectedNode
              ? FormaColors.primaryBlue.withValues(alpha: 0.08)
              : null,
          child: Row(
            children: [
              // Track Label
              SizedBox(
                width: 140,
                child: Row(
                  children: [
                    Icon(
                      _getIconForProperty(track.property),
                      size: 13,
                      color: FormaColors.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        track.property.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelectedNode ? FontWeight.bold : FontWeight.w500,
                          color: isDark ? FormaColors.darkTextMain : FormaColors.lightTextMain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Keyframe Diamonds Track
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final trackWidth = constraints.maxWidth;
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Horizontal track rail
                        Container(
                          height: 1,
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15),
                        ),

                        // Keyframe Diamonds
                        ...track.keyframes.asMap().entries.map((entry) {
                          final kfIdx = entry.key;
                          final kf = entry.value;
                          final ratio = (kf.timeMs / widget.timeline.durationMs).clamp(0.0, 1.0);
                          final pos = ratio * (trackWidth - 16);
                          final isCurrent = (kf.timeMs - widget.currentTimeMs).abs() < 25;

                          return Positioned(
                            left: pos,
                            child: GestureDetector(
                              onTap: () {
                                widget.onScrub(kf.timeMs);
                                _openKeyframeInspector(context, track, kfIdx, kf);
                              },
                              child: Transform.rotate(
                                angle: math.pi / 4,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? FormaColors.primaryBlue
                                        : const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGraphEditorView(bool isDark) {
    if (widget.timeline.tracks.isEmpty) {
      return const Center(child: Text('No tracks to graph'));
    }

    final safeIdx = _activeTrackIndex.clamp(0, widget.timeline.tracks.length - 1);
    final activeTrack = widget.timeline.tracks[safeIdx];

    return Column(
      children: [
        // Track selector strip
        Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'GRAPHING: ',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
                ),
              ),
              DropdownButton<int>(
                value: safeIdx,
                isDense: true,
                underline: const SizedBox.shrink(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: FormaColors.primaryBlue,
                ),
                items: widget.timeline.tracks.asMap().entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text('${entry.value.nodeId} · ${entry.value.property.name.toUpperCase()}'),
                  );
                }).toList(),
                onChanged: (idx) {
                  if (idx != null) setState(() => _activeTrackIndex = idx);
                },
              ),
            ],
          ),
        ),

        // Interactive Curve Graph Painter
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141820) : const Color(0xFFF0F4FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                size: Size.infinite,
                painter: _GraphEditorPainter(
                  track: activeTrack,
                  totalDurationMs: widget.timeline.durationMs,
                  currentTimeMs: widget.currentTimeMs,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForProperty(AnimProperty prop) {
    switch (prop) {
      case AnimProperty.x:
      case AnimProperty.y:
        return Icons.open_with_rounded;
      case AnimProperty.rotation:
        return Icons.rotate_right_rounded;
      case AnimProperty.opacity:
        return Icons.opacity_rounded;
      case AnimProperty.orbitAngle:
        return Icons.public_rounded;
      case AnimProperty.width:
      case AnimProperty.height:
        return Icons.aspect_ratio_rounded;
      case AnimProperty.cornerRadius:
        return Icons.rounded_corner_rounded;
      case AnimProperty.strokeWidth:
        return Icons.line_weight_rounded;
      default:
        return Icons.animation_rounded;
    }
  }
}

/// Custom painter for the Value/Speed Graph Editor
class _GraphEditorPainter extends CustomPainter {
  final NodeAnimationTrack track;
  final double totalDurationMs;
  final double currentTimeMs;
  final bool isDark;

  _GraphEditorPainter({
    required this.track,
    required this.totalDurationMs,
    required this.currentTimeMs,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (track.keyframes.isEmpty) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Min & Max values
    final values = track.keyframes.map((k) => k.value).toList();
    var minVal = values.reduce(math.min);
    var maxVal = values.reduce(math.max);
    if ((maxVal - minVal).abs() < 0.001) {
      minVal -= 10;
      maxVal += 10;
    }

    final valRange = maxVal - minVal;

    Offset toCanvas(double timeMs, double value) {
      final x = (timeMs / totalDurationMs).clamp(0.0, 1.0) * size.width;
      final yNorm = ((value - minVal) / valRange).clamp(0.0, 1.0);
      final y = (1.0 - yNorm) * (size.height - 24) + 12;
      return Offset(x, y);
    }

    // Draw Smooth Evaluated Curve
    final curvePath = Path();
    const int samplePoints = 120;
    final curvePaint = Paint()
      ..color = FormaColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i <= samplePoints; i++) {
      final t = (i / samplePoints) * totalDurationMs;
      final val = track.evaluate(t, values.first);
      final pt = toCanvas(t, val);
      if (i == 0) {
        curvePath.moveTo(pt.dx, pt.dy);
      } else {
        curvePath.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(curvePath, curvePaint);

    // Draw Keyframe Points & Tangents
    final ptPaint = Paint()..color = const Color(0xFFF59E0B);
    final handlePaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 1.5;

    for (final kf in track.keyframes) {
      final center = toCanvas(kf.timeMs, kf.value);

      // Tangent Handle
      if (kf.interpolation == InterpolationType.bezier) {
        final outHandle = Offset(
          center.dx + (kf.handleOutX * 40.0),
          center.dy - (kf.handleOutY * 30.0),
        );
        canvas.drawLine(center, outHandle, handlePaint);
        canvas.drawCircle(outHandle, 4, Paint()..color = Colors.cyan);
      }

      // Keyframe Point
      canvas.drawCircle(center, 5, ptPaint);
      canvas.drawCircle(
        center,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white
          ..strokeWidth = 1.5,
      );
    }

    // Draw Playhead Line
    final playheadX = (currentTimeMs / totalDurationMs).clamp(0.0, 1.0) * size.width;
    final playheadPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(playheadX, 0), Offset(playheadX, size.height), playheadPaint);
  }

  @override
  bool shouldRepaint(covariant _GraphEditorPainter old) {
    return old.currentTimeMs != currentTimeMs || old.track != track;
  }
}

/// Keyframe Inspector Dialog to change exact value, timestamp, and easing curves
class _KeyframeInspectorDialog extends StatefulWidget {
  final NodeAnimationTrack track;
  final int kfIndex;
  final FloatKeyframe keyframe;
  final ValueChanged<FloatKeyframe> onSave;
  final VoidCallback onDelete;

  const _KeyframeInspectorDialog({
    required this.track,
    required this.kfIndex,
    required this.keyframe,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_KeyframeInspectorDialog> createState() => _KeyframeInspectorDialogState();
}

class _KeyframeInspectorDialogState extends State<_KeyframeInspectorDialog> {
  late double _timeMs;
  late double _val;
  late InterpolationType _interp;

  @override
  void initState() {
    super.initState();
    _timeMs = widget.keyframe.timeMs;
    _val = widget.keyframe.value;
    _interp = widget.keyframe.interpolation;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Keyframe #${widget.kfIndex + 1}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.track.property.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: FormaColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Time & Value Readout
            Text(
              'Time: ${(_timeMs / 1000).toStringAsFixed(2)}s  ·  Value: ${_val.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Easing / Interpolation Preset Selector
            const Text(
              'INTERPOLATION & EASING',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: InterpolationType.values.map((type) {
                final isSelected = type == _interp;
                return GestureDetector(
                  onTap: () => setState(() => _interp = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? FormaColors.primaryBlue
                          : (isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? FormaColors.primaryBlue
                            : (isDark ? FormaColors.darkBorder : FormaColors.lightBorder),
                      ),
                    ),
                    child: Text(
                      type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: FormaColors.dangerRed),
                  label: const Text('Delete', style: TextStyle(color: FormaColors.dangerRed)),
                  onPressed: () {
                    widget.onDelete();
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FormaColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onSave(widget.keyframe.copyWith(
                      timeMs: _timeMs,
                      value: _val,
                      interpolation: _interp,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Save Curve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
