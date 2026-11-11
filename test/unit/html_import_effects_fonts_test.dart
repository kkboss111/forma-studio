import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forma_studio/core/export/html_importer.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/domain/models/paint_styles.dart';
import 'package:forma_studio/domain/services/custom_font_service.dart';
import 'package:forma_studio/domain/services/node_render_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HTML Importer Tests', () {
    test('HtmlImporter parses heading, paragraph, button, and container correctly', () {
      const html = '''
        <div style="background-color: #f1f5f9; padding: 20px; width: 600px; height: 400px; border-radius: 12px;">
          <h1 style="color: #0f172a; font-size: 28px;">Welcome to Forma Studio</h1>
          <p style="color: #475569; font-size: 16px;">The open source collaborative vector graphic editor.</p>
          <button style="background-color: #3b82f6; color: #ffffff; border-radius: 8px;">Get Started</button>
        </div>
      ''';

      final result = HtmlImporter.parseHtml(html, insertionPoint: const Offset(50, 50));
      expect(result.rootFrame, isNotNull);
      expect(result.rootFrame.type, NodeType.frame);
      expect(result.rootFrame.x, 50.0);
      expect(result.rootFrame.y, 50.0);
      expect(result.childNodes.isNotEmpty, isTrue);

      final types = result.childNodes.map((n) => n.type).toSet();
      expect(types.contains(NodeType.text), isTrue);

      // Verify button or nested frame
      final buttonFrames = result.childNodes.where((n) => n.name.contains('Button'));
      expect(buttonFrames.isNotEmpty, isTrue);
    });

    test('HtmlImporter handles fallback regex for malformed HTML', () {
      const brokenHtml = '<p>Broken <b>unclosed tag <div>inside';
      final result = HtmlImporter.parseHtml(brokenHtml);
      expect(result.rootFrame, isNotNull);
      expect(result.childNodes.isNotEmpty, isTrue);
    });
  });

  group('Custom Font Service Tests', () {
    test('CustomFontService loads and reports imported fonts', () async {
      SharedPreferences.setMockInitialValues({});
      await CustomFontService.initializeOfflineFonts();

      expect(CustomFontService.isImported('TestCustomFont'), isFalse);

      // Mock font bytes (empty header for test)
      final dummyBytes = Uint8List.fromList(List.filled(32, 0));
      try {
        await CustomFontService.loadFontFromBytes(
          familyName: 'TestCustomFont',
          fontBytes: dummyBytes,
          persist: true,
        );
      } catch (_) {
        // FontLoader native channel might throw in headless mock, but registration state is tracked
      }

      // Check offline persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('forma_offline_custom_fonts');
      expect(savedList, isNotNull);
      expect(savedList!.any((s) => s.contains('TestCustomFont')), isTrue);
    });
  });

  group('NodeRenderService Effects Tests', () {
    test('NodeRenderService paints effects with zero blur radius without throwing', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final nodeWithEffects = DesignNode(
        id: 'effect-test-node',
        name: 'Effect Card',
        type: NodeType.rectangle,
        x: 0,
        y: 0,
        width: 200,
        height: 120,
        effects: const [
          DesignEffect(
            type: DesignEffectType.dropShadow,
            blurRadius: 0.0, // Zero blur! Must not crash MaskFilter.blur
            spreadRadius: 4.0,
            offsetX: 2.0,
            offsetY: 2.0,
            color: Color(0x80000000),
          ),
          DesignEffect(
            type: DesignEffectType.innerShadow,
            blurRadius: 0.0,
            spreadRadius: 2.0,
            offsetX: 1.0,
            offsetY: 1.0,
            color: Color(0x40000000),
          ),
          DesignEffect(
            type: DesignEffectType.backgroundBlur,
            blurRadius: 10.0,
            color: Color(0x20FFFFFF),
          ),
          DesignEffect(
            type: DesignEffectType.outerGlow,
            blurRadius: 6.0,
            spreadRadius: 2.0,
            color: Color(0x803B82F6),
          ),
          DesignEffect(
            type: DesignEffectType.innerGlow,
            blurRadius: 4.0,
            spreadRadius: 1.0,
            color: Color(0x6060A5FA),
          ),
        ],
      );

      final allNodes = {'effect-test-node': nodeWithEffects};

      expect(() {
        NodeRenderService.renderNode(canvas, nodeWithEffects, allNodes);
      }, returnsNormally);

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
