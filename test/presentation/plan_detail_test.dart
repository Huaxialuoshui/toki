import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/planning/plan_progress.dart';
import 'package:toki/application/planning/plan_providers.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/domain/services/recurrence.dart';

import '../helpers/test_app.dart';

void main() {
  const Size surface = Size(1400, 1400);

  PlanDayData data({bool withPlan = true}) {
    final task = TaskItem(
      id: 'task-1',
      title: 'Write report',
      priority: TaskPriority.high,
      status: TaskStatus.open,
      source: TaskSource.manual,
      postponeCount: 0,
      createdAt: kTestNow,
      updatedAt: kTestNow,
    );
    final plan = DailyPlan(
      id: 'plan-1',
      dayKey: '2026-10-06',
      revision: 1,
      status: PlanStatus.draft,
      summary: 'Focus on the report',
      goals: const <PlanGoal>[
        PlanGoal(title: 'Finish report', priority: TaskPriority.high),
      ],
      constraints: const PlanningConstraints(),
      generationSource: PlanGenerationSource.manual,
      createdAt: kTestNow,
      updatedAt: kTestNow,
    );
    final item = DailyPlanItem(
      id: 'item-1',
      planId: 'plan-1',
      taskId: 'task-1',
      titleSnapshot: 'Write report',
      startAt: DateTime(2026, 10, 6, 11),
      endAt: DateTime(2026, 10, 6, 12),
      estimateMinutes: 60,
      priority: TaskPriority.high,
      reason: 'Deadline soon',
      source: PlanItemSource.existingTask,
      status: PlanItemStatus.proposed,
      sortOrder: 0,
      createdAt: kTestNow,
      updatedAt: kTestNow,
    );
    final event = CalendarEvent(
      id: 'fixed',
      title: 'Team sync',
      startTime: DateTime(2026, 10, 6, 13),
      endTime: DateTime(2026, 10, 6, 14),
      createdAt: kTestNow,
      updatedAt: kTestNow,
    );
    final tasks = <String, TaskItem>{task.id: task};
    final items = withPlan ? <DailyPlanItem>[item] : const <DailyPlanItem>[];
    return PlanDayData(
      dayKey: '2026-10-06',
      allPlans: withPlan ? <DailyPlan>[plan] : const <DailyPlan>[],
      currentPlan: null,
      openDraft: withPlan ? plan : null,
      displayPlan: withPlan ? plan : null,
      items: items,
      tasksById: tasks,
      events: <CalendarEvent>[event],
      fixedOccurrences: <EventOccurrence>[
        EventOccurrence(
          event: event,
          start: event.startTime,
          end: event.endTime,
        ),
      ],
      legacyMorningDigest: null,
      progress: withPlan
          ? PlanProgress.compute(
              plan: plan,
              items: items,
              tasksById: tasks,
            )
          : null,
    );
  }

  tokiWidgetTest('首页展示结构化计划并进入详情', (tester) async {
    final fixture = data();
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      extraOverrides: <Override>[
        todayPlanDataProvider.overrideWith((Ref ref) async => fixture),
        planItemsProvider('plan-1').overrideWith(
          (Ref ref) => Stream<List<DailyPlanItem>>.value(fixture.items),
        ),
      ],
    );

    expect(find.text('Focus on the report'), findsOneWidget);
    expect(find.text('Needs review'), findsOneWidget);
    expect(find.text('1:00 PM Team sync'), findsOneWidget);

    final viewAll = find.text('View full plan').first;
    await tester.ensureVisible(viewAll);
    await tester.pumpAndSettle();
    await tester.tap(viewAll);
    await tester.pumpAndSettle();

    expect(find.text('Finish report'), findsOneWidget);
    expect(find.text('Team sync'), findsOneWidget);
    expect(find.text('Write report'), findsWidgets);
    expect(find.text('Apply selected (1)'), findsOneWidget);
  });

  tokiWidgetTest('没有结构化计划时展示生成入口', (tester) async {
    await pumpTokiApp(
      tester,
      size: surface,
      seedDatabase: false,
      extraOverrides: <Override>[
        todayPlanDataProvider.overrideWith(
          (Ref ref) async => data(withPlan: false),
        ),
      ],
    );

    expect(find.text('No structured plan for today yet'), findsOneWidget);
    expect(find.text('Generate today\'s plan'), findsOneWidget);
  });
}
