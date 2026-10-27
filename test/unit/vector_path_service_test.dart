import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forma_studio/domain/models/vector_data.dart';
import 'package:forma_studio/domain/services/vector_path_service.dart';

void main() {
  group('VectorPathService Anchor & Curve Manipulation Tests', () {
    test('updateAnchorPoint translates anchor position and attached handles', () {
      const initialPath = VectorPathData(
        anchors: [
          VectorAnchor(
            point: Offset(10, 10),
            handleIn: Offset(5, 10),
            handleOut: Offset(15, 10),
          ),
          VectorAnchor(point: Offset(100, 100)),
        ],
      );

      final updated = VectorPathService.updateAnchorPoint(
        pathData: initialPath,
        index: 0,
        newPoint: const Offset(30, 20),
        moveHandles: true,
      );

      expect(updated.anchors[0].point, const Offset(30, 20));
      // delta is (20, 10), handleIn was (5, 10) -> (25, 20)
      expect(updated.anchors[0].handleIn, const Offset(25, 20));
      // handleOut was (15, 10) -> (35, 20)
      expect(updated.anchors[0].handleOut, const Offset(35, 20));
    });

    test('updateHandleIn mirrors handleOut when isSmooth is true', () {
      const smoothPath = VectorPathData(
        anchors: [
          VectorAnchor(
            point: Offset(50, 50),
            handleIn: Offset(30, 50),
            handleOut: Offset(70, 50),
            isSmooth: true,
          ),
        ],
      );

      // Moving handleIn to (30, 40) (delta from anchor: (-20, -10))
      final updated = VectorPathService.updateHandleIn(
        pathData: smoothPath,
        index: 0,
        newHandleIn: const Offset(30, 40),
      );

      expect(updated.anchors[0].handleIn, const Offset(30, 40));
      // handleOut should mirror across (50, 50): 50 - (-20) = 70, 50 - (-10) = 60
      expect(updated.anchors[0].handleOut, const Offset(70, 60));
    });

    test('toggleAnchorSmoothness converts corner to smooth and vice versa', () {
      const sharpPath = VectorPathData(
        anchors: [
          VectorAnchor(point: Offset(0, 0)),
          VectorAnchor(point: Offset(50, 50)),
          VectorAnchor(point: Offset(100, 0)),
        ],
      );

      final smooth = VectorPathService.toggleAnchorSmoothness(
        pathData: sharpPath,
        index: 1,
      );

      expect(smooth.anchors[1].isSmooth, isTrue);
      expect(smooth.anchors[1].handleIn, isNotNull);
      expect(smooth.anchors[1].handleOut, isNotNull);

      final sharpAgain = VectorPathService.toggleAnchorSmoothness(
        pathData: smooth,
        index: 1,
      );

      expect(sharpAgain.anchors[1].isSmooth, isFalse);
      expect(sharpAgain.anchors[1].handleIn, isNull);
      expect(sharpAgain.anchors[1].handleOut, isNull);
    });

    test('addAnchor and deleteAnchor manage anchor point list safely', () {
      const path = VectorPathData(
        anchors: [
          VectorAnchor(point: Offset(0, 0)),
          VectorAnchor(point: Offset(100, 0)),
          VectorAnchor(point: Offset(100, 100)),
        ],
      );

      final extended = VectorPathService.addAnchor(path, const Offset(0, 100));
      expect(extended.anchors.length, 4);
      expect(extended.anchors.last.point, const Offset(0, 100));

      final deleted = VectorPathService.deleteAnchor(extended, 1);
      expect(deleted.anchors.length, 3);
      expect(deleted.anchors[1].point, const Offset(100, 100));
    });

    test('combinePaths executes Boolean operations', () {
      final p1 = Path()..addRect(const Rect.fromLTWH(0, 0, 100, 100));
      final p2 = Path()..addRect(const Rect.fromLTWH(50, 50, 100, 100));

      final union = VectorPathService.combinePaths(p1, p2, PathOperation.union);
      final intersect = VectorPathService.combinePaths(p1, p2, PathOperation.intersect);

      expect(union.getBounds(), const Rect.fromLTWH(0, 0, 150, 150));
      expect(intersect.getBounds(), const Rect.fromLTWH(50, 50, 50, 50));
    });
  });
}
