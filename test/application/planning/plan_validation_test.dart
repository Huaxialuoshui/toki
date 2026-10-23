import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/planning/plan_validation_service.dart';
import 'package:toki/application/planning/planning_context.dart';
import 'package:toki/application/planning/planning_result_parser.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';

import '../../helpers/planning_context_fixture.dart';

void main() {
  const validator = PlanValidationService();
  final tasks = <TaskItem>[
    testTask(id: 'a', title: '任务 A', priority: TaskPriority.high),
    testTask(id: 'b', title: '任务 B'),
    testTask(id: 'low', title: '低优先任务', priority: TaskPriority.low),
    testTask(
      id: 'due',
      title: '有截止的任务',
      dueAt: DateTime(2026, 10, 19, 10),
    ),
  ];
  final context = testPlanningContext(tasks: tasks);

  ParsedPlanItem item({
    String? taskId,
    String title = '条目',
    int index = 0,
    DateTime? start,
    DateTime? end,
    int? estimate,
    TaskPriority priority = TaskPriority.normal,
    PlanItemSource source = PlanItemSource.existingTask,
  }) {
    return ParsedPlanItem(
      taskId: taskId,
      title: title,
      startAt: start,
      endAt: end,
      estimatedMinutes: estimate,
      priority: priority,
      reason: '理由',
      source: source,
      index: index,
    );
  }

  ParsedPlanningResult result(List<ParsedPlanItem> items) =>
      ParsedPlanningResult(
        summary: '计划',
        goals: const <PlanGoal>[],
        items: items,
        unscheduledTaskIds: const <String>[],
        conflicts: const <String>[],
        notes: const <String>[],
        diagnostics: const <Map<String, Object?>>[],
      );

  test('合法安排保留，并根据起止时间修正预计耗时', () {
    final validated = validator.validate(
      result(<ParsedPlanItem>[
        item(
          taskId: 'a',
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 9, 50),
        ),
      ]),
      context,
    );

    expect(validated.items, hasLength(1));
    expect(validated.items.single.estimatedMinutes, 50);
    expect(validated.unscheduledTaskIds, isEmpty);
  });

  test('结束早于开始时条目转为待安排', () {
    final validated = validator.validate(
      result(<ParsedPlanItem>[
        item(
          taskId: 'a',
          start: DateTime(2026, 10, 19, 10),
          end: DateTime(2026, 10, 19, 9),
        ),
      ]),
      context,
    );

    expect(validated.items, isEmpty);
    expect(validated.unscheduledTaskIds, contains('a'));
    expect(
      validated.diagnostics.map((Map<String, Object?> d) => d['code']),
      contains('end_before_start'),
    );
  });

  test('固定日程重叠、窗口外、过去时间都会转为待安排', () {
    final fixedContext = testPlanningContext(
      tasks: tasks,
      fixedIntervals: <PlanningInterval>[
        PlanningInterval(
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
      ],
    );
    final validated = validator.validate(
      result(<ParsedPlanItem>[
        item(
          taskId: 'a',
          index: 0,
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 9, 30),
        ),
        item(
          taskId: 'b',
          index: 1,
          start: DateTime(2026, 10, 19, 12, 30),
          end: DateTime(2026, 10, 19, 13),
        ),
        item(
          taskId: 'low',
          index: 2,
          start: DateTime(2026, 10, 19, 7),
          end: DateTime(2026, 10, 19, 8),
        ),
      ]),
      fixedContext,
    );

    expect(validated.items, isEmpty);
    expect(
      validated.unscheduledTaskIds,
      containsAll(<String>['a', 'b', 'low']),
    );
    expect(
      validated.diagnostics.map((Map<String, Object?> d) => d['code']),
      containsAll(<String>[
        'overlaps_fixed_event',
        'outside_available_window',
        'start_in_past',
      ]),
    );
  });

  test('超过截止时间时转为待安排', () {
    final validated = validator.validate(
      result(<ParsedPlanItem>[
        item(
          taskId: 'due',
          index: 0,
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 11),
        ),
      ]),
      context,
    );

    expect(validated.unscheduledTaskIds, contains('due'));
    expect(
      validated.diagnostics.map((Map<String, Object?> d) => d['code']),
      contains('deadline_conflict'),
    );
  });

  test('两个计划条目重叠时后一个转为待安排', () {
    final validated = validator.validate(
      result(<ParsedPlanItem>[
        item(
          taskId: 'b',
          index: 0,
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
        item(
          taskId: 'a',
          index: 1,
          start: DateTime(2026, 10, 19, 9, 30),
          end: DateTime(2026, 10, 19, 10, 30),
        ),
      ]),
      context,
    );

    expect(validated.items.single.taskId, 'b');
    expect(validated.unscheduledTaskIds, contains('a'));
    expect(
      validated.diagnostics.map((Map<String, Object?> d) => d['code']),
      contains('overlapping_plan_items'),
    );
  });

  test('容量不足时优先移除低优先级条目', () {
    final narrow = testPlanningContext(
      tasks: tasks,
      capacityMinutes: 60,
    );
    final validated = validator.validate(
      result(<ParsedPlanItem>[
        item(
          taskId: 'a',
          index: 0,
          priority: TaskPriority.high,
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 9, 50),
        ),
        item(
          taskId: 'low',
          index: 1,
          priority: TaskPriority.low,
          start: DateTime(2026, 10, 19, 10),
          end: DateTime(2026, 10, 19, 10, 50),
        ),
      ]),
      narrow,
    );

    expect(validated.items.single.taskId, 'a');
    expect(validated.unscheduledTaskIds, contains('low'));
  });

  test('新任务可保留为无时间条目，已有任务无时间则进入待安排', () {
    final validated = validator.validate(
      result(<ParsedPlanItem>[
        item(
          taskId: null,
          title: '新任务',
          source: PlanItemSource.newTask,
          index: 0,
        ),
        item(taskId: 'b', index: 1),
      ]),
      context,
    );

    expect(validated.items, hasLength(1));
    expect(validated.items.single.taskId, null);
    expect(validated.items.single.startAt, null);
    expect(validated.unscheduledTaskIds, contains('b'));
  });

  test('必须完成但未安排的任务会补进待安排', () {
    final request = PlanningRequest(
      day: DateTime(2026, 10, 19),
      mustDoTaskIds: const <String>['b'],
    );
    final mustDoContext = testPlanningContext(
      tasks: tasks,
      request: request,
    );
    final validated =
        validator.validate(result(<ParsedPlanItem>[]), mustDoContext);

    expect(validated.unscheduledTaskIds, contains('b'));
  });

  test('没有可用窗口时所有带时间条目转为待安排', () {
    final noWindow = testPlanningContext(
      tasks: tasks,
      availableWindows: const <PlanningInterval>[],
      capacityMinutes: 0,
    );
    final validated = validator.validate(
      result(<ParsedPlanItem>[
        item(
          taskId: 'a',
          start: DateTime(2026, 10, 19, 9),
          end: DateTime(2026, 10, 19, 10),
        ),
      ]),
      noWindow,
    );

    expect(validated.items, isEmpty);
    expect(validated.unscheduledTaskIds, contains('a'));
  });
}
