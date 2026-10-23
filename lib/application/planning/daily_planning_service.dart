import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/errors/planning_exception.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/weather.dart';
import '../../domain/services/ai_provider.dart';
import '../../infrastructure/clock_provider.dart';
import '../../infrastructure/storage/app_settings_store.dart';
import '../ai/ai_providers.dart';
import '../ai/chat_controller.dart';
import 'plan_validation_service.dart';
import 'planning_context.dart';
import 'planning_result_parser.dart';

class GeneratedPlanDraft {
  const GeneratedPlanDraft({
    required this.plan,
    required this.items,
    required this.unscheduledTaskIds,
    required this.conflicts,
    required this.notes,
  });

  final DailyPlan plan;
  final List<DailyPlanItem> items;
  final List<String> unscheduledTaskIds;
  final List<String> conflicts;
  final List<String> notes;
}

class DailyPlanningService {
  DailyPlanningService(
    this._ref, {
    PlanningContextBuilder? contextBuilder,
    PlanningResultParser parser = const PlanningResultParser(),
    PlanValidationService validator = const PlanValidationService(),
  })  : _contextBuilder = contextBuilder,
        _parser = parser,
        _validator = validator;

  final Ref _ref;
  final PlanningContextBuilder? _contextBuilder;
  final PlanningResultParser _parser;
  final PlanValidationService _validator;

  Clock get _clock => _ref.read(clockProvider);

  PlanningContextBuilder get _builder =>
      _contextBuilder ?? _ref.read(planningContextBuilderProvider);

  Future<GeneratedPlanDraft> generateDraft(
    PlanningRequest request, {
    AiCancellationToken? cancelToken,
    PlanGenerationSource generationSource = PlanGenerationSource.manual,
  }) async {
    if (cancelToken?.isCancelled ?? false) {
      throw const PlanningException(PlanningErrorCode.cancelled);
    }
    await _ref.read(aiProvidersProvider.future);
    final config = _ref.read(activeAiConfigProvider);
    if (config == null) {
      throw const PlanningException(PlanningErrorCode.noProvider);
    }
    final effectiveRequest = request.weatherSummary == null
        ? request.copyWith(weatherSummary: _cachedWeatherSummary())
        : request;
    final context = await _builder.build(effectiveRequest);
    if (cancelToken?.isCancelled ?? false) {
      throw const PlanningException(PlanningErrorCode.cancelled);
    }

    final provider = _ref.read(aiProviderBuilderProvider)(config);
    final AiResponse response;
    try {
      response = await provider.chat(
        AiChatRequest(
          messages: <AiMessage>[
            AiMessage.system(_systemPrompt),
            AiMessage.user('${context.prompt}\n\n${_instruction(context)}'),
          ],
          temperature: 0.2,
          maxTokens: 2000,
          cancelToken: cancelToken,
        ),
      );
    } on Object catch (error) {
      throw _mapRequestError(error, cancelToken);
    }
    if (cancelToken?.isCancelled ?? false) {
      throw const PlanningException(PlanningErrorCode.cancelled);
    }
    if (response.content.trim().isEmpty) {
      throw const PlanningException(PlanningErrorCode.parseFailed);
    }

    final parsed = _parser.parse(response.content, context);
    final validated = _validator.validate(parsed, context);
    if (cancelToken?.isCancelled ?? false) {
      throw const PlanningException(PlanningErrorCode.cancelled);
    }

    final now = _clock.now();
    final planId = generateId('plan', now: now);
    final items = <DailyPlanItem>[
      for (var index = 0; index < validated.items.length; index++)
        DailyPlanItem(
          id: generateId('planitem',
              now: now.add(Duration(microseconds: index))),
          planId: planId,
          taskId: validated.items[index].taskId,
          titleSnapshot: validated.items[index].title,
          descriptionSnapshot: validated.items[index].description,
          startAt: validated.items[index].startAt,
          endAt: validated.items[index].endAt,
          estimateMinutes: validated.items[index].estimatedMinutes,
          priority: validated.items[index].priority,
          reason: validated.items[index].reason,
          source: validated.items[index].source,
          sourceEventId: validated.items[index].sourceEventId,
          status: PlanItemStatus.proposed,
          sortOrder: index,
          createdAt: now,
          updatedAt: now,
        ),
    ];
    final metadata = PlanGenerationMetadata(
      diagnostics: validated.diagnostics,
      unscheduledTaskIds: validated.unscheduledTaskIds,
      conflicts: validated.conflicts,
      notes: validated.notes,
    );
    final draft = DailyPlan(
      id: planId,
      dayKey: context.dayKey,
      revision: 0,
      status: PlanStatus.draft,
      summary: validated.summary,
      goals: validated.goals,
      constraints: effectiveRequest.toConstraints(),
      generationSource: generationSource,
      generationDiagnosticsJson: metadata.toJsonString(),
      createdAt: now,
      updatedAt: now,
    );
    final saved = await _ref.read(dailyPlanRepositoryProvider).saveDraft(
          draft,
          items,
        );
    return GeneratedPlanDraft(
      plan: saved,
      items: items
          .map((DailyPlanItem item) => item.copyWith(planId: saved.id))
          .toList(growable: false),
      unscheduledTaskIds: metadata.unscheduledTaskIds,
      conflicts: metadata.conflicts,
      notes: metadata.notes,
    );
  }

  static PlanningException _mapRequestError(
    Object error,
    AiCancellationToken? token,
  ) {
    if (token?.isCancelled ?? false) {
      return const PlanningException(PlanningErrorCode.cancelled);
    }
    final message = '$error';
    if (message.contains('取消')) {
      return PlanningException(
        PlanningErrorCode.cancelled,
        cause: error,
      );
    }
    if (message.contains('429') || message.contains('限流')) {
      return PlanningException(
        PlanningErrorCode.rateLimited,
        cause: error,
      );
    }
    if (message.contains('超时')) {
      return PlanningException(
        PlanningErrorCode.timeout,
        cause: error,
      );
    }
    return PlanningException(
      PlanningErrorCode.network,
      message: message,
      cause: error,
    );
  }

  String? _cachedWeatherSummary() {
    final raw = _ref.read(appSettingsStoreProvider).readWeatherCache();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, Object?>();
      final rawSnapshot = map['snapshot'] is Map
          ? (map['snapshot'] as Map).cast<String, Object?>()
          : map;
      final snapshot = WeatherSnapshot.fromJson(rawSnapshot);
      if (snapshot == null ||
          !snapshot.isFresh(_clock.now(), ttl: const Duration(minutes: 30))) {
        return null;
      }
      return '${snapshot.city} ${snapshot.condition.name} '
          '${snapshot.temperature.round()}°C';
    } on FormatException {
      return null;
    }
  }

  static const String _systemPrompt = '''
你是用户的每日计划助手。你只能提出计划建议，不能声称已经创建任务或日程。
必须只返回一个 JSON 对象，不要输出 Markdown、代码围栏或额外解释。

JSON 结构：
{
  "dayKey": "yyyy-MM-dd",
  "summary": "一句话计划摘要",
  "goals": [{"title": "目标", "priority": "low|normal|high|urgent"}],
  "items": [{
    "taskId": "已有任务 id，或 null",
    "title": "任务标题",
    "description": "可选",
    "startTime": "ISO-8601，可空",
    "endTime": "ISO-8601，可空",
    "estimatedMinutes": 30,
    "priority": "low|normal|high|urgent",
    "reason": "安排理由",
    "source": "existing_task|new_task|event_split"
  }],
  "unscheduledTaskIds": ["已有任务 id"],
  "conflicts": ["需要用户注意的风险"],
  "notes": ["其他建议"]
}

规则：
- 只能使用上下文中出现过的 taskId；新任务使用 source=new_task 且 taskId=null。
- 不得修改固定日程，不得占用固定日程时间。
- 时间必须落在可用窗口内；没有可用窗口时，不要虚构具体时间，放入待安排。
- 不得安排已完成、已归档或已经有正式日程的任务。
- 不得越过截止时间；无法满足时放入待安排并写明风险。
- 同一时间段不能安排多个任务，优先处理紧急事项和临近截止事项。
- 计划语言与用户界面语言一致。''';

  static String _instruction(PlanningContext context) => '''
请基于以上上下文生成 ${context.dayKey} 的计划草稿。
只生成建议，不写数据库。必须返回合法 JSON，dayKey 必须等于 ${context.dayKey}。
''';
}

final planningContextBuilderProvider = Provider<PlanningContextBuilder>(
  (ref) => PlanningContextBuilder(
    events: ref.watch(calendarRepositoryProvider),
    tasks: ref.watch(taskRepositoryProvider),
    countdowns: ref.watch(countdownRepositoryProvider),
    digests: ref.watch(dailyDigestRepositoryProvider),
    preferences: ref.watch(planningPreferencesRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final dailyPlanningServiceProvider = Provider<DailyPlanningService>(
  (ref) => DailyPlanningService(ref),
);
