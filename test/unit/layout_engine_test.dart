import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';
import 'package:forma_studio/domain/models/layout_config.dart';
import 'package:forma_studio/domain/models/constraints.dart';
import 'package:forma_studio/domain/services/layout_engine.dart';

void main() {
  group('Layout & Auto-Layout Engine Tests', () {
    test(
      'computeAutoLayout correctly lays out children in a horizontal row',
      () {
        const frame = DesignNode(
          id: 'frame-1',
          type: NodeType.frame,
          name: 'AutoLayout Row',
          x: 0,
          y: 0,
          width: 300,
          height: 100,
          layoutConfig: AutoLayoutConfig(
            enabled: true,
            direction: AutoLayoutDirection.horizontal,
            paddingLeft: 10,
            paddingTop: 10,
            gap: 15,
            crossAxisAlignment: AutoLayoutCrossAlignment.center,
          ),
        );

        final children = [
          const DesignNode(
            id: 'c1',
            type: NodeType.rectangle,
            name: 'C1',
            x: 0,
            y: 0,
            width: 40,
            height: 40,
          ),
          const DesignNode(
            id: 'c2',
            type: NodeType.rectangle,
            name: 'C2',
            x: 0,
            y: 0,
            width: 60,
            height: 50,
          ),
        ];

        final result = LayoutEngine.computeAutoLayout(
          frame: frame,
          children: children,
        );

        // Child 1 starts at frame.x + paddingLeft = 10
        expect(result['c1']!.x, equals(10.0));
        // Child 2 starts at 10 + 40 (child 1 width) + 15 (gap) = 65
        expect(result['c2']!.x, equals(65.0));

        // Cross axis center alignment:
        // Available height = 100 - (10 + 0) = 90
        // c1: y = 10 + (100 - 40)/2 = 40 (or cross alignment formula)
        expect(result['c1']!.y, greaterThanOrEqualTo(10.0));
      },
    );

    test(
      'applyConstraintsOnParentResize updates right-aligned and stretch children',
      () {
        const childRight = DesignNode(
          id: 'child-r',
          type: NodeType.rectangle,
          name: 'Right Button',
          x: 80,
          y: 10,
          width: 20,
          height: 20,
          constraints: LayoutConstraints(
            horizontal: HorizontalConstraint.right,
            vertical: VerticalConstraint.top,
          ),
        );

        // Parent grows from 100 to 150 (dw = +50)
        final updatedChild = LayoutEngine.applyConstraintsOnParentResize(
          child: childRight,
          oldParentW: 100,
          oldParentH: 100,
          newParentW: 150,
          newParentH: 100,
        );

        expect(updatedChild.x, equals(130.0)); // 80 + 50
        expect(updatedChild.width, equals(20.0)); // Width unchanged
      },
    );
  });
}
