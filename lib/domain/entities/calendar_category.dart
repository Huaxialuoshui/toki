import 'package:flutter/material.dart';

/// 日历分类（规格 §5 的 CalendarCategory）。
@immutable
class CalendarCategory {
  const CalendarCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.icon,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final Color color;

  /// 图标标识（Material 图标名）。
  final String? icon;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarCategory &&
        other.id == id &&
        other.name == name &&
        other.color == color &&
        other.icon == icon &&
        other.sortOrder == sortOrder &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(id, name, color, icon, sortOrder, createdAt, updatedAt);
}
