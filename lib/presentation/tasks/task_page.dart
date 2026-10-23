import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/tasks/task_actions.dart';
import '../../application/tasks/task_providers.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../core/utils/date_formats.dart';
import '../../domain/entities/task_item.dart';
import '../../infrastructure/clock_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';
import '../widgets/async_hint.dart';
import '../widgets/page_scaffold.dart';
import 'task_editor_dialog.dart';

enum _TaskFilter { active, completed, archived }

class TaskPage extends ConsumerStatefulWidget {
  const TaskPage({super.key});

  @override
  ConsumerState<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends ConsumerState<TaskPage> {
  _TaskFilter _filter = _TaskFilter.active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activeAsync = ref.watch(activeTasksProvider);
    final completedAsync = ref.watch(completedTasksProvider);
    final archivedAsync = ref.watch(archivedTasksProvider);

    final tasks = switch (_filter) {
      _TaskFilter.active => activeAsync.valueOrNull ?? const <TaskItem>[],
      _TaskFilter.completed => completedAsync.valueOrNull ?? const <TaskItem>[],
      _TaskFilter.archived => archivedAsync.valueOrNull ?? const <TaskItem>[],
    };
    final loading = switch (_filter) {
      _TaskFilter.active => activeAsync.isLoading,
      _TaskFilter.completed => completedAsync.isLoading,
      _TaskFilter.archived => archivedAsync.isLoading,
    };

    return PageScaffold(
      title: l10n.taskSection,
      subtitle: l10n.taskPageSubtitle,
      actions: <Widget>[
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.taskBack,
        ),
        IconButton.filledTonal(
          onPressed: () => showTaskEditor(context),
          icon: const Icon(Icons.add),
          tooltip: l10n.taskNew,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ChoiceChip(
                label: Text(
                  l10n.taskFilterActive(
                    activeAsync.valueOrNull?.length ?? 0,
                  ),
                ),
                selected: _filter == _TaskFilter.active,
                onSelected: (_) => setState(() => _filter = _TaskFilter.active),
              ),
              ChoiceChip(
                label: Text(
                  l10n.taskFilterCompleted(
                    completedAsync.valueOrNull?.length ?? 0,
                  ),
                ),
                selected: _filter == _TaskFilter.completed,
                onSelected: (_) =>
                    setState(() => _filter = _TaskFilter.completed),
              ),
              ChoiceChip(
                label: Text(
                  l10n.taskFilterArchived(
                    archivedAsync.valueOrNull?.length ?? 0,
                  ),
                ),
                selected: _filter == _TaskFilter.archived,
                onSelected: (_) =>
                    setState(() => _filter = _TaskFilter.archived),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading && tasks.isEmpty)
            const LoadingHint()
          else if (tasks.isEmpty)
            EmptyHint(
              text: _emptyText(l10n),
              icon: Icons.task_alt_outlined,
            )
          else
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskCard(
                  task: task,
                  filter: _filter,
                ),
              ),
        ],
      ),
    );
  }

  String _emptyText(AppLocalizations l10n) => switch (_filter) {
        _TaskFilter.active => l10n.taskEmptyActive,
        _TaskFilter.completed => l10n.taskEmptyCompleted,
        _TaskFilter.archived => l10n.taskEmptyArchived,
      };
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.filter});

  final TaskItem task;
  final _TaskFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.localeCode;
    final now = ref.watch(clockProvider).now();
    final overdue = task.dueAt?.isBefore(now) ?? false;
    final completed = task.status == TaskStatus.completed;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (filter != _TaskFilter.archived)
            Checkbox(
              value: completed,
              onChanged: (bool? value) => _toggleCompleted(
                context,
                ref,
                value ?? false,
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(Icons.archive_outlined, size: 20),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () => showTaskEditor(context, task: task),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        _PriorityBadge(priority: task.priority),
                        if (task.status == TaskStatus.blocked)
                          _MetaChip(
                            label: l10n.taskStatusBlocked,
                            icon: Icons.pause_circle_outline,
                          ),
                        if (task.dueAt != null)
                          _MetaChip(
                            label: l10n.taskDueOn(
                              '${DateFormats.shortDate(task.dueAt!, locale)} '
                              '${DateFormats.time(task.dueAt!, locale)}',
                            ),
                            icon: Icons.schedule,
                            color: overdue ? theme.colorScheme.error : null,
                          ),
                        if (task.estimatedMinutes != null)
                          _MetaChip(
                            label: l10n.taskEstimateValue(
                              task.estimatedMinutes!,
                            ),
                            icon: Icons.timer_outlined,
                          ),
                      ],
                    ),
                    if ((task.description ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.66),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.taskMoreActions,
            onSelected: (String value) => _handleAction(context, ref, value),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'edit',
                child: Text(l10n.taskEdit),
              ),
              if (filter == _TaskFilter.active)
                PopupMenuItem<String>(
                  value: task.status == TaskStatus.blocked ? 'resume' : 'block',
                  child: Text(
                    task.status == TaskStatus.blocked
                        ? l10n.taskResume
                        : l10n.taskBlock,
                  ),
                ),
              if (filter == _TaskFilter.active)
                PopupMenuItem<String>(
                  value: 'postpone',
                  child: Text(l10n.taskPostponeTomorrow),
                ),
              if (filter == _TaskFilter.archived)
                PopupMenuItem<String>(
                  value: 'restore',
                  child: Text(l10n.taskRestore),
                )
              else
                PopupMenuItem<String>(
                  value: 'archive',
                  child: Text(l10n.taskArchive),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCompleted(
    BuildContext context,
    WidgetRef ref,
    bool completed,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final actions = ref.read(taskActionsProvider);
    if (completed) {
      await actions.complete(task.id);
    } else {
      await actions.uncomplete(task.id);
    }
    messenger?.showSnackBar(
      SnackBar(
        content: Text(completed ? l10n.taskCompletedToast : l10n.taskReopened),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final actions = ref.read(taskActionsProvider);
    if (value == 'edit') {
      await showTaskEditor(context, task: task);
      return;
    }
    switch (value) {
      case 'block':
        await actions.setBlocked(task.id, true);
      case 'resume':
        await actions.setBlocked(task.id, false);
      case 'postpone':
        final now = ref.read(clockProvider).now();
        final tomorrow =
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        await actions.postpone(task.id, tomorrow);
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.taskPostponed)),
        );
      case 'archive':
        await actions.archive(task.id);
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.taskArchivedToast)),
        );
      case 'restore':
        await actions.restore(task.id);
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.taskRestoredToast)),
        );
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = switch (priority) {
      TaskPriority.urgent => theme.colorScheme.error,
      TaskPriority.high => theme.colorScheme.primary,
      TaskPriority.normal => theme.colorScheme.secondary,
      TaskPriority.low => theme.colorScheme.onSurface.withValues(alpha: 0.55),
    };
    final label = switch (priority) {
      TaskPriority.low => l10n.taskPriorityLow,
      TaskPriority.normal => l10n.taskPriorityNormal,
      TaskPriority.high => l10n.taskPriorityHigh,
      TaskPriority.urgent => l10n.taskPriorityUrgent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective =
        color ?? theme.colorScheme.onSurface.withValues(alpha: 0.65);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: effective),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: effective),
        ),
      ],
    );
  }
}
