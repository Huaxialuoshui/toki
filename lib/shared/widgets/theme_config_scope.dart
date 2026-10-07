import 'package:flutter/material.dart';

import '../../domain/entities/theme_config.dart';

// 把"当前生效的 ThemeConfig"整体注入 widget 树。
//
// ThemeData 只承载颜色/字体/组件主题，装不下"日历事件默认色""倒计时默认色"
// 这类项目级约定，所以单独用一个 InheritedWidget 往下传。
class ThemeConfigScope extends InheritedWidget {
  const ThemeConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  final ThemeConfig config;

  static ThemeConfig? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeConfigScope>()?.config;

  @override
  bool updateShouldNotify(ThemeConfigScope oldWidget) =>
      oldWidget.config != config;
}
