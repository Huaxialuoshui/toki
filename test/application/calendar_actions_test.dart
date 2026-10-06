import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/calendar/calendar_actions.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/core/utils/id_generator.dart';
import 'package:toki/data/repositories/drift_calendar_repository.dart';
import 'package:toki/data/repositories/drift_reminder_repository.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftCalendarRepository events;
  late DriftReminderRepository reminders;
  late CalendarActions actions;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 6, 10));

  CalendarEvent buildEvent({
    String id = 'event-1',
    String title = '毕业设计答辩',
    int? reminderMinutes,
    DateTime? start,
  }) {
    final startTime = start ?? DateTime(2026, 10, 8, 15);
    return CalendarEvent(
      id: id,
      title: title,
      startTime: startTime,
      endTime: startTime.add(const Duration(hours: 1, minutes: 30)),
      color: const Color(0xFF5A6BF0),
      reminderMinutes: reminderMinutes,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    );
  }

  setUp(() {
    database = AppDatabase.memory();
    events = DriftCalendarRepository(database, clock: clock);
    reminders = DriftReminderRepository(database);
    actions = CalendarActions(
      events: events,
      reminders: reminders,
      clock: clock,
    );
  });

  tearDown(() => database.close());

  test('保存带提醒的事件会写入一条提醒行', () async {
    final event = buildEvent(reminderMinutes: 30);
    await actions.saveEvent(event);

    final rows = await reminders.getForEvent(event.id);
    expect(rows, hasLength(1));
    expect(rows.single.title, '毕业设计答辩');
    expect(rows.single.triggerTime, DateTime(2026, 10, 8, 14, 30));
    expect(rows.single.enabled, isTrue);
  });

  test('不提醒的事件不会留下提醒行', () async {
    final event = buildEvent(reminderMinutes: null);
    await actions.saveEvent(event);
    expect(await reminders.getForEvent(event.id), isEmpty);
  });

  test('修改提醒设置会替换而不是叠加', () async {
    await actions.saveEvent(buildEvent(reminderMinutes: 30));
    await actions.saveEvent(buildEvent(reminderMinutes: 10));

    final rows = await reminders.getForEvent('event-1');
    expect(rows, hasLength(1));
    expect(rows.single.triggerTime, DateTime(2026, 10, 8, 14, 50));

    await actions.saveEvent(buildEvent(reminderMinutes: null));
    expect(await reminders.getForEvent('event-1'), isEmpty);
  });

  test('改时间后提醒时间跟着事件走', () async {
    await actions.saveEvent(buildEvent(reminderMinutes: 60));
    await actions.saveEvent(
      buildEvent(reminderMinutes: 60, start: DateTime(2026, 10, 9, 9)),
    );

    final rows = await reminders.getForEvent('event-1');
    expect(rows.single.triggerTime, DateTime(2026, 10, 9, 8));
  });

  test('删除事件会连带删除提醒（外键约束下不报错）', () async {
    final event = buildEvent(reminderMinutes: 15);
    await actions.saveEvent(event);
    expect(await reminders.getForEvent(event.id), hasLength(1));

    await actions.deleteEvent(event.id);

    expect(await events.findById(event.id), isNull);
    expect(await events.count(), 0);
    expect(await reminders.getForEvent(event.id), isEmpty);
    expect(await reminders.count(), 0);
  });

  test('id 生成器每次返回不同值并带前缀', () {
    final first = generateId('event', now: clock.now());
    final second = generateId('event', now: clock.now());

    expect(first, startsWith('event-'));
    expect(first, isNot(second));
  });
}
