import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/errors/planning_exception.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/task_item.dart';
import 'planning_context.dart';

@immutable
class ParsedPlanItem {
  const ParsedPlanItem({
    required this.title,
    required this.priority,
    required this.reason,
    required this.source,
    this.taskId,
    this.description,
    this.startAt,
    this.endAt,
    this.estimatedMinutes,
    this.sourceEventId,
    this.index = 0,
  });

  final String? taskId;
  final String title;
  final String? description;
  final DateTime? startAt;
  final DateTime? endAt;
  final int? estimatedMinutes;
  final TaskPriority priority;
  final String reason;
  final PlanItemSource source;
  final String? sourceEventId;
  final int index;

  ParsedPlanItem copyWith({
    String? title,
    TaskPriority? priority,
    String? reason,
    PlanItemSource? source,
    String? taskId,
    bool clearTaskId = false,
    String? description,
    DateTime? startAt,
    bool clearStartAt = false,
    DateTime? endAt,
    bool clearEndAt = false,
    int? estimatedMinutes,
    bool clearEstimatedMinutes = false,
    String? sourceEventId,
  }) {
    return ParsedPlanItem(
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: clearStartAt ? null : (startAt ?? this.startAt),
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
      estimatedMinutes: clearEstimatedMinutes
          ? null
          : (estimatedMinutes ?? this.estimatedMinutes),
      priority: priority ?? this.priority,
      reason: reason ?? this.reason,
      source: source ?? this.source,
      sourceEventId: sourceEventId ?? this.sourceEventId,
      index: index,
    );
  }
}

@immutable
class ParsedPlanningResult {
  const ParsedPlanningResult({
    required this.summary,
    required this.goals,
    required this.items,
    required this.unscheduledTaskIds,
    required this.conflicts,
    required this.notes,
    required this.diagnostics,
  });

  final String summary;
  final List<PlanGoal> goals;
  final List<ParsedPlanItem> items;
  final List<String> unscheduledTaskIds;
  final List<String> conflicts;
  final List<String> notes;
  final List<Map<String, Object?>> diagnostics;
}

class PlanningResultParser {
  const PlanningResultParser();

  ParsedPlanningResult parse(String raw, PlanningContext context) {
    final jsonText = _extractJsonObject(raw);
    if (jsonText == null) {
      throw const PlanningException(PlanningErrorCode.parseFailed);
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonText);
    } on FormatException catch (error) {
      throw PlanningException(
        PlanningErrorCode.parseFailed,
        cause: error,
      );
    }
    if (decoded is! Map) {
      throw const PlanningException(PlanningErrorCode.parseFailed);
    }
    final map = decoded.cast<String, Object?>();
    final diagnostics = <Map<String, Object?>>[];

    final goals = _list(map['goals'])
        .map(PlanGoal.fromJson)
        .whereType<PlanGoal>()
        .take(6)
        .toList(growable: false);

    final items = <ParsedPlanItem>[];
    final rawItems = _list(map['items']);
    for (var index = 0; index < rawItems.length; index++) {
      final parsed = _parseItem(
        rawItems[index],
        index,
        context,
        diagnostics,
      );
      if (parsed != null) items.add(parsed);
    }

    final unscheduled = <String>[];
    for (final rawId in _list(map['unscheduledTaskIds'])) {
      final id = '$rawId'.trim();
      if (id.isEmpty || !context.tasksById.containsKey(id)) {
        diagnostics.add(<String, Object?>{
          'code': 'unknown_unscheduled_task',
          'taskId': id,
        });
        continue;
      }
      if (!unscheduled.contains(id)) unscheduled.add(id);
    }

    final summary = _string(map['summary']) ?? '';
    final conflicts = _strings(map['conflicts']);
    final notes = _strings(map['notes']);
    final dayKey = _string(map['dayKey']);
    if (dayKey != null && dayKey != context.dayKey) {
      throw PlanningException(
        PlanningErrorCode.parseFailed,
        message: '计划日期不匹配：$dayKey != ${context.dayKey}',
      );
    }

    return ParsedPlanningResult(
      summary: summary,
      goals: goals,
      items: items,
      unscheduledTaskIds: unscheduled,
      conflicts: conflicts,
      notes: notes,
      diagnostics: diagnostics,
    );
  }

  ParsedPlanItem? _parseItem(
    Object? raw,
    int index,
    PlanningContext context,
    List<Map<String, Object?>> diagnostics,
  ) {
    if (raw is! Map) {
      diagnostics.add(<String, Object?>{
        'code': 'item_not_object',
        'index': index,
      });
      return null;
    }
    final map = raw.cast<String, Object?>();
    final source = _itemSource(
      _string(map['source']) ?? _string(map['kind']) ?? 'existingTask',
    );
    final taskId = _string(map['taskId']) ?? _string(map['task_id']);
    final task = taskId == null ? null : context.tasksById[taskId];

    if (source != PlanItemSource.newTask && task == null) {
      diagnostics.add(<String, Object?>{
        'code': taskId == null ? 'missing_task_id' : 'unknown_task_id',
        'index': index,
        'taskId': taskId,
      });
      return null;
    }

    final title = _string(map['title']) ?? task?.title ?? _string(map['name']);
    if (title == null || title.isEmpty) {
      diagnostics.add(<String, Object?>{
        'code': 'missing_title',
        'index': index,
      });
      return null;
    }

    var start = _date(map['startTime']) ?? _date(map['start_time']);
    var end = _date(map['endTime']) ?? _date(map['end_time']);
    var estimate = _int(map['estimatedMinutes']) ??
        _int(map['estimateMinutes']) ??
        _int(map['estimate_minutes']);
    if (start != null && end != null && estimate == null) {
      estimate = end.difference(start).inMinutes;
    } else if (start != null && end == null && estimate != null) {
      end = start.add(Duration(minutes: estimate));
    } else if (start == null && end != null && estimate != null) {
      start = end.subtract(Duration(minutes: estimate));
    }

    return ParsedPlanItem(
      taskId: source == PlanItemSource.newTask ? null : taskId,
      title: title,
      description: _string(map['description']) ?? task?.description,
      startAt: start,
      endAt: end,
      estimatedMinutes: estimate ?? task?.estimatedMinutes,
      priority:
          _priority(map['priority']) ?? task?.priority ?? TaskPriority.normal,
      reason: _string(map['reason']) ?? '',
      source: source,
      sourceEventId:
          _string(map['sourceEventId']) ?? _string(map['source_event_id']),
      index: index,
    );
  }

  static List<Object?> _list(Object? value) =>
      value is List ? value : const <Object?>[];

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const <String>[];
    return value.map(_string).whereType<String>().toList(growable: false);
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static DateTime? _date(Object? value) {
    final text = _string(value);
    if (text == null) return null;
    final parsed = DateTime.tryParse(text);
    return parsed?.toLocal();
  }

  static TaskPriority? _priority(Object? value) {
    final text = '${value ?? ''}'.toLowerCase().trim();
    for (final priority in TaskPriority.values) {
      if (priority.name == text) return priority;
    }
    return null;
  }

  static PlanItemSource _itemSource(String raw) {
    final normalized = raw.toLowerCase().replaceAll('_', '');
    if (normalized.contains('new')) return PlanItemSource.newTask;
    if (normalized.contains('split') || normalized.contains('event')) {
      return PlanItemSource.eventSplit;
    }
    return PlanItemSource.existingTask;
  }

  /// 从代码围栏或前后说明中提取第一个平衡的 JSON 对象。
  static String? _extractJsonObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final start = trimmed.indexOf('{');
    if (start < 0) return null;
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < trimmed.length; i++) {
      final char = trimmed[i];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }
      if (char == '"') {
        inString = true;
      } else if (char == '{') {
        depth++;
      } else if (char == '}') {
        depth--;
        if (depth == 0) return trimmed.substring(start, i + 1);
      }
    }
    return null;
  }
}
