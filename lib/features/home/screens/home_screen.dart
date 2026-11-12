import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/project_model.dart';
import '../../../domain/models/page_model.dart';
import '../../../domain/models/node_types.dart';
import '../../../app/theme/forma_colors.dart';
import '../../../app/theme/forma_theme.dart';
import '../../../app/theme/neumorphic.dart';
import '../../../app/theme/liquid_glass.dart';
import '../../../app/widgets/forma_logo.dart';
import '../../../app/widgets/studio_loading_transition.dart';
import '../../../app/widgets/forma_ambient_backdrop.dart';
import '../../../app/widgets/forma_theme_picker_dialog.dart';
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
  String _projectFilter = 'all'; // 'all', 'recent', 'starred'
  String _templateCategory = 'components'; // 'components' vs 'screens'
  final TextEditingController _searchController = TextEditingController();

  // Bulk Selection
  bool _isBulkSelectMode = false;
  final Set<String> _selectedProjectIds = {};

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _toggleFavorite(ProjectModel project) async {
    final updated = project.copyWith(
      isFavorite: !project.isFavorite,
      updatedAt: DateTime.now(),
    );
    await _repository.saveProject(updated);
    _loadProjects();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                updated.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: updated.isFavorite ? Colors.pinkAccent : Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                updated.isFavorite
                    ? 'Added "${project.name}" to Favorites ❤️'
                    : 'Removed "${project.name}" from Favorites',
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleTheme() {
    final current = ref.read(settingsProvider);
    final isCurrentlyDark = current.themeMode == FormaThemeMode.dark ||
        (current.themeMode == FormaThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final nextMode = isCurrentlyDark ? FormaThemeMode.light : FormaThemeMode.dark;
    ref.read(settingsProvider.notifier).setThemeMode(nextMode);
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
    final isSystemDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = FormaTheme.tokensForMode(settings.themeMode, isSystemDark: isSystemDark);
    final isGlass = tokens.isGlass;
    final isDark = tokens.isDark;

    Widget content = Scaffold(
      key: _scaffoldKey,
      backgroundColor: isGlass
          ? Colors.transparent
          : (isDark ? FormaColors.darkBg : FormaColors.lightBg),
      drawer: Drawer(
        backgroundColor: tokens.isGlass ? tokens.surface : (isDark ? FormaColors.darkSurface : FormaColors.lightSurface),
        child: SafeArea(
          child: tokens.isGlass && tokens.cardBlur > 0
              ? ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: tokens.cardBlur, sigmaY: tokens.cardBlur),
                    child: _buildSidebarContent(context, isDark, isGlass),
                  ),
                )
              : _buildSidebarContent(context, isDark, isGlass),
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

    return FormaAmbientBackdrop(explicitTokens: tokens, child: content);
  }

  Widget _buildMobileBottomNav(bool isDark, bool isGlass) {
    final tokens = FormaTheme.tokensOf(context);

    Widget nav = Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(
          top: BorderSide(
            color: tokens.border,
            width: 1.0,
          ),
        ),
      ),
      child: NavigationBar(
        height: 60,
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: tokens.accent.withValues(alpha: tokens.isDark ? 0.25 : 0.15),
        selectedIndex: _activeTab == 'recent'
            ? 0
            : _activeTab == 'templates'
            ? 1
            : _activeTab == 'favorites'
            ? 2
            : 3,
        onDestinationSelected: (idx) {
          setState(() {
            if (idx == 0) _activeTab = 'recent';
            if (idx == 1) _activeTab = 'templates';
            if (idx == 2) _activeTab = 'favorites';
            if (idx == 3) _activeTab = 'updates';
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
          NavigationDestination(
            icon: Icon(Icons.new_releases_outlined),
            selectedIcon: Icon(Icons.new_releases_rounded),
            label: 'Updates',
          ),
        ],
      ),
    );

    if (tokens.isGlass && tokens.cardBlur > 0) {
      return ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: tokens.cardBlur, sigmaY: tokens.cardBlur),
          child: nav,
        ),
      );
    }

    return nav;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Brand logo & title matching reference style
                  const SizedBox(height: 8),
                  const FormaLogo(size: 42),
                  const SizedBox(height: 8),
                  Text(
                    'FORMA STUDIO',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isDark
                          ? FormaColors.darkTextMain
                          : FormaColors.lightTextMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: FormaColors.primaryBlue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'v0.4 (Studio Edition)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: FormaColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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
          label: 'WHATS NEW & UPDATES',
          icon: Icons.new_releases_outlined,
          isSelected: _activeTab == 'updates',
          onTap: () {
            setState(() => _activeTab = 'updates');
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemePickerTriggerPill(
    BuildContext context,
    FormaThemeTokens tokens,
    bool isDark, {
    bool isCompact = false,
  }) {
    final settings = ref.watch(settingsProvider);

    String themeLabel;
    List<Color> orbColors;
    switch (settings.themeMode) {
      case FormaThemeMode.light:
        themeLabel = 'Light';
        orbColors = const [Color(0xFFFBBF24), Color(0xFFF59E0B)];
        break;
      case FormaThemeMode.dark:
        themeLabel = 'Obsidian';
        orbColors = const [Color(0xFF1E293B), Color(0xFF0F172A)];
        break;
      case FormaThemeMode.system:
        themeLabel = 'System';
        orbColors = [tokens.accent, tokens.accent.withValues(alpha: 0.6)];
        break;
    }

    return InkWell(
      onTap: () => FormaThemePickerDialog.show(context),
      borderRadius: BorderRadius.circular(20),
      child: Tooltip(
        message: 'Studio Themes: $themeLabel (Tap to switch)',
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tokens.accent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: orbColors),
                  boxShadow: [
                    BoxShadow(
                      color: orbColors.first.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(color: Colors.white70, width: 0.8),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 7),
                Text(
                  themeLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : FormaColors.lightTextMain,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 14,
                  color: isDark
                      ? FormaColors.darkTextMuted
                      : FormaColors.lightTextMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context, bool isDark) {
    final tokens = FormaTheme.tokensOf(context);
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
                        'v0.4 (Studio Edition)',
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

              // Theme Toggle Button (Light / Dark instant toggle)
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

              // Theme Picker Trigger with Live Preview Pill
              _buildThemePickerTriggerPill(
                context,
                tokens,
                isDark,
                isCompact: screenWidth < 460,
              ),
              const SizedBox(width: 6),

              // Quick 'New Artboard' Button
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

  Widget _buildFilterPill(
    String filterKey,
    String label,
    IconData icon,
    bool isDark,
    FormaThemeTokens tokens,
  ) {
    final isSelected = _projectFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _projectFilter = filterKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? tokens.accent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? tokens.accent
                : (isDark ? Colors.white12 : Colors.black12),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tokens.accent.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? FormaColors.darkTextMuted
                      : FormaColors.lightTextMuted),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? FormaColors.darkTextMain
                        : FormaColors.lightTextMain),
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
    final tokens = FormaTheme.tokensOf(context);
    if (_activeTab == 'templates') {
      return _buildTemplatesView(context, isDark, isGlass, settings);
    }
    if (_activeTab == 'updates') {
      return _buildChangelogView(context, isDark, isGlass);
    }

    final filtered = _projects.where((p) {
      if (_searchQuery.isNotEmpty &&
          !p.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_projectFilter == 'starred' && !p.isFavorite) {
        return false;
      }
      if (_activeTab == 'favorites' && !p.isFavorite) {
        return false;
      }
      return true;
    }).toList();

    if (_projectFilter == 'recent') {
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag & Drop / Quick File Import Banner (Desktop & Tablet)
          if (_activeTab == 'recent' && MediaQuery.of(context).size.width >= 850) ...[
            InkWell(
              onTap: _importProject,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: FormaColors.primaryBlue.withValues(alpha: isDark ? 0.08 : 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: FormaColors.primaryBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.file_upload_outlined, color: FormaColors.primaryBlue, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Drag & Drop .forma or Design Files Here',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Or click to browse and open existing projects, Figma, or SVG packages instantly',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: FormaColors.primaryBlue, size: 14),
                  ],
                ),
              ),
            ),
          ],
          // Top Row: Search & Create New Button
          Row(
            children: [
              Expanded(
                child: NeuTextField(
                  hintText: 'Search artboards...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: FormaColors.primaryBlue,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 8),
              NeuButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
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
                  mainAxisSize: MainAxisSize.min,
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
              const SizedBox(width: 8),
              NeuButton(
                isActive: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                tooltip: 'New Artboard',
                onPressed: _createBlankProject,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'New',
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
          const SizedBox(height: 12),

          // Clean Filter Pills Row (All, Recent, Starred) + Theme picker trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill('all', 'All (${_projects.length})', Icons.grid_view_rounded, isDark, tokens),
                      const SizedBox(width: 6),
                      _buildFilterPill('recent', 'Recent', Icons.schedule_rounded, isDark, tokens),
                      const SizedBox(width: 6),
                      _buildFilterPill('starred', 'Starred (${_projects.where((p) => p.isFavorite).length})', Icons.star_rounded, isDark, tokens),
                    ],
                  ),
                ),
              ),
              if (MediaQuery.of(context).size.width >= 600) ...[
                const SizedBox(width: 8),
                _buildThemePickerTriggerPill(context, tokens, isDark, isCompact: false),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // First-Run Welcome Card
          if (!settings.haveUserStartedApp) ...[
            _buildFirstRunWelcomeCard(context, isDark, isGlass),
            const SizedBox(height: 16),
          ],

          // Header with Bulk Delete Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _projectFilter == 'starred'
                      ? 'Starred Artboards'
                      : (_projectFilter == 'recent' ? 'Recent Work' : 'All Artboards'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? FormaColors.darkTextMain
                        : FormaColors.lightTextMain,
                  ),
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
                  '${filtered.length} artboards',
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

          // Responsive Projects Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final int crossAxisCount;
                      final double aspectRatio;

                      if (width < 600) {
                        // 1 column on vertical mobile phones (<600px width)
                        crossAxisCount = 1;
                        if (settings.cardDensity == CardDensity.compact) {
                          aspectRatio = 1.45;
                        } else if (settings.cardDensity == CardDensity.spacious) {
                          aspectRatio = 1.25;
                        } else {
                          aspectRatio = 1.35;
                        }
                      } else if (width < 1000) {
                        // 2 columns on tablets (600px <= width < 1000px)
                        crossAxisCount = 2;
                        if (settings.cardDensity == CardDensity.compact) {
                          aspectRatio = 1.25;
                        } else if (settings.cardDensity == CardDensity.spacious) {
                          aspectRatio = 1.05;
                        } else {
                          aspectRatio = 1.15;
                        }
                      } else {
                        // 3-4 columns on desktop (>=1000px)
                        crossAxisCount = (width / 320).floor().clamp(3, 4);
                        if (settings.cardDensity == CardDensity.compact) {
                          aspectRatio = 1.20;
                        } else if (settings.cardDensity == CardDensity.spacious) {
                          aspectRatio = 1.0;
                        } else {
                          aspectRatio = 1.10;
                        }
                      }

                      // Total items: 1 (Permanent New Artboard Card) + filtered projects
                      final totalItems = 1 + filtered.length;

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
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
                      'Welcome to Forma Studio v0.4',
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

  // --- PERMANENT "NEW ARTBOARD" CARD ---
  Widget _buildNewDesignCard(
    BuildContext context,
    bool isDark,
    bool isGlass,
    AppSettings settings,
  ) {
    final tokens = FormaTheme.tokensOf(context);

    final cardInner = Container(
      decoration: BoxDecoration(
        color: isGlass
            ? tokens.surface
            : (isDark ? FormaColors.darkSurface : FormaColors.lightSurface),
        borderRadius: BorderRadius.circular(19),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  tokens.accent.withValues(alpha: 0.08),
                  tokens.accent.withValues(alpha: 0.02),
                ]
              : [
                  tokens.accent.withValues(alpha: 0.06),
                  tokens.accent.withValues(alpha: 0.01),
                ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [tokens.accent, tokens.accent.withValues(alpha: 0.75)],
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: 0.35),
                  offset: const Offset(0, 4),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'New Artboard',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : FormaColors.lightTextMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create blank artboard',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? FormaColors.darkTextMuted
                  : FormaColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );

    final cardWithGradientEdge = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.accent.withValues(alpha: isDark ? 0.45 : 0.35),
            tokens.accent.withValues(alpha: 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.accent.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: cardInner,
    );

    Widget resultCard = cardWithGradientEdge;
    if (isGlass) {
      resultCard = LiquidGlassBox(
        radius: 20,
        blur: settings.glassBlur,
        opacity: settings.glassOpacity,
        hasSpecular: settings.glassSpecular,
        hasSheen: settings.glassSheen,
        child: resultCard,
      );
    }

    return _TactileCard(
      onTap: _createBlankProject,
      child: resultCard,
    );
  }

  Widget _buildProjectCard(
    ProjectModel project,
    bool isDark,
    bool isGlass,
    AppSettings settings,
  ) {
    final tokens = FormaTheme.tokensOf(context);
    final dateFormat = DateFormat('MMM d • h:mm a');
    final isSelected = _selectedProjectIds.contains(project.id);
    final firstPageBg = project.pages.isNotEmpty
        ? project.pages.first.backgroundColor
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    final cardInner = Container(
      decoration: BoxDecoration(
        color: isGlass
            ? tokens.surface
            : (isDark ? FormaColors.darkSurface : FormaColors.lightSurface),
        borderRadius: BorderRadius.circular(19),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Artboard Preview Well
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: firstPageBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size.infinite,
                            painter: _LiveArtboardThumbnailPainter(
                              project: project,
                              isDark: isDark,
                              pageBg: firstPageBg,
                            ),
                          ),
                          if (project.nodes.isEmpty)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.draw_rounded,
                                  size: 28,
                                  color: FormaColors.primaryBlue.withValues(alpha: 0.8),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Empty Artboard',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: (firstPageBg.computeLuminance() > 0.5)
                                        ? Colors.black54
                                        : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top-Left: Layer Count Badge
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_rounded, size: 10, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${project.nodes.length} ${project.nodes.length == 1 ? "layer" : "layers"}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top-Right: 1-Click Favorite Button
                if (!_isBulkSelectMode)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(project),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: project.isFavorite
                              ? Colors.pinkAccent.withValues(alpha: 0.28)
                              : Colors.black.withValues(alpha: 0.5),
                          border: Border.all(
                            color: project.isFavorite
                                ? Colors.pinkAccent.withValues(alpha: 0.8)
                                : Colors.white24,
                            width: 0.8,
                          ),
                          boxShadow: project.isFavorite
                              ? [
                                  BoxShadow(
                                    color: Colors.pinkAccent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          project.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 14,
                          color: project.isFavorite
                              ? Colors.pinkAccent
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Bulk selection checkbox
                if (_isBulkSelectMode)
                  Positioned(
                    top: 6,
                    right: 6,
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
          const SizedBox(height: 10),

          // Project Title & Options Row
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
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
                      case 'favorite':
                        _toggleFavorite(project);
                        break;
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
                    PopupMenuItem(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(
                            project.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: project.isFavorite ? Colors.pinkAccent : null,
                          ),
                          const SizedBox(width: 8),
                          Text(project.isFavorite ? 'Remove Favorite' : 'Favorite'),
                        ],
                      ),
                    ),
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
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.download_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Export'),
                        ],
                      ),
                    ),
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
          const SizedBox(height: 3),

          // Metadata: Clock Icon + Formatted Timestamp + Multi-Page Count
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 11.5,
                color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
              ),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(project.updatedAt),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? FormaColors.darkTextMuted
                      : FormaColors.lightTextMuted,
                ),
              ),
              const Spacer(),
              if (project.pages.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: tokens.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${project.pages.length} pages',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: tokens.accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    // Outer Gradient Edge Wrapper
    final cardWithGradientEdge = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  tokens.accent.withValues(alpha: 0.40),
                  tokens.accent.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.04),
                ]
              : [
                  tokens.accent.withValues(alpha: 0.35),
                  tokens.accent.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.04),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : tokens.accent.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2), // 1.2px Gradient edge
      child: cardInner,
    );

    Widget resultCard = cardWithGradientEdge;
    if (isGlass) {
      resultCard = LiquidGlassBox(
        radius: 20,
        blur: settings.glassBlur,
        opacity: settings.glassOpacity,
        hasSpecular: settings.glassSpecular,
        hasSheen: settings.glassSheen,
        child: resultCard,
      );
    }

    return _TactileCard(
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
      child: resultCard,
    );
  }

  Widget _buildTemplatesView(
    BuildContext context,
    bool isDark,
    bool isGlass,
    AppSettings settings,
  ) {
    final allTemplates = TemplateService.getTemplates();
    final templates = allTemplates.where((t) => t.category == _templateCategory).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editable Design Templates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? FormaColors.darkTextMain
                          : FormaColors.lightTextMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _templateCategory == 'components'
                        ? 'Components, Buttons, Vector Glyphs, and Cosmic Glass Cards'
                        : 'Full app screens, dashboards, onboarding, and ecommerce views',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? FormaColors.darkTextMuted
                          : FormaColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category Switcher
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'components',
                label: Text('UI Components & Kits'),
                icon: Icon(Icons.widgets_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'screens',
                label: Text('App Mockups & Screens'),
                icon: Icon(Icons.smartphone_rounded, size: 16),
              ),
            ],
            selected: {_templateCategory},
            onSelectionChanged: (val) => setState(() => _templateCategory = val.first),
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

  Widget _buildChangelogView(
    BuildContext context,
    bool isDark,
    bool isGlass,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              final infoColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's New & Version Changelog",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? FormaColors.darkTextMain : FormaColors.lightTextMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track the latest features, engine updates, and release notes',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
                    ),
                  ),
                ],
              );

              final manualButton = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FormaColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: const Text('Open 10-Page Manual', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => const FormaDocumentationDialog(),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoColumn,
                    const SizedBox(height: 12),
                    manualButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: infoColumn),
                  const SizedBox(width: 12),
                  manualButton,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildVersionCard(
                  version: 'v0.4.0 (Latest Release)',
                  date: 'Multiplayer & Icon Studio Edition',
                  tagColor: const Color(0xFF10B981),
                  isLatest: true,
                  isDark: isDark,
                  features: const [
                    '🌐 Multiplayer Collaboration (Firebase + LAN Mesh) & Room Operator Menu: Instant 1-click Live Room hosting with 6-character codes, real-time remote cursors & selection badges, live node delta sync, and full Room Operator Menu (roles, room lock, kick, force sync).',
                    '📄 HTML File Importer: Import .html / .htm layouts directly into native Forma Studio design frames, rectangles, and styled text nodes.',
                    '🎨 Bounded Icon Canvas Studio & Multi-Tab System: Persistent tab bar to switch between Main Canvas and bounded Icon Canvases (16x16 to 128x128) with pixel grids, keyline guides, live multi-scale previews, and fixed 1:1 cursor coordinates.',
                    '🔤 Offline Font Importer & Fixed Effects System: Load local .ttf / .otf / .woff fonts offline across restarts, plus fixed drop shadow, inner shadow, glow, and background blur rendering with Spread controls.',
                    '🚫 Removed — Liquid Glass & Cosmic Glassmorphism Themes: Streamlined to Modern Studio Light, Obsidian Studio Dark, and System Default for cleaner focus and WCAG AAA contrast.',
                    '🚫 Removed — Simulated Fake Bot Collaborators: Eliminated fake mock teammates and erratic wandering bot cursors; rooms exclusively connect genuine designers.',
                  ],
                ),
                const SizedBox(height: 14),
                _buildVersionCard(
                  version: 'v0.3.0',
                  date: 'Previous Studio Edition',
                  tagColor: const Color(0xFF64748B),
                  isLatest: false,
                  isDark: isDark,
                  features: const [
                    '🎯 Automatic Curve Bending Vector Pen: Every new anchor point now bends interactively on drag and locks curves upon pointer release. Tap/click immediately lets you add more points smoothly.',
                    '🔤 Custom Font Import (.ttf / .otf): Import any font file into the engine with one click; rendered instantly on the canvas and in the properties typography library.',
                    '📐 Advanced Spatial Alignment & Dimension Matching: Align by Left, Center, Right, Top, Middle, Bottom, with Match Width, Match Height, and Make Square constraints.',
                    '💎 Revamped Liquid Glass Theme & Low-Shadow UI: Conforms to modern UI rules with softer ambient shadows, crisp borders, and refined glassmorphism styling.',
                    '📁 Windows-Style Drag-to-Folder Nesting: Drag any layer or shape and drop it directly onto a folder in the Layers panel to nest it.',
                    '📋 Global Smart Paste: Seamlessly paste shapes, vector paths, or external copied text with auto-conversion into canvas text elements.',
                    '📱 Vertical Mobile UI Polishing: Fixed phone layout overflow bugs, thumb-friendly tap targets, and dedicated mobile toolbar actions.',
                  ],
                ),
                const SizedBox(height: 14),
                _buildVersionCard(
                  version: 'v0.2.0',
                  date: 'Previous Release',
                  tagColor: const Color(0xFF3B82F6),
                  isLatest: false,
                  isDark: isDark,
                  features: const [
                    '📱 Mobile Portrait Mode Optimization: Bottom dock now has a single unified Shapes menu with persistent canvas background color swatch.',
                    '✒️ Vector Pen & Dedicated Drawn Layer: Freehand & Pen drafting automatically places all strokes into a single clean "Drawn Layer".',
                    '🔘 Explicit Edit Vector Path Button: Entered cleanly through toolbar or properties button.',
                    '📐 Properties Tab Overhaul: Recreated layout with clear text indicators and badges for every field.',
                    '✨ Advanced Effects Suite: Sliders for Blur Radius, Spread, Darkness, Offsets, and one-tap presets.',
                    '📁 Windows Explorer Folders in Layers with chevrons and gold folder icons.',
                  ],
                ),
                const SizedBox(height: 14),
                _buildVersionCard(
                  version: 'v0.1.5',
                  date: 'Polygon & Fillet Release',
                  tagColor: const Color(0xFF8B5CF6),
                  isLatest: false,
                  isDark: isDark,
                  features: const [
                    '🔺 Triangle & Polygon Tool with 3 to 12 corners and quadratic Bezier fillet radius (0 to 50 px).',
                    '🔒 Shift Key 1:1 Aspect Constraint: Hold Shift to draw and resize perfect circles, squares, and equilateral shapes.',
                    '📦 SVG Recursive Export Overhaul: Full nested hierarchy for frames/groups and base64 embedded images.',
                  ],
                ),
                const SizedBox(height: 14),
                _buildVersionCard(
                  version: 'v0.1.2',
                  date: 'Format & Prototype Edition',
                  tagColor: const Color(0xFF64748B),
                  isLatest: false,
                  isDark: isDark,
                  features: const [
                    'Universal Format Service: Export and import Figma (.fig), AutoCAD DXF, PostScript EPS.',
                    'Interactive Prototype Player with Smart Animate and transition triggers.',
                  ],
                ),
                const SizedBox(height: 14),
                _buildVersionCard(
                  version: 'v0.1.1',
                  date: 'Core Foundation Release',
                  tagColor: const Color(0xFF94A3B8),
                  isLatest: false,
                  isDark: isDark,
                  features: const [
                    'Infinite canvas with pan, zoom (1% - 5000%), and layers panel.',
                    'Core shapes, typography, fills, strokes, and gradients.',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard({
    required String version,
    required String date,
    required Color tagColor,
    required bool isLatest,
    required bool isDark,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest ? tagColor : (isDark ? FormaColors.darkBorder : FormaColors.lightBorder),
          width: isLatest ? 1.5 : 1.0,
        ),
        boxShadow: isLatest
            ? [
                BoxShadow(
                  color: tagColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  version,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? FormaColors.darkTextMuted : FormaColors.lightTextMuted,
                ),
              ),
              if (isLatest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: isDark ? FormaColors.darkTextMain : FormaColors.lightTextMain,
                      ),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About Forma Studio'),
        content: const Text(
          'Forma Studio is a free, mobile-first, Figma-inspired design application with a soft blue-gray neumorphic interface.\n\n'
          'Version: v0.4.0 (Latest Release)\n\n'
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

class _LiveArtboardThumbnailPainter extends CustomPainter {
  final ProjectModel project;
  final bool isDark;
  final Color pageBg;

  _LiveArtboardThumbnailPainter({
    required this.project,
    required this.isDark,
    required this.pageBg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Draw blueprint grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    const step = 14.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (project.nodes.isEmpty) return;

    // Calculate bounding box of all visible nodes
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final node in project.nodes.values) {
      if (!node.isVisible) continue;
      if (node.x < minX) minX = node.x;
      if (node.y < minY) minY = node.y;
      if (node.x + node.width > maxX) maxX = node.x + node.width;
      if (node.y + node.height > maxY) maxY = node.y + node.height;
    }

    if (!minX.isFinite || !maxX.isFinite || maxX <= minX || maxY <= minY) {
      return;
    }

    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;

    const padding = 16.0;
    final availW = math.max(10.0, size.width - padding * 2);
    final availH = math.max(10.0, size.height - padding * 2);

    final scaleX = availW / contentWidth;
    final scaleY = availH / contentHeight;
    final scale = math.min(scaleX, scaleY).clamp(0.001, 1.0);

    final offsetX = padding + (availW - contentWidth * scale) / 2 - minX * scale;
    final offsetY = padding + (availH - contentHeight * scale) / 2 - minY * scale;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    ));

    for (final node in project.nodes.values) {
      if (!node.isVisible) continue;

      final nx = node.x * scale + offsetX;
      final ny = node.y * scale + offsetY;
      final nw = math.max(2.0, node.width * scale);
      final nh = math.max(2.0, node.height * scale);

      Color fillColor = FormaColors.primaryBlue.withValues(alpha: 0.6);
      if (node.fills.isNotEmpty && node.fills.first.isVisible) {
        fillColor = node.fills.first.color.withValues(alpha: (node.fills.first.opacity * node.opacity).clamp(0.0, 1.0));
      }

      final rect = Rect.fromLTWH(nx, ny, nw, nh);
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      if (node.type == NodeType.ellipse) {
        canvas.drawOval(rect, fillPaint);
      } else {
        final radius = Radius.circular(math.min(node.cornerRadii.topLeft * scale, 6.0));
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), fillPaint);
      }

      final strokePaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      if (node.type == NodeType.ellipse) {
        canvas.drawOval(rect, strokePaint);
      } else {
        final radius = Radius.circular(math.min(node.cornerRadii.topLeft * scale, 6.0));
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), strokePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiveArtboardThumbnailPainter oldDelegate) =>
      oldDelegate.project.updatedAt != project.updatedAt ||
      oldDelegate.isDark != isDark ||
      oldDelegate.pageBg != pageBg;
}

class _TactileCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactileCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_TactileCard> createState() => _TactileCardState();
}

class _TactileCardState extends State<_TactileCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
