import 'package:drift/drift.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../infrastructure/database/app_database.dart';
import 'mappers.dart';

/// [ReminderRepository] 的 Drift 实现。
class DriftReminderRepository implements ReminderRepository {
  DriftReminderRepository(this._db);

  final AppDatabase _db;

  List<OrderClauseGenerator<$RemindersTable>> _ordering() =>
      <OrderClauseGenerator<$RemindersTable>>[
        ($RemindersTable t) => OrderingTerm.asc(t.triggerTime),
      ];

  @override
  Stream<List<Reminder>> watchAll() =>
      (_db.select(_db.reminders)..orderBy(_ordering())).watch().map(_mapAll);

  @override
  Stream<List<Reminder>> watchForEvent(String eventId) {
    final query = _db.select(_db.reminders)
      ..where(($RemindersTable t) => t.eventId.equals(eventId))
      ..orderBy(_ordering());
    return query.watch().map(_mapAll);
  }

  @override
  Stream<List<Reminder>> watchPending({required DateTime from}) {
    final query = _db.select(_db.reminders)
      ..where(
        ($RemindersTable t) =>
            t.enabled.equals(true) & t.triggerTime.isBiggerOrEqualValue(from),
      )
      ..orderBy(_ordering());
    return query.watch().map(_mapAll);
  }

  @override
  Future<List<Reminder>> getAll() async {
    final rows = await (_db.select(_db.reminders)..orderBy(_ordering())).get();
    return _mapAll(rows);
  }

  @override
  Future<Reminder?> findById(String id) async {
    final row = await (_db.select(_db.reminders)
          ..where(($RemindersTable t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<int> count() async {
    final countExpression = _db.reminders.id.count();
    final query = _db.selectOnly(_db.reminders)
      ..addColumns(<Expression<Object>>[countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  @override
  Future<void> upsert(Reminder reminder) =>
      _db.into(_db.reminders).insertOnConflictUpdate(
            reminderToCompanion(reminder),
          );

  @override
  Future<void> upsertAll(List<Reminder> reminders) async {
    if (reminders.isEmpty) return;
    await _db.batch((Batch batch) {
      batch.insertAllOnConflictUpdate(
        _db.reminders,
        reminders.map(reminderToCompanion),
      );
    });
  }

  @override
  Future<void> setEnabled({required String id, required bool enabled}) async {
    await (_db.update(_db.reminders)
          ..where(($RemindersTable t) => t.id.equals(id)))
        .write(RemindersCompanion(enabled: Value<bool>(enabled)));
  }

  @override
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.reminders)
          ..where(($RemindersTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.reminders).go();

  List<Reminder> _mapAll(List<ReminderRow> rows) =>
      rows.map((ReminderRow row) => row.toDomain()).toList(growable: false);
}
