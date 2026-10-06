import 'package:flutter/material.dart';

import '../../domain/entities/theme_config.dart';

/// 内置主题预设。
///
/// Phase 1 只提供 Default / Light / Dark 三套（其余预设留给 Phase 11 的主题
/// 编辑器）。`ThemeConfig.name` 是技术标签，界面上的显示名由 i18n 提供，
/// 通过 [ThemePresets.defaultId] 等 id 映射。
abstract final class ThemePresets {
  static const String defaultId = 'default';
  static const String lightId = 'light';
  static const String darkId = 'dark';

  static const ThemeConfig defaultTheme = ThemeConfig(
    id: defaultId,
    name: 'Default',
    brightness: Brightness.light,
    primaryColor: Color(0xFF5A6BF0),
    secondaryColor: Color(0xFF9C6BF0),
    backgroundColor: Color(0xFFF4F5FA),
    surfaceColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF1B1D2A),
    borderRadius: 18,
    cardOpacity: 1,
    blurAmount: 0,
  );

  static const ThemeConfig lightTheme = ThemeConfig(
    id: lightId,
    name: 'Light',
    brightness: Brightness.light,
    primaryColor: Color(0xFF2F6FED),
    secondaryColor: Color(0xFF12B5A5),
    backgroundColor: Color(0xFFFFFFFF),
    surfaceColor: Color(0xFFF2F4F7),
    textColor: Color(0xFF14161C),
    borderRadius: 12,
    cardOpacity: 1,
    blurAmount: 0,
  );

  static const ThemeConfig darkTheme = ThemeConfig(
    id: darkId,
    name: 'Dark',
    brightness: Brightness.dark,
    primaryColor: Color(0xFF7C8CFF),
    secondaryColor: Color(0xFFB48CFF),
    backgroundColor: Color(0xFF0E1016),
    surfaceColor: Color(0xFF1A1D26),
    textColor: Color(0xFFECEFF8),
    borderRadius: 20,
    cardOpacity: 0.86,
    blurAmount: 14,
  );

  static const List<ThemeConfig> all = <ThemeConfig>[
    defaultTheme,
    lightTheme,
    darkTheme,
  ];

  /// 按 id 取预设；未知 id 回落到 [defaultTheme]。
  static ThemeConfig byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return defaultTheme;
  }

  static bool isKnownId(String id) => all.any((preset) => preset.id == id);
}
