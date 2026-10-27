import 'package:flutter/material.dart';

class ColorToken {
  final String id;
  final String name;
  final Color value;
  final String? description;

  const ColorToken({
    required this.id,
    required this.name,
    required this.value,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'value': value.toARGB32(),
    if (description != null) 'description': description,
  };

  factory ColorToken.fromJson(Map<String, dynamic> json) => ColorToken(
    id: json['id'] as String,
    name: json['name'] as String,
    value: Color(json['value'] as int),
    description: json['description'] as String?,
  );
}

class SpacingToken {
  final String id;
  final String name;
  final double value;

  const SpacingToken({
    required this.id,
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'value': value};

  factory SpacingToken.fromJson(Map<String, dynamic> json) => SpacingToken(
    id: json['id'] as String,
    name: json['name'] as String,
    value: (json['value'] as num).toDouble(),
  );
}

class RadiusToken {
  final String id;
  final String name;
  final double value;

  const RadiusToken({
    required this.id,
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'value': value};

  factory RadiusToken.fromJson(Map<String, dynamic> json) => RadiusToken(
    id: json['id'] as String,
    name: json['name'] as String,
    value: (json['value'] as num).toDouble(),
  );
}

class DesignTokens {
  final List<ColorToken> colorTokens;
  final List<SpacingToken> spacingTokens;
  final List<RadiusToken> radiusTokens;

  const DesignTokens({
    this.colorTokens = const [],
    this.spacingTokens = const [],
    this.radiusTokens = const [],
  });

  factory DesignTokens.defaultTokens() {
    return const DesignTokens(
      colorTokens: [
        ColorToken(id: 'c-bg', name: 'Background', value: Color(0xFFE6ECF5)),
        ColorToken(id: 'c-surface', name: 'Surface', value: Color(0xFFE6ECF5)),
        ColorToken(
          id: 'c-main-text',
          name: 'Main Text',
          value: Color(0xFF2B3445),
        ),
        ColorToken(
          id: 'c-muted-text',
          name: 'Muted Text',
          value: Color(0xFF8A99AD),
        ),
        ColorToken(
          id: 'c-accent',
          name: 'Accent Slate',
          value: Color(0xFF1E2532),
        ),
        ColorToken(id: 'c-blue', name: 'Brand Blue', value: Color(0xFF3B82F6)),
        ColorToken(
          id: 'c-green',
          name: 'Success Green',
          value: Color(0xFF10B981),
        ),
        ColorToken(id: 'c-white', name: 'Pure White', value: Color(0xFFFFFFFF)),
      ],
      spacingTokens: [
        SpacingToken(id: 's-xs', name: 'XS (4px)', value: 4.0),
        SpacingToken(id: 's-sm', name: 'SM (8px)', value: 8.0),
        SpacingToken(id: 's-md', name: 'MD (16px)', value: 16.0),
        SpacingToken(id: 's-lg', name: 'LG (24px)', value: 24.0),
        SpacingToken(id: 's-xl', name: 'XL (32px)', value: 32.0),
      ],
      radiusTokens: [
        RadiusToken(id: 'r-sm', name: 'Small (8px)', value: 8.0),
        RadiusToken(id: 'r-md', name: 'Medium (16px)', value: 16.0),
        RadiusToken(id: 'r-lg', name: 'Large (24px)', value: 24.0),
        RadiusToken(id: 'r-pill', name: 'Pill (999px)', value: 999.0),
      ],
    );
  }

  DesignTokens copyWith({
    List<ColorToken>? colorTokens,
    List<SpacingToken>? spacingTokens,
    List<RadiusToken>? radiusTokens,
  }) {
    return DesignTokens(
      colorTokens: colorTokens ?? this.colorTokens,
      spacingTokens: spacingTokens ?? this.spacingTokens,
      radiusTokens: radiusTokens ?? this.radiusTokens,
    );
  }

  Map<String, dynamic> toJson() => {
    'colorTokens': colorTokens.map((t) => t.toJson()).toList(),
    'spacingTokens': spacingTokens.map((t) => t.toJson()).toList(),
    'radiusTokens': radiusTokens.map((t) => t.toJson()).toList(),
  };

  factory DesignTokens.fromJson(Map<String, dynamic> json) {
    return DesignTokens(
      colorTokens: (json['colorTokens'] as List? ?? [])
          .map((t) => ColorToken.fromJson(t as Map<String, dynamic>))
          .toList(),
      spacingTokens: (json['spacingTokens'] as List? ?? [])
          .map((t) => SpacingToken.fromJson(t as Map<String, dynamic>))
          .toList(),
      radiusTokens: (json['radiusTokens'] as List? ?? [])
          .map((t) => RadiusToken.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
