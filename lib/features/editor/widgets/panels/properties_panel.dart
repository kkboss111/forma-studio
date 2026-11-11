import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../../../domain/services/custom_font_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../domain/models/project_model.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../domain/models/paint_styles.dart';
import '../../../../domain/models/layout_config.dart';
import '../../../../domain/models/constraints.dart';
import '../../../../domain/models/text_data.dart';
import '../../../../domain/services/node_render_service.dart';
import '../../../../app/theme/forma_theme.dart';
import '../../../../app/theme/touch_controls.dart';
import '../../../settings/models/app_settings.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/editor_state.dart';
import '../dialogs/color_picker_dialog.dart';
import '../dialogs/image_editor_dialog.dart';
import '../dialogs/export_dialog.dart';
import '../canvas/canvas_viewport.dart';

class PropertiesPanel extends ConsumerStatefulWidget {
  final ProjectModel project;
  final double? width;

  const PropertiesPanel({super.key, required this.project, this.width = 280});

  @override
  ConsumerState<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends ConsumerState<PropertiesPanel> {
  bool _aspectRatioLocked = false;
  String _selectedExportFormat = 'PNG';
  String _selectedExportScale = '2x';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider(widget.project));
    final controller = ref.read(editorControllerProvider(widget.project).notifier);
    final settings = ref.watch(settingsProvider);
    final tokens = FormaTheme.tokensOf(context);
    final isDark = tokens.isDark;

    final selectedIds = state.selectedNodeIds;
    final primaryNode = selectedIds.isNotEmpty
        ? state.project.nodes[selectedIds.first]
        : null;

    Widget panel = Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          left: BorderSide(
            color: tokens.border,
            width: 1.0,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        children: [
          if (primaryNode == null) ...[
            // Canvas / Page Settings
            _buildPageSettings(context, state, controller, settings, tokens, isDark),
          ] else ...[
            // Alignment Grid Section
            _buildAlignmentSection(controller, tokens, isDark),

            // Geometry Section (Position, Dimensions, Rotation, Radius, Opacity)
            _buildGeometrySection(context, primaryNode, controller, tokens, isDark),

            // Constraints Section
            _buildConstraintsSection(context, primaryNode, controller, tokens, isDark),

            // Auto-Layout Section (Frames/Containers)
            if (primaryNode.type == NodeType.frame ||
                primaryNode.type == NodeType.annotationSection) ...[
              _buildAutoLayoutSection(context, primaryNode, controller, tokens, isDark),
            ],

            // Typography Section (If Text Node)
            if (primaryNode.type == NodeType.text &&
                primaryNode.textData != null) ...[
              TypographyPropertySection(
                node: primaryNode,
                controller: controller,
                tokens: tokens,
                isDark: isDark,
              ),
            ],

            // Fills Section
            _buildFillsSection(context, primaryNode, controller, tokens, isDark),

            // Strokes Section
            _buildStrokesSection(context, primaryNode, controller, tokens, isDark),

            // Effects Section
            _buildEffectsSection(context, primaryNode, controller, tokens, isDark),

            // Vector Path / Pencil Draw Section
            if (primaryNode.type == NodeType.vectorPath ||
                primaryNode.type == NodeType.freehandPath) ...[
              _buildVectorPathSection(context, primaryNode, controller, tokens, isDark),
            ],

            // Export Section
            _buildExportSection(context, primaryNode, state, tokens, isDark),
          ],
        ],
      ),
    );

    if (tokens.isGlass && tokens.cardBlur > 0) {
      return ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: tokens.cardBlur, sigmaY: tokens.cardBlur),
          child: panel,
        ),
      );
    }

    return panel;
  }

  Widget _buildAlignmentSection(
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    return PropertySectionCard(
      title: 'ALIGNMENT',
      icon: Icons.align_horizontal_center_rounded,
      tokens: tokens,
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _buildMicroIconButton(
              icon: Icons.align_horizontal_left_rounded,
              tooltip: 'Align Left',
              tokens: tokens,
              onTap: () => controller.alignSelection('left'),
            ),
          ),
          Expanded(
            child: _buildMicroIconButton(
              icon: Icons.align_horizontal_center_rounded,
              tooltip: 'Align Center Horizontal',
              tokens: tokens,
              onTap: () => controller.alignSelection('centerHorizontal'),
            ),
          ),
          Expanded(
            child: _buildMicroIconButton(
              icon: Icons.align_horizontal_right_rounded,
              tooltip: 'Align Right',
              tokens: tokens,
              onTap: () => controller.alignSelection('right'),
            ),
          ),
          Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 2), color: tokens.borderSubtle),
          Expanded(
            child: _buildMicroIconButton(
              icon: Icons.align_vertical_top_rounded,
              tooltip: 'Align Top',
              tokens: tokens,
              onTap: () => controller.alignSelection('top'),
            ),
          ),
          Expanded(
            child: _buildMicroIconButton(
              icon: Icons.align_vertical_center_rounded,
              tooltip: 'Align Center Vertical',
              tokens: tokens,
              onTap: () => controller.alignSelection('centerVertical'),
            ),
          ),
          Expanded(
            child: _buildMicroIconButton(
              icon: Icons.align_vertical_bottom_rounded,
              tooltip: 'Align Bottom',
              tokens: tokens,
              onTap: () => controller.alignSelection('bottom'),
            ),
          ),
          Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 2), color: tokens.borderSubtle),
          Expanded(
            child: _buildMicroIconButton(
              icon: Icons.horizontal_distribute_rounded,
              tooltip: 'Distribute Horizontal',
              tokens: tokens,
              onTap: () => controller.distributeSelection('horizontal'),
            ),
          ),
          Expanded(
            child: _buildMicroIconButton(
              icon: Icons.vertical_distribute_rounded,
              tooltip: 'Distribute Vertical',
              tokens: tokens,
              onTap: () => controller.distributeSelection('vertical'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeometrySection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    return PropertySectionCard(
      title: 'GEOMETRY',
      icon: Icons.straighten_rounded,
      tokens: tokens,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Position X and Y
          Row(
            children: [
              Expanded(
                child: FormaTouchNudgeField(
                  label: 'X',
                  value: node.x,
                  onChanged: (val) => controller.updateNode(node.copyWith(x: val)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FormaTouchNudgeField(
                  label: 'Y',
                  value: node.y,
                  onChanged: (val) => controller.updateNode(node.copyWith(y: val)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Dimensions Width, Height and Aspect Ratio Lock
          Row(
            children: [
              Expanded(
                child: FormaTouchNudgeField(
                  label: 'W',
                  value: node.width,
                  min: 1,
                  onChanged: (val) {
                    final newW = math.max(1.0, val);
                    if (_aspectRatioLocked && node.width > 0) {
                      final ratio = node.height / node.width;
                      controller.updateNode(
                        node.copyWith(
                          width: newW,
                          height: math.max(1.0, newW * ratio),
                        ),
                      );
                    } else {
                      controller.updateNode(node.copyWith(width: newW));
                    }
                  },
                ),
              ),
              // Aspect Ratio Lock Button
              Tooltip(
                message: _aspectRatioLocked ? 'Unlock Aspect Ratio' : 'Lock Aspect Ratio',
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _aspectRatioLocked = !_aspectRatioLocked;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 28,
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _aspectRatioLocked
                          ? tokens.accent.withValues(alpha: isDark ? 0.20 : 0.12)
                          : tokens.wellBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _aspectRatioLocked
                            ? tokens.accent.withValues(alpha: isDark ? 0.6 : 0.4)
                            : tokens.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _aspectRatioLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                        size: 14,
                        color: _aspectRatioLocked ? tokens.accent : tokens.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FormaTouchNudgeField(
                  label: 'H',
                  value: node.height,
                  min: 1,
                  onChanged: (val) {
                    final newH = math.max(1.0, val);
                    if (_aspectRatioLocked && node.height > 0) {
                      final ratio = node.width / node.height;
                      controller.updateNode(
                        node.copyWith(
                          height: newH,
                          width: math.max(1.0, newH * ratio),
                        ),
                      );
                    } else {
                      controller.updateNode(node.copyWith(height: newH));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: Rotation & Corner Radius
          Row(
            children: [
              Expanded(
                child: FormaTouchNudgeField(
                  label: 'R°',
                  value: node.rotation,
                  onChanged: (val) => controller.updateNode(node.copyWith(rotation: val)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FormaTouchNudgeField(
                  label: 'Rad',
                  value: node.cornerRadii.uniformValue,
                  min: 0,
                  onChanged: (val) => controller.updateNode(
                    node.copyWith(cornerRadii: CornerRadii.all(val)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Flip Transformation Actions Row
          Row(
            children: [
              Expanded(
                child: _buildActionPill(
                  label: 'Flip Horizontal',
                  icon: Icons.flip_rounded,
                  tokens: tokens,
                  onTap: () => controller.flipHorizontalSelected(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionPill(
                  label: 'Flip Vertical',
                  icon: Icons.swap_vertical_circle_outlined,
                  tokens: tokens,
                  onTap: () => controller.flipVerticalSelected(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Opacity Slider
          FormaTouchSlider(
            label: 'OPACITY',
            value: (node.opacity * 100.0).roundToDouble(),
            min: 0,
            max: 100,
            step: 5,
            unit: '%',
            activeColor: tokens.accent,
            onChanged: (val) {
              controller.updateNode(
                node.copyWith(opacity: (val / 100.0).clamp(0.0, 1.0)),
              );
            },
          ),

          // Polygon / Star Corner Options
          if (node.type == NodeType.polygon) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.wellBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.borderSubtle, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        node.polygonSides == 3 ? 'TRIANGLE CORNERS' : 'POLYGON SIDES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tokens.textMuted,
                        ),
                      ),
                      Text(
                        '${node.polygonSides} sides',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: tokens.accent,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: node.polygonSides.toDouble().clamp(3.0, 12.0),
                      min: 3,
                      max: 12,
                      divisions: 9,
                      activeColor: tokens.accent,
                      onChanged: (val) {
                        controller.updateNode(
                          node.copyWith(polygonSides: val.toInt()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConstraintsSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    return PropertySectionCard(
      title: 'CONSTRAINTS',
      icon: Icons.filter_center_focus_rounded,
      tokens: tokens,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horizontal',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tokens.textMuted),
          ),
          const SizedBox(height: 4),
          _buildSegmentedConstraintPill<HorizontalConstraint>(
            currentValue: node.constraints.horizontal,
            values: const [
              HorizontalConstraint.left,
              HorizontalConstraint.center,
              HorizontalConstraint.right,
              HorizontalConstraint.scale,
            ],
            labelBuilder: (c) => c.name.toUpperCase(),
            tokens: tokens,
            onSelected: (val) {
              controller.updateNode(
                node.copyWith(
                  constraints: node.constraints.copyWith(horizontal: val),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Vertical',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tokens.textMuted),
          ),
          const SizedBox(height: 4),
          _buildSegmentedConstraintPill<VerticalConstraint>(
            currentValue: node.constraints.vertical,
            values: const [
              VerticalConstraint.top,
              VerticalConstraint.center,
              VerticalConstraint.bottom,
              VerticalConstraint.scale,
            ],
            labelBuilder: (c) => c.name.toUpperCase(),
            tokens: tokens,
            onSelected: (val) {
              controller.updateNode(
                node.copyWith(
                  constraints: node.constraints.copyWith(vertical: val),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAutoLayoutSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    final cfg = node.layoutConfig;

    return PropertySectionCard(
      title: 'AUTO-LAYOUT',
      icon: Icons.view_quilt_outlined,
      tokens: tokens,
      isDark: isDark,
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch(
          value: cfg.enabled,
          activeThumbColor: tokens.accent,
          activeTrackColor: tokens.accent.withValues(alpha: 0.3),
          onChanged: (val) {
            controller.updateNode(
              node.copyWith(layoutConfig: cfg.copyWith(enabled: val)),
            );
          },
        ),
      ),
      child: cfg.enabled
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Direction Segmented Pill (Row vs Column)
                Row(
                  children: [
                    Expanded(
                      child: _buildDirectionOption(
                        label: 'Horizontal (Row)',
                        icon: Icons.view_column_rounded,
                        isSelected: cfg.direction == AutoLayoutDirection.horizontal,
                        tokens: tokens,
                        onTap: () {
                          controller.updateNode(
                            node.copyWith(
                              layoutConfig: cfg.copyWith(
                                direction: AutoLayoutDirection.horizontal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDirectionOption(
                        label: 'Vertical (Column)',
                        icon: Icons.table_rows_rounded,
                        isSelected: cfg.direction == AutoLayoutDirection.vertical,
                        tokens: tokens,
                        onTap: () {
                          controller.updateNode(
                            node.copyWith(
                              layoutConfig: cfg.copyWith(
                                direction: AutoLayoutDirection.vertical,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Gap and Padding Fields
                Row(
                  children: [
                    Expanded(
                      child: FormaTouchNudgeField(
                        label: 'Gap',
                        value: cfg.gap,
                        min: 0,
                        onChanged: (val) {
                          controller.updateNode(
                            node.copyWith(layoutConfig: cfg.copyWith(gap: val)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FormaTouchNudgeField(
                        label: 'Pad',
                        value: cfg.paddingLeft,
                        min: 0,
                        onChanged: (val) {
                          controller.updateNode(
                            node.copyWith(
                              layoutConfig: cfg.copyWith(
                                paddingLeft: val,
                                paddingTop: val,
                                paddingRight: val,
                                paddingBottom: val,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Text(
              'Enable auto-layout to automatically manage nested element flow and spacing.',
              style: TextStyle(fontSize: 11, color: tokens.textMuted),
            ),
    );
  }

  Widget _buildDirectionOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required FormaThemeTokens tokens,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.accent.withValues(alpha: tokens.isDark ? 0.22 : 0.12)
              : tokens.wellBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tokens.accent : tokens.borderSubtle,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? tokens.accent : tokens.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? tokens.accent : tokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillsSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    return PropertySectionCard(
      title: 'FILLS',
      icon: Icons.format_color_fill_rounded,
      tokens: tokens,
      isDark: isDark,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniHeaderButton(
            icon: Icons.image_outlined,
            tooltip: 'Add Image Fill',
            tokens: tokens,
            onTap: () => _pickImageFill(context, node, null, controller),
          ),
          const SizedBox(width: 4),
          _buildMiniHeaderButton(
            icon: Icons.add_rounded,
            tooltip: 'Add Color Fill',
            tokens: tokens,
            onTap: () {
              controller.updateNode(
                node.copyWith(
                  fills: [
                    ...node.fills,
                    const DesignFill.solid(Color(0xFF3B82F6)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      child: node.fills.isEmpty
          ? Text('No fills applied', style: TextStyle(fontSize: 11, color: tokens.textMuted))
          : Column(
              children: node.fills.asMap().entries.map((entry) {
                final i = entry.key;
                final fill = entry.value;

                String typeBadge = 'SOLID';
                if (fill.type == DesignFillType.linearGradient) typeBadge = 'LINEAR';
                if (fill.type == DesignFillType.radialGradient) typeBadge = 'RADIAL';
                if (fill.type == DesignFillType.angularGradient) typeBadge = 'ANGULAR';
                if (fill.type == DesignFillType.image) typeBadge = 'IMAGE';

                final hexString = '#${fill.color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.wellBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tokens.borderSubtle, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      // Color Chip
                      GestureDetector(
                        onTap: () => _handleFillTap(context, node, fill, i, controller),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: fill.type == DesignFillType.image
                                ? const Color(0xFF64748B)
                                : fill.color,
                            gradient: (fill.type == DesignFillType.linearGradient &&
                                    fill.gradientColors != null)
                                ? LinearGradient(colors: fill.gradientColors!)
                                : null,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: fill.type == DesignFillType.image
                              ? const Icon(Icons.image, size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Fill Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tokens.accent.withValues(alpha: isDark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeBadge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: tokens.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Color Hex Code
                      Expanded(
                        child: Text(
                          fill.type == DesignFillType.image ? 'Image Mask' : hexString,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                            color: tokens.textMain,
                          ),
                        ),
                      ),

                      // Delete Fill Button
                      InkWell(
                        onTap: () {
                          final updated = List<DesignFill>.from(node.fills)..removeAt(i);
                          controller.updateNode(node.copyWith(fills: updated));
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.close_rounded, size: 14, color: tokens.textMuted),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  void _handleFillTap(
    BuildContext context,
    DesignNode node,
    DesignFill fill,
    int index,
    EditorController controller,
  ) {
    if (fill.type == DesignFillType.image) {
      final existingImg = fill.imageBase64 ?? fill.imagePath;
      if (existingImg != null && existingImg.isNotEmpty) {
        ImageEditorDialog.show(
          context,
          initialImageBase64: existingImg,
          onApply: (newB64) {
            final updatedFills = List<DesignFill>.from(node.fills);
            updatedFills[index] = fill.copyWith(
              imageBase64: newB64,
              imagePath: newB64,
            );
            controller.updateNode(node.copyWith(fills: updatedFills));
          },
        );
      } else {
        _pickImageFill(context, node, index, controller);
      }
    } else {
      ColorPickerDialog.show(
        context,
        initialColor: fill.color,
        initialFill: fill,
        onColorChanged: (c) {
          final updatedFills = List<DesignFill>.from(node.fills);
          updatedFills[index] = fill.copyWith(color: c);
          controller.updateNode(node.copyWith(fills: updatedFills));
        },
        onFillChanged: (newFill) {
          final updatedFills = List<DesignFill>.from(node.fills);
          updatedFills[index] = newFill;
          controller.updateNode(node.copyWith(fills: updatedFills));
        },
      );
    }
  }

  Widget _buildStrokesSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    return PropertySectionCard(
      title: 'STROKES',
      icon: Icons.border_style_rounded,
      tokens: tokens,
      isDark: isDark,
      trailing: _buildMiniHeaderButton(
        icon: Icons.add_rounded,
        tooltip: 'Add Stroke',
        tokens: tokens,
        onTap: () {
          controller.updateNode(
            node.copyWith(
              strokes: [
                ...node.strokes,
                const DesignStroke(color: Color(0xFF94A3B8), width: 1.0),
              ],
            ),
          );
        },
      ),
      child: node.strokes.isEmpty
          ? Text('No strokes applied', style: TextStyle(fontSize: 11, color: tokens.textMuted))
          : Column(
              children: node.strokes.asMap().entries.map((entry) {
                final i = entry.key;
                final stroke = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.wellBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tokens.borderSubtle, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      // Stroke Color Chip
                      GestureDetector(
                        onTap: () {
                          ColorPickerDialog.show(
                            context,
                            initialColor: stroke.color,
                            onColorChanged: (c) {
                              final updated = List<DesignStroke>.from(node.strokes);
                              updated[i] = stroke.copyWith(color: c, clearGradient: true);
                              controller.updateNode(node.copyWith(strokes: updated));
                            },
                          );
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: stroke.color,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Width Scrubber
                      Expanded(
                        child: FormaTouchNudgeField(
                          label: 'W',
                          value: stroke.width,
                          min: 0,
                          onChanged: (val) {
                            final updated = List<DesignStroke>.from(node.strokes);
                            updated[i] = stroke.copyWith(width: math.max(0, val));
                            controller.updateNode(node.copyWith(strokes: updated));
                          },
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Delete Stroke Button
                      InkWell(
                        onTap: () {
                          final updated = List<DesignStroke>.from(node.strokes)..removeAt(i);
                          controller.updateNode(node.copyWith(strokes: updated));
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(Icons.close_rounded, size: 14, color: tokens.textMuted),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEffectsSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    return PropertySectionCard(
      title: 'EFFECTS',
      icon: Icons.auto_awesome_rounded,
      tokens: tokens,
      isDark: isDark,
      trailing: PopupMenuButton<DesignEffectType>(
        icon: Icon(Icons.add_rounded, size: 16, color: tokens.accent),
        tooltip: 'Add Effect',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        color: tokens.surface,
        onSelected: (type) => _addEffect(type, node, controller),
        itemBuilder: (ctx) => [
          _buildEffectMenuItem(DesignEffectType.dropShadow, 'Drop Shadow', tokens),
          _buildEffectMenuItem(DesignEffectType.innerShadow, 'Inner Shadow', tokens),
          _buildEffectMenuItem(DesignEffectType.blur, 'Layer Blur', tokens),
          _buildEffectMenuItem(DesignEffectType.backgroundBlur, 'Backdrop Blur', tokens),
          _buildEffectMenuItem(DesignEffectType.outerGlow, 'Outer Glow', tokens),
          _buildEffectMenuItem(DesignEffectType.innerGlow, 'Inner Glow', tokens),
          _buildEffectMenuItem(DesignEffectType.bloom, 'Bloom', tokens),
          _buildEffectMenuItem(DesignEffectType.grayscale, 'Grayscale', tokens),
          _buildEffectMenuItem(DesignEffectType.sepia, 'Sepia Tone', tokens),
          _buildEffectMenuItem(DesignEffectType.invertColors, 'Invert Colors', tokens),
        ],
      ),
      child: node.effects.isEmpty
          ? Text('No effects applied', style: TextStyle(fontSize: 11, color: tokens.textMuted))
          : Column(
              children: node.effects.asMap().entries.map((entry) {
                final i = entry.key;
                final eff = entry.value;

                final hasColor = eff.type == DesignEffectType.dropShadow ||
                    eff.type == DesignEffectType.innerShadow ||
                    eff.type == DesignEffectType.outerGlow ||
                    eff.type == DesignEffectType.innerGlow;

                final hasOffsets = eff.type == DesignEffectType.dropShadow ||
                    eff.type == DesignEffectType.innerShadow;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.wellBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tokens.borderSubtle, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (hasColor) ...[
                            GestureDetector(
                              onTap: () {
                                ColorPickerDialog.show(
                                  context,
                                  initialColor: eff.color,
                                  onColorChanged: (c) {
                                    final updated = List<DesignEffect>.from(node.effects);
                                    updated[i] = eff.copyWith(color: c);
                                    controller.updateNode(node.copyWith(effects: updated));
                                  },
                                );
                              },
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: eff.color,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _getEffectLabel(eff.type),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tokens.textMain,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              final updated = List<DesignEffect>.from(node.effects)..removeAt(i);
                              controller.updateNode(node.copyWith(effects: updated));
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(Icons.close_rounded, size: 14, color: tokens.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FormaTouchNudgeField(
                              label: 'Blur',
                              value: eff.blurRadius,
                              min: 0,
                              onChanged: (v) {
                                final updated = List<DesignEffect>.from(node.effects);
                                updated[i] = eff.copyWith(blurRadius: v);
                                controller.updateNode(node.copyWith(effects: updated));
                              },
                            ),
                          ),
                          if (hasOffsets) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: FormaTouchNudgeField(
                                label: 'X',
                                value: eff.offsetX,
                                onChanged: (v) {
                                  final updated = List<DesignEffect>.from(node.effects);
                                  updated[i] = eff.copyWith(offsetX: v);
                                  controller.updateNode(node.copyWith(effects: updated));
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FormaTouchNudgeField(
                                label: 'Y',
                                value: eff.offsetY,
                                onChanged: (v) {
                                  final updated = List<DesignEffect>.from(node.effects);
                                  updated[i] = eff.copyWith(offsetY: v);
                                  controller.updateNode(node.copyWith(effects: updated));
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  PopupMenuItem<DesignEffectType> _buildEffectMenuItem(
    DesignEffectType type,
    String label,
    FormaThemeTokens tokens,
  ) {
    return PopupMenuItem(
      value: type,
      height: 34,
      child: Text(
        label,
        style: TextStyle(fontSize: 12, color: tokens.textMain),
      ),
    );
  }

  void _addEffect(DesignEffectType type, DesignNode node, EditorController controller) {
    DesignEffect newEff;
    switch (type) {
      case DesignEffectType.dropShadow:
        newEff = const DesignEffect(
          type: DesignEffectType.dropShadow,
          color: Color(0x33000000),
          offsetX: 0,
          offsetY: 4,
          blurRadius: 8,
        );
        break;
      case DesignEffectType.innerShadow:
        newEff = const DesignEffect(
          type: DesignEffectType.innerShadow,
          color: Color(0x33000000),
          offsetX: 0,
          offsetY: 2,
          blurRadius: 4,
        );
        break;
      case DesignEffectType.blur:
        newEff = const DesignEffect(
          type: DesignEffectType.blur,
          blurRadius: 10,
        );
        break;
      case DesignEffectType.backgroundBlur:
        newEff = const DesignEffect(
          type: DesignEffectType.backgroundBlur,
          blurRadius: 16,
        );
        break;
      case DesignEffectType.outerGlow:
        newEff = const DesignEffect(
          type: DesignEffectType.outerGlow,
          color: Color(0x663B82F6),
          blurRadius: 16,
          spreadRadius: 4,
        );
        break;
      case DesignEffectType.innerGlow:
        newEff = const DesignEffect(
          type: DesignEffectType.innerGlow,
          color: Color(0x6660A5FA),
          blurRadius: 12,
        );
        break;
      case DesignEffectType.bloom:
        newEff = const DesignEffect(
          type: DesignEffectType.bloom,
          blurRadius: 14,
        );
        break;
      case DesignEffectType.grayscale:
        newEff = const DesignEffect(type: DesignEffectType.grayscale);
        break;
      case DesignEffectType.sepia:
        newEff = const DesignEffect(type: DesignEffectType.sepia);
        break;
      case DesignEffectType.invertColors:
        newEff = const DesignEffect(type: DesignEffectType.invertColors);
        break;
      default:
        newEff = const DesignEffect(type: DesignEffectType.dropShadow);
    }
    controller.updateNode(node.copyWith(effects: [...node.effects, newEff]));
  }

  String _getEffectLabel(DesignEffectType type) {
    switch (type) {
      case DesignEffectType.dropShadow:
        return 'DROP SHADOW';
      case DesignEffectType.innerShadow:
        return 'INNER SHADOW';
      case DesignEffectType.blur:
        return 'LAYER BLUR';
      case DesignEffectType.backgroundBlur:
        return 'BACKDROP BLUR';
      case DesignEffectType.outerGlow:
        return 'OUTER GLOW';
      case DesignEffectType.innerGlow:
        return 'INNER GLOW';
      case DesignEffectType.bloom:
        return 'BLOOM';
      case DesignEffectType.grayscale:
        return 'GRAYSCALE';
      case DesignEffectType.sepia:
        return 'SEPIA';
      case DesignEffectType.invertColors:
        return 'INVERT COLORS';
      default:
        return 'EFFECT';
    }
  }

  Widget _buildVectorPathSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    return PropertySectionCard(
      title: 'VECTOR PATH CONTROLS',
      icon: Icons.polyline_rounded,
      tokens: tokens,
      isDark: isDark,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.edit_road_rounded, size: 16),
          label: const Text(
            'Edit Vector Anchor Points',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
          ),
          onPressed: () => controller.enterVectorEditMode(node.id),
        ),
      ),
    );
  }

  Widget _buildExportSection(
    BuildContext context,
    DesignNode node,
    EditorState state,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    return PropertySectionCard(
      title: 'EXPORT',
      icon: Icons.file_download_outlined,
      tokens: tokens,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format Selector Segmented Pills
          Row(
            children: ['PNG', 'JPG', 'SVG', 'PDF', 'FIG'].map((fmt) {
              final isSel = _selectedExportFormat == fmt;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => setState(() => _selectedExportFormat = fmt),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSel
                            ? tokens.accent.withValues(alpha: isDark ? 0.25 : 0.14)
                            : tokens.wellBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel ? tokens.accent : tokens.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        fmt,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          color: isSel ? tokens.accent : tokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Scale Selector Segmented Pills
          Row(
            children: ['0.5x', '1x', '2x', '3x'].map((scale) {
              final isSel = _selectedExportScale == scale;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => setState(() => _selectedExportScale = scale),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSel
                            ? tokens.accent.withValues(alpha: isDark ? 0.25 : 0.14)
                            : tokens.wellBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel ? tokens.accent : tokens.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        scale,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          color: isSel ? tokens.accent : tokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Primary Export Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.file_download_outlined, size: 15),
              label: Text(
                'Export ${node.name} ($_selectedExportScale $_selectedExportFormat)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ExportDialog(
                    project: state.project,
                    activePageId: state.activePageId,
                    selectedNodeId: node.id,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageSettings(
    BuildContext context,
    EditorState state,
    EditorController controller,
    AppSettings settings,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    final page = state.project.getPage(state.activePageId);
    if (page == null) return const SizedBox.shrink();

    return Column(
      children: [
        PropertySectionCard(
          title: 'CANVAS SETTINGS',
          icon: Icons.palette_outlined,
          tokens: tokens,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.textMain,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ColorPickerDialog.show(
                        context,
                        initialColor: page.backgroundColor,
                        onColorChanged: (c) => controller.setPageBackgroundColor(c),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: page.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.borderSubtle, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick palette swatches
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF8FAFC),
                  const Color(0xFFF1F5F9),
                  const Color(0xFFE2E8F0),
                  const Color(0xFF0F172A),
                  const Color(0xFF1E293B),
                  const Color(0xFF000000),
                  const Color(0xFFFEF3C7),
                  const Color(0xFFEFF6FF),
                  const Color(0xFFFDF2F8),
                ].map((c) {
                  final isSelected = page.backgroundColor.toARGB32() == c.toARGB32();
                  return GestureDetector(
                    onTap: () => controller.setPageBackgroundColor(c),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? tokens.accent : Colors.black26,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Grid & Snapping Card
        PropertySectionCard(
          title: 'GRID & SNAPPING',
          icon: Icons.grid_4x4_rounded,
          tokens: tokens,
          isDark: isDark,
          child: Column(
            children: [
              _buildSwitchRow(
                label: 'Show Grid',
                value: settings.showGrid,
                tokens: tokens,
                onChanged: (val) => ref.read(settingsProvider.notifier).toggleShowGrid(val),
              ),
              const SizedBox(height: 6),
              _buildSwitchRow(
                label: 'Snap to Objects',
                value: settings.snapToObjects,
                tokens: tokens,
                onChanged: (val) => ref.read(settingsProvider.notifier).toggleSnapToObjects(val),
              ),
              const SizedBox(height: 6),
              _buildSwitchRow(
                label: 'Snap to Grid',
                value: settings.snapToGrid,
                tokens: tokens,
                onChanged: (val) => ref.read(settingsProvider.notifier).toggleSnapToGrid(val),
              ),
            ],
          ),
        ),

        // Canvas Export Card
        PropertySectionCard(
          title: 'EXPORT CANVAS',
          icon: Icons.file_download_outlined,
          tokens: tokens,
          isDark: isDark,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.file_download_outlined, size: 15),
              label: const Text('Export Current Canvas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ExportDialog(
                    project: state.project,
                    activePageId: state.activePageId,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required FormaThemeTokens tokens,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: tokens.textMain,
            ),
          ),
        ),
        Transform.scale(
          scale: 0.75,
          child: Switch(
            value: value,
            activeThumbColor: tokens.accent,
            activeTrackColor: tokens.accent.withValues(alpha: 0.3),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMicroIconButton({
    required IconData icon,
    required String tooltip,
    required FormaThemeTokens tokens,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(icon, size: 15, color: tokens.textMain),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniHeaderButton({
    required IconData icon,
    required String tooltip,
    required FormaThemeTokens tokens,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: tokens.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(icon, size: 14, color: tokens.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required String label,
    required IconData icon,
    required FormaThemeTokens tokens,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: tokens.wellBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSubtle, width: 1.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: tokens.textMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textMain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedConstraintPill<T>({
    required T currentValue,
    required List<T> values,
    required String Function(T) labelBuilder,
    required FormaThemeTokens tokens,
    required ValueChanged<T> onSelected,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.wellBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSubtle, width: 1.0),
      ),
      child: Row(
        children: values.map((val) {
          final isSelected = val == currentValue;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(val),
              borderRadius: BorderRadius.circular(5),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? tokens.accent.withValues(alpha: tokens.isDark ? 0.25 : 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  labelBuilder(val),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? tokens.accent : tokens.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickImageFill(
    BuildContext context,
    DesignNode node,
    int? fillIndex,
    EditorController controller,
  ) async {
    try {
      final res = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (res != null) {
        final bytes = await res.readAsBytes();
        final base64Str = base64Encode(bytes);
        final newFill = DesignFill.image(imageBase64: base64Str);
        final updatedFills = List<DesignFill>.from(node.fills);
        if (fillIndex != null && fillIndex < updatedFills.length) {
          updatedFills[fillIndex] = newFill;
        } else {
          updatedFills.add(newFill);
        }
        controller.updateNode(node.copyWith(fills: updatedFills));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }
}

/// Un-cramped, refined card section wrapper with clean 1px hairline border and comfortable padding
class PropertySectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final FormaThemeTokens tokens;
  final bool isDark;
  final EdgeInsetsGeometry padding;

  const PropertySectionCard({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    required this.child,
    required this.tokens,
    required this.isDark,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.borderSubtle,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: tokens.accent),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: tokens.textMuted,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    flex: 0,
                    child: trailing!,
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: tokens.borderSubtle),
          // Content with comfortable padding
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

class TypographyPropertySection extends StatefulWidget {
  final DesignNode node;
  final EditorController controller;
  final FormaThemeTokens tokens;
  final bool isDark;

  const TypographyPropertySection({
    super.key,
    required this.node,
    required this.controller,
    required this.tokens,
    required this.isDark,
  });

  @override
  State<TypographyPropertySection> createState() => _TypographyPropertySectionState();
}

class _TypographyPropertySectionState extends State<TypographyPropertySection> {
  late TextEditingController _textCtrl;
  final FocusNode _focusNode = FocusNode();

  static const List<int> _fontWeights = [
    300,
    400,
    500,
    600,
    700,
    800,
  ];

  static const List<double> _quickSizes = [
    12, 14, 16, 20, 24, 32, 48, 64
  ];

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.node.textData?.text ?? '');
  }

  @override
  void didUpdateWidget(covariant TypographyPropertySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id ||
        (widget.node.textData?.text != _textCtrl.text && !_focusNode.hasFocus)) {
      _textCtrl.text = widget.node.textData?.text ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _update(TextNodeData updated) {
    final measured = NodeRenderService.measureText(updated);
    widget.controller.updateNode(
      widget.node.copyWith(
        textData: updated,
        width: math.max(widget.node.width, measured.width + 8.0),
        height: math.max(widget.node.height, measured.height + 4.0),
      ),
    );
  }

  void _showFontPickerModal(BuildContext context, TextNodeData t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return _FontPickerSheet(
          initialFont: t.fontFamily,
          isDark: widget.isDark,
          tokens: widget.tokens,
          onFontSelected: (newFont) {
            _update(t.copyWith(fontFamily: newFont));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.node.textData ?? const TextNodeData();
    final tokens = widget.tokens;
    final isDark = widget.isDark;

    TextStyle activeFontStyle;
    try {
      activeFontStyle = GoogleFonts.getFont(t.fontFamily, fontSize: 13, fontWeight: FontWeight.w600);
    } catch (_) {
      activeFontStyle = TextStyle(fontFamily: t.fontFamily, fontSize: 13, fontWeight: FontWeight.w600);
    }

    return PropertySectionCard(
      title: 'TYPOGRAPHY',
      icon: Icons.title_rounded,
      tokens: tokens,
      isDark: isDark,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => CanvasViewport.showInPlaceTextEditor(context, widget.node, widget.controller),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_full_rounded, size: 11, color: tokens.accent),
                  const SizedBox(width: 3),
                  Text(
                    'Edit',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tokens.accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _showFontPickerModal(context, t),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.font_download_rounded, size: 12, color: tokens.accent),
                  const SizedBox(width: 3),
                  Text(
                    'Fonts',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tokens.accent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Content Input
          TextField(
            controller: _textCtrl,
            focusNode: _focusNode,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(
              fontSize: 12,
              color: tokens.textMain,
            ),
            decoration: InputDecoration(
              hintText: 'Enter text content...',
              hintStyle: TextStyle(fontSize: 11, color: tokens.textMuted),
              filled: true,
              fillColor: tokens.wellBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: tokens.accent, width: 1.5),
              ),
            ),
            onChanged: (val) => _update(t.copyWith(text: val)),
          ),
          const SizedBox(height: 8),

          // Font Family Selector Tile
          InkWell(
            onTap: () => _showFontPickerModal(context, t),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.wellBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle, width: 1.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.text_fields_rounded, size: 16, color: tokens.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FONT FAMILY',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: tokens.textMuted,
                          ),
                        ),
                        Text(
                          t.fontFamily,
                          style: activeFontStyle.copyWith(
                            color: tokens.textMain,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded, size: 16, color: tokens.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Font Size Scrubber and Quick Presets
          Row(
            children: [
              Expanded(
                child: FormaTouchNudgeField(
                  label: 'Size',
                  value: t.fontSize,
                  min: 4,
                  max: 500,
                  step: 1,
                  onChanged: (val) => _update(t.copyWith(fontSize: val)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Quick size pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickSizes.map((sz) {
                final isSel = (t.fontSize - sz).abs() < 0.5;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: () => _update(t.copyWith(fontSize: sz)),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSel ? tokens.accent.withValues(alpha: 0.18) : tokens.wellBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel ? tokens.accent : tokens.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        '${sz.toInt()}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? tokens.accent : tokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Font Weight Segmented Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _fontWeights.map((w) {
                final isSel = t.fontWeight == w;
                String label = '$w';
                if (w == 300) label = 'Light';
                if (w == 400) label = 'Regular';
                if (w == 500) label = 'Medium';
                if (w == 600) label = 'SemiBold';
                if (w == 700) label = 'Bold';
                if (w == 800) label = 'ExtraBold';

                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: InkWell(
                    onTap: () => _update(t.copyWith(fontWeight: w)),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSel ? tokens.accent.withValues(alpha: 0.20) : tokens.wellBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSel ? tokens.accent : tokens.borderSubtle,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? tokens.accent : tokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Alignment & Style Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Alignment Pills
              Container(
                decoration: BoxDecoration(
                  color: tokens.wellBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderSubtle, width: 1.0),
                ),
                child: Row(
                  children: [
                    _buildTextIconButton(
                      icon: Icons.format_align_left_rounded,
                      isSelected: t.textAlign == TextAlign.left,
                      tokens: tokens,
                      onTap: () => _update(t.copyWith(textAlign: TextAlign.left)),
                    ),
                    _buildTextIconButton(
                      icon: Icons.format_align_center_rounded,
                      isSelected: t.textAlign == TextAlign.center,
                      tokens: tokens,
                      onTap: () => _update(t.copyWith(textAlign: TextAlign.center)),
                    ),
                    _buildTextIconButton(
                      icon: Icons.format_align_right_rounded,
                      isSelected: t.textAlign == TextAlign.right,
                      tokens: tokens,
                      onTap: () => _update(t.copyWith(textAlign: TextAlign.right)),
                    ),
                  ],
                ),
              ),

              // Style Pills (Italic, Underline, Strikethrough)
              Container(
                decoration: BoxDecoration(
                  color: tokens.wellBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderSubtle, width: 1.0),
                ),
                child: Row(
                  children: [
                    _buildTextIconButton(
                      icon: Icons.format_italic_rounded,
                      isSelected: t.isItalic,
                      tokens: tokens,
                      onTap: () => _update(t.copyWith(isItalic: !t.isItalic)),
                    ),
                    _buildTextIconButton(
                      icon: Icons.format_underlined_rounded,
                      isSelected: t.underline,
                      tokens: tokens,
                      onTap: () => _update(t.copyWith(underline: !t.underline)),
                    ),
                    _buildTextIconButton(
                      icon: Icons.format_strikethrough_rounded,
                      isSelected: t.strikethrough,
                      tokens: tokens,
                      onTap: () => _update(t.copyWith(strikethrough: !t.strikethrough)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Auto Width vs Fixed Width Toggle Pill
          InkWell(
            onTap: () => _update(t.copyWith(isAutoWidth: !t.isAutoWidth)),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: tokens.wellBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle, width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    t.isAutoWidth ? Icons.fit_screen_rounded : Icons.crop_free_rounded,
                    size: 13,
                    color: tokens.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t.isAutoWidth ? 'Auto-Fit Content Width' : 'Fixed Bounding Box Width',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: tokens.textMain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextIconButton({
    required IconData icon,
    required bool isSelected,
    required FormaThemeTokens tokens,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? tokens.accent.withValues(alpha: 0.20) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 14,
            color: isSelected ? tokens.accent : tokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class _FontPickerSheet extends StatefulWidget {
  final String initialFont;
  final bool isDark;
  final FormaThemeTokens tokens;
  final ValueChanged<String> onFontSelected;

  const _FontPickerSheet({
    required this.initialFont,
    required this.isDark,
    required this.tokens,
    required this.onFontSelected,
  });

  @override
  State<_FontPickerSheet> createState() => _FontPickerSheetState();
}

class _FontPickerSheetState extends State<_FontPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _customCtrl = TextEditingController();
  String _selectedCategory = 'All';

  static const Map<String, List<String>> _fontCategories = {
    'All': [
      'Plus Jakarta Sans', 'Inter', 'Roboto', 'Poppins', 'Montserrat', 'Lato',
      'Open Sans', 'Raleway', 'Ubuntu', 'Nunito', 'Rubik', 'Work Sans',
      'Playfair Display', 'Merriweather', 'Lora', 'Cinzel', 'PT Serif', 'Baskervville',
      'Bebas Neue', 'Oswald', 'Righteous', 'Orbitron', 'Abril Fatface', 'Anton', 'Syne',
      'Fira Code', 'JetBrains Mono', 'Roboto Mono', 'Source Code Pro', 'Space Mono',
      'Dancing Script', 'Pacifico', 'Caveat', 'Satisfy', 'Great Vibes'
    ],
    'Sans': [
      'Plus Jakarta Sans', 'Inter', 'Roboto', 'Poppins', 'Montserrat', 'Lato',
      'Open Sans', 'Raleway', 'Ubuntu', 'Nunito', 'Rubik', 'Work Sans'
    ],
    'Serif': [
      'Playfair Display', 'Merriweather', 'Lora', 'Cinzel', 'PT Serif', 'Baskervville'
    ],
    'Display': [
      'Bebas Neue', 'Oswald', 'Righteous', 'Orbitron', 'Abril Fatface', 'Anton', 'Syne'
    ],
    'Mono': [
      'Fira Code', 'JetBrains Mono', 'Roboto Mono', 'Source Code Pro', 'Space Mono'
    ],
    'Script': [
      'Dancing Script', 'Pacifico', 'Caveat', 'Satisfy', 'Great Vibes'
    ],
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final allFonts = _fontCategories[_selectedCategory] ?? _fontCategories['All']!;
    final query = _searchCtrl.text.toLowerCase().trim();
    final filteredFonts = allFonts.where((f) => f.toLowerCase().contains(query)).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.borderSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.font_download_rounded, color: tokens.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Typography Library',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: tokens.textMain,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, size: 14),
                      label: const Text('Import Font', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        try {
                          final result = await FilePicker.pickFile(
                            type: FileType.custom,
                            allowedExtensions: ['ttf', 'otf'],
                          );
                          if (result != null) {
                            final bytes = await result.readAsBytes();
                            final fontName = result.name.replaceAll('.ttf', '').replaceAll('.otf', '').trim();
                            final loaded = await CustomFontService.loadFontFromBytes(
                              familyName: fontName,
                              fontBytes: bytes,
                            );
                            if (loaded && mounted) {
                              widget.onFontSelected(fontName);
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          }
                        } catch (_) {}
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Custom Google Font input row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.wellBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customCtrl,
                      style: TextStyle(fontSize: 12, color: tokens.textMain),
                      decoration: InputDecoration(
                        hintText: 'Type any Google Font name...',
                        hintStyle: TextStyle(fontSize: 11, color: tokens.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final val = _customCtrl.text.trim();
                      if (val.isNotEmpty) {
                        widget.onFontSelected(val);
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: tokens.accent)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Search Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: tokens.wellBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 12, color: tokens.textMain),
                decoration: InputDecoration(
                  hintText: 'Filter fonts by name...',
                  hintStyle: TextStyle(fontSize: 11, color: tokens.textMuted),
                  prefixIcon: Icon(Icons.search_rounded, size: 16, color: tokens.textMuted),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _fontCategories.keys.map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: tokens.accent.withValues(alpha: 0.18),
                    checkmarkColor: tokens.accent,
                    backgroundColor: tokens.wellBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSel ? tokens.accent : tokens.borderSubtle,
                      ),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? tokens.accent : tokens.textMuted,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Font List View with Live Preview
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredFonts.length,
              separatorBuilder: (_, index) => const SizedBox(height: 6),
              itemBuilder: (ctx, index) {
                final font = filteredFonts[index];
                final isSelected = widget.initialFont.toLowerCase() == font.toLowerCase();

                TextStyle fontStyle;
                try {
                  fontStyle = GoogleFonts.getFont(font, fontSize: 15, fontWeight: FontWeight.w600);
                } catch (_) {
                  fontStyle = TextStyle(fontFamily: font, fontSize: 15, fontWeight: FontWeight.w600);
                }

                return InkWell(
                  onTap: () {
                    widget.onFontSelected(font);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tokens.accent.withValues(alpha: 0.12)
                          : tokens.wellBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? tokens.accent : tokens.borderSubtle,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                font,
                                style: fontStyle.copyWith(
                                  color: tokens.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'The quick brown fox jumps over the lazy dog',
                                style: fontStyle.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.normal,
                                  color: tokens.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: tokens.accent, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
