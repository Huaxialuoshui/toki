import 'package:flutter_test/flutter_test.dart';
import 'package:toki/data/repositories/drift_calendar_repository.dart';
import 'package:toki/data/repositories/drift_reminder_repository.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/reminder.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftReminderRepository repository;
  late DriftCalendarRepository calendarRepository;
  final DateTime now = DateTime(2026, 10, 6, 10);

  Reminder buildReminder({
    required String id,
    required DateTime trigger,
    String? eventId,
    String title = '提醒',
    bool enabled = true,
  }) {
    return Reminder(
      id: id,
      eventId: eventId,
      title: title,
      triggerTime: trigger,
      enabled: enabled,
      createdAt: now,
    );
  }

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftReminderRepository(database);
    calendarRepository = DriftCalendarRepository(database);
  });

  tearDown(() => database.close());

  test('创建 / 读取 / 更新 / 删除', () async {
    await repository.upsert(
      buildReminder(id: 'r1', trigger: DateTime(2026, 10, 8, 9)),
    );
    expect(await repository.count(), 1);
    expect(
      (await repository.findById('r1'))!.triggerTime,
      DateTime(2026, 10, 8, 9),
    );

    await repository.upsert(
      buildReminder(
        id: 'r1',
        trigger: DateTime(2026, 10, 8, 9),
        title: '改过的提醒',
      ),
    );
    expect(await repository.count(), 1);
    expect((await repository.findById('r1'))!.title, '改过的提醒');

    await repository.deleteById('r1');
    expect(await repository.count(), 0);
  });

  test('watchPending 只返回启用且未到时间的提醒', () async {
    await repository.upsertAll(<Reminder>[
      buildReminder(id: 'past', trigger: DateTime(2026, 10, 6, 8)),
      buildReminder(id: 'future', trigger: DateTime(2026, 10, 6, 12)),
      buildReminder(
        id: 'disabled',
        trigger: DateTime(2026, 10, 6, 13),
        enabled: false,
      ),
    ]);

    final pending =
        await repository.watchPending(from: DateTime(2026, 10, 6, 10)).first;

    expect(
      pending.map((Reminder reminder) => reminder.id),
      <String>['future'],
    );
  });

  test('setEnabled 与按事件查询', () async {
    await calendarRepository.upsert(
      CalendarEvent(
        id: 'e1',
        title: '答辩',
        startTime: DateTime(2026, 10, 8, 9),
        endTime: DateTime(2026, 10, 8, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.upsertAll(<Reminder>[
      buildReminder(
        id: 'r-event',
        trigger: DateTime(2026, 10, 8, 8),
        eventId: 'e1',
      ),
      buildReminder(id: 'r-other', trigger: DateTime(2026, 10, 9, 8)),
    ]);

    final forEvent = await repository.watchForEvent('e1').first;
    expect(forEvent.map((Reminder reminder) => reminder.id), <String>['r-event']);

    await repository.setEnabled(id: 'r-event', enabled: false);
    expect((await repository.findById('r-event'))!.enabled, isFalse);
  });
}
