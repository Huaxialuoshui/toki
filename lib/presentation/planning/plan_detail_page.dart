import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/planning/plan_actions.dart';
import '../../application/planning/plan_progress.dart';
import '../../application/planning/plan_providers.dart';
import '../../application/planning/plan_quality_service.dart';
import '../../application/tasks/task_actions.dart';
import '../../core/errors/planning_exception.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/daily_plan.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/services/recurrence.dart';
import '../../infrastructure/clock_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/async_hint.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/section_header.dart';
import 'plan_apply_dialog.dart';
import 'plan_generation_dialog.dart';
import 'plan_labels.dart';

class PlanDetailPage extends ConsumerStatefulWidget {
  const PlanDetailPage({super.key});

  @override
  ConsumerState<PlanDetailPage> createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends ConsumerState<PlanDetailPage> {
  final Set<String> _selected = <String>{};
  bool _explicitSelection = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dataAsync = ref.watch(todayPlanDataProvider);
    final data = dataAsync.valueOrNull;
    final display = data?.openDraft ?? data?.displayPlan;
    if (data == null) {
      return PageScaffold(
        title: l10n.planSection,
        actions: <Widget>[
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.taskBack,
          ),
        ],
        child: dataAsync.hasError
            ? EmptyHint(text: '${dataAsync.error}')
            : const LoadingHint(),
      );
    }
    if (display == null) {
      return PageScaffold(
        title: l10n.planSection,
        actions: <Widget>[
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.taskBack,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            EmptyHint(text: l10n.planNoPlan),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : () => _generate(context),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(l10n.planGenerate),
            ),
          ],
        ),
      );
    }

    final itemsAsync = ref.watch(planItemsProvider(display.id));
    final items = itemsAsync.valueOrNull ??
        (display.id == data.displayPlan?.id
            ? data.items
            : const <DailyPlanItem>[]);
    final proposed = items
        .where((DailyPlanItem item) => item.status == PlanItemStatus.proposed)
        .toList(growable: false);
    final selected = _explicitSelection
        ? _selected.intersection(
            proposed.map((DailyPlanItem item) => item.id).toSet(),
          )
        : proposed.map((DailyPlanItem item) => item.id).toSet();
    final progress = PlanProgress.compute(
      plan: display,
      items: items,
      tasksById: data.tasksById,
    );
    final issues = data.context == null
        ? const <PlanQualityIssue>[]
        : const PlanQualityService().evaluate(
            items: items,
            context: data.context!,
            tasksById: data.tasksById,
            events: data.events,
          );

    return PageScaffold(
      title: l10n.planSection,
      subtitle: DateFormats.fullDate(
        DateTime.parse('${display.dayKey}T00:00:00'),
        context.localeCode,
      ),
      actions: <Widget>[
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.taskBack,
        ),
        IconButton(
          onPressed: _busy ? null : () => _generate(context),
          icon: const Icon(Icons.auto_awesome),
          tooltip: l10n.planRegenerate,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (data.hasPendingDraft && display.id == data.openDraft?.id) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.planPendingDraft,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.planDraftPendingHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.66),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _PlanHeader(
            plan: display,
            progress: progress,
          ),
          const SizedBox(height: 16),
          if (display.goals.isNotEmpty) ...<Widget>[
            SectionHeader(
              title: l10n.planGoalTitle,
              icon: Icons.flag_outlined,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final goal in display.goals)
                  Chip(
                    label: Text(goal.title),
                    avatar: Icon(
                      Icons.flag_outlined,
                      size: 15,
                      color: _priorityColor(
                        Theme.of(context),
                        goal.priority,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (data.context?.availableWindows.isNotEmpty ?? false) ...<Widget>[
            SectionHeader(
              title: l10n.planAvailableWindows,
              icon: Icons.schedule,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final window in data.context!.availableWindows)
                  Chip(
                    label: Text(
                      '${DateFormats.time(window.start, context.localeCode)}'
                      '-${DateFormats.time(window.end, context.localeCode)}',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SectionHeader(
            title: l10n.planFixedSchedule,
            icon: Icons.event_available_outlined,
          ),
          if (data.fixedOccurrences.isEmpty)
            EmptyHint(
              text: l10n.planNoFixed,
              icon: Icons.event_available_outlined,
            )
          else
            for (final occurrence in data.fixedOccurrences)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FixedEventRow(occurrence: occurrence),
              ),
          if (issues.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            SectionHeader(
              title: l10n.planIssuesTitle,
              icon: Icons.warning_amber_outlined,
            ),
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• ${planIssueLabel(l10n, issue.code)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          _Timeline(
            items: items,
            tasksById: data.tasksById,
            selected: selected,
            onToggle: (String id, bool value) {
              setState(() {
                _explicitSelection = true;
                if (value) {
                  _selected.add(id);
                } else {
                  _selected.remove(id);
                }
              });
            },
            onAdjust: (DailyPlanItem item) => _adjustTime(context, item),
            onRemove: (DailyPlanItem item) => _removeItem(context, item),
            onComplete: (DailyPlanItem item) => _toggleTask(context, item),
          ),
          if (items.any(
            (DailyPlanItem item) =>
                item.taskId != null &&
                data.tasksById[item.taskId]?.status == TaskStatus.completed,
          )) ...<Widget>[
            const SizedBox(height: 16),
            SectionHeader(
              title: l10n.planTaskCompleted,
              icon: Icons.check_circle_outline,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final item in items)
                  if (item.taskId != null &&
                      data.tasksById[item.taskId]?.status ==
                          TaskStatus.completed)
                    Chip(
                      avatar: const Icon(Icons.check, size: 15),
                      label: Text(
                        data.tasksById[item.taskId]!.title,
                      ),
                    ),
              ],
            ),
          ],
          if (display
              .generationMetadata.unscheduledTaskIds.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            SectionHeader(
              title: l10n.planTimelineUnscheduled,
              icon: Icons.inbox_outlined,
            ),
            for (final taskId in display.generationMetadata.unscheduledTaskIds)
              if (data.tasksById[taskId] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GlassCard(
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.inbox_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(data.tasksById[taskId]!.title),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 20),
          _Actions(
            plan: display,
            proposedCount: proposed.length,
            selectedCount: selected.length,
            busy: _busy,
            onApplyAll: proposed.isEmpty
                ? null
                : () => _apply(
                      context,
                      proposed.map((DailyPlanItem item) => item.id).toSet(),
                    ),
            onApplySelected:
                selected.isEmpty ? null : () => _apply(context, selected),
            onCancelPlan: () => _cancelPlan(context),
            onCompleteDay: () => _completeDay(context),
          ),
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    final result = await showPlanGenerationDialog(context);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _explicitSelection = false;
      _selected.clear();
    });
    if (result != null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.planGenerated)),
      );
    }
  }

  Future<void> _apply(BuildContext context, Set<String> ids) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _busy = true);
    try {
      final actions = ref.read(planActionsProvider);
      final planId = (ref.read(todayPlanDataProvider).valueOrNull?.openDraft ??
              ref.read(todayPlanDataProvider).valueOrNull?.displayPlan)
          ?.id;
      if (planId == null) return;
      final preview = await actions.previewApply(
        planId: planId,
        itemIds: ids,
      );
      if (!mounted) return;
      if (!preview.canApply) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              preview.isStale
                  ? l10n.planStale
                  : (preview.conflicts.isEmpty
                      ? l10n.planConflict
                      : preview.conflicts.join('；')),
            ),
          ),
        );
        return;
      }
      final confirmed = await showPlanApplyDialog(this.context, preview);
      if (!confirmed || !mounted) return;
      final result = await actions.apply(planId: planId, itemIds: ids);
      if (!mounted) return;
      setState(() {
        _explicitSelection = false;
        _selected.clear();
      });
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            l10n.planApplyResult(
              result.createdTaskCount,
              result.createdEventCount,
              result.skippedItemIds.length,
            ),
          ),
        ),
      );
    } on PlanningException catch (error) {
      if (!mounted) return;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            switch (error.code) {
              PlanningErrorCode.planStale => l10n.planStale,
              PlanningErrorCode.planConflict => l10n.planConflict,
              _ => '${l10n.planApplyFailed}：${error.code.name}',
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _adjustTime(BuildContext context, DailyPlanItem item) async {
    final start = item.startAt ?? ref.read(clockProvider).now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(start),
      firstDate: DateTime(start.year - 1),
      lastDate: DateTime(start.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: this.context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (time == null || !mounted) return;
    final newStart = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final duration = item.startAt != null && item.endAt != null
        ? item.endAt!.difference(item.startAt!)
        : const Duration(minutes: 60);
    try {
      final planId = (ref.read(todayPlanDataProvider).valueOrNull?.openDraft ??
              ref.read(todayPlanDataProvider).valueOrNull?.displayPlan)
          ?.id;
      if (planId == null) return;
      await ref.read(planActionsProvider).updateDraftItemTime(
            planId: planId,
            itemId: item.id,
            start: newStart,
            end: newStart.add(duration),
          );
    } on PlanningException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(this.context)?.showSnackBar(
        SnackBar(
          content: Text(error.message ?? this.context.l10n.planConflict),
        ),
      );
    }
  }

  Future<void> _removeItem(BuildContext context, DailyPlanItem item) async {
    final planId = (ref.read(todayPlanDataProvider).valueOrNull?.openDraft ??
            ref.read(todayPlanDataProvider).valueOrNull?.displayPlan)
        ?.id;
    if (planId == null) return;
    await ref.read(planActionsProvider).skipItem(planId, item.id);
  }

  Future<void> _toggleTask(BuildContext context, DailyPlanItem item) async {
    final task = item.taskId == null
        ? null
        : ref.read(todayPlanDataProvider).valueOrNull?.tasksById[item.taskId];
    if (task == null) return;
    final actions = ref.read(taskActionsProvider);
    if (task.status == TaskStatus.completed) {
      await actions.uncomplete(task.id);
    } else {
      await actions.complete(task.id);
    }
  }

  Future<void> _cancelPlan(BuildContext context) async {
    final l10n = context.l10n;
    final planId = (ref.read(todayPlanDataProvider).valueOrNull?.openDraft ??
            ref.read(todayPlanDataProvider).valueOrNull?.displayPlan)
        ?.id;
    if (planId == null) return;
    final confirmed = await _confirm(
      context,
      title: l10n.planCancelConfirmTitle,
      body: l10n.planCancelConfirmBody,
      action: l10n.planCancelPlan,
    );
    if (!confirmed) return;
    await ref.read(planActionsProvider).cancelPlan(planId);
  }

  Future<void> _completeDay(BuildContext context) async {
    final l10n = context.l10n;
    final planId = (ref.read(todayPlanDataProvider).valueOrNull?.openDraft ??
            ref.read(todayPlanDataProvider).valueOrNull?.displayPlan)
        ?.id;
    if (planId == null) return;
    final confirmed = await _confirm(
      context,
      title: l10n.planCompleteConfirmTitle,
      body: l10n.planCompleteConfirmBody,
      action: l10n.planCompleteDay,
    );
    if (!confirmed) return;
    await ref.read(planActionsProvider).completeDay(planId);
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.planApplyCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.plan, required this.progress});

  final DailyPlan plan;
  final PlanProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: planStatusColor(theme, plan.status)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  planStatusLabel(l10n, plan.status),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: planStatusColor(theme, plan.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.planRevision(plan.revision),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    l10n.planGeneratedAt(
                      DateFormats.time(plan.createdAt, context.localeCode),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  Text(
                    l10n.planUpdatedAt(
                      DateFormats.time(plan.updatedAt, context.localeCode),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            plan.summary,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.completionRate,
                    minHeight: 7,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${progress.completedTasks}/${progress.taskItems}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FixedEventRow extends StatelessWidget {
  const _FixedEventRow({required this.occurrence});

  final EventOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.localeCode;
    return GlassCard(
      child: Row(
        children: <Widget>[
          Icon(
            Icons.event_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(occurrence.event.title)),
          Text(
            '${DateFormats.time(occurrence.start, locale)}'
            '-${DateFormats.time(occurrence.end, locale)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.items,
    required this.tasksById,
    required this.selected,
    required this.onToggle,
    required this.onAdjust,
    required this.onRemove,
    required this.onComplete,
  });

  final List<DailyPlanItem> items;
  final Map<String, TaskItem> tasksById;
  final Set<String> selected;
  final void Function(String id, bool value) onToggle;
  final void Function(DailyPlanItem item) onAdjust;
  final void Function(DailyPlanItem item) onRemove;
  final void Function(DailyPlanItem item) onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = <String, List<DailyPlanItem>>{
      l10n.planTimelineMorning: <DailyPlanItem>[],
      l10n.planTimelineAfternoon: <DailyPlanItem>[],
      l10n.planTimelineEvening: <DailyPlanItem>[],
      l10n.planTimelineUnscheduled: <DailyPlanItem>[],
    };
    for (final item in items) {
      if (item.status == PlanItemStatus.skipped) continue;
      final start = item.startAt;
      if (start == null) {
        groups[l10n.planTimelineUnscheduled]!.add(item);
      } else if (start.hour < 12) {
        groups[l10n.planTimelineMorning]!.add(item);
      } else if (start.hour < 18) {
        groups[l10n.planTimelineAfternoon]!.add(item);
      } else {
        groups[l10n.planTimelineEvening]!.add(item);
      }
    }
    final hasAny = items
        .any((DailyPlanItem item) => item.status != PlanItemStatus.skipped);
    if (!hasAny) {
      return EmptyHint(text: l10n.planNoItems, icon: Icons.auto_awesome);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final entry in groups.entries)
          if (entry.value.isNotEmpty) ...<Widget>[
            SectionHeader(
              title: entry.key,
              icon: Icons.view_timeline_outlined,
            ),
            for (final item in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlanItemCard(
                  item: item,
                  task: item.taskId == null ? null : tasksById[item.taskId],
                  selected: selected.contains(item.id),
                  onToggle: (bool value) => onToggle(item.id, value),
                  onAdjust: () => onAdjust(item),
                  onRemove: () => onRemove(item),
                  onComplete: () => onComplete(item),
                ),
              ),
          ],
      ],
    );
  }
}

class _PlanItemCard extends StatelessWidget {
  const _PlanItemCard({
    required this.item,
    required this.task,
    required this.selected,
    required this.onToggle,
    required this.onAdjust,
    required this.onRemove,
    required this.onComplete,
  });

  final DailyPlanItem item;
  final TaskItem? task;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final VoidCallback onAdjust;
  final VoidCallback onRemove;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.localeCode;
    final proposed = item.status == PlanItemStatus.proposed;
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (proposed)
            Checkbox(value: selected, onChanged: (v) => onToggle(v ?? false))
          else if (item.status == PlanItemStatus.applied)
            Checkbox(
              value: task?.status == TaskStatus.completed,
              onChanged: task == null ? null : (_) => onComplete(),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.titleSnapshot,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _PriorityDot(priority: item.priority),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: <Widget>[
                    Text(
                      item.startAt == null || item.endAt == null
                          ? l10n.planTimelineUnscheduled
                          : '${DateFormats.time(item.startAt!, locale)}'
                              '-${DateFormats.time(item.endAt!, locale)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.estimateMinutes != null)
                      Text(
                        l10n.taskEstimateValue(item.estimateMinutes!),
                        style: theme.textTheme.bodySmall,
                      ),
                    if (task?.dueAt != null)
                      Text(
                        l10n.taskDueOn(
                          DateFormats.shortDate(task!.dueAt!, locale),
                        ),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
                if (item.reason.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 5),
                  Text(
                    item.reason,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.66),
                    ),
                  ),
                ],
                if (item.status == PlanItemStatus.detached)
                  Text(
                    l10n.planIssueDetached,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          if (proposed)
            PopupMenuButton<String>(
              tooltip: l10n.taskMoreActions,
              onSelected: (String value) {
                if (value == 'time') onAdjust();
                if (value == 'remove') onRemove();
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                if (item.startAt != null && item.endAt != null)
                  PopupMenuItem<String>(
                    value: 'time',
                    child: Text(l10n.planAdjustTime),
                  ),
                PopupMenuItem<String>(
                  value: 'remove',
                  child: Text(l10n.planRemoveItem),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: _priorityColor(Theme.of(context), priority),
        shape: BoxShape.circle,
      ),
    );
  }
}

Color _priorityColor(ThemeData theme, TaskPriority priority) =>
    switch (priority) {
      TaskPriority.urgent => theme.colorScheme.error,
      TaskPriority.high => theme.colorScheme.primary,
      TaskPriority.normal => theme.colorScheme.secondary,
      TaskPriority.low => theme.colorScheme.onSurface.withValues(alpha: 0.5),
    };

class _Actions extends StatelessWidget {
  const _Actions({
    required this.plan,
    required this.proposedCount,
    required this.selectedCount,
    required this.busy,
    required this.onApplyAll,
    required this.onApplySelected,
    required this.onCancelPlan,
    required this.onCompleteDay,
  });

  final DailyPlan plan;
  final int proposedCount;
  final int selectedCount;
  final bool busy;
  final VoidCallback? onApplyAll;
  final VoidCallback? onApplySelected;
  final VoidCallback onCancelPlan;
  final VoidCallback onCompleteDay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final draft = plan.status == PlanStatus.draft;
    return GlassCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        children: <Widget>[
          if (draft && proposedCount > 0)
            OutlinedButton(
              onPressed: busy ? null : onApplyAll,
              child: Text(l10n.planApplyAll),
            ),
          if (draft && proposedCount > 0)
            FilledButton(
              onPressed: busy || selectedCount == 0 ? null : onApplySelected,
              child: Text(l10n.planApplySelected(selectedCount)),
            ),
          if (!draft &&
              plan.status != PlanStatus.completed &&
              plan.status != PlanStatus.cancelled)
            FilledButton.tonal(
              onPressed: busy ? null : onCompleteDay,
              child: Text(l10n.planCompleteDay),
            ),
          if (plan.status != PlanStatus.completed &&
              plan.status != PlanStatus.cancelled)
            TextButton(
              onPressed: busy ? null : onCancelPlan,
              child: Text(l10n.planCancelPlan),
            ),
        ],
      ),
    );
  }
}
