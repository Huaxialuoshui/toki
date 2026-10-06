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

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftCalendarRepository events;
  late DriftReminderRepository reminders;
  late AppSettingsStore settings;
  late FakeNotificationService notifications;
  late ReminderScheduler scheduler;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    database = AppDatabase.memory();
    events = DriftCalendarRepository(database, clock: clock);
    reminders = DriftReminderRepository(database);
    settings = AppSettingsStore(await SharedPreferences.getInstance());
    notifications = FakeNotificationService();
    scheduler = ReminderScheduler(
      notifications: notifications,
      reminders: reminders,
      events: events,
      settings: settings,
      clock: clock,
      // 固定英文，断言文案稳定。
      locale: () => const Locale('en'),
    );
  });

  tearDown(() => database.close());

  Future<void> addEvent({
    String id = 'e1',
    String title = '答辩',
    DateTime? start,
  }) async {
    final startTime = start ?? DateTime(2026, 10, 7, 9);
    await events.upsert(
      CalendarEvent(
        id: id,
        title: title,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 1)),
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );
  }

  Future<void> addReminder({
    required String id,
    required DateTime trigger,
    String? eventId,
    String title = '答辩',
    bool enabled = true,
  }) async {
    await reminders.upsert(
      Reminder(
        id: id,
        eventId: eventId,
        title: title,
        triggerTime: trigger,
        enabled: enabled,
        createdAt: clock.now(),
      ),
    );
  }

  String bodyOf(String reminderId) => notifications.scheduled
      .firstWhere(
        (ScheduledNotification item) =>
            item.id == ReminderScheduler.notificationIdFor(reminderId),
      )
      .body;

  test('只排期"已启用且在将来"的提醒，并带上正确的标题与时间', () async {
    await addEvent();
    await addReminder(
      id: 'r-future',
      trigger: DateTime(2026, 10, 6, 14, 30),
      eventId: 'e1',
    );
    await addReminder(
      id: 'r-past',
      trigger: DateTime(2026, 10, 6, 9),
      eventId: 'e1',
    );
    await addReminder(
      id: 'r-disabled',
      trigger: DateTime(2026, 10, 6, 14),
      eventId: 'e1',
      enabled: false,
    );

    await scheduler.sync();

    expect(notifications.scheduled, hasLength(1));
    final ScheduledNotification scheduled = notifications.scheduled.single;
    expect(scheduled.id, ReminderScheduler.notificationIdFor('r-future'));
    expect(scheduled.title, '答辩');
    expect(scheduled.scheduledTime, DateTime(2026, 10, 6, 14, 30));
    expect(scheduled.payload, 'e1');
  });

  test('正文体现提前量：分钟 / 小时 / 天 / 已到点 / 无关联日程', () async {
    await addEvent(start: DateTime(2026, 10, 7, 9));
    await addEvent(id: 'e2', title: '体检', start: DateTime(2026, 10, 8, 9));

    await addReminder(
      id: 'r-minutes',
      trigger: DateTime(2026, 10, 7, 8, 30),
      eventId: 'e1',
    );
    await addReminder(
      id: 'r-hours',
      trigger: DateTime(2026, 10, 7, 7),
      eventId: 'e1',
    );
    await addReminder(
      id: 'r-days',
      trigger: DateTime(2026, 10, 7, 9),
      eventId: 'e2',
    );
    await addReminder(
      id: 'r-now',
      trigger: DateTime(2026, 10, 7, 9),
      eventId: 'e1',
    );
    await addReminder(
      id: 'r-independent',
      trigger: DateTime(2026, 10, 8, 9),
      title: '独立提醒',
    );

    await scheduler.sync();

    expect(bodyOf('r-minutes'), 'Starts in 30 min');
    expect(bodyOf('r-hours'), 'Starts in 2 h');
    expect(bodyOf('r-days'), 'Starts in 1 d');
    expect(bodyOf('r-now'), 'Starting now');
    expect(bodyOf('r-independent'), 'Reminder from Toki');
  });

  test('提醒被删除后，之前的排期会被取消', () async {
    await addEvent();
    await addReminder(
      id: 'r1',
      trigger: DateTime(2026, 10, 6, 14),
      eventId: 'e1',
    );
    await scheduler.sync();
    expect(notifications.scheduled, hasLength(1));

    await reminders.deleteById('r1');
    await scheduler.sync();

    expect(
      notifications.cancelled,
      contains(ReminderScheduler.notificationIdFor('r1')),
    );
    expect(notifications.scheduled, isEmpty);
    expect(settings.readScheduledNotificationIds(), isEmpty);
  });

  test('提醒被停用、或时间改到过去，都会取消排期', () async {
    await addEvent();
    await addReminder(
      id: 'r1',
      trigger: DateTime(2026, 10, 6, 14),
      eventId: 'e1',
    );
    await scheduler.sync();
    expect(notifications.scheduled, hasLength(1));

    await reminders.setEnabled(id: 'r1', enabled: false);
    await scheduler.sync();
    expect(notifications.scheduled, isEmpty);

    final existing = (await reminders.findById('r1'))!;
    await reminders.upsert(
      existing.copyWith(
        enabled: true,
        triggerTime: DateTime(2026, 10, 6, 8),
      ),
    );
    await scheduler.sync();
    expect(notifications.scheduled, isEmpty);
  });

  test('重复同步是幂等的：同一个提醒不会重复排期', () async {
    await addEvent();
    await addReminder(
      id: 'r1',
      trigger: DateTime(2026, 10, 6, 14),
      eventId: 'e1',
    );

    await scheduler.sync();
    await scheduler.sync();
    await scheduler.sync();

    expect(notifications.scheduled, hasLength(1));
    expect(settings.readScheduledNotificationIds(), hasLength(1));
  });

  test('通知 id 稳定、非负，且不同提醒不冲突', () {
    final int a1 = ReminderScheduler.notificationIdFor('reminder-abc');
    final int a2 = ReminderScheduler.notificationIdFor('reminder-abc');
    final int b = ReminderScheduler.notificationIdFor('reminder-xyz');

    expect(a1, a2);
    expect(a1, isNot(b));
    expect(a1, greaterThanOrEqualTo(0));
    expect(b, greaterThanOrEqualTo(0));
  });
}
