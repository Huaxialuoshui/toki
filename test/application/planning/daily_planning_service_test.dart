import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toki/application/ai/ai_providers.dart';
import 'package:toki/application/planning/daily_planning_service.dart';
import 'package:toki/application/planning/planning_context.dart';
import 'package:toki/core/clock.dart';
import 'package:toki/core/errors/app_exception.dart';
import 'package:toki/core/errors/planning_exception.dart';
import 'package:toki/data/repositories/repository_providers.dart';
import 'package:toki/domain/entities/ai_provider_config.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/domain/services/ai_provider.dart';
import 'package:toki/infrastructure/clock_provider.dart';
import 'package:toki/infrastructure/database/app_database.dart';
import 'package:toki/infrastructure/storage/app_settings_store.dart';

import '../../helpers/fake_ai_provider.dart';
import '../../helpers/sqlite_bootstrap.dart';

class _CancelAwareProvider implements AiProvider {
  final Completer<void> started = Completer<void>();

  @override
  Future<AiResponse> chat(AiChatRequest request) async {
    if (!started.isCompleted) started.complete();
    final token = request.cancelToken;
    if (token != null) {
      await token.whenCancelled;
      throw const AppException('AI 请求已取消');
    }
    return const AiResponse(content: '{}');
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

  const validJson = '''
{
  "dayKey": "2026-10-19",
  "summary": "先完成报告",
  "goals": [{"title": "完成报告", "priority": "high"}],
  "items": [
    {
      "taskId": "task-1",
      "title": "写报告",
      "startTime": "2026-10-19T09:00:00",
      "endTime": "2026-10-19T10:00:00",
      "priority": "high",
      "reason": "截止临近",
      "source": "existing_task"
    },
    {
      "taskId": null,
      "title": "整理引用",
      "estimatedMinutes": 30,
      "priority": "normal",
      "reason": "报告前置",
      "source": "new_task"
    }
  ],
  "unscheduledTaskIds": [],
  "conflicts": [],
  "notes": []
}
''';

  AiProviderConfig config() => AiProviderConfig(
        id: 'p1',
        name: '测试',
        baseUrl: 'http://127.0.0.1:9/v1',
        model: 'test',
        isDefault: true,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  Future<void> setUpContainer(
    AiProvider provider, {
    bool withConfig = true,
  }) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    database = AppDatabase.memory();
    clock = FixedClock(DateTime(2026, 10, 19, 8));
    container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        clockProvider.overrideWithValue(clock),
        appDatabaseProvider.overrideWithValue(database),
        aiProviderBuilderProvider.overrideWithValue((_) => provider),
        dailyPlanningServiceProvider.overrideWith(
          (Ref ref) => DailyPlanningService(ref),
        ),
        if (withConfig)
          aiProvidersProvider.overrideWith(
            (Ref ref) => Stream<List<AiProviderConfig>>.value(
              <AiProviderConfig>[config()],
            ),
          )
        else
          aiProvidersProvider.overrideWith(
            (Ref ref) => Stream<List<AiProviderConfig>>.value(
              const <AiProviderConfig>[],
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

  Future<void> seedTaskAndEvent() async {
    final taskRepository = container.read(taskRepositoryProvider);
    await taskRepository.upsert(
      TaskItem(
        id: 'task-1',
        title: '写报告',
        priority: TaskPriority.high,
        status: TaskStatus.open,
        source: TaskSource.manual,
        dueAt: DateTime(2026, 10, 19, 18),
        estimatedMinutes: 60,
        postponeCount: 0,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      ),
    );
    await container.read(calendarRepositoryProvider).upsert(
          CalendarEvent(
            id: 'fixed',
            title: '固定会议',
            startTime: DateTime(2026, 10, 19, 10),
            endTime: DateTime(2026, 10, 19, 11),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
  }

  PlanningRequest request() => PlanningRequest(day: DateTime(2026, 10, 19));

  test('生成结构化草稿：新任务不写 tasks，条目保存快照', () async {
    final ai = FakeAiProvider(chunks: <String>[validJson]);
    await setUpContainer(ai);
    await seedTaskAndEvent();

    final generated = await container
        .read(dailyPlanningServiceProvider)
        .generateDraft(request());

    expect(generated.plan.status, PlanStatus.draft);
    expect(generated.plan.revision, 1);
    expect(generated.items, hasLength(2));
    expect(generated.items.first.taskId, 'task-1');
    expect(generated.items.last.taskId, null);
    expect(generated.items.last.source, PlanItemSource.newTask);

    final repository = container.read(dailyPlanRepositoryProvider);
    final items = await repository.itemsForPlan(generated.plan.id);
    expect(items, hasLength(2));
    final taskCount = await container.read(taskRepositoryProvider).count();
    expect(taskCount, 1, reason: '草稿中的新任务不能提前写入 tasks');
  });

  test('新草稿不改变确认计划；解析失败保留旧草稿', () async {
    final ai = FakeAiProvider(chunks: <String>[validJson]);
    await setUpContainer(ai);
    await seedTaskAndEvent();
    final service = container.read(dailyPlanningServiceProvider);
    final repository = container.read(dailyPlanRepositoryProvider);

    final first = await service.generateDraft(request());
    await (database.update(database.dailyPlans)
          ..where(($DailyPlansTable t) => t.id.equals(first.plan.id)))
        .write(
      const DailyPlansCompanion(status: Value<String>('confirmed')),
    );

    ai.chunks
      ..clear()
      ..add('这不是 JSON');
    await expectLater(
      service.generateDraft(request()),
      throwsA(
        isA<PlanningException>().having(
          (PlanningException e) => e.code,
          'code',
          PlanningErrorCode.parseFailed,
        ),
      ),
    );
    expect((await repository.findCurrent('2026-10-19'))!.id, first.plan.id);

    ai.chunks
      ..clear()
      ..add(validJson.replaceFirst('"summary": "先完成报告"', '"summary": "新草稿"'));
    final second = await service.generateDraft(request());
    expect(second.plan.revision, 2);
    expect((await repository.findCurrent('2026-10-19'))!.id, first.plan.id);
    expect(
        (await repository.findLatestDraft('2026-10-19'))!.id, second.plan.id);
  });

  test('未配置 Provider 时返回明确错误且不写计划', () async {
    final ai = FakeAiProvider(chunks: <String>[validJson]);
    await setUpContainer(ai, withConfig: false);

    await expectLater(
      container.read(dailyPlanningServiceProvider).generateDraft(request()),
      throwsA(
        isA<PlanningException>().having(
          (PlanningException e) => e.code,
          'code',
          PlanningErrorCode.noProvider,
        ),
      ),
    );
    expect(
      await container
          .read(dailyPlanRepositoryProvider)
          .findVersions('2026-10-19'),
      isEmpty,
    );
  });

  test('取消请求不会保存草稿', () async {
    final ai = _CancelAwareProvider();
    await setUpContainer(ai);
    final token = AiCancellationToken();
    final future = container
        .read(dailyPlanningServiceProvider)
        .generateDraft(request(), cancelToken: token);
    await ai.started.future;
    token.cancel();

    await expectLater(
      future,
      throwsA(
        isA<PlanningException>().having(
          (PlanningException e) => e.code,
          'code',
          PlanningErrorCode.cancelled,
        ),
      ),
    );
    expect(
      await container
          .read(dailyPlanRepositoryProvider)
          .findVersions('2026-10-19'),
      isEmpty,
    );
  });
}
