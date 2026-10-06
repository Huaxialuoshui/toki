import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/entities/theme_config.dart';
import '../../domain/repositories/theme_repository.dart';
import '../../infrastructure/database/app_database.dart';
import 'mappers.dart';

/// [ThemeRepository] 的 Drift 实现：只保存用户自建 / 导入的主题。
class DriftThemeRepository implements ThemeRepository {
  DriftThemeRepository(this._db, {Clock clock = const SystemClock()})
      : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  @override
  Stream<List<ThemeConfig>> watchAll() => (_db.select(_db.themeConfigs)
        ..orderBy(<OrderClauseGenerator<$ThemeConfigsTable>>[
          ($ThemeConfigsTable t) => OrderingTerm.asc(t.name),
        ]))
      .watch()
      .map(_mapAll);

  @override
  Future<List<ThemeConfig>> getAll() async {
    final rows = await (_db.select(_db.themeConfigs)
          ..orderBy(<OrderClauseGenerator<$ThemeConfigsTable>>[
            ($ThemeConfigsTable t) => OrderingTerm.asc(t.name),
          ]))
        .get();
    return _mapAll(rows);
  }

  @override
  Future<ThemeConfig?> findById(String id) async {
    final row = await (_db.select(_db.themeConfigs)
          ..where(($ThemeConfigsTable t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(ThemeConfig config) async {
    final existing = await (_db.select(_db.themeConfigs)
          ..where(($ThemeConfigsTable t) => t.id.equals(config.id)))
        .getSingleOrNull();
    final now = _clock.now();
    await _db.into(_db.themeConfigs).insertOnConflictUpdate(
          themeConfigToCompanion(
            config,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.themeConfigs)
          ..where(($ThemeConfigsTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.themeConfigs).go();

  List<ThemeConfig> _mapAll(List<ThemeConfigRow> rows) =>
      rows.map((ThemeConfigRow row) => row.toDomain()).toList(growable: false);
}
