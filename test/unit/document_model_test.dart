import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/domain/models/paint_styles.dart';
import 'package:forma_studio/domain/models/text_data.dart';
import 'package:forma_studio/domain/models/tokens_model.dart';
import 'package:forma_studio/domain/services/node_render_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Document Model & Serialization Tests', () {
    test('DesignNode serialization and deserialization roundtrip', () {
      const node = DesignNode(
        id: 'test-node-1',
        type: NodeType.roundedRectangle,
        name: 'Primary Card',
        x: 40.0,
        y: 80.0,
        width: 320.0,
        height: 200.0,
        rotation: 15.0,
        opacity: 0.9,
        fills: [DesignFill.solid(Color(0xFFE6ECF5))],
        strokes: [DesignStroke(color: Color(0xFF2B3445), width: 2.0)],
        effects: [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            offsetX: 4.0,
            offsetY: 6.0,
            blurRadius: 12.0,
          ),
        ],
        cornerRadii: CornerRadii.all(24.0),
      );

      final jsonMap = node.toJson();
      final restored = DesignNode.fromJson(jsonMap);

      expect(restored.id, equals(node.id));
      expect(restored.type, equals(NodeType.roundedRectangle));
      expect(restored.name, equals('Primary Card'));
      expect(restored.x, equals(40.0));
      expect(restored.y, equals(80.0));
      expect(restored.width, equals(320.0));
      expect(restored.height, equals(200.0));
      expect(restored.rotation, equals(15.0));
      expect(restored.cornerRadii.uniformValue, equals(24.0));
      expect(
        restored.fills.first.color.toARGB32(),
        equals(const Color(0xFFE6ECF5).toARGB32()),
      );
      expect(restored.strokes.first.width, equals(2.0));
      expect(restored.effects.first.blurRadius, equals(12.0));
    });

    test('ProjectModel serialization with pages, tokens, and nodes', () {
      final now = DateTime.now();
      final project = ProjectModel(
        id: 'proj-123',
        name: 'Forma Mobile App',
        createdAt: now,
        updatedAt: now,
        pages: const [
          PageModel(
            id: 'page-1',
            name: 'Home Artboard',
            rootNodeIds: ['node-frame-1'],
          ),
        ],
        nodes: const {
          'node-frame-1': DesignNode(
            id: 'node-frame-1',
            type: NodeType.frame,
            name: 'Mobile Frame',
            x: 0,
            y: 0,
            width: 390,
            height: 844,
            textData: TextNodeData(text: 'Welcome to Forma'),
          ),
        },
        tokens: DesignTokens.defaultTokens(),
      );

      final jsonStr = jsonEncode(project.toJson());
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = ProjectModel.fromJson(decoded);

      expect(restored.id, equals('proj-123'));
      expect(restored.name, equals('Forma Mobile App'));
      expect(restored.pages.length, equals(1));
      expect(restored.nodes.containsKey('node-frame-1'), isTrue);
      expect(restored.nodes['node-frame-1']!.width, equals(390.0));
      expect(restored.tokens.colorTokens.isNotEmpty, isTrue);
    });

    test('PageModel value equality and hashCode supports rootNodeIds comparison', () {
      const page1 = PageModel(
        id: 'p1',
        name: 'Page 1',
        rootNodeIds: ['node-1', 'node-2'],
        showGrid: true,
        snapToGrid: true,
      );
      const page2 = PageModel(
        id: 'p1',
        name: 'Page 1',
        rootNodeIds: ['node-1', 'node-2'],
        showGrid: true,
        snapToGrid: true,
      );
      const page3 = PageModel(
        id: 'p1',
        name: 'Page 1',
        rootNodeIds: ['node-1', 'node-3'],
        showGrid: true,
        snapToGrid: true,
      );

      expect(page1, equals(page2));
      expect(page1.hashCode, equals(page2.hashCode));
      expect(page1 == page3, isFalse);
    });

    test('DesignStroke gradient serialization roundtrip', () {
      const stroke = DesignStroke(
        width: 3.5,
        gradientColors: [Color(0xFF3B82F6), Color(0xFF10B981)],
        gradientStops: [0.0, 1.0],
        gradientAngle: 45.0,
      );

      expect(stroke.hasGradient, isTrue);
      final json = stroke.toJson();
      final restored = DesignStroke.fromJson(json);

      expect(restored.hasGradient, isTrue);
      expect(restored.width, equals(3.5));
      expect(restored.gradientColors!.length, equals(2));
      expect(restored.gradientStops!.length, equals(2));
      expect(restored.gradientAngle, equals(45.0));
    });

    test('12 DesignEffectType values serialize and deserialize accurately', () {
      final allTypes = DesignEffectType.values;
      expect(allTypes.length, equals(12));

      for (final type in allTypes) {
        final effect = DesignEffect(
          type: type,
          blurRadius: 10.0,
          color: const Color(0x803B82F6),
        );
        final json = effect.toJson();
        final restored = DesignEffect.fromJson(json);
        expect(restored.type, equals(type));
        expect(restored.blurRadius, equals(10.0));
      }
    });

    test('NodeRenderService resolves GoogleFonts dynamically with safe fallback', () {
      final style = NodeRenderService.resolveTextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 18.0,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.normal,
        decoration: TextDecoration.none,
        color: const Color(0xFF2563EB),
        letterSpacing: 0.5,
        height: 1.4,
      );

      expect(style.fontSize, equals(18.0));
      expect(style.fontWeight, equals(FontWeight.w700));
      expect(style.color, equals(const Color(0xFF2563EB)));
      expect(style.fontFamily, isNotNull);
    });
  });
}
