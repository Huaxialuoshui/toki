import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/entities/glass_style.dart';

/// 把 [GlassStyle] 注入 widget 树的继承组件。
///
/// 透明度 / 模糊不进入 `ThemeData`，而是通过这里向下传递，`GlassCard`、
/// 未来的聊天气泡与聊天背景都从同一个来源取参数。
class GlassTheme extends InheritedTheme {
  const GlassTheme({super.key, required this.style, required super.child});

  final GlassStyle style;

  static GlassStyle of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<GlassTheme>();
    return theme?.style ??
        const GlassStyle(opacity: 1, blurAmount: 0, borderRadius: 18);
  }

  @override
  bool updateShouldNotify(GlassTheme oldWidget) => oldWidget.style != style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      GlassTheme(style: style, child: child);
}

/// 玻璃拟态卡片：负责透明度与模糊，颜色/圆角默认跟随当前主题与 [GlassTheme]。
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.style,
    this.color,
    this.onTap,
    this.border,
  });

  final Widget? child;
  final EdgeInsetsGeometry padding;

  /// 覆盖当前 [GlassTheme] 的参数；不传则用继承下来的样式。
  final GlassStyle? style;

  /// 覆盖底色（默认用主题 surface 色）。
  final Color? color;

  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = style ?? GlassTheme.of(context);
    final radius = glass.radius;
    final tint = color ?? theme.colorScheme.surface;
    final opacity = glass.opacity.clamp(0.0, 1.0);

    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: opacity),
        borderRadius: radius,
        border: border ??
            Border.all(
              color: glass.borderColor ?? theme.dividerColor,
            ),
      ),
      child: child,
    );

    if (glass.hasBlur) {
      card = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass.blurAmount,
            sigmaY: glass.blurAmount,
          ),
          child: card,
        ),
      );
    }

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: card,
        ),
      );
    }

    return card;
  }
}
