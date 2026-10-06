import 'package:flutter/material.dart';

/// 事件状态。Phase 1 只用于展示，Phase 3 接入增删改时复用。
enum EventStatus { scheduled, completed, cancelled }

/// 日历事件。
///
/// 字段与规格 §5 的 `CalendarEvent` 表一一对应，Phase 2 建库时可以直接映射，
/// 不需要改动 UI 层。
@immutable
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.allDay = false,
    this.location,
    this.categoryId,
    this.color,
    this.repeatRule,
    this.reminderMinutes,
    this.status = EventStatus.scheduled,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String? location;
  final String? categoryId;
  final Color? color;

  /// 重复规则（RRULE 字符串），Phase 3 接入。
  final String? repeatRule;

  /// 提前提醒分钟数（如 5 / 10 / 30 / 60 / 1440）。
  final int? reminderMinutes;

  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Duration get duration => endTime.difference(startTime);

  bool get isCancelled => status == EventStatus.cancelled;

  /// 事件是否落在 [day] 这一天（按本地时间）。
  bool occursOn(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return startTime.isBefore(dayEnd) && !endTime.isBefore(dayStart);
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? allDay,
    String? location,
    String? categoryId,
    Color? color,
    String? repeatRule,
    int? reminderMinutes,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allDay: allDay ?? this.allDay,
      location: location ?? this.location,
      categoryId: categoryId ?? this.categoryId,
      color: color ?? this.color,
      repeatRule: repeatRule ?? this.repeatRule,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.allDay == allDay &&
        other.location == location &&
        other.categoryId == categoryId &&
        other.color == color &&
        other.repeatRule == repeatRule &&
        other.reminderMinutes == reminderMinutes &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        startTime,
        endTime,
        allDay,
        location,
        categoryId,
        color,
        repeatRule,
        reminderMinutes,
        status,
        createdAt,
        updatedAt,
      );
}
