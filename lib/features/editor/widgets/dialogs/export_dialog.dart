import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../domain/models/project_model.dart';
import '../../../../app/theme/forma_colors.dart';
import '../../../../core/export/png_exporter.dart';
import '../../../../core/export/svg_exporter.dart';
import '../../../../core/export/pdf_exporter.dart';
import '../../../../core/export/file_saver_service.dart';
import '../../../../core/export/universal_format_service.dart';
import '../../../settings/models/app_settings.dart';

enum ExportFormat {
  png,
  svg,
  pdf,
  formaPackage,
  figma,
  sketch,
  adobeXd,
  eps,
  dxf,
  tokensJson,
  htmlCss,
}

class ExportDialog extends ConsumerStatefulWidget {
  final ProjectModel project;
  final String activePageId;
  final String? selectedNodeId;

  const ExportDialog({
    super.key,
    required this.project,
    required this.activePageId,
    this.selectedNodeId,
  });

  @override
  ConsumerState<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends ConsumerState<ExportDialog> {
  ExportFormat _format = ExportFormat.png;
  double _scale = 2.0;
  bool _transparentBg = false;
  bool _isExporting = false;
  String? _statusText;

  Future<Uint8List?> _generateExportBytes() async {
    final encoder = Encoding.getByName('utf-8')!;

    switch (_format) {
      case ExportFormat.png:
        return await PngExporter.exportToPng(
          project: widget.project,
          pageId: widget.activePageId,
          frameId: widget.selectedNodeId,
          scale: _scale,
          transparentBg: _transparentBg,
        );

      case ExportFormat.svg:
        final svg = SvgExporter.exportPage(
          widget.project,
          widget.activePageId,
          frameId: widget.selectedNodeId,
        );
        return Uint8List.fromList(encoder.encode(svg));

      case ExportFormat.pdf:
        return await PdfExporter.exportToPdf(
          project: widget.project,
          pageId: widget.activePageId,
          frameId: widget.selectedNodeId,
        );

      case ExportFormat.formaPackage:
        final jsonString = jsonEncode(widget.project.toJson());
        return Uint8List.fromList(encoder.encode(jsonString));

      case ExportFormat.figma:
        return await UniversalFormatService.exportToFormat(
          project: widget.project,
          pageId: widget.activePageId,
          format: SupportedFormat.figma,
          frameId: widget.selectedNodeId,
        );

      case ExportFormat.sketch:
        return await UniversalFormatService.exportToFormat(
          project: widget.project,
          pageId: widget.activePageId,
          format: SupportedFormat.sketch,
          frameId: widget.selectedNodeId,
        );

      case ExportFormat.adobeXd:
        return await UniversalFormatService.exportToFormat(
          project: widget.project,
          pageId: widget.activePageId,
          format: SupportedFormat.adobeXd,
          frameId: widget.selectedNodeId,
        );

      case ExportFormat.eps:
        return await UniversalFormatService.exportToFormat(
          project: widget.project,
          pageId: widget.activePageId,
          format: SupportedFormat.eps,
          frameId: widget.selectedNodeId,
        );

      case ExportFormat.dxf:
        return await UniversalFormatService.exportToFormat(
          project: widget.project,
          pageId: widget.activePageId,
          format: SupportedFormat.dxf,
          frameId: widget.selectedNodeId,
        );

      case ExportFormat.tokensJson:
        final tokensJson = jsonEncode(widget.project.tokens.toJson());
        return Uint8List.fromList(encoder.encode(tokensJson));

      case ExportFormat.htmlCss:
        return await UniversalFormatService.exportToFormat(
          project: widget.project,
          pageId: widget.activePageId,
          format: SupportedFormat.htmlCss,
          frameId: widget.selectedNodeId,
        );
    }
  }

  String _getFilename(String projName) {
    switch (_format) {
      case ExportFormat.png:
        return '${projName}_${_scale.toInt()}x.png';
      case ExportFormat.svg:
        return '$projName.svg';
      case ExportFormat.pdf:
        return '$projName.pdf';
      case ExportFormat.formaPackage:
        return '$projName.forma';
      case ExportFormat.figma:
        return '$projName.fig';
      case ExportFormat.sketch:
        return '$projName.sketch';
      case ExportFormat.adobeXd:
        return '$projName.xd';
      case ExportFormat.eps:
        return '$projName.eps';
      case ExportFormat.dxf:
        return '$projName.dxf';
      case ExportFormat.tokensJson:
        return '${projName}_tokens.json';
      case ExportFormat.htmlCss:
        return '$projName.html';
    }
  }

  String _getMimeType() {
    switch (_format) {
      case ExportFormat.png:
        return 'image/png';
      case ExportFormat.svg:
        return 'image/svg+xml';
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.formaPackage:
      case ExportFormat.tokensJson:
        return 'application/json';
      case ExportFormat.figma:
      case ExportFormat.sketch:
      case ExportFormat.adobeXd:
        return 'application/zip';
      case ExportFormat.eps:
        return 'application/postscript';
      case ExportFormat.dxf:
        return 'application/dxf';
      case ExportFormat.htmlCss:
        return 'text/html';
    }
  }

  Future<void> _handleExport({bool useShareSheet = false}) async {
    setState(() {
      _isExporting = true;
      _statusText = useShareSheet
          ? 'Preparing ${useShareSheet ? "system share" : "download"}...'
          : 'Generating ${_format.name.toUpperCase()}...';
    });

    final projName = widget.project.name.replaceAll(RegExp(r'[^\w\-]'), '_');
    final filename = _getFilename(projName);
    final mimeType = _getMimeType();

    try {
      final bytes = await _generateExportBytes();
      if (bytes != null && bytes.isNotEmpty) {
        bool ok = false;
        if (useShareSheet) {
          ok = await FileSaverService.shareFile(
            bytes: bytes,
            filename: filename,
            mimeType: mimeType,
            subject: 'Forma Studio: ${widget.project.name}',
          );
        } else {
          ok = await FileSaverService.saveFile(
            bytes: bytes,
            filename: filename,
            mimeType: mimeType,
          );
        }

        final sizeStr = FileSaverService.formatFileSize(bytes.length);
        setState(() {
          _statusText = ok
              ? (useShareSheet
                  ? 'Shared $filename ($sizeStr) via system chooser!'
                  : 'Saved $filename ($sizeStr) successfully!')
              : 'Action completed for $filename ($sizeStr)';
        });
      } else {
        setState(() => _statusText = 'Export generated empty content.');
      }
    } catch (e) {
      setState(() => _statusText = 'Export error: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _handleCopyToClipboard() async {
    try {
      String textData = '';
      switch (_format) {
        case ExportFormat.svg:
          textData = SvgExporter.exportPage(
            widget.project,
            widget.activePageId,
            frameId: widget.selectedNodeId,
          );
          break;
        case ExportFormat.formaPackage:
          textData = jsonEncode(widget.project.toJson());
          break;
        case ExportFormat.tokensJson:
          textData = jsonEncode(widget.project.tokens.toJson());
          break;
        default:
          textData = 'Forma Studio - ${widget.project.name}';
      }
      await Clipboard.setData(ClipboardData(text: textData));
      setState(() => _statusText = 'Copied data to clipboard!');
    } catch (e) {
      setState(() => _statusText = 'Copy failed: $e');
    }
  }

  Future<void> _handlePrintPdf() async {
    try {
      setState(() => _statusText = 'Opening Print / PDF Preview...');
      final pdfBytes = await PdfExporter.exportToPdf(
        project: widget.project,
        pageId: widget.activePageId,
        frameId: widget.selectedNodeId,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: widget.project.name,
      );
      setState(() => _statusText = 'Print preview opened!');
    } catch (e) {
      setState(() => _statusText = 'Print error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);
    final size = MediaQuery.of(context).size;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: math.min(size.width - 24, 440),
          constraints: BoxConstraints(maxHeight: size.height * 0.92),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.file_download_outlined,
                          size: 20,
                          color: FormaColors.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Export & Share Design',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? FormaColors.darkTextMain
                                : FormaColors.lightTextMain,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Options
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELECT EXPORT FORMAT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark
                              ? FormaColors.darkTextMuted
                              : FormaColors.lightTextMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFormatChip(ExportFormat.png, 'PNG Image'),
                          _buildFormatChip(ExportFormat.svg, 'SVG Vector'),
                          _buildFormatChip(ExportFormat.pdf, 'PDF Document'),
                          _buildFormatChip(ExportFormat.formaPackage, 'Forma (.forma)'),
                          _buildFormatChip(ExportFormat.figma, 'Figma (.fig)'),
                          _buildFormatChip(ExportFormat.sketch, 'Sketch (.sketch)'),
                          _buildFormatChip(ExportFormat.adobeXd, 'Adobe XD (.xd)'),
                          _buildFormatChip(ExportFormat.eps, 'PostScript (.eps)'),
                          _buildFormatChip(ExportFormat.dxf, 'AutoCAD (.dxf)'),
                          _buildFormatChip(ExportFormat.tokensJson, 'Tokens (.json)'),
                          // HTML/CSS is strictly visible ONLY if enabled in settings
                          if (settings.enableHtmlCodeExport)
                            _buildFormatChip(ExportFormat.htmlCss, 'HTML/CSS Web Code'),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // PNG Specific Scale
                      if (_format == ExportFormat.png) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Resolution Scale',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? FormaColors.darkTextMain
                                    : FormaColors.lightTextMain,
                              ),
                            ),
                            Row(
                              children: [
                                ...[1.0, 2.0, 3.0, 4.0].map((s) {
                                  final isSel = _scale == s;
                                  return GestureDetector(
                                    onTap: () => setState(() => _scale = s),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSel
                                            ? FormaColors.primaryBlue
                                            : (isDark
                                                ? FormaColors.darkWellBg
                                                : FormaColors.lightWellBg),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${s.toInt()}x',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSel ? Colors.white : null,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                GestureDetector(
                                  onTap: () => _showCustomScaleDialog(context, isDark),
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? FormaColors.darkWellBg
                                          : FormaColors.lightWellBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: FormaColors.primaryBlue.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: const Text(
                                      'Custom',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: FormaColors.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Transparent Background'),
                          subtitle: const Text('Export with alpha channel transparency'),
                          value: _transparentBg,
                          onChanged: (val) => setState(() => _transparentBg = val),
                        ),
                      ],

                      // HTML Code notice when selected
                      if (_format == ExportFormat.htmlCss) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FormaColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: FormaColors.primaryBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.code_rounded, size: 20, color: FormaColors.primaryBlue),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Developer Mode: Exports semantic HTML5 + CSS positioning ready for web deployment.',
                                  style: TextStyle(fontSize: 11.5, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_statusText != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _statusText!.contains('error')
                                ? FormaColors.dangerRed.withValues(alpha: 0.12)
                                : FormaColors.successGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusText!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _statusText!.contains('error')
                                  ? FormaColors.dangerRed
                                  : FormaColors.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Actions: Download and System Share
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Save / Download File Button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FormaColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.download_rounded, size: 18),
                            label: Text(
                              _isExporting ? 'Exporting...' : 'Save File',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: _isExporting ? null : () => _handleExport(useShareSheet: false),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // System Share Sheet Button (Android Share Window to All Apps)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text(
                              'Share to App',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: _isExporting ? null : () => _handleExport(useShareSheet: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Secondary Actions (Copy to Clipboard / Print PDF)
                    Row(
                      children: [
                        if (_format == ExportFormat.svg ||
                            _format == ExportFormat.formaPackage ||
                            _format == ExportFormat.tokensJson)
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.copy_rounded, size: 15),
                              label: const Text('Copy Data', style: TextStyle(fontSize: 11)),
                              onPressed: _handleCopyToClipboard,
                            ),
                          ),
                        if (_format == ExportFormat.pdf)
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.print_rounded, size: 15),
                              label: const Text('Print / Preview', style: TextStyle(fontSize: 11)),
                              onPressed: _handlePrintPdf,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomScaleDialog(BuildContext context, bool isDark) async {
    final textController = TextEditingController(text: _scale.toStringAsFixed(1));
    final customVal = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: FormaColors.primaryBlue),
            SizedBox(width: 8),
            Text('Custom Export Scale', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter custom scale factor (e.g. 0.5 to 16.0):',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg,
                suffixText: 'x',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (val) {
                final parsed = double.tryParse(val);
                if (parsed != null && parsed > 0) Navigator.pop(ctx, parsed);
              },
            ),
          ],
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
            onPressed: () {
              final parsed = double.tryParse(textController.text);
              if (parsed != null && parsed > 0) {
                Navigator.pop(ctx, parsed);
              }
            },
            child: const Text('Set Scale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (customVal != null && customVal > 0) {
      setState(() => _scale = customVal.clamp(0.1, 16.0));
    }
  }

  Widget _buildFormatChip(ExportFormat format, String label) {
    final isSelected = _format == format;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() {
        _format = format;
        _statusText = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? FormaColors.primaryBlue
              : (isDark ? FormaColors.darkWellBg : FormaColors.lightWellBg),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? FormaColors.primaryBlue
                : (isDark ? FormaColors.darkBorder : FormaColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}
