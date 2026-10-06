import 'package:flutter/foundation.dart';

/// 提醒（规格 §5 的 Reminder）。
@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.triggerTime,
    required this.createdAt,
    this.eventId,
    this.repeatRule,
    this.enabled = true,
  });

  final String id;

  /// 关联的日程；为空表示独立提醒。
  final String? eventId;
  final String title;
  final DateTime triggerTime;

  /// 重复规则（RRULE），Phase 5 接入通知时使用。
  final String? repeatRule;
  final bool enabled;
  final DateTime createdAt;

  Reminder copyWith({
    String? id,
    String? eventId,
    String? title,
    DateTime? triggerTime,
    String? repeatRule,
    bool? enabled,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      triggerTime: triggerTime ?? this.triggerTime,
      repeatRule: repeatRule ?? this.repeatRule,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder &&
        other.id == id &&
        other.eventId == eventId &&
        other.title == title &&
        other.triggerTime == triggerTime &&
        other.repeatRule == repeatRule &&
        other.enabled == enabled &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        eventId,
        title,
        triggerTime,
        repeatRule,
        enabled,
        createdAt,
      );
}
