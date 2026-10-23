import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/errors/planning_exception.dart';
import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/daily_plan_repository.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/services/transaction_runner.dart';
import '../../infrastructure/clock_provider.dart';
import '../calendar/calendar_actions.dart';
import 'daily_planning_service.dart';
import 'plan_validation_service.dart';
import 'planning_context.dart';
import 'planning_result_parser.dart';

enum PlanApplyAction { createTask, matchTask, createEvent, scheduleTask }

@immutable
class PlanApplyChange {
  const PlanApplyChange({
    required this.itemId,
    required this.title,
    required this.action,
    this.taskId,
    this.start,
    this.end,
  });

  final String itemId;
  final String title;
  final PlanApplyAction action;
  final String? taskId;
  final DateTime? start;
  final DateTime? end;
}

@immutable
class PlanApplyPreview {
  const PlanApplyPreview({
    required this.plan,
    required this.eligibleItemIds,
    required this.skippedItemIds,
    required this.changes,
    required this.skippedReasons,
    required this.conflicts,
    required this.isStale,
  });

  final DailyPlan plan;
  final List<String> eligibleItemIds;
  final List<String> skippedItemIds;
  final List<PlanApplyChange> changes;
  final Map<String, String> skippedReasons;
  final List<String> conflicts;
  final bool isStale;

  bool get canApply => !isStale && eligibleItemIds.isNotEmpty;
}

@immutable
class PlanApplyResult {
  const PlanApplyResult({
    required this.appliedItemIds,
    required this.skippedItemIds,
    required this.failedItemIds,
    required this.createdTaskCount,
    required this.createdEventCount,
    required this.messages,
  });

  final List<String> appliedItemIds;
  final List<String> skippedItemIds;
  final List<String> failedItemIds;
  final int createdTaskCount;
  final int createdEventCount;
  final List<String> messages;

  bool get isSuccess => failedItemIds.isEmpty;
}

class PlanActions {
  PlanActions({
    required DailyPlanRepository plans,
    required TaskRepository tasks,
    required CalendarRepository events,
    required CalendarActions calendarActions,
    required PlanningContextBuilder contextBuilder,
    required PlanValidationService validator,
    required TransactionRunner transactionRunner,
    required Clock clock,
  })  : _plans = plans,
        _tasks = tasks,
        _events = events,
        _calendarActions = calendarActions,
        _contextBuilder = contextBuilder,
        _validator = validator,
        _transactionRunner = transactionRunner,
        _clock = clock;

  final DailyPlanRepository _plans;
  final TaskRepository _tasks;
  final CalendarRepository _events;
  final CalendarActions _calendarActions;
  final PlanningContextBuilder _contextBuilder;
  final PlanValidationService _validator;
  final TransactionRunner _transactionRunner;
  final Clock _clock;

  Future<PlanApplyPreview> previewApply({
    required String planId,
    required Set<String> itemIds,
  }) async {
    final plan = await _plans.findById(planId);
    if (plan == null) {
      throw const PlanningException(PlanningErrorCode.planStale);
    }
    if (plan.status == PlanStatus.cancelled ||
        plan.status == PlanStatus.completed ||
        plan.status == PlanStatus.superseded) {
      throw const PlanningException(PlanningErrorCode.planStale);
    }
    final latestDraft = await _plans.findLatestDraft(plan.dayKey);
    final stale = plan.status == PlanStatus.draft &&
        latestDraft != null &&
        latestDraft.id != plan.id;
    final allItems = await _plans.itemsForPlan(planId);
    final selected = <DailyPlanItem>[];
    final skipped = <String>[];
    final reasons = <String, String>{};
    for (final item in allItems) {
      if (!itemIds.contains(item.id)) continue;
      final appliedEvent = item.appliedEventId == null
          ? null
          : await _events.findById(item.appliedEventId!);
      if (item.appliedEventId != null && appliedEvent == null) {
        skipped.add(item.id);
        reasons[item.id] = 'detached';
        continue;
      }
      if (item.status == PlanItemStatus.applied) {
        skipped.add(item.id);
        reasons[item.id] = 'already_applied';
        continue;
      }
      if (item.status != PlanItemStatus.proposed) {
        skipped.add(item.id);
        reasons[item.id] = 'not_proposed';
        continue;
      }
      if (appliedEvent != null) {
        skipped.add(item.id);
        reasons[item.id] = 'already_applied';
        continue;
      }
      selected.add(item);
    }

    if (stale) {
      return PlanApplyPreview(
        plan: plan,
        eligibleItemIds: const <String>[],
        skippedItemIds: skipped,
        changes: const <PlanApplyChange>[],
        skippedReasons: reasons,
        conflicts: const <String>['计划已被新的草稿取代，请重新打开最新版本'],
        isStale: true,
      );
    }

    final context = await _contextFor(plan, selected);
    final parsedItems = <ParsedPlanItem>[
      for (var index = 0; index < selected.length; index++)
        _toParsedItem(selected[index], index),
    ];
    final validation = _validator.validate(
      ParsedPlanningResult(
        summary: plan.summary,
        goals: plan.goals,
        items: parsedItems,
        unscheduledTaskIds: const <String>[],
        conflicts: const <String>[],
        notes: const <String>[],
        diagnostics: const <Map<String, Object?>>[],
      ),
      context,
    );
    final validIndexes = <int>{
      for (final item in validation.items) item.index,
    };
    final eligible = <String>[];
    final changes = <PlanApplyChange>[];
    for (var index = 0; index < selected.length; index++) {
      final item = selected[index];
      if (!validIndexes.contains(index)) {
        skipped.add(item.id);
        reasons[item.id] = 'conflict';
        continue;
      }
      eligible.add(item.id);
      if (item.taskId == null) {
        changes.add(
          PlanApplyChange(
            itemId: item.id,
            title: item.titleSnapshot,
            action: PlanApplyAction.createTask,
            start: item.startAt,
            end: item.endAt,
          ),
        );
      } else if (item.startAt != null && item.endAt != null) {
        changes.add(
          PlanApplyChange(
            itemId: item.id,
            title: item.titleSnapshot,
            action: PlanApplyAction.scheduleTask,
            taskId: item.taskId,
            start: item.startAt,
            end: item.endAt,
          ),
        );
      } else {
        changes.add(
          PlanApplyChange(
            itemId: item.id,
            title: item.titleSnapshot,
            action: PlanApplyAction.matchTask,
            taskId: item.taskId,
          ),
        );
      }
    }
    return PlanApplyPreview(
      plan: plan,
      eligibleItemIds: eligible,
      skippedItemIds: skipped.toSet().toList(growable: false),
      changes: changes,
      skippedReasons: reasons,
      conflicts: validation.conflicts,
      isStale: false,
    );
  }

  Future<PlanApplyResult> apply({
    required String planId,
    required Set<String> itemIds,
  }) async {
    final preflight = await previewApply(planId: planId, itemIds: itemIds);
    if (preflight.isStale) {
      throw const PlanningException(PlanningErrorCode.planStale);
    }
    if (preflight.eligibleItemIds.isEmpty) {
      return PlanApplyResult(
        appliedItemIds: const <String>[],
        skippedItemIds: preflight.skippedItemIds,
        failedItemIds: const <String>[],
        createdTaskCount: 0,
        createdEventCount: 0,
        messages: const <String>['没有需要应用的新条目'],
      );
    }

    try {
      final counts = await _transactionRunner.run<_ApplyCounts>(() async {
        final live = await previewApply(planId: planId, itemIds: itemIds);
        if (live.isStale) {
          throw const PlanningException(PlanningErrorCode.planStale);
        }
        final missing = preflight.eligibleItemIds
            .where((String id) => !live.eligibleItemIds.contains(id))
            .toList(growable: false);
        if (missing.isNotEmpty) {
          throw const PlanningException(PlanningErrorCode.planConflict);
        }

        final now = _clock.now();
        var createdTasks = 0;
        var createdEvents = 0;
        final applied = <String>[];
        final allItems = await _plans.itemsForPlan(planId);
        for (final itemId in live.eligibleItemIds) {
          var item = allItems.firstWhere((DailyPlanItem i) => i.id == itemId);
          final taskId = item.taskId ?? 'task-from-plan-item-${item.id}';
          var task = await _tasks.findById(taskId);
          if (task == null) {
            if (item.source != PlanItemSource.newTask) {
              throw const PlanningException(PlanningErrorCode.taskMissing);
            }
            task = TaskItem(
              id: taskId,
              title: item.titleSnapshot,
              description: item.descriptionSnapshot,
              priority: item.priority,
              dueAt: null,
              estimatedMinutes: item.estimateMinutes,
              status: TaskStatus.open,
              source: TaskSource.ai,
              postponeCount: 0,
              createdAt: now,
              updatedAt: now,
            );
            await _tasks.upsert(task);
            createdTasks++;
          } else if (!task.isActive) {
            throw const PlanningException(PlanningErrorCode.planConflict);
          }

          String? appliedEventId;
          if (item.startAt != null && item.endAt != null) {
            final eventId = 'event-from-plan-item-${item.id}';
            final existingEvent = await _events.findById(eventId);
            if (existingEvent != null) {
              if (existingEvent.taskId != taskId) {
                throw const PlanningException(PlanningErrorCode.planConflict);
              }
              appliedEventId = eventId;
            } else {
              final event = CalendarEvent(
                id: eventId,
                title: task.title,
                description: item.reason,
                startTime: item.startAt!,
                endTime: item.endAt!,
                taskId: taskId,
                status: EventStatus.scheduled,
                createdAt: now,
                updatedAt: now,
              );
              await _calendarActions.saveEvent(event);
              createdEvents++;
              appliedEventId = eventId;
            }
          }

          item = item.copyWith(
            taskId: taskId,
            status: PlanItemStatus.applied,
            appliedEventId: appliedEventId,
            clearAppliedEventId: appliedEventId == null,
            appliedAt: now,
            clearAppliedAt: appliedEventId == null,
            clearFailureReason: true,
            updatedAt: now,
          );
          await _plans.upsertItem(item);
          applied.add(itemId);
        }

        final plan = (await _plans.findById(planId))!;
        final appliedIds = applied.toSet();
        final inProgress = allItems.any(
          (DailyPlanItem item) =>
              appliedIds.contains(item.id) &&
              item.startAt != null &&
              !item.startAt!.isAfter(now),
        );
        await _plans.updatePlan(
          plan.copyWith(
            status: inProgress ? PlanStatus.inProgress : PlanStatus.confirmed,
            confirmedAt: plan.confirmedAt ?? now,
            updatedAt: now,
          ),
        );
        await _plans.markOtherPlansSuperseded(
          dayKey: plan.dayKey,
          exceptPlanId: planId,
          updatedAt: now,
        );
        return _ApplyCounts(
          applied: applied,
          createdTasks: createdTasks,
          createdEvents: createdEvents,
        );
      });
      return PlanApplyResult(
        appliedItemIds: counts.applied,
        skippedItemIds: preflight.skippedItemIds,
        failedItemIds: const <String>[],
        createdTaskCount: counts.createdTasks,
        createdEventCount: counts.createdEvents,
        messages: const <String>[],
      );
    } on PlanningException {
      rethrow;
    } on Object catch (error) {
      throw PlanningException(
        PlanningErrorCode.databaseWriteFailed,
        cause: error,
      );
    }
  }

  Future<void> skipItem(String planId, String itemId) async {
    final plan = await _plans.findById(planId);
    if (plan == null || plan.status != PlanStatus.draft) {
      throw const PlanningException(PlanningErrorCode.planStale);
    }
    final items = await _plans.itemsForPlan(planId);
    final item = items.firstWhere((DailyPlanItem i) => i.id == itemId);
    if (item.status != PlanItemStatus.proposed) return;
    await _plans.upsertItem(
      item.copyWith(
        status: PlanItemStatus.skipped,
        updatedAt: _clock.now(),
      ),
    );
  }

  Future<void> updateDraftItemTime({
    required String planId,
    required String itemId,
    required DateTime start,
    required DateTime end,
  }) async {
    final plan = await _plans.findById(planId);
    if (plan == null || plan.status != PlanStatus.draft) {
      throw const PlanningException(PlanningErrorCode.planStale);
    }
    final items = await _plans.itemsForPlan(planId);
    final target = items.firstWhere((DailyPlanItem i) => i.id == itemId);
    if (target.status != PlanItemStatus.proposed) {
      throw const PlanningException(PlanningErrorCode.validationFailed);
    }
    final proposed = items
        .where((DailyPlanItem i) => i.status == PlanItemStatus.proposed)
        .toList(growable: false);
    final context = await _contextFor(plan, proposed);
    final parsed = <ParsedPlanItem>[
      for (var index = 0; index < proposed.length; index++)
        _toParsedItem(
          proposed[index],
          index,
          overrideStart: proposed[index].id == itemId ? start : null,
          overrideEnd: proposed[index].id == itemId ? end : null,
        ),
    ];
    final validation = _validator.validate(
      ParsedPlanningResult(
        summary: plan.summary,
        goals: plan.goals,
        items: parsed,
        unscheduledTaskIds: const <String>[],
        conflicts: const <String>[],
        notes: const <String>[],
        diagnostics: const <Map<String, Object?>>[],
      ),
      context,
    );
    final targetIndex = proposed.indexWhere(
      (DailyPlanItem item) => item.id == itemId,
    );
    ParsedPlanItem? validated;
    for (final item in validation.items) {
      if (item.index == targetIndex) {
        validated = item;
        break;
      }
    }
    if (validated == null) {
      throw PlanningException(
        PlanningErrorCode.validationFailed,
        message: validation.conflicts.join('；'),
      );
    }
    await _plans.upsertItem(
      target.copyWith(
        startAt: validated.startAt,
        endAt: validated.endAt,
        estimateMinutes: validated.estimatedMinutes,
        updatedAt: _clock.now(),
      ),
    );
  }

  Future<void> cancelPlan(String planId) async {
    final plan = await _plans.findById(planId);
    if (plan == null) {
      throw const PlanningException(PlanningErrorCode.planStale);
    }
    if (plan.status == PlanStatus.cancelled ||
        plan.status == PlanStatus.superseded) {
      return;
    }
    await _plans.updatePlan(
      plan.copyWith(
        status: PlanStatus.cancelled,
        updatedAt: _clock.now(),
      ),
    );
  }

  Future<void> completeDay(String planId) async {
    final plan = await _plans.findById(planId);
    if (plan == null) {
      throw const PlanningException(PlanningErrorCode.planStale);
    }
    final now = _clock.now();
    await _plans.updatePlan(
      plan.copyWith(
        status: PlanStatus.completed,
        completedAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<PlanningContext> _contextFor(
    DailyPlan plan,
    List<DailyPlanItem> items,
  ) {
    final day = DateTime.parse('${plan.dayKey}T00:00:00');
    final taskIds = items
        .map((DailyPlanItem item) => item.taskId)
        .whereType<String>()
        .toList(growable: false);
    return _contextBuilder.build(
      PlanningRequest(
        day: day,
        goalText: plan.constraints.goalText,
        mustDoTaskIds: <String>{
          ...plan.constraints.mustDoTaskIds,
          ...taskIds,
        }.toList(growable: false),
        availableWindows: plan.constraints.availableWindows,
        blockedWindows: plan.constraints.blockedWindows,
        energy: plan.constraints.energy,
        notes: plan.constraints.notes,
      ),
    );
  }

  static ParsedPlanItem _toParsedItem(
    DailyPlanItem item,
    int index, {
    DateTime? overrideStart,
    DateTime? overrideEnd,
  }) {
    return ParsedPlanItem(
      taskId: item.taskId,
      title: item.titleSnapshot,
      description: item.descriptionSnapshot,
      startAt: overrideStart ?? item.startAt,
      endAt: overrideEnd ?? item.endAt,
      estimatedMinutes: item.estimateMinutes,
      priority: item.priority,
      reason: item.reason,
      source: item.source,
      sourceEventId: item.sourceEventId,
      index: index,
    );
  }
}

class _ApplyCounts {
  const _ApplyCounts({
    required this.applied,
    required this.createdTasks,
    required this.createdEvents,
  });

  final List<String> applied;
  final int createdTasks;
  final int createdEvents;
}

final planActionsProvider = Provider<PlanActions>(
  (ref) => PlanActions(
    plans: ref.watch(dailyPlanRepositoryProvider),
    tasks: ref.watch(taskRepositoryProvider),
    events: ref.watch(calendarRepositoryProvider),
    calendarActions: ref.watch(calendarActionsProvider),
    contextBuilder: ref.watch(planningContextBuilderProvider),
    validator: const PlanValidationService(),
    transactionRunner: ref.watch(transactionRunnerProvider),
    clock: ref.watch(clockProvider),
  ),
);
