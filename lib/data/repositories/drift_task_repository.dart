import 'package:drift/drift.dart';

import '../../domain/entities/task_item.dart';
import '../../domain/repositories/task_repository.dart';
import '../../infrastructure/database/app_database.dart';
import 'mappers.dart';

class DriftTaskRepository implements TaskRepository {
  DriftTaskRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<TaskItem>> watchActive() =>
      _activeQuery().watch().map(_sortActive);

  @override
  Stream<List<TaskItem>> watchAll({bool includeArchived = false}) {
    final query = _db.select(_db.tasks);
    if (!includeArchived) {
      query.where(($TasksTable t) => t.archivedAt.isNull());
    }
    return query.watch().map(_mapAll);
  }

  @override
  Stream<List<TaskItem>> watchCompleted() {
    final query = _db.select(_db.tasks)
      ..where(
        ($TasksTable t) =>
            t.archivedAt.isNull() & t.status.equalsValue(TaskStatus.completed),
      )
      ..orderBy(<OrderClauseGenerator<$TasksTable>>[
        ($TasksTable t) => OrderingTerm.desc(t.completedAt),
        ($TasksTable t) => OrderingTerm.desc(t.updatedAt),
      ]);
    return query.watch().map(_mapAll);
  }

  @override
  Stream<List<TaskItem>> watchArchived() {
    final query = _db.select(_db.tasks)
      ..where(($TasksTable t) => t.archivedAt.isNotNull())
      ..orderBy(<OrderClauseGenerator<$TasksTable>>[
        ($TasksTable t) => OrderingTerm.desc(t.archivedAt),
      ]);
    return query.watch().map(_mapAll);
  }

  @override
  Future<List<TaskItem>> getActive() async =>
      _sortActive(await _activeQuery().get());

  @override
  Future<List<TaskItem>> getAll({bool includeArchived = false}) async {
    final query = _db.select(_db.tasks);
    if (!includeArchived) {
      query.where(($TasksTable t) => t.archivedAt.isNull());
    }
    final rows = await query.get();
    return _mapAll(rows);
  }

  @override
  Future<TaskItem?> findById(String id) async {
    final row = await (_db.select(_db.tasks)
          ..where(($TasksTable t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<List<TaskItem>> getOverdue(DateTime now) async {
    final active = await getActive();
    return active
        .where((TaskItem task) => task.dueAt?.isBefore(now) ?? false)
        .toList(growable: false);
  }

  @override
  Future<List<TaskItem>> getDueSoon(DateTime now, DateTime until) async {
    final active = await getActive();
    return active.where((TaskItem task) {
      final due = task.dueAt;
      if (due == null) return false;
      return !due.isBefore(now) && !due.isAfter(until);
    }).toList(growable: false);
  }

  @override
  Future<int> count({bool includeArchived = false}) async {
    final countExpression = _db.tasks.id.count();
    final query = _db.selectOnly(_db.tasks)
      ..addColumns(<Expression<Object>>[countExpression]);
    if (!includeArchived) {
      query.where(_db.tasks.archivedAt.isNull());
    }
    final row = await query.getSingle();
    return row.read(countExpression) ?? 0;
  }

  @override
  Future<void> upsert(TaskItem task) =>
      _db.into(_db.tasks).insertOnConflictUpdate(taskToCompanion(task));

  @override
  Future<void> upsertAll(List<TaskItem> tasks) async {
    if (tasks.isEmpty) return;
    await _db.batch((Batch batch) {
      batch.insertAllOnConflictUpdate(
        _db.tasks,
        tasks.map(taskToCompanion),
      );
    });
  }

  @override
  Future<void> deleteById(String id) async {
    await (_db.delete(_db.tasks)..where(($TasksTable t) => t.id.equals(id)))
        .go();
  }

  @override
  Future<void> deleteAll() => _db.delete(_db.tasks).go();

  SimpleSelectStatement<$TasksTable, TaskRow> _activeQuery() {
    return _db.select(_db.tasks)
      ..where(
        ($TasksTable t) =>
            t.archivedAt.isNull() &
            (t.status.equalsValue(TaskStatus.open) |
                t.status.equalsValue(TaskStatus.blocked)),
      );
  }

  List<TaskItem> _sortActive(List<TaskRow> rows) {
    final tasks = _mapAll(rows);
    tasks.sort((TaskItem a, TaskItem b) {
      final statusRank = _statusRank(a.status).compareTo(_statusRank(b.status));
      if (statusRank != 0) return statusRank;

      final priorityRank =
          taskPriorityRank(a.priority).compareTo(taskPriorityRank(b.priority));
      if (priorityRank != 0) return priorityRank;

      final aDue = a.dueAt;
      final bDue = b.dueAt;
      if (aDue == null && bDue != null) return 1;
      if (aDue != null && bDue == null) return -1;
      if (aDue != null && bDue != null) {
        final dueRank = aDue.compareTo(bDue);
        if (dueRank != 0) return dueRank;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return tasks;
  }

  static int _statusRank(TaskStatus status) => switch (status) {
        TaskStatus.blocked => 1,
        _ => 0,
      };

  List<TaskItem> _mapAll(List<TaskRow> rows) =>
      rows.map((TaskRow row) => row.toDomain()).toList(growable: true);
}
