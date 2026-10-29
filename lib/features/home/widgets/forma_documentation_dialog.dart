import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../app/theme/forma_colors.dart';
import '../../../app/theme/neumorphic.dart';
import '../../../app/widgets/forma_logo.dart';

class FormaDocumentationDialog extends StatefulWidget {
  const FormaDocumentationDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const FormaDocumentationDialog(),
    );
  }

  @override
  State<FormaDocumentationDialog> createState() =>
      _FormaDocumentationDialogState();
}

class _FormaDocumentationDialogState extends State<FormaDocumentationDialog> {
  int _currentPage = 0;
  bool _isGeneratingPdf = false;

  static const int _totalPages = 10;

  static const List<Map<String, dynamic>> _chapters = [
    {
      'number': 1,
      'title': 'Workspace Anatomy & Viewport Navigation',
      'icon': Icons.space_dashboard_rounded,
      'subtitle': 'Canvas, Pan/Zoom Gestures, Mobile Unrotated Dock & View Controls',
      'highlights': [
        'Universal Canvas: Infinite 2D coordinate space with smooth 10% to 500% zoom scaling.',
        'Touch & Mouse Navigation: Pinch with 2 fingers to zoom; drag with 2 fingers or hold Spacebar + Drag (or Hand tool H) to pan.',
        'Mobile Portrait "Unrotated" Mode: Clean bottom dock featuring a unified Shapes menu button, persistent Canvas Background Color swatch, and essential mode switches.',
        'Canvas Background Color: Tap the canvas background swatch in the mobile dock or properties panel to immediately repaint the entire workspace background.',
        'Rulers & Grid: Press Shift+R to toggle pixel-perfect alignment rulers and canvas grid overlay.',
      ],
      'tips': 'Tip: Press Ctrl+0 (or Cmd+0) anytime to immediately reset the canvas zoom to 100% and center your work.',
    },
    {
      'number': 2,
      'title': 'Vector Pen & Bézier Curve Mastery',
      'icon': Icons.polyline_rounded,
      'subtitle': 'Dedicated Drawn Layer, Anchor Points, Tangent Handles & Safe Vector Mode',
      'highlights': [
        'Dedicated "Drawn Layer": All pen and freehand vector paths are now automatically consolidated into a clean, dedicated Drawn Layer for effortless organization.',
        'Bézier Drafting (P): Click or tap to place sharp corner nodes; click/tap and drag outwards to pull smooth tangent direction handles.',
        'Smooth vs Sharp Conversion: Select any anchor point and toggle between Smooth Curve and Sharp Corner with a single tap on the floating Vector HUD.',
        'Path Closing: Click the initial anchor point or tap "Close Path" on the HUD to create a closed, fillable polygon/shape.',
        'Safe Vector Editing: Double-clicking shapes will no longer accidentally trigger vector mode. Open vector editing intentionally via the toolbar Pen icon or the "Edit Vector Path" button at the bottom of the Properties tab.',
      ],
      'tips': 'Tip: Tap "Finish Path" on the floating HUD or press Escape to cleanly exit vector editing.',
    },
    {
      'number': 3,
      'title': 'Geometric Shapes, Triangles & Fillet Radii',
      'icon': Icons.change_history_rounded,
      'subtitle': 'Primitive Shapes, Shift-Key 1:1 Constraints, Side Counts & Fillet Curvature',
      'highlights': [
        'Complete Shape Library: Rectangles (R), Rounded Rects, Ellipses/Circles (O), Triangles (Y), Polygons, Stars, and Lines.',
        'Shift-Key Perfect Geometry: Hold the Shift key while drawing or resizing any shape to lock a perfect 1:1 aspect ratio (creates exact squares, perfect circles, and equilateral triangles).',
        'Triangle & Polygon Corner Controls: Select any triangle or polygon to adjust its corner count (from 3 to 12 vertices) and corner fillet radius (0 to 50 px) directly from the Properties Panel.',
        'Frame Creation (F): Draw responsive artboard containers with preset screen dimensions (iPhone, iPad, Desktop, Banner).',
        'Smart Snapping: Automatically snaps object edges and centers to adjacent shapes with magnetic alignment guidelines.',
      ],
      'tips': 'Tip: You can dynamically turn a triangle into a pentagon, hexagon, or octagon by simply raising the corner count slider in the Properties panel.',
    },
    {
      'number': 4,
      'title': 'Windows Explorer Folders & Layer Hierarchy',
      'icon': Icons.folder_copy_rounded,
      'subtitle': 'Collapsible Windows-Style Folders, Drag-and-Drop Reordering & Stacking Order',
      'highlights': [
        'Windows Explorer Folders: Group related layers into Windows-style folders complete with expandable/collapsible chevrons (> and v) and classic folder icons.',
        'Recursive Visibility: Collapsing a parent folder cleanly hides all its nested children from view in the Layers list, saving vertical screen space in complex projects.',
        'Reliable Drag-and-Drop Reordering: Each layer row features an explicit grip handle (ReorderableDragStartListener) so you can smoothly drag layers up or down on touch and mouse without accidental selections.',
        'Header Folder Creation: Tap the "New Folder" icon in the Layers panel header to immediately generate an organized folder grouping.',
        'Stacking Controls: Quick buttons for Bring to Front, Bring Forward, Send Backward, and Send to Back in the Properties panel.',
      ],
      'tips': 'Tip: Double-click any layer name in the panel to rename it instantly.',
    },
    {
      'number': 5,
      'title': 'Styling, Gradients, Effects & WCAG Contrast',
      'icon': Icons.palette_rounded,
      'subtitle': 'Linear/Radial Gradients, Drop Shadows, Outer Glows, Glass Blurs & Accessibility',
      'highlights': [
        'Color & Gradient Engines: Solid fills, Linear gradients, Radial gradients, and Angular gradients with full angle rotation and multi-stop color controls.',
        'Deep Effects Customization: Drop Shadows and Outer Glows feature granular controls for Darkness/Opacity %, Blur Radius, Spread Distance, and X/Y directional offsets.',
        'Quick Effect Presets: One-click presets for Soft Drop Shadow, Intense Neon Glow, Frosted Glass Backdrop Blur, and Subtle Elevation.',
        'WCAG 2.1 Contrast Checker: Real-time calculation of contrast ratios against background layers with instant AA / AAA compliance badges.',
        'Blend Modes: Support for Multiply, Screen, Overlay, Soft Light, and Color Dodge.',
      ],
      'tips': 'Tip: The Frosted Glass effect looks incredible when paired with the new Glassmorphism app theme!',
    },
    {
      'number': 6,
      'title': 'Cross-Canvas Copy-Paste & Media Import',
      'icon': Icons.content_paste_go_rounded,
      'subtitle': 'System Clipboard Integration, Multi-Node Copy, Drag-and-Drop .forma & Image Pasting',
      'highlights': [
        'Cross-Canvas Copy & Paste: Select single or multiple shapes, press Ctrl+C (or Cmd+C) to copy, switch pages or even open a different canvas project, and press Ctrl+V to paste with all dimensions, fills, strokes, and effects preserved.',
        'System Clipboard JSON Serialization: Copied elements are synced to the OS clipboard, enabling sharing between app instances.',
        'Drag-and-Drop File Import: Drag and drop any .forma project file directly onto the Home Screen or editor window to import it instantly.',
        'Direct Image Pasting: Copy any PNG/JPG image from your web browser or screenshot tool and paste it directly onto the canvas with Ctrl+V.',
        'Image Studio: Mask images inside geometric shapes, adjust opacity, and fine-tune corner radiuses.',
      ],
      'tips': 'Tip: Hold Shift while clicking multiple layers on canvas to group-select them before copying.',
    },
    {
      'number': 7,
      'title': 'Timeline Motion Engine & 100+ Animation Presets',
      'icon': Icons.animation_rounded,
      'subtitle': 'Keyframing, Motion Presets, Timeline Scrubbing, Easing Curves & Playback',
      'highlights': [
        'Integrated Timeline Panel: Access the bottom motion timeline anytime by toggling the Motion panel in the top header.',
        '100+ Curated Motion Presets: Fast one-click animations including Bounce In/Out, Pop, Pulse, Slide Up/Down/Left/Right, Float, Wobble, Strobe, Orbit, and Elastic Snap.',
        'Keyframing Capabilities: Animate Position (X/Y), Dimensions (W/H), Opacity (0% - 100%), and Rotation (0° - 360°) across customizable time tracks.',
        'Playback Controls: Real-time play, pause, rewind, loop toggling, and draggable timeline time scrubber.',
        'Configurable Frame Rates: Switch smoothly between 24 FPS (cinematic), 30 FPS (standard), and 60 FPS (ultra-smooth).',
      ],
      'tips': 'Tip: Apply a preset first, then tweak individual keyframes on the timeline for custom easing!',
    },
    {
      'number': 8,
      'title': 'Prototyping & Gesture Interactions',
      'icon': Icons.alt_route_rounded,
      'subtitle': 'Interactive Node Linking, Triggers, Smart Animate & Live Presentation Mode',
      'highlights': [
        'Visual Wire Linking: Connect any button, shape, or frame to another page using interactive prototype destination links.',
        'Event Triggers: Configure On Tap (Click), On Hover (Mouse Over), On Long Press, and On Drag events.',
        'Smart Animate Transitions: Smoothly interpolate matching layers across artboards with ease-in, ease-out, or spring curves.',
        'Device Presentation Mode: Click the "Play Prototype" button in the top bar to run an interactive preview with touch/click simulation.',
        'Fixed Header & Bottom Bars: Mark any layer as "Fix position when scrolling" to simulate realistic mobile and desktop navbars.',
      ],
      'tips': 'Tip: Press Esc while in Presentation mode to quickly return to the editor.',
    },
    {
      'number': 9,
      'title': 'Universal Format Export Matrix',
      'icon': Icons.file_download_rounded,
      'subtitle': 'Clean SVG, Multi-Scale PNG, Vector PDF, and Native Figma/Sketch/XD Bundles',
      'highlights': [
        'Recursive Vector SVG: Clean, production-ready SVG output featuring nested groups, fills, strokes, drop shadow filter definitions, and embedded bitmap assets.',
        'Crisp PNG Rasterization: High-resolution raster export at 1x, 2x (Retina), 3x, and 4x (Ultra HD) scales with transparent background support.',
        'Multi-Page Vector PDF: Export individual artboards or the complete project as an industry-standard vector PDF document.',
        'Industry Interchange Bundles: Export complete archive bundles compatible with Figma (.fig), Sketch (.sketch), and Adobe XD (.xd).',
        'Native Forma Bundle (.forma): Encrypted local-first project bundle containing all pages, design nodes, vector paths, and timeline keyframes.',
      ],
      'tips': 'Tip: You can print or save this entire 10-page manual directly to PDF using the "Print / Save PDF" button below!',
    },
    {
      'number': 10,
      'title': '120+ Command Palette & Windows Native Hotkeys',
      'icon': Icons.terminal_rounded,
      'subtitle': 'Searchable Action Palette, Windows F11 Fullscreen, Cache Cleanup & Full Hotkey Matrix',
      'highlights': [
        '120+ Command Palette: Press Ctrl+K (or Cmd+K) anywhere to open the instant fuzzy-search palette with categorized commands for Tools, Edit, View, Canvas, Motion, and System.',
        'Windows Native Commands: Dedicated commands for F11 Fullscreen toggle, Memory Cache Purge, Hardware Diagnostic Specs, and Project JSON export.',
        'Essential Hotkeys: V (Select), H (Hand/Pan), R (Rectangle), O (Ellipse/Circle), T (Text), P (Pen/Vector), Y (Triangle), F (Frame), Del/Backspace (Delete selected).',
        'History Shortcuts: Ctrl+Z (Undo) and Ctrl+Y / Ctrl+Shift+Z (Redo) with deep undo stack preservation.',
        'Clipboard Shortcuts: Ctrl+C (Copy), Ctrl+V (Paste), Ctrl+D (Duplicate in-place), Ctrl+A (Select all layers).',
      ],
      'tips': 'Tip: Press ? or / anytime in the editor to quickly bring up this manual or the command palette.',
    },
  ];

  Future<void> _exportManualAsPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();

      for (final ch in _chapters) {
        final number = ch['number'] as int;
        final title = ch['title'] as String;
        final subtitle = ch['subtitle'] as String;
        final highlights = ch['highlights'] as List<String>;
        final tips = ch['tips'] as String;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(36),
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Page Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'FORMA STUDIO • USER MANUAL',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.Text(
                        'Page $number of $_totalPages',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey300, thickness: 1),
                  pw.SizedBox(height: 14),

                  // Chapter Title
                  pw.Text(
                    'Chapter $number: $title',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.blueGrey600,
                    ),
                  ),
                  pw.SizedBox(height: 18),

                  // Key Highlights
                  pw.Text(
                    'CORE CAPABILITIES & WORKFLOWS',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  ...highlights.map(
                    (point) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '• ',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              point,
                              style: const pw.TextStyle(
                                fontSize: 10.5,
                                color: PdfColors.grey900,
                                lineSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.Spacer(),

                  // Pro Tip Box
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Text(
                      tips,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // Footer
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Forma Studio v1.3 • 100% Free & Open-Source Vector Design Suite',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'https://github.com/kkboss111/forma-studio',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.blue700,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Forma_Studio_User_Manual_v1.3.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final chapter = _chapters[_currentPage];

    final number = chapter['number'] as int;
    final title = chapter['title'] as String;
    final icon = chapter['icon'] as IconData;
    final subtitle = chapter['subtitle'] as String;
    final highlights = chapter['highlights'] as List<String>;
    final tips = chapter['tips'] as String;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: math.min(size.width - 24, 820),
        height: math.min(size.height * 0.90, 720),
        decoration: BoxDecoration(
          color: isDark ? FormaColors.darkSurface : FormaColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? FormaColors.darkBorder : FormaColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  const FormaLogo(size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forma Studio Interactive User Manual',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? FormaColors.darkTextMain
                                : FormaColors.lightTextMain,
                          ),
                        ),
                        Text(
                          '10-Page Comprehensive Guide • Page $number of $_totalPages',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: FormaColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Print / Save PDF Button
                  NeuButton(
                    onPressed: _isGeneratingPdf ? null : _exportManualAsPdf,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isGeneratingPdf)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 16,
                            color: FormaColors.primaryBlue,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _isGeneratingPdf ? 'Exporting...' : 'Print / Save PDF',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    tooltip: 'Close Guide',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Chapter Dropdown Jump Navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: isDark
                  ? FormaColors.darkWellBg.withValues(alpha: 0.3)
                  : FormaColors.lightWellBg.withValues(alpha: 0.4),
              child: Row(
                children: [
                  const Text(
                    'Jump to Chapter: ',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _currentPage,
                        isDense: true,
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? FormaColors.darkTextMain
                              : FormaColors.lightTextMain,
                        ),
                        items: List.generate(_totalPages, (i) {
                          final ch = _chapters[i];
                          return DropdownMenuItem<int>(
                            value: i,
                            child: Text(
                              'Ch. ${ch['number']}: ${ch['title']}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _currentPage = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Current Page Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 18,
                ),
                children: [
                  // Chapter Header Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FormaColors.primaryBlue.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: FormaColors.primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: FormaColors.primaryBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, size: 24, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CHAPTER $number',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: FormaColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? FormaColors.darkTextMain
                                      : FormaColors.lightTextMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 11.5,
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
                  const SizedBox(height: 18),

                  // Highlights List
                  ...highlights.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? FormaColors.darkWellBg.withValues(alpha: 0.6)
                              : FormaColors.lightWellBg.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? FormaColors.darkBorder
                                : FormaColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2, right: 10),
                              child: Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: FormaColors.primaryBlue,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.5,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.88)
                                      : FormaColors.lightTextMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Pro Tip Box
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tips,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.amber.shade200
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Bottom Navigation Footer (Previous, Page Dots, Next)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  NeuButton(
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 12),
                        SizedBox(width: 6),
                        Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Quick Page Dots / Indicator
                  Text(
                    'Page ${_currentPage + 1} of $_totalPages',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? FormaColors.darkTextMuted
                          : FormaColors.lightTextMuted,
                    ),
                  ),
                  const Spacer(),

                  if (_currentPage < _totalPages - 1)
                    NeuButton(
                      isActive: true,
                      onPressed: () => setState(() => _currentPage++),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    )
                  else
                    NeuButton(
                      isActive: true,
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Complete',
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
            ),
          ],
        ),
      ),
    );
  }
}
