import '../../../core/clock.dart';
import '../../../domain/entities/calendar_event.dart';
import '../../../domain/entities/daily_plan.dart';
import '../../../domain/entities/task_item.dart';
import '../../../domain/repositories/calendar_repository.dart';
import '../../../domain/repositories/daily_plan_repository.dart';
import '../../../domain/repositories/task_repository.dart';
import '../../../domain/services/transaction_runner.dart';
import '../../planning/daily_planning_service.dart';
import '../../planning/daily_review_service.dart';
import '../../planning/plan_actions.dart';
import '../../planning/plan_progress.dart';
import '../../planning/plan_quality_service.dart';
import '../../planning/planning_context.dart';
import '../../tasks/task_actions.dart';
import '../../calendar/calendar_actions.dart';
import 'ai_tool.dart';

List<AiTool> buildPlanningTools({
  required DailyPlanRepository plans,
  required TaskRepository tasks,
  required CalendarRepository events,
  required TaskActions taskActions,
  required PlanActions planActions,
  required DailyPlanningService planningService,
  required DailyReviewService reviewService,
  required PlanningContextBuilder contextBuilder,
  required CalendarActions calendarActions,
  required TransactionRunner transactionRunner,
  required Clock clock,
}) {
  Map<String, Object?> taskJson(TaskItem task) => <String, Object?>{
        'id': task.id,
        'title': task.title,
        if (task.description != null) 'description': task.description,
        'priority': task.priority.name,
        'status': task.status.name,
        if (task.dueAt != null) 'due_at': task.dueAt!.toIso8601String(),
        if (task.estimatedMinutes != null)
          'estimated_minutes': task.estimatedMinutes,
        if (task.actualMinutes != null) 'actual_minutes': task.actualMinutes,
        if (task.completedAt != null)
          'completed_at': task.completedAt!.toIso8601String(),
        'postpone_count': task.postponeCount,
        if (task.archivedAt != null)
          'archived_at': task.archivedAt!.toIso8601String(),
      };

  Map<String, Object?> itemJson(DailyPlanItem item) => <String, Object?>{
        'id': item.id,
        if (item.taskId != null) 'task_id': item.taskId,
        'title': item.titleSnapshot,
        if (item.startAt != null) 'start_at': item.startAt!.toIso8601String(),
        if (item.endAt != null) 'end_at': item.endAt!.toIso8601String(),
        if (item.estimateMinutes != null)
          'estimate_minutes': item.estimateMinutes,
        'priority': item.priority.name,
        'status': item.status.name,
        'source': item.source.name,
        if (item.reason.isNotEmpty) 'reason': item.reason,
        if (item.appliedEventId != null)
          'applied_event_id': item.appliedEventId,
      };

  Future<Map<String, Object?>> planJson(DailyPlan plan) async {
    final items = await plans.itemsForPlan(plan.id);
    return <String, Object?>{
      'id': plan.id,
      'day_key': plan.dayKey,
      'revision': plan.revision,
      'status': plan.status.name,
      'summary': plan.summary,
      'goals': plan.goals.map((PlanGoal goal) => goal.toJson()).toList(),
      'items': items.map(itemJson).toList(),
      'unscheduled_task_ids': plan.generationMetadata.unscheduledTaskIds,
      'conflicts': plan.generationMetadata.conflicts,
      'notes': plan.generationMetadata.notes,
    };
  }

  Future<DailyPlan?> currentOrDraft(String dayKey) async {
    final current = await plans.findCurrent(dayKey);
    return current ?? await plans.findLatestDraft(dayKey);
  }

  String dayKey(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  DateTime parseDay(String? raw) {
    final text = raw?.trim();
    if (text != null && text.isNotEmpty) {
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    final now = clock.now();
    return DateTime(now.year, now.month, now.day);
  }

  return <AiTool>[
    SimpleAiTool(
      name: 'get_today_plan',
      description: '查询今天的结构化计划、状态、条目、待安排任务和冲突。',
      category: AiToolCategory.read,
      parameters: _object(),
      handler: (Map<String, Object?> args) async {
        final plan = await currentOrDraft(dayKey(clock.now()));
        return AiToolResult.success(<String, Object?>{
          'plan': plan == null ? null : await planJson(plan),
        });
      },
    ),
    SimpleAiTool(
      name: 'get_tasks',
      description:
          '查询任务。status 可为 all/open/blocked/completed，due_before 为 ISO-8601。',
      category: AiToolCategory.read,
      parameters: _object(
        properties: <String, Object?>{
          'status': _string('all/open/blocked/completed'),
          'due_before': _string('截止时间上限 ISO-8601'),
          'limit': <String, Object?>{'type': 'integer'},
        },
      ),
      handler: (Map<String, Object?> args) async {
        var list = await tasks.getAll();
        final status = args.optionalString('status') ?? 'all';
        if (status != 'all') {
          list = list
              .where((TaskItem task) => task.status.name == status)
              .toList();
        }
        final dueBefore = args.optionalDateTime('due_before');
        if (dueBefore != null) {
          list = list
              .where((TaskItem task) =>
                  task.dueAt != null && !task.dueAt!.isAfter(dueBefore))
              .toList();
        }
        final limit = (args.optionalInt('limit') ?? 40).clamp(1, 100);
        return AiToolResult.success(<String, Object?>{
          'count': list.length,
          'tasks': list.take(limit).map(taskJson).toList(),
        });
      },
    ),
    SimpleAiTool(
      name: 'create_task',
      description: '创建任务，但不创建日程。due_at 使用 ISO-8601。',
      category: AiToolCategory.create,
      parameters: _object(
        properties: <String, Object?>{
          'title': _string('任务标题'),
          'description': _string('备注'),
          'priority': _string('low/normal/high/urgent'),
          'due_at': _string('截止时间 ISO-8601'),
          'estimated_minutes': <String, Object?>{'type': 'integer'},
        },
        required: <String>['title'],
      ),
      handler: (Map<String, Object?> args) async {
        final title = args.requiredString('title');
        if (title == null) return const AiToolResult.failure('缺少参数 title');
        final task = await taskActions.create(
          title: title,
          description: args.optionalString('description'),
          priority: _priorityOrNull(args.optionalString('priority')) ??
              TaskPriority.normal,
          dueAt: args.optionalDateTime('due_at'),
          estimatedMinutes: args.optionalInt('estimated_minutes'),
          source: TaskSource.ai,
        );
        return AiToolResult.success(taskJson(task));
      },
    ),
    SimpleAiTool(
      name: 'update_task',
      description: '修改任务。clear_due=true 可清除截止时间。',
      category: AiToolCategory.update,
      confirm: true,
      parameters: _object(
        properties: <String, Object?>{
          'task_id': _string('任务 id'),
          'title': _string('新标题'),
          'description': _string('新备注'),
          'priority': _string('low/normal/high/urgent'),
          'due_at': _string('新截止时间 ISO-8601'),
          'clear_due': <String, Object?>{'type': 'boolean'},
          'estimated_minutes': <String, Object?>{'type': 'integer'},
        },
        required: <String>['task_id'],
      ),
      previewHandler: (Map<String, Object?> args) async {
        final task = await tasks.findById(args.requiredString('task_id') ?? '');
        if (task == null) return const AiToolPreview(<String>['任务不存在']);
        return AiToolPreview(<String>[
          '修改任务：${task.title}',
          if (args.optionalString('title') != null)
            '标题 → ${args.optionalString('title')}',
          if (args.containsKey('due_at'))
            '截止时间 → ${args.optionalString('due_at') ?? '清除'}',
        ]);
      },
      handler: (Map<String, Object?> args) async {
        final id = args.requiredString('task_id');
        if (id == null) return const AiToolResult.failure('缺少参数 task_id');
        final task = await tasks.findById(id);
        if (task == null) return AiToolResult.failure('没有找到任务 $id');
        final clearDue = args.optionalBool('clear_due');
        final hasDue = args.containsKey('due_at');
        final due = hasDue ? args.optionalDateTime('due_at') : null;
        final updated = task.copyWith(
          title: args.optionalString('title'),
          description: args.optionalString('description'),
          clearDescription: args.containsKey('description') &&
              args.optionalString('description') == null,
          priority: _priorityOrNull(args.optionalString('priority')),
          dueAt: due,
          clearDueAt: clearDue || (hasDue && due == null),
          estimatedMinutes: args.optionalInt('estimated_minutes'),
          clearEstimatedMinutes: args.containsKey('estimated_minutes') &&
              args.optionalInt('estimated_minutes') == null,
        );
        final saved = await taskActions.update(updated);
        return AiToolResult.success(taskJson(saved));
      },
    ),
    SimpleAiTool(
      name: 'set_task_status',
      description: '显式设置任务状态：open/completed/blocked。完成状态不由语气推断。',
      category: AiToolCategory.update,
      confirm: true,
      parameters: _object(
        properties: <String, Object?>{
          'task_id': _string('任务 id'),
          'status': _string('open/completed/blocked'),
          'completion_note': _string('完成备注'),
          'actual_minutes': <String, Object?>{'type': 'integer'},
        },
        required: <String>['task_id', 'status'],
      ),
      previewHandler: (Map<String, Object?> args) async {
        final task = await tasks.findById(args.requiredString('task_id') ?? '');
        return AiToolPreview(<String>[
          if (task == null)
            '任务不存在'
          else
            '任务「${task.title}」状态 → ${args.optionalString('status')}',
        ]);
      },
      handler: (Map<String, Object?> args) async {
        final id = args.requiredString('task_id');
        final status = args.optionalString('status');
        if (id == null || status == null) {
          return const AiToolResult.failure('缺少 task_id 或 status');
        }
        final TaskItem task;
        switch (status) {
          case 'completed':
            task = await taskActions.complete(
              id,
              completionNote: args.optionalString('completion_note'),
              actualMinutes: args.optionalInt('actual_minutes'),
            );
          case 'open':
            task = await taskActions.uncomplete(id);
          case 'blocked':
            task = await taskActions.setBlocked(id, true);
          default:
            return const AiToolResult.failure(
              'status 必须是 open/completed/blocked',
            );
        }
        return AiToolResult.success(taskJson(task));
      },
    ),
    SimpleAiTool(
      name: 'postpone_task',
      description: '把任务延后到目标日期；默认同时把该任务未来的正式日程移到目标日期。',
      category: AiToolCategory.update,
      confirm: true,
      parameters: _object(
        properties: <String, Object?>{
          'task_id': _string('任务 id'),
          'target_day': _string('目标日期 yyyy-MM-dd'),
          'move_linked_events': <String, Object?>{'type': 'boolean'},
        },
        required: <String>['task_id', 'target_day'],
      ),
      previewHandler: (Map<String, Object?> args) async {
        final id = args.requiredString('task_id') ?? '';
        final task = await tasks.findById(id);
        final now = clock.now();
        final linked = (await events.getAll())
            .where((CalendarEvent event) =>
                event.taskId == id &&
                event.endTime.isAfter(now) &&
                !event.isCancelled)
            .length;
        return AiToolPreview(<String>[
          if (task == null)
            '任务不存在'
          else
            '任务「${task.title}」延后到 ${args.optionalString('target_day')}',
          if (linked > 0) '将移动 $linked 个未来日程',
        ]);
      },
      handler: (Map<String, Object?> args) async {
        final id = args.requiredString('task_id');
        final targetRaw = args.requiredString('target_day');
        if (id == null || targetRaw == null) {
          return const AiToolResult.failure('缺少 task_id 或 target_day');
        }
        final target = DateTime.tryParse(targetRaw);
        if (target == null) {
          return const AiToolResult.failure('target_day 必须是 yyyy-MM-dd');
        }
        final moveEvents =
            args.optionalBool('move_linked_events', fallback: true);
        final now = clock.now();
        final linked = (await events.getAll())
            .where((CalendarEvent event) =>
                event.taskId == id &&
                event.endTime.isAfter(now) &&
                !event.isCancelled)
            .toList(growable: false);
        final task = await transactionRunner.run<TaskItem>(() async {
          final postponed = await taskActions.postpone(id, target);
          if (moveEvents) {
            for (final event in linked) {
              final duration = event.endTime.difference(event.startTime);
              final start = DateTime(
                target.year,
                target.month,
                target.day,
                event.startTime.hour,
                event.startTime.minute,
              );
              await calendarActions.saveEvent(
                event.copyWith(
                  startTime: start,
                  endTime: start.add(duration),
                  updatedAt: now,
                ),
              );
            }
          }
          return postponed;
        });
        return AiToolResult.success(<String, Object?>{
          'task': taskJson(task),
          'moved_events': moveEvents ? linked.length : 0,
        });
      },
    ),
    SimpleAiTool(
      name: 'generate_plan_draft',
      description: '生成今天的结构化计划草稿。只写草稿，不应用任务或日程。',
      category: AiToolCategory.create,
      parameters: _object(
        properties: <String, Object?>{
          'day': _string('日期 yyyy-MM-dd，默认今天'),
          'goal': _string('今日目标'),
          'notes': _string('补充约束'),
          'energy': _string('low/normal/high'),
          'must_do_task_ids': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{'type': 'string'},
          },
          'available_windows': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{'type': 'object'},
          },
        },
      ),
      handler: (Map<String, Object?> args) async {
        final day = parseDay(args.optionalString('day'));
        final windows = <PlanningWindow>[];
        final rawWindows = args['available_windows'];
        if (rawWindows is List) {
          for (final raw in rawWindows) {
            if (raw is Map) {
              final window = PlanningWindow.fromJson(raw);
              if (window != null) windows.add(window);
            }
          }
        }
        final result = await planningService.generateDraft(
          PlanningRequest(
            day: day,
            goalText: args.optionalString('goal'),
            notes: args.optionalString('notes'),
            energy: args.optionalString('energy'),
            mustDoTaskIds: _stringList(args['must_do_task_ids']),
            availableWindows: windows,
          ),
        );
        return AiToolResult.success(<String, Object?>{
          'plan': await planJson(result.plan),
          'unscheduled_task_ids': result.unscheduledTaskIds,
          'conflicts': result.conflicts,
        });
      },
    ),
    SimpleAiTool(
      name: 'get_plan_quality',
      description: '查询今天计划的质量风险和冲突。',
      category: AiToolCategory.read,
      parameters: _object(),
      handler: (Map<String, Object?> args) async {
        final now = clock.now();
        final plan = await currentOrDraft(dayKey(now));
        if (plan == null) {
          return const AiToolResult.success(<String, Object?>{'issues': []});
        }
        final items = await plans.itemsForPlan(plan.id);
        final allTasks = await tasks.getAll();
        final tasksById = <String, TaskItem>{
          for (final task in allTasks) task.id: task,
        };
        final context = await contextBuilder.build(
          PlanningRequest(
            day: DateTime.parse('${plan.dayKey}T00:00:00'),
            goalText: plan.constraints.goalText,
            mustDoTaskIds: plan.constraints.mustDoTaskIds,
            availableWindows: plan.constraints.availableWindows,
            blockedWindows: plan.constraints.blockedWindows,
          ),
        );
        final issues = const PlanQualityService().evaluate(
          items: items,
          context: context,
          tasksById: tasksById,
          events: await events.getAll(),
        );
        return AiToolResult.success(<String, Object?>{
          'issues': issues
              .map((PlanQualityIssue issue) => <String, Object?>{
                    'code': issue.code.name,
                    if (issue.itemId != null) 'item_id': issue.itemId,
                    if (issue.taskId != null) 'task_id': issue.taskId,
                  })
              .toList(),
        });
      },
    ),
    SimpleAiTool(
      name: 'apply_daily_plan',
      description: '应用计划草稿。必须展示变更预览并取得用户确认。',
      category: AiToolCategory.update,
      requiredCategories: <AiToolCategory>{
        AiToolCategory.create,
        AiToolCategory.update,
      },
      confirm: true,
      parameters: _object(
        properties: <String, Object?>{
          'plan_id': _string('计划 id'),
          'item_ids': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{'type': 'string'},
          },
        },
        required: <String>['plan_id'],
      ),
      previewHandler: (Map<String, Object?> args) async {
        final planId = args.requiredString('plan_id');
        if (planId == null) return const AiToolPreview(<String>['缺少 plan_id']);
        var ids = _stringList(args['item_ids']).toSet();
        if (ids.isEmpty) {
          final items = await plans.itemsForPlan(planId);
          ids = items
              .where((DailyPlanItem item) =>
                  item.status == PlanItemStatus.proposed)
              .map((DailyPlanItem item) => item.id)
              .toSet();
        }
        final preview = await planActions.previewApply(
          planId: planId,
          itemIds: ids,
        );
        return AiToolPreview(<String>[
          for (final change in preview.changes)
            '${change.action.name}: ${change.title}',
          if (preview.skippedItemIds.isNotEmpty)
            '跳过 ${preview.skippedItemIds.length} 条',
          ...preview.conflicts,
        ]);
      },
      handler: (Map<String, Object?> args) async {
        final planId = args.requiredString('plan_id');
        if (planId == null) return const AiToolResult.failure('缺少 plan_id');
        var ids = _stringList(args['item_ids']).toSet();
        if (ids.isEmpty) {
          final items = await plans.itemsForPlan(planId);
          ids = items
              .where((DailyPlanItem item) =>
                  item.status == PlanItemStatus.proposed)
              .map((DailyPlanItem item) => item.id)
              .toSet();
        }
        final result = await planActions.apply(planId: planId, itemIds: ids);
        return AiToolResult.success(<String, Object?>{
          'applied_item_ids': result.appliedItemIds,
          'skipped_item_ids': result.skippedItemIds,
          'failed_item_ids': result.failedItemIds,
          'created_tasks': result.createdTaskCount,
          'created_events': result.createdEventCount,
          'messages': result.messages,
        });
      },
    ),
    SimpleAiTool(
      name: 'get_daily_review',
      description: '查询今天的晚间复盘、本地完成统计和已保存正文。',
      category: AiToolCategory.read,
      parameters: _object(
        properties: <String, Object?>{
          'day': _string('日期 yyyy-MM-dd，默认今天'),
        },
      ),
      handler: (Map<String, Object?> args) async {
        final day = parseDay(args.optionalString('day'));
        final metrics = await reviewService.buildMetrics(day);
        final digest = await reviewService.findForDay(day);
        return AiToolResult.success(<String, Object?>{
          'metrics': metrics.toJson(),
          'review': digest == null
              ? null
              : <String, Object?>{
                  'content': digest.content,
                  if (digest.feedback != null) 'feedback': digest.feedback,
                  'user_edited': digest.userEdited,
                },
        });
      },
    ),
  ];
}

TaskPriority? _priorityOrNull(String? raw) {
  final text = raw?.toLowerCase().trim();
  for (final priority in TaskPriority.values) {
    if (priority.name == text) return priority;
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .whereType<String>()
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, Object?> _object({
  Map<String, Object?> properties = const <String, Object?>{},
  List<String> required = const <String>[],
}) =>
    <String, Object?>{
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
    };

Map<String, Object?> _string(String description) => <String, Object?>{
      'type': 'string',
      'description': description,
    };
