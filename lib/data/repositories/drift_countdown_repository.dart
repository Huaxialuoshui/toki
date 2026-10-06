import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/entities/countdown_item.dart';
import '../../domain/repositories/countdown_repository.dart';
import '../../infrastructure/database/app_database.dart';
import 'mappers.dart';

/// [CountdownRepository] 的 Drift 实现。
class DriftCountdownRepository implements CountdownRepository {
  DriftCountdownRepository(this._db, {Clock clock = const SystemClock()})
      : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  /// 置顶优先，其次按手动排序位，最后按目标时间。
  List<OrderClauseGenerator<$CountdownsTable>> _ordering() =>
      <OrderClauseGenerator<$CountdownsTable>>[
        ($CountdownsTable t) => OrderingTerm.desc(t.isPinned),
        ($CountdownsTable t) => OrderingTerm.asc(t.sortOrder),
        ($CountdownsTable t) => OrderingTerm.asc(t.targetTime),
      ];

  @override
  Stream<List<CountdownItem>> watchAll() =>
      (_db.select(_db.countdowns)..orderBy(_ordering())).watch().map(_mapAll);

  @override
  Stream<List<CountdownItem>> watchPinned() {
    final query = _db.select(_db.countdowns)
      ..where(($CountdownsTable t) => t.isPinned.equals(true))
      ..orderBy(_ordering());
    return query.watch().map(_mapAll);
  }

  @override
  Future<List<CountdownItem>> getAll() async {
    final rows = await (_db.select(_db.countdowns)..orderBy(_ordering())).get();
    return _mapAll(rows);
  }

  @override
  Future<CountdownItem?> findById(String id) async {
    final row = await (_db.select(_db.countdowns)
          ..where(($CountdownsTable t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<int> count() async {
    final countExpression = _db.countdowns.id.count();
    final query = _db.selectOnly(_db.countdowns)
      ..addColumns(<Expression<Object>>[countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  @override
  Future<void> upsert(CountdownItem item) async {
    final now = _clock.now();
    await _db.into(_db.countdowns).insertOnConflictUpdate(
          countdownToCompanion(item).copyWith(updatedAt: Value<DateTime>(now)),
        );
  }

  @override
  Future<void> upsertAll(List<CountdownItem> items) async {
    if (items.isEmpty) return;
    final now = _clock.now();
    await _db.batch((Batch batch) {
      batch.insertAllOnConflictUpdate(
        _db.countdowns,
        items.map(
          (CountdownItem item) => countdownToCompanion(item)
              .copyWith(updatedAt: Value<DateTime>(now)),
        ),
      );
    });
  }

  @override
  Future<void> setPinned({required String id, required bool isPinned}) async {
    await (_db.update(_db.countdowns)
          ..where(($CountdownsTable t) => t.id.equals(id)))
        .write(
      CountdownsCompanion(
        isPinned: Value<bool>(isPinned),
        updatedAt: Value<DateTime>(_clock.now()),
      ),
    );
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    final now = _clock.now();
    await _db.transaction(() async {
      for (var index = 0; index < orderedIds.length; index++) {
        await (_db.update(_db.countdowns)
              ..where(($CountdownsTable t) => t.id.equals(orderedIds[index])))
            .write(
          CountdownsCompanion(
            sortOrder: Value<int>(index),
            updatedAt: Value<DateTime>(now),
          ),
        );
      }
    });
  }

  @override
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.countdowns)
          ..where(($CountdownsTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.countdowns).go();

  List<CountdownItem> _mapAll(List<CountdownRow> rows) =>
      rows.map((CountdownRow row) => row.toDomain()).toList(growable: false);
}
