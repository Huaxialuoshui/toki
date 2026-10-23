import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/calendar/calendar_actions.dart';
import 'package:toki/application/planning/plan_actions.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/core/errors/planning_exception.dart';
import 'package:toki/data/repositories/drift_calendar_repository.dart';
import 'package:toki/data/repositories/drift_reminder_repository.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../../helpers/sqlite_bootstrap.dart';

class _FailingCalendarActions extends CalendarActions {
  _FailingCalendarActions({
    required super.events,
    required super.reminders,
    required super.clock,
  });

  int calls = 0;

  @override
  Future<void> saveEvent(CalendarEvent event) async {
    calls++;
    if (calls >= 2) throw StateError('simulated event failure');
    await super.saveEvent(event);
  }
}

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late ProviderContainer container;
  late FixedClock clock;

  DailyPlan draft(String id) => DailyPlan(
        id: id,
        dayKey: '2026-10-19',
        revision: 0,
        status: PlanStatus.draft,
        summary: '计划',
        goals: const <PlanGoal>[],
        constraints: const PlanningConstraints(),
        generationSource: PlanGenerationSource.manual,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  DailyPlanItem item({
    required String id,
    String? taskId,
    PlanItemSource source = PlanItemSource.existingTask,
    DateTime? start,
    DateTime? end,
  }) {
    return DailyPlanItem(
      id: id,
      planId: 'plan-1',
      taskId: taskId,
      titleSnapshot: taskId == null ? '新任务' : '任务 $taskId',
      startAt: start,
      endAt: end,
      estimateMinutes: start == null ? null : 60,
      priority: TaskPriority.normal,
      reason: '理由',
      source: source,
      status: PlanItemStatus.proposed,
      sortOrder: 0,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    );
  }

  Future<void> setUpContainer({bool failingCalendar = false}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    clock = FixedClock(DateTime(2026, 10, 19, 8));
    final calendarActions = failingCalendar
        ? _FailingCalendarActions(
            events: DriftCalendarRepository(database, clock: clock),
            reminders: DriftReminderRepository(database),
            clock: clock,
          )
        : null;
    container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(clock),
        appDatabaseProvider.overrideWithValue(database),
        if (calendarActions != null)
          calendarActionsProvider.overrideWithValue(calendarActions),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });
  }

  Future<void> seedTask(String id, {String? title}) async {
    await container.read(taskRepositoryProvider).upsert(
          TaskItem(
            id: id,
            title: title ?? '任务 $id',
            priority: TaskPriority.normal,
            status: TaskStatus.open,
            source: TaskSource.manual,
            postponeCount: 0,
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
  }

  test('选择性应用创建任务 / 日程，重复应用不重复写入', () async {
    await setUpContainer();
    await seedTask('task-1', title: '已有任务');
    final repository = container.read(dailyPlanRepositoryProvider);
    await repository.saveDraft(
      draft('plan-1'),
      <DailyPlanItem>[
        item(
          id: 'item-1',
          taskId: 'task-1',
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
        item(
          id: 'item-2',
          source: PlanItemSource.newTask,
        ),
      ],
    );

    final actions = container.read(planActionsProvider);
    final preview = await actions.previewApply(
      planId: 'plan-1',
      itemIds: const <String>{'item-1', 'item-2'},
    );
    expect(preview.eligibleItemIds, hasLength(2));
    expect(preview.canApply, isTrue);

    final result = await actions.apply(
      planId: 'plan-1',
      itemIds: const <String>{'item-1', 'item-2'},
    );
    expect(result.appliedItemIds, hasLength(2));
    expect(result.createdTaskCount, 1);
    expect(result.createdEventCount, 1);

    final tasks = await container.read(taskRepositoryProvider).getAll();
    expect(tasks, hasLength(2));
    expect(
      await container.read(taskRepositoryProvider).findById(
            'task-from-plan-item-item-2',
          ),
      isNotNull,
    );
    final events = await container.read(calendarRepositoryProvider).getAll();
    expect(events, hasLength(1));
    expect(events.single.taskId, 'task-1');

    final saved = (await repository.findById('plan-1'))!;
    expect(saved.status, PlanStatus.confirmed);
    final items = await repository.itemsForPlan('plan-1');
    expect(
      items.every((DailyPlanItem i) => i.status == PlanItemStatus.applied),
      isTrue,
    );

    final repeated = await actions.apply(
      planId: 'plan-1',
      itemIds: const <String>{'item-1', 'item-2'},
    );
    expect(repeated.createdEventCount, 0);
    expect(repeated.createdTaskCount, 0);
    expect(repeated.skippedItemIds, hasLength(2));
    expect(
      await container.read(calendarRepositoryProvider).getAll(),
      hasLength(1),
    );

    await actions.cancelPlan('plan-1');
    expect((await repository.findById('plan-1'))!.status, PlanStatus.cancelled);
    expect(
      await container.read(calendarRepositoryProvider).getAll(),
      hasLength(1),
      reason: '取消计划不能删除已经创建的日程',
    );
  });

  test('旧 revision 被新草稿取代后阻止应用', () async {
    await setUpContainer();
    final repository = container.read(dailyPlanRepositoryProvider);
    await repository.saveDraft(draft('plan-old'), <DailyPlanItem>[]);
    await repository.saveDraft(draft('plan-new'), <DailyPlanItem>[]);

    await expectLater(
      container.read(planActionsProvider).previewApply(
        planId: 'plan-old',
        itemIds: const <String>{},
      ),
      throwsA(
        isA<PlanningException>().having(
          (PlanningException e) => e.code,
          'code',
          PlanningErrorCode.planStale,
        ),
      ),
    );
  });

  test('生成后新增日历冲突时条目跳过且不写库', () async {
    await setUpContainer();
    await seedTask('task-1');
    final repository = container.read(dailyPlanRepositoryProvider);
    await repository.saveDraft(
      draft('plan-1'),
      <DailyPlanItem>[
        item(
          id: 'item-1',
          taskId: 'task-1',
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
      ],
    );
    await container.read(calendarRepositoryProvider).upsert(
          CalendarEvent(
            id: 'new-conflict',
            title: '临时会议',
            startTime: DateTime(2026, 10, 19, 9, 30),
            endTime: DateTime(2026, 10, 19, 10, 30),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );

    final actions = container.read(planActionsProvider);
    final preview = await actions.previewApply(
      planId: 'plan-1',
      itemIds: const <String>{'item-1'},
    );
    expect(preview.eligibleItemIds, isEmpty);
    expect(preview.skippedReasons['item-1'], 'conflict');

    final result = await actions.apply(
      planId: 'plan-1',
      itemIds: const <String>{'item-1'},
    );
    expect(result.appliedItemIds, isEmpty);
    expect(
      await container.read(taskRepositoryProvider).count(),
      1,
      reason: '只应包含预置任务',
    );
    expect(
      await container.read(calendarRepositoryProvider).getAll(),
      hasLength(1),
    );
  });

  test('事务中途失败时任务、日程和计划状态全部回滚', () async {
    await setUpContainer(failingCalendar: true);
    final repository = container.read(dailyPlanRepositoryProvider);
    await repository.saveDraft(
      draft('plan-1'),
      <DailyPlanItem>[
        item(
          id: 'item-1',
          source: PlanItemSource.newTask,
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
        item(
          id: 'item-2',
          source: PlanItemSource.newTask,
          start: DateTime(2026, 10, 19, 11),
          end: DateTime(2026, 10, 19, 12),
        ),
      ],
    );

    await expectLater(
      container.read(planActionsProvider).apply(
        planId: 'plan-1',
        itemIds: const <String>{'item-1', 'item-2'},
      ),
      throwsA(isA<PlanningException>()),
    );
    expect(await container.read(taskRepositoryProvider).count(), 0);
    expect(
      await container.read(calendarRepositoryProvider).getAll(),
      isEmpty,
    );
    expect((await repository.findById('plan-1'))!.status, PlanStatus.draft);
    expect(
      (await repository.itemsForPlan('plan-1'))
          .every((DailyPlanItem i) => i.status == PlanItemStatus.proposed),
      isTrue,
    );
  });

  test('已应用日程被删除后预览标记 detached', () async {
    await setUpContainer();
    await seedTask('task-1');
    final repository = container.read(dailyPlanRepositoryProvider);
    await repository.saveDraft(
      draft('plan-1'),
      <DailyPlanItem>[
        item(
          id: 'item-1',
          taskId: 'task-1',
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
      ],
    );
    final actions = container.read(planActionsProvider);
    await actions.apply(
      planId: 'plan-1',
      itemIds: const <String>{'item-1'},
    );
    final event =
        (await container.read(calendarRepositoryProvider).getAll()).single;
    await container.read(calendarRepositoryProvider).deleteById(event.id);

    final preview = await actions.previewApply(
      planId: 'plan-1',
      itemIds: const <String>{'item-1'},
    );
    expect(preview.skippedReasons['item-1'], 'detached');
  });

  test('调整草稿时间会重新校验，移出条目只标记 skipped', () async {
    await setUpContainer();
    await seedTask('task-1');
    final repository = container.read(dailyPlanRepositoryProvider);
    await repository.saveDraft(
      draft('plan-1'),
      <DailyPlanItem>[
        item(
          id: 'item-1',
          taskId: 'task-1',
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
        item(
          id: 'item-2',
          taskId: 'task-1',
          start: DateTime(2026, 10, 19, 11),
          end: DateTime(2026, 10, 19, 12),
        ),
      ],
    );
    final actions = container.read(planActionsProvider);
    await actions.updateDraftItemTime(
      planId: 'plan-1',
      itemId: 'item-1',
      start: DateTime(2026, 10, 19, 11),
      end: DateTime(2026, 10, 19, 12),
    );
    final adjusted = (await repository.itemsForPlan('plan-1'))
        .firstWhere((DailyPlanItem item) => item.id == 'item-1');
    expect(adjusted.startAt, DateTime(2026, 10, 19, 11));

    await actions.skipItem('plan-1', 'item-2');
    final skipped = (await repository.itemsForPlan('plan-1'))
        .firstWhere((DailyPlanItem item) => item.id == 'item-2');
    expect(skipped.status, PlanItemStatus.skipped);
    expect(
      await container.read(taskRepositoryProvider).count(),
      1,
      reason: '移出计划不能删除任务',
    );
  });

  test('应用新计划后旧确认计划才标记 superseded', () async {
    await setUpContainer();
    final repository = container.read(dailyPlanRepositoryProvider);
    await repository.saveDraft(
      draft('plan-a'),
      <DailyPlanItem>[
        item(
          id: 'item-a',
          source: PlanItemSource.newTask,
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
      ],
    );
    final actions = container.read(planActionsProvider);
    await actions.apply(
      planId: 'plan-a',
      itemIds: const <String>{'item-a'},
    );
    expect((await repository.findById('plan-a'))!.status, PlanStatus.confirmed);

    await repository.saveDraft(
      draft('plan-b'),
      <DailyPlanItem>[
        item(
          id: 'item-b',
          source: PlanItemSource.newTask,
          start: DateTime(2026, 10, 19, 11),
          end: DateTime(2026, 10, 19, 12),
        ),
      ],
    );
    expect((await repository.findById('plan-a'))!.status, PlanStatus.confirmed);

    await actions.apply(
      planId: 'plan-b',
      itemIds: const <String>{'item-b'},
    );
    expect(
      (await repository.findById('plan-a'))!.status,
      PlanStatus.superseded,
    );
    expect((await repository.findById('plan-b'))!.status, PlanStatus.confirmed);
  });
}
