import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../app/theme/forma_colors.dart';
import '../../../app/theme/neumorphic.dart';
import '../../../app/theme/liquid_glass.dart';
import '../../../app/widgets/forma_logo.dart';
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
      final pin = await _showPasscodeDialog(
        context,
        'Glassmorphism Passcode',
        'Glassmorphism Frost Mode',
      );
      if (pin == '2222') {
        notifier.setThemeMode(FormaThemeMode.glassmorphism);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passcode verified! Glassmorphism Frost Mode activated.'),
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
    } else if (mode == FormaThemeMode.cyberpunk) {
      final pin = await _showPasscodeDialog(
        context,
        'Cyberpunk Neon Passcode',
        'Cyberpunk Neon Mode',
      );
      if (pin == '4444') {
        notifier.setThemeMode(FormaThemeMode.cyberpunk);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passcode verified! Cyberpunk Neon Mode activated.'),
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
    final isGlass = settings.themeMode == FormaThemeMode.liquidGlass;
    final isDark = settings.themeMode == FormaThemeMode.dark ||
        (settings.themeMode == FormaThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    final bgColor = isGlass
        ? null
        : (isDark ? FormaColors.darkBg : FormaColors.lightBg);

    Widget content = Scaffold(
      backgroundColor: bgColor ?? Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Settings & Preferences',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : FormaColors.lightTextMain,
          ),
        ),
        actions: [
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
                    child: isGlass
                        ? LiquidGlassBox(
                            radius: 20,
                            blur: settings.glassBlur,
                            opacity: settings.glassOpacity,
                            hasSpecular: settings.glassSpecular,
                            hasSheen: settings.glassSheen,
                            padding: const EdgeInsets.all(24),
                            child: _buildActiveTabContent(
                              settings,
                              notifier,
                              isDark,
                            ),
                          )
                        : NeuCard(
                            radius: 20,
                            padding: const EdgeInsets.all(24),
                            child: _buildActiveTabContent(
                              settings,
                              notifier,
                              isDark,
                            ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: isGlass
                        ? LiquidGlassBox(
                            radius: 20,
                            blur: settings.glassBlur,
                            opacity: settings.glassOpacity,
                            hasSpecular: settings.glassSpecular,
                            hasSheen: settings.glassSheen,
                            padding: const EdgeInsets.all(16),
                            child: _buildActiveTabContent(
                              settings,
                              notifier,
                              isDark,
                            ),
                          )
                        : NeuCard(
                            radius: 20,
                            padding: const EdgeInsets.all(16),
                            child: _buildActiveTabContent(
                              settings,
                              notifier,
                              isDark,
                            ),
                          ),
                  ),
                ),
              ],
            );
          }
        },
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

  Widget _buildActiveTabContent(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark,
  ) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAppearanceTab(settings, notifier, isDark);
      case 1:
        return _buildEditorCanvasTab(settings, notifier, isDark);
      case 2:
        return _buildPerformanceTab(settings, notifier, isDark);
      case 3:
        return _buildStorageBackupTab(settings, notifier, isDark);
      case 4:
        return _buildAdvancedTab(settings, notifier, isDark);
      case 5:
        return _buildShortcutsTab(isDark);
      case 6:
        return _buildAboutTab(isDark);
      default:
        return const SizedBox();
    }
  }

  // 1. Appearance Tab
  Widget _buildAppearanceTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark,
  ) {
    return ListView(
      children: [
        _buildSectionTitle('Theme & Visual Identity', isDark),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: FormaThemeMode.values.map((mode) {
            final isSelected = settings.themeMode == mode;
            String label;
            IconData icon;
            switch (mode) {
              case FormaThemeMode.system:
                label = 'System Default';
                icon = Icons.brightness_auto_rounded;
                break;
              case FormaThemeMode.light:
                label = 'Soft Neumorphic Light';
                icon = Icons.light_mode_rounded;
                break;
              case FormaThemeMode.dark:
                label = 'Deep Slate Dark';
                icon = Icons.dark_mode_rounded;
                break;
              case FormaThemeMode.liquidGlass:
                label = 'Liquid Glass';
                icon = Icons.blur_on_rounded;
                break;
              case FormaThemeMode.glassmorphism:
                label = 'Glassmorphism Frost';
                icon = Icons.auto_awesome_rounded;
                break;
              case FormaThemeMode.cyberpunk:
                label = 'Cyberpunk Neon';
                icon = Icons.electric_bolt_rounded;
                break;
            }

            return InkWell(
              onTap: () => _handleThemeSelection(mode, settings, notifier),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? FormaColors.primaryBlue
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? FormaColors.primaryBlue.withValues(alpha: 0.12)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isSelected ? FormaColors.primaryBlue : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? FormaColors.primaryBlue : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        if (settings.themeMode == FormaThemeMode.liquidGlass) ...[
          _buildSectionTitle('Liquid Glass Shader Parameters', isDark),
          const SizedBox(height: 12),
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
            title: const Text('Specular Light Highlight'),
            subtitle: const Text('Luminous top-edge reflection simulation'),
            value: settings.glassSpecular,
            onChanged: notifier.toggleGlassSpecular,
          ),
          SwitchListTile(
            title: const Text('Fluid Sheen Animation'),
            subtitle: const Text('Soft angled ambient highlight overlay'),
            value: settings.glassSheen,
            onChanged: notifier.toggleGlassSheen,
          ),
          const Divider(height: 32),
        ],

        _buildSectionTitle('Layout & Primary Dock Placement', isDark),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Sidebar & Tool Dock Position'),
          subtitle: const Text(
            'Keep primary sidebar on Left or Right. Navigation snaps appropriately.',
          ),
          trailing: SegmentedButton<SidebarSide>(
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
        const SizedBox(height: 16),

        _buildSectionTitle('Home Grid Card Density', isDark),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Recent & Template Card Sizing'),
          subtitle: const Text(
            'Compact fits 4 cards cleanly on mobile screens without scrolling.',
          ),
          trailing: SegmentedButton<CardDensity>(
            segments: const [
              ButtonSegment(
                value: CardDensity.compact,
                label: Text('Compact (4-fit)'),
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
        const Divider(height: 32),
        _buildSectionTitle('App Branding & Native Vector Insignia', isDark),
        const SizedBox(height: 8),
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
        const SizedBox(height: 16),
      ],
    );
  }

  // 2. Editor & Canvas Tab
  Widget _buildEditorCanvasTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark,
  ) {
    return ListView(
      children: [
        _buildSectionTitle('Snapping & Alignment Guides', isDark),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Snap to Grid'),
          subtitle: const Text('Align object edges to the active canvas grid lines'),
          value: settings.snapToGrid,
          onChanged: notifier.toggleSnapToGrid,
        ),
        SwitchListTile(
          title: const Text('Snap to Objects (Smart Guides)'),
          subtitle: const Text(
            'Show magenta alignment rays and distance tags when aligning with other nodes',
          ),
          value: settings.snapToObjects,
          onChanged: notifier.toggleSnapToObjects,
        ),
        const Divider(height: 32),

        _buildSectionTitle('Grid & Canvas Rules', isDark),
        const SizedBox(height: 8),
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
          title: const Text('Show Canvas Rulers'),
          subtitle: const Text(
            'Display top and left pixel measurement rulers on the canvas viewport',
          ),
          value: settings.showRulers,
          onChanged: notifier.toggleShowRulers,
        ),
        SwitchListTile(
          title: const Text('Show Canvas Grid'),
          subtitle: const Text('Display subtle background grid dots and alignment lines'),
          value: settings.showGrid,
          onChanged: notifier.toggleShowGrid,
        ),
      ],
    );
  }

  // 3. Performance Tab
  Widget _buildPerformanceTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark,
  ) {
    return ListView(
      children: [
        _buildSectionTitle('Rendering & Hardware Acceleration', isDark),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('High Refresh Rate (120Hz ProMotion)'),
          subtitle: const Text(
            'Enables smoothest scrolling, panning, and interactive transformations',
          ),
          value: settings.highRefreshRate,
          onChanged: (val) {},
        ),
        SwitchListTile(
          title: const Text('Reduce Blur on Low-End Devices'),
          subtitle: const Text(
            'Disables heavy backdrop filters to maintain locked 60 FPS',
          ),
          value: settings.reduceBlurForPerformance,
          onChanged: notifier.toggleReduceBlur,
        ),
        const Divider(height: 32),
        _buildSectionTitle('Repaint Boundaries & Cache Isolation', isDark),
        const SizedBox(height: 8),
        const ListTile(
          leading: Icon(Icons.speed_rounded, color: FormaColors.primaryBlue),
          title: Text('Layered Repaint Boundaries'),
          subtitle: Text('Active — isolates canvas repainting from UI chrome.'),
        ),
        const ListTile(
          leading: Icon(Icons.memory_rounded, color: FormaColors.successGreen),
          title: Text('Dynamic Vector Path Caching'),
          subtitle: Text('Active — caches parsed SVG and bezier path bounds.'),
        ),
      ],
    );
  }

  // 4. Storage & Backup Tab
  Widget _buildStorageBackupTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark,
  ) {
    return ListView(
      children: [
        _buildSectionTitle('Local Storage & Project Security', isDark),
        const SizedBox(height: 8),
        const Text(
          'Forma Studio runs 100% offline. All designs, vector paths, pages, and components are securely persisted in local storage without third-party servers, accounts, or paid APIs.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 16),

        // Live Storage Statistics Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
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
        const SizedBox(height: 20),

        _buildSectionTitle('Autosave Engine', isDark),
        const SizedBox(height: 8),
        _buildSliderRow(
          label: 'Autosave Debounce Interval',
          value: settings.autoSaveIntervalMs.toDouble(),
          min: 200.0,
          max: 2000.0,
          unit: 'ms',
          onChanged: (val) => notifier.setAutoSaveIntervalMs(val.round()),
          isDark: isDark,
        ),
        const Divider(height: 32),

        _buildSectionTitle('Backup & Portability', isDark),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: FormaColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.archive_rounded, size: 18),
              label: const Text('Export Full Archive Backup (.forma)'),
              onPressed: _exportFullBackup,
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.unarchive_rounded, size: 18),
              label: const Text('Restore Backup from File'),
              onPressed: _restoreBackupFromFile,
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Cache Management', isDark),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Clear App Cache & Temporary Vectors'),
          subtitle: const Text(
            'Purge image decoding buffers and vector caches without deleting projects.',
          ),
          trailing: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: FormaColors.dangerRed,
              side: const BorderSide(color: FormaColors.dangerRed),
            ),
            onPressed: _clearAppCache,
            child: const Text('Clear Cache'),
          ),
        ),
      ],
    );
  }

  // 5. Advanced Tab
  Widget _buildAdvancedTab(
    AppSettings settings,
    SettingsNotifier notifier,
    bool isDark,
  ) {
    return ListView(
      children: [
        _buildSectionTitle('Screen Resolution Layout Lock (10 Presets)', isDark),
        const SizedBox(height: 6),
        const Text(
          'Lock canvas layout or generate artboards matching exact phone, tablet, and desktop dimensions. Device brand names are stripped in favor of standard aspect ratios:',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
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
        const Divider(height: 32),

        _buildSectionTitle('Developer Vector Path Engine', isDark),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.polyline_rounded, color: FormaColors.primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    'High-Precision Bézier Vector Engine',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Includes touch-hold curvature dragging, interactive tangent handles, loop-closing snaps to first anchor, and draggable control points. Fully coded in the graphics kernel and hidden from the standard toolbar for official v1.0 release.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                    label: const Text('Kernel: v1.0.4-dev', style: TextStyle(fontSize: 11)),
                  ),
                  Chip(
                    avatar: const Icon(Icons.visibility_off_rounded, size: 16),
                    label: const Text('Toolbar Visibility: Hidden (Beta)', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 32),

        _buildSectionTitle('Viewport Frustum Culling', isDark),
        const SizedBox(height: 8),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.crop_free_rounded, color: FormaColors.primaryBlue),
          title: Text('Frustum Culling for Deep Node Hierarchies'),
          subtitle: Text(
            'Skips off-screen visual elements during canvas draw passes to maintain 120 FPS on heavy artboards.',
          ),
        ),
        const Divider(height: 32),
        _buildSectionTitle('Developer Settings & Code Generation', isDark),
        const SizedBox(height: 8),
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
    );
  }

  // 6. Shortcuts Tab
  Widget _buildShortcutsTab(bool isDark) {
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
        _buildSectionTitle('Figma-Compatible Hotkeys Reference', isDark),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2.5),
          },
          children: shortcuts.map((item) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item[0],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    item[1],
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : FormaColors.lightTextMain,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 7. About Tab
  Widget _buildAboutTab(bool isDark) {
    return ListView(
      children: [
        _buildSectionTitle('About Forma Studio', isDark),
        const SizedBox(height: 16),
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
                'v0.1 (Beta Testing)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: FormaColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Forma Studio is a professional, mobile-first visual design editor and vector prototyping suite built with Flutter and Dart.\n\n'
          'Designed for high precision, offline independence, and aesthetic craft. Features include hierarchical node trees, auto-layout, real Bezier vector path editing, interactive prototype transitions, design tokens, timeline animation, and multi-format vector export.',
          style: TextStyle(fontSize: 13, height: 1.6),
        ),
        const Divider(height: 32),

        // Roadmap & Future Releases Section
        _buildSectionTitle('Roadmap & Future Releases', isDark),
        const SizedBox(height: 12),
        _buildRoadmapCard(
          icon: Icons.auto_fix_high_rounded,
          title: 'AI Sketch-to-Vector Synthesis',
          description:
              'Convert rough hand-drawn pencil sketches and wireframes into clean, mathematically optimized Bezier vector shapes and UI components using deep learning.',
          score: 9.6,
          accentColor: const Color(0xFF10B981),
          isTop3: true,
          isDark: isDark,
        ),
        _buildRoadmapCard(
          icon: Icons.groups_rounded,
          title: 'Multi-User Live Collaboration Canvas',
          description:
              'Real-time peer-to-peer multiplayer canvas syncing with live presence cursors, shared selection rings, and simultaneous vector node editing.',
          score: 9.4,
          accentColor: const Color(0xFF06B6D4),
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

        const Divider(height: 32),
        _buildSectionTitle('App Launcher Icon Replacement Guide (For Developers)', isDark),
        const SizedBox(height: 8),
        const Text(
          'To replace the default launcher icons in native builds:\n'
          '• Android: Replace the launcher icons in `android/app/src/main/res/mipmap-*/ic_launcher.png` (or use `flutter_launcher_icons`).\n'
          '• iOS: Replace the icons inside `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.\n'
          '• PC / Windows: Replace `windows/runner/resources/app_icon.ico`.\n'
          '• Web: Replace `web/favicon.png` and `web/icons/Icon-*.png`.',
          style: TextStyle(fontSize: 12, height: 1.6),
        ),
        const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? accentColor.withValues(alpha: isTop3 ? 0.12 : 0.05)
            : accentColor.withValues(alpha: isTop3 ? 0.08 : 0.03),
        borderRadius: BorderRadius.circular(12),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isTop3) ...[
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
                const SizedBox(width: 6),
              ],
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
                      '${score.toStringAsFixed(1)}/10',
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
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : FormaColors.lightTextMain,
                ),
              ),
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
