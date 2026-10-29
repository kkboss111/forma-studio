import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../domain/models/project_model.dart';
import '../../../domain/models/paint_styles.dart';
import '../../../app/theme/forma_colors.dart';
import '../../../app/theme/neumorphic.dart';
import '../../../app/theme/liquid_glass.dart';
import '../../../app/theme/responsive_breakpoints.dart';
import '../../../app/widgets/forma_logo.dart';
import '../../../app/widgets/studio_loading_transition.dart';
import '../../settings/models/app_settings.dart';
import '../../settings/screens/settings_screen.dart';
import '../controllers/editor_controller.dart';
import '../controllers/editor_state.dart';
import '../widgets/canvas/canvas_viewport.dart';
import '../widgets/panels/layers_panel.dart';
import '../widgets/panels/properties_panel.dart';
import '../widgets/panels/inspector_panel.dart';
import '../widgets/prototype/prototype_player.dart';
import '../widgets/dialogs/export_dialog.dart';
import '../widgets/dialogs/color_picker_dialog.dart';
import '../widgets/dialogs/command_palette.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const EditorScreen({super.key, required this.project});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final FocusNode _focusNode = FocusNode();
  bool _showLayersSheet = false;
  bool _showPropertiesSheet = false;

  Future<void> _returnToHome(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StudioLoadingTransition(
        type: StudioTransitionType.canvasToHome,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 280));
    if (context.mounted) {
      Navigator.of(context).pop(); // pop loading dialog
      Navigator.of(context).pop(); // pop editor screen to home
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _openExportDialog(BuildContext context, dynamic state) {
    showDialog(
      context: context,
      builder: (_) => ExportDialog(
        project: state.project,
        activePageId: state.activePageId,
        selectedNodeId: state.primarySelectedId,
      ),
    );
  }

  void _openCommandPalette(
    BuildContext context,
    EditorController controller,
    dynamic state,
  ) {
    showDialog(
      context: context,
      builder: (_) => CommandPaletteDialog(
        controller: controller,
        onOpenExport: () {
          Navigator.of(context).pop();
          _openExportDialog(context, state);
        },
      ),
    );
  }

  Future<void> _showRenameDialog(
    EditorController controller,
    String currentName,
  ) async {
    final textController = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: FormaColors.primaryBlue),
            SizedBox(width: 8),
            Text('Rename Document', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            hintText: 'Enter document name',
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, textController.text),
            child: const Text('Rename', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (newName != null && newName.trim().isNotEmpty) {
      controller.renameProject(newName.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document renamed to "$newName"')),
      );
    }
  }

  Future<void> _handleImportSvg(EditorController controller) async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final decoder = Encoding.getByName('utf-8')!;
        final svgString = decoder.decode(bytes);
        controller.importSvg(svgString);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SVG imported onto canvas!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import SVG: $e')),
        );
      }
    }
  }

  Future<void> _handleInsertImage(EditorController controller) async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Str = base64Encode(bytes);
        controller.insertImageNode(base64Image: base64Str);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image inserted onto canvas!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to insert image: $e')),
        );
      }
    }
  }

  Future<void> _handleSetSelectedImageFill(EditorController controller) async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Str = base64Encode(bytes);
        controller.setImageFillForSelected(base64Image: base64Str);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image applied inside selected object!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply image fill: $e')),
        );
      }
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(initialTabIndex: 1),
      ),
    );
  }

  KeyEventResult _handleKey(
    FocusNode node,
    KeyEvent event,
    EditorController controller,
    dynamic state,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Do NOT hijack keys (especially backspace or delete) when typing in text fields
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus != node) {
      final focusedWidget = primaryFocus.context?.widget;
      if (focusedWidget is EditableText ||
          primaryFocus.context?.findAncestorWidgetOfExactType<EditableText>() != null) {
        return KeyEventResult.ignored;
      }
    }

    final isCtrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyZ) {
      if (isShift) {
        controller.redo();
      } else {
        controller.undo();
      }
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyY) {
      controller.redo();
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyC) {
      controller.copySelection();
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyX) {
      controller.cutSelection();
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyV) {
      controller.paste();
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyD) {
      controller.duplicateSelectedNodes();
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyA) {
      controller.selectAll();
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyG) {
      if (isShift) {
        controller.ungroupSelectedNodes();
      } else {
        controller.groupSelectedNodes();
      }
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyK) {
      _openCommandPalette(context, controller, state);
      return KeyEventResult.handled;
    }

    // Zoom shortcuts
    if (isCtrl &&
        (event.logicalKey == LogicalKeyboardKey.equal ||
            event.logicalKey == LogicalKeyboardKey.add)) {
      controller.zoomIn();
      return KeyEventResult.handled;
    }

    if (isCtrl &&
        (event.logicalKey == LogicalKeyboardKey.minus ||
            event.logicalKey == LogicalKeyboardKey.numpadSubtract)) {
      controller.zoomOut();
      return KeyEventResult.handled;
    }

    if (isCtrl &&
        (event.logicalKey == LogicalKeyboardKey.digit0 ||
            event.logicalKey == LogicalKeyboardKey.numpad0)) {
      controller.zoom100();
      return KeyEventResult.handled;
    }

    // Transform flip shortcuts
    if (isShift && !isCtrl && event.logicalKey == LogicalKeyboardKey.keyH) {
      controller.flipHorizontalSelected();
      return KeyEventResult.handled;
    }

    if (isShift && !isCtrl && event.logicalKey == LogicalKeyboardKey.keyV) {
      controller.flipVerticalSelected();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      controller.deleteSelectedNodes();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      controller.clearSelection();
      return KeyEventResult.handled;
    }

    // Arrow nudging
    final nudgeDist = isShift ? 10.0 : 1.0;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.nudgeSelection(Offset(-nudgeDist, 0));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.nudgeSelection(Offset(nudgeDist, 0));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      controller.nudgeSelection(Offset(0, -nudgeDist));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      controller.nudgeSelection(Offset(0, nudgeDist));
      return KeyEventResult.handled;
    }

    // Single-key tool switches
    if (!isCtrl) {
      if (event.logicalKey == LogicalKeyboardKey.keyV) {
        controller.setTool(EditorTool.select);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyH) {
        controller.setTool(EditorTool.hand);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyR) {
        controller.setTool(EditorTool.rectangle);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyO) {
        controller.setTool(EditorTool.ellipse);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyT) {
        controller.setTool(EditorTool.text);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyP) {
        controller.setTool(EditorTool.vectorPen);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyF) {
        controller.setTool(EditorTool.frame);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider(widget.project));
    final controller = ref.read(
      editorControllerProvider(widget.project).notifier,
    );
    final settings = ref.watch(settingsProvider);
    final isGlass = settings.themeMode == FormaThemeMode.liquidGlass;
    final isDark = settings.themeMode == FormaThemeMode.dark ||
        (settings.themeMode == FormaThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    // If Prototype Player is active, display full interactive preview
    if (state.isPlayingPrototype) {
      return PrototypePlayer(
        project: state.project,
        onClose: controller.togglePrototypePlay,
      );
    }

    Widget content = PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _returnToHome(context);
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (node, event) => _handleKey(node, event, controller, state),
        child: Scaffold(
        backgroundColor: isGlass
            ? Colors.transparent
            : (isDark ? FormaColors.darkBg : FormaColors.lightBg),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final orientation = MediaQuery.of(context).orientation;
              final layoutType = FormaResponsive.getLayoutType(
                constraints,
                orientation,
              );

              return Column(
                children: [
                  // --- TOP BAR ---
                  _buildTopBar(
                    context,
                    state,
                    controller,
                    layoutType,
                    isDark,
                    isGlass,
                  ),

                  // --- MAIN EDITOR WORKSPACE ---
                  Expanded(
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            // Left Layers Panel (Tablets & Desktop)
                            if (layoutType == DeviceLayoutType.tabletOrDesktop)
                              LayersPanel(project: widget.project),

                            // Center Canvas (Full screen on phones & landscape mobile)
                            Expanded(
                              child: CanvasViewport(project: widget.project),
                            ),

                            // Right Inspector Panel or Properties Panel (Tablets & Desktop)
                            if (layoutType == DeviceLayoutType.tabletOrDesktop)
                              state.isDevInspectMode
                                  ? InspectorPanel(project: widget.project)
                                  : PropertiesPanel(project: widget.project),
                          ],
                        ),

                        // --- MOBILE FLOATING CONTEXTUAL SELECTION BAR ---
                        if (layoutType != DeviceLayoutType.tabletOrDesktop)
                          _buildMobileSelectionActionBar(
                            context,
                            state,
                            controller,
                            isDark,
                            isGlass,
                          ),

                        // --- MOBILE FLOATING BOTTOM DOCK ---
                        if (layoutType != DeviceLayoutType.tabletOrDesktop)
                          _buildMobileBottomDock(
                            context,
                            state,
                            controller,
                            isDark,
                            isGlass,
                          ),

                        // --- MOBILE SLIDING LAYERS SHEET / DRAWER ---
                        if (_showLayersSheet &&
                            layoutType != DeviceLayoutType.tabletOrDesktop)
                          _buildMobileSheet(
                            context: context,
                            constraints: constraints,
                            title: 'Layers',
                            onClose: () =>
                                setState(() => _showLayersSheet = false),
                            child: LayersPanel(
                              project: widget.project,
                              width: double.infinity,
                            ),
                            isDark: isDark,
                          ),

                        // --- MOBILE SLIDING PROPERTIES SHEET / DRAWER ---
                        if (_showPropertiesSheet &&
                            layoutType != DeviceLayoutType.tabletOrDesktop)
                          _buildMobileSheet(
                            context: context,
                            constraints: constraints,
                            title: 'Properties',
                            onClose: () =>
                                setState(() => _showPropertiesSheet = false),
                            child: PropertiesPanel(
                              project: widget.project,
                              width: double.infinity,
                            ),
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

    if (isGlass) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LiquidGlassTheme.liquidMeshGradient,
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildTopBar(
    BuildContext context,
    dynamic state,
    EditorController controller,
    DeviceLayoutType layoutType,
    bool isDark,
    bool isGlass,
  ) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isGlass
            ? Colors.white.withValues(alpha: 0.35)
            : (isDark ? FormaColors.darkSurface : FormaColors.lightSurface),
        border: Border(
          bottom: BorderSide(
            color: isGlass
                ? Colors.white.withValues(alpha: 0.4)
                : (isDark ? FormaColors.darkBorder : FormaColors.lightBorder),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Back to Home
            NeuIconButton(
              icon: Icons.home_rounded,
              size: 34,
              iconSize: 18,
              tooltip: 'Home',
              onPressed: () => _returnToHome(context),
            ),
            const SizedBox(width: 8),

            // App Logo
            const FormaLogo(size: 26),
            const SizedBox(width: 8),

            // Project Title (Tap to Rename)
            InkWell(
              onTap: () => _showRenameDialog(controller, state.project.name),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        state.project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? FormaColors.darkTextMain
                              : FormaColors.lightTextMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Undo / Redo
            NeuIconButton(
              icon: Icons.undo_rounded,
              size: 32,
              iconSize: 16,
              tooltip: 'Undo (Ctrl+Z)',
              onPressed: controller.canUndo ? controller.undo : null,
            ),
            const SizedBox(width: 4),
            NeuIconButton(
              icon: Icons.redo_rounded,
              size: 32,
              iconSize: 16,
              tooltip: 'Redo (Ctrl+Y)',
              onPressed: controller.canRedo ? controller.redo : null,
            ),
            const SizedBox(width: 12),

            // Central Tools Dock on Tablets & Desktop
            if (layoutType == DeviceLayoutType.tabletOrDesktop) ...[
              _buildToolsBar(state, controller, isDark),
              const SizedBox(width: 12),
            ],

            // Insert Image
            NeuIconButton(
              icon: Icons.image_outlined,
              size: 34,
              iconSize: 16,
              tooltip: 'Insert Image (PNG/JPG)',
              onPressed: () => _handleInsertImage(controller),
            ),
            const SizedBox(width: 6),

            // Import SVG
            NeuIconButton(
              icon: Icons.file_open_outlined,
              size: 34,
              iconSize: 16,
              tooltip: 'Import SVG to Canvas',
              onPressed: () => _handleImportSvg(controller),
            ),
            const SizedBox(width: 6),

            // Command Palette Button
            NeuIconButton(
              icon: Icons.terminal_rounded,
              size: 34,
              iconSize: 16,
              tooltip: 'Command Palette (Ctrl+K)',
              onPressed: () => _openCommandPalette(context, controller, state),
            ),
            const SizedBox(width: 6),

            // Zoom percentage indicator
            NeuButton(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              onPressed: controller.zoom100,
              tooltip: 'Reset Zoom (100%)',
              child: Text(
                '${(state.zoom * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? FormaColors.darkTextMain
                      : FormaColors.lightTextMain,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Dev Inspect Toggle
            NeuIconButton(
              icon: Icons.code_rounded,
              size: 34,
              iconSize: 16,
              isActive: state.isDevInspectMode,
              tooltip: 'Inspect CSS / Flutter Code',
              onPressed: controller.toggleDevInspectMode,
            ),
            const SizedBox(width: 6),

            // Play Prototype
            NeuIconButton(
              icon: Icons.play_arrow_rounded,
              size: 34,
              iconSize: 18,
              tooltip: 'Play Interactive Prototype',
              iconColor: FormaColors.successGreen,
              onPressed: controller.togglePrototypePlay,
            ),
            const SizedBox(width: 6),

            // Settings Button
            NeuIconButton(
              icon: Icons.settings_outlined,
              size: 34,
              iconSize: 16,
              tooltip: 'Settings & Themes',
              onPressed: () => _openSettings(context),
            ),
            const SizedBox(width: 6),

            // Theme Toggle Button (Quick Dark / Light mode toggle)
            NeuIconButton(
              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 34,
              iconSize: 16,
              iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFF6366F1),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () {
                final current = ref.read(settingsProvider);
                final isCurrentlyDark = current.themeMode == FormaThemeMode.dark ||
                    (current.themeMode == FormaThemeMode.system &&
                        MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                final nextMode = isCurrentlyDark ? FormaThemeMode.light : FormaThemeMode.dark;
                ref.read(settingsProvider.notifier).setThemeMode(nextMode);
              },
            ),
            const SizedBox(width: 6),

            // Export Button (Sleek, Restrained Neumorphic Pill)
            NeuButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              onPressed: () => _openExportDialog(context, state),
              tooltip: 'Export Design (PNG, SVG, PDF, FIG)',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.file_download_outlined,
                    size: 15,
                    color: FormaColors.primaryBlue,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Export',
                    style: TextStyle(
                      color: isDark ? FormaColors.darkTextMain : FormaColors.lightTextMain,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsBar(
    dynamic state,
    EditorController controller,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkBg : FormaColors.lightBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toolButton(
            EditorTool.select,
            Icons.near_me_rounded,
            'Select (V)',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.hand,
            Icons.pan_tool_rounded,
            'Hand Pan (H)',
            state,
            controller,
          ),
          const SizedBox(width: 4),
          _toolButton(
            EditorTool.frame,
            Icons.crop_free_rounded,
            'Frame (F)',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.rectangle,
            Icons.crop_square_rounded,
            'Rectangle (R)',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.roundedRectangle,
            Icons.rectangle_rounded,
            'Rounded Rect',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.triangle,
            Icons.change_history_rounded,
            'Triangle',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.ellipse,
            Icons.circle_outlined,
            'Ellipse (O)',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.line,
            Icons.horizontal_rule_rounded,
            'Line (L)',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.arrow,
            Icons.arrow_right_alt_rounded,
            'Arrow',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.polygon,
            Icons.hexagon_outlined,
            'Polygon (5-sided)',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.star,
            Icons.star_border_rounded,
            'Star',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.vectorPen,
            Icons.polyline_rounded,
            'Vector Pen (P)',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.text,
            Icons.title_rounded,
            'Text (T)',
            state,
            controller,
          ),
          _toolButton(
            EditorTool.freehand,
            Icons.edit_outlined,
            'Pencil Draw',
            state,
            controller,
          ),
        ],
      ),
    );
  }

  Widget _toolButton(
    EditorTool tool,
    IconData icon,
    String tooltip,
    dynamic state,
    EditorController controller, {
    double size = 36,
    double iconSize = 18,
  }) {
    final isActive = state.activeTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: NeuIconButton(
        icon: icon,
        size: size,
        iconSize: iconSize,
        isActive: isActive,
        tooltip: tooltip,
        onPressed: () => controller.setTool(tool),
      ),
    );
  }

  Widget _buildMobileSelectionActionBar(
    BuildContext context,
    dynamic state,
    EditorController controller,
    bool isDark,
    bool isGlass,
  ) {
    final selectedIds = state.selectedNodeIds as Set<String>;
    if (selectedIds.isEmpty) return const SizedBox.shrink();

    final primaryNode = state.project.nodes[selectedIds.first];
    final fillColor = (primaryNode != null && primaryNode.fills.isNotEmpty)
        ? primaryNode.fills.first.color
        : FormaColors.primaryBlue;

    final barContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PROMINENT DELETE BUTTON (Red accent)
          IconButton(
            icon: const Icon(
              Icons.delete_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
            tooltip: 'Delete Selected',
            splashRadius: 22,
            onPressed: controller.deleteSelectedNodes,
          ),
          const SizedBox(width: 4),

          // DUPLICATE BUTTON
          IconButton(
            icon: Icon(
              Icons.copy_rounded,
              color: isDark ? Colors.white70 : FormaColors.lightTextMain,
              size: 20,
            ),
            tooltip: 'Duplicate (Ctrl+D)',
            splashRadius: 20,
            onPressed: controller.duplicateSelectedNodes,
          ),
          const SizedBox(width: 4),

          // COLOR SWATCH BUTTON
          GestureDetector(
            onTap: () {
              ColorPickerDialog.show(
                context,
                initialColor: fillColor,
                initialFill: (primaryNode != null && primaryNode.fills.isNotEmpty)
                    ? primaryNode.fills.first
                    : null,
                onColorChanged: (c) {
                  controller.updateSelectedProperties(
                    fills: [DesignFill.solid(c)],
                  );
                },
                onFillChanged: (newFill) {
                  controller.updateSelectedProperties(fills: [newFill]);
                },
              );
            },
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: fillColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: fillColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // IMAGE FILL BUTTON (Mask image inside selected object)
          IconButton(
            icon: const Icon(
              Icons.image_outlined,
              size: 20,
            ),
            tooltip: 'Apply Image Inside Shape',
            splashRadius: 20,
            onPressed: () => _handleSetSelectedImageFill(controller),
          ),
          const SizedBox(width: 4),

          // ALIGN CENTER
          IconButton(
            icon: Icon(
              Icons.align_horizontal_center_rounded,
              color: isDark ? Colors.white70 : FormaColors.lightTextMain,
              size: 20,
            ),
            tooltip: 'Align Center',
            splashRadius: 20,
            onPressed: () => controller.alignSelection('centerHorizontal'),
          ),
          const SizedBox(width: 4),

          // BRING FORWARD
          IconButton(
            icon: Icon(
              Icons.flip_to_front_rounded,
              color: isDark ? Colors.white70 : FormaColors.lightTextMain,
              size: 20,
            ),
            tooltip: 'Bring Forward',
            splashRadius: 20,
            onPressed: controller.bringForward,
          ),
          const SizedBox(width: 4),

          // PROPERTIES TOGGLE
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: FormaColors.primaryBlue,
              size: 20,
            ),
            tooltip: 'Properties Sheet',
            splashRadius: 20,
            onPressed: () {
              setState(() {
                _showPropertiesSheet = !_showPropertiesSheet;
                _showLayersSheet = false;
              });
            },
          ),
        ],
      ),
    );

    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: barContent,
        ),
      ),
    );
  }

  Widget _buildMobileBottomDock(
    BuildContext context,
    dynamic state,
    EditorController controller,
    bool isDark,
    bool isGlass,
  ) {
    final settings = ref.watch(settingsProvider);

    final children = [
      NeuIconButton(
        icon: Icons.layers_outlined,
        size: 38,
        iconSize: 18,
        isActive: _showLayersSheet,
        tooltip: 'Layers',
        onPressed: () {
          setState(() {
            _showLayersSheet = !_showLayersSheet;
            _showPropertiesSheet = false;
          });
        },
      ),
      const SizedBox(width: 4, height: 4),
      _toolButton(
        EditorTool.select,
        Icons.near_me_rounded,
        'Select',
        state,
        controller,
        size: 36,
        iconSize: 17,
      ),
      _toolButton(
        EditorTool.rectangle,
        Icons.crop_square_rounded,
        'Rect',
        state,
        controller,
        size: 36,
        iconSize: 17,
      ),
      _toolButton(
        EditorTool.triangle,
        Icons.change_history_rounded,
        'Triangle',
        state,
        controller,
        size: 36,
        iconSize: 17,
      ),
      _toolButton(
        EditorTool.ellipse,
        Icons.circle_outlined,
        'Oval',
        state,
        controller,
        size: 36,
        iconSize: 17,
      ),
      _toolButton(
        EditorTool.vectorPen,
        Icons.polyline_rounded,
        'Pen',
        state,
        controller,
        size: 36,
        iconSize: 17,
      ),
      _toolButton(
        EditorTool.text,
        Icons.title_rounded,
        'Text',
        state,
        controller,
        size: 36,
        iconSize: 17,
      ),
      NeuIconButton(
        icon: Icons.image_outlined,
        size: 36,
        iconSize: 17,
        tooltip: 'Insert Image',
        onPressed: () => _handleInsertImage(controller),
      ),
      if (state.selectedNodeIds.isEmpty) ...[
        GestureDetector(
          onTap: () {
            final page = state.project.getPage(state.activePageId);
            if (page != null) {
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
            }
          },
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: state.project.getPage(state.activePageId)?.backgroundColor ?? Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
      _toolButton(
        EditorTool.hand,
        Icons.pan_tool_rounded,
        'Pan',
        state,
        controller,
        size: 36,
        iconSize: 17,
      ),
      const SizedBox(width: 4, height: 4),
      NeuIconButton(
        icon: Icons.tune_rounded,
        size: 38,
        iconSize: 18,
        isActive: _showPropertiesSheet,
        tooltip: 'Properties',
        onPressed: () {
          setState(() {
            _showPropertiesSheet = !_showPropertiesSheet;
            _showLayersSheet = false;
          });
        },
      ),
    ];

    final dockContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    final wrappedDock = isGlass
        ? LiquidGlassBox(
            radius: 24,
            blur: settings.glassBlur,
            opacity: settings.glassOpacity,
            hasSpecular: settings.glassSpecular,
            hasSheen: settings.glassSheen,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: dockContent,
            ),
          )
        : NeuCard(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: dockContent,
            ),
          );

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: wrappedDock,
        ),
      ),
    );
  }

  Widget _buildMobileSheet({
    required BuildContext context,
    required BoxConstraints constraints,
    required String title,
    required VoidCallback onClose,
    required Widget child,
    required bool isDark,
  }) {
    final isLandscape = constraints.maxHeight < 550;

    if (isLandscape) {
      // Landscape Phone: Slide-over right drawer (full height, 330px width)
      return Positioned(
        top: 6,
        bottom: 6,
        right: 6,
        width: math.min(340, constraints.maxWidth * 0.55),
        child: NeuCard(
          radius: 18,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.6,
                        color: FormaColors.primaryBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      splashRadius: 16,
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    } else {
      // Portrait Phone: Slide-up bottom sheet
      return Positioned(
        bottom: 74,
        left: 12,
        right: 12,
        height: constraints.maxHeight * 0.70,
        child: NeuCard(
          radius: 24,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.6,
                        color: FormaColors.primaryBlue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      splashRadius: 18,
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }
  }
}
