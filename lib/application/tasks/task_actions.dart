import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/errors/task_exception.dart';
import '../../core/utils/id_generator.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../../infrastructure/clock_provider.dart';

/// 任务的业务写入口。
///
/// 状态规则集中在这里，UI 不直接改数据库。任务完成 / 归档都不会碰日程。
class TaskActions {
  TaskActions({
    required TaskRepository repository,
    required Clock clock,
  })  : _repository = repository,
        _clock = clock;

  final TaskRepository _repository;
  final Clock _clock;

  Future<TaskItem> create({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.normal,
    DateTime? dueAt,
    int? estimatedMinutes,
    TaskSource source = TaskSource.manual,
    String? sourceEventId,
  }) async {
    _validateTitle(title);
    _validateMinutes(
      estimatedMinutes,
      TaskErrorCode.invalidEstimatedMinutes,
    );
    final now = _clock.now();
    final task = TaskItem(
      id: generateId('task', now: now),
      title: title.trim(),
      description: _emptyToNull(description),
      priority: priority,
      dueAt: dueAt,
      estimatedMinutes: estimatedMinutes,
      status: TaskStatus.open,
      source: source,
      sourceEventId: sourceEventId,
      postponeCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(task);
    return task;
  }

  Future<TaskItem> update(TaskItem task) async {
    _validateTitle(task.title);
    _validateMinutes(
      task.estimatedMinutes,
      TaskErrorCode.invalidEstimatedMinutes,
    );
    _validateMinutes(
      task.actualMinutes,
      TaskErrorCode.invalidActualMinutes,
    );
    final now = _clock.now();
    final normalized = task.copyWith(
      title: task.title.trim(),
      description: _emptyToNull(task.description),
      completionNote: _emptyToNull(task.completionNote),
      completedAt: task.status == TaskStatus.completed
          ? (task.completedAt ?? now)
          : null,
      clearCompletedAt: task.status != TaskStatus.completed,
      updatedAt: now,
    );
    await _repository.upsert(normalized);
    return normalized;
  }

  Future<TaskItem> setPriority(String id, TaskPriority priority) async {
    final task = await _require(id);
    return update(task.copyWith(priority: priority));
  }

  Future<TaskItem> setDueAt(String id, DateTime? dueAt) async {
    final task = await _require(id);
    return update(task.copyWith(dueAt: dueAt, clearDueAt: dueAt == null));
  }

  Future<TaskItem> setEstimatedMinutes(String id, int? minutes) async {
    final task = await _require(id);
    return update(
      task.copyWith(
        estimatedMinutes: minutes,
        clearEstimatedMinutes: minutes == null,
      ),
    );
  }

  Future<TaskItem> complete(
    String id, {
    int? actualMinutes,
    String? completionNote,
  }) async {
    final task = await _require(id);
    if (task.status == TaskStatus.completed) return task;
    return update(
      task.copyWith(
        status: TaskStatus.completed,
        completedAt: _clock.now(),
        actualMinutes: actualMinutes,
        clearActualMinutes: actualMinutes == null,
        completionNote: completionNote,
        clearCompletionNote: completionNote == null,
      ),
    );
  }

  Future<TaskItem> uncomplete(String id) async {
    final task = await _require(id);
    if (task.status != TaskStatus.completed) return task;
    return update(
      task.copyWith(
        status: TaskStatus.open,
        clearCompletedAt: true,
        clearActualMinutes: true,
        clearCompletionNote: true,
      ),
    );
  }

  Future<TaskItem> setBlocked(String id, bool blocked) async {
    final task = await _require(id);
    if (task.status == TaskStatus.completed ||
        task.status == TaskStatus.cancelled) {
      throw TaskException(TaskErrorCode.notActive, taskId: id);
    }
    return update(
      task.copyWith(
        status: blocked ? TaskStatus.blocked : TaskStatus.open,
      ),
    );
  }

  /// 延后到目标日期；有截止时间时保留原时刻，没有截止时间则不虚构时间。
  Future<TaskItem> postpone(String id, DateTime targetDate) async {
    final task = await _require(id);
    final due = task.dueAt;
    final nextDue = due == null
        ? null
        : DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            due.hour,
            due.minute,
            due.second,
            due.millisecond,
            due.microsecond,
          );
    return update(
      task.copyWith(
        dueAt: nextDue,
        clearDueAt: nextDue == null,
        postponeCount: task.postponeCount + 1,
        lastPostponedAt: _clock.now(),
      ),
    );
  }

  /// 软归档：任务与计划历史保留，关联日程不删除。
  Future<TaskItem> archive(String id) async {
    final task = await _require(id);
    return update(task.copyWith(archivedAt: _clock.now()));
  }

  Future<TaskItem> restore(String id) async {
    final task = await _require(id);
    return update(task.copyWith(clearArchivedAt: true));
  }

  /// 物理删除，只用于数据维护 / 测试；外键会置空任务引用。
  Future<void> hardDelete(String id) => _repository.deleteById(id);

  Future<TaskItem> _require(String id) async {
    final task = await _repository.findById(id);
    if (task == null) {
      throw TaskException(TaskErrorCode.notFound, taskId: id);
    }
    return task;
  }

  static void _validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw const TaskException(TaskErrorCode.emptyTitle);
    }
  }

  static void _validateMinutes(int? minutes, TaskErrorCode code) {
    if (minutes != null && minutes < 0) {
      throw TaskException(code);
    }
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

final taskActionsProvider = Provider<TaskActions>(
  (ref) => TaskActions(
    repository: ref.watch(taskRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);
