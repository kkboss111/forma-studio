import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../app/theme/forma_colors.dart';
import '../../../app/theme/forma_theme.dart';
import '../../../app/theme/neumorphic.dart';
import '../../../app/theme/liquid_glass.dart';
import '../../../app/widgets/forma_logo.dart';
import '../../../app/widgets/forma_ambient_backdrop.dart';
import '../../../core/export/file_saver_service.dart';
import '../../../core/persistence/project_repository.dart';
import '../../../domain/models/project_model.dart';
import '../models/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const SettingsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late int _selectedTabIndex;
  final ProjectRepository _projectRepository = ProjectRepository();

  int _totalProjectsCount = 0;
  int _totalProjectsBytes = 0;
  bool _isLoadingStats = true;

  final List<String> _dockItems = [
    'Layers Panel Button',
    'Selection Tool (V)',
    'Shapes Menu (Rect, Circle, Triangle)',
    'Vector Pen & Drawn Layer (P)',
    'Text Typography Tool (T)',
    'Image Insertion Tool',
    'Canvas Background Swatch',
    'Pan & Hand Navigation Tool (H)',
    'Properties Panel Button',
  ];

  final List<String> _tabs = [
    'Appearance',
    'Editor & Canvas',
    'Performance',
    'Storage & Backup',
    'Advanced',
    'Shortcuts',
    'About',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, _tabs.length - 1);
    _loadStorageStats();
  }

  Future<void> _loadStorageStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final projects = await _projectRepository.listProjects();
      int bytes = 0;
      final enc = Encoding.getByName('utf-8')!;
      for (final p in projects) {
        final jsonStr = jsonEncode(p.toJson());
        bytes += enc.encode(jsonStr).length;
      }
      if (mounted) {
        setState(() {
          _totalProjectsCount = projects.length;
          _totalProjectsBytes = bytes;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _handleThemeSelection(
    FormaThemeMode mode,
    AppSettings settings,
    SettingsNotifier notifier,
  ) async {
    if (mode == settings.themeMode) return;

    if (mode == FormaThemeMode.liquidGlass) {
      final pin = await _showPasscodeDialog(
        context,
        'Liquid Glass Passcode',
        'Liquid Glass Mode',
      );
      if (pin == '1111') {
        notifier.setThemeMode(FormaThemeMode.liquidGlass);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passcode verified! Liquid Glass Mode activated.'),
              backgroundColor: FormaColors.successGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (pin != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect passcode. Please enter the valid security PIN.'),
              backgroundColor: FormaColors.dangerRed,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } else if (mode == FormaThemeMode.glassmorphism) {
      notifier.setThemeMode(FormaThemeMode.glassmorphism);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Glassmorphism Cosmic Theme activated! ✨'),
            backgroundColor: FormaColors.primaryBlue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      notifier.setThemeMode(mode);
    }
  }

  Future<String?> _showPasscodeDialog(
    BuildContext context,
    String title,
    String targetMode,
  ) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: FormaColors.primaryBlue),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 4-digit security PIN to activate $targetMode:',
              style: const TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) => Navigator.of(ctx).pop(val),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text(
              'Verify PIN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFullBackup() async {
    try {
      final projects = await _projectRepository.listProjects();
      final backupMap = {
        'format': 'forma_backup_archive',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'projectCount': projects.length,
        'projects': projects.map((p) => p.toJson()).toList(),
      };
      final jsonStr = jsonEncode(backupMap);
      final bytes = Uint8List.fromList(
        Encoding.getByName('utf-8')!.encode(jsonStr),
      );
      final filename =
          'forma_backup_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first}.forma';

      final success = await FileSaverService.saveFile(
        bytes: bytes,
        filename: filename,
        mimeType: 'application/json',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Full backup exported (${projects.length} projects, ${FileSaverService.formatFileSize(bytes.length)}).',
              ),
              backgroundColor: FormaColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export backup: $e'),
            backgroundColor: FormaColors.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackupFromFile() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['forma', 'json'],
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final rawStr = Encoding.getByName('utf-8')!.decode(bytes);
        final decoded = jsonDecode(rawStr);

        int restoredCount = 0;
        if (decoded is Map<String, dynamic>) {
          if (decoded['projects'] is List) {
            final list = decoded['projects'] as List;
            for (final item in list) {
              if (item is Map<String, dynamic>) {
                final project = ProjectModel.fromJson(item);
                await _projectRepository.saveProject(project);
                restoredCount++;
              }
            }
          } else if (decoded.containsKey('pages')) {
            // Single project file
            final project = ProjectModel.fromJson(decoded);
            await _projectRepository.saveProject(project);
            restoredCount = 1;
          }
        }

        await _loadStorageStats();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully restored $restoredCount project(s).'),
              backgroundColor: FormaColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore backup: $e'),
            backgroundColor: FormaColors.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _clearAppCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear App Cache?'),
        content: const Text(
          'This will purge rendered vector image caches and layout calculation buffers. Your saved projects will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await _loadStorageStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('App cache cleared successfully.'),
            backgroundColor: FormaColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isSystemDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = FormaTheme.tokensForMode(settings.themeMode, isSystemDark: isSystemDark);
    final isGlass = tokens.isGlass;
    final isDark = tokens.isDark;

    final bgColor = isGlass
        ? null
        : (isDark ? FormaColors.darkBg : FormaColors.lightBg);

    Widget content = Scaffold(
      backgroundColor: bgColor ?? Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (MediaQuery.of(context).size.width >= 500)
            TextButton.icon(
              onPressed: () {
                notifier.resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: const Text('Reset Defaults'),
            )
          else
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: 'Reset Defaults',
              onPressed: () {
                notifier.resetToDefaults();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to defaults.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;

          if (isWide) {
            return Row(
              children: [
                // Left Navigation Rail
                Container(
                  width: 220,
                  margin: const EdgeInsets.only(left: 16, bottom: 16),
                  child: isGlass
                      ? LiquidGlassBox(
                          radius: 20,
                          blur: settings.glassBlur,
                          opacity: settings.glassOpacity,
                          hasSpecular: settings.glassSpecular,
                          hasSheen: settings.glassSheen,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 10,
                          ),
                          child: _buildNavigationList(isDark, isGlass),
                        )
                      : NeuCard(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 10,
                          ),
                          child: _buildNavigationList(isDark, isGlass),
                        ),
                ),
                // Right Detail Area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 12,
                      right: 16,
                      bottom: 16,
                    ),
                    child: _buildActiveTabContent(
                      settings,
                      notifier,
                      isDark,
                      isGlass,
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Mobile Tabbed Column
            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedTabIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_tabs[index]),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedTabIndex = index),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _buildActiveTabContent(
                      settings,
                      notifier,
                      isDark,
                      isGlass,
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );

    return FormaAmbientBackdrop(explicitTokens: tokens, child: content);
  }

  Widget _buildNavigationList(bool isDark, bool isGlass) {
    return ListView.builder(
      itemCount: _tabs.length,
      itemBuilder: (context, index) {
        final isSelected = _selectedTabIndex == index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            selected: isSelected,
            selectedTileColor: isGlass
                ? LiquidGlassTheme.accentBlue.withValues(alpha: 0.2)
                : (isDark
                    ? FormaColors.primaryBlue.withValues(alpha: 0.25)
                    : FormaColors.primaryBlue.withValues(alpha: 0.1)),
            title: Text(
              _tabs[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : FormaColors.primaryBlue)
                    : (isDark
                        ? FormaColors.darkTextMuted
                        : FormaColors.lightTextMuted),
              ),
            ),
            onTap: () => setState(() => _selectedTabIndex = index),
          ),
        );
      },
    );
  }

  Widget _buildConfigCard({
    required String title,
    String? subtitle,
    IconData? icon,
    required List<Widget> children,
    required bool isDark,
    bool isGlass = false,
    EdgeInsetsGeometry? padding,
  }) {
    final tokens = FormaTheme.tokensOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isGlass
            ? tokens.surface
            : (isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: FormaColors.primaryBlue),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : FormaColors.lightTextMain,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark,
    bool isGlass,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAppearanceTab(settings, notifier, isDark, isGlass);
      case 1:
        return _buildEditorCanvasTab(settings, notifier, isDark, isGlass);
      case 2:
        return _buildPerformanceTab(settings, notifier, isDark, isGlass);
      case 3:
        return _buildStorageBackupTab(settings, notifier, isDark, isGlass);
      case 4:
        return _buildAdvancedTab(settings, notifier, isDark, isGlass);
      case 5:
        return _buildShortcutsTab(isDark, isGlass);
      case 6:
        return _buildAboutTab(isDark, isGlass);
      default:
        return const SizedBox();
    }
  }

  // 1. Appearance Tab
  Widget _buildAppearanceTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark, [
    bool isGlass = false,
  ]) {
    return ListView(
      children: [
        _buildConfigCard(
          title: 'Theme & Visual Identity',
          subtitle: 'Select active canvas aesthetic, color tokens, and elevation model',
          icon: Icons.palette_outlined,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            Column(
              children: FormaThemeMode.values.map((mode) {
                final isSelected = settings.themeMode == mode;
                String label;
                String desc;
                IconData icon;
                switch (mode) {
                  case FormaThemeMode.system:
                    label = 'System Default';
                    desc = 'Syncs automatically with device system appearance';
                    icon = Icons.brightness_auto_rounded;
                    break;
                  case FormaThemeMode.light:
                    label = 'Soft Neumorphic Light';
                    desc = 'Warm paper craft & crisp contrast tokens';
                    icon = Icons.light_mode_rounded;
                    break;
                  case FormaThemeMode.dark:
                    label = 'Deep Slate Dark';
                    desc = 'Obsidian palette with deep slate tones';
                    icon = Icons.dark_mode_rounded;
                    break;
                  case FormaThemeMode.liquidGlass:
                    label = 'Liquid Glass';
                    desc = 'Real-time backdrop blur & specular sheen';
                    icon = Icons.blur_on_rounded;
                    break;
                  case FormaThemeMode.glassmorphism:
                    label = 'Glassmorphism (CSS Showcase)';
                    desc = 'Dynamic cosmic blur gradients & glow accents';
                    icon = Icons.auto_awesome_rounded;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _handleThemeSelection(mode, settings, notifier),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? FormaColors.primaryBlue
                              : (isDark ? Colors.white12 : Colors.black12),
                          width: isSelected ? 2 : 1,
                        ),
                        color: isSelected
                            ? FormaColors.primaryBlue.withValues(alpha: 0.12)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.02)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? FormaColors.primaryBlue.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white10 : Colors.black12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: isSelected
                                  ? FormaColors.primaryBlue
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected
                                        ? FormaColors.primaryBlue
                                        : (isDark ? Colors.white : FormaColors.lightTextMain),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: isSelected ? FormaColors.primaryBlue : (isDark ? Colors.white30 : Colors.black26),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        if (settings.themeMode == FormaThemeMode.liquidGlass)
          _buildConfigCard(
            title: 'Liquid Glass Shader Parameters',
            subtitle: 'Tune dynamic optical refraction, blur, and specular light highlights',
            icon: Icons.blur_on_rounded,
            isDark: isDark,
            isGlass: isGlass,
            children: [
              _buildSliderRow(
                label: 'Backdrop Blur Strength',
                value: settings.glassBlur,
                min: 5.0,
                max: 60.0,
                unit: 'px',
                onChanged: notifier.setGlassBlur,
                isDark: isDark,
              ),
              _buildSliderRow(
                label: 'Glass Panel Opacity',
                value: settings.glassOpacity * 100,
                min: 15.0,
                max: 85.0,
                unit: '%',
                onChanged: (val) => notifier.setGlassOpacity(val / 100),
                isDark: isDark,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Specular Light Highlight'),
                subtitle: const Text('Luminous top-edge reflection simulation'),
                value: settings.glassSpecular,
                onChanged: notifier.toggleGlassSpecular,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fluid Sheen Animation'),
                subtitle: const Text('Soft angled ambient highlight overlay'),
                value: settings.glassSheen,
                onChanged: notifier.toggleGlassSheen,
              ),
            ],
          ),
        _buildConfigCard(
          title: 'Sidebar & Tool Dock Position',
          subtitle: 'Keep primary sidebar on Left or Right. Navigation snaps appropriately.',
          icon: Icons.dock_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<SidebarSide>(
                segments: const [
                  ButtonSegment(
                    value: SidebarSide.left,
                    label: Text('Left'),
                    icon: Icon(Icons.dock_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: SidebarSide.right,
                    label: Text('Right'),
                    icon: Icon(Icons.vertical_split_rounded, size: 16),
                  ),
                ],
                selected: {settings.sidebarPrimarySide},
                onSelectionChanged: (val) {
                  if (val.isNotEmpty) {
                    notifier.setSidebarPrimarySide(val.first);
                  }
                },
              ),
            ),
          ],
        ),
        _buildConfigCard(
          title: 'Recent & Template Card Sizing',
          subtitle: 'Compact fits 4 cards cleanly on mobile screens without scrolling.',
          icon: Icons.grid_view_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<CardDensity>(
                segments: const [
                  ButtonSegment(
                    value: CardDensity.compact,
                    label: Text('Compact'),
                  ),
                  ButtonSegment(
                    value: CardDensity.normal,
                    label: Text('Normal'),
                  ),
                  ButtonSegment(
                    value: CardDensity.spacious,
                    label: Text('Spacious'),
                  ),
                ],
                selected: {settings.cardDensity},
                onSelectionChanged: (val) {
                  if (val.isNotEmpty) {
                    notifier.setCardDensity(val.first);
                  }
                },
              ),
            ),
          ],
        ),
        _buildConfigCard(
          title: 'App Branding & Native Vector Insignia',
          subtitle: 'Vector icon engine with zero memory decode overhead',
          icon: Icons.auto_awesome_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormaLogo(size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forma Studio Vector Insignia',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rendered dynamically with zero memory decode overhead and no refresh flicker. Standardized across Android, iOS, Windows, and Web.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? FormaColors.darkTextMuted
                              : FormaColors.lightTextMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 2. Editor & Canvas Tab
  Widget _buildEditorCanvasTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark, [
    bool isGlass = false,
  ]) {
    return ListView(
      children: [
        _buildConfigCard(
          title: 'Snapping & Alignment Guides',
          subtitle: 'Intelligent magnetic snaps to grid lines and neighboring shape edges',
          icon: Icons.grid_goldenratio_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Snap to Grid'),
              subtitle: const Text('Align object edges to the active canvas grid lines'),
              value: settings.snapToGrid,
              onChanged: notifier.toggleSnapToGrid,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Snap to Objects (Smart Guides)'),
              subtitle: const Text(
                'Show magenta alignment rays and distance tags when aligning with other nodes',
              ),
              value: settings.snapToObjects,
              onChanged: notifier.toggleSnapToObjects,
            ),
          ],
        ),
        _buildConfigCard(
          title: 'Grid & Canvas Rules',
          subtitle: 'Configure default grid spacing, pixel rulers, and zoom limits',
          icon: Icons.straighten_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            _buildSliderRow(
              label: 'Default Grid Size',
              value: settings.defaultGridSize,
              min: 4.0,
              max: 64.0,
              unit: 'pt',
              onChanged: notifier.setDefaultGridSize,
              isDark: isDark,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Canvas Rulers'),
              subtitle: const Text(
                'Display top and left pixel measurement rulers on the canvas viewport',
              ),
              value: settings.showRulers,
              onChanged: notifier.toggleShowRulers,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Canvas Grid'),
              subtitle: const Text('Display subtle background grid dots and alignment lines'),
              value: settings.showGrid,
              onChanged: notifier.toggleShowGrid,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Extended Zoom Limit (1% – 5000%)'),
              subtitle: const Text(
                'Allows extreme macro zoom into vector paths (up to 5000%) and birds-eye overview (down to 1%)',
              ),
              value: settings.extendedZoomLimit,
              onChanged: notifier.toggleExtendedZoomLimit,
            ),
          ],
        ),
        _buildConfigCard(
          title: 'UI Position & Layout Customizer',
          subtitle: 'Drag & drop to customize where toolbar buttons appear in your dock',
          icon: Icons.drag_indicator_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            _buildUiPositionCustomizer(isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildUiPositionCustomizer(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.drag_indicator_rounded, size: 18, color: FormaColors.primaryBlue),
              SizedBox(width: 8),
              Text(
                'Mobile & Canvas Dock Button Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Drag items by the grip icon to reorder buttons in your editor dock:',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIdx, newIdx) {
              setState(() {
                if (oldIdx < newIdx) newIdx -= 1;
                final item = _dockItems.removeAt(oldIdx);
                _dockItems.insert(newIdx, item);
              });
            },
            children: [
              for (int i = 0; i < _dockItems.length; i++)
                Container(
                  key: ValueKey(_dockItems[i]),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_handle_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _dockItems[i],
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FormaColors.primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Pos ${i + 1}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FormaColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Performance Tab
  Widget _buildPerformanceTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark, [
    bool isGlass = false,
  ]) {
    return ListView(
      children: [
        _buildConfigCard(
          title: 'Rendering & Hardware Acceleration',
          subtitle: 'Configure display refresh rate and graphics pipeline settings',
          icon: Icons.speed_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('High Refresh Rate (120Hz ProMotion)'),
              subtitle: const Text(
                'Enables smoothest scrolling, panning, and interactive transformations',
              ),
              value: settings.highRefreshRate,
              onChanged: (val) => notifier.toggleHighRefreshRate(val),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Reduce Blur on Low-End Devices'),
              subtitle: const Text(
                'Disables heavy backdrop filters to maintain locked 60 FPS',
              ),
              value: settings.reduceBlurForPerformance,
              onChanged: notifier.toggleReduceBlur,
            ),
          ],
        ),
        _buildConfigCard(
          title: 'Repaint Boundaries & Cache Isolation',
          subtitle: 'Active engine optimizations ensuring isolated GPU rasterization',
          icon: Icons.memory_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: const [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.speed_rounded, color: FormaColors.primaryBlue),
              title: Text('Layered Repaint Boundaries'),
              subtitle: Text('Active — isolates canvas repainting from UI chrome.'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.memory_rounded, color: FormaColors.successGreen),
              title: Text('Dynamic Vector Path Caching'),
              subtitle: Text('Active — caches parsed SVG and bezier path bounds.'),
            ),
          ],
        ),
      ],
    );
  }

  // 4. Storage & Backup Tab
  Widget _buildStorageBackupTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark, [
    bool isGlass = false,
  ]) {
    return ListView(
      children: [
        _buildConfigCard(
          title: 'Local Storage & Project Security',
          subtitle: 'Forma Studio runs 100% offline. All designs, vector paths, pages, and components are securely persisted in local storage without third-party servers, accounts, or paid APIs.',
          icon: Icons.security_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
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
                      const Text(
                        'Storage Footprint',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        onPressed: _loadStorageStats,
                        tooltip: 'Refresh statistics',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingStats)
                    const LinearProgressIndicator()
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_totalProjectsCount',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: FormaColors.primaryBlue,
                                ),
                              ),
                              const Text(
                                'Saved Projects',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                FileSaverService.formatFileSize(_totalProjectsBytes),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: FormaColors.primaryBlue,
                                ),
                              ),
                              const Text(
                                'Document Data',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        _buildConfigCard(
          title: 'Autosave Engine',
          subtitle: 'Configurable background debounce timer to prevent disk write thrashing',
          icon: Icons.save_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            _buildSliderRow(
              label: 'Autosave Debounce Interval',
              value: settings.autoSaveIntervalMs.toDouble(),
              min: 200.0,
              max: 2000.0,
              unit: 'ms',
              onChanged: (val) => notifier.setAutoSaveIntervalMs(val.round()),
              isDark: isDark,
            ),
          ],
        ),
        _buildConfigCard(
          title: 'Backup & Portability',
          subtitle: 'Full archive snapshots with all node hierarchies and design tokens',
          icon: Icons.backup_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FormaColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.archive_rounded, size: 18),
                    label: const Text('Export Full Archive Backup (.forma)'),
                    onPressed: _exportFullBackup,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.unarchive_rounded, size: 18),
                    label: const Text('Restore Backup from File'),
                    onPressed: _restoreBackupFromFile,
                  ),
                ),
              ],
            ),
          ],
        ),
        _buildConfigCard(
          title: 'Cache Management',
          subtitle: 'Purge image decoding buffers and vector caches without deleting projects.',
          icon: Icons.cleaning_services_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: FormaColors.dangerRed,
                side: const BorderSide(color: FormaColors.dangerRed),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_sweep_rounded, size: 16),
              onPressed: _clearAppCache,
              label: const Text('Clear Cache'),
            ),
          ],
        ),
      ],
    );
  }

  // 5. Advanced Tab
  Widget _buildAdvancedTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark, [
    bool isGlass = false,
  ]) {
    return ListView(
      children: [
        _buildConfigCard(
          title: 'Screen Resolution Layout Lock (10 Presets)',
          subtitle: 'Lock canvas layout or generate artboards matching exact phone, tablet, and desktop dimensions. Device brand names are stripped in favor of standard aspect ratios:',
          icon: Icons.aspect_ratio_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: settings.lockedResolutionPreset,
                  isExpanded: true,
                  hint: const Text('Freeform Canvas (No resolution lock)'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Freeform Canvas (No lock)'),
                    ),
                    ...ResolutionPreset.presets.map((preset) {
                      return DropdownMenuItem<String?>(
                        value: preset.label,
                        child: Text('${preset.category}: ${preset.label}'),
                      );
                    }),
                  ],
                  onChanged: (preset) {
                    notifier.setLockedResolutionPreset(preset);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          preset == null
                              ? 'Canvas set to Freeform.'
                              : 'Locked canvas layout to $preset.',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        _buildConfigCard(
          title: 'Developer Vector Path Engine',
          subtitle: 'Includes touch-hold curvature dragging, interactive tangent handles, loop-closing snaps to first anchor, and draggable control points. Fully coded in the graphics kernel and hidden from the standard toolbar for official v1.0 release.',
          icon: Icons.polyline_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: const [
                Chip(
                  avatar: Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                  label: Text('Kernel: v1.0.4-dev', style: TextStyle(fontSize: 11)),
                ),
                Chip(
                  avatar: Icon(Icons.visibility_off_rounded, size: 16),
                  label: Text('Toolbar Visibility: Hidden (Beta)', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
        _buildConfigCard(
          title: 'Viewport Frustum Culling',
          subtitle: 'Skips off-screen visual elements during canvas draw passes to maintain 120 FPS on heavy artboards.',
          icon: Icons.crop_free_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: const [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.crop_free_rounded, color: FormaColors.primaryBlue),
              title: Text('Frustum Culling for Deep Node Hierarchies'),
              subtitle: Text(
                'Active — keeps render cycles restricted to visible viewport bounds.',
              ),
            ),
          ],
        ),
        _buildConfigCard(
          title: 'Developer Settings & Code Generation',
          subtitle: 'Export options for developer handoff and code inspection',
          icon: Icons.code_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Design-to-HTML Code Export'),
              subtitle: const Text(
                'Unlocks HTML5 & CSS web bundle export in the canvas Export and Share menus. When disabled, HTML export is completely hidden across the studio.',
              ),
              value: settings.enableHtmlCodeExport,
              onChanged: (val) {
                notifier.toggleEnableHtmlCodeExport(val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? 'HTML Code Export unlocked in Export & Share menus.'
                          : 'HTML Code Export disabled and hidden.',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // 6. Shortcuts Tab
  Widget _buildShortcutsTab(bool isDark, [bool isGlass = false]) {
    final shortcuts = [
      ['V', 'Selection & Transformation Tool'],
      ['H', 'Hand Pan Tool (drag to move canvas)'],
      ['R', 'Create Rectangle shape'],
      ['O', 'Create Ellipse / Circle shape'],
      ['L', 'Create Line'],
      ['T', 'Create Text block (double tap on canvas to edit)'],
      ['F', 'Create Frame container'],
      ['P', 'Vector Pen Tool (Bézier anchor edit)'],
      ['Ctrl / Cmd + Z', 'Undo last action'],
      ['Ctrl / Cmd + Y / Shift+Z', 'Redo previously undone action'],
      ['Ctrl / Cmd + C', 'Copy selected nodes to clipboard'],
      ['Ctrl / Cmd + X', 'Cut selected nodes'],
      ['Ctrl / Cmd + V', 'Paste nodes from clipboard'],
      ['Ctrl / Cmd + D', 'Duplicate selected nodes in-place'],
      ['Delete / Backspace', 'Delete selected nodes (safe: ignored inside text inputs)'],
      ['Ctrl / Cmd + K', 'Open Command Palette'],
    ];

    return ListView(
      children: [
        _buildConfigCard(
          title: 'Figma-Compatible Hotkeys Reference',
          subtitle: 'Industry standard keyboard shortcuts for high-speed desktop & web editing',
          icon: Icons.keyboard_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                return Column(
                  children: shortcuts.map((item) {
                    final keycap = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        item[0],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: FormaColors.primaryBlue,
                        ),
                      ),
                    );

                    final description = Text(
                      item[1],
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? FormaColors.darkTextMain : FormaColors.lightTextMain,
                      ),
                    );

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
                        ),
                      ),
                      child: isNarrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                keycap,
                                const SizedBox(height: 6),
                                description,
                              ],
                            )
                          : Row(
                              children: [
                                keycap,
                                const SizedBox(width: 12),
                                Expanded(child: description),
                              ],
                            ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // 7. About Tab
  Widget _buildAboutTab(bool isDark, [bool isGlass = false]) {
    return ListView(
      children: [
        _buildConfigCard(
          title: 'About Forma Studio',
          subtitle: 'Professional vector design and responsive artboard suite',
          icon: Icons.info_outline_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: [
            const Center(
              child: Column(
                children: [
                  FormaLogo(size: 56),
                  SizedBox(height: 12),
                  Text(
                    'FORMA STUDIO',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'v0.3.0 (Studio Release)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: FormaColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Forma Studio is a professional, mobile-first visual design editor and vector prototyping suite built with Flutter and Dart.\n\n'
              'Designed for high precision, offline independence, and aesthetic craft. Features include hierarchical node trees, auto-layout, real Bezier vector path editing, interactive prototype transitions, design tokens, timeline animation, and multi-format vector export.',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
          ],
        ),
        _buildSectionTitle('Roadmap & Future Releases (Local First)', isDark),
        const SizedBox(height: 12),
        _buildRoadmapCard(
          icon: Icons.storage_rounded,
          title: 'High-Speed SQLite Local Vault & Instant Rollback',
          description:
              'Crash-proof local disk persistence with microsecond project auto-snapshots, zero cloud reliance, and branching local history checkpoints.',
          score: 9.6,
          accentColor: const Color(0xFF10B981),
          isTop3: true,
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.font_download_rounded,
          title: 'Offline Custom Font (OTF/TTF) & Glyph Importer',
          description:
              'Import desktop .ttf and .otf font files directly into local sandboxed storage with zero network dependencies and fast local glyph rasterization.',
          score: 9.4,
          accentColor: const Color(0xFF06B6D4),
          isTop3: true,
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.grain_rounded,
          title: 'Procedural Geometric Pattern & Mesh Generator',
          description:
              'Mathematically generate seamless isometric grids, voronoi cells, dotted halftone arrays, and geometric guilloche vector waves completely offline.',
          score: 9.2,
          accentColor: const Color(0xFFF59E0B),
          isTop3: true,
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.movie_creation_rounded,
          title: 'Animation Tool & Timeline',
          description:
              'Full keyframing engine for Position, Scale, Rotation, Opacity, Colors, and Effects with subframe scrubber, playhead, and loops.',
          score: 9.3,
          accentColor: const Color(0xFF3B82F6),
          isTop3: true,
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.view_in_ar_rounded,
          title: '3D Mesh & Depth Extrusion Engine',
          description:
              'Real-time 3D extrusion of 2D vector shapes, customizable bevel angles, dynamic lighting, material roughness/metallic shaders, and glTF / OBJ export.',
          score: 9.0,
          accentColor: const Color(0xFFF59E0B),
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.code_rounded,
          title: 'Design to HTML/CSS Code Export',
          description:
              'Clean semantic HTML5 markup generation with responsive CSS linear/radial gradients, multi-layer drop shadows, and web fonts.',
          score: 8.8,
          accentColor: const Color(0xFF8B5CF6),
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.rotate_right_rounded,
          title: 'Orbital Motion & Gravitational Paths',
          description:
              'Elliptical orbit trajectories around custom anchor points, variable orbital velocity, and retrograde motion for animation design.',
          score: 8.2,
          accentColor: const Color(0xFFEC4899),
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.shutter_speed_rounded,
          title: 'Sub-frame Keyframing & Custom Framerates',
          description:
              'Sub-frame placement, timecode display (HH:MM:SS:FF), and custom playback framerates (24, 30, 60, 120 FPS).',
          score: 7.9,
          accentColor: const Color(0xFFF59E0B),
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.graphic_eq_rounded,
          title: 'Audio Track Synchronization & Waveforms',
          description:
              'Audio waveform visualization on timeline, cue-point snapping, and sound event triggers for interactive prototypes.',
          score: 7.6,
          accentColor: const Color(0xFF06B6D4),
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.transform_rounded,
          title: 'Lottie JSON & Web Animation Export',
          description:
              'Direct export of vector motion curves to Lottie JSON (.json), SVG animations, and WebGL runtimes.',
          score: 7.4,
          accentColor: const Color(0xFF14B8A6),
          isDark: isDark,
        ),
        _buildConfigCard(
          title: 'App Launcher Icon Replacement Guide (For Developers)',
          subtitle: 'Instructions for configuring release app icons on native platforms',
          icon: Icons.app_shortcut_rounded,
          isDark: isDark,
          isGlass: isGlass,
          children: const [
            Text(
              'To replace the default launcher icons in native builds:\n'
              '• Android: Replace the launcher icons in `android/app/src/main/res/mipmap-*/ic_launcher.png` (or use `flutter_launcher_icons`).\n'
              '• iOS: Replace the icons inside `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.\n'
              '• PC / Windows: Replace `windows/runner/resources/app_icon.ico`.\n'
              '• Web: Replace `web/favicon.png` and `web/icons/Icon-*.png`.',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoadmapCard({
    required IconData icon,
    required String title,
    required String description,
    required double score,
    required Color accentColor,
    bool isTop3 = false,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: isTop3 ? 0.12 : 0.05)
            : accentColor.withValues(alpha: isTop3 ? 0.08 : 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop3
              ? accentColor.withValues(alpha: 0.6)
              : (isDark ? FormaColors.darkBorder : FormaColors.lightBorder),
          width: isTop3 ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (isTop3)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentColor, accentColor.withValues(alpha: 0.75)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 11, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'TOP 3 NEXT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, size: 11, color: accentColor),
                              const SizedBox(width: 2),
                              Text(
                                '${score.toStringAsFixed(1)}/10 Priority',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
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
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: isDark
                  ? FormaColors.darkTextMuted
                  : FormaColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : FormaColors.lightTextMain,
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : FormaColors.lightTextMain,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${value.toStringAsFixed(1)} $unit',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: FormaColors.primaryBlue,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
