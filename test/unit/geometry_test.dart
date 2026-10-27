import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/core/geometry/transform2d.dart';
import 'package:forma_studio/core/geometry/geometry_utils.dart';
import 'package:forma_studio/domain/models/node_model.dart';
import 'package:forma_studio/domain/models/node_types.dart';

void main() {
  group('Geometry & Coordinate Transform Tests', () {
    test('CanvasTransform correctly maps screen to doc and vice versa', () {
      const transform = CanvasTransform(zoom: 2.0, panOffset: Offset(100, 50));

      const docPt = Offset(50, 25);
      final screenPt = transform.docToScreen(docPt);
      expect(screenPt.dx, equals(200.0)); // (50 * 2) + 100
      expect(screenPt.dy, equals(100.0)); // (25 * 2) + 50

      final restoredDocPt = transform.screenToDoc(screenPt);
      expect(restoredDocPt.dx, equals(50.0));
      expect(restoredDocPt.dy, equals(25.0));

      const screenDelta = Offset(20, 40);
      final docDelta = transform.screenDeltaToDoc(screenDelta);
      expect(docDelta.dx, equals(10.0));
      expect(docDelta.dy, equals(20.0));
    });

    test('GeometryMath rotates points and calculates bounding boxes', () {
      const pivot = Offset(100, 100);
      const pt = Offset(100, 50);

      // Rotate 90 degrees clockwise
      final rotated90 = GeometryMath.rotatePoint(pt, pivot, 90);
      expect(rotated90.dx, closeTo(150.0, 0.001));
      expect(rotated90.dy, closeTo(100.0, 0.001));

      // Bounding box of rotated rect
      const rect = Rect.fromLTWH(50, 50, 100, 100);
      final aabb = GeometryMath.getRotatedAABB(rect, 45);
      expect(aabb.width, greaterThan(100.0));
      expect(aabb.center.dx, closeTo(rect.center.dx, 0.001));
      expect(aabb.center.dy, closeTo(rect.center.dy, 0.001));
    });

    test('GeometryUtils generates 9 selection handles including rotation', () {
      const rect = Rect.fromLTWH(100, 100, 200, 150);
      final handles = GeometryUtils.getSelectionHandles(rect, handleSize: 10.0);

      expect(handles.length, equals(9));
      expect(handles.any((h) => h.type == ResizeHandleType.topLeft), isTrue);
      expect(
        handles.any((h) => h.type == ResizeHandleType.bottomRight),
        isTrue,
      );
      expect(handles.any((h) => h.type == ResizeHandleType.rotation), isTrue);

      final rotHandle = handles.firstWhere(
        (h) => h.type == ResizeHandleType.rotation,
      );
      expect(rotHandle.position.dy, lessThan(rect.top));
    });

    test('GeometryUtils accurately hit-tests nodes', () {
      const node = DesignNode(
        id: 'node-1',
        type: NodeType.rectangle,
        name: 'Box',
        x: 50,
        y: 50,
        width: 100,
        height: 100,
      );

      expect(GeometryUtils.hitTestNode(const Offset(75, 75), node), isTrue);
      expect(GeometryUtils.hitTestNode(const Offset(20, 20), node), isFalse);
      expect(GeometryUtils.hitTestNode(const Offset(160, 80), node), isFalse);
    });

    test('GeometryUtils snaps to grid and static rects', () {
      const activeRect = Rect.fromLTWH(10, 10, 100, 100);
      final guides = <SnapGuide>[];

      // Snap to grid at 8px
      final snapped = GeometryUtils.snapDelta(
        activeRect: activeRect,
        rawDelta: const Offset(
          4.5,
          0,
        ), // 10 + 4.5 = 14.5 -> closest multiple of 8 is 16 (+6 from active)
        staticRects: const [],
        snapToGrid: true,
        gridSize: 8.0,
        outGuides: guides,
      );

      expect(snapped.dx, equals(6.0));
      expect(activeRect.left + snapped.dx, equals(16.0));
    });
  });
}
