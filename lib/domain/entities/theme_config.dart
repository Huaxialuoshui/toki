import 'package:flutter/material.dart';

/// 主题配置（纯模型）。
///
/// 刻意与 `ThemeData` 解耦：它描述"用户想要什么样的界面"，由
/// `application/theme/theme_mapper.dart` 负责翻译成 `ThemeData`。
/// 透明度与模糊不进入 `ThemeData`，请见 [GlassStyle]。
@immutable
class ThemeConfig {
  const ThemeConfig({
    required this.id,
    required this.name,
    required this.brightness,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    this.borderRadius = 18,
    this.cardOpacity = 1,
    this.blurAmount = 0,
    this.fontScale = 1,
    this.animationEnabled = true,
  });

  final String id;
  final String name;
  final Brightness brightness;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;

  /// 圆角半径（逻辑像素）。
  final double borderRadius;

  /// 卡片不透明度（0 - 1），由玻璃层消费，不进入 `ThemeData`。
  final double cardOpacity;

  /// 背景模糊强度（sigma），由玻璃层消费，不进入 `ThemeData`。
  final double blurAmount;

  /// 字号缩放系数。
  final double fontScale;

  /// 是否启用过渡动画。
  final bool animationEnabled;

  bool get isLight => brightness == Brightness.light;

  bool get isDark => brightness == Brightness.dark;

  BorderRadius get radius => BorderRadius.circular(borderRadius);

  ThemeConfig copyWith({
    String? id,
    String? name,
    Brightness? brightness,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? textColor,
    double? borderRadius,
    double? cardOpacity,
    double? blurAmount,
    double? fontScale,
    bool? animationEnabled,
  }) {
    return ThemeConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      borderRadius: borderRadius ?? this.borderRadius,
      cardOpacity: cardOpacity ?? this.cardOpacity,
      blurAmount: blurAmount ?? this.blurAmount,
      fontScale: fontScale ?? this.fontScale,
      animationEnabled: animationEnabled ?? this.animationEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeConfig &&
        other.id == id &&
        other.name == name &&
        other.brightness == brightness &&
        other.primaryColor == primaryColor &&
        other.secondaryColor == secondaryColor &&
        other.backgroundColor == backgroundColor &&
        other.surfaceColor == surfaceColor &&
        other.textColor == textColor &&
        other.borderRadius == borderRadius &&
        other.cardOpacity == cardOpacity &&
        other.blurAmount == blurAmount &&
        other.fontScale == fontScale &&
        other.animationEnabled == animationEnabled;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        brightness,
        primaryColor,
        secondaryColor,
        backgroundColor,
        surfaceColor,
        textColor,
        borderRadius,
        cardOpacity,
        blurAmount,
        fontScale,
        animationEnabled,
      );

  @override
  String toString() => 'ThemeConfig($id, $brightness)';
}
