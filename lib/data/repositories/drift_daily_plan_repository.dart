import 'package:drift/drift.dart';

import '../../core/clock.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/repositories/daily_plan_repository.dart';
import '../../infrastructure/database/app_database.dart';
import 'mappers.dart';

class DriftDailyPlanRepository implements DailyPlanRepository {
  DriftDailyPlanRepository(
    this._db, {
    Clock clock = const SystemClock(),
  }) : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<DailyPlan?> findById(String id) async {
    final row = await (_db.select(_db.dailyPlans)
          ..where(($DailyPlansTable t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<DailyPlan?> findLatestDraft(String dayKey) async {
    final row = await (_db.select(_db.dailyPlans)
          ..where(
            ($DailyPlansTable t) =>
                t.dayKey.equals(dayKey) & t.status.equals('draft'),
          )
          ..orderBy(<OrderClauseGenerator<$DailyPlansTable>>[
            ($DailyPlansTable t) => OrderingTerm.desc(t.revision),
          ])
          ..limit(1))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<DailyPlan?> findCurrent(String dayKey) async {
    final row = await (_db.select(_db.dailyPlans)
          ..where(
            ($DailyPlansTable t) =>
                t.dayKey.equals(dayKey) &
                t.status.isIn(<String>[
                  PlanStatus.confirmed.name,
                  PlanStatus.inProgress.name,
                  PlanStatus.completed.name,
                ]),
          )
          ..orderBy(<OrderClauseGenerator<$DailyPlansTable>>[
            ($DailyPlansTable t) => OrderingTerm.desc(t.revision),
          ])
          ..limit(1))
        .getSingleOrNull();
    return row?.toDomain();
  }

  @override
  Future<List<DailyPlan>> findVersions(String dayKey) async {
    final rows = await (_db.select(_db.dailyPlans)
          ..where(($DailyPlansTable t) => t.dayKey.equals(dayKey))
          ..orderBy(<OrderClauseGenerator<$DailyPlansTable>>[
            ($DailyPlansTable t) => OrderingTerm.desc(t.revision),
          ]))
        .get();
    return rows.map((DailyPlanRow row) => row.toDomain()).toList();
  }

  @override
  Stream<List<DailyPlan>> watchVersions(String dayKey) {
    final query = _db.select(_db.dailyPlans)
      ..where(($DailyPlansTable t) => t.dayKey.equals(dayKey))
      ..orderBy(<OrderClauseGenerator<$DailyPlansTable>>[
        ($DailyPlansTable t) => OrderingTerm.desc(t.revision),
      ]);
    return query.watch().map(
          (List<DailyPlanRow> rows) =>
              rows.map((DailyPlanRow row) => row.toDomain()).toList(),
        );
  }

  @override
  Future<List<DailyPlanItem>> itemsForPlan(String planId) async {
    final rows = await (_db.select(_db.dailyPlanItems)
          ..where(($DailyPlanItemsTable t) => t.planId.equals(planId))
          ..orderBy(<OrderClauseGenerator<$DailyPlanItemsTable>>[
            ($DailyPlanItemsTable t) => OrderingTerm.asc(t.sortOrder),
          ]))
        .get();
    return rows.map((DailyPlanItemRow row) => row.toDomain()).toList();
  }

  @override
  Stream<List<DailyPlanItem>> watchItems(String planId) {
    final query = _db.select(_db.dailyPlanItems)
      ..where(($DailyPlanItemsTable t) => t.planId.equals(planId))
      ..orderBy(<OrderClauseGenerator<$DailyPlanItemsTable>>[
        ($DailyPlanItemsTable t) => OrderingTerm.asc(t.sortOrder),
      ]);
    return query.watch().map(
          (List<DailyPlanItemRow> rows) =>
              rows.map((DailyPlanItemRow row) => row.toDomain()).toList(),
        );
  }

  @override
  Future<DailyPlan> saveDraft(
    DailyPlan draft,
    List<DailyPlanItem> items,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await _db.transaction(() async {
          final now = _clock.now();
          final versions = await (_db.select(_db.dailyPlans)
                ..where(
                  ($DailyPlansTable t) => t.dayKey.equals(draft.dayKey),
                ))
              .get();
          final nextRevision = versions.isEmpty
              ? 1
              : versions
                      .map((DailyPlanRow row) => row.revision)
                      .reduce((int a, int b) => a > b ? a : b) +
                  1;

          // 只废弃开放草稿；确认 / 执行中计划必须等新计划成功应用后再变。
          await (_db.update(_db.dailyPlans)
                ..where(
                  ($DailyPlansTable t) =>
                      t.dayKey.equals(draft.dayKey) &
                      t.status.equals(PlanStatus.draft.name),
                ))
              .write(
            DailyPlansCompanion(
              status: Value<String>(PlanStatus.superseded.name),
              updatedAt: Value<DateTime>(now),
            ),
          );

          final saved = draft.copyWith(
            revision: nextRevision,
            status: PlanStatus.draft,
            createdAt: draft.createdAt,
            updatedAt: now,
          );
          await _db.into(_db.dailyPlans).insert(dailyPlanToCompanion(saved));

          if (items.isNotEmpty) {
            await _db.batch((Batch batch) {
              batch.insertAll(
                _db.dailyPlanItems,
                items
                    .map(
                      (DailyPlanItem item) =>
                          dailyPlanItemToCompanion(item.copyWith(
                        planId: saved.id,
                        updatedAt: now,
                      )),
                    )
                    .toList(growable: false),
              );
            });
          }
          return saved;
        });
      } catch (error) {
        lastError = error;
        if (!'$error'.contains('UNIQUE constraint failed')) rethrow;
      }
    }
    throw StateError('保存计划草稿时 revision 冲突：$lastError');
  }

  @override
  Future<void> updatePlan(DailyPlan plan) async {
    await (_db.update(_db.dailyPlans)
          ..where(($DailyPlansTable t) => t.id.equals(plan.id)))
        .write(dailyPlanToCompanion(plan));
  }

  @override
  Future<void> upsertItem(DailyPlanItem item) =>
      _db.into(_db.dailyPlanItems).insertOnConflictUpdate(
            dailyPlanItemToCompanion(item),
          );

  @override
  Future<void> markOtherPlansSuperseded({
    required String dayKey,
    required String exceptPlanId,
    required DateTime updatedAt,
  }) async {
    await (_db.update(_db.dailyPlans)
          ..where(
            ($DailyPlansTable t) =>
                t.dayKey.equals(dayKey) &
                t.id.equals(exceptPlanId).not() &
                t.status.isIn(<String>[
                  PlanStatus.confirmed.name,
                  PlanStatus.inProgress.name,
                ]),
          ))
        .write(
      DailyPlansCompanion(
        status: Value<String>(PlanStatus.superseded.name),
        updatedAt: Value<DateTime>(updatedAt),
      ),
    );
  }

  @override
  Future<void> deleteAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.dailyPlanItems).go();
      await _db.delete(_db.dailyPlans).go();
    });
  }
}
