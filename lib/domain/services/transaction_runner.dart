/// 让应用层把多个仓储写入放进同一个数据库事务。
abstract interface class TransactionRunner {
  Future<T> run<T>(Future<T> Function() action);
}
