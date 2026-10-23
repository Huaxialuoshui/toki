enum PlanningErrorCode {
  noProvider,
  network,
  timeout,
  rateLimited,
  parseFailed,
  validationFailed,
  planConflict,
  taskMissing,
  userDeclined,
  databaseWriteFailed,
  planStale,
  cancelled,
}

class PlanningException implements Exception {
  const PlanningException(
    this.code, {
    this.message,
    this.cause,
  });

  final PlanningErrorCode code;
  final String? message;
  final Object? cause;

  @override
  String toString() {
    final detail = message == null ? '' : ': $message';
    return 'PlanningException(${code.name}$detail)';
  }
}
