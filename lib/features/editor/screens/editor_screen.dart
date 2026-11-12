import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../widgets/dialogs/icon_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../domain/models/project_model.dart';
import '../../../domain/models/paint_styles.dart';
import '../../../domain/models/editor_tab_model.dart';
import '../../../core/collab/collab_service.dart';
import '../../../app/theme/forma_colors.dart';
import '../../../app/theme/neumorphic.dart';
import '../../../app/theme/liquid_glass.dart';
import '../../../app/theme/responsive_breakpoints.dart';
import '../../../app/widgets/forma_logo.dart';
import '../../../app/widgets/studio_loading_transition.dart';
import '../../../app/widgets/forma_ambient_backdrop.dart';
import '../../../app/widgets/forma_theme_picker_dialog.dart';
import '../../../app/theme/forma_theme.dart';
import '../../settings/models/app_settings.dart';
import '../../settings/screens/settings_screen.dart';
import '../controllers/editor_controller.dart';
import '../controllers/editor_state.dart';
import '../widgets/canvas/canvas_viewport.dart';
import '../widgets/canvas/icon_canvas_viewport.dart';
import '../widgets/tabs/editor_tab_bar.dart';
import '../widgets/panels/layers_panel.dart';
import '../widgets/panels/properties_panel.dart';
import '../widgets/panels/inspector_panel.dart';
import '../widgets/prototype/prototype_player.dart';
import '../widgets/dialogs/export_dialog.dart';
import '../widgets/dialogs/color_picker_dialog.dart';
import '../widgets/dialogs/command_palette.dart';
import '../widgets/dialogs/manual_zoom_dialog.dart';
import '../widgets/dialogs/collab_dialog.dart';
import '../widgets/panels/timeline_panel.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const EditorScreen({super.key, required this.project});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  bool _showLayersSheet = false;
  bool _showPropertiesSheet = false;
  bool _leftSidebarOpen = true;
  bool _rightSidebarOpen = true;
  late List<EditorTab> _tabs;
  String _activeTabId = 'main-canvas';

  EditorTab get _activeTab => _tabs.firstWhere(
        (t) => t.id == _activeTabId,
        orElse: () => _tabs.isNotEmpty ? _tabs.first : EditorTab.mainCanvas(),
      );

  @override
  void initState() {
    super.initState();
    _tabs = [
      EditorTab.mainCanvas(
        id: 'main-canvas',
        title: widget.project.pages.isNotEmpty
            ? widget.project.pages.first.name
            : 'Main Artboard',
      ),
    ];
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive ||
        lifecycleState == AppLifecycleState.hidden) {
      ref.read(editorControllerProvider(widget.project).notifier).saveNow();
    }
  }

  Future<void> _returnToHome(BuildContext context) async {
    await ref.read(editorControllerProvider(widget.project).notifier).saveNow();
    if (!context.mounted) return;
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
    WidgetsBinding.instance.removeObserver(this);
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
    final tokens = FormaTheme.tokensOf(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: tokens.accent),
            const SizedBox(width: 8),
            Text(
              'Rename Document',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: tokens.textMain),
            ),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: TextStyle(color: tokens.textMain, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: tokens.wellBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.accent, width: 1.5),
            ),
            hintText: 'Enter document name...',
            hintStyle: TextStyle(color: tokens.textMuted, fontSize: 12),
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: tokens.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, textController.text),
            child: const Text('Rename', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _handleImportHtml(EditorController controller) async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['html', 'htm'],
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final decoder = Encoding.getByName('utf-8')!;
        final htmlString = decoder.decode(bytes);
        controller.importHtml(htmlString);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('HTML layout imported onto canvas!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import HTML: $e')),
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

    // Do NOT hijack keys when typing in text fields
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

    // Sidebar toggle shortcuts
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.bracketLeft) {
      setState(() => _leftSidebarOpen = !_leftSidebarOpen);
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.bracketRight) {
      setState(() => _rightSidebarOpen = !_rightSidebarOpen);
      return KeyEventResult.handled;
    }

    if (isCtrl && event.logicalKey == LogicalKeyboardKey.backslash) {
      setState(() {
        final anyOpen = _leftSidebarOpen || _rightSidebarOpen;
        _leftSidebarOpen = !anyOpen;
        _rightSidebarOpen = !anyOpen;
      });
      return KeyEventResult.handled;
    }

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
    final isSystemDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = FormaTheme.tokensForMode(settings.themeMode, isSystemDark: isSystemDark);
    final isGlass = tokens.isGlass;
    final isDark = tokens.isDark;

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
                final isDesktop = layoutType == DeviceLayoutType.tabletOrDesktop;

                final activePage = state.project.getPage(state.activePageId);
                if (_tabs.isNotEmpty &&
                    _tabs.first.isMainCanvas &&
                    activePage != null &&
                    _tabs.first.title != activePage.name) {
                  _tabs[0] = _tabs[0].copyWith(title: activePage.name);
                }

                return Column(
                  children: [
                    // --- TOP BAR WITH BREADCRUMBS ---
                    _buildTopBar(
                      context,
                      state,
                      controller,
                      layoutType,
                      tokens,
                      isDark,
                      isGlass,
                    ),

                    // --- MAIN EDITOR WORKSPACE ---
                    Expanded(
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              // Left Layers Panel (Tablets & Desktop with smooth collapsible animation)
                              if (isDesktop)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOutCubic,
                                  width: _leftSidebarOpen ? 260 : 0,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      minWidth: 260,
                                      maxWidth: 260,
                                      alignment: Alignment.topLeft,
                                      child: LayersPanel(project: widget.project, width: 260),
                                    ),
                                  ),
                                ),

                              // Center Canvas (Never squished on mobile!)
                              Expanded(
                                child: Stack(
                                  children: [
                                    Column(
                                      children: [
                                        // Sleek EditorTabBar directly above the canvas viewport
                                        EditorTabBar(
                                          tabs: _tabs,
                                          activeTabId: _activeTabId,
                                          onTabSelected: (tab) => setState(() => _activeTabId = tab.id),
                                          onTabClosed: (tab) => setState(() {
                                            _tabs.removeWhere((t) => t.id == tab.id);
                                            if (_activeTabId == tab.id) {
                                              _activeTabId = _tabs.isNotEmpty ? _tabs.last.id : 'main-canvas';
                                            }
                                          }),
                                          onNewIconCanvasWithSize: (sz) => setState(() {
                                            final t = EditorTab.iconCanvas(iconSize: sz);
                                            _tabs.add(t);
                                            _activeTabId = t.id;
                                          }),
                                          onTabRenamed: (renamed) => setState(() {
                                            final idx = _tabs.indexWhere((t) => t.id == renamed.id);
                                            if (idx != -1) _tabs[idx] = renamed;
                                          }),
                                        ),
                                        Expanded(
                                          child: _activeTab.isIconCanvas
                                              ? IconCanvasViewport(
                                                  tab: _activeTab,
                                                  project: widget.project,
                                                  onTabChanged: (u) {
                                                    final idx = _tabs.indexWhere((t) => t.id == u.id);
                                                    if (idx != -1) {
                                                      _tabs[idx] = u;
                                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                                        if (mounted) setState(() {});
                                                      });
                                                    }
                                                  },
                                                  onClose: () => setState(() {
                                                    _tabs.removeWhere((t) => t.id == _activeTab.id);
                                                    _activeTabId = _tabs.isNotEmpty ? _tabs.last.id : 'main-canvas';
                                                  }),
                                                )
                                              : CanvasViewport(project: widget.project),
                                        ),
                                        if (state.showTimelinePanel && !_activeTab.isIconCanvas)
                                          TimelinePanel(
                                            timeline: state.timeline,
                                            currentTimeMs: state.currentTimelineMs,
                                            isPlaying: state.isPlayingTimeline,
                                            selectedNodeId: state.primarySelectedId,
                                            onTogglePlay: () => controller.togglePlayAnimation(),
                                            onScrub: (ms) => controller.setTimelineScrub(ms),
                                            onAddKeyframe: (prop) => controller.addKeyframeForSelectedNode(property: prop),
                                            onDeleteKeyframe: () => controller.deleteKeyframeAtPlayhead(),
                                            onToggleLoop: () => controller.toggleTimelineLoop(),
                                            onFpsChanged: (fps) => controller.setTimelineFps(fps),
                                            onSnapPrev: () => controller.snapToPrevKeyframe(),
                                            onSnapNext: () => controller.snapToNextKeyframe(),
                                            onUpdateKeyframe: (nodeId, prop, idx, kf) => controller.updateKeyframe(nodeId, prop, idx, kf),
                                            onAddMotionPreset: (preset) => controller.addQuickMotionPreset(preset),
                                            onClose: () => controller.toggleTimelinePanel(),
                                          ),
                                      ],
                                    ),

                                    // PC Desktop: Floating Bottom Canvas Toolbar (Active on main canvas)
                                    if (isDesktop && !_activeTab.isIconCanvas)
                                      Positioned(
                                        bottom: 22,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                          child: _buildDesktopFloatingToolbar(
                                            context,
                                            state,
                                            controller,
                                            tokens,
                                            isDark,
                                            isGlass,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Right Inspector / Properties Panel (Tablets & Desktop with smooth collapsible animation)
                              if (isDesktop)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOutCubic,
                                  width: _rightSidebarOpen
                                      ? (state.isDevInspectMode ? 340 : 280)
                                      : 0,
                                  child: ClipRect(
                                    child: OverflowBox(
                                      minWidth: state.isDevInspectMode ? 340 : 280,
                                      maxWidth: state.isDevInspectMode ? 340 : 280,
                                      alignment: Alignment.topRight,
                                      child: state.isDevInspectMode
                                          ? InspectorPanel(project: widget.project)
                                          : PropertiesPanel(project: widget.project, width: 280),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // --- MOBILE FLOATING CONTEXTUAL SELECTION BAR ---
                          if (!isDesktop)
                            _buildMobileSelectionActionBar(
                              context,
                              state,
                              controller,
                              tokens,
                              isDark,
                            ),

                          // --- MOBILE FLOATING BOTTOM DOCK (Min 44x44 tap targets) ---
                          if (!isDesktop)
                            _buildMobileBottomDock(
                              context,
                              state,
                              controller,
                              tokens,
                              isDark,
                              isGlass,
                            ),

                          // --- MOBILE SLIDING DRAWER / BOTTOM SHEET FOR LAYERS (Does not squish canvas!) ---
                          if (!isDesktop && _showLayersSheet)
                            _buildMobileSlidingSheet(
                              context: context,
                              constraints: constraints,
                              title: 'Layers',
                              tokens: tokens,
                              isDark: isDark,
                              onClose: () => setState(() => _showLayersSheet = false),
                              child: LayersPanel(
                                project: widget.project,
                                width: double.infinity,
                              ),
                            ),

                          // --- MOBILE SLIDING DRAWER / BOTTOM SHEET FOR PROPERTIES (Does not squish canvas!) ---
                          if (!isDesktop && _showPropertiesSheet)
                            _buildMobileSlidingSheet(
                              context: context,
                              constraints: constraints,
                              title: 'Properties',
                              tokens: tokens,
                              isDark: isDark,
                              onClose: () => setState(() => _showPropertiesSheet = false),
                              child: PropertiesPanel(
                                project: widget.project,
                                width: double.infinity,
                              ),
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

    return FormaAmbientBackdrop(explicitTokens: tokens, child: content);
  }

  Widget _buildTopBar(
    BuildContext context,
    dynamic state,
    EditorController controller,
    DeviceLayoutType layoutType,
    FormaThemeTokens tokens,
    bool isDark,
    bool isGlass,
  ) {
    final settings = ref.watch(settingsProvider);
    final isDesktop = layoutType == DeviceLayoutType.tabletOrDesktop;
    final activePage = state.project.getPage(state.activePageId);

    Widget barContent = Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          bottom: BorderSide(
            color: tokens.border,
            width: 1.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Left Cluster: Home + Breadcrumbs
            NeuIconButton(
              icon: Icons.home_rounded,
              size: 34,
              iconSize: 18,
              tooltip: 'Home',
              onPressed: () => _returnToHome(context),
            ),
            const SizedBox(width: 8),

            // App Logo
            const FormaLogo(size: 24),
            const SizedBox(width: 10),

            // Breadcrumbs Header
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Home breadcrumb
                Text(
                  'Forma',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tokens.textMuted,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.chevron_right_rounded, size: 14, color: tokens.textMuted),
                ),

                // Project Name (Tap to Rename)
                InkWell(
                  onTap: () => _showRenameDialog(controller, state.project.name),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isDesktop ? 220 : 130),
                          child: Text(
                            state.project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: tokens.textMain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_outlined, size: 12, color: tokens.textMuted),
                      ],
                    ),
                  ),
                ),

                // Active Page / Canvas Breadcrumb Pill
                if (activePage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.chevron_right_rounded, size: 14, color: tokens.textMuted),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: tokens.accent.withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: tokens.accent.withValues(alpha: isDark ? 0.40 : 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      activePage.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tokens.accent,
                      ),
                    ),
                  ),
                ],

                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  // Collapsible Left Sidebar (Layers) Toggle
                  NeuIconButton(
                    icon: Icons.view_sidebar_rounded,
                    size: 32,
                    iconSize: 16,
                    isActive: _leftSidebarOpen,
                    tooltip: _leftSidebarOpen ? 'Collapse Layers (Ctrl+[)' : 'Expand Layers (Ctrl+[)',
                    onPressed: () => setState(() => _leftSidebarOpen = !_leftSidebarOpen),
                  ),
                  const SizedBox(width: 6),

                  // Undo / Redo
                  NeuIconButton(
                    icon: Icons.undo_rounded,
                    size: 32,
                    iconSize: 15,
                    tooltip: 'Undo (Ctrl+Z)',
                    onPressed: controller.canUndo ? controller.undo : null,
                  ),
                  const SizedBox(width: 4),
                  NeuIconButton(
                    icon: Icons.redo_rounded,
                    size: 32,
                    iconSize: 15,
                    tooltip: 'Redo (Ctrl+Y)',
                    onPressed: controller.canRedo ? controller.redo : null,
                  ),
                ],
              ],
            ),
            const SizedBox(width: 14),

            // Right Cluster: Actions & Export
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom Percentage Pill
                NeuButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: () => showManualZoomDialog(
                    context,
                    controller,
                    state.zoom,
                    settings.extendedZoomLimit,
                  ),
                  tooltip: 'Set Zoom Level (${(state.zoom * 100).toInt()}%)',
                  child: Text(
                    '${(state.zoom * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: tokens.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                if (isDesktop) ...[
                  // Dev Inspect Code Toggle
                  NeuIconButton(
                    icon: Icons.code_rounded,
                    size: 34,
                    iconSize: 16,
                    isActive: state.isDevInspectMode,
                    tooltip: 'Inspect Code (CSS / Flutter)',
                    onPressed: controller.toggleDevInspectMode,
                  ),
                  const SizedBox(width: 6),

                  // Animation Timeline Toggle
                  NeuIconButton(
                    icon: Icons.animation_rounded,
                    size: 34,
                    iconSize: 16,
                    isActive: state.showTimelinePanel,
                    tooltip: 'Toggle Animation Timeline',
                    onPressed: controller.toggleTimelinePanel,
                  ),
                  const SizedBox(width: 6),
                ],

                // Play Prototype Button
                NeuIconButton(
                  icon: Icons.play_arrow_rounded,
                  size: 34,
                  iconSize: 18,
                  tooltip: 'Play Interactive Prototype',
                  iconColor: FormaColors.successGreen,
                  onPressed: controller.togglePrototypePlay,
                ),
                const SizedBox(width: 6),

                // Theme Toggle Button (Instant Light / Dark toggle)
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

                // Studio Themes Switcher Button
                NeuIconButton(
                  icon: Icons.palette_outlined,
                  size: 34,
                  iconSize: 16,
                  iconColor: tokens.accent,
                  tooltip: 'Studio Themes (Light, Dark, Glass, Cosmic)',
                  onPressed: () => FormaThemePickerDialog.show(context),
                ),
                const SizedBox(width: 6),

                // Real-time Collaboration / Share Button
                _buildCollabButton(context, tokens, isDark, isDesktop),
                const SizedBox(width: 6),

                if (isDesktop) ...[
                  // Settings Button
                  NeuIconButton(
                    icon: Icons.settings_outlined,
                    size: 34,
                    iconSize: 16,
                    tooltip: 'Settings',
                    onPressed: () => _openSettings(context),
                  ),
                  const SizedBox(width: 6),

                  // Collapsible Right Sidebar (Properties) Toggle
                  NeuIconButton(
                    icon: Icons.view_sidebar_outlined,
                    size: 34,
                    iconSize: 16,
                    isActive: _rightSidebarOpen,
                    tooltip: _rightSidebarOpen ? 'Collapse Properties (Ctrl+])' : 'Expand Properties (Ctrl+])',
                    onPressed: () => setState(() => _rightSidebarOpen = !_rightSidebarOpen),
                  ),
                  const SizedBox(width: 8),
                ],

                // Export Button
                NeuButton(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  onPressed: () => _openExportDialog(context, state),
                  tooltip: 'Export Design (PNG, SVG, PDF, FIG)',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.file_download_outlined,
                        size: 15,
                        color: tokens.accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Export',
                        style: TextStyle(
                          color: tokens.textMain,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (tokens.isGlass && tokens.cardBlur > 0) {
      return ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: tokens.cardBlur, sigmaY: tokens.cardBlur),
          child: barContent,
        ),
      );
    }

    return barContent;
  }

  Widget _buildCollabButton(
    BuildContext context,
    FormaThemeTokens tokens,
    bool isDark,
    bool isDesktop,
  ) {
    final session = ref.watch(activeCollabSessionProvider);
    final collaborators = ref.watch(activeCollaboratorsProvider);
    final isConnected = session != null && session.isConnected;

    if (isConnected) {
      return Tooltip(
        message: 'Active Collab Room #${session.roomId} (${collaborators.length} online)',
        child: InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (_) => const CollabDialog(),
          ),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: tokens.accent.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tokens.accent.withValues(alpha: isDark ? 0.45 : 0.30),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Live glowing emerald presence pulse
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Live #${session.roomId}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: tokens.accent,
                  ),
                ),
                const SizedBox(width: 6),
                // Overlapping Avatar Circles
                if (collaborators.isNotEmpty) ...[
                  SizedBox(
                    height: 22,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < math.min(3, collaborators.length); i++) ...[
                          Align(
                            widthFactor: 0.72,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: collaborators[i].color,
                                shape: BoxShape.circle,
                                border: Border.all(color: tokens.surface, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  collaborators[i].initials,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (collaborators.length > 3) ...[
                          Align(
                            widthFactor: 0.72,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: tokens.textMuted,
                                shape: BoxShape.circle,
                                border: Border.all(color: tokens.surface, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  '+${collaborators.length - 3}',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return NeuButton(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 10 : 8, vertical: 6),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const CollabDialog(),
      ),
      tooltip: 'Real-time Live Collaboration & Room Sharing',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group_add_outlined,
            size: 15,
            color: tokens.accent,
          ),
          if (isDesktop) ...[
            const SizedBox(width: 5),
            Text(
              'Share',
              style: TextStyle(
                color: tokens.textMain,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// PC Desktop: Floating Bottom Canvas Toolbar with refined cards and micro-interactions
  Widget _buildDesktopFloatingToolbar(
    BuildContext context,
    dynamic state,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
    bool isGlass,
  ) {
    final settings = ref.watch(settingsProvider);

    final tools = <Widget>[
      _desktopToolButton(EditorTool.select, Icons.near_me_rounded, 'Select (V)', state, controller, tokens),
      _desktopToolButton(EditorTool.hand, Icons.pan_tool_rounded, 'Hand Pan (H)', state, controller, tokens),
      _desktopVerticalDivider(tokens),
      _desktopToolButton(EditorTool.frame, Icons.crop_free_rounded, 'Frame / Artboard (F)', state, controller, tokens),
      _desktopToolButton(EditorTool.rectangle, Icons.crop_square_rounded, 'Rectangle (R)', state, controller, tokens),
      _desktopToolButton(EditorTool.roundedRectangle, Icons.rectangle_rounded, 'Rounded Rect', state, controller, tokens),
      _desktopToolButton(EditorTool.ellipse, Icons.circle_outlined, 'Ellipse / Circle (O)', state, controller, tokens),
      _desktopToolButton(EditorTool.triangle, Icons.change_history_rounded, 'Triangle', state, controller, tokens),
      _desktopToolButton(EditorTool.polygon, Icons.hexagon_outlined, 'Polygon (5-sided)', state, controller, tokens),
      _desktopToolButton(EditorTool.star, Icons.star_border_rounded, 'Star', state, controller, tokens),
      _desktopToolButton(EditorTool.line, Icons.horizontal_rule_rounded, 'Line (L)', state, controller, tokens),
      _desktopToolButton(EditorTool.arrow, Icons.arrow_right_alt_rounded, 'Arrow', state, controller, tokens),
      _desktopToolButton(EditorTool.vectorPen, Icons.polyline_rounded, 'Vector Pen (P)', state, controller, tokens),
      _desktopToolButton(EditorTool.text, Icons.title_rounded, 'Text (T)', state, controller, tokens),
      _desktopToolButton(EditorTool.freehand, Icons.edit_outlined, 'Pencil Draw', state, controller, tokens),
      _desktopVerticalDivider(tokens),
      NeuIconButton(
        icon: Icons.image_outlined,
        size: 34,
        iconSize: 16,
        tooltip: 'Insert Image (PNG/JPG)',
        onPressed: () => _handleInsertImage(controller),
      ),
      const SizedBox(width: 4),
      NeuIconButton(
        icon: Icons.star_border_purple500_rounded,
        size: 34,
        iconSize: 16,
        iconColor: const Color(0xFF8B5CF6),
        tooltip: 'Open Icon Studio Arena',
        onPressed: () => IconEditorDialog.show(
          context,
          controller: controller,
          isDark: isDark,
        ),
      ),
      const SizedBox(width: 4),
      NeuIconButton(
        icon: Icons.file_open_outlined,
        size: 34,
        iconSize: 16,
        tooltip: 'Import SVG',
        onPressed: () => _handleImportSvg(controller),
      ),
      const SizedBox(width: 4),
      NeuIconButton(
        icon: Icons.html_rounded,
        size: 34,
        iconSize: 18,
        tooltip: 'Import HTML Layout',
        onPressed: () => _handleImportHtml(controller),
      ),
      const SizedBox(width: 4),
      NeuIconButton(
        icon: Icons.terminal_rounded,
        size: 34,
        iconSize: 16,
        tooltip: 'Command Palette (Ctrl+K)',
        onPressed: () => _openCommandPalette(context, controller, state),
      ),
    ];

    final row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tools,
      ),
    );

    if (isGlass) {
      return LiquidGlassBox(
        radius: 24,
        blur: settings.glassBlur,
        opacity: settings.glassOpacity,
        hasSpecular: settings.glassSpecular,
        hasSheen: settings.glassSheen,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: row,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: tokens.surface.withValues(alpha: isDark ? 0.90 : 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tokens.borderSubtle, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: row,
        ),
      ),
    );
  }

  Widget _desktopToolButton(
    EditorTool tool,
    IconData icon,
    String tooltip,
    dynamic state,
    EditorController controller,
    FormaThemeTokens tokens,
  ) {
    final isActive = state.activeTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 300),
        child: InkWell(
          onTap: () {
            if (tool == EditorTool.text && isActive) {
              final id = controller.insertTextAtViewportCenter();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final n = controller.currentState.project.nodes[id];
                if (n != null && mounted) {
                  CanvasViewport.showInPlaceTextEditor(context, n, controller);
                }
              });
              controller.setTool(EditorTool.select);
              return;
            }
            controller.setTool(tool);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isActive
                  ? tokens.accent.withValues(alpha: tokens.isDark ? 0.25 : 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(color: tokens.accent, width: 1.0)
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 16,
                color: isActive ? tokens.accent : tokens.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopVerticalDivider(FormaThemeTokens tokens) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: tokens.borderSubtle,
    );
  }

  /// Mobile: Contextual Selection Action Bar with min 44x44 thumb-friendly touch targets
  Widget _buildMobileSelectionActionBar(
    BuildContext context,
    dynamic state,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
  ) {
    final selectedIds = state.selectedNodeIds as Set<String>;
    if (selectedIds.isEmpty) return const SizedBox.shrink();

    final primaryNode = state.project.nodes[selectedIds.first];
    final fillColor = (primaryNode != null && primaryNode.fills.isNotEmpty)
        ? primaryNode.fills.first.color
        : tokens.accent;

    return Positioned(
      top: 10,
      left: 12,
      right: 12,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.surface.withValues(alpha: isDark ? 0.90 : 0.94),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: tokens.borderSubtle, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Prominent Delete Button (min 44x44 tap target)
                _buildMobileActionButton(
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFEF4444),
                  tooltip: 'Delete Selected',
                  onPressed: controller.deleteSelectedNodes,
                ),

                // Duplicate Button (min 44x44 tap target)
                _buildMobileActionButton(
                  icon: Icons.copy_rounded,
                  iconColor: tokens.textMain,
                  tooltip: 'Duplicate (Ctrl+D)',
                  onPressed: controller.duplicateSelectedNodes,
                ),

                // Color Swatch Button (min 44x44 tap target)
                InkWell(
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
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: fillColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: fillColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Image Mask Fill Button (min 44x44 tap target)
                _buildMobileActionButton(
                  icon: Icons.image_outlined,
                  iconColor: tokens.textMain,
                  tooltip: 'Apply Image Fill',
                  onPressed: () => _handleSetSelectedImageFill(controller),
                ),

                // Align Center Button (min 44x44 tap target)
                _buildMobileActionButton(
                  icon: Icons.align_horizontal_center_rounded,
                  iconColor: tokens.textMain,
                  tooltip: 'Align Center',
                  onPressed: () => controller.alignSelection('centerHorizontal'),
                ),

                // Bring Forward Button (min 44x44 tap target)
                _buildMobileActionButton(
                  icon: Icons.flip_to_front_rounded,
                  iconColor: tokens.textMain,
                  tooltip: 'Bring Forward',
                  onPressed: controller.bringForward,
                ),

                // Properties Sheet Toggle Button (min 44x44 tap target)
                _buildMobileActionButton(
                  icon: Icons.tune_rounded,
                  iconColor: tokens.accent,
                  tooltip: 'Open Properties Sheet',
                  onPressed: () {
                    setState(() {
                      _showPropertiesSheet = !_showPropertiesSheet;
                      _showLayersSheet = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildMobileActionButton({
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }

  /// Mobile: Floating Bottom Dock with generous min 44x44 tap targets
  Widget _buildMobileBottomDock(
    BuildContext context,
    dynamic state,
    EditorController controller,
    FormaThemeTokens tokens,
    bool isDark,
    bool isGlass,
  ) {
    final pageBg = state.project.getPage(state.activePageId)?.backgroundColor ?? Colors.white;

    final children = <Widget>[
      // Layers Toggle (min 44x44)
      _buildDockToolButton(
        icon: Icons.layers_outlined,
        tooltip: 'Layers Sheet',
        isActive: _showLayersSheet,
        tokens: tokens,
        onTap: () {
          setState(() {
            _showLayersSheet = !_showLayersSheet;
            _showPropertiesSheet = false;
          });
        },
      ),

      // Select Tool (min 44x44)
      _buildDockToolButton(
        icon: Icons.near_me_rounded,
        tooltip: 'Select (V)',
        isActive: state.activeTool == EditorTool.select,
        tokens: tokens,
        onTap: () => controller.setTool(EditorTool.select),
      ),

      // Shapes Menu (min 44x44)
      _buildDockToolButton(
        icon: Icons.category_rounded,
        tooltip: 'Shape Tools',
        isActive: false,
        tokens: tokens,
        onTap: () => _showMobileShapesMenu(context, controller, tokens),
      ),

      // Pen Tool (min 44x44)
      _buildDockToolButton(
        icon: Icons.polyline_rounded,
        tooltip: 'Vector Pen',
        isActive: state.activeTool == EditorTool.vectorPen,
        tokens: tokens,
        onTap: () => controller.setTool(EditorTool.vectorPen),
      ),

      // Text Menu (min 44x44)
      _buildDockToolButton(
        icon: Icons.title_rounded,
        tooltip: 'Text & Typography',
        isActive: state.activeTool == EditorTool.text,
        tokens: tokens,
        onTap: () => _showMobileTextMenu(context, controller, tokens),
      ),

      // Insert Image (min 44x44)
      _buildDockToolButton(
        icon: Icons.image_outlined,
        tooltip: 'Insert Image',
        isActive: false,
        tokens: tokens,
        onTap: () => _handleInsertImage(controller),
      ),

      // Canvas Background Color Picker (min 44x44 tap target)
      InkWell(
        onTap: () {
          final page = state.project.getPage(state.activePageId);
          if (page != null) {
            ColorPickerDialog.show(
              context,
              initialColor: page.backgroundColor,
              onColorChanged: (c) => controller.setPageBackgroundColor(c),
            );
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: pageBg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),

      // Pan Tool (min 44x44)
      _buildDockToolButton(
        icon: Icons.pan_tool_rounded,
        tooltip: 'Pan Canvas (H)',
        isActive: state.activeTool == EditorTool.hand,
        tokens: tokens,
        onTap: () => controller.setTool(EditorTool.hand),
      ),

      // Properties Toggle (min 44x44)
      _buildDockToolButton(
        icon: Icons.tune_rounded,
        tooltip: 'Properties Sheet',
        isActive: _showPropertiesSheet,
        tokens: tokens,
        onTap: () {
          setState(() {
            _showPropertiesSheet = !_showPropertiesSheet;
            _showLayersSheet = false;
          });
        },
      ),
    ];

    return Positioned(
      bottom: 14,
      left: 12,
      right: 12,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: tokens.borderSubtle, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockToolButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required FormaThemeTokens tokens,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive
                ? tokens.accent.withValues(alpha: tokens.isDark ? 0.25 : 0.15)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? tokens.accent : tokens.textMain,
          ),
        ),
      ),
    );
  }

  /// Mobile: Collapsible sliding bottom drawer sheet with drag handle (Never squishes canvas!)
  Widget _buildMobileSlidingSheet({
    required BuildContext context,
    required BoxConstraints constraints,
    required String title,
    required FormaThemeTokens tokens,
    required bool isDark,
    required VoidCallback onClose,
    required Widget child,
  }) {
    final sheetHeight = math.min(constraints.maxHeight * 0.72, 540.0);

    return Positioned.fill(
      child: Stack(
        children: [
          // Dimmed backdrop that taps to close
          GestureDetector(
            onTap: onClose,
            child: Container(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.25),
            ),
          ),

          // Sliding Bottom Sheet Container
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: sheetHeight,
            child: Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border.all(color: tokens.borderSubtle, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Tactile Drag Handle Area
                  GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta != null && details.primaryDelta! > 6) {
                        onClose();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: tokens.textMuted.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Header with Title & Close Action
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 8, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: tokens.accent,
                          ),
                        ),
                        // Min 44x44 touch target close button
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: Icon(Icons.close_rounded, size: 20, color: tokens.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: tokens.borderSubtle),

                  // Sheet Content
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileShapesMenu(
    BuildContext context,
    EditorController controller,
    FormaThemeTokens tokens,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: tokens.borderSubtle),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: tokens.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SHAPE TOOLS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: tokens.textMuted,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: tokens.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _shapeOption(ctx, controller, EditorTool.rectangle, Icons.crop_square_rounded, 'Rectangle', tokens),
                  _shapeOption(ctx, controller, EditorTool.roundedRectangle, Icons.rectangle_rounded, 'Rounded', tokens),
                  _shapeOption(ctx, controller, EditorTool.ellipse, Icons.circle_outlined, 'Circle', tokens),
                  _shapeOption(ctx, controller, EditorTool.triangle, Icons.change_history_rounded, 'Triangle', tokens),
                  _shapeOption(ctx, controller, EditorTool.polygon, Icons.hexagon_outlined, 'Polygon', tokens),
                  _shapeOption(ctx, controller, EditorTool.star, Icons.star_border_rounded, 'Star', tokens),
                  _shapeOption(ctx, controller, EditorTool.line, Icons.horizontal_rule_rounded, 'Line', tokens),
                  _shapeOption(ctx, controller, EditorTool.frame, Icons.crop_free_rounded, 'Frame', tokens),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shapeOption(
    BuildContext ctx,
    EditorController controller,
    EditorTool tool,
    IconData icon,
    String label,
    FormaThemeTokens tokens,
  ) {
    return InkWell(
      onTap: () {
        controller.setTool(tool);
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.accent.withValues(alpha: 0.20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: tokens.accent),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: tokens.textMain),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileTextMenu(
    BuildContext context,
    EditorController controller,
    FormaThemeTokens tokens,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: tokens.borderSubtle),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: tokens.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ADD TYPOGRAPHY & TEXT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: tokens.textMuted,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: tokens.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _textOptionCard(
                ctx,
                controller,
                title: 'Add a Heading',
                subtitle: 'Large, bold title for sections & headers (32px)',
                fontSize: 32.0,
                fontWeight: 700,
                icon: Icons.title_rounded,
                tokens: tokens,
              ),
              const SizedBox(height: 8),
              _textOptionCard(
                ctx,
                controller,
                title: 'Add a Subheading',
                subtitle: 'Medium, emphasized title for cards & groups (22px)',
                fontSize: 22.0,
                fontWeight: 600,
                icon: Icons.text_fields_rounded,
                tokens: tokens,
              ),
              const SizedBox(height: 8),
              _textOptionCard(
                ctx,
                controller,
                title: 'Add Body Text',
                subtitle: 'Standard paragraph font for general copy (16px)',
                fontSize: 16.0,
                fontWeight: 400,
                icon: Icons.short_text_rounded,
                tokens: tokens,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.accent,
                    side: BorderSide(color: tokens.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.touch_app_rounded, size: 18),
                  label: const Text('Tap Canvas to Draw Custom Box'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.setTool(EditorTool.text);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _textOptionCard(
    BuildContext ctx,
    EditorController controller, {
    required String title,
    required String subtitle,
    required double fontSize,
    required int fontWeight,
    required IconData icon,
    required FormaThemeTokens tokens,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        final id = controller.insertTextAtViewportCenter(
          initialText: title.replaceFirst('Add a ', '').replaceFirst('Add ', ''),
          fontSize: fontSize,
          fontWeight: fontWeight,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final n = controller.currentState.project.nodes[id];
          if (n != null && mounted) {
            CanvasViewport.showInPlaceTextEditor(context, n, controller);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.wellBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: tokens.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tokens.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: tokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, size: 18, color: tokens.accent),
          ],
        ),
      ),
    );
  }
}
