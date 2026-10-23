import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/errors/planning_exception.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/daily_digest.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/services/ai_provider.dart';
import '../../domain/services/recurrence.dart';
import '../../infrastructure/clock_provider.dart';
import '../ai/ai_providers.dart';
import '../ai/chat_controller.dart';

@immutable
class DailyReviewMetrics {
  const DailyReviewMetrics({
    required this.dayKey,
    required this.plannedTaskIds,
    required this.completedTaskIds,
    required this.openTaskIds,
    required this.blockedTaskIds,
    required this.cancelledTaskIds,
    required this.postponedCount,
    required this.actualMinutes,
    required this.unknownEventCount,
    this.planId,
  });

  final String dayKey;
  final String? planId;
  final List<String> plannedTaskIds;
  final List<String> completedTaskIds;
  final List<String> openTaskIds;
  final List<String> blockedTaskIds;
  final List<String> cancelledTaskIds;
  final int postponedCount;
  final int actualMinutes;
  final int unknownEventCount;

  int get totalTasks => plannedTaskIds.length;
  double get completionRate =>
      totalTasks == 0 ? 0 : completedTaskIds.length / totalTasks;

  Map<String, Object?> toJson() => <String, Object?>{
        'dayKey': dayKey,
        if (planId != null) 'planId': planId,
        'plannedTaskIds': plannedTaskIds,
        'completedTaskIds': completedTaskIds,
        'openTaskIds': openTaskIds,
        'blockedTaskIds': blockedTaskIds,
        'cancelledTaskIds': cancelledTaskIds,
        'postponedCount': postponedCount,
        'actualMinutes': actualMinutes,
        'unknownEventCount': unknownEventCount,
      };

  String toJsonString() => jsonEncode(toJson());

  static DailyReviewMetrics? fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, Object?>();
      return DailyReviewMetrics(
        dayKey: '${map['dayKey'] ?? ''}',
        planId: map['planId'] is String ? map['planId'] as String : null,
        plannedTaskIds: _strings(map['plannedTaskIds']),
        completedTaskIds: _strings(map['completedTaskIds']),
        openTaskIds: _strings(map['openTaskIds']),
        blockedTaskIds: _strings(map['blockedTaskIds']),
        cancelledTaskIds: _strings(map['cancelledTaskIds']),
        postponedCount: _int(map['postponedCount']),
        actualMinutes: _int(map['actualMinutes']),
        unknownEventCount: _int(map['unknownEventCount']),
      );
    } on FormatException {
      return null;
    }
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().toList(growable: false);
  }

  static int _int(Object? value) =>
      value is int ? value : (value is num ? value.toInt() : 0);
}

@immutable
class DailyReviewResult {
  const DailyReviewResult({
    required this.metrics,
    required this.digest,
    required this.usedAi,
  });

  final DailyReviewMetrics metrics;
  final DailyDigest digest;
  final bool usedAi;
}

class DailyReviewService {
  DailyReviewService(this._ref);

  final Ref _ref;

  Clock get _clock => _ref.read(clockProvider);

  Future<DailyDigest?> today() => findForDay(_clock.now());

  Future<DailyDigest?> findForDay(DateTime day) {
    return _ref
        .read(dailyDigestRepositoryProvider)
        .find(DailyDigest.keyFor(day), DailyDigestKind.evening);
  }

  Future<DailyDigest?> ensureToday() async {
    final existing = await today();
    if (existing != null) return existing;
    final result = await generate();
    return result.digest;
  }

  Future<DailyReviewMetrics> buildMetrics([DateTime? day]) async {
    final now = _clock.now();
    final dayStart = DateTime(
      (day ?? now).year,
      (day ?? now).month,
      (day ?? now).day,
    );
    final dayEnd = DateTime(
      dayStart.year,
      dayStart.month,
      dayStart.day + 1,
    );
    final dayKey = DailyDigest.keyFor(dayStart);
    final plan =
        await _ref.read(dailyPlanRepositoryProvider).findCurrent(dayKey);
    final items = plan == null
        ? const <DailyPlanItem>[]
        : await _ref.read(dailyPlanRepositoryProvider).itemsForPlan(plan.id);
    final allTasks = await _ref.read(taskRepositoryProvider).getAll();
    final tasksById = <String, TaskItem>{
      for (final task in allTasks) task.id: task,
    };

    final planned = <String>[];
    final completed = <String>[];
    final open = <String>[];
    final blocked = <String>[];
    final cancelled = <String>[];
    var postponed = 0;
    var actualMinutes = 0;
    for (final item in items) {
      final taskId = item.taskId;
      if (taskId == null || planned.contains(taskId)) continue;
      planned.add(taskId);
      final task = tasksById[taskId];
      if (task == null) continue;
      if (task.isArchived) continue;
      switch (task.status) {
        case TaskStatus.completed:
          completed.add(taskId);
        case TaskStatus.blocked:
          blocked.add(taskId);
        case TaskStatus.cancelled:
          cancelled.add(taskId);
        case TaskStatus.open:
          open.add(taskId);
      }
      postponed += task.postponeCount;
      actualMinutes += task.actualMinutes ?? 0;
    }

    final events = await _ref.read(calendarRepositoryProvider).getAll();
    var unknownEvents = 0;
    for (final event in events) {
      if (event.isCancelled || event.taskId != null) continue;
      final occurrences = expandOccurrences(event, dayStart, dayEnd);
      if (occurrences.isNotEmpty) unknownEvents++;
    }

    return DailyReviewMetrics(
      dayKey: dayKey,
      planId: plan?.id,
      plannedTaskIds: planned,
      completedTaskIds: completed,
      openTaskIds: open,
      blockedTaskIds: blocked,
      cancelledTaskIds: cancelled,
      postponedCount: postponed,
      actualMinutes: actualMinutes,
      unknownEventCount: unknownEvents,
    );
  }

  Future<DailyReviewResult> generate({
    DateTime? day,
    AiCancellationToken? cancelToken,
  }) async {
    final metrics = await buildMetrics(day);
    if (cancelToken?.isCancelled ?? false) {
      throw const PlanningException(PlanningErrorCode.cancelled);
    }
    await _ref.read(aiProvidersProvider.future);
    final config = _ref.read(activeAiConfigProvider);
    if (config == null) {
      throw const PlanningException(PlanningErrorCode.noProvider);
    }
    final provider = _ref.read(aiProviderBuilderProvider)(config);
    final ai = await provider.chat(
      AiChatRequest(
        messages: <AiMessage>[
          AiMessage.system(_reviewPrompt),
          AiMessage.user(_reviewContext(metrics)),
        ],
        temperature: 0.3,
        maxTokens: 900,
        cancelToken: cancelToken,
      ),
    );
    if (cancelToken?.isCancelled ?? false) {
      throw const PlanningException(PlanningErrorCode.cancelled);
    }
    final parsed = _parseReview(ai.content, metrics);
    final now = _clock.now();
    final existing = await today();
    final digest = DailyDigest(
      id: existing?.id ?? generateId('digest', now: now),
      kind: DailyDigestKind.evening,
      dayKey: metrics.dayKey,
      content: parsed,
      createdAt: existing?.createdAt ?? now,
      planId: metrics.planId,
      feedback: existing?.feedback,
      metricsJson: metrics.toJsonString(),
      updatedAt: now,
      userEdited: false,
    );
    await _ref.read(dailyDigestRepositoryProvider).upsert(digest);
    return DailyReviewResult(metrics: metrics, digest: digest, usedAi: true);
  }

  /// 用户编辑复盘正文和困难反馈。
  Future<DailyDigest> saveEdited({
    required DailyDigest digest,
    required String content,
    String? feedback,
  }) async {
    final now = _clock.now();
    final updated = DailyDigest(
      id: digest.id,
      kind: digest.kind,
      dayKey: digest.dayKey,
      content: content.trim(),
      createdAt: digest.createdAt,
      planId: digest.planId,
      feedback: feedback?.trim().isEmpty ?? true ? null : feedback!.trim(),
      metricsJson: digest.metricsJson,
      updatedAt: now,
      userEdited: true,
    );
    await _ref.read(dailyDigestRepositoryProvider).upsert(updated);
    return updated;
  }

  String _parseReview(String raw, DailyReviewMetrics metrics) {
    final jsonText = _extractJson(raw);
    if (jsonText != null) {
      try {
        final decoded = jsonDecode(jsonText);
        if (decoded is Map) {
          final map = decoded.cast<String, Object?>();
          final summary = '${map['summary'] ?? ''}'.trim();
          final differences = _strings(map['differences']);
          final suggestions = _strings(map['suggestions']);
          return _markdownReview(
            metrics,
            summary: summary.isEmpty ? '今日复盘' : summary,
            differences: differences,
            suggestions: suggestions,
          );
        }
      } on FormatException {
        // 回落到纯文本。
      }
    }
    return raw.trim().isEmpty ? _localMarkdown(metrics) : raw.trim();
  }

  String _markdownReview(
    DailyReviewMetrics metrics, {
    required String summary,
    required List<String> differences,
    required List<String> suggestions,
  }) {
    final buffer = StringBuffer('## $summary\n\n');
    buffer.writeln('### 执行情况');
    buffer.writeln(
      '- 计划任务 ${metrics.totalTasks} 个，完成 ${metrics.completedTaskIds.length} 个',
    );
    if (metrics.openTaskIds.isNotEmpty) {
      buffer.writeln('- 未完成 ${metrics.openTaskIds.length} 个');
    }
    if (metrics.blockedTaskIds.isNotEmpty) {
      buffer.writeln('- 阻塞 ${metrics.blockedTaskIds.length} 个');
    }
    if (metrics.unknownEventCount > 0) {
      buffer.writeln('- 另有 ${metrics.unknownEventCount} 个无任务记录的日程，状态未知');
    }
    if (differences.isNotEmpty) {
      buffer.writeln('\n### 主要差异');
      for (final line in differences) {
        buffer.writeln('- $line');
      }
    }
    if (suggestions.isNotEmpty) {
      buffer.writeln('\n### 明天建议');
      for (final line in suggestions) {
        buffer.writeln('- $line');
      }
    }
    return buffer.toString().trim();
  }

  String _localMarkdown(DailyReviewMetrics metrics) => _markdownReview(
        metrics,
        summary: '今日复盘',
        differences: const <String>[],
        suggestions: const <String>[],
      );

  static List<String> _strings(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String? _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return raw.substring(start, end + 1);
  }

  String _reviewContext(DailyReviewMetrics metrics) => '''
dayKey: ${metrics.dayKey}
计划任务数: ${metrics.totalTasks}
完成: ${metrics.completedTaskIds.length}
未完成: ${metrics.openTaskIds.length}
阻塞: ${metrics.blockedTaskIds.length}
取消: ${metrics.cancelledTaskIds.length}
延期次数合计: ${metrics.postponedCount}
实际耗时: ${metrics.actualMinutes} 分钟
无任务记录日程: ${metrics.unknownEventCount}

请只返回 JSON：
{"summary":"一句话总结","differences":["计划与实际的差异"],"suggestions":["明天的一条具体建议"]}
不要改变本地统计，不要编造完成记录。''';

  static const String _reviewPrompt =
      '你是用户的每日复盘助手。只返回 JSON，不要 Markdown，不要声称未记录的日程已完成。';
}

final dailyReviewServiceProvider = Provider<DailyReviewService>(
  (ref) => DailyReviewService(ref),
);
