import '../entities/task_item.dart';

/// 任务数据访问契约。
abstract interface class TaskRepository {
  /// 未归档的未完成任务，按“阻塞 / 逾期 / 优先级 / 截止时间”排序。
  Stream<List<TaskItem>> watchActive();

  /// 全部任务（默认不含归档），用于按 ID 读取计划条目的实时状态。
  Stream<List<TaskItem>> watchAll({bool includeArchived = false});

  /// 未归档的已完成任务，最近完成的在前。
  Stream<List<TaskItem>> watchCompleted();

  /// 已归档任务，最近归档的在前。
  Stream<List<TaskItem>> watchArchived();

  Future<List<TaskItem>> getActive();
  Future<List<TaskItem>> getAll({bool includeArchived = false});
  Future<TaskItem?> findById(String id);
  Future<List<TaskItem>> getOverdue(DateTime now);
  Future<List<TaskItem>> getDueSoon(DateTime now, DateTime until);
  Future<int> count({bool includeArchived = false});

  Future<void> upsert(TaskItem task);
  Future<void> upsertAll(List<TaskItem> tasks);

  /// 物理删除；UI 的“删除”使用 Actions 的软归档。
  Future<void> deleteById(String id);
  Future<void> deleteAll();
}
