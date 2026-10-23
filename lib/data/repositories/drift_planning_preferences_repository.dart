import '../../core/clock.dart';
import '../../domain/entities/planning_preferences.dart';
import '../../domain/repositories/planning_preferences_repository.dart';
import '../../infrastructure/database/app_database.dart';
import 'mappers.dart';

class DriftPlanningPreferencesRepository
    implements PlanningPreferencesRepository {
  DriftPlanningPreferencesRepository(
    this._db, {
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  static const String _rowId = 'default';

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<PlanningPreferences> load() async {
    final row = await (_db.select(_db.planningPreferenceSettings)
          ..where(
            ($PlanningPreferenceSettingsTable t) => t.id.equals(_rowId),
          ))
        .getSingleOrNull();
    if (row != null) return row.toDomain();

    final now = _clock.now();
    return PlanningPreferences(createdAt: now, updatedAt: now);
  }

  @override
  Future<void> save(PlanningPreferences preferences) async {
    final existing = await (_db.select(_db.planningPreferenceSettings)
          ..where(
            ($PlanningPreferenceSettingsTable t) => t.id.equals(_rowId),
          ))
        .getSingleOrNull();
    final now = _clock.now();
    final normalized = preferences.copyWith(
      createdAt: existing?.createdAt ?? preferences.createdAt,
      updatedAt: now,
    );
    await _db
        .into(_db.planningPreferenceSettings)
        .insertOnConflictUpdate(planningPreferencesToCompanion(normalized));
  }

  @override
  Future<void> clear() async {
    await (_db.delete(_db.planningPreferenceSettings)
          ..where(($PlanningPreferenceSettingsTable t) => t.id.equals(_rowId)))
        .go();
  }
}
