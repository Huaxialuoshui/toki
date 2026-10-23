import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/repository_providers.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/daily_digest.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/planning_preferences.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/services/recurrence.dart';
import '../../infrastructure/clock_provider.dart';
import '../tasks/task_providers.dart';
import 'daily_planning_service.dart';
import 'plan_progress.dart';
import 'plan_quality_service.dart';
import 'planning_context.dart';

final planVersionsProvider =
    StreamProvider.autoDispose.family<List<DailyPlan>, String>(
  (ref, dayKey) => ref.watch(dailyPlanRepositoryProvider).watchVersions(dayKey),
);

final planItemsProvider =
    StreamProvider.autoDispose.family<List<DailyPlanItem>, String>(
  (ref, planId) => ref.watch(dailyPlanRepositoryProvider).watchItems(planId),
);

@immutable
class PlanDayData {
  const PlanDayData({
    required this.dayKey,
    required this.allPlans,
    required this.tasksById,
    required this.events,
    required this.fixedOccurrences,
    required this.legacyMorningDigest,
    this.currentPlan,
    this.openDraft,
    this.displayPlan,
    this.items = const <DailyPlanItem>[],
    this.progress,
    this.issues = const <PlanQualityIssue>[],
    this.context,
  });

  final String dayKey;
  final List<DailyPlan> allPlans;
  final DailyPlan? currentPlan;
  final DailyPlan? openDraft;
  final DailyPlan? displayPlan;
  final List<DailyPlanItem> items;
  final Map<String, TaskItem> tasksById;
  final List<CalendarEvent> events;
  final List<EventOccurrence> fixedOccurrences;
  final DailyDigest? legacyMorningDigest;
  final PlanProgress? progress;
  final List<PlanQualityIssue> issues;
  final PlanningContext? context;

  bool get hasStructuredPlan => displayPlan != null;
  bool get hasPendingDraft =>
      currentPlan != null &&
      openDraft != null &&
      currentPlan!.id != openDraft!.id;
  bool get hasLegacyOnly => displayPlan == null && legacyMorningDigest != null;
}

final planDayDataProvider =
    FutureProvider.autoDispose.family<PlanDayData, String>((ref, dayKey) async {
  final plans = await ref.watch(planVersionsProvider(dayKey).future);
  final tasks = await ref.watch(allTasksProvider.future);
  final events = await ref.watch(calendarRepositoryProvider).getAll();
  final tasksById = <String, TaskItem>{
    for (final task in tasks) task.id: task,
  };

  DailyPlan? current;
  DailyPlan? draft;
  for (final plan in plans) {
    if (plan.status == PlanStatus.draft && draft == null) draft = plan;
    if ((plan.status == PlanStatus.confirmed ||
            plan.status == PlanStatus.inProgress ||
            plan.status == PlanStatus.completed) &&
        current == null) {
      current = plan;
    }
  }
  final display = current ?? draft;
  final items = display == null
      ? const <DailyPlanItem>[]
      : await ref.watch(planItemsProvider(display.id).future);
  final day = DateTime.parse('${dayKey}T00:00:00');
  final constraints = display?.constraints ?? const PlanningConstraints();
  final context = await ref.watch(planningContextBuilderProvider).build(
        PlanningRequest(
          day: day,
          goalText: constraints.goalText,
          mustDoTaskIds: <String>{
            ...constraints.mustDoTaskIds,
            for (final item in items)
              if (item.taskId != null) item.taskId!,
          }.toList(growable: false),
          availableWindows: constraints.availableWindows,
          blockedWindows: constraints.blockedWindows,
          energy: constraints.energy,
          notes: constraints.notes,
        ),
      );
  final legacy = await ref
      .watch(dailyDigestRepositoryProvider)
      .find(dayKey, DailyDigestKind.morning);

  PlanProgress? progress;
  List<PlanQualityIssue> issues = const <PlanQualityIssue>[];
  if (display != null) {
    progress = PlanProgress.compute(
      plan: display,
      items: items,
      tasksById: tasksById,
    );
    issues = const PlanQualityService().evaluate(
      items: items,
      context: context,
      tasksById: tasksById,
      events: events,
    );
  }
  return PlanDayData(
    dayKey: dayKey,
    allPlans: plans,
    currentPlan: current,
    openDraft: draft,
    displayPlan: display,
    items: items,
    tasksById: tasksById,
    events: events,
    fixedOccurrences: context.fixedOccurrences,
    legacyMorningDigest: legacy,
    progress: progress,
    issues: issues,
    context: context,
  );
});

final todayPlanDataProvider = FutureProvider.autoDispose<PlanDayData>((ref) {
  final now = ref.watch(clockProvider).now();
  return ref.watch(planDayDataProvider(_dayKey(now)).future);
});

final todayPlanDayKeyProvider = Provider.autoDispose<String>((ref) {
  final now = ref.watch(clockProvider).now();
  return _dayKey(now);
});

final planningPreferencesProvider =
    FutureProvider.autoDispose<PlanningPreferences>(
  (ref) => ref.watch(planningPreferencesRepositoryProvider).load(),
);

String _dayKey(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
