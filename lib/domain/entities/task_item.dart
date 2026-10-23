import 'package:flutter/foundation.dart';

/// 任务优先级。
enum TaskPriority { low, normal, high, urgent }

/// 任务状态。日程的完成状态不会自动改变这里。
enum TaskStatus { open, blocked, completed, cancelled }

/// 任务来源。
enum TaskSource { manual, ai, eventSplit }

/// 一件需要完成的事。
///
/// 任务可以没有截止时间，也不要求有日程。正式日程通过可空 `taskId`
/// 反向引用任务；一个任务可以关联多个日程。
@immutable
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.source,
    required this.postponeCount,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.dueAt,
    this.estimatedMinutes,
    this.actualMinutes,
    this.sourceEventId,
    this.completedAt,
    this.completionNote,
    this.lastPostponedAt,
    this.archivedAt,
  });

  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueAt;
  final int? estimatedMinutes;
  final int? actualMinutes;
  final TaskStatus status;
  final TaskSource source;

  /// 从某个日程拆分出来时的来源日程；只作历史追踪，不设外键。
  final String? sourceEventId;
  final DateTime? completedAt;
  final String? completionNote;
  final int postponeCount;
  final DateTime? lastPostponedAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isArchived => archivedAt != null;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isActive =>
      !isArchived && !isCompleted && status != TaskStatus.cancelled;

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    TaskPriority? priority,
    DateTime? dueAt,
    bool clearDueAt = false,
    int? estimatedMinutes,
    bool clearEstimatedMinutes = false,
    int? actualMinutes,
    bool clearActualMinutes = false,
    TaskStatus? status,
    TaskSource? source,
    String? sourceEventId,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    String? completionNote,
    bool clearCompletionNote = false,
    int? postponeCount,
    DateTime? lastPostponedAt,
    bool clearLastPostponedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      priority: priority ?? this.priority,
      dueAt: clearDueAt ? null : (dueAt ?? this.dueAt),
      estimatedMinutes: clearEstimatedMinutes
          ? null
          : (estimatedMinutes ?? this.estimatedMinutes),
      actualMinutes:
          clearActualMinutes ? null : (actualMinutes ?? this.actualMinutes),
      status: status ?? this.status,
      source: source ?? this.source,
      sourceEventId: sourceEventId ?? this.sourceEventId,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      completionNote:
          clearCompletionNote ? null : (completionNote ?? this.completionNote),
      postponeCount: postponeCount ?? this.postponeCount,
      lastPostponedAt: clearLastPostponedAt
          ? null
          : (lastPostponedAt ?? this.lastPostponedAt),
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.dueAt == dueAt &&
        other.estimatedMinutes == estimatedMinutes &&
        other.actualMinutes == actualMinutes &&
        other.status == status &&
        other.source == source &&
        other.sourceEventId == sourceEventId &&
        other.completedAt == completedAt &&
        other.completionNote == completionNote &&
        other.postponeCount == postponeCount &&
        other.lastPostponedAt == lastPostponedAt &&
        other.archivedAt == archivedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        title,
        description,
        priority,
        dueAt,
        estimatedMinutes,
        actualMinutes,
        status,
        source,
        sourceEventId,
        completedAt,
        completionNote,
        postponeCount,
        lastPostponedAt,
        archivedAt,
        createdAt,
        updatedAt,
      ]);
}

/// 优先级排序权重：紧急在前，低优先级在后。
int taskPriorityRank(TaskPriority priority) => switch (priority) {
      TaskPriority.urgent => 0,
      TaskPriority.high => 1,
      TaskPriority.normal => 2,
      TaskPriority.low => 3,
    };
