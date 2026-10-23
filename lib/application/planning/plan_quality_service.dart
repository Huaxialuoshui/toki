import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/task_item.dart';
import 'plan_progress.dart';
import 'planning_context.dart';

class PlanQualityService {
  const PlanQualityService();

  List<PlanQualityIssue> evaluate({
    required List<DailyPlanItem> items,
    required PlanningContext context,
    required Map<String, TaskItem> tasksById,
    required List<CalendarEvent> events,
  }) {
    final issues = <PlanQualityIssue>[];
    final timed = items
        .where(
          (DailyPlanItem item) =>
              item.status != PlanItemStatus.skipped &&
              item.startAt != null &&
              item.endAt != null,
        )
        .toList()
      ..sort((DailyPlanItem a, DailyPlanItem b) =>
          a.startAt!.compareTo(b.startAt!));
    final totalMinutes = timed.fold<int>(
      0,
      (int sum, DailyPlanItem item) =>
          sum + item.endAt!.difference(item.startAt!).inMinutes,
    );
    if (totalMinutes > context.capacityMinutes) {
      issues.add(const PlanQualityIssue(code: PlanQualityCode.overbooked));
    }
    for (var i = 1; i < timed.length; i++) {
      final gap = timed[i].startAt!.difference(timed[i - 1].endAt!);
      if (!gap.isNegative && gap.inMinutes < context.preferences.breakMinutes) {
        issues.add(
          PlanQualityIssue(
            code: PlanQualityCode.noBreak,
            itemId: timed[i].id,
          ),
        );
      }
    }
    if (context.allDayOccurrences.isNotEmpty) {
      issues.add(
        const PlanQualityIssue(code: PlanQualityCode.allDayContext),
      );
    }
    final plannedIds = <String>{
      for (final item in items)
        if (item.taskId != null && item.status != PlanItemStatus.skipped)
          item.taskId!,
    };
    for (final task in tasksById.values) {
      if (task.isActive &&
          task.dueAt != null &&
          task.dueAt!.isBefore(context.now.add(const Duration(hours: 24))) &&
          !plannedIds.contains(task.id)) {
        issues.add(
          PlanQualityIssue(
            code: PlanQualityCode.unscheduledDueSoon,
            taskId: task.id,
          ),
        );
      }
      if (task.status == TaskStatus.completed &&
          events.any(
            (CalendarEvent event) =>
                event.taskId == task.id &&
                event.startTime.isAfter(context.now) &&
                !event.isCancelled,
          )) {
        issues.add(
          PlanQualityIssue(
            code: PlanQualityCode.completedTaskWithFutureEvent,
            taskId: task.id,
          ),
        );
      }
      if (task.postponeCount >= 3) {
        issues.add(
          PlanQualityIssue(
            code: PlanQualityCode.repeatedPostpone,
            taskId: task.id,
          ),
        );
      }
    }
    for (final item in items) {
      final task = item.taskId == null ? null : tasksById[item.taskId];
      if (task?.dueAt != null &&
          item.endAt != null &&
          item.endAt!.isAfter(task!.dueAt!)) {
        issues.add(
          PlanQualityIssue(
            code: PlanQualityCode.deadlineRisk,
            itemId: item.id,
            taskId: task.id,
          ),
        );
      }
      if (item.appliedEventId != null &&
          !events
              .any((CalendarEvent event) => event.id == item.appliedEventId)) {
        issues.add(
          PlanQualityIssue(
            code: PlanQualityCode.detachedEvent,
            itemId: item.id,
            taskId: item.taskId,
          ),
        );
      }
    }
    return issues;
  }
}
