import 'package:flutter/foundation.dart';

import 'task_item.dart';

/// 每日规划偏好。
///
/// 默认只假设工作日 09:00–12:00、13:30–18:00 可用；周末没有明确窗口时
/// 不虚构具体时间。
@immutable
class PlanningPreferences {
  const PlanningPreferences({
    required this.createdAt,
    required this.updatedAt,
    this.workdayStartMinute = 9 * 60,
    this.workdayEndMinute = 18 * 60,
    this.lunchStartMinute = 12 * 60,
    this.lunchEndMinute = 13 * 60 + 30,
    this.focusMinutes = 60,
    this.breakMinutes = 10,
    this.defaultPriority = TaskPriority.normal,
    this.slotMinutes = 30,
    this.weekdaysOnly = true,
  });

  final int workdayStartMinute;
  final int workdayEndMinute;
  final int lunchStartMinute;
  final int lunchEndMinute;
  final int focusMinutes;
  final int breakMinutes;
  final TaskPriority defaultPriority;
  final int slotMinutes;
  final bool weekdaysOnly;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanningPreferences copyWith({
    int? workdayStartMinute,
    int? workdayEndMinute,
    int? lunchStartMinute,
    int? lunchEndMinute,
    int? focusMinutes,
    int? breakMinutes,
    TaskPriority? defaultPriority,
    int? slotMinutes,
    bool? weekdaysOnly,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanningPreferences(
      workdayStartMinute: workdayStartMinute ?? this.workdayStartMinute,
      workdayEndMinute: workdayEndMinute ?? this.workdayEndMinute,
      lunchStartMinute: lunchStartMinute ?? this.lunchStartMinute,
      lunchEndMinute: lunchEndMinute ?? this.lunchEndMinute,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      slotMinutes: slotMinutes ?? this.slotMinutes,
      weekdaysOnly: weekdaysOnly ?? this.weekdaysOnly,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlanningPreferences &&
        other.workdayStartMinute == workdayStartMinute &&
        other.workdayEndMinute == workdayEndMinute &&
        other.lunchStartMinute == lunchStartMinute &&
        other.lunchEndMinute == lunchEndMinute &&
        other.focusMinutes == focusMinutes &&
        other.breakMinutes == breakMinutes &&
        other.defaultPriority == defaultPriority &&
        other.slotMinutes == slotMinutes &&
        other.weekdaysOnly == weekdaysOnly &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        workdayStartMinute,
        workdayEndMinute,
        lunchStartMinute,
        lunchEndMinute,
        focusMinutes,
        breakMinutes,
        defaultPriority,
        slotMinutes,
        weekdaysOnly,
        createdAt,
        updatedAt,
      );
}
