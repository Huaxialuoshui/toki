import '../../domain/services/transaction_runner.dart';
import '../../infrastructure/database/app_database.dart';

class DriftTransactionRunner implements TransactionRunner {
  DriftTransactionRunner(this._db);

  final AppDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
