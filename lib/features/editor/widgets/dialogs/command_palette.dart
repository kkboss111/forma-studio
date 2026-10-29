import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/neumorphic.dart';
import '../../../../domain/models/node_types.dart';
import '../../../../domain/models/paint_styles.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/editor_state.dart';

class CommandItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String shortcut;
  final String category;
  final VoidCallback action;

  const CommandItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.shortcut,
    this.category = 'General',
    required this.action,
  });
}

class CommandPaletteDialog extends StatefulWidget {
  final EditorController controller;
  final VoidCallback onOpenExport;

  const CommandPaletteDialog({
    super.key,
    required this.controller,
    required this.onOpenExport,
  });

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';

  List<CommandItem> _getAllCommands() {
    final c = widget.controller;
    return [
      // 1. Tool Commands
      CommandItem(title: 'Select Tool', subtitle: 'Switch to selection mode', icon: Icons.near_me_rounded, shortcut: 'V', category: 'Tools', action: () => c.setTool(EditorTool.select)),
      CommandItem(title: 'Hand / Pan Tool', subtitle: 'Pan across infinite canvas', icon: Icons.pan_tool_rounded, shortcut: 'H', category: 'Tools', action: () => c.setTool(EditorTool.hand)),
      CommandItem(title: 'Frame Tool', subtitle: 'Draw responsive artboard frame', icon: Icons.crop_free_rounded, shortcut: 'F', category: 'Tools', action: () => c.setTool(EditorTool.frame)),
      CommandItem(title: 'Rectangle Tool', subtitle: 'Draw rectangle box', icon: Icons.crop_square_rounded, shortcut: 'R', category: 'Tools', action: () => c.setTool(EditorTool.rectangle)),
      CommandItem(title: 'Rounded Rectangle Tool', subtitle: 'Draw rounded corner rectangle', icon: Icons.rounded_corner_rounded, shortcut: 'U', category: 'Tools', action: () => c.setTool(EditorTool.roundedRectangle)),
      CommandItem(title: 'Triangle Tool', subtitle: 'Draw 3-corner triangle with fillet radius', icon: Icons.change_history_rounded, shortcut: 'Y', category: 'Tools', action: () => c.setTool(EditorTool.triangle)),
      CommandItem(title: 'Ellipse / Circle Tool', subtitle: 'Draw circle or oval shape', icon: Icons.circle_outlined, shortcut: 'O', category: 'Tools', action: () => c.setTool(EditorTool.ellipse)),
      CommandItem(title: 'Polygon Tool', subtitle: 'Draw regular multi-sided polygon (3-12 sides)', icon: Icons.hexagon_outlined, shortcut: 'Shift+P', category: 'Tools', action: () => c.setTool(EditorTool.polygon)),
      CommandItem(title: 'Star Tool', subtitle: 'Draw multi-point geometric star', icon: Icons.star_border_rounded, shortcut: 'S', category: 'Tools', action: () => c.setTool(EditorTool.star)),
      CommandItem(title: 'Vector Pen Tool', subtitle: 'Bézier curves & Drawn Layer drafting', icon: Icons.polyline_rounded, shortcut: 'P', category: 'Tools', action: () => c.setTool(EditorTool.vectorPen)),
      CommandItem(title: 'Text Tool', subtitle: 'Insert editable typography layer', icon: Icons.title_rounded, shortcut: 'T', category: 'Tools', action: () => c.setTool(EditorTool.text)),
      CommandItem(title: 'Line Tool', subtitle: 'Draw straight line segment', icon: Icons.horizontal_rule_rounded, shortcut: 'L', category: 'Tools', action: () => c.setTool(EditorTool.line)),
      CommandItem(title: 'Arrow Tool', subtitle: 'Draw directional arrow vector', icon: Icons.arrow_right_alt_rounded, shortcut: 'Shift+A', category: 'Tools', action: () => c.setTool(EditorTool.arrow)),
      CommandItem(title: 'Comment Pin Tool', subtitle: 'Leave feedback note on canvas', icon: Icons.chat_bubble_outline_rounded, shortcut: 'C', category: 'Tools', action: () => c.setTool(EditorTool.comment)),

      // 2. Insert Node Components
      CommandItem(title: 'Insert iPhone 15 Frame', subtitle: 'Standard Mobile 393 × 852', icon: Icons.smartphone_rounded, shortcut: 'Ctrl+1', category: 'Insert', action: () => c.createNode(type: NodeType.frame, rect: const Rect.fromLTWH(100, 100, 393, 852), name: 'iPhone 15 Frame')),
      CommandItem(title: 'Insert Android Tall Frame', subtitle: 'Mobile 412 × 923', icon: Icons.phone_android_rounded, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.frame, rect: const Rect.fromLTWH(100, 100, 412, 923), name: 'Android Tall Frame')),
      CommandItem(title: 'Insert iPad Tablet Frame', subtitle: 'Tablet 834 × 1194', icon: Icons.tablet_mac_rounded, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.frame, rect: const Rect.fromLTWH(100, 100, 834, 1194), name: 'iPad Pro Frame')),
      CommandItem(title: 'Insert Desktop FHD 1080p Frame', subtitle: 'Desktop 1920 × 1080', icon: Icons.desktop_windows_rounded, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.frame, rect: const Rect.fromLTWH(100, 100, 1920, 1080), name: 'Desktop FHD Frame')),
      CommandItem(title: 'Insert Square Post Frame', subtitle: 'Social 1080 × 1080 (1:1)', icon: Icons.square_outlined, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.frame, rect: const Rect.fromLTWH(100, 100, 1080, 1080), name: 'Square Artboard')),
      CommandItem(title: 'Insert Primary Button', subtitle: 'UI CTA button component', icon: Icons.smart_button_rounded, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.roundedRectangle, rect: const Rect.fromLTWH(100, 100, 180, 48), cornerRadii: const CornerRadii.all(12), fills: [DesignFill.solid(const Color(0xFF2563EB))], name: 'Primary Button')),
      CommandItem(title: 'Insert Secondary Outline Button', subtitle: 'Bordered button component', icon: Icons.crop_portrait_rounded, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.roundedRectangle, rect: const Rect.fromLTWH(100, 100, 180, 48), cornerRadii: const CornerRadii.all(12), fills: [DesignFill.solid(Colors.transparent)], strokes: [const DesignStroke(color: Color(0xFF2563EB), width: 1.5)], name: 'Outline Button')),
      CommandItem(title: 'Insert Input Field Container', subtitle: 'Text input card with border', icon: Icons.text_fields_rounded, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.roundedRectangle, rect: const Rect.fromLTWH(100, 100, 280, 52), cornerRadii: const CornerRadii.all(10), fills: [DesignFill.solid(const Color(0xFFF8FAFC))], strokes: [const DesignStroke(color: Color(0xFFCBD5E1), width: 1.0)], name: 'Input Field')),
      CommandItem(title: 'Insert Card Container', subtitle: 'Elevated UI card', icon: Icons.featured_play_list_outlined, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.roundedRectangle, rect: const Rect.fromLTWH(100, 100, 320, 200), cornerRadii: const CornerRadii.all(16), fills: [DesignFill.solid(Colors.white)], effects: const [DesignEffect(type: DesignEffectType.dropShadow, color: Color(0x1F000000), offsetY: 6, blurRadius: 16)], name: 'UI Card')),
      CommandItem(title: 'Insert Avatar Circle', subtitle: 'Circular image placeholder', icon: Icons.account_circle_outlined, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.ellipse, rect: const Rect.fromLTWH(100, 100, 64, 64), fills: [DesignFill.solid(const Color(0xFFE2E8F0))], name: 'Avatar')),
      CommandItem(title: 'Insert Divider Line', subtitle: 'Horizontal separator rule', icon: Icons.remove_rounded, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.line, rect: const Rect.fromLTWH(100, 100, 300, 2), strokes: [const DesignStroke(color: Color(0xFFE2E8F0), width: 1.0)], name: 'Divider')),
      CommandItem(title: 'Insert Hexagon', subtitle: '6-sided regular polygon', icon: Icons.hexagon_outlined, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.polygon, rect: const Rect.fromLTWH(100, 100, 140, 140), polygonSides: 6, name: 'Hexagon')),
      CommandItem(title: 'Insert Octagon', subtitle: '8-sided regular polygon', icon: Icons.stop_circle_outlined, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.polygon, rect: const Rect.fromLTWH(100, 100, 140, 140), polygonSides: 8, name: 'Octagon')),
      CommandItem(title: 'Insert Dodecagon', subtitle: '12-sided polygon', icon: Icons.circle_outlined, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.polygon, rect: const Rect.fromLTWH(100, 100, 150, 150), polygonSides: 12, name: 'Dodecagon')),
      CommandItem(title: 'Insert 5-Point Star', subtitle: 'Standard star vector', icon: Icons.star_border_rounded, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.star, rect: const Rect.fromLTWH(100, 100, 140, 140), starPoints: 5, name: '5-Star')),
      CommandItem(title: 'Insert 8-Point Star', subtitle: 'Badge star vector', icon: Icons.auto_awesome_outlined, shortcut: '', category: 'Insert', action: () => c.createNode(type: NodeType.star, rect: const Rect.fromLTWH(100, 100, 140, 140), starPoints: 8, name: '8-Star Badge')),

      // 3. Edit & Clipboard
      CommandItem(title: 'Undo', subtitle: 'Revert last action', icon: Icons.undo_rounded, shortcut: 'Ctrl+Z', category: 'Edit', action: c.undo),
      CommandItem(title: 'Redo', subtitle: 'Re-apply reverted action', icon: Icons.redo_rounded, shortcut: 'Ctrl+Y', category: 'Edit', action: c.redo),
      CommandItem(title: 'Copy Selection', subtitle: 'Copy shapes to global clipboard', icon: Icons.copy_rounded, shortcut: 'Ctrl+C', category: 'Edit', action: c.copySelection),
      CommandItem(title: 'Cut Selection', subtitle: 'Cut shapes to global clipboard', icon: Icons.cut_rounded, shortcut: 'Ctrl+X', category: 'Edit', action: c.cutSelection),
      CommandItem(title: 'Paste', subtitle: 'Paste shapes across canvases/pages', icon: Icons.paste_rounded, shortcut: 'Ctrl+V', category: 'Edit', action: c.paste),
      CommandItem(title: 'Duplicate Objects', subtitle: 'Clone selected layers inline', icon: Icons.content_copy_rounded, shortcut: 'Ctrl+D', category: 'Edit', action: c.duplicateSelectedNodes),
      CommandItem(title: 'Select All', subtitle: 'Select all nodes on current page', icon: Icons.select_all_rounded, shortcut: 'Ctrl+A', category: 'Edit', action: c.selectAll),
      CommandItem(title: 'Clear Selection', subtitle: 'Deselect all active layers', icon: Icons.deselect_rounded, shortcut: 'Esc', category: 'Edit', action: c.clearSelection),
      CommandItem(title: 'Delete Selected', subtitle: 'Remove selected layers from canvas', icon: Icons.delete_outline_rounded, shortcut: 'Del', category: 'Edit', action: c.deleteSelectedNodes),
      CommandItem(title: 'Group Selection', subtitle: 'Group selected nodes into container', icon: Icons.folder_outlined, shortcut: 'Ctrl+G', category: 'Edit', action: c.groupSelectedNodes),
      CommandItem(title: 'Ungroup Selection', subtitle: 'Dissolve group container', icon: Icons.folder_open_outlined, shortcut: 'Ctrl+Shift+G', category: 'Edit', action: c.ungroupSelectedNodes),
      CommandItem(title: 'New Windows Folder', subtitle: 'Create a new expandable folder group', icon: Icons.create_new_folder_outlined, shortcut: '', category: 'Edit', action: () => c.createNode(type: NodeType.group, rect: const Rect.fromLTWH(100, 100, 240, 240), name: 'New Folder')),

      // 4. Align & Arrange
      CommandItem(title: 'Align Left', subtitle: 'Align left edges', icon: Icons.align_horizontal_left_rounded, shortcut: 'Alt+A', category: 'Arrange', action: () => c.alignSelection('left')),
      CommandItem(title: 'Align Center Horizontal', subtitle: 'Align horizontal centers', icon: Icons.align_horizontal_center_rounded, shortcut: 'Alt+H', category: 'Arrange', action: () => c.alignSelection('centerHorizontal')),
      CommandItem(title: 'Align Right', subtitle: 'Align right edges', icon: Icons.align_horizontal_right_rounded, shortcut: 'Alt+D', category: 'Arrange', action: () => c.alignSelection('right')),
      CommandItem(title: 'Align Top', subtitle: 'Align top edges', icon: Icons.align_vertical_top_rounded, shortcut: 'Alt+W', category: 'Arrange', action: () => c.alignSelection('top')),
      CommandItem(title: 'Align Center Vertical', subtitle: 'Align vertical middles', icon: Icons.align_vertical_center_rounded, shortcut: 'Alt+V', category: 'Arrange', action: () => c.alignSelection('centerVertical')),
      CommandItem(title: 'Align Bottom', subtitle: 'Align bottom edges', icon: Icons.align_vertical_bottom_rounded, shortcut: 'Alt+S', category: 'Arrange', action: () => c.alignSelection('bottom')),
      CommandItem(title: 'Distribute Horizontally', subtitle: 'Even horizontal spacing', icon: Icons.horizontal_distribute_rounded, shortcut: '', category: 'Arrange', action: () => c.distributeSelection('horizontal')),
      CommandItem(title: 'Distribute Vertically', subtitle: 'Even vertical spacing', icon: Icons.vertical_distribute_rounded, shortcut: '', category: 'Arrange', action: () => c.distributeSelection('vertical')),
      CommandItem(title: 'Bring to Front', subtitle: 'Move layer to top of stacking order', icon: Icons.vertical_align_top_rounded, shortcut: 'Ctrl+]', category: 'Arrange', action: c.bringToFront),
      CommandItem(title: 'Bring Forward', subtitle: 'Move layer one step up', icon: Icons.arrow_upward_rounded, shortcut: ']', category: 'Arrange', action: c.bringForward),
      CommandItem(title: 'Send Backward', subtitle: 'Move layer one step down', icon: Icons.arrow_downward_rounded, shortcut: '[', category: 'Arrange', action: c.sendBackward),
      CommandItem(title: 'Send to Back', subtitle: 'Move layer to bottom of stack', icon: Icons.vertical_align_bottom_rounded, shortcut: 'Ctrl+[', category: 'Arrange', action: c.sendToBack),
      CommandItem(title: 'Flip Horizontal', subtitle: 'Mirror across vertical axis', icon: Icons.flip_rounded, shortcut: 'Shift+H', category: 'Arrange', action: c.flipHorizontalSelected),
      CommandItem(title: 'Flip Vertical', subtitle: 'Mirror across horizontal axis', icon: Icons.swap_vert_rounded, shortcut: 'Shift+V', category: 'Arrange', action: c.flipVerticalSelected),

      // 5. Canvas & View Controls
      CommandItem(title: 'Zoom to 100%', subtitle: 'Reset zoom to 1x pixel scale', icon: Icons.zoom_in_rounded, shortcut: 'Ctrl+0', category: 'View', action: c.zoom100),
      CommandItem(title: 'Zoom to Fit', subtitle: 'Fit all nodes in viewport', icon: Icons.fit_screen_rounded, shortcut: 'Shift+1', category: 'View', action: c.zoomToFit),
      CommandItem(title: 'Zoom In (+)', subtitle: 'Magnify viewport', icon: Icons.add_circle_outline_rounded, shortcut: 'Ctrl++', category: 'View', action: c.zoomIn),
      CommandItem(title: 'Zoom Out (-)', subtitle: 'Demagnify viewport', icon: Icons.remove_circle_outline_rounded, shortcut: 'Ctrl+-', category: 'View', action: c.zoomOut),
      CommandItem(title: 'Toggle Canvas Grid', subtitle: 'Show or hide pixel grid', icon: Icons.grid_4x4_rounded, shortcut: 'Ctrl+\'', category: 'View', action: () => c.setPageShowGrid(!widget.controller.currentState.project.getPage(widget.controller.currentState.activePageId)!.showGrid)),
      CommandItem(title: 'Toggle Snap to Grid', subtitle: 'Magnetic grid snapping', icon: Icons.grain_rounded, shortcut: 'Ctrl+Shift+\'', category: 'View', action: () => c.setPageSnapToGrid(!widget.controller.currentState.project.getPage(widget.controller.currentState.activePageId)!.snapToGrid)),
      CommandItem(title: 'Canvas Background: Pure White', subtitle: 'Set background to #FFFFFF', icon: Icons.format_paint_outlined, shortcut: '', category: 'View', action: () => c.setPageBackgroundColor(const Color(0xFFFFFFFF))),
      CommandItem(title: 'Canvas Background: Frosted Blue', subtitle: 'Set background to #F0F4FA', icon: Icons.format_paint_outlined, shortcut: '', category: 'View', action: () => c.setPageBackgroundColor(const Color(0xFFF0F4FA))),
      CommandItem(title: 'Canvas Background: Slate Dark', subtitle: 'Set background to #0F172A', icon: Icons.format_paint_outlined, shortcut: '', category: 'View', action: () => c.setPageBackgroundColor(const Color(0xFF0F172A))),
      CommandItem(title: 'Canvas Background: Midnight Black', subtitle: 'Set background to #000000', icon: Icons.format_paint_outlined, shortcut: '', category: 'View', action: () => c.setPageBackgroundColor(const Color(0xFF000000))),
      CommandItem(title: 'Canvas Background: Cyberpunk Violet', subtitle: 'Set background to #0A0014', icon: Icons.format_paint_outlined, shortcut: '', category: 'View', action: () => c.setPageBackgroundColor(const Color(0xFF0A0014))),

      // 6. Effects & Styling
      CommandItem(title: 'Add Drop Shadow', subtitle: 'Elevate with soft blur shadow', icon: Icons.wb_shade_rounded, shortcut: '', category: 'Effects', action: () => c.addDropShadowToSelected()),
      CommandItem(title: 'Add Outer Glow', subtitle: 'Radiate neon outer light glow', icon: Icons.flare_rounded, shortcut: '', category: 'Effects', action: () => c.addOuterGlowToSelected()),
      CommandItem(title: 'Add Layer Blur', subtitle: 'Defocus layer with gaussian blur', icon: Icons.blur_on_rounded, shortcut: '', category: 'Effects', action: () => c.addBlurToSelected()),
      CommandItem(title: 'Add Frosted Glass Backdrop Blur', subtitle: 'Blur artwork beneath element', icon: Icons.blur_circular_rounded, shortcut: '', category: 'Effects', action: () => c.addBackdropBlurToSelected()),
      CommandItem(title: 'Toggle Dev Inspector Panel', subtitle: 'Inspect Flutter and CSS source code', icon: Icons.code_rounded, shortcut: 'Alt+I', category: 'Inspect', action: c.toggleDevInspectMode),
      CommandItem(title: 'Play Interactive Prototype', subtitle: 'Full-screen gesture prototype simulation', icon: Icons.play_arrow_rounded, shortcut: 'Alt+P', category: 'Inspect', action: c.togglePrototypePlay),
      CommandItem(title: 'Timeline Animation Panel', subtitle: 'Open subframe motion keyframing studio', icon: Icons.animation_rounded, shortcut: 'Alt+M', category: 'Animation', action: c.toggleTimelinePanel),

      // 7. Motion & Animation Presets
      CommandItem(title: 'Motion: Spin 360°', subtitle: '2-second continuous rotational loop', icon: Icons.rotate_right_rounded, shortcut: 'Shift+R', category: 'Animation', action: () => c.addQuickMotionPreset('spin')),
      CommandItem(title: 'Motion: Slide Right', subtitle: '1.5-second horizontal translation', icon: Icons.trending_flat_rounded, shortcut: 'Shift+S', category: 'Animation', action: () => c.addQuickMotionPreset('moveRight')),
      CommandItem(title: 'Motion: Bounce Drop', subtitle: 'Physical bounce impact curve', icon: Icons.sports_basketball_rounded, shortcut: 'Shift+B', category: 'Animation', action: () => c.addQuickMotionPreset('bounce')),
      CommandItem(title: 'Motion: Pop & Spring', subtitle: 'Elastic scale popping entrance', icon: Icons.open_in_full_rounded, shortcut: 'Shift+P', category: 'Animation', action: () => c.addQuickMotionPreset('pop')),
      CommandItem(title: 'Motion: Pulse Heartbeat', subtitle: 'Continuous scale pulsing loop', icon: Icons.favorite_rounded, shortcut: '', category: 'Animation', action: () => c.addQuickMotionPreset('pulse')),
      CommandItem(title: 'Motion: Slide Up', subtitle: 'Entrance glide upward with fade', icon: Icons.arrow_upward_rounded, shortcut: 'Shift+U', category: 'Animation', action: () => c.addQuickMotionPreset('slideUp')),
      CommandItem(title: 'Motion: Slide Down', subtitle: 'Entrance glide downward', icon: Icons.arrow_downward_rounded, shortcut: 'Shift+D', category: 'Animation', action: () => c.addQuickMotionPreset('slideDown')),
      CommandItem(title: 'Motion: Wobble Shake', subtitle: 'Rotational wobble shake alert', icon: Icons.vibration_rounded, shortcut: '', category: 'Animation', action: () => c.addQuickMotionPreset('wobble')),
      CommandItem(title: 'Motion: Float Hover', subtitle: 'Gentle sine wave floating hover', icon: Icons.cloud_outlined, shortcut: '', category: 'Animation', action: () => c.addQuickMotionPreset('float')),
      CommandItem(title: 'Motion: Neon Strobe', subtitle: 'Cyberpunk opacity pulse', icon: Icons.flash_on_rounded, shortcut: '', category: 'Animation', action: () => c.addQuickMotionPreset('strobe')),
      CommandItem(title: 'Motion: Planetary Orbit', subtitle: 'Smooth circular orbit around anchor', icon: Icons.track_changes_rounded, shortcut: '', category: 'Animation', action: () => c.addQuickMotionPreset('orbit')),

      // 8. Export Matrix Commands
      CommandItem(title: 'Export Document / Frame Dialog', subtitle: 'Open multi-format export studio', icon: Icons.file_download_outlined, shortcut: 'Ctrl+E', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export SVG Vector', subtitle: 'Scalable vector XML with recursive tree', icon: Icons.code_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export High-Res PNG @1x', subtitle: 'Crisp raster export at 1x resolution', icon: Icons.image_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export High-Res PNG @2x Retina', subtitle: 'High-DPI 2x pixel density export', icon: Icons.photo_size_select_actual_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export High-Res PNG @3x UHD', subtitle: 'Ultra-DPI 3x print density export', icon: Icons.hd_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export PDF Document', subtitle: 'High quality vector PDF page', icon: Icons.picture_as_pdf_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export Flutter Dart Code', subtitle: 'Production-ready Flutter CustomPaint widgets', icon: Icons.flutter_dash_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export HTML5 & CSS3', subtitle: 'Responsive CSS flexbox & gradient markup', icon: Icons.html_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export Figma (.fig) Bundle', subtitle: 'Universal Figma schema compatible ZIP', icon: Icons.folder_zip_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export Sketch (.sketch) Bundle', subtitle: 'Universal Sketch schema compatible ZIP', icon: Icons.folder_zip_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export Adobe XD Bundle', subtitle: 'Universal Adobe XD schema compatible ZIP', icon: Icons.folder_zip_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export AutoCAD DXF', subtitle: 'CAD vector lines and polygons', icon: Icons.architecture_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),
      CommandItem(title: 'Export PostScript EPS Vector', subtitle: 'Print-ready PostScript coordinate curves', icon: Icons.print_rounded, shortcut: '', category: 'Export', action: widget.onOpenExport),

      // 9. PC & Windows Native App Commands
      if (!kIsWeb) ...[
        CommandItem(
          title: 'PC: System Memory Garbage Collection',
          subtitle: 'Free cached image buffers & run garbage collection',
          icon: Icons.cleaning_services_rounded,
          shortcut: 'Ctrl+Shift+Del',
          category: 'PC Native',
          action: () {
            PaintingBinding.instance.imageCache.clear();
            PaintingBinding.instance.imageCache.clearLiveImages();
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text('Memory cache cleaned & freed successfully!')),
            );
          },
        ),
        CommandItem(
          title: 'PC: Copy Project Raw JSON to Clipboard',
          subtitle: 'Copy full serialized project JSON to Windows clipboard',
          icon: Icons.data_object_rounded,
          shortcut: 'Ctrl+Shift+C',
          category: 'PC Native',
          action: () {
            Clipboard.setData(ClipboardData(text: jsonEncode(widget.controller.currentState.project.toJson())));
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text('Project JSON copied to Windows clipboard!')),
            );
          },
        ),
        CommandItem(
          title: 'PC: Save Project State Immediately',
          subtitle: 'Flush all pending autosaves to persistent disk',
          icon: Icons.save_rounded,
          shortcut: 'Ctrl+S',
          category: 'PC Native',
          action: () {
            c.saveNow();
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              const SnackBar(content: Text('Project saved immediately to local disk.')),
            );
          },
        ),
        CommandItem(
          title: 'PC: Reset Zoom to 100% & Pan to Center',
          subtitle: 'Reset camera coordinates to (0, 0)',
          icon: Icons.center_focus_strong_rounded,
          shortcut: 'F5',
          category: 'PC Native',
          action: () {
            c.zoom100();
            c.panDelta(-widget.controller.currentState.panOffset);
          },
        ),
        CommandItem(
          title: 'PC: Windows Hardware Diagnostics',
          subtitle: 'Show screen resolution, DPR and refresh rate info',
          icon: Icons.memory_rounded,
          shortcut: 'F12',
          category: 'PC Native',
          action: () {
            final dpr = MediaQuery.of(context).devicePixelRatio;
            final size = MediaQuery.of(context).size;
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('PC Hardware Diagnostics'),
                content: Text('Screen: ${size.width.toInt()} × ${size.height.toInt()} px\nDevice Pixel Ratio: ${dpr}x\nTarget Platform: Windows Desktop\nEngine: Flutter Impeller/Skia Vector Engine'),
                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
              ),
            );
          },
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final all = _getAllCommands();
    final filtered = _filter.isEmpty
        ? all
        : all
              .where(
                (item) =>
                    item.title.toLowerCase().contains(_filter.toLowerCase()) ||
                    item.subtitle.toLowerCase().contains(_filter.toLowerCase()),
              )
              .toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.only(
        top: math.min(80.0, screenHeight * 0.1),
        left: 16,
        right: 16,
      ),
      child: NeuCard(
        width: math.min(screenWidth - 32, 480),
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuTextField(
              controller: _searchCtrl,
              hintText:
                  'Type a command or search action (e.g. Export, Frame)...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: FormaColors.primaryBlue,
              ),
              autofocus: true,
              onChanged: (text) => setState(() => _filter = text),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No commands matching your search',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final cmd = filtered[index];
                        return ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(
                            cmd.icon,
                            size: 18,
                            color: FormaColors.primaryBlue,
                          ),
                          title: Text(
                            cmd.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            cmd.subtitle,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: (cmd.shortcut.isNotEmpty || cmd.category.isNotEmpty)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF283140)
                                        : const Color(0xFFDFE6F0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    cmd.shortcut.isNotEmpty ? cmd.shortcut : cmd.category,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.of(context).pop();
                            cmd.action();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
