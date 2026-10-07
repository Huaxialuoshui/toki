import 'package:drift/drift.dart';

import '../../domain/entities/daily_digest.dart';
import '../../domain/repositories/daily_digest_repository.dart';
import '../../infrastructure/database/app_database.dart';

/// [DailyDigestRepository] 的 Drift 实现。
class DriftDailyDigestRepository implements DailyDigestRepository {
  DriftDailyDigestRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<DailyDigest>> findByDay(String dayKey) async {
    final rows = await (_db.select(_db.dailyDigests)
          ..where(($DailyDigestsTable t) => t.dayKey.equals(dayKey))
          ..orderBy(<OrderClauseGenerator<$DailyDigestsTable>>[
            ($DailyDigestsTable t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<DailyDigest?> find(String dayKey, DailyDigestKind kind) async {
    final row = await (_db.select(_db.dailyDigests)
          ..where(
            ($DailyDigestsTable t) =>
                t.dayKey.equals(dayKey) & t.kind.equals(kind.name),
          )
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Stream<List<DailyDigest>> watchRecent({int limit = 20}) =>
      (_db.select(_db.dailyDigests)
            ..orderBy(<OrderClauseGenerator<$DailyDigestsTable>>[
              ($DailyDigestsTable t) => OrderingTerm.desc(t.createdAt),
            ])
            ..limit(limit))
          .watch()
          .map(
            (List<DailyDigestRow> rows) =>
                rows.map(_map).toList(growable: false),
          );

  @override
  Future<void> upsert(DailyDigest digest) =>
      _db.into(_db.dailyDigests).insertOnConflictUpdate(
            DailyDigestsCompanion(
              id: Value<String>(digest.id),
              kind: Value<String>(digest.kind.name),
              dayKey: Value<String>(digest.dayKey),
              content: Value<String>(digest.content),
              createdAt: Value<DateTime>(digest.createdAt),
            ),
          );

  @override
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.dailyDigests)
          ..where(($DailyDigestsTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.dailyDigests).go();

  DailyDigest _map(DailyDigestRow row) => DailyDigest(
        id: row.id,
        kind: DailyDigestKind.values.firstWhere(
          (DailyDigestKind kind) => kind.name == row.kind,
          orElse: () => DailyDigestKind.morning,
        ),
        dayKey: row.dayKey,
        content: row.content,
        createdAt: row.createdAt,
      );
}
