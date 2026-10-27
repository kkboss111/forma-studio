import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/project_model.dart';
import '../../../domain/models/page_model.dart';
import '../../../app/theme/forma_colors.dart';
import '../../../app/theme/neumorphic.dart';
import '../../../app/theme/liquid_glass.dart';
import '../../../app/widgets/forma_logo.dart';
import '../../../app/widgets/studio_loading_transition.dart';
import '../widgets/forma_documentation_dialog.dart';
import 'splash_screen.dart';
import '../../../core/persistence/project_repository.dart';
import '../../../core/export/file_saver_service.dart';
import '../../../core/export/universal_format_service.dart';
import '../../templates/template_service.dart';
import '../../editor/screens/editor_screen.dart';
import '../../settings/models/app_settings.dart';
import '../../settings/screens/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;

  const HomeScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ProjectRepository _repository = ProjectRepository();
  List<ProjectModel> _projects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _activeTab = 'recent'; // 'recent', 'templates', 'favorites'

  // Bulk Selection
  bool _isBulkSelectMode = false;
  final Set<String> _selectedProjectIds = {};

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final list = await _repository.listProjects();
    setState(() {
      _projects = list;
      _isLoading = false;
    });
  }

  void _openProject(ProjectModel project) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FutureBuilder(
            future: Future.delayed(const Duration(milliseconds: 260)),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const StudioLoadingTransition(
                  type: StudioTransitionType.homeToCanvas,
                );
              }
              return EditorScreen(project: project);
            },
          );
        },
      ),
    );
    _loadProjects();
  }

  void _createBlankProject() async {
    final now = DateTime.now();
    final newProj = ProjectModel(
      id: 'proj-${now.millisecondsSinceEpoch}',
      name: 'Untitled Project ${_projects.length + 1}',
      createdAt: now,
      updatedAt: now,
      pages: [PageModel(id: 'page-1', name: 'Page 1', rootNodeIds: const [])],
    );
    await _repository.saveProject(newProj);
    _openProject(newProj);
  }

  void _createFromTemplate(TemplateInfo template) async {
    final proj = template.projectBuilder();
    await _repository.saveProject(proj);
    _openProject(proj);
  }

  void _deleteProject(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: const Text(
          'This will permanently delete this project from local storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: FormaColors.dangerRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteProject(id);
      _loadProjects();
    }
  }

  void _deleteBulkSelected() async {
    if (_selectedProjectIds.isEmpty) return;

    final count = _selectedProjectIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count Projects?'),
        content: Text(
          'This will permanently delete $count selected projects from local storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete All Selected',
              style: TextStyle(color: FormaColors.dangerRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in _selectedProjectIds) {
        await _repository.deleteProject(id);
      }
      setState(() {
        _selectedProjectIds.clear();
        _isBulkSelectMode = false;
      });
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted $count projects.'),
            backgroundColor: FormaColors.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _importProject() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: UniversalFormatService.allSupportedExtensions,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final importRes = await UniversalFormatService.importFile(
          filename: picked.name,
          bytes: bytes,
        );

        if (!mounted) return;

        final shouldImport = await _showImportPreviewDialog(
          context,
          importRes.project,
          bytes.length,
        );

        if (shouldImport == true) {
          await _repository.saveProject(importRes.project);
          setState(() {
            _activeTab = 'recent';
            _searchQuery = '';
          });
          await _loadProjects();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imported "${importRes.project.name}" successfully!'),
                backgroundColor: FormaColors.successGreen,
              ),
            );
            _openProject(importRes.project);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import project: $e'),
            backgroundColor: FormaColors.dangerRed,
          ),
        );
      }
    }
  }

  Future<void> _showProjectPropertiesDialog(ProjectModel project) async {
    final nameController = TextEditingController(text: project.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jsonStr = jsonEncode(project.toJson());
    final sizeFormatted = FileSaverService.formatFileSize(jsonStr.length);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: FormaColors.primaryBlue),
            SizedBox(width: 8),
            Text('Document Properties', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Document Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            _buildPropRow('Document ID', project.id.substring(0, math.min(16, project.id.length))),
            _buildPropRow('Pages', '${project.pages.length} Page(s)'),
            _buildPropRow('Total Layers', '${project.nodes.length} Elements'),
            _buildPropRow('Estimated Size', sizeFormatted),
            _buildPropRow('Created', dateFormat.format(project.createdAt)),
            _buildPropRow('Last Modified', dateFormat.format(project.updatedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save & Rename', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (updated == true && nameController.text.trim().isNotEmpty) {
      final renamed = project.copyWith(
        name: nameController.text.trim(),
        updatedAt: DateTime.now(),
      );
      await _repository.saveProject(renamed);
      _loadProjects();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renamed to "${renamed.name}"')),
      );
    }
  }

  Widget _buildPropRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _duplicateProject(ProjectModel project) async {
    final copyId = 'proj_${DateTime.now().millisecondsSinceEpoch}';
    final copy = project.copyWith(
      id: copyId,
      name: '${project.name} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.saveProject(copy);
    _loadProjects();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated "${project.name}" as "${copy.name}"'),
          backgroundColor: FormaColors.primaryBlue,
        ),
      );
    }
  }

  void _toggleTheme() {
    final currentSettings = ref.read(settingsProvider);
    final isCurrentlyDark = currentSettings.themeMode == FormaThemeMode.dark ||
        (currentSettings.themeMode == FormaThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final nextMode = isCurrentlyDark ? FormaThemeMode.light : FormaThemeMode.dark;
    ref.read(settingsProvider.notifier).setThemeMode(nextMode);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                nextMode == FormaThemeMode.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nextMode == FormaThemeMode.dark
                      ? 'Deep Slate Dark Mode enabled'
                      : 'Soft Neumorphic Light Mode enabled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: nextMode == FormaThemeMode.dark
              ? const Color(0xFF1E242F)
              : const Color(0xFF2B3445),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _reloadAppAndIntro() {
    final settings = ref.read(settingsProvider);
    final isDark = settings.themeMode == FormaThemeMode.dark ||
        (settings.themeMode == FormaThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) => SplashScreen(
          onToggleTheme: _toggleTheme,
          isDarkMode: isDark,
          isManualReload: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _shareProject(ProjectModel project) async {
    final settings = ref.read(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SupportedFormat selectedFormat = SupportedFormat.forma;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final formats = [
              (SupportedFormat.forma, 'Forma (.forma)'),
              (SupportedFormat.figma, 'Figma (.fig)'),
              (SupportedFormat.sketch, 'Sketch (.sketch)'),
              (SupportedFormat.adobeXd, 'Adobe XD (.xd)'),
              (SupportedFormat.svg, 'SVG Vector (.svg)'),
              (SupportedFormat.png, 'PNG Image (.png)'),
              (SupportedFormat.pdf, 'PDF Document (.pdf)'),
              (SupportedFormat.jsonTokens, 'Tokens (.json)'),
              (SupportedFormat.eps, 'PostScript (.eps)'),
              (SupportedFormat.dxf, 'AutoCAD (.dxf)'),
              if (settings.enableHtmlCodeExport)
                (SupportedFormat.htmlCss, 'HTML/CSS Web Code (.html)'),
            ];

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.share_rounded, color: FormaColors.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Share "${project.name}"',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select format to share to Android apps (WhatsApp, Drive, Gmail, etc.):',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: formats.map((item) {
                      final isSel = selectedFormat == item.$1;
                      return ChoiceChip(
                        label: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSel,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedFormat = item.$1);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: const Text('Save File', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _executeProjectShareOrSave(project, selectedFormat, useShareSheet: false);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FormaColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Share to Apps', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _executeProjectShareOrSave(project, selectedFormat, useShareSheet: true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _executeProjectShareOrSave(
    ProjectModel project,
    SupportedFormat format, {
    required bool useShareSheet,
  }) async {
    try {
      final pageId = project.pages.isNotEmpty ? project.pages.first.id : 'page-1';
      final bytes = await UniversalFormatService.exportToFormat(
        project: project,
        pageId: pageId,
        format: format,
      );

      final safeName = project.name.replaceAll(RegExp(r'[^\w\s-]'), '_');
      String ext = 'forma';
      String mimeType = 'application/json';
      switch (format) {
        case SupportedFormat.figma:
          ext = 'fig';
          mimeType = 'application/zip';
          break;
        case SupportedFormat.sketch:
          ext = 'sketch';
          mimeType = 'application/zip';
          break;
        case SupportedFormat.adobeXd:
          ext = 'xd';
          mimeType = 'application/zip';
          break;
        case SupportedFormat.svg:
          ext = 'svg';
          mimeType = 'image/svg+xml';
          break;
        case SupportedFormat.png:
        case SupportedFormat.jpeg:
        case SupportedFormat.webp:
          ext = 'png';
          mimeType = 'image/png';
          break;
        case SupportedFormat.pdf:
          ext = 'pdf';
          mimeType = 'application/pdf';
          break;
        case SupportedFormat.forma:
          ext = 'forma';
          mimeType = 'application/json';
          break;
        case SupportedFormat.jsonTokens:
          ext = 'json';
          mimeType = 'application/json';
          break;
        case SupportedFormat.eps:
          ext = 'eps';
          mimeType = 'application/postscript';
          break;
        case SupportedFormat.dxf:
          ext = 'dxf';
          mimeType = 'application/dxf';
          break;
        case SupportedFormat.htmlCss:
          ext = 'html';
          mimeType = 'text/html';
          break;
      }

      final filename = '$safeName.$ext';
      bool ok = false;
      if (useShareSheet) {
        ok = await FileSaverService.shareFile(
          bytes: bytes,
          filename: filename,
          mimeType: mimeType,
          subject: 'Forma Studio: ${project.name}',
        );
      } else {
        ok = await FileSaverService.saveFile(
          bytes: bytes,
          filename: filename,
          mimeType: mimeType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? (useShareSheet
                      ? 'Shared "$filename" via system chooser (${FileSaverService.formatFileSize(bytes.length)})'
                      : 'Saved "$filename" (${FileSaverService.formatFileSize(bytes.length)})')
                  : 'Action completed for "$filename".',
            ),
            backgroundColor: ok ? FormaColors.successGreen : FormaColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: FormaColors.dangerRed,
          ),
        );
      }
    }
  }

  Future<bool?> _showImportPreviewDialog(
    BuildContext context,
    ProjectModel project,
    int byteSize,
  ) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    final formattedSize = FileSaverService.formatFileSize(byteSize);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined, color: FormaColors.primaryBlue),
            SizedBox(width: 8),
            Text('Import Project Preview', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FormaColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: FormaColors.primaryBlue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Size: $formattedSize • ${project.nodes.length} Elements',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _previewInfoRow('Pages', '${project.pages.length} page(s)'),
            _previewInfoRow('Components', '${project.components.length} defined'),
            _previewInfoRow('Last Updated', dateFormat.format(project.updatedAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FormaColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Import'),
          ),
        ],
      ),
    );
  }

  Widget _previewInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isGlass = settings.themeMode == FormaThemeMode.liquidGlass;
    final isDark = settings.themeMode == FormaThemeMode.dark ||
        (settings.themeMode == FormaThemeMode.system &&
            Theme.of(context).brightness == Brightness.dark);

    Widget content = Scaffold(
      key: _scaffoldKey,
      backgroundColor: isGlass
          ? Colors.transparent
          : (isDark ? FormaColors.darkBg : FormaColors.lightBg),
      drawer: Drawer(
        backgroundColor: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        child: SafeArea(
          child: _buildSidebarContent(context, isDark, isGlass),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850 && constraints.maxHeight >= 550;

            if (isWide) {
              final isLeft = settings.sidebarPrimarySide == SidebarSide.left;
              final sidebarWidget = _buildSidebar(context, isDark, isGlass, settings);
              final mainWidget = Expanded(
                child: _buildMainContent(context, isDark, isGlass, settings),
              );

              return Row(
                children: isLeft
                    ? [sidebarWidget, mainWidget]
                    : [mainWidget, sidebarWidget],
              );
            } else {
              // Mobile / Tablet Portrait Layout
              return Column(
                children: [
                  _buildMobileHeader(context, isDark),
                  Expanded(
                    child: _buildMainContent(context, isDark, isGlass, settings),
                  ),
                ],
              );
            }
          },
        ),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 850
          ? _buildMobileBottomNav(isDark, isGlass)
          : null,
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

  Widget _buildMobileBottomNav(bool isDark, bool isGlass) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
        ),
      ),
      child: NavigationBar(
        height: 60,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIndex: _activeTab == 'recent'
            ? 0
            : _activeTab == 'templates'
            ? 1
            : 2,
        onDestinationSelected: (idx) {
          setState(() {
            if (idx == 0) _activeTab = 'recent';
            if (idx == 1) _activeTab = 'templates';
            if (idx == 2) _activeTab = 'favorites';
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Recent Work',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    bool isDark,
    bool isGlass,
    AppSettings settings,
  ) {
    final content = _buildSidebarContent(context, isDark, isGlass);

    return Container(
      width: 240,
      margin: const EdgeInsets.all(16),
      child: isGlass
          ? LiquidGlassBox(
              radius: 28,
              blur: settings.glassBlur,
              opacity: settings.glassOpacity,
              hasSpecular: settings.glassSpecular,
              hasSheen: settings.glassSheen,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: content,
            )
          : NeuCard(
              radius: 28,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: content,
            ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    bool isDark,
    bool isGlass,
  ) {
    return Column(
      children: [
        // Brand logo & title matching reference style
        const SizedBox(height: 12),
        const FormaLogo(size: 40),
        const SizedBox(height: 8),
        Text(
          'FORMA STUDIO',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark
                ? FormaColors.darkTextMain
                : FormaColors.lightTextMain,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: FormaColors.primaryBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'v0.1 (Beta Testing)',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: FormaColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Navigation Links
        _sidebarNavItem(
          label: 'RECENT PROJECTS',
          icon: Icons.dashboard_outlined,
          isSelected: _activeTab == 'recent',
          onTap: () {
            setState(() => _activeTab = 'recent');
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _sidebarNavItem(
          label: 'TEMPLATES',
          icon: Icons.auto_awesome_mosaic_outlined,
          isSelected: _activeTab == 'templates',
          onTap: () {
            setState(() => _activeTab = 'templates');
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _sidebarNavItem(
          label: 'FAVORITES',
          icon: Icons.favorite_border_rounded,
          isSelected: _activeTab == 'favorites',
          onTap: () {
            setState(() => _activeTab = 'favorites');
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _sidebarNavItem(
          label: 'IMPORT (.forma)',
          icon: Icons.file_upload_outlined,
          isSelected: false,
          onTap: () {
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            _importProject();
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _sidebarNavItem(
          label: 'RELOAD & INTRO',
          icon: Icons.restart_alt_rounded,
          isSelected: false,
          onTap: () {
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            _reloadAppAndIntro();
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _sidebarNavItem(
          label: isDark ? 'SWITCH TO LIGHT MODE' : 'SWITCH TO DARK MODE',
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          isSelected: false,
          onTap: () {
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            _toggleTheme();
          },
          isDark: isDark,
        ),

        const Spacer(),

        // Bottom settings & theme actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NeuIconButton(
              icon: Icons.settings_outlined,
              size: 40,
              iconSize: 18,
              tooltip: 'Settings & Themes',
              onPressed: _openSettings,
            ),
            NeuIconButton(
              icon: isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 40,
              iconSize: 18,
              iconColor: isDark
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFF6366F1),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: _toggleTheme,
            ),
            NeuIconButton(
              icon: Icons.info_outline_rounded,
              size: 40,
              iconSize: 18,
              tooltip: 'About Forma Studio',
              onPressed: () => _showAboutDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildMobileHeader(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Menu + Logo + Brand text (Flexible to never push right buttons offscreen)
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  tooltip: 'Open Navigation Menu',
                ),
                const SizedBox(width: 4),
                const FormaLogo(size: 26),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FORMA STUDIO',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark
                              ? FormaColors.darkTextMain
                              : FormaColors.lightTextMain,
                        ),
                      ),
                      const Text(
                        'v0.1 (Beta Testing)',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: FormaColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Right Actions Row (Guaranteed to fit on any mobile width with Theme toggle front-and-center)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (screenWidth >= 440) ...[
                NeuIconButton(
                  icon: Icons.refresh_rounded,
                  size: 36,
                  iconSize: 18,
                  tooltip: 'Reload App & Replay Intro',
                  onPressed: _reloadAppAndIntro,
                ),
                const SizedBox(width: 6),
                NeuIconButton(
                  icon: Icons.file_upload_outlined,
                  size: 36,
                  iconSize: 18,
                  tooltip: 'Import Project',
                  onPressed: _importProject,
                ),
                const SizedBox(width: 6),
              ] else if (screenWidth >= 380) ...[
                NeuIconButton(
                  icon: Icons.refresh_rounded,
                  size: 36,
                  iconSize: 18,
                  tooltip: 'Reload App & Replay Intro',
                  onPressed: _reloadAppAndIntro,
                ),
                const SizedBox(width: 6),
              ],
              // Settings Button
              NeuIconButton(
                icon: Icons.settings_outlined,
                size: 36,
                iconSize: 18,
                tooltip: 'Settings & Themes',
                onPressed: _openSettings,
              ),
              const SizedBox(width: 6),

              // THEME TOGGLE BUTTON - PROMINENT, RELIABLE, FULLY INTERACTIVE
              NeuIconButton(
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 36,
                iconSize: 18,
                iconColor: isDark
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF6366F1),
                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                onPressed: _toggleTheme,
              ),
              const SizedBox(width: 6),

              // New Artboard Button
              NeuIconButton(
                icon: Icons.add_rounded,
                size: 36,
                iconSize: 20,
                iconColor: FormaColors.primaryBlue,
                tooltip: 'New Artboard',
                onPressed: _createBlankProject,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sidebarNavItem({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: isSelected
            ? NeuBoxDecoration.box(
                context: context,
                style: NeuStyle.raised,
                radius: 16,
                isSelected: true,
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDark ? Colors.white : FormaColors.lightTextMain)
                  : (isDark
                        ? FormaColors.darkTextMuted
                        : FormaColors.lightTextMuted),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.5,
                  color: isSelected
                      ? (isDark ? Colors.white : FormaColors.lightTextMain)
                      : (isDark
                            ? FormaColors.darkTextMuted
                            : FormaColors.lightTextMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    bool isDark,
    bool isGlass,
    AppSettings settings,
  ) {
    if (_activeTab == 'templates') {
      return _buildTemplatesView(context, isDark, isGlass, settings);
    }

    final filtered = _projects.where((p) {
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_activeTab == 'favorites' && !p.isFavorite) {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Search & Create New Button
          Row(
            children: [
              Expanded(
                child: NeuTextField(
                  hintText: 'Search designs and mockups...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: FormaColors.primaryBlue,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 10),
              NeuButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                tooltip: 'Bulk select and delete designs',
                onPressed: () {
                  setState(() {
                    _isBulkSelectMode = !_isBulkSelectMode;
                    _selectedProjectIds.clear();
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _isBulkSelectMode
                          ? Icons.check_circle_rounded
                          : Icons.checklist_rounded,
                      size: 16,
                      color: _isBulkSelectMode
                          ? FormaColors.primaryBlue
                          : (isDark ? Colors.white : FormaColors.lightTextMain),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isBulkSelectMode ? 'Done' : 'Select',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isBulkSelectMode
                            ? FormaColors.primaryBlue
                            : (isDark ? Colors.white : FormaColors.lightTextMain),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              NeuButton(
                isActive: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                onPressed: _createBlankProject,
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'New Design',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // First-Run Welcome Card
          if (!settings.haveUserStartedApp) ...[
            _buildFirstRunWelcomeCard(context, isDark, isGlass),
            const SizedBox(height: 16),
          ],

          // Header with Bulk Delete Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _activeTab == 'favorites' ? 'Favorite Projects' : 'Recent Work',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? FormaColors.darkTextMain
                      : FormaColors.lightTextMain,
                ),
              ),
              if (_isBulkSelectMode)
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedProjectIds.length == filtered.length) {
                            _selectedProjectIds.clear();
                          } else {
                            _selectedProjectIds.addAll(filtered.map((e) => e.id));
                          }
                        });
                      },
                      child: Text(
                        _selectedProjectIds.length == filtered.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    if (_selectedProjectIds.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FormaColors.dangerRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: _deleteBulkSelected,
                        icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                        label: Text('Delete (${_selectedProjectIds.length})'),
                      ),
                  ],
                )
              else
                Text(
                  '${filtered.length} files',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? FormaColors.darkTextMuted
                        : FormaColors.lightTextMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Responsive Projects Grid (Fits 4 cards on mobile screen)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate columns: on mobile screens < 600px width, use 2 columns
                      final isMobile = constraints.maxWidth < 600;
                      final crossAxisCount = isMobile
                          ? 2
                          : (constraints.maxWidth / 220).floor().clamp(2, 6);

                      double aspectRatio = 1.05;
                      if (settings.cardDensity == CardDensity.compact) {
                        aspectRatio = isMobile ? 1.05 : 1.15;
                      } else if (settings.cardDensity == CardDensity.spacious) {
                        aspectRatio = isMobile ? 0.90 : 1.0;
                      }

                      // Total items: 1 (Permanent New Design Card) + filtered projects
                      final totalItems = 1 + filtered.length;

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildNewDesignCard(
                              context,
                              isDark,
                              isGlass,
                              settings,
                            );
                          }
                          final project = filtered[index - 1];
                          return _buildProjectCard(
                            project,
                            isDark,
                            isGlass,
                            settings,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstRunWelcomeCard(
    BuildContext context,
    bool isDark,
    bool isGlass,
  ) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FormaLogo(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Forma Studio v0.1 (Beta Testing)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : FormaColors.lightTextMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Free, offline-first vector UI/UX design suite inspired by Figma.',
                      style: TextStyle(
                        fontSize: 11,
                        color: FormaColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Create artboards, craft vector curves, design components, build keyframe animations, and import/export across 13 industry design formats—100% private and offline.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 14, color: FormaColors.primaryBlue),
                label: const Text('User Documentation & Guide', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                onPressed: () => FormaDocumentationDialog.show(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FormaColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => ref.read(settingsProvider.notifier).setHaveUserStartedApp(true),
                child: const Text('Get Started', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );

    if (isGlass) {
      return LiquidGlassBox(
        radius: 18,
        child: content,
      );
    }

    return NeuCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: content,
    );
  }

  // --- PERMANENT "NEW DESIGN" CARD (Image 2) ---
  Widget _buildNewDesignCard(
    BuildContext context,
    bool isDark,
    bool isGlass,
    AppSettings settings,
  ) {
    final content = InkWell(
      onTap: _createBlankProject,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FormaColors.primaryBlue.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 32,
              color: FormaColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'New Design',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : FormaColors.lightTextMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Create blank artboard',
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? FormaColors.darkTextMuted
                  : FormaColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );

    if (isGlass) {
      return LiquidGlassBox(
        radius: 18,
        blur: settings.glassBlur,
        opacity: settings.glassOpacity,
        hasSpecular: settings.glassSpecular,
        hasSheen: settings.glassSheen,
        child: content,
      );
    }

    return NeuCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: content,
    );
  }

  Widget _buildProjectCard(
    ProjectModel project,
    bool isDark,
    bool isGlass,
    AppSettings settings,
  ) {
    final dateFormat = DateFormat('MMM d • h:mm a');
    final isSelected = _selectedProjectIds.contains(project.id);

    final cardContent = InkWell(
      onTap: () {
        if (_isBulkSelectMode) {
          setState(() {
            if (isSelected) {
              _selectedProjectIds.remove(project.id);
            } else {
              _selectedProjectIds.add(project.id);
            }
          });
        } else {
          _openProject(project);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Thumbnail Well with optional selection checkbox
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NeuWell(
                      radius: 12,
                      padding: EdgeInsets.zero,
                      child: Center(
                        child: Icon(
                          Icons.draw_rounded,
                          size: 32,
                          color: FormaColors.primaryBlue.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  if (_isBulkSelectMode)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? FormaColors.primaryBlue
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Project Title & Options
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? FormaColors.darkTextMain
                          : FormaColors.lightTextMain,
                    ),
                  ),
                ),
                if (!_isBulkSelectMode)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: isDark
                          ? FormaColors.darkTextMuted
                          : FormaColors.lightTextMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (val) {
                      switch (val) {
                        case 'properties':
                          _showProjectPropertiesDialog(project);
                          break;
                        case 'duplicate':
                          _duplicateProject(project);
                          break;
                        case 'export':
                          _openProject(project);
                          break;
                        case 'share':
                          _shareProject(project);
                          break;
                        case 'delete':
                          _deleteProject(project.id);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      // 1. Properties (Rename & Info)
                      const PopupMenuItem(
                        value: 'properties',
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Properties'),
                          ],
                        ),
                      ),
                      // 2. Duplicate
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Duplicate'),
                          ],
                        ),
                      ),
                      // 3. Quick Export
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.file_upload_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Export'),
                          ],
                        ),
                      ),
                      // 4. Share
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Share'),
                          ],
                        ),
                      ),
                      // 5. Delete
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: FormaColors.dangerRed),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: FormaColors.dangerRed)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Updated date
            Text(
              dateFormat.format(project.updatedAt),
              style: TextStyle(
                fontSize: 9.5,
                color: isDark
                    ? FormaColors.darkTextMuted
                    : FormaColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );

    if (isGlass) {
      return LiquidGlassBox(
        radius: 18,
        blur: settings.glassBlur,
        opacity: settings.glassOpacity,
        hasSpecular: settings.glassSpecular,
        hasSheen: settings.glassSheen,
        child: cardContent,
      );
    }

    return NeuCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: cardContent,
    );
  }

  Widget _buildTemplatesView(
    BuildContext context,
    bool isDark,
    bool isGlass,
    AppSettings settings,
  ) {
    final templates = TemplateService.getTemplates();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editable Design Templates',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? FormaColors.darkTextMain
                  : FormaColors.lightTextMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Explore 12 real editable vector templates, including the Neumorphic Fan Analysis Dashboard reference!',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark
                  ? FormaColors.darkTextMuted
                  : FormaColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final crossAxisCount = isMobile ? 1 : (constraints.maxWidth / 320).floor().clamp(1, 4);

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isMobile ? 2.4 : 2.0,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final t = templates[index];
                    final templateContent = InkWell(
                      onTap: () => _createFromTemplate(t),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: FormaColors.primaryBlue.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                t.icon,
                                color: FormaColors.primaryBlue,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? FormaColors.darkTextMain
                                          : FormaColors.lightTextMain,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    t.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark
                                          ? FormaColors.darkTextMuted
                                          : FormaColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (isGlass) {
                      return LiquidGlassBox(
                        radius: 18,
                        blur: settings.glassBlur,
                        opacity: settings.glassOpacity,
                        hasSpecular: settings.glassSpecular,
                        hasSheen: settings.glassSheen,
                        child: templateContent,
                      );
                    }

                    return NeuCard(
                      radius: 18,
                      padding: EdgeInsets.zero,
                      child: templateContent,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About Forma Studio'),
        content: const Text(
          'Forma Studio is a free, mobile-first, Figma-inspired design application with a soft blue-gray neumorphic interface.\n\n'
          'Version: v0.1 (Beta Testing)\n\n'
          'Features include versioned document models, offline autosaving, interactive canvas engine, command-based history, auto-layout, prototype player, and SVG/PDF/PNG exports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
