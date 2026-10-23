import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/task_item.dart';
import '../../infrastructure/clock_provider.dart';

final activeTasksProvider = StreamProvider.autoDispose<List<TaskItem>>(
  (ref) => ref.watch(taskRepositoryProvider).watchActive(),
);

final allTasksProvider = StreamProvider.autoDispose<List<TaskItem>>(
  (ref) => ref.watch(taskRepositoryProvider).watchAll(),
);

final completedTasksProvider = StreamProvider.autoDispose<List<TaskItem>>(
  (ref) => ref.watch(taskRepositoryProvider).watchCompleted(),
);

final archivedTasksProvider = StreamProvider.autoDispose<List<TaskItem>>(
  (ref) => ref.watch(taskRepositoryProvider).watchArchived(),
);

/// 首页任务摘要。
class TaskSummary {
  const TaskSummary({
    required this.active,
    required this.completed,
    required this.overdue,
    required this.dueToday,
  });

  final int active;
  final int completed;
  final int overdue;
  final int dueToday;

  int get total => active + completed;
  double get completionRate => total == 0 ? 0 : completed / total;
}

final taskSummaryProvider = Provider.autoDispose<TaskSummary>((ref) {
  final active =
      ref.watch(activeTasksProvider).valueOrNull ?? const <TaskItem>[];
  final completed =
      ref.watch(completedTasksProvider).valueOrNull ?? const <TaskItem>[];
  final now = ref.watch(clockProvider).now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final overdue = active
      .where((TaskItem task) => task.dueAt?.isBefore(now) ?? false)
      .length;
  final dueToday = active.where((TaskItem task) {
    final due = task.dueAt;
    return due != null && !due.isBefore(todayStart) && due.isBefore(todayEnd);
  }).length;
  return TaskSummary(
    active: active.length,
    completed: completed.length,
    overdue: overdue,
    dueToday: dueToday,
  );
});
