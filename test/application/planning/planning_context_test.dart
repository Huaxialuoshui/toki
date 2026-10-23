import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/planning/planning_context.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_calendar_repository.dart';
import 'package:toki/data/repositories/drift_countdown_repository.dart';
import 'package:toki/data/repositories/drift_daily_digest_repository.dart';
import 'package:toki/data/repositories/drift_planning_preferences_repository.dart';
import 'package:toki/data/repositories/drift_task_repository.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/countdown_item.dart';
import 'package:toki/domain/entities/daily_digest.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftCalendarRepository events;
  late DriftTaskRepository tasks;
  late DriftCountdownRepository countdowns;
  late DriftDailyDigestRepository digests;
  late DriftPlanningPreferencesRepository preferences;
  late FixedClock clock;

  PlanningContextBuilder builder({int maxChars = 6000}) =>
      PlanningContextBuilder(
        events: events,
        tasks: tasks,
        countdowns: countdowns,
        digests: digests,
        preferences: preferences,
        clock: clock,
        maxChars: maxChars,
      );

  CalendarEvent event({
    required String id,
    required String title,
    required DateTime start,
    required DateTime end,
    bool allDay = false,
    String? repeatRule,
    String? taskId,
  }) {
    return CalendarEvent(
      id: id,
      title: title,
      startTime: start,
      endTime: end,
      allDay: allDay,
      repeatRule: repeatRule,
      taskId: taskId,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    );
  }

  setUp(() {
    database = AppDatabase.memory();
    clock = FixedClock(DateTime(2026, 10, 19, 8));
    events = DriftCalendarRepository(database, clock: clock);
    tasks = DriftTaskRepository(database);
    countdowns = DriftCountdownRepository(database, clock: clock);
    digests = DriftDailyDigestRepository(database);
    preferences = DriftPlanningPreferencesRepository(database, clock: clock);
  });

  tearDown(() => database.close());

  test('工作日默认窗口会扣除固定日程、午休和重复日程', () async {
    await events.upsertAll(<CalendarEvent>[
      event(
        id: 'fixed',
        title: '固定会议',
        start: DateTime(2026, 10, 19, 10),
        end: DateTime(2026, 10, 19, 11),
      ),
      event(
        id: 'repeat',
        title: '每日站会',
        start: DateTime(2026, 10, 17, 14),
        end: DateTime(2026, 10, 17, 15),
        repeatRule: 'daily',
      ),
      event(
        id: 'all-day',
        title: '全天活动',
        start: DateTime(2026, 10, 19),
        end: DateTime(2026, 10, 20),
        allDay: true,
      ),
    ]);

    final context = await builder().build(
      PlanningRequest(day: DateTime(2026, 10, 19)),
    );

    expect(context.availableWindows, hasLength(4));
    expect(
      context.availableWindows.map((PlanningInterval i) => i.minutes).toList(),
      <int>[60, 60, 30, 180],
    );
    expect(context.capacityMinutes, 330);
    expect(context.fixedOccurrences, hasLength(2));
    expect(context.allDayOccurrences, hasLength(1));
    expect(context.prompt, contains('固定会议'));
  });

  test('周末没有明确窗口时不虚构可用时间', () async {
    final context = await builder().build(
      PlanningRequest(day: DateTime(2026, 10, 24)),
    );

    expect(context.availableWindows, isEmpty);
    expect(context.capacityMinutes, 0);
    expect(context.prompt, contains('不得虚构具体时间'));
  });

  test('用户明确窗口优先于默认工作时段', () async {
    final context = await builder().build(
      PlanningRequest(
        day: DateTime(2026, 10, 24),
        availableWindows: <PlanningWindow>[
          PlanningWindow(
            start: DateTime(2026, 10, 24, 10),
            end: DateTime(2026, 10, 24, 12),
          ),
        ],
        blockedWindows: <PlanningWindow>[
          PlanningWindow(
            start: DateTime(2026, 10, 24, 11),
            end: DateTime(2026, 10, 24, 11, 30),
          ),
        ],
      ),
    );

    expect(context.capacityMinutes, 90);
    expect(context.availableWindows, hasLength(2));
  });

  test('已有日程的任务会标记，已逾期任务仍在上下文中', () async {
    await database.into(database.tasks).insert(
          TasksCompanion.insert(
            id: 'scheduled-task',
            title: '已排任务',
            dueAt: Value<DateTime?>(DateTime(2026, 10, 20)),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    await events.upsert(
      event(
        id: 'task-event',
        title: '已排任务',
        start: DateTime(2026, 10, 19, 9),
        end: DateTime(2026, 10, 19, 10),
        taskId: 'scheduled-task',
      ),
    );
    await tasks.upsert(
      TaskItem(
        id: 'overdue',
        title: '逾期任务',
        priority: TaskPriority.urgent,
        status: TaskStatus.open,
        source: TaskSource.manual,
        dueAt: DateTime(2026, 10, 18, 18),
        postponeCount: 0,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );

    final context = await builder().build(
      PlanningRequest(day: DateTime(2026, 10, 19)),
    );

    expect(context.scheduledTaskIds, contains('scheduled-task'));
    expect(
      context.candidateTasks.map((TaskItem task) => task.id),
      contains('overdue'),
    );
    expect(
      context.candidateTasks.map((TaskItem task) => task.id),
      isNot(contains('scheduled-task')),
    );
  });

  test('倒计时、昨日复盘与上下文长度上限生效', () async {
    await countdowns.upsert(
      CountdownItem(
        id: 'cd',
        title: '项目截止',
        targetTime: DateTime(2026, 10, 21, 18),
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );
    await digests.upsert(
      DailyDigest(
        id: 'yesterday',
        kind: DailyDigestKind.evening,
        dayKey: '2026-10-18',
        content: '昨天完成了资料整理',
        createdAt: clock.now(),
      ),
    );

    final context = await builder(maxChars: 120).build(
      PlanningRequest(day: DateTime(2026, 10, 19)),
    );

    expect(context.countdowns.single.title, '项目截止');
    expect(context.priorReview, contains('资料整理'));
    expect(context.prompt.length, lessThanOrEqualTo(120 + 20));
    expect(context.prompt, contains('已截断'));
  });
}
