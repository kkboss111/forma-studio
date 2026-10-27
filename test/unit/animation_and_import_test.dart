import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/domain/models/animation_model.dart';
import 'package:forma_studio/core/export/svg_importer.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/features/settings/models/app_settings.dart';

void main() {
  group('Animation Model & Timeline Interpolation Tests', () {
    test('NodeAnimationTrack evaluates and interpolates smoothly between keyframes', () {
      const track = NodeAnimationTrack(
        nodeId: 'test-node-1',
        property: AnimProperty.x,
        keyframes: [
          FloatKeyframe(timeMs: 0.0, value: 0.0),
          FloatKeyframe(timeMs: 1000.0, value: 100.0),
        ],
      );

      // At start
      expect(track.evaluate(0.0, 0.0), 0.0);
      // At end
      expect(track.evaluate(1000.0, 0.0), 100.0);
      // Midpoint: between 0 and 100 (easeInOut ~50.0)
      final mid = track.evaluate(500.0, 0.0);
      expect(mid, inInclusiveRange(45.0, 55.0));

      // Before start clamps to first keyframe
      expect(track.evaluate(-50.0, 0.0), 0.0);
      // Beyond end clamps to last keyframe
      expect(track.evaluate(2000.0, 0.0), 100.0);
    });

    test('NodeAnimationTrack handles Hold step interpolation for discrete UI state changes', () {
      const track = NodeAnimationTrack(
        nodeId: 'toggle-btn',
        property: AnimProperty.opacity,
        keyframes: [
          FloatKeyframe(timeMs: 0.0, value: 0.0, interpolation: InterpolationType.hold),
          FloatKeyframe(timeMs: 500.0, value: 1.0, interpolation: InterpolationType.hold),
        ],
      );

      // At 0ms -> 0.0
      expect(track.evaluate(0.0, 0.0), 0.0);
      // At 250ms -> 0.0 (held constant!)
      expect(track.evaluate(250.0, 0.0), 0.0);
      // At 499ms -> 0.0 (still held constant!)
      expect(track.evaluate(499.0, 0.0), 0.0);
      // At 500ms -> 1.0 (instant step jump!)
      expect(track.evaluate(500.0, 0.0), 1.0);
    });

    test('ProjectTimeline keyframe navigation accurately finds previous and next keyframes', () {
      const timeline = ProjectTimeline(
        durationMs: 3000.0,
        tracks: [
          NodeAnimationTrack(
            nodeId: 'orbiter',
            property: AnimProperty.orbitAngle,
            keyframes: [
              FloatKeyframe(timeMs: 200.0, value: 0.0),
              FloatKeyframe(timeMs: 800.0, value: 90.0),
              FloatKeyframe(timeMs: 1500.0, value: 180.0),
              FloatKeyframe(timeMs: 2400.0, value: 360.0),
            ],
          ),
        ],
      );

      // From 500ms, previous keyframe is 200ms, next is 800ms
      expect(timeline.getPreviousKeyframeTime(500.0), 200.0);
      expect(timeline.getNextKeyframeTime(500.0), 800.0);

      // From 810ms (just past 800), next is 1500ms
      expect(timeline.getNextKeyframeTime(810.0), 1500.0);
      expect(timeline.getPreviousKeyframeTime(810.0), 800.0);
    });

    test('ProjectTimeline serializes and deserializes cleanly to JSON', () {
      const timeline = ProjectTimeline(
        durationMs: 4000.0,
        fps: 60,
        isLooping: false,
        tracks: [
          NodeAnimationTrack(
            nodeId: 'rect-1',
            property: AnimProperty.rotation,
            keyframes: [
              FloatKeyframe(timeMs: 0, value: 0),
              FloatKeyframe(timeMs: 2000, value: 360),
            ],
          ),
        ],
      );

      final json = timeline.toJson();
      final restored = ProjectTimeline.fromJson(json);

      expect(restored.durationMs, 4000.0);
      expect(restored.fps, 60);
      expect(restored.isLooping, isFalse);
      expect(restored.tracks.length, 1);
      expect(restored.tracks.first.property, AnimProperty.rotation);
      expect(restored.tracks.first.keyframes.length, 2);
    });
  });

  group('SvgImporter Vector Parsing Tests', () {
    test('parseSvg parses rect, circle, line and paths into native DesignNodes', () {
      const sampleSvg = '''
<svg viewBox="0 0 500 400" width="500" height="400" xmlns="http://www.w3.org/2000/svg">
  <rect x="20" y="30" width="120" height="80" rx="10" fill="#3B82F6" stroke="#1E2532" stroke-width="2"/>
  <circle cx="200" cy="150" r="40" fill="#10B981"/>
  <line x1="50" y1="300" x2="250" y2="300" stroke="#000000" stroke-width="3"/>
  <path d="M 10 10 L 90 90 C 100 120 120 120 150 90 Z" fill="#EF4444"/>
</svg>
''';

      final result = SvgImporter.parseSvg(sampleSvg);

      expect(result.rootFrame.type, NodeType.frame);
      expect(result.rootFrame.width, 500.0);
      expect(result.rootFrame.height, 400.0);
      expect(result.childNodes.length, 4);

      final rect = result.childNodes.firstWhere((n) => n.name == 'Rect');
      expect(rect.type, NodeType.roundedRectangle);
      expect(rect.width, 120.0);
      expect(rect.height, 80.0);
      expect(rect.cornerRadii.topLeft, 10.0);

      final circle = result.childNodes.firstWhere((n) => n.name == 'Circle');
      expect(circle.type, NodeType.ellipse);
      expect(circle.width, 80.0); // 2 * r

      final path = result.childNodes.firstWhere((n) => n.name == 'Path');
      expect(path.type, NodeType.vectorPath);
      expect(path.vectorData, isNotNull);
      expect(path.vectorData!.anchors.isNotEmpty, isTrue);
    });
  });

  group('AppSettings Tests', () {
    test('AppSettings defaults to system theme and serializes properly', () {
      const settings = AppSettings();
      expect(settings.themeMode, FormaThemeMode.system);
      expect(settings.glassBlur, 32.0);
      expect(settings.glassSpecular, isTrue);

      final customSettings = settings.copyWith(themeMode: FormaThemeMode.liquidGlass);
      final json = customSettings.toJson();
      final restored = AppSettings.fromJson(json);

      expect(restored.themeMode, FormaThemeMode.liquidGlass);
      expect(restored.glassBlur, 32.0);
      expect(restored.glassSpecular, isTrue);
      expect(restored.enableHtmlCodeExport, isFalse);

      final withHtml = customSettings.copyWith(enableHtmlCodeExport: true);
      expect(withHtml.enableHtmlCodeExport, isTrue);
      final jsonHtml = withHtml.toJson();
      final restoredHtml = AppSettings.fromJson(jsonHtml);
      expect(restoredHtml.enableHtmlCodeExport, isTrue);
    });
  });
}
