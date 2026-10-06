/// Phase 1 只需要一个最小错误类型。
///
/// 后续阶段（数据库 / AI / 通知）会在此基础上扩展具体子类，避免业务层直接
/// 抛出平台或第三方库的原始异常。
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      cause == null ? 'AppException: $message' : 'AppException: $message ($cause)';
}
