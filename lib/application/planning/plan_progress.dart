import 'package:flutter/foundation.dart';

import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/task_item.dart';

@immutable
class PlanProgress {
  const PlanProgress({
    required this.totalItems,
    required this.appliedItems,
    required this.completedTasks,
    required this.openTasks,
    required this.taskItems,
    required this.totalMinutes,
  });

  final int totalItems;
  final int appliedItems;
  final int completedTasks;
  final int openTasks;
  final int taskItems;
  final int totalMinutes;

  double get completionRate => taskItems == 0 ? 0 : completedTasks / taskItems;

  static PlanProgress compute({
    required DailyPlan plan,
    required List<DailyPlanItem> items,
    required Map<String, TaskItem> tasksById,
  }) {
    var applied = 0;
    var completed = 0;
    var open = 0;
    var taskItems = 0;
    var minutes = 0;
    for (final item in items) {
      if (item.status == PlanItemStatus.skipped) continue;
      if (item.status == PlanItemStatus.applied) applied++;
      if (item.startAt != null && item.endAt != null) {
        minutes += item.endAt!.difference(item.startAt!).inMinutes;
      }
      final taskId = item.taskId;
      if (taskId != null) {
        taskItems++;
        final task = tasksById[taskId];
        if (task?.status == TaskStatus.completed) {
          completed++;
        } else if (task != null) {
          open++;
        }
      }
    }
    return PlanProgress(
      totalItems: items
          .where((DailyPlanItem item) => item.status != PlanItemStatus.skipped)
          .length,
      appliedItems: applied,
      completedTasks: completed,
      openTasks: open,
      taskItems: taskItems,
      totalMinutes: minutes,
    );
  }
}

enum PlanQualityCode {
  overbooked,
  noBreak,
  allDayContext,
  unscheduledDueSoon,
  completedTaskWithFutureEvent,
  deadlineRisk,
  repeatedPostpone,
  detachedEvent,
}

@immutable
class PlanQualityIssue {
  const PlanQualityIssue({
    required this.code,
    this.itemId,
    this.taskId,
  });

  final PlanQualityCode code;
  final String? itemId;
  final String? taskId;
}
