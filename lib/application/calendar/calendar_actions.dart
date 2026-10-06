import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../infrastructure/clock_provider.dart';

/// 日历的写操作入口。
///
/// UI 不直接组合多个仓储：保存事件时同步提醒行、删除事件时先删提醒再删事件
/// （`PRAGMA foreign_keys = ON`，否则会有外键约束错误），都收敛在这里，
/// 便于单测。
class CalendarActions {
  CalendarActions({
    required CalendarRepository events,
    required ReminderRepository reminders,
    required Clock clock,
  })  : _events = events,
        _reminders = reminders,
        _clock = clock;

  final CalendarRepository _events;
  final ReminderRepository _reminders;
  final Clock _clock;

  /// 保存事件，并让提醒行与 `reminderMinutes` 保持一致。
  Future<void> saveEvent(CalendarEvent event) async {
    await _events.upsert(event);

    // 先清掉这个事件已有的提醒，再按当前设置写入，避免重复。
    await _reminders.deleteForEvent(event.id);

    final minutes = event.reminderMinutes;
    if (minutes == null) return;

    await _reminders.upsert(
      Reminder(
        id: 'reminder-${event.id}',
        eventId: event.id,
        title: event.title,
        triggerTime: event.startTime.subtract(Duration(minutes: minutes)),
        createdAt: _clock.now(),
      ),
    );
  }

  /// 删除事件（连带它的提醒）。
  Future<void> deleteEvent(String eventId) async {
    await _reminders.deleteForEvent(eventId);
    await _events.deleteById(eventId);
  }
}

final calendarActionsProvider = Provider<CalendarActions>(
  (ref) => CalendarActions(
    events: ref.watch(calendarRepositoryProvider),
    reminders: ref.watch(reminderRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);
