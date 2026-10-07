import 'package:flutter/material.dart';

/// 倒计时展示样式（规格 §7 的"多种显示模式"）。
///
/// Phase 1 实现 [bigNumber] 与 [fullText] 两种渲染，Phase 4 接入数据后再开放
/// 逐条切换。
enum CountdownDisplayStyle {
  /// 大数字 + 单位，例如 `13 天`。
  bigNumber,

  /// 完整文本，例如 `距离毕业答辩还有 13天 08小时 21分钟`。
  fullText,
}

/// 倒计时条目。
///
/// 与规格 §5 的 `Countdown` 表对应。注意 `remainingSeconds` 这类派生值不会
/// 出现在模型里，一律由 `CountdownRemaining` 实时计算。
@immutable
class CountdownItem {
  const CountdownItem({
    required this.id,
    required this.title,
    required this.targetTime,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.color,
    this.backgroundColor,
    this.icon,
    this.isPinned = false,
    this.displayStyle = CountdownDisplayStyle.fullText,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final DateTime targetTime;
  final String? description;
  final Color? color;

  /// 卡片背景色；为空时用主题的 surface 色。
  final Color? backgroundColor;

  /// 图标标识（使用 Material 图标名，Phase 4 支持自定义）。
  final String? icon;
  final bool isPinned;
  final CountdownDisplayStyle displayStyle;

  /// 手动排序位（Phase 4 拖动排序时写回）。
  final int sortOrder;

  final DateTime createdAt;
  final DateTime updatedAt;

  CountdownItem copyWith({
    String? id,
    String? title,
    DateTime? targetTime,
    String? description,
    Color? color,
    Color? backgroundColor,
    String? icon,
    bool? isPinned,
    CountdownDisplayStyle? displayStyle,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CountdownItem(
      id: id ?? this.id,
      title: title ?? this.title,
      targetTime: targetTime ?? this.targetTime,
      description: description ?? this.description,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      icon: icon ?? this.icon,
      isPinned: isPinned ?? this.isPinned,
      displayStyle: displayStyle ?? this.displayStyle,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountdownItem &&
        other.id == id &&
        other.title == title &&
        other.targetTime == targetTime &&
        other.description == description &&
        other.color == color &&
        other.backgroundColor == backgroundColor &&
        other.icon == icon &&
        other.isPinned == isPinned &&
        other.displayStyle == displayStyle &&
        other.sortOrder == sortOrder &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        targetTime,
        description,
        color,
        backgroundColor,
        icon,
        isPinned,
        displayStyle,
        sortOrder,
        createdAt,
        updatedAt,
      );
}
