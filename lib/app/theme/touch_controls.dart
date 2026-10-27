import 'dart:async';
import 'package:flutter/material.dart';
import 'forma_colors.dart';

/// Touch-first Stepper and Slider component designed for mobile thumbs.
/// Never forces the keyboard to open, but allows fast increment/decrement with tap or hold.
class FormaTouchSlider extends StatefulWidget {
  final String? label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String unit;
  final Color? activeColor;
  final ValueChanged<double> onChanged;

  const FormaTouchSlider({
    super.key,
    this.label,
    required this.value,
    this.min = 0.0,
    this.max = 100.0,
    this.step = 1.0,
    this.unit = '',
    this.activeColor,
    required this.onChanged,
  });

  @override
  State<FormaTouchSlider> createState() => _FormaTouchSliderState();
}

class _FormaTouchSliderState extends State<FormaTouchSlider> {
  Timer? _holdTimer;

  void _step(double delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    widget.onChanged(next);
  }

  void _startHold(double delta) {
    _step(delta);
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _step(delta);
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.activeColor ?? FormaColors.primaryBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? FormaColors.darkTextMuted
                      : FormaColors.lightTextMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.value.toStringAsFixed(widget.step < 1 ? 1 : 0)}${widget.unit}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            // Stepper Minus [-]
            GestureDetector(
              onTapDown: (_) => _startHold(-widget.step),
              onTapUp: (_) => _stopHold(),
              onTapCancel: _stopHold,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkWellBg
                      : FormaColors.lightWellBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? FormaColors.darkBorder
                        : FormaColors.lightBorder,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: isDark
                        ? FormaColors.darkTextMain
                        : FormaColors.lightTextMain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Large Touch Slider Track
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  activeTrackColor: color,
                  inactiveTrackColor: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  thumbColor: color,
                  overlayColor: color.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                    elevation: 3,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                ),
                child: Slider(
                  value: widget.value.clamp(widget.min, widget.max),
                  min: widget.min,
                  max: widget.max,
                  onChanged: widget.onChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Stepper Plus [+]
            GestureDetector(
              onTapDown: (_) => _startHold(widget.step),
              onTapUp: (_) => _stopHold(),
              onTapCancel: _stopHold,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? FormaColors.darkWellBg
                      : FormaColors.lightWellBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? FormaColors.darkBorder
                        : FormaColors.lightBorder,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: isDark
                        ? FormaColors.darkTextMain
                        : FormaColors.lightTextMain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Nudge field with [+] and [-] buttons and direct horizontal scrub support for mobile thumbs.
class FormaTouchNudgeField extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const FormaTouchNudgeField({
    super.key,
    required this.label,
    required this.value,
    this.min = -99999,
    this.max = 99999,
    this.step = 1.0,
    required this.onChanged,
  });

  @override
  State<FormaTouchNudgeField> createState() => _FormaTouchNudgeFieldState();
}

class _FormaTouchNudgeFieldState extends State<FormaTouchNudgeField> {
  Timer? _holdTimer;
  double _dragAccumulator = 0.0;

  void _step(double delta) {
    final next = (widget.value + delta).clamp(widget.min, widget.max);
    widget.onChanged(next);
  }

  void _startHold(double delta) {
    _step(delta);
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      _step(delta);
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _promptDirectEdit(BuildContext context) {
    final controller = TextEditingController(
      text: widget.value.toStringAsFixed(1),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set ${widget.label}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed != null) {
                widget.onChanged(parsed.clamp(widget.min, widget.max));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Minus Button
          GestureDetector(
            onTapDown: (_) => _startHold(-widget.step),
            onTapUp: (_) => _stopHold(),
            onTapCancel: _stopHold,
            child: Container(
              width: 28,
              height: 42,
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  Icons.remove_rounded,
                  size: 15,
                  color: isDark
                      ? FormaColors.darkTextMuted
                      : FormaColors.lightTextMuted,
                ),
              ),
            ),
          ),

          // Label and Value display with Horizontal scrub & Tap to edit
          Expanded(
            child: GestureDetector(
              onHorizontalDragStart: (_) => _dragAccumulator = 0,
              onHorizontalDragUpdate: (details) {
                _dragAccumulator += details.delta.dx;
                if (_dragAccumulator.abs() >= 4.0) {
                  final steps = (_dragAccumulator / 4.0).truncate();
                  _step(steps * widget.step);
                  _dragAccumulator -= steps * 4.0;
                }
              },
              onTap: () => _promptDirectEdit(context),
              child: Container(
                color: Colors.transparent,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: FormaColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.value.toStringAsFixed(
                          widget.step < 1 ? 1 : 0,
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? FormaColors.darkTextMain
                              : FormaColors.lightTextMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Plus Button
          GestureDetector(
            onTapDown: (_) => _startHold(widget.step),
            onTapUp: (_) => _stopHold(),
            onTapCancel: _stopHold,
            child: Container(
              width: 28,
              height: 42,
              color: Colors.transparent,
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  size: 15,
                  color: isDark
                      ? FormaColors.darkTextMuted
                      : FormaColors.lightTextMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
