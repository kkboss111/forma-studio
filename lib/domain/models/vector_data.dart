import 'package:flutter/material.dart';

class VectorAnchor {
  final Offset point;
  final Offset? handleIn;
  final Offset? handleOut;
  final bool isSmooth;

  const VectorAnchor({
    required this.point,
    this.handleIn,
    this.handleOut,
    this.isSmooth = false,
  });

  VectorAnchor copyWith({
    Offset? point,
    Offset? handleIn,
    Offset? handleOut,
    bool? isSmooth,
  }) {
    return VectorAnchor(
      point: point ?? this.point,
      handleIn: handleIn ?? this.handleIn,
      handleOut: handleOut ?? this.handleOut,
      isSmooth: isSmooth ?? this.isSmooth,
    );
  }

  Map<String, dynamic> toJson() => {
    'px': point.dx,
    'py': point.dy,
    if (handleIn != null) 'hix': handleIn!.dx,
    if (handleIn != null) 'hiy': handleIn!.dy,
    if (handleOut != null) 'hox': handleOut!.dx,
    if (handleOut != null) 'hoy': handleOut!.dy,
    'isSmooth': isSmooth,
  };

  factory VectorAnchor.fromJson(Map<String, dynamic> json) {
    return VectorAnchor(
      point: Offset(
        (json['px'] as num).toDouble(),
        (json['py'] as num).toDouble(),
      ),
      handleIn: json.containsKey('hix')
          ? Offset(
              (json['hix'] as num).toDouble(),
              (json['hiy'] as num).toDouble(),
            )
          : null,
      handleOut: json.containsKey('hox')
          ? Offset(
              (json['hox'] as num).toDouble(),
              (json['hoy'] as num).toDouble(),
            )
          : null,
      isSmooth: json['isSmooth'] as bool? ?? false,
    );
  }
}

class VectorPathData {
  final List<VectorAnchor> anchors;
  final bool isClosed;

  const VectorPathData({required this.anchors, this.isClosed = true});

  VectorPathData copyWith({
    List<VectorAnchor>? anchors,
    bool? isClosed,
  }) {
    return VectorPathData(
      anchors: anchors ?? this.anchors,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  Path toPath({
    Offset offset = Offset.zero,
    double scaleX = 1.0,
    double scaleY = 1.0,
  }) {
    final path = Path();
    if (anchors.isEmpty) return path;

    final first = anchors.first;
    path.moveTo(
      offset.dx + first.point.dx * scaleX,
      offset.dy + first.point.dy * scaleY,
    );

    for (int i = 1; i < anchors.length; i++) {
      final prev = anchors[i - 1];
      final curr = anchors[i];

      final p0 = Offset(
        offset.dx + prev.point.dx * scaleX,
        offset.dy + prev.point.dy * scaleY,
      );
      final p1 = curr.handleIn != null
          ? Offset(
              offset.dx + curr.handleIn!.dx * scaleX,
              offset.dy + curr.handleIn!.dy * scaleY,
            )
          : null;
      final p2 = prev.handleOut != null
          ? Offset(
              offset.dx + prev.handleOut!.dx * scaleX,
              offset.dy + prev.handleOut!.dy * scaleY,
            )
          : null;
      final p3 = Offset(
        offset.dx + curr.point.dx * scaleX,
        offset.dy + curr.point.dy * scaleY,
      );

      if (p1 != null || p2 != null) {
        final cp1 = p2 ?? p0;
        final cp2 = p1 ?? p3;
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p3.dx, p3.dy);
      } else {
        path.lineTo(p3.dx, p3.dy);
      }
    }

    if (isClosed && anchors.length > 2) {
      final last = anchors.last;
      final first = anchors.first;
      if (last.handleOut != null || first.handleIn != null) {
        final p0 = Offset(
          offset.dx + last.point.dx * scaleX,
          offset.dy + last.point.dy * scaleY,
        );
        final cp1 = last.handleOut != null
            ? Offset(
                offset.dx + last.handleOut!.dx * scaleX,
                offset.dy + last.handleOut!.dy * scaleY,
              )
            : p0;
        final cp2 = first.handleIn != null
            ? Offset(
                offset.dx + first.handleIn!.dx * scaleX,
                offset.dy + first.handleIn!.dy * scaleY,
              )
            : Offset(
                offset.dx + first.point.dx * scaleX,
                offset.dy + first.point.dy * scaleY,
              );
        final p3 = Offset(
          offset.dx + first.point.dx * scaleX,
          offset.dy + first.point.dy * scaleY,
        );
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p3.dx, p3.dy);
      } else {
        path.close();
      }
    }

    return path;
  }

  Map<String, dynamic> toJson() => {
    'anchors': anchors.map((a) => a.toJson()).toList(),
    'isClosed': isClosed,
  };

  factory VectorPathData.fromJson(Map<String, dynamic> json) {
    return VectorPathData(
      anchors: (json['anchors'] as List? ?? [])
          .map((a) => VectorAnchor.fromJson(a as Map<String, dynamic>))
          .toList(),
      isClosed: json['isClosed'] as bool? ?? true,
    );
  }
}
