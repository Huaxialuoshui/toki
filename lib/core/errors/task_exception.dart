/// 任务业务规则错误。
enum TaskErrorCode {
  emptyTitle,
  invalidEstimatedMinutes,
  invalidActualMinutes,
  invalidDueAt,
  notFound,
  notActive,
  notCompleted,
}

class TaskException implements Exception {
  const TaskException(this.code, {this.taskId});

  final TaskErrorCode code;
  final String? taskId;

  @override
  String toString() =>
      'TaskException(${code.name}${taskId == null ? '' : ': $taskId'})';
}
