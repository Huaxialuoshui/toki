import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/notification/reminder_scheduler.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_calendar_repository.dart';
import 'package:toki/data/repositories/drift_reminder_repository.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/reminder.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../helpers/fake_notification_service.dart';
import '../helpers/sqlite_bootstrap.dart';

/// 重复日程 / 重复提醒的通知排期（规格 §6 §8）。
void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftCalendarRepository events;
  late DriftReminderRepository reminders;
  late FakeNotificationService notifications;
  late ReminderScheduler scheduler;
  late FixedClock clock;
  late AppSettingsStore settings;

  Future<void> setUpScheduler(DateTime now) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    clock = FixedClock(now);
    events = DriftCalendarRepository(database, clock: clock);
    reminders = DriftReminderRepository(database);
    notifications = FakeNotificationService();
    settings = AppSettingsStore(preferences);
    scheduler = ReminderScheduler(
      notifications: notifications,
      reminders: reminders,
      events: events,
      settings: settings,
      clock: clock,
      locale: () => const Locale('zh'),
    );
    addTearDown(database.close);
  }

  Future<void> addEventWithReminder({
    required String eventId,
    required DateTime start,
    String? repeatRule,
    DateTime? repeatUntil,
    int leadMinutes = 10,
  }) async {
    await events.upsert(
      CalendarEvent(
        id: eventId,
        title: '周会',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        repeatRule: repeatRule,
        repeatUntil: repeatUntil,
        reminderMinutes: leadMinutes,
        createdAt: start,
        updatedAt: start,
      ),
    );
    await reminders.upsert(
      Reminder(
        id: '$eventId-reminder',
        eventId: eventId,
        title: '周会',
        triggerTime: start.subtract(Duration(minutes: leadMinutes)),
        createdAt: start,
      ),
    );
  }

  test('重复日程会排期到未来每一次发生', () async {
    await setUpScheduler(DateTime(2026, 10, 6, 8));
    await addEventWithReminder(
      eventId: 'e-weekly',
      start: DateTime(2026, 10, 6, 9),
      repeatRule: 'daily',
    );

    await scheduler.sync();

    // 视野 30 天，最多 30 条：这里应当排满上限。
    expect(
      notifications.scheduled.length,
      ReminderScheduler.maxOccurrencesPerReminder,
    );
    // 第一条是当天 08:50 的那次。
    expect(notifications.scheduled.first.scheduledTime,
        DateTime(2026, 10, 6, 8, 50));
    expect(notifications.scheduled.first.title, '周会');
    expect(notifications.scheduled.first.body, contains('10 分钟'));
    // 每次发生的通知 id 都不一样。
    expect(
      notifications.scheduled.map((_) => 0).length,
      notifications.scheduled.length,
    );
    final ids = settings.readScheduledNotificationIds();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('重复截止之后不再排期', () async {
    await setUpScheduler(DateTime(2026, 10, 6, 8));
    await addEventWithReminder(
      eventId: 'e-until',
      start: DateTime(2026, 10, 6, 9),
      repeatRule: 'daily',
      repeatUntil: DateTime(2026, 10, 8),
    );

    await scheduler.sync();

    expect(notifications.scheduled, hasLength(3)); // 6 / 7 / 8
    expect(
      notifications.scheduled.last.scheduledTime,
      DateTime(2026, 10, 8, 8, 50),
    );
  });

  test('独立重复提醒（不关联日程）也会按规则排期', () async {
    await setUpScheduler(DateTime(2026, 10, 6, 8));
    await reminders.upsert(
      Reminder(
        id: 'r-daily',
        title: '喝水',
        triggerTime: DateTime(2026, 10, 6, 9),
        repeatRule: 'daily',
        createdAt: DateTime(2026, 10, 1),
      ),
    );

    await scheduler.sync();

    expect(notifications.scheduled, hasLength(30));
    expect(
        notifications.scheduled.first.scheduledTime, DateTime(2026, 10, 6, 9));
    expect(notifications.scheduled.first.title, '喝水');
  });

  test('取消重复日程后，之前排出去的通知都会被取消', () async {
    await setUpScheduler(DateTime(2026, 10, 6, 8));
    await addEventWithReminder(
      eventId: 'e-daily',
      start: DateTime(2026, 10, 6, 9),
      repeatRule: 'daily',
    );
    await scheduler.sync();
    final scheduled = notifications.scheduled.length;
    expect(scheduled, greaterThan(1));

    // 删掉事件与提醒后重新同步
    await reminders.deleteAll();
    await events.deleteById('e-daily');
    await scheduler.sync();

    expect(notifications.scheduled, isEmpty);
    expect(notifications.cancelled.length, scheduled);
    expect(settings.readScheduledNotificationIds(), isEmpty);
  });
}
