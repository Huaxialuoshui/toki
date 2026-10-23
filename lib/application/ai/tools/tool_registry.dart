import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/entities/ai_persona.dart';
import '../../../domain/repositories/calendar_repository.dart';
import '../../../domain/repositories/countdown_repository.dart';
import '../../../domain/repositories/daily_plan_repository.dart';
import '../../../domain/repositories/reminder_repository.dart';
import '../../../domain/repositories/task_repository.dart';
import '../../../domain/services/ai_provider.dart';
import '../../../domain/services/transaction_runner.dart';
import '../../../infrastructure/clock_provider.dart';
import '../../calendar/calendar_actions.dart';
import '../../planning/daily_planning_service.dart';
import '../../planning/daily_review_service.dart';
import '../../planning/plan_actions.dart';
import '../../planning/planning_context.dart';
import '../persona_prompt.dart';
import '../../tasks/task_actions.dart';
import '../tool_permissions.dart';
import 'ai_tool.dart';
import 'calendar_tools.dart';
import 'countdown_tools.dart';
import 'reminder_tools.dart';
import 'planning_tools.dart';
import 'system_tools.dart';

/// 工具注册表：统一管理 AI 能调用的全部工具。
class AiToolRegistry {
  AiToolRegistry(List<AiTool> tools)
      : _tools = <String, AiTool>{
          for (final tool in tools) tool.name: tool,
        };

  final Map<String, AiTool> _tools;

  List<AiTool> get all => _tools.values.toList(growable: false);

  AiTool? byName(String name) => _tools[name];

  /// 过滤出当前权限与人设允许使用的工具。
  List<AiTool> allowedTools({
    required ToolPermissions permissions,
    AiPersona? persona,
  }) {
    // 纯聊天 / 扮演的人设一个工具都不给：连"现在几点"都不查，
    // 免得模型把聊天聊成日程管理。
    if (!PersonaPrompt.usesCalendar(persona)) return const <AiTool>[];

    final enabled = persona?.enabledTools ?? const <String>[];
    return _tools.values.where((AiTool tool) {
      if (!tool.requiredCategories
          .every((AiToolCategory category) => permissions.allows(category))) {
        return false;
      }
      // 人设的 enabledTools 为空表示不限制。
      if (enabled.isNotEmpty && !enabled.contains(tool.name)) return false;
      return true;
    }).toList(growable: false);
  }

  /// 转成发给模型的工具定义。
  List<AiToolDefinition> definitions({
    required ToolPermissions permissions,
    AiPersona? persona,
  }) {
    return allowedTools(permissions: permissions, persona: persona)
        .map(
          (AiTool tool) => AiToolDefinition(
            name: tool.name,
            description: tool.description,
            parameters: tool.parameters,
          ),
        )
        .toList(growable: false);
  }

  /// 生产环境的标准工具集（25 个）。
  factory AiToolRegistry.standard({
    required ToolDependencies bundle,
  }) {
    return AiToolRegistry(<AiTool>[
      ...buildSystemTools(clock: bundle.clock),
      ...buildCalendarTools(
        events: bundle.calendar,
        actions: bundle.calendarActions,
        clock: bundle.clock,
      ),
      ...buildCountdownTools(
        countdowns: bundle.countdowns,
        clock: bundle.clock,
      ),
      ...buildReminderTools(
        reminders: bundle.reminders,
        clock: bundle.clock,
      ),
      if (bundle.plans != null &&
          bundle.tasks != null &&
          bundle.taskActions != null &&
          bundle.planActions != null &&
          bundle.planningService != null &&
          bundle.reviewService != null &&
          bundle.contextBuilder != null &&
          bundle.transactionRunner != null)
        ...buildPlanningTools(
          plans: bundle.plans!,
          tasks: bundle.tasks!,
          events: bundle.calendar,
          taskActions: bundle.taskActions!,
          planActions: bundle.planActions!,
          planningService: bundle.planningService!,
          reviewService: bundle.reviewService!,
          contextBuilder: bundle.contextBuilder!,
          calendarActions: bundle.calendarActions,
          transactionRunner: bundle.transactionRunner!,
          clock: bundle.clock,
        ),
    ]);
  }
}

/// 注册表构造所需的一组依赖。
class ToolDependencies {
  const ToolDependencies({
    required this.calendar,
    required this.countdowns,
    required this.reminders,
    required this.calendarActions,
    this.plans,
    this.tasks,
    this.taskActions,
    this.planActions,
    this.planningService,
    this.reviewService,
    this.contextBuilder,
    this.transactionRunner,
    required this.clock,
  });

  final CalendarRepository calendar;
  final CountdownRepository countdowns;
  final ReminderRepository reminders;
  final CalendarActions calendarActions;
  final DailyPlanRepository? plans;
  final TaskRepository? tasks;
  final TaskActions? taskActions;
  final PlanActions? planActions;
  final DailyPlanningService? planningService;
  final DailyReviewService? reviewService;
  final PlanningContextBuilder? contextBuilder;
  final TransactionRunner? transactionRunner;
  final Clock clock;
}

final aiToolRegistryProvider = Provider<AiToolRegistry>(
  (ref) => AiToolRegistry.standard(
    bundle: ToolDependencies(
      calendar: ref.watch(calendarRepositoryProvider),
      countdowns: ref.watch(countdownRepositoryProvider),
      reminders: ref.watch(reminderRepositoryProvider),
      calendarActions: ref.watch(calendarActionsProvider),
      plans: ref.watch(dailyPlanRepositoryProvider),
      tasks: ref.watch(taskRepositoryProvider),
      taskActions: ref.watch(taskActionsProvider),
      planActions: ref.watch(planActionsProvider),
      planningService: ref.watch(dailyPlanningServiceProvider),
      reviewService: ref.watch(dailyReviewServiceProvider),
      contextBuilder: ref.watch(planningContextBuilderProvider),
      transactionRunner: ref.watch(transactionRunnerProvider),
      clock: ref.watch(clockProvider),
    ),
  ),
);
