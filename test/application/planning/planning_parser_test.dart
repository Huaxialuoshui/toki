import 'package:flutter_test/flutter_test.dart';
import 'package:toki/application/planning/planning_result_parser.dart';
import 'package:toki/core/errors/planning_exception.dart';
import 'package:toki/domain/entities/daily_plan.dart';
import 'package:toki/domain/entities/task_item.dart';

import '../../helpers/planning_context_fixture.dart';

void main() {
  const parser = PlanningResultParser();
  final context = testPlanningContext(
    tasks: <TaskItem>[
      testTask(id: 'task-1', title: '写报告', priority: TaskPriority.high),
      testTask(id: 'task-2', title: '复习'),
    ],
  );

  test('解析代码围栏、前后说明、已有任务与新任务', () {
    final result = parser.parse(
      '''
下面是计划：
```json
{
  "dayKey": "2026-10-19",
  "summary": "先完成报告",
  "goals": [{"title": "完成报告", "priority": "high"}],
  "items": [
    {
      "taskId": "task-1",
      "title": "写报告",
      "startTime": "2026-10-19T09:00:00",
      "endTime": "2026-10-19T10:00:00",
      "priority": "high",
      "reason": "截止临近",
      "source": "existing_task"
    },
    {
      "taskId": null,
      "title": "整理引用",
      "estimatedMinutes": 30,
      "priority": "normal",
      "reason": "报告前置",
      "source": "new_task"
    }
  ],
  "unscheduledTaskIds": ["task-2"],
  "conflicts": [],
  "notes": ["下午留出休息"]
}
```
以上是建议。
''',
      context,
    );

    expect(result.summary, '先完成报告');
    expect(result.goals.single.priority, TaskPriority.high);
    expect(result.items, hasLength(2));
    expect(result.items.first.taskId, 'task-1');
    expect(result.items.last.taskId, null);
    expect(result.items.last.source, PlanItemSource.newTask);
    expect(result.unscheduledTaskIds, <String>['task-2']);
    expect(result.notes.single, '下午留出休息');
  });

  test('未知任务 ID、缺标题和未知待安排 ID 会形成诊断并跳过对应项', () {
    final result = parser.parse(
      '''
{
  "summary": "计划",
  "items": [
    {"taskId": "missing", "title": "伪造", "source": "existing_task"},
    {"taskId": null, "title": "", "source": "new_task"}
  ],
  "unscheduledTaskIds": ["also-missing"]
}
''',
      context,
    );

    expect(result.items, isEmpty);
    expect(result.unscheduledTaskIds, isEmpty);
    expect(
      result.diagnostics.map((Map<String, Object?> d) => d['code']),
      containsAll(<String>[
        'unknown_task_id',
        'missing_title',
        'unknown_unscheduled_task',
      ]),
    );
  });

  test('只有开始时间与预计耗时会推导结束时间', () {
    final result = parser.parse(
      '''
{
  "summary": "计划",
  "items": [{
    "taskId": "task-1",
    "title": "写报告",
    "startTime": "2026-10-19T09:00:00",
    "estimatedMinutes": 45,
    "source": "existing_task"
  }]
}
''',
      context,
    );

    expect(result.items.single.startAt, DateTime(2026, 10, 19, 9));
    expect(result.items.single.endAt, DateTime(2026, 10, 19, 9, 45));
  });

  test('日期不匹配与没有 JSON 时拒绝解析', () {
    expect(
      () => parser.parse(
        '{"dayKey":"2026-10-20","summary":"x","items":[]}',
        context,
      ),
      throwsA(
        isA<PlanningException>().having(
          (PlanningException e) => e.code,
          'code',
          PlanningErrorCode.parseFailed,
        ),
      ),
    );
    expect(
      () => parser.parse('模型没有返回 JSON', context),
      throwsA(isA<PlanningException>()),
    );
  });
}
