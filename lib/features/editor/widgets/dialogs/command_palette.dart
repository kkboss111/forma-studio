import 'package:flutter/material.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../app/theme/neumorphic.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/editor_state.dart';

class CommandItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String shortcut;
  final VoidCallback action;

  const CommandItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.shortcut,
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
      CommandItem(
        title: 'Select Tool',
        subtitle: 'Switch to selection mode',
        icon: Icons.near_me_rounded,
        shortcut: 'V',
        action: () => c.setTool(EditorTool.select),
      ),
      CommandItem(
        title: 'Draw Frame',
        subtitle: 'Create a responsive device frame',
        icon: Icons.crop_free_rounded,
        shortcut: 'F',
        action: () => c.setTool(EditorTool.frame),
      ),
      CommandItem(
        title: 'Draw Rectangle',
        subtitle: 'Create a rectangle shape',
        icon: Icons.crop_square_rounded,
        shortcut: 'R',
        action: () => c.setTool(EditorTool.rectangle),
      ),
      CommandItem(
        title: 'Draw Ellipse',
        subtitle: 'Create an oval or circle',
        icon: Icons.circle_outlined,
        shortcut: 'O',
        action: () => c.setTool(EditorTool.ellipse),
      ),
      CommandItem(
        title: 'Add Text',
        subtitle: 'Insert typography layer',
        icon: Icons.title_rounded,
        shortcut: 'T',
        action: () => c.setTool(EditorTool.text),
      ),
      CommandItem(
        title: 'Group Selection',
        subtitle: 'Group selected nodes into container',
        icon: Icons.folder_outlined,
        shortcut: 'Ctrl+G',
        action: c.groupSelectedNodes,
      ),
      CommandItem(
        title: 'Ungroup Selection',
        subtitle: 'Dissolve group container',
        icon: Icons.folder_open_outlined,
        shortcut: 'Ctrl+Shift+G',
        action: c.ungroupSelectedNodes,
      ),
      CommandItem(
        title: 'Duplicate Objects',
        subtitle: 'Clone selected layers',
        icon: Icons.copy_rounded,
        shortcut: 'Ctrl+D',
        action: c.duplicateSelectedNodes,
      ),
      CommandItem(
        title: 'Delete Selected',
        subtitle: 'Remove selected layers from canvas',
        icon: Icons.delete_outline_rounded,
        shortcut: 'Del',
        action: c.deleteSelectedNodes,
      ),
      CommandItem(
        title: 'Zoom to 100%',
        subtitle: 'Reset zoom to default 1x scale',
        icon: Icons.zoom_in_rounded,
        shortcut: 'Ctrl+0',
        action: c.zoom100,
      ),
      CommandItem(
        title: 'Zoom to Fit',
        subtitle: 'Fit entire artboard onto screen',
        icon: Icons.fit_screen_rounded,
        shortcut: 'Shift+1',
        action: c.zoomToFit,
      ),
      CommandItem(
        title: 'Toggle Dev Inspector',
        subtitle: 'View live CSS and Flutter widget code',
        icon: Icons.code_rounded,
        shortcut: 'Alt+I',
        action: c.toggleDevInspectMode,
      ),
      CommandItem(
        title: 'Play Interactive Prototype',
        subtitle: 'Launch full prototype simulation',
        icon: Icons.play_arrow_rounded,
        shortcut: 'Alt+P',
        action: c.togglePrototypePlay,
      ),
      CommandItem(
        title: 'Export Document / Frame',
        subtitle: 'Export to PNG, SVG, PDF or Forma native',
        icon: Icons.file_download_outlined,
        shortcut: 'Ctrl+E',
        action: widget.onOpenExport,
      ),
      CommandItem(
        title: 'Timeline Animation Panel',
        subtitle: 'Open motion keyframing timeline',
        icon: Icons.animation_rounded,
        shortcut: 'Alt+M',
        action: c.toggleTimelinePanel,
      ),
      CommandItem(
        title: 'Quick Motion: Spin 360°',
        subtitle: 'Apply 2-second continuous rotation',
        icon: Icons.rotate_right_rounded,
        shortcut: 'Shift+R',
        action: () => c.addQuickMotionPreset('spin'),
      ),
      CommandItem(
        title: 'Quick Motion: Slide Right',
        subtitle: 'Apply 1.5-second horizontal translation',
        icon: Icons.trending_flat_rounded,
        shortcut: 'Shift+S',
        action: () => c.addQuickMotionPreset('moveRight'),
      ),
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

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
      child: NeuCard(
        width: 480,
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
                          trailing: Container(
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
                              cmd.shortcut,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
