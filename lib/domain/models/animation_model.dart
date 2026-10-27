import 'dart:math' as math;
import 'package:flutter/animation.dart';

enum AnimProperty {
  x,
  y,
  width,
  height,
  rotation,
  opacity,
  scaleX,
  scaleY,
  pivotX,
  pivotY,
  orbitAngle,
  orbitRadius,
  cornerRadius,
  strokeWidth,
}

enum InterpolationType {
  linear,
  hold,
  easeIn,
  easeOut,
  easeInOut,
  spring,
  bounce,
  bezier,
}

class FloatKeyframe {
  final double timeMs;
  final double value;
  final InterpolationType interpolation;
  final double handleOutX;
  final double handleOutY;
  final double handleInX;
  final double handleInY;

  const FloatKeyframe({
    required this.timeMs,
    required this.value,
    this.interpolation = InterpolationType.easeInOut,
    this.handleOutX = 0.42,
    this.handleOutY = 0.0,
    this.handleInX = 0.58,
    this.handleInY = 1.0,
  });

  FloatKeyframe copyWith({
    double? timeMs,
    double? value,
    InterpolationType? interpolation,
    double? handleOutX,
    double? handleOutY,
    double? handleInX,
    double? handleInY,
  }) {
    return FloatKeyframe(
      timeMs: timeMs ?? this.timeMs,
      value: value ?? this.value,
      interpolation: interpolation ?? this.interpolation,
      handleOutX: handleOutX ?? this.handleOutX,
      handleOutY: handleOutY ?? this.handleOutY,
      handleInX: handleInX ?? this.handleInX,
      handleInY: handleInY ?? this.handleInY,
    );
  }

  Map<String, dynamic> toJson() => {
    'timeMs': timeMs,
    'value': value,
    'interpolation': interpolation.name,
    'handleOutX': handleOutX,
    'handleOutY': handleOutY,
    'handleInX': handleInX,
    'handleInY': handleInY,
  };

  factory FloatKeyframe.fromJson(Map<String, dynamic> json) {
    return FloatKeyframe(
      timeMs: (json['timeMs'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
      interpolation: InterpolationType.values.firstWhere(
        (e) => e.name == json['interpolation'],
        orElse: () => InterpolationType.easeInOut,
      ),
      handleOutX: (json['handleOutX'] as num?)?.toDouble() ?? 0.42,
      handleOutY: (json['handleOutY'] as num?)?.toDouble() ?? 0.0,
      handleInX: (json['handleInX'] as num?)?.toDouble() ?? 0.58,
      handleInY: (json['handleInY'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class NodeAnimationTrack {
  final String nodeId;
  final AnimProperty property;
  final List<FloatKeyframe> keyframes;

  const NodeAnimationTrack({
    required this.nodeId,
    required this.property,
    required this.keyframes,
  });

  double evaluate(double timeMs, double defaultValue) {
    if (keyframes.isEmpty) return defaultValue;
    if (keyframes.length == 1) return keyframes.first.value;

    final sorted = List<FloatKeyframe>.from(keyframes)
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    if (timeMs <= sorted.first.timeMs) return sorted.first.value;
    if (timeMs >= sorted.last.timeMs) return sorted.last.value;

    // Find interval [k0, k1]
    for (int i = 0; i < sorted.length - 1; i++) {
      final k0 = sorted[i];
      final k1 = sorted[i + 1];

      if (timeMs >= k0.timeMs && timeMs <= k1.timeMs) {
        if (k0.interpolation == InterpolationType.hold) {
          return k0.value;
        }

        final duration = k1.timeMs - k0.timeMs;
        if (duration <= 0.001) return k1.value;
        final t = ((timeMs - k0.timeMs) / duration).clamp(0.0, 1.0);

        double curveT;
        switch (k0.interpolation) {
          case InterpolationType.hold:
            return k0.value;
          case InterpolationType.linear:
            curveT = t;
            break;
          case InterpolationType.easeIn:
            curveT = Curves.easeIn.transform(t);
            break;
          case InterpolationType.easeOut:
            curveT = Curves.easeOut.transform(t);
            break;
          case InterpolationType.easeInOut:
            curveT = Curves.easeInOut.transform(t);
            break;
          case InterpolationType.spring:
            // Custom elastic overshoot curve
            curveT = 1.0 - math.exp(-6.0 * t) * math.cos(8.0 * t);
            break;
          case InterpolationType.bounce:
            curveT = Curves.bounceOut.transform(t);
            break;
          case InterpolationType.bezier:
            try {
              final cubic = Cubic(
                k0.handleOutX.clamp(0.0, 1.0),
                k0.handleOutY,
                k1.handleInX.clamp(0.0, 1.0),
                k1.handleInY,
              );
              curveT = cubic.transform(t);
            } catch (_) {
              curveT = t;
            }
            break;
        }

        return k0.value + (k1.value - k0.value) * curveT;
      }
    }

    return defaultValue;
  }

  NodeAnimationTrack copyWith({
    String? nodeId,
    AnimProperty? property,
    List<FloatKeyframe>? keyframes,
  }) {
    return NodeAnimationTrack(
      nodeId: nodeId ?? this.nodeId,
      property: property ?? this.property,
      keyframes: keyframes ?? this.keyframes,
    );
  }

  Map<String, dynamic> toJson() => {
    'nodeId': nodeId,
    'property': property.name,
    'keyframes': keyframes.map((k) => k.toJson()).toList(),
  };

  factory NodeAnimationTrack.fromJson(Map<String, dynamic> json) {
    return NodeAnimationTrack(
      nodeId: json['nodeId'] as String,
      property: AnimProperty.values.firstWhere(
        (e) => e.name == json['property'],
        orElse: () => AnimProperty.opacity,
      ),
      keyframes: (json['keyframes'] as List? ?? [])
          .map((k) => FloatKeyframe.fromJson(k as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProjectTimeline {
  final double durationMs;
  final int fps;
  final bool isLooping;
  final List<NodeAnimationTrack> tracks;

  const ProjectTimeline({
    this.durationMs = 3000.0,
    this.fps = 30,
    this.isLooping = true,
    this.tracks = const [],
  });

  /// Returns sorted unique list of all keyframe timestamps
  List<double> getAllKeyframeTimes() {
    final set = <double>{};
    for (final track in tracks) {
      for (final k in track.keyframes) {
        set.add(k.timeMs);
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  /// Returns the nearest previous keyframe time before [currentTimeMs]
  double? getPreviousKeyframeTime(double currentTimeMs) {
    final all = getAllKeyframeTimes();
    for (int i = all.length - 1; i >= 0; i--) {
      if (all[i] < currentTimeMs - 1.0) {
        return all[i];
      }
    }
    return null;
  }

  /// Returns the nearest next keyframe time after [currentTimeMs]
  double? getNextKeyframeTime(double currentTimeMs) {
    final all = getAllKeyframeTimes();
    for (final t in all) {
      if (t > currentTimeMs + 1.0) {
        return t;
      }
    }
    return null;
  }

  ProjectTimeline copyWith({
    double? durationMs,
    int? fps,
    bool? isLooping,
    List<NodeAnimationTrack>? tracks,
  }) {
    return ProjectTimeline(
      durationMs: durationMs ?? this.durationMs,
      fps: fps ?? this.fps,
      isLooping: isLooping ?? this.isLooping,
      tracks: tracks ?? this.tracks,
    );
  }

  Map<String, dynamic> toJson() => {
    'durationMs': durationMs,
    'fps': fps,
    'isLooping': isLooping,
    'tracks': tracks.map((t) => t.toJson()).toList(),
  };

  factory ProjectTimeline.fromJson(Map<String, dynamic> json) {
    return ProjectTimeline(
      durationMs: (json['durationMs'] as num?)?.toDouble() ?? 3000.0,
      fps: json['fps'] as int? ?? 30,
      isLooping: json['isLooping'] as bool? ?? true,
      tracks: (json['tracks'] as List? ?? [])
          .map((t) => NodeAnimationTrack.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
