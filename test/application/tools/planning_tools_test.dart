import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/tool_permissions.dart';
import 'package:toki/application/ai/tools/ai_tool.dart';
import 'package:toki/application/ai/tools/tool_registry.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../../helpers/sqlite_bootstrap.dart';

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late ProviderContainer container;
  late AiToolRegistry registry;
  late FixedClock clock;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    clock = FixedClock(DateTime(2026, 10, 19, 8));
    container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(clock),
        appDatabaseProvider.overrideWithValue(database),
      ],
    );
    registry = container.read(aiToolRegistryProvider);
    addTearDown(() async {
      container.dispose();
      await database.close();
    });
  });

  test('生产工具集为 25 个，并包含全部计划 / 任务 / 复盘工具', () {
    final names = registry.all.map((AiTool tool) => tool.name).toSet();
    expect(names, hasLength(25));
    expect(
      names,
      containsAll(<String>[
        'get_today_plan',
        'get_tasks',
        'create_task',
        'update_task',
        'set_task_status',
        'postpone_task',
        'generate_plan_draft',
        'get_plan_quality',
        'apply_daily_plan',
        'get_daily_review',
      ]),
    );
  });

  test('apply_daily_plan 同时要求 create + update 权限', () {
    const both = ToolPermissions();
    expect(
      registry.allowedTools(permissions: both).map((AiTool tool) => tool.name),
      contains('apply_daily_plan'),
    );
    expect(
      registry
          .allowedTools(
            permissions: const ToolPermissions(allowCreate: false),
          )
          .map((AiTool tool) => tool.name),
      isNot(contains('apply_daily_plan')),
    );
    expect(
      registry
          .allowedTools(
            permissions: const ToolPermissions(allowUpdate: false),
          )
          .map((AiTool tool) => tool.name),
      isNot(contains('apply_daily_plan')),
    );
  });

  test('create_task / set_task_status 执行真实仓储操作并返回 JSON', () async {
    final create = registry.byName('create_task')!;
    final created = await create.execute(<String, Object?>{
      'title': '写报告',
      'priority': 'high',
      'estimated_minutes': 45,
    });
    expect(created.isError, isFalse);
    final task = (await container.read(taskRepositoryProvider).getAll()).single;
    expect(task.title, '写报告');
    expect(task.priority, TaskPriority.high);

    final status = registry.byName('set_task_status')!;
    expect(status.requiresConfirmation, isTrue);
    final completed = await status.execute(<String, Object?>{
      'task_id': task.id,
      'status': 'completed',
      'actual_minutes': 40,
    });
    expect(completed.isError, isFalse);
    final saved =
        (await container.read(taskRepositoryProvider).findById(task.id))!;
    expect(saved.status, TaskStatus.completed);
    expect(saved.actualMinutes, 40);
  });

  test('update_task 确认预览包含任务与目标状态', () async {
    final create = registry.byName('create_task')!;
    await create.execute(<String, Object?>{'title': '复习'});
    final task = (await container.read(taskRepositoryProvider).getAll()).single;

    final update = registry.byName('update_task')!;
    expect(update.requiresConfirmation, isTrue);
    final preview = await update.preview(<String, Object?>{
      'task_id': task.id,
      'title': '复习第二章',
    });
    expect(preview, isNotNull);
    expect(preview!.lines.join(' '), contains('复习第二章'));
  });

  test('get_today_plan 与 apply_daily_plan 预览读取真实计划', () async {
    final plans = container.read(dailyPlanRepositoryProvider);
    await plans.saveDraft(
      DailyPlan(
        id: 'plan-1',
        dayKey: '2026-10-19',
        revision: 0,
        status: PlanStatus.draft,
        summary: '今日计划',
        goals: const <PlanGoal>[],
        constraints: const PlanningConstraints(),
        generationSource: PlanGenerationSource.manual,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
      <DailyPlanItem>[
        DailyPlanItem(
          id: 'item-1',
          planId: 'plan-1',
          titleSnapshot: '整理资料',
          priority: TaskPriority.normal,
          reason: '先做',
          source: PlanItemSource.newTask,
          status: PlanItemStatus.proposed,
          sortOrder: 0,
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      ],
    );
    final today = await registry.byName('get_today_plan')!.execute(
      const <String, Object?>{},
    );
    expect(today.isError, isFalse);
    expect('${today.payload}', contains('今日计划'));

    final apply = registry.byName('apply_daily_plan')!;
    expect(apply.requiresConfirmation, isTrue);
    final preview = await apply.preview(<String, Object?>{
      'plan_id': 'plan-1',
    });
    expect(preview, isNotNull);
    expect(preview!.lines.join(' '), contains('整理资料'));
  });
}
