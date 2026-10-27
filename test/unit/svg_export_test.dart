import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/domain/models/paint_styles.dart';
import 'package:forma_studio/domain/models/text_data.dart';
import 'package:forma_studio/core/export/svg_exporter.dart';

void main() {
  group('SVG Export Tests', () {
    test('SvgExporter generates valid XML with nodes and text escaping', () {
      final project = ProjectModel(
        id: 'proj-svg',
        name: 'SVG Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: const [
          PageModel(
            id: 'page-1',
            name: 'Page 1',
            rootNodeIds: ['node-rect', 'node-text'],
          ),
        ],
        nodes: const {
          'node-rect': DesignNode(
            id: 'node-rect',
            type: NodeType.roundedRectangle,
            name: 'Card',
            x: 20,
            y: 30,
            width: 200,
            height: 120,
            fills: [DesignFill.solid(Color(0xFFE6ECF5))],
            strokes: [DesignStroke(color: Color(0xFF2B3445), width: 2)],
            cornerRadii: CornerRadii.all(16),
          ),
          'node-text': DesignNode(
            id: 'node-text',
            type: NodeType.text,
            name: 'Title Text',
            x: 40,
            y: 50,
            width: 150,
            height: 30,
            textData: TextNodeData(text: 'UI & Design <2026>'),
            fills: [DesignFill.solid(Color(0xFF2B3445))],
          ),
        },
      );

      final svgXml = SvgExporter.exportPage(project, 'page-1');

      expect(
        svgXml.contains('<svg xmlns="http://www.w3.org/2000/svg"'),
        isTrue,
      );
      expect(
        svgXml.contains('<rect x="20.0" y="30.0" width="200.0" height="120.0"'),
        isTrue,
      );
      expect(svgXml.contains('rx="16.0" ry="16.0"'), isTrue);
      // Escaped text: & -> &amp;, < -> &lt;, > -> &gt;
      expect(svgXml.contains('UI &amp; Design &lt;2026&gt;'), isTrue);
      expect(svgXml.endsWith('</svg>\n'), isTrue);
    });
  });
}
