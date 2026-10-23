import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/drift_daily_plan_repository.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/infrastructure/database/app_database.dart';

import '../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late DriftDailyPlanRepository repository;
  final FixedClock clock = FixedClock(DateTime(2026, 10, 19, 8));

  DailyPlan draft({String id = 'plan-1', String summary = '计划'}) => DailyPlan(
        id: id,
        dayKey: '2026-10-19',
        revision: 0,
        status: PlanStatus.draft,
        summary: summary,
        goals: const <PlanGoal>[
          PlanGoal(title: '完成主要任务', priority: TaskPriority.high),
        ],
        constraints: const PlanningConstraints(goalText: '完成主要任务'),
        generationSource: PlanGenerationSource.manual,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  DailyPlanItem item(String id, String planId, String taskId) => DailyPlanItem(
        id: id,
        planId: planId,
        taskId: taskId,
        titleSnapshot: '任务 $taskId',
        startAt: DateTime(2026, 10, 19, 9),
        endAt: DateTime(2026, 10, 19, 10),
        estimateMinutes: 60,
        priority: TaskPriority.normal,
        reason: '优先完成',
        source: PlanItemSource.existingTask,
        status: PlanItemStatus.proposed,
        sortOrder: 0,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftDailyPlanRepository(database, clock: clock);
  });

  tearDown(() => database.close());

  test('首次保存草稿为 revision 1，并写入条目', () async {
    await database.into(database.tasks).insert(
          TasksCompanion.insert(
            id: 'task-1',
            title: '任务',
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    final saved = await repository.saveDraft(
      draft(),
      <DailyPlanItem>[item('item-1', 'plan-1', 'task-1')],
    );

    expect(saved.revision, 1);
    expect(saved.status, PlanStatus.draft);
    final items = await repository.itemsForPlan('plan-1');
    expect(items, hasLength(1));
    expect(items.single.taskId, 'task-1');
    expect((await repository.findLatestDraft('2026-10-19'))!.id, 'plan-1');
  });

  test('新草稿只废弃旧草稿，不改变确认计划', () async {
    final first = await repository.saveDraft(draft(id: 'plan-confirmed'), []);
    await (database.update(database.dailyPlans)
          ..where(($DailyPlansTable t) => t.id.equals(first.id)))
        .write(
      const DailyPlansCompanion(
        status: Value<String>('confirmed'),
      ),
    );

    final draftTwo = await repository.saveDraft(
      draft(id: 'plan-draft'),
      <DailyPlanItem>[],
    );
    final draftThree = await repository.saveDraft(
      draft(id: 'plan-draft-2'),
      <DailyPlanItem>[],
    );

    expect(draftTwo.revision, 2);
    expect(draftThree.revision, 3);
    final versions = await repository.findVersions('2026-10-19');
    expect(
      versions.map((DailyPlan plan) => plan.status).toList(),
      <PlanStatus>[
        PlanStatus.draft,
        PlanStatus.superseded,
        PlanStatus.confirmed,
      ],
    );
    expect((await repository.findCurrent('2026-10-19'))!.id, 'plan-confirmed');
  });

  test('并发保存草稿会产生连续 revision，且只有一个开放草稿', () async {
    final saved = await Future.wait(<Future<DailyPlan>>[
      repository.saveDraft(draft(id: 'plan-a'), []),
      repository.saveDraft(draft(id: 'plan-b'), []),
    ]);

    expect(saved.map((DailyPlan plan) => plan.revision).toSet(), <int>{1, 2});
    final versions = await repository.findVersions('2026-10-19');
    expect(
      versions.where((DailyPlan plan) => plan.status == PlanStatus.draft),
      hasLength(1),
    );
    expect(
      versions.where((DailyPlan plan) => plan.status == PlanStatus.superseded),
      hasLength(1),
    );
  });
}
