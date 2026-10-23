import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'task_item.dart';

enum PlanStatus {
  draft,
  confirmed,
  inProgress,
  completed,
  cancelled,
  superseded,
}

enum PlanGenerationSource { manual, auto }

enum PlanItemStatus { proposed, applied, skipped, failed, detached }

enum PlanItemSource { existingTask, newTask, eventSplit }

/// 用户明确指定的可用 / 不可用时间。
@immutable
class PlanningWindow {
  const PlanningWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  Map<String, Object?> toJson() => <String, Object?>{
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  static PlanningWindow? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final start = DateTime.tryParse('${raw['start']}');
    final end = DateTime.tryParse('${raw['end']}');
    if (start == null || end == null || !end.isAfter(start)) return null;
    return PlanningWindow(start: start, end: end);
  }

  @override
  bool operator ==(Object other) =>
      other is PlanningWindow && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// 计划生成时的用户输入。
@immutable
class PlanningConstraints {
  const PlanningConstraints({
    this.goalText,
    this.mustDoTaskIds = const <String>[],
    this.availableWindows = const <PlanningWindow>[],
    this.blockedWindows = const <PlanningWindow>[],
    this.energy,
    this.notes,
  });

  final String? goalText;
  final List<String> mustDoTaskIds;
  final List<PlanningWindow> availableWindows;
  final List<PlanningWindow> blockedWindows;
  final String? energy;
  final String? notes;

  Map<String, Object?> toJson() => <String, Object?>{
        if (goalText != null) 'goalText': goalText,
        'mustDoTaskIds': mustDoTaskIds,
        'availableWindows':
            availableWindows.map((PlanningWindow w) => w.toJson()).toList(),
        'blockedWindows':
            blockedWindows.map((PlanningWindow w) => w.toJson()).toList(),
        if (energy != null) 'energy': energy,
        if (notes != null) 'notes': notes,
      };

  static PlanningConstraints fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const PlanningConstraints();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const PlanningConstraints();
      final map = decoded.cast<String, Object?>();
      return PlanningConstraints(
        goalText: _string(map['goalText']),
        mustDoTaskIds: _strings(map['mustDoTaskIds']),
        availableWindows: _windows(map['availableWindows']),
        blockedWindows: _windows(map['blockedWindows']),
        energy: _string(map['energy']),
        notes: _string(map['notes']),
      );
    } on FormatException {
      return const PlanningConstraints();
    }
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<PlanningWindow> _windows(Object? value) {
    if (value is! List) return const <PlanningWindow>[];
    return value
        .map(PlanningWindow.fromJson)
        .whereType<PlanningWindow>()
        .toList(growable: false);
  }
}

@immutable
class PlanGoal {
  const PlanGoal({required this.title, this.priority = TaskPriority.normal});

  final String title;
  final TaskPriority priority;

  Map<String, Object?> toJson() => <String, Object?>{
        'title': title,
        'priority': priority.name,
      };

  static PlanGoal? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final title = '${raw['title'] ?? ''}'.trim();
    if (title.isEmpty) return null;
    return PlanGoal(
      title: title,
      priority: _priority(raw['priority']),
    );
  }
}

TaskPriority _priority(Object? raw) {
  final value = '${raw ?? ''}'.toLowerCase().trim();
  for (final priority in TaskPriority.values) {
    if (priority.name == value) return priority;
  }
  return TaskPriority.normal;
}

List<PlanGoal> planGoalsFromJson(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const <PlanGoal>[];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <PlanGoal>[];
    return decoded
        .map(PlanGoal.fromJson)
        .whereType<PlanGoal>()
        .toList(growable: false);
  } on FormatException {
    return const <PlanGoal>[];
  }
}

String planGoalsToJson(List<PlanGoal> goals) =>
    jsonEncode(goals.map((PlanGoal goal) => goal.toJson()).toList());

@immutable
class PlanGenerationMetadata {
  const PlanGenerationMetadata({
    this.diagnostics = const <Map<String, Object?>>[],
    this.unscheduledTaskIds = const <String>[],
    this.conflicts = const <String>[],
    this.notes = const <String>[],
  });

  final List<Map<String, Object?>> diagnostics;
  final List<String> unscheduledTaskIds;
  final List<String> conflicts;
  final List<String> notes;

  String toJsonString() => jsonEncode(<String, Object?>{
        'diagnostics': diagnostics,
        'unscheduledTaskIds': unscheduledTaskIds,
        'conflicts': conflicts,
        'notes': notes,
      });

  static PlanGenerationMetadata fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const PlanGenerationMetadata();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        // 兼容 Phase 14.2 早期仅保存诊断数组的草稿。
        return PlanGenerationMetadata(
          diagnostics: decoded
              .whereType<Map>()
              .map((Map item) => item.cast<String, Object?>())
              .toList(growable: false),
        );
      }
      if (decoded is! Map) return const PlanGenerationMetadata();
      final map = decoded.cast<String, Object?>();
      return PlanGenerationMetadata(
        diagnostics: _maps(map['diagnostics']),
        unscheduledTaskIds: _strings(map['unscheduledTaskIds']),
        conflicts: _strings(map['conflicts']),
        notes: _strings(map['notes']),
      );
    } on FormatException {
      return const PlanGenerationMetadata();
    }
  }

  static List<Map<String, Object?>> _maps(Object? value) {
    if (value is! List) return const <Map<String, Object?>>[];
    return value
        .whereType<Map>()
        .map((Map item) => item.cast<String, Object?>())
        .toList(growable: false);
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .whereType<String>()
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

/// 一个结构化的每日计划 revision。
@immutable
class DailyPlan {
  const DailyPlan({
    required this.id,
    required this.dayKey,
    required this.revision,
    required this.status,
    required this.summary,
    required this.goals,
    required this.constraints,
    required this.generationSource,
    required this.createdAt,
    required this.updatedAt,
    this.generationDiagnosticsJson,
    this.confirmedAt,
    this.completedAt,
  });

  final String id;
  final String dayKey;
  final int revision;
  final PlanStatus status;
  final String summary;
  final List<PlanGoal> goals;
  final PlanningConstraints constraints;
  final PlanGenerationSource generationSource;
  final String? generationDiagnosticsJson;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanGenerationMetadata get generationMetadata =>
      PlanGenerationMetadata.fromJsonString(generationDiagnosticsJson);

  DailyPlan copyWith({
    String? id,
    String? dayKey,
    int? revision,
    PlanStatus? status,
    String? summary,
    List<PlanGoal>? goals,
    PlanningConstraints? constraints,
    PlanGenerationSource? generationSource,
    String? generationDiagnosticsJson,
    bool clearGenerationDiagnostics = false,
    DateTime? confirmedAt,
    bool clearConfirmedAt = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyPlan(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      revision: revision ?? this.revision,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      goals: goals ?? this.goals,
      constraints: constraints ?? this.constraints,
      generationSource: generationSource ?? this.generationSource,
      generationDiagnosticsJson: clearGenerationDiagnostics
          ? null
          : (generationDiagnosticsJson ?? this.generationDiagnosticsJson),
      confirmedAt: clearConfirmedAt ? null : (confirmedAt ?? this.confirmedAt),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyPlan &&
        other.id == id &&
        other.dayKey == dayKey &&
        other.revision == revision &&
        other.status == status &&
        other.summary == summary &&
        listEquals(other.goals, goals) &&
        other.constraints.toJson().toString() ==
            constraints.toJson().toString() &&
        other.generationSource == generationSource &&
        other.generationDiagnosticsJson == generationDiagnosticsJson &&
        other.confirmedAt == confirmedAt &&
        other.completedAt == completedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        dayKey,
        revision,
        status,
        summary,
        Object.hashAll(goals),
        constraints.toJson().toString(),
        generationSource,
        generationDiagnosticsJson,
        confirmedAt,
        completedAt,
        createdAt,
        updatedAt,
      );
}

/// 计划中的一个建议条目。
@immutable
class DailyPlanItem {
  const DailyPlanItem({
    required this.id,
    required this.planId,
    required this.titleSnapshot,
    required this.priority,
    required this.reason,
    required this.source,
    required this.status,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.taskId,
    this.descriptionSnapshot,
    this.startAt,
    this.endAt,
    this.estimateMinutes,
    this.sourceEventId,
    this.appliedEventId,
    this.appliedAt,
    this.failureReason,
  });

  final String id;
  final String planId;
  final String? taskId;
  final String titleSnapshot;
  final String? descriptionSnapshot;
  final DateTime? startAt;
  final DateTime? endAt;
  final int? estimateMinutes;
  final TaskPriority priority;
  final String reason;
  final PlanItemSource source;
  final String? sourceEventId;
  final PlanItemStatus status;
  final String? appliedEventId;
  final DateTime? appliedAt;
  final String? failureReason;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyPlanItem copyWith({
    String? id,
    String? planId,
    String? taskId,
    bool clearTaskId = false,
    String? titleSnapshot,
    String? descriptionSnapshot,
    bool clearDescriptionSnapshot = false,
    DateTime? startAt,
    bool clearStartAt = false,
    DateTime? endAt,
    bool clearEndAt = false,
    int? estimateMinutes,
    bool clearEstimateMinutes = false,
    TaskPriority? priority,
    String? reason,
    PlanItemSource? source,
    String? sourceEventId,
    PlanItemStatus? status,
    String? appliedEventId,
    bool clearAppliedEventId = false,
    DateTime? appliedAt,
    bool clearAppliedAt = false,
    String? failureReason,
    bool clearFailureReason = false,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyPlanItem(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      taskId: clearTaskId ? null : (taskId ?? this.taskId),
      titleSnapshot: titleSnapshot ?? this.titleSnapshot,
      descriptionSnapshot: clearDescriptionSnapshot
          ? null
          : (descriptionSnapshot ?? this.descriptionSnapshot),
      startAt: clearStartAt ? null : (startAt ?? this.startAt),
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
      estimateMinutes: clearEstimateMinutes
          ? null
          : (estimateMinutes ?? this.estimateMinutes),
      priority: priority ?? this.priority,
      reason: reason ?? this.reason,
      source: source ?? this.source,
      sourceEventId: sourceEventId ?? this.sourceEventId,
      status: status ?? this.status,
      appliedEventId:
          clearAppliedEventId ? null : (appliedEventId ?? this.appliedEventId),
      appliedAt: clearAppliedAt ? null : (appliedAt ?? this.appliedAt),
      failureReason:
          clearFailureReason ? null : (failureReason ?? this.failureReason),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
