import 'package:flutter/material.dart';
import '../../../../app/theme/forma_theme.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../domain/models/editor_tab_model.dart';

/// A sleek horizontal tab bar positioned directly above the canvas viewport.
/// Supports switching between the main infinite canvas and dedicated bounded icon studio canvases.
class EditorTabBar extends StatefulWidget {
  /// All currently open editor tabs.
  final List<EditorTab> tabs;

  /// ID of the currently active tab.
  final String activeTabId;

  /// Callback when user selects a tab.
  final ValueChanged<EditorTab> onTabSelected;

  /// Callback when user clicks the close (x) button on a closable tab.
  final ValueChanged<EditorTab>? onTabClosed;

  /// Callback to create a new icon canvas with default (24x24) size.
  final VoidCallback? onNewIconCanvas;

  /// Callback to create a new icon canvas with a chosen preset size.
  final void Function(double iconSize)? onNewIconCanvasWithSize;

  /// Optional callback when a tab is renamed.
  final ValueChanged<EditorTab>? onTabRenamed;

  const EditorTabBar({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.onTabSelected,
    this.onTabClosed,
    this.onNewIconCanvas,
    this.onNewIconCanvasWithSize,
    this.onTabRenamed,
  });

  @override
  State<EditorTabBar> createState() => _EditorTabBarState();
}

class _EditorTabBarState extends State<EditorTabBar> {
  final ScrollController _scrollController = ScrollController();

  static const List<double> _presetSizes = [16, 24, 32, 48, 64, 128];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showRenameDialog(BuildContext context, EditorTab tab) {
    final controller = TextEditingController(text: tab.title);
    showDialog(
      context: context,
      builder: (ctx) {
        final tokens = FormaTheme.tokensOf(ctx);
        return AlertDialog(
          backgroundColor: tokens.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tokens.border),
          ),
          title: Text(
            'Rename Canvas Tab',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: tokens.textMain,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: tokens.textMain, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Tab Title',
              labelStyle: TextStyle(color: tokens.textMuted),
              filled: true,
              fillColor: tokens.wellBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.accent, width: 1.5),
              ),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                widget.onTabRenamed?.call(tab.copyWith(title: val.trim()));
                Navigator.pop(ctx);
              }
            },
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  widget.onTabRenamed?.call(tab.copyWith(title: controller.text.trim()));
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = FormaTheme.tokensOf(context);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: tokens.wellBg.withValues(alpha: tokens.isDark ? 0.7 : 0.85),
        border: Border(
          bottom: BorderSide(color: tokens.borderSubtle, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Left side: Horizontal scrollable tab strip
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thickness: 2.0,
              radius: const Radius.circular(2),
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                itemCount: widget.tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final tab = widget.tabs[index];
                  final isActive = tab.id == widget.activeTabId;
                  return _buildTabItem(context, tab, isActive, tokens);
                },
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: tokens.borderSubtle,
          ),

          // Right side: "+ New Icon Canvas" button with dropdown presets
          _buildNewIconCanvasButton(context, tokens),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    BuildContext context,
    EditorTab tab,
    bool isActive,
    FormaThemeTokens tokens,
  ) {
    final isIcon = tab.isIconCanvas;
    final leadIcon = isIcon
        ? Icons.draw_rounded
        : Icons.dashboard_customize_outlined;

    return Tooltip(
      message: '${tab.title}${isIcon ? ' (${tab.iconSize.toInt()}x${tab.iconSize.toInt()} Bounded Canvas)' : ' (Infinite Canvas)'}\nDouble-tap to rename',
      waitDuration: const Duration(milliseconds: 600),
      child: GestureDetector(
        onTap: () => widget.onTabSelected(tab),
        onDoubleTap: () => _showRenameDialog(context, tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? tokens.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? tokens.border
                  : Colors.transparent,
              width: 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: tokens.isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : FormaColors.lightShadowDark,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tab Type Icon
              Icon(
                leadIcon,
                size: 14,
                color: isActive
                    ? (isIcon ? FormaColors.componentPurple : tokens.accent)
                    : tokens.textMuted,
              ),
              const SizedBox(width: 6),

              // Title
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  tab.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? tokens.textMain : tokens.textMuted,
                    letterSpacing: -0.1,
                  ),
                ),
              ),

              // Size Tag badge (for icon canvases)
              if (isIcon) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? tokens.accent.withValues(alpha: 0.12)
                        : tokens.wellBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive
                          ? tokens.accent.withValues(alpha: 0.25)
                          : tokens.borderSubtle,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    '${tab.iconSize.toInt()}px',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isActive ? tokens.accent : tokens.textMuted,
                    ),
                  ),
                ),
              ],

              // Modified dot indicator
              if (tab.isModified) ...[
                const SizedBox(width: 5),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: tokens.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],

              // Close button (x)
              if (tab.isClosable && widget.onTabClosed != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => widget.onTabClosed!(tab),
                  borderRadius: BorderRadius.circular(4),
                  hoverColor: tokens.isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: isActive ? tokens.textMuted : tokens.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewIconCanvasButton(
    BuildContext context,
    FormaThemeTokens tokens,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: PopupMenuButton<double>(
        tooltip: 'New Icon Studio Canvas',
        offset: const Offset(0, 34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.border),
        ),
        color: tokens.surface,
        onSelected: (size) {
          if (widget.onNewIconCanvasWithSize != null) {
            widget.onNewIconCanvasWithSize!(size);
          } else {
            widget.onNewIconCanvas?.call();
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem<double>(
            enabled: false,
            height: 28,
            child: Text(
              'NEW ICON CANVAS PRESET',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
                color: tokens.textMuted,
              ),
            ),
          ),
          ..._presetSizes.map(
            (sz) => PopupMenuItem<double>(
              value: sz,
              height: 36,
              child: Row(
                children: [
                  Icon(
                    Icons.crop_square_rounded,
                    size: 16,
                    color: sz == 24 ? tokens.accent : tokens.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${sz.toInt()} x ${sz.toInt()} px',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: sz == 24 ? FontWeight.bold : FontWeight.w500,
                      color: tokens.textMain,
                    ),
                  ),
                  if (sz == 24) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: tokens.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Standard',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: tokens.accent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tokens.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_rounded,
                size: 15,
                color: tokens.accent,
              ),
              const SizedBox(width: 4),
              Text(
                'New Icon Canvas',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textMain,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 15,
                color: tokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
