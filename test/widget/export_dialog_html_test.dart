import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma_studio/domain/models/project_model.dart';
import 'package:forma_studio/domain/models/page_model.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/domain/models/paint_styles.dart';
import 'package:forma_studio/features/editor/widgets/dialogs/export_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'ExportDialog unconditionally displays HTML / CSS Web Code and renders interactive preview',
    (WidgetTester tester) async {
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final args = methodCall.arguments as Map?;
            copiedText = args?['text'] as String?;
            return null;
          }
          return null;
        },
      );
      final project = ProjectModel(
        id: 'export-test-proj',
        name: 'Export Web Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        pages: const [
          PageModel(id: 'page-1', name: 'Page 1', rootNodeIds: ['node-box-1']),
        ],
        nodes: const {
          'node-box-1': DesignNode(
            id: 'node-box-1',
            type: NodeType.rectangle,
            name: 'Hero Card',
            x: 20,
            y: 40,
            width: 300,
            height: 180,
            fills: [DesignFill(color: Color(0xFF3B82F6))],
          ),
        },
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ExportDialog(
                project: project,
                activePageId: 'page-1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify HTML / CSS Web Code chip is ALWAYS present in the options grid
      final htmlChipFinder = find.text('HTML / CSS Web Code');
      expect(htmlChipFinder, findsOneWidget);

      // 2. Tap HTML / CSS Web Code chip
      await tester.tap(htmlChipFinder);
      await tester.pumpAndSettle();

      // 3. Verify HTML code preview section is displayed
      expect(find.text('HTML5 + CSS Live Output'), findsOneWidget);
      expect(find.text('Copy HTML'), findsWidgets);
      expect(find.text('Download .html'), findsOneWidget);

      // 4. Tap Bottom Copy HTML Button
      final copyBtn = find.widgetWithText(OutlinedButton, 'Copy HTML');
      expect(copyBtn, findsOneWidget);
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();

      // 5. Verify status feedback & actual HTML payload in clipboard
      expect(find.text('Copied HTML/CSS code to clipboard!'), findsOneWidget);
      expect(copiedText, isNotNull);
      expect(copiedText!, contains('<!DOCTYPE html>'));
      expect(copiedText!, contains('Export Web Test'));
      expect(copiedText!, contains('node-box-1'));

      // 6. Tap the in-panel Copy HTML chip
      copiedText = null;
      final copyChip = find.byKey(const Key('copy_html_preview_chip'));
      expect(copyChip, findsOneWidget);
      await tester.tap(copyChip);
      await tester.pumpAndSettle();
      expect(find.text('Copied HTML/CSS code to clipboard!'), findsOneWidget);
      expect(copiedText!.toLowerCase(), contains('<html'));
    },
  );
}
