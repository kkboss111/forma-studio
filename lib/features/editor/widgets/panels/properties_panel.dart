import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../domain/models/project_model.dart';
import '../../../../domain/models/node_model.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../domain/models/paint_styles.dart';
import '../../../../domain/models/layout_config.dart';
import '../../../../domain/models/constraints.dart';
import '../../../../domain/models/text_data.dart';
import '../../../../domain/services/node_render_service.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/neumorphic.dart';
import '../../../../app/theme/touch_controls.dart';
import '../../../settings/models/app_settings.dart';
import '../../controllers/editor_controller.dart';
import '../dialogs/color_picker_dialog.dart';
import '../dialogs/image_editor_dialog.dart';

class PropertiesPanel extends ConsumerWidget {
  final ProjectModel project;
  final double? width;

  const PropertiesPanel({super.key, required this.project, this.width = 280});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorControllerProvider(project));
    final controller = ref.read(editorControllerProvider(project).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedIds = state.selectedNodeIds;
    final primaryNode = selectedIds.isNotEmpty
        ? state.project.nodes[selectedIds.first]
        : null;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        border: Border(
          left: BorderSide(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          if (primaryNode == null) ...[
            // Page Settings
            _buildPageSettings(context, state, controller, isDark, ref),
          ] else ...[
            // Alignment Bar
            _buildAlignmentBar(controller, isDark),
            const SizedBox(height: 14),

            // Geometry Section (X, Y, W, H, Rotation)
            _buildGeometrySection(context, primaryNode, controller, isDark),
            const Divider(height: 24),

            // Constraints Section
            _buildConstraintsSection(context, primaryNode, controller, isDark),
            const Divider(height: 24),

            // Auto-Layout Section (Frames/Containers)
            if (primaryNode.type == NodeType.frame ||
                primaryNode.type == NodeType.annotationSection) ...[
              _buildAutoLayoutSection(context, primaryNode, controller, isDark),
              const Divider(height: 24),
            ],

            // Typography Section (If Text Node)
            if (primaryNode.type == NodeType.text &&
                primaryNode.textData != null) ...[
              TypographyPropertySection(
                node: primaryNode,
                controller: controller,
                isDark: isDark,
              ),
              const Divider(height: 24),
            ],

            // Fills Section
            _buildFillsSection(context, primaryNode, controller, isDark),
            const Divider(height: 24),

            // Strokes Section
            _buildStrokesSection(context, primaryNode, controller, isDark),
            const Divider(height: 24),

            // Effects Section
            _buildEffectsSection(context, primaryNode, controller, isDark),
            const Divider(height: 24),

            // WCAG Contrast Badge
            _buildContrastChecker(context, primaryNode, state, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildPageSettings(
    BuildContext context,
    dynamic state,
    EditorController controller,
    bool isDark,
    WidgetRef ref,
  ) {
    final page = state.project.getPage(state.activePageId);
    if (page == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CANVAS SETTINGS', isDark),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Background',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? FormaColors.darkTextMain
                    : FormaColors.lightTextMain,
              ),
            ),
            GestureDetector(
              onTap: () {
                ColorPickerDialog.show(
                  context,
                  initialColor: page.backgroundColor,
                  onColorChanged: (c) {
                    final updatedPage = page.copyWith(backgroundColor: c);
                    final pages = state.project.pages
                        .map((p) => p.id == page.id ? updatedPage : p)
                        .toList();
                    controller.updatePages(pages);
                  },
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: page.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Show Grid',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? FormaColors.darkTextMain
                    : FormaColors.lightTextMain,
              ),
            ),
            Switch(
              value: page.showGrid,
              activeThumbColor: FormaColors.primaryBlue,
              onChanged: (val) {
                controller.setPageShowGrid(val);
                ref.read(settingsProvider.notifier).toggleShowGrid(val);
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Snap to Grid',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? FormaColors.darkTextMain
                    : FormaColors.lightTextMain,
              ),
            ),
            Switch(
              value: page.snapToGrid,
              activeThumbColor: FormaColors.primaryBlue,
              onChanged: (val) {
                controller.setPageSnapToGrid(val);
                ref.read(settingsProvider.notifier).toggleSnapToGrid(val);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignmentBar(EditorController controller, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NeuIconButton(
          icon: Icons.align_horizontal_left_rounded,
          size: 32,
          iconSize: 16,
          tooltip: 'Align Left',
          onPressed: () => controller.alignSelection('left'),
        ),
        NeuIconButton(
          icon: Icons.align_horizontal_center_rounded,
          size: 32,
          iconSize: 16,
          tooltip: 'Align Center Horizontal',
          onPressed: () => controller.alignSelection('centerHorizontal'),
        ),
        NeuIconButton(
          icon: Icons.align_horizontal_right_rounded,
          size: 32,
          iconSize: 16,
          tooltip: 'Align Right',
          onPressed: () => controller.alignSelection('right'),
        ),
        NeuIconButton(
          icon: Icons.align_vertical_top_rounded,
          size: 32,
          iconSize: 16,
          tooltip: 'Align Top',
          onPressed: () => controller.alignSelection('top'),
        ),
        NeuIconButton(
          icon: Icons.align_vertical_center_rounded,
          size: 32,
          iconSize: 16,
          tooltip: 'Align Center Vertical',
          onPressed: () => controller.alignSelection('centerVertical'),
        ),
        NeuIconButton(
          icon: Icons.align_vertical_bottom_rounded,
          size: 32,
          iconSize: 16,
          tooltip: 'Align Bottom',
          onPressed: () => controller.alignSelection('bottom'),
        ),
      ],
    );
  }

  Widget _buildGeometrySection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('GEOMETRY', isDark),
        const SizedBox(height: 10),
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
        Row(
          children: [
            Expanded(
              child: FormaTouchNudgeField(
                label: 'W',
                value: node.width,
                min: 1,
                onChanged: (val) => controller.updateNode(
                  node.copyWith(width: math.max(1, val)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FormaTouchNudgeField(
                label: 'H',
                value: node.height,
                min: 1,
                onChanged: (val) => controller.updateNode(
                  node.copyWith(height: math.max(1, val)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FormaTouchNudgeField(
                label: 'R°',
                value: node.rotation,
                onChanged: (val) =>
                    controller.updateNode(node.copyWith(rotation: val)),
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
        const SizedBox(height: 12),
        // Touch-first Opacity slider
        FormaTouchSlider(
          label: 'OPACITY',
          value: (node.opacity * 100.0).roundToDouble(),
          min: 0,
          max: 100,
          step: 5,
          unit: '%',
          onChanged: (val) {
            controller.updateNode(
              node.copyWith(opacity: (val / 100.0).clamp(0.0, 1.0)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConstraintsSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('CONSTRAINTS', isDark),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Horizontal',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? FormaColors.darkTextMuted
                    : FormaColors.lightTextMuted,
              ),
            ),
            DropdownButton<HorizontalConstraint>(
              value: node.constraints.horizontal,
              isDense: true,
              underline: const SizedBox.shrink(),
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? FormaColors.darkTextMain
                    : FormaColors.lightTextMain,
              ),
              items: HorizontalConstraint.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  controller.updateNode(
                    node.copyWith(
                      constraints: node.constraints.copyWith(horizontal: val),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vertical',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? FormaColors.darkTextMuted
                    : FormaColors.lightTextMuted,
              ),
            ),
            DropdownButton<VerticalConstraint>(
              value: node.constraints.vertical,
              isDense: true,
              underline: const SizedBox.shrink(),
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? FormaColors.darkTextMain
                    : FormaColors.lightTextMain,
              ),
              items: VerticalConstraint.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  controller.updateNode(
                    node.copyWith(
                      constraints: node.constraints.copyWith(vertical: val),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutoLayoutSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    bool isDark,
  ) {
    final cfg = node.layoutConfig;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('AUTO-LAYOUT', isDark),
            Switch(
              value: cfg.enabled,
              activeThumbColor: FormaColors.primaryBlue,
              onChanged: (val) {
                controller.updateNode(
                  node.copyWith(layoutConfig: cfg.copyWith(enabled: val)),
                );
              },
            ),
          ],
        ),
        if (cfg.enabled) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: NeuButton(
                  isActive: cfg.direction == AutoLayoutDirection.horizontal,
                  onPressed: () {
                    controller.updateNode(
                      node.copyWith(
                        layoutConfig: cfg.copyWith(
                          direction: AutoLayoutDirection.horizontal,
                        ),
                      ),
                    );
                  },
                  child: const Text('Row', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeuButton(
                  isActive: cfg.direction == AutoLayoutDirection.vertical,
                  onPressed: () {
                    controller.updateNode(
                      node.copyWith(
                        layoutConfig: cfg.copyWith(
                          direction: AutoLayoutDirection.vertical,
                        ),
                      ),
                    );
                  },
                  child: const Text('Column', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNumberInput('Gap', cfg.gap, (val) {
                  controller.updateNode(
                    node.copyWith(layoutConfig: cfg.copyWith(gap: val)),
                  );
                }, isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumberInput('Pad', cfg.paddingLeft, (val) {
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
                }, isDark),
              ),
            ],
          ),
        ],
      ],
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

  Widget _buildFillsSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('FILLS', isDark),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined, size: 16),
                  tooltip: 'Add Image Fill (Masked)',
                  splashRadius: 14,
                  onPressed: () => _pickImageFill(context, node, null, controller),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  tooltip: 'Add Color / Gradient Fill',
                  splashRadius: 14,
                  onPressed: () {
                    controller.updateNode(
                      node.copyWith(
                        fills: [
                          ...node.fills,
                          const DesignFill.solid(Color(0xFF2B3445)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        ...node.fills.asMap().entries.map((entry) {
          final i = entry.key;
          final fill = entry.value;

          String typeBadge = 'SOLID';
          if (fill.type == DesignFillType.linearGradient) typeBadge = 'LINEAR';
          if (fill.type == DesignFillType.radialGradient) typeBadge = 'RADIAL';
          if (fill.type == DesignFillType.angularGradient) typeBadge = 'ANGULAR';
          if (fill.type == DesignFillType.image) typeBadge = 'IMAGE';

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (fill.type == DesignFillType.image) {
                      final existingImg = fill.imageBase64 ?? fill.imagePath;
                      if (existingImg != null && existingImg.isNotEmpty) {
                        ImageEditorDialog.show(
                          context,
                          initialImageBase64: existingImg,
                          onApply: (newB64) {
                            final updatedFills = List<DesignFill>.from(node.fills);
                            updatedFills[i] = fill.copyWith(
                              imageBase64: newB64,
                              imagePath: newB64,
                            );
                            controller.updateNode(node.copyWith(fills: updatedFills));
                          },
                        );
                      } else {
                        _pickImageFill(context, node, i, controller);
                      }
                    } else {
                      ColorPickerDialog.show(
                        context,
                        initialColor: fill.color,
                        initialFill: fill,
                        onColorChanged: (c) {
                          final updatedFills = List<DesignFill>.from(node.fills);
                          updatedFills[i] = fill.copyWith(color: c);
                          controller.updateNode(node.copyWith(fills: updatedFills));
                        },
                        onFillChanged: (newFill) {
                          final updatedFills = List<DesignFill>.from(node.fills);
                          updatedFills[i] = newFill;
                          controller.updateNode(node.copyWith(fills: updatedFills));
                        },
                      );
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: fill.type == DesignFillType.image
                          ? Colors.blueGrey
                          : fill.color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: fill.type == DesignFillType.image
                        ? const Icon(Icons.image, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: FormaColors.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeBadge,
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: FormaColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fill.type == DesignFillType.image
                        ? 'Image Fill'
                        : _colorToHex(fill.color),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? FormaColors.darkTextMain
                          : FormaColors.lightTextMain,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    fill.isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 14,
                  ),
                  splashRadius: 12,
                  onPressed: () {
                    final updatedFills = List<DesignFill>.from(node.fills);
                    updatedFills[i] = fill.copyWith(isVisible: !fill.isVisible);
                    controller.updateNode(node.copyWith(fills: updatedFills));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 14),
                  splashRadius: 12,
                  onPressed: () {
                    final updatedFills = List<DesignFill>.from(node.fills)
                      ..removeAt(i);
                    controller.updateNode(node.copyWith(fills: updatedFills));
                  },
                ),
              ],
            ),
          );
        }),
        if (node.type == NodeType.image || node.fills.any((f) => f.type == DesignFillType.image))
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.crop_rotate_rounded, size: 14),
                label: const Text('Edit / Crop Image', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final fillImg = node.fills.where((f) => f.type == DesignFillType.image).firstOrNull;
                  final imgData = fillImg?.imageBase64 ?? fillImg?.imagePath ?? node.imagePath;
                  ImageEditorDialog.show(
                    context,
                    initialImageBase64: imgData,
                    onApply: (newB64) {
                      if (fillImg != null) {
                        final idx = node.fills.indexOf(fillImg);
                        final updated = List<DesignFill>.from(node.fills);
                        updated[idx] = fillImg.copyWith(imageBase64: newB64, imagePath: newB64);
                        controller.updateNode(node.copyWith(fills: updated, imagePath: newB64));
                      } else {
                        controller.updateNode(node.copyWith(imagePath: newB64));
                      }
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStrokesSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('STROKES', isDark),
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 16),
              splashRadius: 14,
              onPressed: () {
                controller.updateNode(
                  node.copyWith(
                    strokes: [
                      ...node.strokes,
                      const DesignStroke(color: Color(0xFFC8D3E2), width: 1.0),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        ...node.strokes.asMap().entries.map((entry) {
          final i = entry.key;
          final stroke = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    ColorPickerDialog.show(
                      context,
                      initialColor: stroke.color,
                      initialFill: stroke.hasGradient
                          ? DesignFill.linear(
                              colors: stroke.gradientColors!,
                              stops: stroke.gradientStops,
                              angle: stroke.gradientAngle,
                            )
                          : DesignFill.solid(stroke.color),
                      onColorChanged: (c) {
                        final updated = List<DesignStroke>.from(node.strokes);
                        updated[i] = stroke.copyWith(color: c, clearGradient: true);
                        controller.updateNode(
                          node.copyWith(strokes: updated),
                        );
                      },
                      onFillChanged: (fill) {
                        final updated = List<DesignStroke>.from(node.strokes);
                        if (fill.type == DesignFillType.solid) {
                          updated[i] = stroke.copyWith(color: fill.color, clearGradient: true);
                        } else if (fill.gradientColors != null && fill.gradientColors!.length >= 2) {
                          updated[i] = stroke.copyWith(
                            gradientColors: fill.gradientColors,
                            gradientStops: fill.gradientStops,
                            gradientAngle: fill.gradientAngle,
                          );
                        }
                        controller.updateNode(
                          node.copyWith(strokes: updated),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: stroke.hasGradient ? null : stroke.color,
                      gradient: stroke.hasGradient
                          ? LinearGradient(colors: stroke.gradientColors!)
                          : null,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 14),
                  splashRadius: 12,
                  onPressed: () {
                    final updated = List<DesignStroke>.from(node.strokes)
                      ..removeAt(i);
                    controller.updateNode(node.copyWith(strokes: updated));
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEffectsSection(
    BuildContext context,
    DesignNode node,
    EditorController controller,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('EFFECTS', isDark),
            PopupMenuButton<DesignEffectType>(
              icon: const Icon(Icons.add_rounded, size: 16),
              tooltip: 'Add Effect',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (type) {
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
                  case DesignEffectType.colorTint:
                    newEff = const DesignEffect(
                      type: DesignEffectType.colorTint,
                      color: Color(0x443B82F6),
                    );
                    break;
                  case DesignEffectType.vignette:
                    newEff = const DesignEffect(
                      type: DesignEffectType.vignette,
                      color: Color(0x99000000),
                      blurRadius: 20,
                    );
                    break;
                  case DesignEffectType.bloom:
                    newEff = const DesignEffect(
                      type: DesignEffectType.bloom,
                      blurRadius: 14,
                    );
                    break;
                  case DesignEffectType.grayscale:
                    newEff = const DesignEffect(
                      type: DesignEffectType.grayscale,
                    );
                    break;
                  case DesignEffectType.sepia:
                    newEff = const DesignEffect(
                      type: DesignEffectType.sepia,
                    );
                    break;
                  case DesignEffectType.invertColors:
                    newEff = const DesignEffect(
                      type: DesignEffectType.invertColors,
                    );
                    break;
                }
                controller.updateNode(
                  node.copyWith(effects: [...node.effects, newEff]),
                );
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: DesignEffectType.dropShadow,
                  child: Text('Drop Shadow'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.innerShadow,
                  child: Text('Inner Shadow'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.blur,
                  child: Text('Layer Blur'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.backgroundBlur,
                  child: Text('Background Blur'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.outerGlow,
                  child: Text('Outer Glow'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.innerGlow,
                  child: Text('Inner Glow'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.colorTint,
                  child: Text('Color Tint'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.vignette,
                  child: Text('Vignette'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.bloom,
                  child: Text('Bloom / Soft Light'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.grayscale,
                  child: Text('Grayscale Filter'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.sepia,
                  child: Text('Sepia Tone'),
                ),
                const PopupMenuItem(
                  value: DesignEffectType.invertColors,
                  child: Text('Invert Colors'),
                ),
              ],
            ),
          ],
        ),
        ...node.effects.asMap().entries.map((entry) {
          final i = entry.key;
          final eff = entry.value;

          String label = 'DROP SHADOW';
          if (eff.type == DesignEffectType.innerShadow) label = 'INNER SHADOW';
          if (eff.type == DesignEffectType.blur) label = 'LAYER BLUR';
          if (eff.type == DesignEffectType.backgroundBlur) label = 'BACKDROP BLUR';
          if (eff.type == DesignEffectType.outerGlow) label = 'OUTER GLOW';
          if (eff.type == DesignEffectType.innerGlow) label = 'INNER GLOW';
          if (eff.type == DesignEffectType.colorTint) label = 'COLOR TINT';
          if (eff.type == DesignEffectType.vignette) label = 'VIGNETTE';
          if (eff.type == DesignEffectType.bloom) label = 'BLOOM';
          if (eff.type == DesignEffectType.grayscale) label = 'GRAYSCALE';
          if (eff.type == DesignEffectType.sepia) label = 'SEPIA';
          if (eff.type == DesignEffectType.invertColors) label = 'INVERT COLORS';

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.blur_on_rounded, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? FormaColors.darkTextMain
                              : FormaColors.lightTextMain,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 14),
                      splashRadius: 12,
                      onPressed: () {
                        final updated = List<DesignEffect>.from(node.effects)
                          ..removeAt(i);
                        controller.updateNode(node.copyWith(effects: updated));
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: FormaTouchNudgeField(
                          label: 'BLUR',
                          value: eff.blurRadius,
                          min: 0,
                          onChanged: (v) {
                            final updated = List<DesignEffect>.from(node.effects);
                            updated[i] = eff.copyWith(blurRadius: v);
                            controller.updateNode(node.copyWith(effects: updated));
                          },
                        ),
                      ),
                      if (eff.type == DesignEffectType.dropShadow ||
                          eff.type == DesignEffectType.innerShadow) ...[
                        const SizedBox(width: 8),
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
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildContrastChecker(
    BuildContext context,
    DesignNode node,
    dynamic state,
    bool isDark,
  ) {
    final page = state.project.getPage(state.activePageId);
    final bgColor = page?.backgroundColor ?? Colors.white;
    final fgColor = node.fills.isNotEmpty
        ? node.fills.first.color
        : Colors.black;

    final ratio = _calculateContrastRatio(fgColor, bgColor);
    final passesAA = ratio >= 4.5;
    final passesAAA = ratio >= 7.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141820) : const Color(0xFFE2EAF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCESSIBILITY (WCAG CONTRAST)',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark
                            ? FormaColors.darkTextMuted
                            : FormaColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Layer color readability vs canvas',
                      style: TextStyle(
                        fontSize: 8.5,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${ratio.toStringAsFixed(1)}:1',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildBadge('AA Normal', passesAA),
              _buildBadge('AAA Enhanced', passesAAA),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, bool pass) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: pass
            ? FormaColors.successGreen.withValues(alpha: 0.15)
            : FormaColors.dangerRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label ${pass ? "PASS" : "FAIL"}',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: pass ? FormaColors.successGreen : FormaColors.dangerRed,
        ),
      ),
    );
  }

  double _calculateContrastRatio(Color fg, Color bg) {
    final l1 = fg.computeLuminance();
    final l2 = bg.computeLuminance();
    final brightest = math.max(l1, l2);
    final darkest = math.min(l1, l2);
    return (brightest + 0.05) / (darkest + 0.05);
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
      ),
    );
  }

  Widget _buildNumberInput(
    String label,
    double value,
    ValueChanged<double> onChanged,
    bool isDark,
  ) {
    return NeuWell(
      radius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? FormaColors.darkTextMuted
                  : FormaColors.lightTextMuted,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value.toStringAsFixed(1)),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? FormaColors.darkTextMain
                    : FormaColors.lightTextMain,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (txt) {
                final parsed = double.tryParse(txt);
                if (parsed != null) onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}


class TypographyPropertySection extends StatefulWidget {
  final DesignNode node;
  final EditorController controller;
  final bool isDark;

  const TypographyPropertySection({
    super.key,
    required this.node,
    required this.controller,
    required this.isDark,
  });

  @override
  State<TypographyPropertySection> createState() => _TypographyPropertySectionState();
}

class _TypographyPropertySectionState extends State<TypographyPropertySection> {
  late TextEditingController _textCtrl;
  late TextEditingController _fontSizeCtrl;
  late TextEditingController _customFontCtrl;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _fontSizeFocusNode = FocusNode();
  bool _showCustomFontInput = false;

  static const List<String> _fontFamilies = [
    'Plus Jakarta Sans',
    'Inter',
    'Roboto',
    'Open Sans',
    'Poppins',
    'Lato',
    'Montserrat',
    'Playfair Display',
    'Fira Code',
    'Courier New',
    'Georgia',
    'Arial',
  ];

  static const List<int> _fontWeights = [
    100,
    300,
    400,
    500,
    600,
    700,
    800,
    900,
  ];

  static const List<double> _quickSizes = [
    12, 14, 16, 20, 24, 32, 48, 64, 96, 120
  ];

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.node.textData?.text ?? '');
    _fontSizeCtrl = TextEditingController(
      text: (widget.node.textData?.fontSize ?? 16.0).toStringAsFixed(0),
    );
    _customFontCtrl = TextEditingController(
      text: widget.node.textData?.fontFamily ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant TypographyPropertySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id ||
        (widget.node.textData?.text != _textCtrl.text && !_focusNode.hasFocus)) {
      _textCtrl.text = widget.node.textData?.text ?? '';
    }
    if (oldWidget.node.id != widget.node.id ||
        (!_fontSizeFocusNode.hasFocus)) {
      final curVal = double.tryParse(_fontSizeCtrl.text);
      if (curVal == null || (curVal - (widget.node.textData?.fontSize ?? 16.0)).abs() > 0.5) {
        _fontSizeCtrl.text = (widget.node.textData?.fontSize ?? 16.0).toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _fontSizeFocusNode.dispose();
    _textCtrl.dispose();
    _fontSizeCtrl.dispose();
    _customFontCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    final t = widget.node.textData ?? const TextNodeData();
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TYPOGRAPHY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
              ),
            ),
            IconButton(
              icon: Icon(
                _showCustomFontInput ? Icons.font_download_rounded : Icons.add_circle_outline_rounded,
                size: 16,
                color: FormaColors.primaryBlue,
              ),
              tooltip: _showCustomFontInput ? 'Hide Custom Font' : 'Type Custom Font Name',
              onPressed: () => setState(() => _showCustomFontInput = !_showCustomFontInput),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Text Content Input (Persistent controller)
        TextField(
          controller: _textCtrl,
          focusNode: _focusNode,
          maxLines: 3,
          minLines: 1,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? FormaColors.darkTextMain : FormaColors.lightTextMain,
          ),
          decoration: InputDecoration(
            hintText: 'Enter text content...',
            filled: true,
            fillColor: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) => _update(t.copyWith(text: val)),
        ),
        const SizedBox(height: 10),

        // Custom Font Input Bar (if toggled)
        if (_showCustomFontInput) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FormaColors.primaryBlue.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customFontCtrl,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Type any Google or System Font (e.g. Bebas Neue)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (fontName) {
                      if (fontName.trim().isNotEmpty) {
                        _update(t.copyWith(fontFamily: fontName.trim()));
                      }
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final fontName = _customFontCtrl.text.trim();
                    if (fontName.isNotEmpty) {
                      _update(t.copyWith(fontFamily: fontName));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FormaColors.primaryBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Font Family Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _fontFamilies.contains(t.fontFamily) ? t.fontFamily : null,
              hint: Text(
                t.fontFamily,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.arrow_drop_down_rounded),
              items: _fontFamilies.map((font) {
                TextStyle fontStyle;
                try {
                  fontStyle = GoogleFonts.getFont(font, fontSize: 12.5);
                } catch (_) {
                  fontStyle = TextStyle(fontFamily: font, fontSize: 12.5);
                }
                return DropdownMenuItem(
                  value: font,
                  child: Text(font, style: fontStyle),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  _customFontCtrl.text = val;
                  _update(t.copyWith(fontFamily: val));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Font Weight Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _fontWeights.map((w) {
              final isSel = t.fontWeight == w;
              return GestureDetector(
                onTap: () => _update(t.copyWith(fontWeight: w)),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSel
                        ? FormaColors.primaryBlue
                        : (isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$w',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSel ? Colors.white : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Direct Editable Font Size Input Row
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'SIZE (PT)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fontSizeCtrl,
                        focusNode: _fontSizeFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null && parsed >= 4) {
                            _update(t.copyWith(fontSize: parsed));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Quick stepper [+] / [-]
            Row(
              children: [
                NeuIconButton(
                  icon: Icons.remove_rounded,
                  size: 34,
                  iconSize: 16,
                  onPressed: () {
                    final next = math.max(6.0, t.fontSize - 2.0);
                    _fontSizeCtrl.text = next.toStringAsFixed(0);
                    _update(t.copyWith(fontSize: next));
                  },
                ),
                const SizedBox(width: 4),
                NeuIconButton(
                  icon: Icons.add_rounded,
                  size: 34,
                  iconSize: 16,
                  onPressed: () {
                    final next = t.fontSize + 2.0;
                    _fontSizeCtrl.text = next.toStringAsFixed(0);
                    _update(t.copyWith(fontSize: next));
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick Preset Size Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickSizes.map((sz) {
              final isSel = (t.fontSize - sz).abs() < 0.5;
              return GestureDetector(
                onTap: () {
                  _fontSizeCtrl.text = sz.toStringAsFixed(0);
                  _update(t.copyWith(fontSize: sz));
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSel
                        ? FormaColors.primaryBlue.withValues(alpha: 0.2)
                        : (isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSel
                          ? FormaColors.primaryBlue
                          : (isDark ? FormaColors.darkBorder : FormaColors.lightBorder),
                    ),
                  ),
                  child: Text(
                    '${sz.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? FormaColors.primaryBlue : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        // Line Height & Letter Spacing
        Row(
          children: [
            Expanded(
              child: FormaTouchNudgeField(
                label: 'HEIGHT',
                value: t.lineHeight,
                min: 0.5,
                step: 0.1,
                onChanged: (v) => _update(t.copyWith(lineHeight: math.max(0.5, v))),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FormaTouchNudgeField(
                label: 'SPACING',
                value: t.letterSpacing,
                step: 0.5,
                onChanged: (v) => _update(t.copyWith(letterSpacing: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Alignment & Style Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                NeuIconButton(
                  icon: Icons.format_align_left_rounded,
                  size: 28,
                  iconSize: 14,
                  isActive: t.textAlign == TextAlign.left,
                  onPressed: () => _update(t.copyWith(textAlign: TextAlign.left)),
                ),
                const SizedBox(width: 4),
                NeuIconButton(
                  icon: Icons.format_align_center_rounded,
                  size: 28,
                  iconSize: 14,
                  isActive: t.textAlign == TextAlign.center,
                  onPressed: () => _update(t.copyWith(textAlign: TextAlign.center)),
                ),
                const SizedBox(width: 4),
                NeuIconButton(
                  icon: Icons.format_align_right_rounded,
                  size: 28,
                  iconSize: 14,
                  isActive: t.textAlign == TextAlign.right,
                  onPressed: () => _update(t.copyWith(textAlign: TextAlign.right)),
                ),
                const SizedBox(width: 4),
                NeuIconButton(
                  icon: Icons.format_align_justify_rounded,
                  size: 28,
                  iconSize: 14,
                  isActive: t.textAlign == TextAlign.justify,
                  onPressed: () => _update(t.copyWith(textAlign: TextAlign.justify)),
                ),
              ],
            ),
            Row(
              children: [
                NeuIconButton(
                  icon: Icons.format_italic_rounded,
                  size: 28,
                  iconSize: 14,
                  isActive: t.isItalic,
                  onPressed: () => _update(t.copyWith(isItalic: !t.isItalic)),
                ),
                const SizedBox(width: 4),
                NeuIconButton(
                  icon: Icons.format_underlined_rounded,
                  size: 28,
                  iconSize: 14,
                  isActive: t.underline,
                  onPressed: () => _update(t.copyWith(underline: !t.underline)),
                ),
                const SizedBox(width: 4),
                NeuIconButton(
                  icon: Icons.format_strikethrough_rounded,
                  size: 28,
                  iconSize: 14,
                  isActive: t.strikethrough,
                  onPressed: () => _update(t.copyWith(strikethrough: !t.strikethrough)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
