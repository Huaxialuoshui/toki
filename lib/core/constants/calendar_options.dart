import 'package:flutter/material.dart';

/// 事件可选颜色。
///
/// 只放"事件色"这一类语义色，主题色仍然来自 ThemeConfig。
abstract final class EventPalette {
  static const List<Color> colors = <Color>[
    Color(0xFF5A6BF0),
    Color(0xFF7C8CFF),
    Color(0xFF12B5A5),
    Color(0xFF3DBF7A),
    Color(0xFFF0A05A),
    Color(0xFFE4577B),
    Color(0xFFB48CFF),
    Color(0xFF6B7A90),
  ];
}

/// 提醒预设（分钟）。0 表示"准时提醒"，null 表示不提醒。
abstract final class ReminderPresets {
  static const List<int> minutes = <int>[0, 5, 10, 30, 60, 1440];
}
