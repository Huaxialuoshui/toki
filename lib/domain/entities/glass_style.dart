import 'package:flutter/material.dart';

import 'theme_config.dart';

/// 玻璃拟态样式。
///
/// 透明度与模糊**不属于** `ThemeData` 的职责，单独建模可以让卡片、聊天气泡、
/// 聊天背景等复用同一套参数（规格 §9 / §10）。
@immutable
class GlassStyle {
  const GlassStyle({
    required this.opacity,
    required this.blurAmount,
    required this.borderRadius,
    this.tintColor,
    this.borderColor,
  });

  /// 从主题配置派生玻璃参数。
  factory GlassStyle.fromThemeConfig(ThemeConfig config) => GlassStyle(
        opacity: config.cardOpacity,
        blurAmount: config.blurAmount,
        borderRadius: config.borderRadius,
        tintColor: config.surfaceColor,
        borderColor: config.textColor.withValues(alpha: 0.08),
      );

  /// 卡片不透明度（0 - 1）。
  final double opacity;

  /// 背景模糊强度（sigma）。
  final double blurAmount;

  final double borderRadius;

  /// 玻璃底色。
  final Color? tintColor;

  /// 玻璃描边颜色。
  final Color? borderColor;

  bool get hasBlur => blurAmount > 0;

  bool get isTranslucent => opacity < 1;

  BorderRadius get radius => BorderRadius.circular(borderRadius);

  GlassStyle copyWith({
    double? opacity,
    double? blurAmount,
    double? borderRadius,
    Color? tintColor,
    Color? borderColor,
  }) {
    return GlassStyle(
      opacity: opacity ?? this.opacity,
      blurAmount: blurAmount ?? this.blurAmount,
      borderRadius: borderRadius ?? this.borderRadius,
      tintColor: tintColor ?? this.tintColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GlassStyle &&
        other.opacity == opacity &&
        other.blurAmount == blurAmount &&
        other.borderRadius == borderRadius &&
        other.tintColor == tintColor &&
        other.borderColor == borderColor;
  }

  @override
  int get hashCode =>
      Object.hash(opacity, blurAmount, borderRadius, tintColor, borderColor);
}
