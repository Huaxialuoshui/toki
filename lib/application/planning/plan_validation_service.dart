import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/task_item.dart';
import 'planning_context.dart';
import 'planning_result_parser.dart';

class ValidatedPlanningResult {
  const ValidatedPlanningResult({
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

class PlanValidationService {
  const PlanValidationService();

  ValidatedPlanningResult validate(
    ParsedPlanningResult parsed,
    PlanningContext context,
  ) {
    final diagnostics = <Map<String, Object?>>[...parsed.diagnostics];
    final conflicts = <String>[...parsed.conflicts];
    final unscheduled = <String>{...parsed.unscheduledTaskIds};
    final items = <ParsedPlanItem>[];

    for (final item in parsed.items) {
      final task = item.taskId == null ? null : context.tasksById[item.taskId];
      if (item.taskId != null && task == null) {
        diagnostics.add(<String, Object?>{
          'code': 'unknown_task_id',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        continue;
      }
      if (task != null && !task.isActive) {
        diagnostics.add(<String, Object?>{
          'code': 'inactive_task',
          'itemIndex': item.index,
          'taskId': task.id,
        });
        continue;
      }

      var start = item.startAt;
      var end = item.endAt;
      var estimate = item.estimatedMinutes;
      if ((start == null) ^ (end == null)) {
        diagnostics.add(<String, Object?>{
          'code': 'incomplete_time_range',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }
      if (start == null || end == null) {
        if (item.taskId != null) {
          _unschedule(item, unscheduled, items, diagnostics, conflicts);
        } else {
          items.add(item.copyWith(clearStartAt: true, clearEndAt: true));
        }
        continue;
      }
      if (!end.isAfter(start)) {
        diagnostics.add(<String, Object?>{
          'code': 'end_before_start',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }
      if (start.isBefore(context.dayStart) || end.isAfter(context.dayEnd)) {
        diagnostics.add(<String, Object?>{
          'code': 'outside_day',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }
      if (start.isBefore(context.now)) {
        diagnostics.add(<String, Object?>{
          'code': 'start_in_past',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }

      final duration = end.difference(start).inMinutes;
      if (duration < 5 || duration > 480) {
        diagnostics.add(<String, Object?>{
          'code': 'invalid_duration',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }
      estimate = duration;

      if (!_fitsAvailability(start, end, context.availableWindows)) {
        diagnostics.add(<String, Object?>{
          'code': 'outside_available_window',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }
      if (_overlapsFixed(start, end, context.fixedIntervals)) {
        diagnostics.add(<String, Object?>{
          'code': 'overlaps_fixed_event',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }
      if (task?.dueAt != null && end.isAfter(task!.dueAt!)) {
        diagnostics.add(<String, Object?>{
          'code': 'deadline_conflict',
          'itemIndex': item.index,
          'taskId': task.id,
        });
        conflicts.add('任务「${task.title}」的安排会超过截止时间');
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }
      if (item.taskId != null &&
          context.scheduledTaskIds.contains(item.taskId)) {
        diagnostics.add(<String, Object?>{
          'code': 'task_already_scheduled',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        conflicts.add('任务「${item.title}」已经有正式日程');
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }

      final timed = item.copyWith(
        startAt: start,
        endAt: end,
        estimatedMinutes: estimate,
      );
      if (_overlapsPlanItem(timed, items)) {
        diagnostics.add(<String, Object?>{
          'code': 'overlapping_plan_items',
          'itemIndex': item.index,
          'taskId': item.taskId,
        });
        conflicts.add('建议安排「${item.title}」与其他条目重叠');
        _unschedule(item, unscheduled, items, diagnostics, conflicts);
        continue;
      }
      items.add(timed);
    }

    _enforceCapacity(items, unscheduled, diagnostics, conflicts, context);
    _sortItems(items);

    for (final taskId in context.request.mustDoTaskIds) {
      final inPlan = items.any((ParsedPlanItem item) => item.taskId == taskId);
      if (!inPlan && !unscheduled.contains(taskId)) {
        unscheduled.add(taskId);
        diagnostics.add(<String, Object?>{
          'code': 'must_do_unscheduled',
          'taskId': taskId,
        });
      }
    }

    final summary = parsed.summary.trim().isNotEmpty
        ? parsed.summary.trim()
        : (parsed.goals.isNotEmpty
            ? parsed.goals.first.title
            : (items.isEmpty ? '今日暂无安排' : '今日计划'));

    return ValidatedPlanningResult(
      summary: summary,
      goals: parsed.goals,
      items: items,
      unscheduledTaskIds: unscheduled.toList(growable: false),
      conflicts: conflicts,
      notes: parsed.notes,
      diagnostics: diagnostics,
    );
  }

  void _enforceCapacity(
    List<ParsedPlanItem> items,
    Set<String> unscheduled,
    List<Map<String, Object?>> diagnostics,
    List<String> conflicts,
    PlanningContext context,
  ) {
    int total() => items.fold<int>(
          0,
          (int sum, ParsedPlanItem item) =>
              sum +
              ((item.startAt != null && item.endAt != null)
                  ? item.endAt!.difference(item.startAt!).inMinutes
                  : 0),
        );
    if (total() <= context.capacityMinutes) return;

    final removable =
        items.where((ParsedPlanItem item) => item.startAt != null).toList()
          ..sort((ParsedPlanItem a, ParsedPlanItem b) {
            final rank = taskPriorityRank(b.priority)
                .compareTo(taskPriorityRank(a.priority));
            if (rank != 0) return rank;
            return b.startAt!.compareTo(a.startAt!);
          });
    for (final item in removable) {
      if (total() <= context.capacityMinutes) break;
      items.remove(item);
      _unschedule(item, unscheduled, items, diagnostics, conflicts);
      diagnostics.add(<String, Object?>{
        'code': 'capacity_exceeded',
        'taskId': item.taskId,
      });
    }
  }

  void _unschedule(
    ParsedPlanItem item,
    Set<String> unscheduled,
    List<ParsedPlanItem> items,
    List<Map<String, Object?>> diagnostics,
    List<String> conflicts,
  ) {
    if (item.taskId != null) {
      unscheduled.add(item.taskId!);
    } else {
      items.add(item.copyWith(clearStartAt: true, clearEndAt: true));
    }
    if (item.taskId != null) {
      conflicts.add('任务「${item.title}」转为待安排');
    }
  }

  void _sortItems(List<ParsedPlanItem> items) {
    items.sort((ParsedPlanItem a, ParsedPlanItem b) {
      final aStart = a.startAt;
      final bStart = b.startAt;
      if (aStart == null && bStart != null) return 1;
      if (aStart != null && bStart == null) return -1;
      if (aStart != null && bStart != null) {
        final byStart = aStart.compareTo(bStart);
        if (byStart != 0) return byStart;
      }
      return taskPriorityRank(a.priority).compareTo(
        taskPriorityRank(b.priority),
      );
    });
  }

  static bool _fitsAvailability(
    DateTime start,
    DateTime end,
    List<PlanningInterval> windows,
  ) {
    for (final window in windows) {
      if (!start.isBefore(window.start) && !end.isAfter(window.end)) {
        return true;
      }
    }
    return false;
  }

  static bool _overlapsFixed(
    DateTime start,
    DateTime end,
    List<PlanningInterval> fixed,
  ) {
    for (final interval in fixed) {
      if (start.isBefore(interval.end) && interval.start.isBefore(end)) {
        return true;
      }
    }
    return false;
  }

  static bool _overlapsPlanItem(
    ParsedPlanItem candidate,
    List<ParsedPlanItem> items,
  ) {
    final start = candidate.startAt;
    final end = candidate.endAt;
    if (start == null || end == null) return false;
    for (final item in items) {
      final otherStart = item.startAt;
      final otherEnd = item.endAt;
      if (otherStart == null || otherEnd == null) continue;
      if (start.isBefore(otherEnd) && otherStart.isBefore(end)) return true;
    }
    return false;
  }
}
