import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/neumorphic.dart';
import '../../../../app/theme/touch_controls.dart';
import '../../../../domain/models/paint_styles.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final DesignFill? initialFill;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<DesignFill>? onFillChanged;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    this.initialFill,
    required this.onColorChanged,
    this.onFillChanged,
  });

  /// Helper to show color picker adaptively on mobile as a bottom sheet or dialog
  static Future<void> show(
    BuildContext context, {
    required Color initialColor,
    DesignFill? initialFill,
    required ValueChanged<Color> onColorChanged,
    ValueChanged<DesignFill>? onFillChanged,
  }) {
    final isMobile = MediaQuery.of(context).size.shortestSide < 600;
    if (isMobile) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ColorPickerDialog(
            initialColor: initialColor,
            initialFill: initialFill,
            onColorChanged: onColorChanged,
            onFillChanged: onFillChanged,
          ),
        ),
      );
    } else {
      return showDialog(
        context: context,
        builder: (_) => ColorPickerDialog(
          initialColor: initialColor,
          initialFill: initialFill,
          onColorChanged: onColorChanged,
          onFillChanged: onFillChanged,
        ),
      );
    }
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  int _tabIndex = 0; // 0: Wheel, 1: Sliders & Swatches, 2: Gradients

  late Color _currentColor;
  late double _opacity;
  late TextEditingController _hexController;

  // Gradient State
  DesignFillType _gradientType = DesignFillType.linearGradient;
  double _gradientAngle = 135.0;
  List<Color> _gradientColors = [
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
  ];
  int _activeStopIndex = 0;

  static const List<Color> _swatches = [
    // Theme Slate / Neumorphic
    Color(0xFFE6ECF5),
    Color(0xFF2B3445),
    Color(0xFF8A99AD),
    Color(0xFFC8D3E2),
    Color(0xFF4A72B2),
    Color(0xFF0F172A),
    Color(0xFFFFFFFF),
    Color(0xFF000000),

    // Creative Accents
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFF97316),

    // Soft Pastels
    Color(0xFFBAE6FD),
    Color(0xFFA7F3D0),
    Color(0xFFFDE68A),
    Color(0xFFFECDD3),
    Color(0xFFDDD6FE),
    Color(0xFFFED7AA),
    Color(0xFFCFFAFE),
    Color(0xFFE2E8F0),
  ];

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _opacity = widget.initialColor.a;
    _hexController = TextEditingController(text: _colorToHex(_currentColor));

    if (widget.initialFill != null) {
      if (widget.initialFill!.type != DesignFillType.solid &&
          widget.initialFill!.type != DesignFillType.image) {
        _gradientType = widget.initialFill!.type;
        _gradientAngle = widget.initialFill!.gradientAngle;
        if (widget.initialFill!.gradientColors != null &&
            widget.initialFill!.gradientColors!.isNotEmpty) {
          _gradientColors = List<Color>.from(widget.initialFill!.gradientColors!);
        }
        _tabIndex = 2; // Jump directly to Gradients tab
      }
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }

  void _updateColor(Color newColor) {
    setState(() {
      _currentColor = newColor;
      _opacity = newColor.a;
      _hexController.text = _colorToHex(newColor);
      if (_tabIndex == 2 && _activeStopIndex < _gradientColors.length) {
        _gradientColors[_activeStopIndex] = newColor;
      }
    });
    widget.onColorChanged(newColor);
    _emitFillChange();
  }

  void _emitFillChange() {
    if (widget.onFillChanged == null) return;

    if (_tabIndex == 2) {
      // Gradient
      if (_gradientType == DesignFillType.radialGradient) {
        widget.onFillChanged!(
          DesignFill.radial(
            colors: _gradientColors,
            opacity: _opacity,
          ),
        );
      } else if (_gradientType == DesignFillType.angularGradient) {
        widget.onFillChanged!(
          DesignFill.angular(
            colors: _gradientColors,
            opacity: _opacity,
          ),
        );
      } else {
        widget.onFillChanged!(
          DesignFill.linear(
            colors: _gradientColors,
            angle: _gradientAngle,
            opacity: _opacity,
          ),
        );
      }
    } else {
      // Solid
      widget.onFillChanged!(
        DesignFill.solid(_currentColor, opacity: _opacity),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 550;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: size.height * (isCompact ? 0.95 : 0.88),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _currentColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _currentColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tabIndex == 2 ? 'Gradient Studio' : 'Color Picker',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? FormaColors.darkTextMain
                                : FormaColors.lightTextMain,
                          ),
                        ),
                        Text(
                          '#${_colorToHex(_currentColor)} (${(_opacity * 100).toInt()}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? FormaColors.darkTextMuted
                                : FormaColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Tab Selector: Color Wheel | Sliders & Swatches | Gradients
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      label: Text('Wheel'),
                      icon: Icon(Icons.colorize_rounded, size: 15),
                    ),
                    ButtonSegment(
                      value: 1,
                      label: Text('Sliders'),
                      icon: Icon(Icons.tune_rounded, size: 15),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text('Gradients'),
                      icon: Icon(Icons.gradient_rounded, size: 15),
                    ),
                  ],
                  selected: {_tabIndex},
                  onSelectionChanged: (val) {
                    setState(() => _tabIndex = val.first);
                    _emitFillChange();
                  },
                ),
              ),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: _tabIndex == 0
                      ? _buildColorWheelTab(isDark)
                      : _tabIndex == 1
                      ? _buildSlidersAndSwatchesTab(isDark)
                      : _buildGradientsTab(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 0: INTERACTIVE HSV COLOR WHEEL ---
  Widget _buildColorWheelTab(bool isDark) {
    final hsv = HSVColor.fromColor(_currentColor);

    return Column(
      children: [
        // Circular Color Wheel
        SizedBox(
          width: 220,
          height: 220,
          child: _HsvColorWheel(
            hsvColor: hsv,
            onChanged: (newHsv) {
              _updateColor(newHsv.toColor().withValues(alpha: _opacity));
            },
          ),
        ),
        const SizedBox(height: 16),

        // Value / Brightness Slider
        FormaTouchSlider(
          label: 'BRIGHTNESS',
          value: (hsv.value * 100).roundToDouble(),
          min: 0,
          max: 100,
          step: 1,
          activeColor: FormaColors.primaryBlue,
          onChanged: (v) {
            final newHsv = hsv.withValue(v / 100.0);
            _updateColor(newHsv.toColor().withValues(alpha: _opacity));
          },
        ),
        const SizedBox(height: 12),

        // Opacity Slider
        FormaTouchSlider(
          label: 'OPACITY',
          value: (_opacity * 100).roundToDouble(),
          min: 0,
          max: 100,
          step: 1,
          activeColor: Colors.black54,
          onChanged: (v) {
            setState(() => _opacity = v / 100.0);
            _updateColor(_currentColor.withValues(alpha: _opacity));
          },
        ),
      ],
    );
  }

  // --- TAB 1: RGB SLIDERS & SWATCHES ---
  Widget _buildSlidersAndSwatchesTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Red Slider
        FormaTouchSlider(
          label: 'RED',
          value: (_currentColor.r * 255.0).roundToDouble(),
          min: 0,
          max: 255,
          step: 1,
          activeColor: const Color(0xFFEF4444),
          onChanged: (v) {
            _updateColor(_currentColor.withValues(red: v / 255.0));
          },
        ),
        const SizedBox(height: 12),

        // Green Slider
        FormaTouchSlider(
          label: 'GREEN',
          value: (_currentColor.g * 255.0).roundToDouble(),
          min: 0,
          max: 255,
          step: 1,
          activeColor: const Color(0xFF10B981),
          onChanged: (v) {
            _updateColor(_currentColor.withValues(green: v / 255.0));
          },
        ),
        const SizedBox(height: 12),

        // Blue Slider
        FormaTouchSlider(
          label: 'BLUE',
          value: (_currentColor.b * 255.0).roundToDouble(),
          min: 0,
          max: 255,
          step: 1,
          activeColor: const Color(0xFF3B82F6),
          onChanged: (v) {
            _updateColor(_currentColor.withValues(blue: v / 255.0));
          },
        ),
        const SizedBox(height: 12),

        // Alpha Slider
        FormaTouchSlider(
          label: 'OPACITY',
          value: (_opacity * 100.0).roundToDouble(),
          min: 0,
          max: 100,
          step: 1,
          activeColor: const Color(0xFF8A99AD),
          onChanged: (v) {
            setState(() => _opacity = v / 100.0);
            _updateColor(_currentColor.withValues(alpha: _opacity));
          },
        ),
        const SizedBox(height: 16),

        // Hex Code Input Field
        Row(
          children: [
            Text(
              'HEX',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isDark
                    ? FormaColors.darkTextMuted
                    : FormaColors.lightTextMuted,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NeuTextField(
                controller: _hexController,
                hintText: 'RRGGBB',
                onChanged: (val) {
                  final hex = val.replaceAll('#', '').trim();
                  if (hex.length == 6) {
                    final intVal = int.tryParse('FF$hex', radix: 16);
                    if (intVal != null) {
                      _updateColor(Color(intVal).withValues(alpha: _opacity));
                    }
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Palette Swatches
        Text(
          'CURATED PALETTE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark
                ? FormaColors.darkTextMuted
                : FormaColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _swatches.map((color) {
            final isSelected =
                _currentColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => _updateColor(color.withValues(alpha: _opacity)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? FormaColors.primaryBlue
                        : Colors.black.withValues(alpha: 0.12),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: FormaColors.primaryBlue.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- TAB 2: GRADIENTS (LINEAR, RADIAL, ANGULAR / SWEEP) ---
  Widget _buildGradientsTab(bool isDark) {
    // Gradient Preview decoration
    Decoration previewDecor;
    if (_gradientType == DesignFillType.radialGradient) {
      previewDecor = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: RadialGradient(
          colors: _gradientColors,
          center: Alignment.center,
          radius: 0.8,
        ),
      );
    } else if (_gradientType == DesignFillType.angularGradient) {
      previewDecor = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: SweepGradient(
          colors: _gradientColors,
          center: Alignment.center,
        ),
      );
    } else {
      final rad = _gradientAngle * math.pi / 180.0;
      previewDecor = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment(-math.cos(rad), -math.sin(rad)),
          end: Alignment(math.cos(rad), math.sin(rad)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Gradient Preview Bar
        Container(
          height: 64,
          width: double.infinity,
          decoration: previewDecor,
        ),
        const SizedBox(height: 16),

        // Gradient Type Selector
        SegmentedButton<DesignFillType>(
          segments: const [
            ButtonSegment(
              value: DesignFillType.linearGradient,
              label: Text('Linear'),
            ),
            ButtonSegment(
              value: DesignFillType.radialGradient,
              label: Text('Radial'),
            ),
            ButtonSegment(
              value: DesignFillType.angularGradient,
              label: Text('Angular'),
            ),
          ],
          selected: {_gradientType},
          onSelectionChanged: (val) {
            setState(() => _gradientType = val.first);
            _emitFillChange();
          },
        ),
        const SizedBox(height: 16),

        // Angle Slider (For Linear Gradient)
        if (_gradientType == DesignFillType.linearGradient) ...[
          FormaTouchSlider(
            label: 'ANGLE',
            value: _gradientAngle,
            min: 0,
            max: 360,
            step: 5,
            activeColor: FormaColors.primaryBlue,
            onChanged: (v) {
              setState(() => _gradientAngle = v);
              _emitFillChange();
            },
          ),
          const SizedBox(height: 16),
        ],

        // Color Stops Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'COLOR STOPS (${_gradientColors.length})',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark
                    ? FormaColors.darkTextMuted
                    : FormaColors.lightTextMuted,
              ),
            ),
            if (_gradientColors.length < 5)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _gradientColors.add(_currentColor);
                    _activeStopIndex = _gradientColors.length - 1;
                  });
                  _emitFillChange();
                },
                icon: const Icon(Icons.add_rounded, size: 14),
                label: const Text('Add Stop', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Color Stops List
        Row(
          children: _gradientColors.asMap().entries.map((entry) {
            final idx = entry.key;
            final color = entry.value;
            final isSelected = _activeStopIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _activeStopIndex = idx;
                    _currentColor = color;
                    _hexController.text = _colorToHex(color);
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? FormaColors.primaryBlue
                              : Colors.black26,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: FormaColors.primaryBlue.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 8,
                            ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${_colorToHex(color).substring(0, 4)}',
                      style: const TextStyle(fontSize: 9, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          onPressed: () => _showStopColorWheelModal(context, isDark),
          icon: const Icon(Icons.palette_rounded, size: 16, color: FormaColors.primaryBlue),
          label: Text(
            'Pick Stop #${_activeStopIndex + 1} with Color Wheel',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 14),

        // Quick Swatches to apply to active stop
        Text(
          'CLICK COLOR TO UPDATE ACTIVE STOP',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark
                ? FormaColors.darkTextMuted
                : FormaColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _swatches.take(16).map((c) {
            return GestureDetector(
              onTap: () => _updateColor(c),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.black12),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showStopColorWheelModal(BuildContext context, bool isDark) {
    HSVColor tempHsv = HSVColor.fromColor(_gradientColors[_activeStopIndex]);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.palette_rounded, color: FormaColors.primaryBlue),
                const SizedBox(width: 8),
                Text('Pick Color for Stop #${_activeStopIndex + 1}', style: const TextStyle(fontSize: 15)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: GestureDetector(
                    onPanDown: (d) {
                      final center = const Offset(110, 110);
                      final delta = d.localPosition - center;
                      final rad = math.atan2(delta.dy, delta.dx);
                      var deg = rad * 180.0 / math.pi;
                      if (deg < 0) deg += 360.0;
                      final sat = (delta.distance / 110.0).clamp(0.0, 1.0);
                      setModalState(() => tempHsv = tempHsv.withHue(deg).withSaturation(sat));
                      setState(() {
                        _gradientColors[_activeStopIndex] = tempHsv.toColor();
                        _currentColor = tempHsv.toColor();
                        _hexController.text = _colorToHex(_currentColor);
                      });
                      _emitFillChange();
                    },
                    onPanUpdate: (d) {
                      final center = const Offset(110, 110);
                      final delta = d.localPosition - center;
                      final rad = math.atan2(delta.dy, delta.dx);
                      var deg = rad * 180.0 / math.pi;
                      if (deg < 0) deg += 360.0;
                      final sat = (delta.distance / 110.0).clamp(0.0, 1.0);
                      setModalState(() => tempHsv = tempHsv.withHue(deg).withSaturation(sat));
                      setState(() {
                        _gradientColors[_activeStopIndex] = tempHsv.toColor();
                        _currentColor = tempHsv.toColor();
                        _hexController.text = _colorToHex(_currentColor);
                      });
                      _emitFillChange();
                    },
                    child: CustomPaint(
                      size: const Size(220, 220),
                      painter: _ColorWheelPainter(hsvColor: tempHsv),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FormaTouchSlider(
                  label: 'BRIGHTNESS',
                  value: tempHsv.value,
                  min: 0.0,
                  max: 1.0,
                  step: 0.01,
                  activeColor: FormaColors.primaryBlue,
                  onChanged: (v) {
                    setModalState(() => tempHsv = tempHsv.withValue(v));
                    setState(() {
                      _gradientColors[_activeStopIndex] = tempHsv.toColor();
                      _currentColor = tempHsv.toColor();
                      _hexController.text = _colorToHex(_currentColor);
                    });
                    _emitFillChange();
                  },
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FormaColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom HSV Color Wheel Painter
class _HsvColorWheel extends StatelessWidget {
  final HSVColor hsvColor;
  final ValueChanged<HSVColor> onChanged;

  const _HsvColorWheel({
    required this.hsvColor,
    required this.onChanged,
  });

  void _handlePan(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final rad = math.sqrt(dx * dx + dy * dy);
    final maxRad = size.width / 2;

    var angle = math.atan2(dy, dx) * 180 / math.pi;
    if (angle < 0) angle += 360;

    final sat = (rad / maxRad).clamp(0.0, 1.0);
    onChanged(hsvColor.withHue(angle).withSaturation(sat));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (d) => _handlePan(d.localPosition, const Size(220, 220)),
      onPanUpdate: (d) => _handlePan(d.localPosition, const Size(220, 220)),
      child: CustomPaint(
        size: const Size(220, 220),
        painter: _ColorWheelPainter(hsvColor: hsvColor),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final HSVColor hsvColor;

  _ColorWheelPainter({required this.hsvColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw chromatic sweep ring
    final sweepGradient = SweepGradient(
      colors: const [
        Color(0xFFFF0000),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF00FFFF),
        Color(0xFF0000FF),
        Color(0xFFFF00FF),
        Color(0xFFFF0000),
      ],
    );

    final wheelPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, wheelPaint);

    // Draw radial white center overlay for saturation
    final satPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 1.0),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, satPaint);

    // Draw active indicator thumb
    final angleRad = hsvColor.hue * math.pi / 180.0;
    final dist = hsvColor.saturation * radius;
    final thumbPos = Offset(
      center.dx + dist * math.cos(angleRad),
      center.dy + dist * math.sin(angleRad),
    );

    // Thumb shadow
    canvas.drawCircle(
      thumbPos,
      10,
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Outer white ring
    canvas.drawCircle(
      thumbPos,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Inner fill with current color
    canvas.drawCircle(
      thumbPos,
      7,
      Paint()..color = hsvColor.toColor(),
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) =>
      oldDelegate.hsvColor != hsvColor;
}
