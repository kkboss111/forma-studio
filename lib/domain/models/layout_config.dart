enum AutoLayoutDirection { horizontal, vertical }

enum AutoLayoutAlignment { start, center, end, spaceBetween }

enum AutoLayoutCrossAlignment { start, center, end, stretch }

enum SizingMode { fixed, hug, fill }

class AutoLayoutConfig {
  final bool enabled;
  final AutoLayoutDirection direction;
  final double paddingLeft;
  final double paddingTop;
  final double paddingRight;
  final double paddingBottom;
  final double gap;
  final AutoLayoutAlignment mainAxisAlignment;
  final AutoLayoutCrossAlignment crossAxisAlignment;
  final bool wrap;

  const AutoLayoutConfig({
    this.enabled = false,
    this.direction = AutoLayoutDirection.vertical,
    this.paddingLeft = 0.0,
    this.paddingTop = 0.0,
    this.paddingRight = 0.0,
    this.paddingBottom = 0.0,
    this.gap = 8.0,
    this.mainAxisAlignment = AutoLayoutAlignment.start,
    this.crossAxisAlignment = AutoLayoutCrossAlignment.start,
    this.wrap = false,
  });

  AutoLayoutConfig copyWith({
    bool? enabled,
    AutoLayoutDirection? direction,
    double? paddingLeft,
    double? paddingTop,
    double? paddingRight,
    double? paddingBottom,
    double? gap,
    AutoLayoutAlignment? mainAxisAlignment,
    AutoLayoutCrossAlignment? crossAxisAlignment,
    bool? wrap,
  }) {
    return AutoLayoutConfig(
      enabled: enabled ?? this.enabled,
      direction: direction ?? this.direction,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingRight: paddingRight ?? this.paddingRight,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      gap: gap ?? this.gap,
      mainAxisAlignment: mainAxisAlignment ?? this.mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      wrap: wrap ?? this.wrap,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'direction': direction.name,
    'paddingLeft': paddingLeft,
    'paddingTop': paddingTop,
    'paddingRight': paddingRight,
    'paddingBottom': paddingBottom,
    'gap': gap,
    'mainAxisAlignment': mainAxisAlignment.name,
    'crossAxisAlignment': crossAxisAlignment.name,
    'wrap': wrap,
  };

  factory AutoLayoutConfig.fromJson(Map<String, dynamic> json) {
    return AutoLayoutConfig(
      enabled: json['enabled'] as bool? ?? false,
      direction: AutoLayoutDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => AutoLayoutDirection.vertical,
      ),
      paddingLeft: (json['paddingLeft'] as num?)?.toDouble() ?? 0.0,
      paddingTop: (json['paddingTop'] as num?)?.toDouble() ?? 0.0,
      paddingRight: (json['paddingRight'] as num?)?.toDouble() ?? 0.0,
      paddingBottom: (json['paddingBottom'] as num?)?.toDouble() ?? 0.0,
      gap: (json['gap'] as num?)?.toDouble() ?? 8.0,
      mainAxisAlignment: AutoLayoutAlignment.values.firstWhere(
        (e) => e.name == json['mainAxisAlignment'],
        orElse: () => AutoLayoutAlignment.start,
      ),
      crossAxisAlignment: AutoLayoutCrossAlignment.values.firstWhere(
        (e) => e.name == json['crossAxisAlignment'],
        orElse: () => AutoLayoutCrossAlignment.start,
      ),
      wrap: json['wrap'] as bool? ?? false,
    );
  }
}
