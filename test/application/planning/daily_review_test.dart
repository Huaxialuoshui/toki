import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/planning/daily_review_service.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../../helpers/sqlite_bootstrap.dart';

class _SwitchableAiProvider implements AiProvider {
  String content = '{"summary":"完成了主要任务","differences":["报告还没收尾"],'
      '"suggestions":["明天先完成报告"]}';
  Object? error;

  @override
  Future<AiResponse> chat(AiChatRequest request) async {
    if (error != null) throw error!;
    return AiResponse(content: content);
  }

  @override
  Stream<AiResponseChunk> chatStream(AiChatRequest request) =>
      const Stream<AiResponseChunk>.empty();

  @override
  Future<List<String>> listModels() async => const <String>[];
}

void main() {
  setUpAll(ensureSqliteLibraryAvailable);

  late AppDatabase database;
  late ProviderContainer container;
  late FixedClock clock;
  late _SwitchableAiProvider ai;

  AiProviderConfig config() => AiProviderConfig(
        id: 'p1',
        name: '测试',
        baseUrl: 'http://127.0.0.1:9/v1',
        model: 'test',
        isDefault: true,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  Future<void> setUpContainer({bool withConfig = true}) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    clock = FixedClock(DateTime(2026, 10, 19, 19));
    ai = _SwitchableAiProvider();
    container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(clock),
        appDatabaseProvider.overrideWithValue(database),
        aiProviderBuilderProvider.overrideWithValue((_) => ai),
        aiProvidersProvider.overrideWith(
          (Ref ref) => Stream<List<AiProviderConfig>>.value(
            withConfig
                ? <AiProviderConfig>[config()]
                : const <AiProviderConfig>[],
          ),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });
    await container.read(aiProvidersProvider.future);
  }

  Future<void> seedPlan() async {
    final tasks = container.read(taskRepositoryProvider);
    await tasks.upsertAll(<TaskItem>[
      TaskItem(
        id: 'done',
        title: '完成任务',
        priority: TaskPriority.normal,
        status: TaskStatus.completed,
        source: TaskSource.manual,
        actualMinutes: 40,
        postponeCount: 0,
        completedAt: clock.now(),
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
      TaskItem(
        id: 'open',
        title: '未完成任务',
        priority: TaskPriority.high,
        status: TaskStatus.open,
        source: TaskSource.manual,
        postponeCount: 0,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    ]);
    final plans = container.read(dailyPlanRepositoryProvider);
    await plans.saveDraft(
      DailyPlan(
        id: 'plan-1',
        dayKey: '2026-10-19',
        revision: 0,
        status: PlanStatus.draft,
        summary: '计划',
        goals: const <PlanGoal>[],
        constraints: const PlanningConstraints(),
        generationSource: PlanGenerationSource.manual,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
      <DailyPlanItem>[
        DailyPlanItem(
          id: 'i1',
          planId: 'plan-1',
          taskId: 'done',
          titleSnapshot: '完成任务',
          priority: TaskPriority.normal,
          reason: '',
          source: PlanItemSource.existingTask,
          status: PlanItemStatus.applied,
          sortOrder: 0,
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
        DailyPlanItem(
          id: 'i2',
          planId: 'plan-1',
          taskId: 'open',
          titleSnapshot: '未完成任务',
          priority: TaskPriority.high,
          reason: '',
          source: PlanItemSource.existingTask,
          status: PlanItemStatus.applied,
          sortOrder: 1,
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      ],
    );
    await (database.update(database.dailyPlans)
          ..where(($DailyPlansTable t) => t.id.equals('plan-1')))
        .write(const DailyPlansCompanion(status: Value<String>('confirmed')));
    await container.read(calendarRepositoryProvider).upsert(
          CalendarEvent(
            id: 'unknown-event',
            title: '无任务记录的日程',
            startTime: DateTime(2026, 10, 19, 15),
            endTime: DateTime(2026, 10, 19, 16),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
  }

  test('复盘指标来自本地任务，未知日程不计为完成', () async {
    await setUpContainer();
    await seedPlan();
    final metrics =
        await container.read(dailyReviewServiceProvider).buildMetrics();

    expect(metrics.totalTasks, 2);
    expect(metrics.completedTaskIds, <String>['done']);
    expect(metrics.openTaskIds, <String>['open']);
    expect(metrics.actualMinutes, 40);
    expect(metrics.unknownEventCount, 1);
    expect(metrics.completionRate, 0.5);
  });

  test('生成复盘写入本地指标，编辑后标记 userEdited', () async {
    await setUpContainer();
    await seedPlan();
    final service = container.read(dailyReviewServiceProvider);
    final result = await service.generate();
    expect(result.usedAi, isTrue);
    expect(result.digest.content, contains('完成了主要任务'));
    expect(
      DailyReviewMetrics.fromJsonString(result.digest.metricsJson)!
          .unknownEventCount,
      1,
    );

    final edited = await service.saveEdited(
      digest: result.digest,
      content: '手动修改后的复盘',
      feedback: '今天有点累',
    );
    expect(edited.userEdited, isTrue);
    expect(edited.feedback, '今天有点累');
    expect((await service.today())!.content, '手动修改后的复盘');
  });

  test('AI 失败时不会覆盖已有复盘', () async {
    await setUpContainer();
    await seedPlan();
    final service = container.read(dailyReviewServiceProvider);
    final first = await service.generate();
    ai.error = StateError('network down');

    await expectLater(service.generate(), throwsA(anything));
    expect((await service.today())!.content, first.digest.content);
  });

  test('没有 Provider 时本地指标仍可读取', () async {
    await setUpContainer(withConfig: false);
    await seedPlan();
    final metrics =
        await container.read(dailyReviewServiceProvider).buildMetrics();
    expect(metrics.totalTasks, 2);
  });
}
