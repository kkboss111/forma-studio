import 'package:flutter/material.dart';

class TextNodeData {
  final String text;
  final double fontSize;
  final String fontFamily;
  final int fontWeight;
  final bool isItalic;
  final bool underline;
  final bool strikethrough;
  final TextAlign textAlign;
  final double letterSpacing;
  final double lineHeight;
  final bool isAutoWidth;

  const TextNodeData({
    this.text = 'Text',
    this.fontSize = 16.0,
    this.fontFamily = 'Plus Jakarta Sans',
    this.fontWeight = 500,
    this.isItalic = false,
    this.underline = false,
    this.strikethrough = false,
    this.textAlign = TextAlign.left,
    this.letterSpacing = 0.0,
    this.lineHeight = 1.3,
    this.isAutoWidth = true,
  });

  TextNodeData copyWith({
    String? text,
    double? fontSize,
    String? fontFamily,
    int? fontWeight,
    bool? isItalic,
    bool? underline,
    bool? strikethrough,
    TextAlign? textAlign,
    double? letterSpacing,
    double? lineHeight,
    bool? isAutoWidth,
  }) {
    return TextNodeData(
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      fontWeight: fontWeight ?? this.fontWeight,
      isItalic: isItalic ?? this.isItalic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      textAlign: textAlign ?? this.textAlign,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      isAutoWidth: isAutoWidth ?? this.isAutoWidth,
    );
  }

  FontWeight get resolvedFontWeight {
    switch (fontWeight) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w500;
    }
  }

  TextDecoration get resolvedDecoration {
    if (underline && strikethrough) {
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    }
    if (underline) return TextDecoration.underline;
    if (strikethrough) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'fontWeight': fontWeight,
    'isItalic': isItalic,
    'underline': underline,
    'strikethrough': strikethrough,
    'textAlign': textAlign.name,
    'letterSpacing': letterSpacing,
    'lineHeight': lineHeight,
    'isAutoWidth': isAutoWidth,
  };

  factory TextNodeData.fromJson(Map<String, dynamic> json) {
    return TextNodeData(
      text: json['text'] as String? ?? 'Text',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      fontFamily: json['fontFamily'] as String? ?? 'Plus Jakarta Sans',
      fontWeight: json['fontWeight'] as int? ?? 500,
      isItalic: json['isItalic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      strikethrough: json['strikethrough'] as bool? ?? false,
      textAlign: TextAlign.values.firstWhere(
        (e) => e.name == json['textAlign'],
        orElse: () => TextAlign.left,
      ),
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.3,
      isAutoWidth: json['isAutoWidth'] as bool? ?? true,
    );
  }
}
