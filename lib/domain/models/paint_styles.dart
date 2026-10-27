import 'package:flutter/material.dart';

enum DesignFillType {
  solid,
  linearGradient,
  radialGradient,
  angularGradient,
  image,
}

class DesignFill {
  final DesignFillType type;
  final Color color;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final double gradientAngle; // 0.0 to 360.0 degrees
  final double opacity;
  final bool isVisible;
  final String? imageBase64;
  final String? imagePath;

  const DesignFill({
    this.type = DesignFillType.solid,
    this.color = const Color(0xFF2B3445),
    this.gradientColors,
    this.gradientStops,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.gradientAngle = 135.0,
    this.opacity = 1.0,
    this.isVisible = true,
    this.imageBase64,
    this.imagePath,
  });

  const DesignFill.solid(
    this.color, {
    this.opacity = 1.0,
    this.isVisible = true,
  }) : type = DesignFillType.solid,
       gradientColors = null,
       gradientStops = null,
       gradientBegin = Alignment.topLeft,
       gradientEnd = Alignment.bottomRight,
       gradientAngle = 135.0,
       imageBase64 = null,
       imagePath = null;

  DesignFill.linear({
    required List<Color> colors,
    List<double>? stops,
    double angle = 135.0,
    this.opacity = 1.0,
    this.isVisible = true,
  }) : type = DesignFillType.linearGradient,
       color = colors.isNotEmpty ? colors.first : const Color(0xFF2B3445),
       gradientColors = colors,
       gradientStops = stops,
       gradientBegin = Alignment.topLeft,
       gradientEnd = Alignment.bottomRight,
       gradientAngle = angle,
       imageBase64 = null,
       imagePath = null;

  DesignFill.radial({
    required List<Color> colors,
    List<double>? stops,
    this.opacity = 1.0,
    this.isVisible = true,
  }) : type = DesignFillType.radialGradient,
       color = colors.isNotEmpty ? colors.first : const Color(0xFF2B3445),
       gradientColors = colors,
       gradientStops = stops,
       gradientBegin = Alignment.center,
       gradientEnd = Alignment.bottomRight,
       gradientAngle = 0.0,
       imageBase64 = null,
       imagePath = null;

  DesignFill.angular({
    required List<Color> colors,
    List<double>? stops,
    this.opacity = 1.0,
    this.isVisible = true,
  }) : type = DesignFillType.angularGradient,
       color = colors.isNotEmpty ? colors.first : const Color(0xFF2B3445),
       gradientColors = colors,
       gradientStops = stops,
       gradientBegin = Alignment.center,
       gradientEnd = Alignment.bottomRight,
       gradientAngle = 0.0,
       imageBase64 = null,
       imagePath = null;

  const DesignFill.image({
    this.imageBase64,
    this.imagePath,
    this.opacity = 1.0,
    this.isVisible = true,
  }) : type = DesignFillType.image,
       color = const Color(0xFF8A99AD),
       gradientColors = null,
       gradientStops = null,
       gradientBegin = Alignment.topLeft,
       gradientEnd = Alignment.bottomRight,
       gradientAngle = 0.0;

  DesignFill copyWith({
    DesignFillType? type,
    Color? color,
    List<Color>? gradientColors,
    List<double>? gradientStops,
    Alignment? gradientBegin,
    Alignment? gradientEnd,
    double? gradientAngle,
    double? opacity,
    bool? isVisible,
    String? imageBase64,
    String? imagePath,
  }) {
    return DesignFill(
      type: type ?? this.type,
      color: color ?? this.color,
      gradientColors: gradientColors ?? this.gradientColors,
      gradientStops: gradientStops ?? this.gradientStops,
      gradientBegin: gradientBegin ?? this.gradientBegin,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      gradientAngle: gradientAngle ?? this.gradientAngle,
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      imageBase64: imageBase64 ?? this.imageBase64,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'color': color.toARGB32(),
    if (gradientColors != null)
      'gradientColors': gradientColors!.map((c) => c.toARGB32()).toList(),
    if (gradientStops != null) 'gradientStops': gradientStops,
    'gradientAngle': gradientAngle,
    'opacity': opacity,
    'isVisible': isVisible,
    if (imageBase64 != null) 'imageBase64': imageBase64,
    if (imagePath != null) 'imagePath': imagePath,
  };

  factory DesignFill.fromJson(Map<String, dynamic> json) {
    return DesignFill(
      type: DesignFillType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DesignFillType.solid,
      ),
      color: Color(json['color'] as int? ?? 0xFF2B3445),
      gradientColors: (json['gradientColors'] as List?)
          ?.map((c) => Color(c as int))
          .toList(),
      gradientStops: (json['gradientStops'] as List?)
          ?.map((s) => (s as num).toDouble())
          .toList(),
      gradientAngle: (json['gradientAngle'] as num?)?.toDouble() ?? 135.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      isVisible: json['isVisible'] as bool? ?? true,
      imageBase64: json['imageBase64'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }
}

enum StrokeAlign { center, inside, outside }

class DesignStroke {
  final Color color;
  final double width;
  final bool isVisible;
  final StrokeCap cap;
  final StrokeJoin join;
  final StrokeAlign align;
  final List<double>? dashPattern;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;
  final double gradientAngle;

  const DesignStroke({
    this.color = const Color(0xFFC8D3E2),
    this.width = 1.0,
    this.isVisible = true,
    this.cap = StrokeCap.round,
    this.join = StrokeJoin.round,
    this.align = StrokeAlign.center,
    this.dashPattern,
    this.gradientColors,
    this.gradientStops,
    this.gradientAngle = 135.0,
  });

  bool get hasGradient => gradientColors != null && gradientColors!.length >= 2;

  DesignStroke copyWith({
    Color? color,
    double? width,
    bool? isVisible,
    StrokeCap? cap,
    StrokeJoin join = StrokeJoin.round,
    StrokeAlign? align,
    List<double>? dashPattern,
    List<Color>? gradientColors,
    List<double>? gradientStops,
    double? gradientAngle,
    bool clearGradient = false,
  }) {
    return DesignStroke(
      color: color ?? this.color,
      width: width ?? this.width,
      isVisible: isVisible ?? this.isVisible,
      cap: cap ?? this.cap,
      join: join,
      align: align ?? this.align,
      dashPattern: dashPattern ?? this.dashPattern,
      gradientColors: clearGradient ? null : (gradientColors ?? this.gradientColors),
      gradientStops: clearGradient ? null : (gradientStops ?? this.gradientStops),
      gradientAngle: gradientAngle ?? this.gradientAngle,
    );
  }

  Map<String, dynamic> toJson() => {
    'color': color.toARGB32(),
    'width': width,
    'isVisible': isVisible,
    'cap': cap.name,
    'join': join.name,
    'align': align.name,
    if (dashPattern != null) 'dashPattern': dashPattern,
    if (gradientColors != null)
      'gradientColors': gradientColors!.map((c) => c.toARGB32()).toList(),
    if (gradientStops != null) 'gradientStops': gradientStops,
    'gradientAngle': gradientAngle,
  };

  factory DesignStroke.fromJson(Map<String, dynamic> json) {
    return DesignStroke(
      color: Color(json['color'] as int? ?? 0xFFC8D3E2),
      width: (json['width'] as num?)?.toDouble() ?? 1.0,
      isVisible: json['isVisible'] as bool? ?? true,
      cap: StrokeCap.values.firstWhere(
        (e) => e.name == json['cap'],
        orElse: () => StrokeCap.round,
      ),
      join: StrokeJoin.values.firstWhere(
        (e) => e.name == json['join'],
        orElse: () => StrokeJoin.round,
      ),
      align: StrokeAlign.values.firstWhere(
        (e) => e.name == json['align'],
        orElse: () => StrokeAlign.center,
      ),
      dashPattern: (json['dashPattern'] as List?)
          ?.map((d) => (d as num).toDouble())
          .toList(),
      gradientColors: (json['gradientColors'] as List?)
          ?.map((c) => Color(c as int))
          .toList(),
      gradientStops: (json['gradientStops'] as List?)
          ?.map((s) => (s as num).toDouble())
          .toList(),
      gradientAngle: (json['gradientAngle'] as num?)?.toDouble() ?? 135.0,
    );
  }
}

enum DesignEffectType {
  dropShadow,
  innerShadow,
  blur,
  backgroundBlur,
  outerGlow,
  innerGlow,
  colorTint,
  vignette,
  bloom,
  grayscale,
  sepia,
  invertColors,
}

class DesignEffect {
  final DesignEffectType type;
  final Color color;
  final double offsetX;
  final double offsetY;
  final double blurRadius;
  final double spreadRadius;
  final bool isVisible;

  const DesignEffect({
    this.type = DesignEffectType.dropShadow,
    this.color = const Color(0x33000000),
    this.offsetX = 0.0,
    this.offsetY = 4.0,
    this.blurRadius = 8.0,
    this.spreadRadius = 0.0,
    this.isVisible = true,
  });

  DesignEffect copyWith({
    DesignEffectType? type,
    Color? color,
    double? offsetX,
    double? offsetY,
    double? blurRadius,
    double? spreadRadius,
    bool? isVisible,
  }) {
    return DesignEffect(
      type: type ?? this.type,
      color: color ?? this.color,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      blurRadius: blurRadius ?? this.blurRadius,
      spreadRadius: spreadRadius ?? this.spreadRadius,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'color': color.toARGB32(),
    'offsetX': offsetX,
    'offsetY': offsetY,
    'blurRadius': blurRadius,
    'spreadRadius': spreadRadius,
    'isVisible': isVisible,
  };

  factory DesignEffect.fromJson(Map<String, dynamic> json) {
    return DesignEffect(
      type: DesignEffectType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DesignEffectType.dropShadow,
      ),
      color: Color(json['color'] as int? ?? 0x33000000),
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 4.0,
      blurRadius: (json['blurRadius'] as num?)?.toDouble() ?? 8.0,
      spreadRadius: (json['spreadRadius'] as num?)?.toDouble() ?? 0.0,
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }
}

class CornerRadii {
  final double topLeft;
  final double topRight;
  final double bottomRight;
  final double bottomLeft;

  const CornerRadii({
    this.topLeft = 0,
    this.topRight = 0,
    this.bottomRight = 0,
    this.bottomLeft = 0,
  });

  const CornerRadii.all(double radius)
    : topLeft = radius,
      topRight = radius,
      bottomRight = radius,
      bottomLeft = radius;

  bool get isUniform =>
      topLeft == topRight && topRight == bottomRight && bottomRight == bottomLeft;

  double get uniformValue => isUniform ? topLeft : 0.0;

  BorderRadius toBorderRadius() {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomRight: Radius.circular(bottomRight),
      bottomLeft: Radius.circular(bottomLeft),
    );
  }

  CornerRadii copyWith({
    double? topLeft,
    double? topRight,
    double? bottomRight,
    double? bottomLeft,
  }) {
    return CornerRadii(
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomRight: bottomRight ?? this.bottomRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
    );
  }

  Map<String, dynamic> toJson() => {
    'topLeft': topLeft,
    'topRight': topRight,
    'bottomRight': bottomRight,
    'bottomLeft': bottomLeft,
  };

  factory CornerRadii.fromJson(Map<String, dynamic> json) {
    return CornerRadii(
      topLeft: (json['topLeft'] as num?)?.toDouble() ?? 0.0,
      topRight: (json['topRight'] as num?)?.toDouble() ?? 0.0,
      bottomRight: (json['bottomRight'] as num?)?.toDouble() ?? 0.0,
      bottomLeft: (json['bottomLeft'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
