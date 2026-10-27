import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../app/theme/forma_colors.dart';

class FloatingPanelWindow extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Offset initialPosition;
  final Size initialSize;
  final Size minSize;
  final VoidCallback onDock;
  final VoidCallback? onClose;

  const FloatingPanelWindow({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.initialPosition = const Offset(80, 80),
    this.initialSize = const Size(380, 320),
    this.minSize = const Size(260, 160),
    required this.onDock,
    this.onClose,
  });

  @override
  State<FloatingPanelWindow> createState() => _FloatingPanelWindowState();
}

class _FloatingPanelWindowState extends State<FloatingPanelWindow> {
  late Offset _position;
  late Size _size;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _size = widget.initialSize;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Container(
        width: _size.width,
        height: _isMinimized ? 44 : _size.height,
        decoration: BoxDecoration(
          color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Draggable Title Header
              GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _position += details.delta;
                    _position = Offset(
                      math.max(10.0, _position.dx),
                      math.max(10.0, _position.dy),
                    );
                  });
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141820) : const Color(0xFFE2EAF4),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, size: 16, color: FormaColors.primaryBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Minimize / Restore
                      IconButton(
                        icon: Icon(
                          _isMinimized ? Icons.expand_more_rounded : Icons.remove_rounded,
                          size: 16,
                        ),
                        splashRadius: 14,
                        tooltip: _isMinimized ? 'Expand' : 'Minimize',
                        onPressed: () => setState(() => _isMinimized = !_isMinimized),
                      ),
                      // Dock back
                      IconButton(
                        icon: const Icon(Icons.push_pin_outlined, size: 15),
                        splashRadius: 14,
                        tooltip: 'Dock to Sidebar',
                        onPressed: widget.onDock,
                      ),
                      if (widget.onClose != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          splashRadius: 14,
                          tooltip: 'Close Window',
                          onPressed: widget.onClose,
                        ),
                    ],
                  ),
                ),
              ),

              // Window Content
              if (!_isMinimized)
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: widget.child),

                      // Desktop-only Resize Corner Grip
                      if (isDesktop)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                final newW = math.max(
                                  widget.minSize.width,
                                  _size.width + details.delta.dx,
                                );
                                final newH = math.max(
                                  widget.minSize.height,
                                  _size.height + details.delta.dy,
                                );
                                _size = Size(newW, newH);
                              });
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeDownRight,
                              child: Container(
                                width: 20,
                                height: 20,
                                color: Colors.transparent,
                                child: CustomPaint(
                                  painter: _ResizeGripPainter(
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizeGripPainter extends CustomPainter {
  final Color color;
  _ResizeGripPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw 3 diagonal grip lines
    canvas.drawLine(Offset(size.width - 4, size.height - 12), Offset(size.width - 12, size.height - 4), paint);
    canvas.drawLine(Offset(size.width - 4, size.height - 8), Offset(size.width - 8, size.height - 4), paint);
    canvas.drawLine(Offset(size.width - 4, size.height - 4), Offset(size.width - 4, size.height - 4), paint);
  }

  @override
  bool shouldRepaint(covariant _ResizeGripPainter oldDelegate) => false;
}
