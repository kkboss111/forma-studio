import 'package:flutter/material.dart';
import '../../../../domain/models/project_model.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../domain/services/node_render_service.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/neumorphic.dart';

class PrototypePlayer extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onClose;

  const PrototypePlayer({
    super.key,
    required this.project,
    required this.onClose,
  });

  @override
  State<PrototypePlayer> createState() => _PrototypePlayerState();
}

class _PrototypePlayerState extends State<PrototypePlayer> {
  late String _currentFrameId;
  final List<String> _historyStack = [];
  bool _isLandscape = false;
  bool _showHotspotHint = false;

  @override
  void initState() {
    super.initState();
    // Default to first frame or starting frame of flow
    final flow =
        widget.project.flows.isEmpty ? null : widget.project.flows.first;
    if (flow?.startingFrameId != null &&
        widget.project.nodes.containsKey(flow!.startingFrameId)) {
      _currentFrameId = flow.startingFrameId!;
    } else {
      final frames = widget.project.nodes.values
          .where((n) => n.type.isContainer)
          .toList();
      _currentFrameId = frames.isNotEmpty ? frames.first.id : '';
    }
  }

  void _triggerNode(String nodeId) {
    for (final flow in widget.project.flows) {
      for (final inter in flow.interactions) {
        if (inter.sourceNodeId == nodeId &&
            widget.project.nodes.containsKey(inter.targetFrameId)) {
          setState(() {
            _historyStack.add(_currentFrameId);
            _currentFrameId = inter.targetFrameId;
          });
          return;
        }
      }
    }
    // If no interaction on this node, flash hotspot hint
    setState(() => _showHotspotHint = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showHotspotHint = false);
    });
  }

  void _goBack() {
    if (_historyStack.isNotEmpty) {
      setState(() {
        _currentFrameId = _historyStack.removeLast();
      });
    }
  }

  void _resetFlow() {
    final flow =
        widget.project.flows.isEmpty ? null : widget.project.flows.first;
    final containerNodes =
        widget.project.nodes.values.where((n) => n.type.isContainer).toList();
    setState(() {
      _historyStack.clear();
      _currentFrameId = flow?.startingFrameId ??
          (containerNodes.isNotEmpty ? containerNodes.first.id : '');
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentFrame = widget.project.nodes[_currentFrameId];

    return Scaffold(
      backgroundColor: const Color(0xFF141820),
      body: SafeArea(
        child: Column(
          children: [
            // Top Control Bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFF1B202A),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _historyStack.isNotEmpty ? _goBack : null,
                    tooltip: 'Back',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _resetFlow,
                    tooltip: 'Restart Prototype',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentFrame?.name ?? 'Prototype Preview',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Orientation Toggle
                  NeuIconButton(
                    icon: _isLandscape
                        ? Icons.screen_lock_landscape_rounded
                        : Icons.screen_lock_portrait_rounded,
                    size: 34,
                    iconSize: 18,
                    iconColor: Colors.white,
                    tooltip: 'Toggle Device Orientation',
                    onPressed: () =>
                        setState(() => _isLandscape = !_isLandscape),
                  ),
                  const SizedBox(width: 12),
                  // Exit Presentation
                  NeuButton(
                    onPressed: widget.onClose,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    color: const Color(0xFF283140),
                    child: const Text(
                      'Exit Player',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Device Mockup Viewport Area
            Expanded(
              child: Center(
                child: currentFrame == null
                    ? const Text(
                        'No frames available for prototyping',
                        style: TextStyle(color: Colors.white70),
                      )
                    : _buildDeviceMockup(currentFrame),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceMockup(DesignNode frame) {
    final frameW = _isLandscape ? frame.height : frame.width;
    final frameH = _isLandscape ? frame.width : frame.height;

    return Container(
      width: frameW,
      height: frameH,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            offset: Offset(0, 20),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTapDown: (details) {
          final localPt = details.localPosition;
          // Hit-test children of this frame to trigger interaction
          final hit = _hitTestFrameChildren(localPt, frame);
          if (hit != null) {
            _triggerNode(hit.id);
          } else {
            _triggerNode(frame.id);
          }
        },
        child: Stack(
          children: [
            CustomPaint(
              size: Size(frameW, frameH),
              painter: _FramePainter(
                frame: frame,
                allNodes: widget.project.nodes,
              ),
            ),
            // Hotspot hint flash
            if (_showHotspotHint)
              Positioned.fill(
                child: Container(
                  color: FormaColors.primaryBlue.withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  DesignNode? _hitTestFrameChildren(Offset localPt, DesignNode frame) {
    for (final childId in frame.childrenIds.reversed) {
      final child = widget.project.nodes[childId];
      if (child != null && child.isVisible) {
        // Child coordinates are relative to canvas, convert relative to frame
        final childLocal = Rect.fromLTWH(
          child.x - frame.x,
          child.y - frame.y,
          child.width,
          child.height,
        );
        if (childLocal.contains(localPt)) {
          return child;
        }
      }
    }
    return null;
  }
}

class _FramePainter extends CustomPainter {
  final DesignNode frame;
  final Map<String, DesignNode> allNodes;

  _FramePainter({required this.frame, required this.allNodes});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Offset so frame top-left is at (0, 0)
    canvas.translate(-frame.x, -frame.y);
    NodeRenderService.renderNode(canvas, frame, allNodes);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => true;
}
