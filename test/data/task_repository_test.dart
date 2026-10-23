import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_planning_preferences_repository.dart';
import 'package:toki/data/repositories/drift_task_repository.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftTaskRepository repository;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 18, 10));

  TaskItem buildTask({
    required String id,
    String title = '任务',
    TaskPriority priority = TaskPriority.normal,
    TaskStatus status = TaskStatus.open,
    DateTime? dueAt,
    DateTime? archivedAt,
  }) {
    return TaskItem(
      id: id,
      title: title,
      priority: priority,
      status: status,
      source: TaskSource.manual,
      dueAt: dueAt,
      postponeCount: 0,
      archivedAt: archivedAt,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    );
  }

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftTaskRepository(database);
  });

  tearDown(() => database.close());

  test('任务 CRUD 与可空字段往返', () async {
    await repository.upsert(
      buildTask(
        id: 't1',
        title: '写周报',
        priority: TaskPriority.high,
        dueAt: DateTime(2026, 10, 19, 18),
      ).copyWith(
        description: '列出本周完成项',
        estimatedMinutes: 45,
        actualMinutes: 30,
        completionNote: '提前完成',
        postponeCount: 2,
      ),
    );

    final loaded = (await repository.findById('t1'))!;
    expect(loaded.title, '写周报');
    expect(loaded.description, '列出本周完成项');
    expect(loaded.priority, TaskPriority.high);
    expect(loaded.estimatedMinutes, 45);
    expect(loaded.actualMinutes, 30);
    expect(loaded.postponeCount, 2);

    await repository.upsert(
      loaded.copyWith(
        title: '写月报',
        clearDescription: true,
        clearActualMinutes: true,
      ),
    );
    final updated = (await repository.findById('t1'))!;
    expect(updated.title, '写月报');
    expect(updated.description, null);
    expect(updated.actualMinutes, null);

    await repository.deleteById('t1');
    expect(await repository.findById('t1'), null);
  });

  test('活动任务按阻塞 / 优先级 / 截止时间排序，完成与归档分开', () async {
    await repository.upsertAll(<TaskItem>[
      buildTask(id: 'low', priority: TaskPriority.low),
      buildTask(
        id: 'urgent-later',
        priority: TaskPriority.urgent,
        dueAt: DateTime(2026, 10, 20),
      ),
      buildTask(
        id: 'urgent-sooner',
        priority: TaskPriority.urgent,
        dueAt: DateTime(2026, 10, 19),
      ),
      buildTask(id: 'blocked', status: TaskStatus.blocked),
      buildTask(id: 'done', status: TaskStatus.completed),
      buildTask(
        id: 'archived',
        archivedAt: DateTime(2026, 10, 17),
      ),
    ]);

    final active = await repository.getActive();
    expect(
      active.map((TaskItem task) => task.id).toList(),
      <String>['urgent-sooner', 'urgent-later', 'low', 'blocked'],
    );
    expect(
      (await repository.watchCompleted().first).map((TaskItem task) => task.id),
      <String>['done'],
    );
    expect(
      (await repository.watchArchived().first).map((TaskItem task) => task.id),
      <String>['archived'],
    );
  });

  test('逾期与近期截止只返回未归档的未完成任务', () async {
    await repository.upsertAll(<TaskItem>[
      buildTask(id: 'overdue', dueAt: DateTime(2026, 10, 17, 18)),
      buildTask(id: 'soon', dueAt: DateTime(2026, 10, 19, 9)),
      buildTask(id: 'done', status: TaskStatus.completed),
      buildTask(
        id: 'archived',
        dueAt: DateTime(2026, 10, 17, 18),
        archivedAt: DateTime(2026, 10, 18),
      ),
    ]);

    expect(
      (await repository.getOverdue(clock.now()))
          .map((TaskItem task) => task.id),
      <String>['overdue'],
    );
    expect(
      (await repository.getDueSoon(
        clock.now(),
        DateTime(2026, 10, 20),
      ))
          .map((TaskItem task) => task.id),
      <String>['soon'],
    );
  });

  test('删除任务不会删除日程，只会把事件 taskId 置空', () async {
    await repository.upsert(buildTask(id: 't1'));
    await database.into(database.calendarEvents).insert(
          CalendarEventsCompanion.insert(
            id: 'event-1',
            title: '执行任务',
            startTime: DateTime(2026, 10, 18, 14),
            endTime: DateTime(2026, 10, 18, 15),
            taskId: const Value<String>('t1'),
            status: EventStatus.scheduled,
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );

    await repository.deleteById('t1');

    final event = await database.select(database.calendarEvents).getSingle();
    expect(event.id, 'event-1');
    expect(event.taskId, null);
  });

  test('规划偏好默认值、保存与清除', () async {
    final preferencesRepository = DriftPlanningPreferencesRepository(
      database,
      clock: clock,
    );
    final defaults = await preferencesRepository.load();
    expect(defaults.workdayStartMinute, 9 * 60);
    expect(defaults.workdayEndMinute, 18 * 60);
    expect(defaults.weekdaysOnly, isTrue);

    await preferencesRepository.save(
      defaults.copyWith(
        workdayStartMinute: 8 * 60,
        focusMinutes: 90,
        weekdaysOnly: false,
      ),
    );
    final saved = await preferencesRepository.load();
    expect(saved.workdayStartMinute, 8 * 60);
    expect(saved.focusMinutes, 90);
    expect(saved.weekdaysOnly, isFalse);

    await preferencesRepository.clear();
    final reset = await preferencesRepository.load();
    expect(reset.workdayStartMinute, 9 * 60);
  });
}
