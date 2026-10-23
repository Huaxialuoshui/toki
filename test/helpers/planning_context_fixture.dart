import 'package:toki/application/planning/planning_context.dart';
import 'package:toki/domain/entities/planning_preferences.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/domain/services/recurrence.dart';

PlanningContext testPlanningContext({
  DateTime? now,
  List<TaskItem> tasks = const <TaskItem>[],
  List<PlanningInterval>? availableWindows,
  List<PlanningInterval> fixedIntervals = const <PlanningInterval>[],
  List<EventOccurrence> allDayOccurrences = const <EventOccurrence>[],
  Set<String> scheduledTaskIds = const <String>{},
  PlanningRequest? request,
  int? capacityMinutes,
}) {
  final effectiveNow = now ?? DateTime(2026, 10, 19, 8);
  final dayStart = DateTime(
    effectiveNow.year,
    effectiveNow.month,
    effectiveNow.day,
  );
  final dayEnd = DateTime(
    effectiveNow.year,
    effectiveNow.month,
    effectiveNow.day + 1,
  );
  final windows = availableWindows ??
      <PlanningInterval>[
        PlanningInterval(
          start: DateTime(dayStart.year, dayStart.month, dayStart.day, 9),
          end: DateTime(dayStart.year, dayStart.month, dayStart.day, 12),
        ),
        PlanningInterval(
          start: DateTime(dayStart.year, dayStart.month, dayStart.day, 13, 30),
          end: DateTime(dayStart.year, dayStart.month, dayStart.day, 18),
        ),
      ];
  final effectiveRequest = request ?? PlanningRequest(day: dayStart);
  final preferences = PlanningPreferences(
    createdAt: effectiveNow,
    updatedAt: effectiveNow,
  );
  return PlanningContext(
    request: effectiveRequest,
    now: effectiveNow,
    dayStart: dayStart,
    dayEnd: dayEnd,
    dayKey: '${dayStart.year}-'
        '${dayStart.month.toString().padLeft(2, '0')}-'
        '${dayStart.day.toString().padLeft(2, '0')}',
    fixedOccurrences: const [],
    allDayOccurrences: allDayOccurrences,
    fixedIntervals: fixedIntervals,
    candidateTasks: tasks,
    tasksById: <String, TaskItem>{
      for (final task in tasks) task.id: task,
    },
    scheduledTaskIds: scheduledTaskIds,
    countdowns: const [],
    preferences: preferences,
    availableWindows: windows,
    blockedWindows: const [],
    capacityMinutes: capacityMinutes ??
        windows.fold<int>(
          0,
          (int sum, PlanningInterval interval) => sum + interval.minutes,
        ),
    priorReview: null,
    weatherSummary: null,
    prompt: '',
  );
}

TaskItem testTask({
  required String id,
  String? title,
  TaskPriority priority = TaskPriority.normal,
  DateTime? dueAt,
  int? estimateMinutes,
  TaskStatus status = TaskStatus.open,
  DateTime? archivedAt,
}) {
  final now = DateTime(2026, 10, 19, 8);
  return TaskItem(
    id: id,
    title: title ?? '任务 $id',
    priority: priority,
    status: status,
    source: TaskSource.manual,
    dueAt: dueAt,
    estimatedMinutes: estimateMinutes,
    archivedAt: archivedAt,
    postponeCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}
