import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/core/export/universal_format_service.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/paint_styles.dart';
import 'package:forma_studio/domain/models/text_data.dart';
import 'package:forma_studio/domain/services/node_render_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final encoder = Encoding.getByName('utf-8')!;
  final decoder = Encoding.getByName('utf-8')!;

  group('UniversalFormatService Multi-Format Tests', () {
    test('detectFormat recognizes 12+ industry design formats correctly', () {
      expect(UniversalFormatService.detectFormat('design.fig'), SupportedFormat.figma);
      expect(UniversalFormatService.detectFormat('app.sketch'), SupportedFormat.sketch);
      expect(UniversalFormatService.detectFormat('wireframe.xd'), SupportedFormat.adobeXd);
      expect(UniversalFormatService.detectFormat('icon.svg'), SupportedFormat.svg);
      expect(UniversalFormatService.detectFormat('portfolio.forma'), SupportedFormat.forma);
      expect(UniversalFormatService.detectFormat('tokens.json'), SupportedFormat.jsonTokens);
      expect(UniversalFormatService.detectFormat('presentation.pdf'), SupportedFormat.pdf);
      expect(UniversalFormatService.detectFormat('logo.eps'), SupportedFormat.eps);
      expect(UniversalFormatService.detectFormat('illustration.ai'), SupportedFormat.eps);
      expect(UniversalFormatService.detectFormat('floorplan.dxf'), SupportedFormat.dxf);
      expect(UniversalFormatService.detectFormat('banner.png'), SupportedFormat.png);
      expect(UniversalFormatService.detectFormat('photo.jpg'), SupportedFormat.jpeg);
      expect(UniversalFormatService.detectFormat('hero.webp'), SupportedFormat.webp);
      expect(UniversalFormatService.detectFormat('template.html'), SupportedFormat.htmlCss);
    });

    test('importFile correctly parses PostScript EPS vector coordinates', () async {
      const epsData = '''
%!PS-Adobe-3.0 EPSF-3.0
10.0 20.0 m
50.0 20.0 l
50.0 80.0 l
10.0 80.0 l
closepath
stroke
''';
      final bytes = Uint8List.fromList(encoder.encode(epsData));
      final res = await UniversalFormatService.importFile(
        filename: 'vector_logo.eps',
        bytes: bytes,
      );

      expect(res.format, SupportedFormat.eps);
      expect(res.nodes.length, 1);
      final node = res.nodes.first;
      expect(node.type, NodeType.vectorPath);
      expect(node.vectorData, isNotNull);
      expect(node.vectorData!.anchors.length, 4);
      expect(node.vectorData!.anchors[0].point.dx, 10.0);
      expect(node.vectorData!.anchors[0].point.dy, 20.0);
      expect(node.vectorData!.anchors[1].point.dx, 50.0);
    });

    test('importFile correctly parses AutoCAD DXF coordinate entities', () async {
      const dxfData = '''
0
SECTION
2
ENTITIES
0
LINE
10
25.0
20
45.0
10
100.0
20
150.0
0
ENDSEC
''';
      final bytes = Uint8List.fromList(encoder.encode(dxfData));
      final res = await UniversalFormatService.importFile(
        filename: 'cad_drawing.dxf',
        bytes: bytes,
      );

      expect(res.format, SupportedFormat.dxf);
      expect(res.nodes.length, 1);
      final node = res.nodes.first;
      expect(node.type, NodeType.vectorPath);
      expect(node.vectorData, isNotNull);
      expect(node.vectorData!.anchors.length, 2);
      expect(node.vectorData!.anchors[0].point.dx, 25.0);
      expect(node.vectorData!.anchors[0].point.dy, 45.0);
      expect(node.vectorData!.anchors[1].point.dx, 100.0);
      expect(node.vectorData!.anchors[1].point.dy, 150.0);
    });

    test('exportToFormat exports EPS and DXF textual formats cleanly', () async {
      final now = DateTime.now();
      final project = ProjectModel(
        id: 'proj-export-test',
        name: 'Export Test',
        createdAt: now,
        updatedAt: now,
        pages: [
          const PageModel(
            id: 'page-1',
            name: 'Page 1',
            rootNodeIds: ['node-1'],
          ),
        ],
        nodes: {
          'node-1': const DesignNode(
            id: 'node-1',
            type: NodeType.roundedRectangle,
            name: 'Card',
            x: 50,
            y: 50,
            width: 200,
            height: 120,
          ),
        },
      );

      final epsBytes = await UniversalFormatService.exportToFormat(
        format: SupportedFormat.eps,
        project: project,
        pageId: 'page-1',
      );
      final epsStr = decoder.decode(epsBytes);
      expect(epsStr.contains('%!PS-Adobe-3.0 EPSF-3.0'), isTrue);
      expect(epsStr.contains('Card'), isTrue);

      final dxfBytes = await UniversalFormatService.exportToFormat(
        format: SupportedFormat.dxf,
        project: project,
        pageId: 'page-1',
      );
      final dxfStr = decoder.decode(dxfBytes);
      expect(dxfStr.contains('SECTION'), isTrue);
      expect(dxfStr.contains('ENTITIES'), isTrue);
    });

    test('exportToFormat produces robust HTML with gradients, shadows and text', () async {
      final now = DateTime.now();
      final project = ProjectModel(
        id: 'html-test',
        name: 'HTML Gradient Test',
        createdAt: now,
        updatedAt: now,
        pages: [
          const PageModel(id: 'page-1', name: 'Page 1', rootNodeIds: ['node-card', 'node-text']),
        ],
        nodes: {
          'node-card': const DesignNode(
            id: 'node-card',
            type: NodeType.roundedRectangle,
            name: 'Gradient Card',
            x: 20,
            y: 20,
            width: 300,
            height: 180,
            fills: [
              DesignFill(
                type: DesignFillType.linearGradient,
                gradientColors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                gradientAngle: 135,
              ),
            ],
            effects: [
              DesignEffect(
                type: DesignEffectType.dropShadow,
                color: Color(0x66000000),
                blurRadius: 16,
                offsetY: 8,
              ),
            ],
          ),
          'node-text': const DesignNode(
            id: 'node-text',
            type: NodeType.text,
            name: 'Title Text',
            x: 40,
            y: 50,
            width: 200,
            height: 40,
            textData: TextNodeData(
              text: 'Pikachu Design',
              fontSize: 24,
              fontFamily: 'Poppins',
            ),
            fills: [DesignFill.solid(Colors.white)],
          ),
        },
      );

      final htmlBytes = await UniversalFormatService.exportToFormat(
        format: SupportedFormat.htmlCss,
        project: project,
        pageId: 'page-1',
      );
      final htmlStr = decoder.decode(htmlBytes);

      expect(htmlStr.contains('<!DOCTYPE html>'), isTrue);
      expect(htmlStr.contains('linear-gradient(135deg'), isTrue);
      expect(htmlStr.contains('box-shadow:'), isTrue);
      expect(htmlStr.contains('Pikachu Design'), isTrue);
      expect(htmlStr.contains('font-family: \'Poppins\''), isTrue);
      expect(htmlStr.contains('fonts.googleapis.com'), isTrue);
    });

    test('Round-trip export and import of Figma (.fig) bundle retains full node graph', () async {
      final now = DateTime.now();
      final original = ProjectModel(
        id: 'fig-roundtrip',
        name: 'Figma Roundtrip',
        createdAt: now,
        updatedAt: now,
        pages: [
          const PageModel(id: 'page-1', name: 'Page 1', rootNodeIds: ['n1']),
        ],
        nodes: {
          'n1': const DesignNode(
            id: 'n1',
            type: NodeType.rectangle,
            name: 'Hero Rect',
            x: 10,
            y: 10,
            width: 100,
            height: 100,
          ),
        },
      );

      final figBytes = await UniversalFormatService.exportToFormat(
        format: SupportedFormat.figma,
        project: original,
        pageId: 'page-1',
      );

      final imported = await UniversalFormatService.importFile(
        filename: 'export.fig',
        bytes: figBytes,
      );

      expect(imported.format, SupportedFormat.figma);
      expect(imported.nodes.length, 1);
      expect(imported.nodes.first.name, 'Hero Rect');
    });

    test('NodeRenderService.measureText returns non-zero dimensions for text content', () {
      const text = TextNodeData(
        text: 'Forma Studio Pro',
        fontSize: 32,
      );
      final size = NodeRenderService.measureText(text);
      expect(size.width, greaterThan(50.0));
      expect(size.height, greaterThan(20.0));
    });
  });
}
