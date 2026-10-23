import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/planning/plan_progress.dart';
import 'package:toki/application/planning/plan_quality_service.dart';
import 'package:toki/domain/entities/calendar_event.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';
import 'package:toki/domain/services/recurrence.dart';

import '../../helpers/planning_context_fixture.dart';

void main() {
  final now = DateTime(2026, 10, 19, 8);
  final plan = DailyPlan(
    id: 'plan-1',
    dayKey: '2026-10-19',
    revision: 1,
    status: PlanStatus.confirmed,
    summary: '计划',
    goals: const <PlanGoal>[],
    constraints: const PlanningConstraints(),
    generationSource: PlanGenerationSource.manual,
    createdAt: now,
    updatedAt: now,
  );
  DailyPlanItem item({
    required String id,
    String? taskId,
    DateTime? start,
    DateTime? end,
    PlanItemStatus status = PlanItemStatus.applied,
    String? appliedEventId,
  }) {
    return DailyPlanItem(
      id: id,
      planId: 'plan-1',
      taskId: taskId,
      titleSnapshot: '任务 $id',
      startAt: start,
      endAt: end,
      estimateMinutes: start == null ? null : 60,
      priority: TaskPriority.normal,
      reason: '',
      source: PlanItemSource.existingTask,
      status: status,
      appliedEventId: appliedEventId,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('计划进度只统计任务条目并排除 skipped', () {
    final tasks = <String, TaskItem>{
      'done': testTask(
        id: 'done',
        status: TaskStatus.completed,
      ),
      'open': testTask(id: 'open'),
    };
    final progress = PlanProgress.compute(
      plan: plan,
      items: <DailyPlanItem>[
        item(
          id: 'a',
          taskId: 'done',
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
        item(
          id: 'b',
          taskId: 'open',
          start: DateTime(2026, 10, 19, 10),
          end: DateTime(2026, 10, 19, 11),
        ),
        item(
          id: 'c',
          taskId: 'open',
          status: PlanItemStatus.skipped,
        ),
      ],
      tasksById: tasks,
    );

    expect(progress.taskItems, 2);
    expect(progress.completedTasks, 1);
    expect(progress.openTasks, 1);
    expect(progress.completionRate, 0.5);
    expect(progress.totalMinutes, 120);
  });

  test('质量规则覆盖过满、无休息、截止、延期、未来日程和 detached', () {
    final completedTask = testTask(
      id: 'completed',
      status: TaskStatus.completed,
    );
    final dueSoon = testTask(
      id: 'due-soon',
      dueAt: DateTime(2026, 10, 19, 20),
    );
    final postponed = testTask(id: 'postponed').copyWith(postponeCount: 3);
    final deadlineTask = testTask(
      id: 'deadline',
      dueAt: DateTime(2026, 10, 19, 9, 30),
    );
    final tasks = <String, TaskItem>{
      for (final task in <TaskItem>[
        completedTask,
        dueSoon,
        postponed,
        deadlineTask,
      ])
        task.id: task,
    };
    final events = <CalendarEvent>[
      CalendarEvent(
        id: 'future',
        title: '未来日程',
        startTime: DateTime(2026, 10, 19, 15),
        endTime: DateTime(2026, 10, 19, 16),
        taskId: 'completed',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final allDay = EventOccurrence(
      event: CalendarEvent(
        id: 'all-day',
        title: '全天活动',
        startTime: DateTime(2026, 10, 19),
        endTime: DateTime(2026, 10, 20),
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
      start: DateTime(2026, 10, 19),
      end: DateTime(2026, 10, 20),
    );
    final context = testPlanningContext(
      now: now,
      tasks: tasks.values.toList(),
      capacityMinutes: 60,
      allDayOccurrences: <EventOccurrence>[allDay],
    );
    final items = <DailyPlanItem>[
      item(
        id: 'a',
        taskId: 'deadline',
        start: DateTime(2026, 10, 19, 9),
        end: DateTime(2026, 10, 19, 10),
      ),
      item(
        id: 'b',
        taskId: 'completed',
        start: DateTime(2026, 10, 19, 10, 5),
        end: DateTime(2026, 10, 19, 11),
      ),
      item(
        id: 'detached',
        taskId: 'postponed',
        status: PlanItemStatus.detached,
        appliedEventId: 'missing-event',
      ),
    ];
    final issues = const PlanQualityService().evaluate(
      items: items,
      context: context,
      tasksById: tasks,
      events: events,
    );
    final codes = issues.map((PlanQualityIssue issue) => issue.code).toSet();

    expect(codes, contains(PlanQualityCode.overbooked));
    expect(codes, contains(PlanQualityCode.noBreak));
    expect(codes, contains(PlanQualityCode.allDayContext));
    expect(codes, contains(PlanQualityCode.unscheduledDueSoon));
    expect(codes, contains(PlanQualityCode.completedTaskWithFutureEvent));
    expect(codes, contains(PlanQualityCode.deadlineRisk));
    expect(codes, contains(PlanQualityCode.repeatedPostpone));
    expect(codes, contains(PlanQualityCode.detachedEvent));
  });
}
