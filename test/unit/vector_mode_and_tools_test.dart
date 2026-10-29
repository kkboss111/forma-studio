import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/domain/models/paint_styles.dart';
import 'package:forma_studio/domain/services/node_render_service.dart';
import 'package:forma_studio/core/export/svg_exporter.dart';
import 'package:forma_studio/features/settings/models/app_settings.dart';
import 'package:forma_studio/features/editor/controllers/editor_state.dart';

void main() {
  group('Triangle, Rounded Polygon & Shift Constraint Tests', () {
    test('NodeRenderService produces valid path for 3-corner triangle with fillet radius', () {
      final triangle = DesignNode(
        id: 'tri_1',
        name: 'Triangle',
        type: NodeType.polygon,
        x: 0,
        y: 0,
        width: 100,
        height: 100,
        polygonSides: 3,
        cornerRadii: const CornerRadii.all(8.0),
      );

      final path = NodeRenderService.getNodePath(triangle, const Rect.fromLTWH(0, 0, 100, 100));
      expect(path, isNotNull);
      final bounds = path.getBounds();
      expect(bounds.width, greaterThan(0));
      expect(bounds.height, greaterThan(0));
    });

    test('NodeRenderService supports polygon sides from 3 to 12', () {
      for (int sides = 3; sides <= 12; sides++) {
        final poly = DesignNode(
          id: 'poly_$sides',
          name: 'Poly $sides',
          type: NodeType.polygon,
          x: 10,
          y: 10,
          width: 80,
          height: 80,
          polygonSides: sides,
          cornerRadii: const CornerRadii.all(4.0),
        );
        final path = NodeRenderService.getNodePath(poly, const Rect.fromLTWH(10, 10, 80, 80));
        expect(path.getBounds().isEmpty, isFalse);
      }
    });

    test('EditorTool includes triangle and vectorPen tools', () {
      expect(EditorTool.triangle, isNotNull);
      expect(EditorTool.vectorPen, isNotNull);
    });
  });

  group('SVG Export Recursive Hierarchy & Image Tests', () {
    test('SvgExporter exports recursive children of frames and groups', () {
      final childNode = DesignNode(
        id: 'child_1',
        name: 'Inside Rect',
        type: NodeType.rectangle,
        parentId: 'frame_1',
        x: 20,
        y: 20,
        width: 50,
        height: 50,
        fills: const [DesignFill.solid(Color(0xFFFF0000))],
      );

      final frameNode = DesignNode(
        id: 'frame_1',
        name: 'Parent Frame',
        type: NodeType.frame,
        x: 0,
        y: 0,
        width: 200,
        height: 200,
        childrenIds: ['child_1'],
        fills: const [DesignFill.solid(Color(0xFF00FF00))],
      );

      final project = ProjectModel(
        id: 'proj_svg',
        name: 'SVG Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: [
          const PageModel(
            id: 'page_1',
            name: 'Page 1',
            rootNodeIds: ['frame_1'],
          ),
        ],
        nodes: {
          'frame_1': frameNode,
          'child_1': childNode,
        },
      );

      final svg = SvgExporter.exportPage(project, 'page_1');
      expect(svg, contains('fill="#00FF00"'));
      expect(svg, contains('x="20.0"'));
      expect(svg, contains('fill="#FF0000"'));
    });

    test('SvgExporter embeds image node href with base64 data', () {
      final imgNode = DesignNode(
        id: 'img_1',
        name: 'Photo',
        type: NodeType.image,
        x: 10,
        y: 10,
        width: 100,
        height: 100,
        imagePath: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );

      final project = ProjectModel(
        id: 'proj_img',
        name: 'Image Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: [
          const PageModel(
            id: 'page_1',
            name: 'Page 1',
            rootNodeIds: ['img_1'],
          ),
        ],
        nodes: {'img_1': imgNode},
      );

      final svg = SvgExporter.exportPage(project, 'page_1');
      expect(svg, contains('<image'));
      expect(svg, contains('data:image/png;base64,'));
    });
  });

  group('Theme Modes & Extended Zoom Tests', () {
    test('FormaThemeMode has glassmorphism enum', () {
      expect(FormaThemeMode.glassmorphism, isNotNull);
      expect(FormaThemeMode.values.contains(FormaThemeMode.glassmorphism), isTrue);
    });

    test('AppSettings serializes and restores glassmorphism and extendedZoomLimit', () {
      const settingsGlass = AppSettings(
        themeMode: FormaThemeMode.glassmorphism,
        extendedZoomLimit: true,
      );
      final jsonGlass = settingsGlass.toJson();
      final restoredGlass = AppSettings.fromJson(jsonGlass);
      expect(restoredGlass.themeMode, FormaThemeMode.glassmorphism);
      expect(restoredGlass.extendedZoomLimit, isTrue);
    });
  });
}
