import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/entities/calendar_category.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../infrastructure/database/app_database.dart';
import 'mappers.dart';

/// [CalendarRepository] 的 Drift 实现。
class DriftCalendarRepository implements CalendarRepository {
  DriftCalendarRepository(this._db, {Clock clock = const SystemClock()})
      : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  @override
  Stream<List<CalendarEvent>> watchAll() {
    final query = _db.select(_db.calendarEvents)
      ..orderBy(<OrderClauseGenerator<$CalendarEventsTable>>[
        ($CalendarEventsTable t) => OrderingTerm.asc(t.startTime),
      ]);
    return query.watch().map(_mapAll);
  }

  @override
  Stream<List<CalendarEvent>> watchRange({
    required DateTime from,
    required DateTime to,
  }) {
    final query = _db.select(_db.calendarEvents)
      ..where(
        ($CalendarEventsTable t) =>
            t.startTime.isSmallerThanValue(to) &
            t.endTime.isBiggerOrEqualValue(from),
      )
      ..orderBy(<OrderClauseGenerator<$CalendarEventsTable>>[
        ($CalendarEventsTable t) => OrderingTerm.asc(t.startTime),
      ]);
    return query.watch().map(_mapAll);
  }

  @override
  Stream<List<CalendarEvent>> watchUpcoming({
    required DateTime after,
    int limit = 5,
  }) {
    final query = _db.select(_db.calendarEvents)
      ..where(
          ($CalendarEventsTable t) => t.startTime.isBiggerOrEqualValue(after))
      ..orderBy(<OrderClauseGenerator<$CalendarEventsTable>>[
        ($CalendarEventsTable t) => OrderingTerm.asc(t.startTime),
      ])
      ..limit(limit);
    return query.watch().map(_mapAll);
  }

  @override
  Future<List<CalendarEvent>> getAll() async {
    final rows = await (_db.select(_db.calendarEvents)
          ..orderBy(<OrderClauseGenerator<$CalendarEventsTable>>[
            ($CalendarEventsTable t) => OrderingTerm.asc(t.startTime),
          ]))
        .get();
    return _mapAll(rows);
  }

  @override
  Future<CalendarEvent?> findById(String id) async {
    final row = await (_db.select(_db.calendarEvents)
          ..where(($CalendarEventsTable t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<int> count() async {
    final countExpression = _db.calendarEvents.id.count();
    final query = _db.selectOnly(_db.calendarEvents)
      ..addColumns(<Expression<Object>>[countExpression]);
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  @override
  Future<void> upsert(CalendarEvent event) async {
    final now = _clock.now();
    final companion = calendarEventToCompanion(event);
    await _db.into(_db.calendarEvents).insertOnConflictUpdate(
          companion.copyWith(updatedAt: Value<DateTime>(now)),
        );
  }

  @override
  Future<void> upsertAll(List<CalendarEvent> events) async {
    if (events.isEmpty) return;
    final now = _clock.now();
    await _db.batch((Batch batch) {
      batch.insertAllOnConflictUpdate(
        _db.calendarEvents,
        events.map(
          (CalendarEvent event) => calendarEventToCompanion(event)
              .copyWith(updatedAt: Value<DateTime>(now)),
        ),
      );
    });
  }

  @override
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.calendarEvents)
          ..where(($CalendarEventsTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.calendarEvents).go();

  List<CalendarEvent> _mapAll(List<CalendarEventRow> rows) => rows
      .map((CalendarEventRow row) => row.toDomain())
      .toList(growable: false);
}

/// [CalendarCategoryRepository] 的 Drift 实现。
class DriftCalendarCategoryRepository implements CalendarCategoryRepository {
  DriftCalendarCategoryRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<CalendarCategory>> watchAll() {
    final query = _db.select(_db.calendarCategories)
      ..orderBy(<OrderClauseGenerator<$CalendarCategoriesTable>>[
        ($CalendarCategoriesTable t) => OrderingTerm.asc(t.sortOrder),
      ]);
    return query.watch().map(_mapAll);
  }

  @override
  Future<List<CalendarCategory>> getAll() async {
    final rows = await (_db.select(_db.calendarCategories)
          ..orderBy(<OrderClauseGenerator<$CalendarCategoriesTable>>[
            ($CalendarCategoriesTable t) => OrderingTerm.asc(t.sortOrder),
          ]))
        .get();
    return _mapAll(rows);
  }

  @override
  Future<void> upsert(CalendarCategory category) => _db
      .into(_db.calendarCategories)
      .insertOnConflictUpdate(calendarCategoryToCompanion(category));

  @override
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.calendarCategories)
          ..where(($CalendarCategoriesTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.calendarCategories).go();

  List<CalendarCategory> _mapAll(List<CalendarCategoryRow> rows) => rows
      .map((CalendarCategoryRow row) => row.toDomain())
      .toList(growable: false);
}
